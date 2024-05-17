# Introduction

Nopo11y is a wrapper on top of nopo11y-stack, using nopo11y one can create basic dashboards with golder signals, alerts and SLOs for every microservice.

# How to install?

[Helm](https://helm.sh) must be installed to use the charts. Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add znsio https://znsio.github.io/nopo11y

If you had already added this repo earlier, run following command to retrieve the latest versions of the packages,

    helm repo update

To install the chart:

    helm install <service_name>-nopo11y znsio/nopo11y

To uninstall the chart:

    helm delete <service_name>-nopo11y

# Configuration

| Key                               | Type   | Required? | Default        | Description                                                                        |
|-----------------------------------|--------|-----------|----------------|------------------------------------------------------------------------------------|
| enabled                           | bool   | no        | false          | If set to true then it will create default dashboard, alerts and SLOs              |
| namespace                         | string | no        | observability  | Use the same namespace as you used during the installation of nopo11y stack        |
| appLabel                          | string | yes       | <empty>        | You will find it in your deployment yaml                                           |
| includeReleaseNameInMetricsLabels | bool   | no        | false          | If set to true then it will add release name in metric label                       |
| deploymentName                    | string | yes       | <empty>        | Your deployment name                                                               |
| prometheusReleaseLabel            | string | no        | nopo11y-stack  |                                                                                    |
| availabilitySLO                   | float  | no        | 99.9           | Threshold for service availability SLO. Value is in percentage                     |
| latencySLO                        | float  | no        | 99             | Threshold for service latency SLO. Value is in percentage                          |
| latency                           | number | no        | 1000           | Threshold for overall api latency alert. Value is in milliseconds                  |
| errorRate5xx                      | float  | no        | 0.05           | Threshold for 5xx error rate alert. Value is in percentage                         |
| errorRate4xx                      | float  | no        | 5              | Threshold for 4xx error rate alert. Value is in percentage                         |
| grafanaURL                        | string | no        | <empty>        | External grafana url, if set then dashboard links will be visible in the alert     |
| logLabel                          | string | no        | <empty>        | If set then logs will be filtered with specified log label in logs dashboard panel |
| logLabelValue                     | string | no        | <empty>        | value for the logLabel                                                             |
| istioMetrics.enabled              | bool   | no        | true           | If true then istio metrics will be visible in prometheus                           |
| nginxIngressMetrics.enabled       | bool   | no        | false          | If true then nginx ingress metrics will be visible in prometheus                   |
| nginxIngressMetrics.ingressName   | string | no        | sample-ingress | Name of the ingress                                                                |
