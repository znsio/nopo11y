# Introduction

Nopo11y is a collection of multiple open-source components charts. It includes following sub-charts:

- kube-prometheus-stack v58.2.2
- thanos v15.4.1
- grafana-loki v4.0.0
- promtail v6.15.5
- sloth v0.7.0
- kiali-server v1.83.0
- jaeger v1.0.0

# Usage

[Helm](https://helm.sh) must be installed to use the charts. Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add znsio https://znsio.github.io/charts

If you had already added this repo earlier, run following command to retrieve the latest versions of the packages,

    helm repo update

You can then run following command to see the available charts,

    helm search repo znsio

To install the <chart-name> chart:

    helm install my-<chart-name> znsio/<chart-name>

To uninstall the chart:

    helm delete my-<chart-name>