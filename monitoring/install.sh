#!/bin/bash
kubectl create namespace monitoring

# Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus \
  -n monitoring -f prometheus/values.yaml

# Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana \
  -n monitoring -f grafana/values.yaml

# Loki
helm install loki grafana/loki-stack \
  -n monitoring -f loki/values.yaml

echo "Monitoring stack installé !"
