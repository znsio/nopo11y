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