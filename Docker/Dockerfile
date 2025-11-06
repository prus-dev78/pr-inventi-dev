# Dockerfile HelloWorld
FROM python:3.11-slim

WORKDIR /app
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .

RUN useradd -m -u 1000 flaskuser && \
    chown -R flaskuser:flaskuser /app
USER flaskuser
EXPOSE 8080

HEALTHCHECK --interval=60s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

CMD ["python", "app.py"]

# docker build -t hello-world:1 .
# docker run -d -p 8080:8080 hello-world:1