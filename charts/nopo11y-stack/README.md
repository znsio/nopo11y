# Introduction

Nopo11y-stack is a fully opensource observability stack. Which provides metrics, logs, tracing and alerts integration out of the box. It includes following popular sub-charts:

- kube-prometheus-stack v58.2.2
- thanos v15.4.1
- grafana-loki v4.0.0
- promtail v6.15.5
- sloth v0.7.0
- kiali-server v1.83.0
- jaeger v1.0.0

It will install following components into your kubernetes cluster:

- **Prometheus**: Opensource monitoring system & timeseries database
- **Thanos**: Open source, highly available Prometheus setup with long term storage capabilities.
- **Grafana**: Grafana is the open source analytics & monitoring solution for every database.
- **Loki**: Loki is a horizontally scalable, highly available, multi-tenant log aggregation system inspired by Prometheus
- **Promtail**: Promtail is an agent which ships the contents of local logs to a private Grafana Loki instance
- **Jaeger**: Jaeger is an open source distributed tracing platform.
- **Alertmanager**: The Alertmanager handles alerts sent by client applications such as the Prometheus server. It takes care of deduplicating, grouping, and routing them to the correct receiver integration such as email, PagerDuty, or OpsGenie
- **Kiali**: Kiali is a console for Istio service mesh, You can configure, visualize, validate and troubleshoot your mesh using Kiali
- **Sloth**: Prometheus SLO generator


# How to install?

[Helm](https://helm.sh) must be installed to use the charts. Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add znsio https://znsio.github.io/charts

If you had already added this repo earlier, run following command to retrieve the latest versions of the packages,

    helm repo update

To install the chart:

    helm install nopo11y-stack znsio/nopo11y-stack

To uninstall the chart:

    helm delete nopo11y-stack