**Note** - If you have nopo11y-stack >= 1.3.1 installed then you don't have to use nopo11y helm chart, the nopo11y-stack has nopo11y-operator which is a replacement of nopo11y helm chart, please check [this](https://github.com/znsio/nopo11y/tree/main/tools/nopo11y-operator) to know more about nopo11y-operator
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
To add it as a dependency in your service's chart add below lines in your service's Chart.yaml file
```yaml
dependencies:
- condition: nopo11y.enabled
  name: nopo11y
  repository: https://znsio.github.io/nopo11y
  version: 2.1.0
``` 
# Configuration

| Key                               | Type   | Required? | Default        | Description                                                                        |
|-----------------------------------|--------|-----------|----------------|------------------------------------------------------------------------------------|
| enabled                           | bool   | no        | false          | If set to true then it will create default dashboard, alerts and SLOs              |
| namespace                         | string | no        | observability  | Use the same namespace as you used during the installation of nopo11y stack        |
| defaults                         | map | no       | -      | Default values for SLO objective and alert thresholds for all services                                           |
| prependReleaseName | bool   | no        | false          | If set to true then it will prepend release name to service and deployment name                       |
| grafanaURL            | string | no        | empty  |  External grafana URL                                                                       |
| apiGateway | string | yes | istio | Which api gateway metrics to use, allowed values istio, nginx |
| services | array | yes | - | list of services for which you want to create dashboard, alerts and SLOs |

# Sample values
```yaml
enabled: false

defaults:
  slo:
    availability: 99.9
    latency: 99
  alertThresholds:
    latencyMS: 100
    rate5xx: 0.05
    rate4xx: 5

namespace: observability

prependReleaseName: false

grafanaURL: "https://observability.grafana.com"

apiGateway: "istio"

services:
- serviceName: "sample"
  deploymentName: "sample"
  namespace: "sample"
  slo: 
    availability: 99.9
    latency: 99
 
  alertThresholds: 
    latencyMS: 100
    rate4xx: 5
    rate5xx: 0.05
```