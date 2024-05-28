import requests
import json
import kh_client
import os
import logging
import sys

logger = logging.getLogger()

handler = logging.StreamHandler(stream=sys.stdout)
formatter = logging.Formatter('%(asctime)s.%(msecs)03d - %(levelname)s - %(message)s', datefmt='%d-%m-%y %I:%M:%S')
handler.setFormatter(formatter)
logger.addHandler(handler)
logger.setLevel(logging.INFO)

logger.info("Starting health check")

prometheus = os.getenv("PROMETHEUS_ENDPOINT", "http://nopo11y-stack-kube-prometh-prometheus:9090")
namespace = os.getenv("NAMESPACE","default")
healthy_pods = os.getenv("HEALTHY_PODS_PERCENTAGE","30")
pod_cpu_threshold = os.getenv("HEALTHY_POD_CPU_UTILIZATION_THRESHOLD","80")
pod_memory_threshold = os.getenv("HEALTHY_POD_MEMORY_UTILIZATION_THRESHOLD", "80")
pvc_threshold = os.getenv("HEALTHY_PVC_FREE_SPACE","200")
node_cpu_threshold = os.getenv("HEALTHY_NODE_CPU_UTILIZATION_THRESHOLD","90")
node_cpu_available = os.getenv("HEALTHY_NODE_CPU_AVAILABLE","400")
node_memory_threshold = os.getenv("HEALTHY_NODE_MEMORY_UTILIZATION_THRESHOLD","90")
node_memory_available = os.getenv("HEALTHY_NODE_MEMORY_AVAILABLE", "1000")
node_disk_available = os.getenv("HEALTHY_NODE_ROOT_DISK_AVAILABLR_SPACE", "200")

prometheus_url = prometheus + '/api/v1/query?'

pods_with_resources_query = 'sum(kube_pod_container_resource_limits{namespace="'+ namespace +'",container!~"istio-proxy|", resource="cpu"}) by (pod) AND sum(kube_pod_container_resource_limits{namespace="'+ namespace +'",container!~"istio-proxy|", resource="memory"}) by (pod)'

def check_pods_with_resources():
    pods = ""
    try:
        response = requests.get(prometheus_url, params={'query': pods_with_resources_query})
        response_json = json.loads(response.text)
        if response_json['data']['result']:
            for result in response_json['data']['result']:
                failed += "|"+ result['metric']['pod']
            return pods
    except Exception as e:
        logger.error("%s Exception occured while checking pods with resources", str(e))
    return pods

pods_with_resources = check_pods_with_resources()

pods_health_query = '''
sum
    (
        ( 
            (
                sum 
                (
                    (
                        (sum(kube_pod_info{pod=~"''' + pods_with_resources + '''", created_by_kind!="Job",namespace="''' + namespace + '''"} * on (pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) by (pod, namespace, deployment)) AND ON (pod, namespace) kube_pod_status_ready{pod=~"''' + pods_with_resources + '''", namespace="''' + namespace + '''", condition="false"} == 0
                    )
                    AND 
                    (
                        sum(rate(container_cpu_usage_seconds_total{pod=~"''' + pods_with_resources + '''", container!~"istio-proxy|",namespace="''' + namespace + '''"}[30m]) * on (pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) by (pod, namespace, deployment) / sum(kube_pod_container_resource_limits{pod=~"''' + pods_with_resources + '''", container!~"istio-proxy|", namespace="''' + namespace + '''", resource="cpu"} * on (pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) by (pod, namespace, deployment) * 100 <= ''' + str(pod_cpu_threshold) + '''
                    ) 
                    AND
                    (
                        sum by (pod, namespace, deployment) (container_memory_working_set_bytes{pod=~"''' + pods_with_resources + '''", container!~"istio-proxy|", namespace="''' + namespace + '''", image!=""} * on (pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) / sum by (pod, namespace, deployment) (kube_pod_container_resource_limits{pod=~"''' + pods_with_resources + '''", container!~"istio-proxy|", namespace="''' + namespace + '''", resource="memory"} * on (namespace, pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) * 100 <= ''' + str(pod_memory_threshold) + '''
                    )
                    OR
                    ( 
                        (
                        sum(kube_pod_status_ready{pod=~"''' + pods_with_resources + '''", namespace="''' + namespace + '''", condition="false"} * on (pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) by (pod, namespace, deployment) == 0 AND ON (pod) kube_pod_info{pod=~"''' + pods_with_resources + '''", namespace="''' + namespace + '''", created_by_kind!="Job"}
                        )
                        OR
                        (
                        sum(kube_pod_status_ready{pod=~"''' + pods_with_resources + '''", namespace="''' + namespace + '''", condition="true"} * on (pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) by (pod, namespace, deployment) == 0 AND ON (pod) kube_pod_info{pod=~"''' + pods_with_resources + '''", namespace="''' + namespace + '''", created_by_kind!="Job"}
                        )
                    )
                ) by (pod, namespace, deployment)
            ) 
        )
        OR
        (
            (
                sum(kube_pod_status_ready{namespace="''' + namespace + '''", condition="true"} * on (pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) by (pod, namespace, deployment) == 1 AND ON (pod) kube_pod_info{namespace="''' + namespace + '''", created_by_kind!="Job"}
            )
            OR
            (
                sum(kube_pod_status_ready{namespace="''' + namespace + '''", condition="true"} * on (pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) by (pod, namespace, deployment) == 0 AND ON (pod) kube_pod_info{namespace="''' + namespace + '''", created_by_kind!="Job"}
            )
        ) 
) by (deployment)
/
(
 sum(kube_deployment_status_replicas{namespace="''' +namespace+ '''"} != 0) by (deployment)
) 
* 
100
<
''' + str(healthy_pods)

