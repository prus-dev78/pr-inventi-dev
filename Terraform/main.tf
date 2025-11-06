# Main Terraform configuration for OCI Kubernetes Infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

# Virtual Cloud Network (VCN)
resource "oci_core_vcn" "k8s_vcn" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "k8s-vcn"
  dns_label      = "k8svcn"
}

# Internet Gateway for public subnet
resource "oci_core_internet_gateway" "k8s_ig" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s_vcn.id
  display_name   = "k8s-internet-gateway"
  enabled        = true
}

# NAT Gateway for private subnet
resource "oci_core_nat_gateway" "k8s_nat" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s_vcn.id
  display_name   = "k8s-nat-gateway"
}

# Service Gateway for Oracle services
resource "oci_core_service_gateway" "k8s_sg" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s_vcn.id
  display_name   = "k8s-service-gateway"
  
  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
}

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

# Route table for public subnet
resource "oci_core_route_table" "k8s_public_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s_vcn.id
  display_name   = "k8s-public-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.k8s_ig.id
  }
}

# Route table for private subnet
resource "oci_core_route_table" "k8s_private_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s_vcn.id
  display_name   = "k8s-private-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.k8s_nat.id
  }

  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.k8s_sg.id
  }
}

# Security List for Kubernetes API Endpoint (public subnet)
resource "oci_core_security_list" "k8s_api_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s_vcn.id
  display_name   = "k8s-api-security-list"

  # Allow inbound HTTPS traffic to Kubernetes API from allowed IPs
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = var.api_allowed_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # Allow all outbound traffic
  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    stateless        = false
  }
}

# Security List for Worker Nodes (private subnet)
resource "oci_core_security_list" "k8s_worker_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s_vcn.id
  display_name   = "k8s-worker-security-list"

  # Allow inbound traffic from VCN (internal communication)
  ingress_security_rules {
    protocol    = "all"
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  # Allow inbound HTTP traffic from load balancer subnet
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "10.0.20.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      min = 30000
      max = 32767
    }
  }

  # Allow all outbound traffic
  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    stateless        = false
  }
}

# Security List for Load Balancer (public subnet)
resource "oci_core_security_list" "k8s_lb_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s_vcn.id
  display_name   = "k8s-lb-security-list"

  # Allow inbound HTTP traffic
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      min = 80
      max = 80
    }
  }

  # Allow inbound HTTPS traffic
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      min = 443
      max = 443
    }
  }

  # Allow all outbound traffic
  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    stateless        = false
  }
}

# Public subnet for Kubernetes API endpoint
resource "oci_core_subnet" "k8s_api_subnet" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.k8s_vcn.id
  cidr_block        = "10.0.10.0/24"
  display_name      = "k8s-api-subnet"
  dns_label         = "k8sapi"
  route_table_id    = oci_core_route_table.k8s_public_rt.id
  security_list_ids = [oci_core_security_list.k8s_api_security_list.id]
}

# Private subnet for worker nodes
resource "oci_core_subnet" "k8s_worker_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.k8s_vcn.id
  cidr_block                 = "10.0.11.0/24"
  display_name               = "k8s-worker-subnet"
  dns_label                  = "k8sworker"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.k8s_private_rt.id
  security_list_ids          = [oci_core_security_list.k8s_worker_security_list.id]
}

# Public subnet for load balancers
resource "oci_core_subnet" "k8s_lb_subnet" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.k8s_vcn.id
  cidr_block        = "10.0.20.0/24"
  display_name      = "k8s-lb-subnet"
  dns_label         = "k8slb"
  route_table_id    = oci_core_route_table.k8s_public_rt.id
  security_list_ids = [oci_core_security_list.k8s_lb_security_list.id]
}

# OKE Cluster
resource "oci_containerengine_cluster" "k8s_cluster" {
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = "k8s-cluster"
  vcn_id             = oci_core_vcn.k8s_vcn.id

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.k8s_api_subnet.id
  }

  options {
    service_lb_subnet_ids = [oci_core_subnet.k8s_lb_subnet.id]

    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }

    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
  }
}

# Node Pool with 4 nodes
resource "oci_containerengine_node_pool" "k8s_node_pool" {
  cluster_id         = oci_containerengine_cluster.k8s_cluster.id
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = "k8s-node-pool"
  node_shape         = var.node_shape

  node_shape_config {
    memory_in_gbs = var.node_memory_in_gbs
    ocpus         = var.node_ocpus
  }

  node_source_details {
    image_id    = data.oci_core_images.node_pool_images.images[0].id
    source_type = "IMAGE"
  }

  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.k8s_worker_subnet.id
    }

    size = var.node_pool_size
  }

  initial_node_labels {
    key   = "name"
    value = "k8s-cluster"
  }
}

# Get the latest Oracle Linux image for worker nodes
data "oci_core_images" "node_pool_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "7.9"
  shape                    = var.node_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}
