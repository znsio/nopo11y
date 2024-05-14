# Introduction

NopO11y provides a set of Helm charts that can be used to install and configure observability in your kubernetes cluster.

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
