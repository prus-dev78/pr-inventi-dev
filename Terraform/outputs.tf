# Outputs for OCI Kubernetes Infrastructure

output "vcn_id" {
  description = "The OCID of the VCN"
  value       = oci_core_vcn.k8s_vcn.id
}

output "cluster_id" {
  description = "The OCID of the OKE cluster"
  value       = oci_containerengine_cluster.k8s_cluster.id
}

output "cluster_name" {
  description = "The name of the OKE cluster"
  value       = oci_containerengine_cluster.k8s_cluster.name
}

output "cluster_kubernetes_version" {
  description = "The Kubernetes version of the cluster"
  value       = oci_containerengine_cluster.k8s_cluster.kubernetes_version
}

output "node_pool_id" {
  description = "The OCID of the node pool"
  value       = oci_containerengine_node_pool.k8s_node_pool.id
}

output "node_pool_kubernetes_version" {
  description = "The Kubernetes version of the node pool"
  value       = oci_containerengine_node_pool.k8s_node_pool.kubernetes_version
}

output "kubeconfig_command" {
  description = "Command to generate kubeconfig for cluster access"
  value       = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.k8s_cluster.id} --file $HOME/.kube/config --region ${var.region} --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT"
}

output "cluster_endpoints" {
  description = "Cluster endpoint details"
  value = {
    public_endpoint  = oci_containerengine_cluster.k8s_cluster.endpoints[0].public_endpoint
    private_endpoint = oci_containerengine_cluster.k8s_cluster.endpoints[0].private_endpoint
  }
}

output "api_subnet_id" {
  description = "The OCID of the API subnet"
  value       = oci_core_subnet.k8s_api_subnet.id
}

output "worker_subnet_id" {
  description = "The OCID of the worker subnet"
  value       = oci_core_subnet.k8s_worker_subnet.id
}

output "lb_subnet_id" {
  description = "The OCID of the load balancer subnet"
  value       = oci_core_subnet.k8s_lb_subnet.id
}