pvc_health_query = '(sum(kubelet_volume_stats_available_bytes{namespace="' +namespace+ '"} / 1024 / 1024) by (persistentvolumeclaim)) < '+ str(pvc_threshold)

node_health_query = """
(
    (
    (sum(kube_node_status_condition{condition="Ready", status="true"} * on (node) group_left(instance) label_replace(kube_node_info,"instance", "$1:9100", "internal_ip", "(.*)")) by (instance)) == 1 
    )
    AND 
    (
    (
        100 * avg(1 - rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) <= """ + str(node_cpu_threshold) + """
    )
    AND
    (
        avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * (count (node_cpu_seconds_total{mode="idle"}) by (instance) * 1000) >= """ + str(node_cpu_available) + """
    )
    ) 
    AND
    (
    (
        100 * avg(1 - ((avg_over_time(node_memory_MemFree_bytes[5m]) + avg_over_time(node_memory_Cached_bytes[5m]) + avg_over_time(node_memory_Buffers_bytes[5m])) / avg_over_time(node_memory_MemTotal_bytes[5m] ))) by (instance) <= """ + str(node_memory_threshold) + """
    )
    AND
    (
        (avg(avg_over_time(node_memory_MemFree_bytes[5m]) + avg_over_time(node_memory_Cached_bytes[5m]) + avg_over_time(node_memory_Buffers_bytes[5m])) by (instance) / 1024 / 1024 ) >= """ + str(node_memory_available) + """
    )
    ) 
    AND 
    (

    (sum(node_filesystem_avail_bytes{fstype!="tmpfs",job="node-exporter",mountpoint="/"}) by (instance) / 1024 / 1024 ) >= """ + str(node_disk_available) + """
    ) 
    OR 
    (
    ((sum(kube_node_status_condition{condition="Ready", status="false"} * on (node) group_left(instance) label_replace(kube_node_info,"instance", "$1:9100", "internal_ip", "(.*)")) by (instance)) == 0)
    )
) == 0
"""

pods_details_query = '''
sum
    (
        ( 
            (
                sum 
                (
                    (
                        (sum(kube_pod_info{pod=~"''' + pods_with_resources + '''", created_by_kind!="Job",namespace="''' + namespace + '''"} * on (pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) by (pod, namespace, deployment)) AND ON (pod, namespace) kube_pod_status_ready{pod=~"''' + pods_with_resources + '''", namespace="''' + namespace + '''", condition="false"} == 0
                    )
                    AND 
                    (
                        sum(rate(container_cpu_usage_seconds_total{pod=~"''' + pods_with_resources + '''", container!~"istio-proxy|",namespace="''' + namespace + '''"}[30m]) * on (pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) by (pod, namespace, deployment) / sum(kube_pod_container_resource_limits{pod=~"''' + pods_with_resources + '''", container!~"istio-proxy|", namespace="''' + namespace + '''", resource="cpu"} * on (pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) by (pod, namespace, deployment) * 100 <= ''' + str(pod_cpu_threshold) + '''
                    ) 
                    AND
                    (
                        sum by (pod, namespace, deployment) (container_memory_working_set_bytes{pod=~"''' + pods_with_resources + '''", container!~"istio-proxy|", namespace="''' + namespace + '''", image!=""} * on (pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) / sum by (pod, namespace, deployment) (kube_pod_container_resource_limits{pod=~"''' + pods_with_resources + '''", container!~"istio-proxy|", namespace="''' + namespace + '''", resource="memory"} * on (namespace, pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) * 100 <= ''' + str(pod_memory_threshold) + '''
                    )
                    OR
                    ( 
                        (
                        sum(kube_pod_status_ready{pod=~"''' + pods_with_resources + '''", namespace="''' + namespace + '''", condition="false"} * on (pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) by (pod, namespace, deployment) == 0 AND ON (pod) kube_pod_info{pod=~"''' + pods_with_resources + '''", namespace="''' + namespace + '''", created_by_kind!="Job"}
                        )
                        OR
                        (
                        sum(kube_pod_status_ready{pod=~"''' + pods_with_resources + '''", namespace="''' + namespace + '''", condition="true"} * on (pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) by (pod, namespace, deployment) == 0 AND ON (pod) kube_pod_info{pod=~"''' + pods_with_resources + '''", namespace="''' + namespace + '''", created_by_kind!="Job"}
                        )
                    )
                ) by (pod, namespace, deployment)
            ) 
        ) == 0
        OR
        (
            (
                sum(kube_pod_status_ready{namespace="''' + namespace + '''", condition="true"} * on (pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) by (pod, namespace, deployment) == 1 AND ON (pod) kube_pod_info{namespace="''' + namespace + '''", created_by_kind!="Job"}
            )
            OR
            (
                sum(kube_pod_status_ready{namespace="''' + namespace + '''", condition="true"} * on (pod) group_left (deployment, workload, workload_type) label_replace(namespace_workload_pod:kube_pod_owner:relabel{namespace="''' + namespace + '''", workload_type="deployment"},"deployment", "$1", "workload", "(.*)")) by (pod, namespace, deployment) == 0 AND ON (pod) kube_pod_info{namespace="''' + namespace + '''", created_by_kind!="Job"}
            )
        ) == 0
) by (pod)
'''

