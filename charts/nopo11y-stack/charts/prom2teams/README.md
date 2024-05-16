# prom2teams

prom2teams is a service built with Python that receives alert notifications from a previously configured Prometheus Alertmanager instance and forwards it to Microsoft Teams using defined connectors.

## Prerequisites

- Namespace should be available - observability
- Outbound internet should be configured in aks route table.
- MS teams channel where the alerts will be sent and incoming webhook url to be added in values file. You can create the webhook url by following [this link](https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook).

## Installation:
```console
$ helm install prom2teams prom2teams --repo https://devopsartifact.jio.com/artifactory/noops_helm_repo -f <your-env>-values.yaml -n observability
```

## Upgrade:
```console
$ helm upgrade --install prom2teams prom2teams --repo https://devopsartifact.jio.com/artifactory/noops_helm_repo -f <your-env>-values.yaml -n observability
```