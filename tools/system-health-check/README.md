# System health check
--------

This Kuberhealthy health check program integrates seamlessly with your Kubernetes cluster to provide proactive monitoring using Prometheus. It queries the Prometheus server to:

- Evaluate the health of pods, nodes, and PVCs based on customizable thresholds.
- Detect any critical SLO alerts currently in a firing state.

The health check program reports its findings directly to Kuberhealthy, enabling streamlined observability and alerting within your cluster.

[READ][Kuberhealthy](https://github.com/kuberhealthy/kuberhealthy)


## Supported Checks  
---------------
This Kuberhealthy health check program performs three types of checks: **Namespace**, **Node**, and **SLO**. The type of check to perform is determined by an environment variable (`HEALTH_CHECK_TYPE`). Based on the selected check type, the program functions as follows:  

1. **Namespace Check**  
   - If `HEALTH_CHECK_TYPE` is set to `namespace`, the program validates the health of **pods** and **PVCs** across all deployments within the specified namespace.  
   - The namespace to monitor must be provided via the `NAMESPACE` environment variable.  
   - The health evaluation is based on thresholds defined in the environment variables you set for pod and PVC health.

2. **Node Check**  
   - If `HEALTH_CHECK_TYPE` is set to `node`, the program assesses the health of all **nodes** in the Kubernetes cluster.  
   - It ensures nodes meet the predefined thresholds for node health metrics.

3. **SLO Check**  
   - If `CHECK_TYPE` is set to `slo`, the program verifies if any **critical SLO alerts** are in an active firing state.  
   - This check is particularly useful for ensuring compliance with service-level objectives and identifying critical issues promptly.   

Here's a well-structured explanation of **How the Checks Work** for your README:  

---

## How the Checks Work  
--------------
This program performs detailed health checks based on the selected `HEALTH_CHECK_TYPE`. Below is an explanation of how each check operates:  

### 1. **Namespace Health Check**  
   - **Scope:** Validates the health of pods within all deployments in the specified namespace.  
   - **Checks Performed:**  
     - **Pod Readiness:** Verifies if each pod in the namespace is in a ready state.  
     - **Resource Utilization:** Ensures that each pod's CPU and memory usage is below the defined thresholds:
       - CPU: `HEALTHY_POD_CPU_UTILIZATION_THRESHOLD`
       - Memory: `HEALTHY_POD_MEMORY_UTILIZATION_THRESHOLD`  
     - **Unhealthy Pod Evaluation:** If a pod is not ready or exceeds the CPU/memory thresholds, it is marked as **unhealthy**.  
   - **Deployment Health:**  
     - The program calculates the percentage of healthy vs. unhealthy pods in each deployment.  
     - If the percentage of unhealthy pods exceeds the threshold defined by the `HEALTHY_PODS_PERCENTAGE` environment variable, the deployment is marked **unhealthy**.  
   - **Reporting:** Any unhealthy deployment triggers a failure report to Kuberhealthy.

### 2. **Node Health Check**  
   - **Scope:** Monitors the health of all nodes in the Kubernetes cluster.  
   - **Checks Performed:**  
     - **Node Readiness:** Ensures all nodes are in a ready state.  
     - **Resource Utilization:**  
       - **CPU Utilization:**  
         - Verifies that each node’s CPU utilization is below the threshold set by `HEALTHY_NODE_CPU_UTILIZATION_THRESHOLD`.  
         - Confirms sufficient available CPU (`HEALTHY_NODE_CPU_AVAILABLE`).  
       - **Memory Utilization:**  
         - Ensures each node's memory usage is below the threshold set by `HEALTHY_NODE_MEMORY_UTILIZATION_THRESHOLD`.  
         - Confirms that sufficient memory is available on the node, defined by `HEALTHY_NODE_MEMORY_AVAILABLE`.  
     - **Disk Space:** Validates that the root disk available space on each node meets the minimum requirement defined by `HEALTHY_NODE_ROOT_DISK_AVAILABLE_SPACE`.  
   - **Unhealthy Node Identification:** If any node fails one or more of these checks, it is marked **unhealthy**.  
   - **Reporting:** Unhealthy nodes are reported as failures to Kuberhealthy.  

### 3. **SLO Alert Check**  
   - **Scope:** Monitors for any active **critical SLO alerts** firing in the cluster.  
   - **Checks Performed:**  
     - Queries Prometheus to identify if any critical SLO alert is currently in a firing state.  
   - **Reporting:** If any active SLO alert is detected, it is reported as a failure to Kuberhealthy.  

---

## Customizing the Health Check  
-------------
The behavior of the Kuberhealthy health check can be customized using the following environment variables. These variables allow users to configure thresholds, select check types, and define endpoints for Prometheus or Thanos Query.  

#### **Environment Variables**  

1. **Prometheus/Thanos Configuration**  
   - `PROMETHEUS_ENDPOINT`: URL of the Prometheus server to query metrics from.  
   - `THANOS_QUERY_ENDPOINT`: (Optional) URL of the Thanos Query endpoint, if Thanos is used for metrics aggregation.  

2. **Health Check Type**  
   - `HEALTH_CHECK_TYPE`: Specifies the type of health check to perform. Supported values are:  
     - `namespace`: Check health of deployments within a specific namespace.  
     - `node`: Check health of all nodes in the cluster.  
     - `slo`: Check for active critical SLO alerts.  

3. **Namespace Configuration (for Namespace Check)**  
   - `NAMESPACE`: Specifies the namespace to monitor when `HEALTH_CHECK_TYPE` is set to `namespace`.  

4. **Thresholds for Namespace Health Check**  
   - `HEALTHY_PODS_PERCENTAGE`: Minimum percentage of healthy pods required for a deployment to be considered healthy.  
   - `HEALTHY_POD_CPU_UTILIZATION_THRESHOLD`: Maximum CPU utilization (in percentage) for pods to be considered healthy.  
   - `HEALTHY_POD_MEMORY_UTILIZATION_THRESHOLD`: Maximum memory utilization (in percentage) for pods to be considered healthy.  
   - `HEALTHY_PVC_FREE_SPACE`: Minimum free space (in MB) required for PVCs to be considered healthy.  

5. **Thresholds for Node Health Check**  
   - `HEALTHY_NODE_CPU_UTILIZATION_THRESHOLD`: Maximum CPU utilization (in percentage) for nodes to be considered healthy.  
   - `HEALTHY_NODE_CPU_AVAILABLE`: Minimum available CPU (in milicores) required for nodes to be considered healthy.  
   - `HEALTHY_NODE_MEMORY_UTILIZATION_THRESHOLD`: Maximum memory utilization (in percentage) for nodes to be considered healthy.  
   - `HEALTHY_NODE_MEMORY_AVAILABLE`: Minimum available memory (in MB) required for nodes to be considered healthy.  
   - `HEALTHY_NODE_ROOT_DISK_AVAILABLE_SPACE`: Minimum root disk available space (in MB) required for nodes to be considered healthy.  

---

## Sample Kuberhealthy Checks  
----------
Below are sample configurations for integrating the Kuberhealthy health check with different types of monitoring:  

---------

#### 1. **Namespace Health Check**  
Monitors the health of all deployments within the specified namespace (`apps`) using Prometheus metrics.  

```yaml
apiVersion: comcast.github.io/v1
kind: KuberhealthyCheck
metadata:
  name: apps-nopo11y-health-check
  namespace: observability
spec:
  podSpec:
    containers:
    - env:
      - name: KH_REPORTING_URL
        value: kuberhealthy:80
      - name: PROMETHEUS_ENDPOINT
        value: http://nopo11y-stack-kube-prometh-prometheus:9090/prometheus
      - name: HEALTH_CHECK_TYPE
        value: namespace
      - name: NAMESPACE
        value: apps
      image: ghcr.io/znsio/nopo11y/system-health-check:latest
      imagePullPolicy: IfNotPresent
      name: main
      resources:
        requests:
          cpu: 10m
          memory: 50Mi
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
    securityContext:
      fsGroup: 999
      runAsUser: 999
  runInterval: 1m
  timeout: 5m
```

---

#### 2. **Node Health Check**  
Checks the health of all nodes in the cluster based on Prometheus metrics for CPU, memory, and disk utilization.  

```yaml
apiVersion: comcast.github.io/v1
kind: KuberhealthyCheck
metadata:
  name: nodes-nopo11y-health-check
  namespace: observability
spec:
  podSpec:
    containers:
    - env:
      - name: KH_REPORTING_URL
        value: kuberhealthy:80
      - name: PROMETHEUS_ENDPOINT
        value: http://nopo11y-stack-kube-prometh-prometheus:9090/prometheus
      - name: HEALTH_CHECK_TYPE
        value: node
      image: ghcr.io/znsio/nopo11y/system-health-check:latest
      imagePullPolicy: IfNotPresent
      name: main
      resources:
        requests:
          cpu: 10m
          memory: 50Mi
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
    securityContext:
      fsGroup: 999
      runAsUser: 999
  runInterval: 1m
  timeout: 5m
```

---

#### 3. **SLO Alert Check**  
Checks for any active critical SLO alerts in the cluster using Prometheus and Thanos Query.  

```yaml
apiVersion: comcast.github.io/v1
kind: KuberhealthyCheck
metadata:
  name: slo-nopo11y-health-check
  namespace: observability
spec:
  podSpec:
    containers:
    - env:
      - name: KH_REPORTING_URL
        value: kuberhealthy:80
      - name: PROMETHEUS_ENDPOINT
        value: http://nopo11y-stack-kube-prometh-prometheus:9090/prometheus
      - name: THANOS_QUERY_ENDPOINT
        value: http://nopo11y-stack-thanos-query:9090/thanos-query
      - name: HEALTH_CHECK_TYPE
        value: slo
      image: ghcr.io/znsio/nopo11y/system-health-check:latest
      imagePullPolicy: IfNotPresent
      name: main
      resources:
        requests:
          cpu: 10m
          memory: 50Mi
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
    securityContext:
      fsGroup: 999
      runAsUser: 999
  runInterval: 1m
  timeout: 5m
```

---

These configurations can be customized by updating the environment variables to suit your specific requirements for Prometheus endpoints, thresholds, and check types.