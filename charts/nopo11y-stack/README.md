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


## How to install?

[Helm](https://helm.sh) must be installed to use the charts. Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add znsio https://znsio.github.io/nopo11y

If you had already added this repo earlier, run following command to retrieve the latest versions of the packages,

    helm repo update

To install the chart:

    helm install nopo11y-stack znsio/nopo11y-stack

To uninstall the chart:

    helm uninstall nopo11y-stack

## How to access
Nopo11y-stack gives you an option to setup an ingress for accessing nopo11y-stack components externally either using nginx ingress or istio ingress, based on the ingress type you select. 

Nopo11y-stack creates an ingress with path based routing to the nopo11y-stack components, if you have enabled nopo11y-stack ingress with DNS/hostname ```observability.example.com``` and configured nopo11y-stack components like prometheus, alertmanaget, grafana, kiali, jaeger etc. with route-prefix other than ```/``` then you can access thonse componets using the DNS and the route-prefix, e.g. if you configure prometheus with route-prefix ```/prometheus``` then you would be able to access prometheus on ```http(s)://observability.example.com/prometheus```

|Components |Route-prefix|Endpoint|
|-----------|------------|--------|
|Prometheus |/prometheus |http(s)://observability.example.com/prometheus |
|Grafana |/grafana |http(s)://observability.example.com/grafnan |
|Alertmanager |/alertmanager |http(s)://observability.example.com/alertmanager |
|Thanos-query |/thanos-query |http(s)://observability.example.com/thanos-query |
|Kiali |/kiali |http(s)://observability.example.com/kiali |
|Jaeger |/jaeger |http(s)://observability.example.com/jaeger |
|Kuberhealthy |/nopo11y-health-check |http(s)://observability.example.com/nopo11y-health-check |

**Note:** Nopo11y-stack creates an ingress only for those components which are configured with route-prefix other than ```/```, if you configured your component to run on ```/``` web root then it won't create an ingress for that component.