# System health check
--------
This program queries the prometheus running inside or outside of your cluster and check for pods, pvcs and nodes health, it also checks for SLO alerts configured in your environment (using sloth) and reports the status to the kuberhealthy.

[READ][Kuberhealthy](https://github.com/kuberhealthy/kuberhealthy)


## How it works.
---------------


### Pod health check
It checks for the pod's readiness, CPU utilization and Memory utilization and mark pod as unhealthy if pod is not in ready state or pod's CPU or Memory utilization is above configured threshold (default is 80%), if all of these checks are ok then it mark that pod as healthy, then it checks for pods expected by the deployment against the healthy pods of that deployment, if the percentage of healthy pods of the deployment is lesser than the configured threshold (by default 30%) then it mark that deployment as un healthy and report the failure

### PVC health check
It checks for the avialable space of PVCs, if the available space on PVC is less than configured threshold (default is  200mb) then it marks that PVC as unhealthy and resports the failur.

### Node health Check
It checks for the node readiness, root disk space of node, CPU and Memory utilization of the node and mark node unhealthy if the node is not in ready state or root disk space of node is lesser than the configured thresold (default 200mb) or CPU or Memory utilization of node is above the configured threshold (default 80% and 400m CPU available and 1000mb Memory available), if all of these checks or ok then it mark that node as healthy, if it find any unhealthy node then it reports the failure.

### SLO alert check
It checks if any critical SLO alerts are in active state, if it find any active critical SLO alert then it reports the failure
[READ][Sloth SLOs](https://sloth.dev/)

## How to configure
--------
This health check program except below environment variables, if you don't provide any it takes default values.

|Environment Variables|Default|Description|
|---------------------|-------|-----------|
|PROMETHEUS_ENDPOINT|http://nopo11y-stack-kube-prometh-prometheus:9090|Prometheus URL on which you want to run your queries|
|NAMESPACE|default|Kubernetes namespace where you have your services deployed|
|HEALTHY_PODS_PERCENTAGE|30%|Percentage of healthy pods for deployments in give namespace|
|HEALTHY_POD_CPU_UTILIZATION_THRESHOLD|80%|CPU utilization threshold for healthy pods|
|HEALTHY_POD_MEMORY_UTILIZATION_THRESHOLD|80%|Memory utilization threshold for healthy pods|
|HEALTHY_PVC_FREE_SPACE|200mb|Available space threshold for healthy pvcs|
|HEALTHY_NODE_CPU_UTILIZATION_THRESHOLD|90%|CPU utilization for healthy nodes|
|HEALTHY_NODE_CPU_AVAILABLE|400m|CPU milicores available for healthy nodes|
|HEALTHY_NODE_MEMORY_UTILIZATION_THRESHOLD|90%|Memory utilization threshold for healthy nodes|
|HEALTHY_NODE_MEMORY_AVAILABLE|1000mb|Free Memory in mbs for healthy nodes|
|HEALTHY_NODE_ROOT_DISK_AVAILABLR_SPACE|200mb|Free space available on node's root disk in mbs for healthy nodes|

[Check][Example](./examples/health-check.yaml)


## Build docker image
---------------
Dockerfile present in this directory has a instructions for building the docker image.
```sh
docker build -t <your-registry>:<docker-tag> .
```