def pod_check():
    failed = []
    try:
        response = requests.get(prometheus_url, params={'query': pods_health_query})
        response_json = json.loads(response.text)
        if response_json['data']['result']:
            for result in response_json['data']['result']:
                failed.append(str(result['metric']['deployment']))
            return failed
    except Exception as e:
        logger.error("%s Exception occured while checking pods health", str(e))
    return failed

def pvc_check():
    failed = []
    try:
        response = requests.get(prometheus_url, params={'query': pvc_health_query})
        response_json = json.loads(response.text)
        if response_json['data']['result']:
            for result in response_json['data']['result']:
                failed.append("PVC - "+str(result['metric']['persistentvolumeclaim'])+" has less than 200MB available space")
            return failed
    except Exception as e:
        logger.error("%s Exception occured while checking pvc health", str(e))
    return failed

def node_check():
    failed = []
    try:
        response = requests.get(prometheus_url, params={'query': node_health_query})
        response_json = json.loads(response.text)
        if response_json['data']['result']:
            for result in response_json['data']['result']:
                failed.append("Node - "+ result['metric']['instance'] + " is not healthy")
            return failed
    except Exception as e:
        logger.error("%s Exception occured while checking nodes health", str(e))
    return failed
        

def slo_check():
    failed = []
    try:
        response = requests.get(prometheus_url, params={'query': 'ALERTS{alertname=~".*availability.*|.*requests.*|.*latency.*|.*response time.*", severity="critical"}'})
        response_json = json.loads(response.text)
        if response_json['data']['result']:
            for result in response_json['data']['result']:
                failed.append("SLO - "+ result['metric']['sloth_slo'] + " is having active critical alert")
            return failed
    except Exception as e:
        logger.error("%s Exception occured while checking SLO alerts", str(e))
    return failed

def pods_details():
    failed = []
    failed_deploys = pod_check()
    try:
        if failed_deploys:
            response = requests.get(prometheus_url, params={'query': pods_details_query})
            response_json = json.loads(response.text)
            if response_json['data']['result']:
                for deploy in failed_deploys:
                    pods = []
                    for result in response_json['data']['result']:
                        if str(result['metric']['pod']).startswith(str(deploy)):
                            pods.append(str(result['metric']['pod']))
                    failed.append("Deployment - "+ str(deploy) +" does not have "+ healthy_pods +"% healthy pods, unhealthy pods are "+str(pods))
                return failed
    except Exception as e:
        logger.error("%s Exception occured while checking pods details", str(e))
    return failed
  


def main():
    errors = []
    for failures in [pods_details(), pvc_check(), node_check(), slo_check()]:
        for error in failures:
            errors.append(error)
    logger.info("health check errors %s",  str(errors))

    if len(errors) > 0:
        logger.info("reporting failure")
        try:
            kh_client.report_failure(errors)
        except Exception as e:
            print(f"Error when reporting failure: {e}")
            exit(1)
    else:
        logger.info("reporting success")
        try:
            kh_client.report_success()
        except Exception as e:
            print(f"Error when reporting success: {e}")
            exit(1)
            
if __name__ == '__main__':
    main()