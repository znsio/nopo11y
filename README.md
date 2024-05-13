[WIP]

# Introduction

Nopo11y is a collection of multiple open-source components charts. It includes following sub-charts:

- kube-prometheus-stack v58.2.2
- thanos v15.4.1
- grafana-loki v4.0.0
- promtail v6.15.5
- sloth v0.7.0
- kiali-server v1.83.0
- jaeger v1.0.0

# How to configure?

All the sub-charts have their configuration with documentation in `values.yaml` file.

# How to install?

1. Update the `values.yaml` file as per your requirement.
2. Install the chart using below command,
```bash
helm upgrade --install nopo11y-stack . -n <NAMEPSPACE>
```