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

# Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

  helm repo add <alias> https://<orgname>.github.io/helm-charts

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
<alias>` to see the charts.

To install the <chart-name> chart:

    helm install my-<chart-name> <alias>/<chart-name>

To uninstall the chart:

    helm delete my-<chart-name>