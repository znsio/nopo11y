## nopo11y-operator

The `nopo11y-operator` is a powerful tool designed to automate the generation of dashboards, Service Level Objectives (SLOs), and alerts for any given service. This operator simplifies the monitoring and observability setup process, ensuring consistent and reliable metrics and alerts for your services.

### Prerequisites

Before you begin, ensure you have met the following requirements:

- Kubernetes cluster (version 1.16 or later)
- `kubectl` installed and configured to interact with your Kubernetes cluster
- `helm` installed
- `nopo11y-stack` installed and running in your cluster

### Installation

To install the `nopo11y-operator`, follow these steps:

1. Clone the repository.

2. Edit the `charts/values.yaml` as per your need. Below are the available options:

| **Key**                 | **Data Type** | **Default**   | **Required?** | **Options**                                 | **Usage**                                                                        |
|-------------------------|---------------|---------------|---------------|---------------------------------------------|----------------------------------------------------------------------------------|
| LOG_LEVEL               | text          | INFO          | No            | WARN, CRITICAL, ERROR, DEBUG, FATAL, NOTSET | Logging level                                                                    |
| API_GATEWAY             | text          | istio         | No            | istio, nginx                                | The gateway you are using. This will be used to generate golden signals and SLOs |
| GRAFANA_EXTERNAL_URL    | text          |               | No            |                                             | External grafana url. If set then you will get dashboard link in alerts.         |
| AVAILABILITY_SLO        | float         | 99            | No            |                                             | Objective for service availability                                               |
| LATENCY_SLO             | float         | 99            | No            |                                             | Objective for service latency                                                    |
| LATENCY_MS              | number        | 3000          | No            |                                             | Used in latency SLO for setting threshold, the value is in milliseconds          |
| ERROR_RATE_4XX          | float         | 5             | No            |                                             | Alert after x% of 4xx errors                                                     |
| ERROR_RATE_5XX          | float         | 0.5           | No            |                                             | Alert after x% of 5xx errors                                                     |
| NOPO11Y_STACK_NAMESPACE | text          | observability | No            |                                             | Nopo11y stack installation namespace                                             |


3. Deploy the operator.
```bash
cd charts/
helm upgrade --install nopo11y-operator .
```

### Usage

To use the `nopo11y-operator` for generating dashboards, SLOs, and alerts, you need to create a custom resource definition (CRD) for your service. Below is an example of how to define a CRD:

```yaml
apiVersion: znsio.nopo11y.com/v1alpha
kind: Nopo11yConfig
metadata:
  name: sample-spec
  namespace: observability
spec:
  defaults:
    alertThresholds:
      errorRate4xx: 5
      errorRate5xx: 0.5
      latencyMs: 2000
    slo:
      availability: 99
      latency: 98
  services:
  - namespace: components
    serviceName: kv001-prodcatapi
    slo:
      latency: 95
    alertThresholds:
      errorRate5xx: 1
  - namespace: components
    serviceName: tmfc001-prodcatmgt
```

If you're looking for the bare minimum configuration then check the below example:
```yaml
apiVersion: znsio.nopo11y.com/v1alpha
kind: Nopo11yConfig
metadata:
  name: sample-spec
  namespace: observability
spec:
  services:
  - namespace: components
    serviceName: kv001-prodcatapi
  - namespace: components
    serviceName: tmfc001-prodcatmgt
```

- Apply the CRD to your cluster:
```bash
kubectl apply -f my-crd.yaml
```

The `nopo11y-operator` will automatically generate the necessary dashboards, SLOs, and alerts based on the specifications provided in the CRD.

### CRD Configuration

- `defaults` are the global defaults for all the services that you define. You can define configs globally or at individual service levels. If nothing is defined at service level then it will use global defaults. If globals are not defined then it will utilise operator level defaults. If that is also not defined then it will use code level defaults. `defaults` are optional.
- `services` are required. `namespace` refers to namespace of the service and `serviceName` refers to the name of the service. You can define below options at service level.

| **Key**                      | **Data Type** | **Usage**                                                               |
|------------------------------|---------------|-------------------------------------------------------------------------|
| slo.availability             | float         | Objective for service availability                                      |
| slo.latency                  | float         | Objective for service latency                                           |
| alertThresholds.errorRate4xx | float         | Alert after x% of 4xx errors                                            |
| alertThresholds.errorRate5xx | float         | Alert after x% of 5xx errors                                            |
| alertThresholds.latencyMs    | number        | Used in latency SLO for setting threshold, the value is in milliseconds |