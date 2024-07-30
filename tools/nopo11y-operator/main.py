import os
import uuid
import logging

from copy import deepcopy
from jinja2 import Environment, FileSystemLoader
import kopf
import kubernetes
from kubernetes.client import AppsV1Api, CoreV1Api, CustomObjectsApi
from kubernetes.client.rest import ApiException
import yaml

# Initialize the Kubernetes client
# kubernetes.config.load_kube_config()
kubernetes.config.load_incluster_config()
core_v1_api = CoreV1Api()
apps_v1_api = AppsV1Api()
custom_object_api = CustomObjectsApi()

# Env variables and constants
LOGGING_LEVEL = str(os.getenv("LOG_LEVEL", "INFO"))
API_GATEWAY = str(os.getenv("API_GATEWAY", "istio"))
GRAFANA_URL = str(os.getenv("GRAFANA_EXTERNAL_URL", ""))
DEFAULT_CONFIG = {
    "slo": {
        "availability": float(os.getenv("AVAILABILITY_SLO", "99")),
        "latency": float(os.getenv("LATENCY_SLO", "99"))
    },
    "alertThresholds": {
        "latencyMs": int(os.getenv("LATENCY_MS", "3000")),
        "errorRate4xx": float(os.getenv("ERROR_RATE_4XX", "5")),
        "errorRate5xx": float(os.getenv("ERROR_RATE_5XX", "0.5"))
    }
}
O11Y_NAMEPSACE = str(os.getenv("NOPO11Y_STACK_NAMESPACE", "observability"))

GROUP = "znsio.nopo11y.com"
VERSION = "v1alpha"
COMPONENTS_PLURAL = "nopo11yconfigs"
SLOTH_GROUP = "sloth.slok.dev"
SLOTH_CRD_VERSION = "v1"
PROMETHEUS_GROUP = "monitoring.coreos.com"
PROMETHEUS_CRD_VERSION = "v1"
ALERT_CRD_POSTFIX = "-alert-rules"
AVAILABILITY_SLO_CRD_POSTFIX = "-availability-slo"
LATENCY_CRD_POSTFIX = "-latency-slo"
DASHBOARD_CM_POSTFIX = "-overview-dashboard"

# Logging setup
print(f"Logging set to: {LOGGING_LEVEL}")

kopf_logger = logging.getLogger()
kopf_logger.setLevel(logging.WARNING)

logger = logging.getLogger("Nopo11yOperator")
logger.setLevel(LOGGING_LEVEL)


def get_services():
    """ This will return all the services available inside the k8s cluster """
    try:
        services = core_v1_api.list_service_for_all_namespaces(watch=False)
        return services.items
    except ApiException as e:
        logger.info(f"Exception when calling CoreV1Api->list_service_for_all_namespaces: {e}")
        return []


def get_deployments():
    """ This will return all the deployments available inside the k8s cluster """
    try:
        deployments = apps_v1_api.list_deployment_for_all_namespaces(watch=False)
        return deployments.items
    except ApiException as e:
        logger.info(f"Exception when calling AppsV1Api->list_deployment_for_all_namespaces: {e}")
        return []


def match_service_to_deployment(service, deployments):
    """ This will return the deployment name for the given service using the selector labels """
    namespace = service.metadata.namespace
    selector = service.spec.selector
    if not selector:
        return None

    selector_items = set(selector.items())

    for deployment in deployments:
        if deployment.metadata.namespace != namespace:
            continue

        deployment_labels = deployment.spec.selector.match_labels
        if not deployment_labels:
            continue

        deployment_label_items = set(deployment_labels.items())
        if selector_items.issubset(deployment_label_items) or deployment_label_items.issubset(selector_items):
            return deployment.metadata.name

    return None


def get_service_deployment_map(service=None):
    """ This will return servicename => deployment map by calling k8s apis """
    services = get_services()
    deployments = get_deployments()
    results = {}

    for service in services:
        namespace = service.metadata.namespace
        service_name = service.metadata.name
        deployment_name = match_service_to_deployment(service, deployments)

        if deployment_name:
            results[f"{namespace}/{service_name}"] = f"{deployment_name}"

    return results


@kopf.on.startup()
def configure(settings: kopf.OperatorSettings, **_):
    """ This function overwrites default kopf operator configuration """
    settings.watching.client_timeout = 4 * 60


@kopf.on.create(GROUP, VERSION, COMPONENTS_PLURAL)
@kopf.on.update(GROUP, VERSION, COMPONENTS_PLURAL)
@kopf.on.resume(GROUP, VERSION, COMPONENTS_PLURAL)
def generate_dashboard_alerts(spec, namespace, old, new, **kwargs):
    """ This function will generate dashboards, slos and alert rules for your service """
    old = old if isinstance(old, dict) and old else {}
    new = new if isinstance(new, dict) and new else {}

    spec_dict = dict(spec)
    old_spec, new_spec = transform_spec(old, new)
    if old_spec == new_spec:
        logger.info("There is no change in specs, skipping")
        return

    deleted_svc_list = set(old_spec.keys()) - set(new_spec.keys())
    if deleted_svc_list:
        delete_service_nopo11y(deleted_svc_list)

    environment = Environment(loader=FileSystemLoader("templates/"))
    try:
        alert_template = environment.get_template("nopo11y-op-alerts.yaml")
        dashboard_template = environment.get_template("nopo11y-op-dashboard.yaml")
        availabilty_slo_template = environment.get_template("nopo11y-op-slo-availability.yaml")
        latency_slo_template = environment.get_template("nopo11y-op-slo-latency.yaml")
    except Exception as e:
        logger.info(f"Unable to find templates inside 'templates/' directory, error: {e}")
        raise

    svc_deploy_map = get_service_deployment_map()
    default_slo_availability = spec_dict.get("defaults", {}).get("slo", {}).get("availability") or DEFAULT_CONFIG["slo"]["availability"]
    default_slo_latency = spec_dict.get("defaults", {}).get("slo", {}).get("latency") or DEFAULT_CONFIG["slo"]["latency"]
    default_4xx_rate = spec_dict.get("defaults", {}).get("alertThresholds", {}).get("errorRate4xx") or DEFAULT_CONFIG["alertThresholds"]["errorRate4xx"]
    default_5xx_rate = spec_dict.get("defaults", {}).get("alertThresholds", {}).get("errorRate5xx") or DEFAULT_CONFIG["alertThresholds"]["errorRate5xx"]
    default_latency = spec_dict.get("defaults", {}).get("alertThresholds", {}).get("latencyMs") or DEFAULT_CONFIG["alertThresholds"]["latencyMs"]

    for service in spec_dict.get("services", []):
        service_name = service.get("serviceName")
        if new_spec.get(service_name) == old_spec.get(service_name) and \
            old.get("defaults") == new.get("defaults"):
            logger.info(f"Found no changes for following service: {service_name}")
            continue

        service_namespace = service.get("namespace")
        deployment_name = service.get("deploymentName") or svc_deploy_map.get(f"{service_namespace}/{service_name}")
        cluster_name = service.get("clusterName")
        slo_availability = service.get("slo", {}).get("availability") or default_slo_availability
        slo_latency = service.get("slo", {}).get("latency") or default_slo_latency
        alert_4xx = service.get("alertThresholds", {}).get("errorRate4xx") or default_4xx_rate
        alert_5xx = service.get("alertThresholds", {}).get("errorRate5xx") or default_5xx_rate
        alert_latency = service.get("alertThresholds", {}).get("latencyMs") or default_latency
        dashboard_uuid = uuid.uuid4().hex
        patch_service = service_name in old_spec

        if not deployment_name:
            logger.info(f"Unable to find deployment name for the given namespace: {service_namespace} and serviceName: {service}")
            continue

        alert_manifest = alert_template.render(
            namespace=O11Y_NAMEPSACE,
            apiGateway=API_GATEWAY,
            grafanaUrl=GRAFANA_URL,
            service=service_name,
            serviceNamespace=service_namespace,
            cluster=cluster_name,
            dashboarduid=dashboard_uuid,
            rate5xx=alert_5xx,
            rate4xx=alert_4xx
        )
        if patch_service:
            update_custom_obj(PROMETHEUS_GROUP, PROMETHEUS_CRD_VERSION, service_name+ALERT_CRD_POSTFIX, O11Y_NAMEPSACE, "prometheusrules", alert_manifest)
        else:
            create_custom_obj(PROMETHEUS_GROUP, PROMETHEUS_CRD_VERSION, O11Y_NAMEPSACE, "prometheusrules", alert_manifest)

        availabilty_slo_manifest = availabilty_slo_template.render(
            namespace=O11Y_NAMEPSACE,
            apiGateway=API_GATEWAY,
            grafanaUrl=GRAFANA_URL,
            service=service_name,
            serviceNamespace=service_namespace,
            cluster=cluster_name,
            latencyThreshold=alert_latency,
            availability=slo_availability,
        )
        if patch_service:
            update_custom_obj(SLOTH_GROUP, SLOTH_CRD_VERSION, service_name+AVAILABILITY_SLO_CRD_POSTFIX, O11Y_NAMEPSACE, "prometheusservicelevels", availabilty_slo_manifest)
        else:
            create_custom_obj(SLOTH_GROUP, SLOTH_CRD_VERSION, O11Y_NAMEPSACE, "prometheusservicelevels", availabilty_slo_manifest)

        latency_slo_manifest = latency_slo_template.render(
            namespace=O11Y_NAMEPSACE,
            apiGateway=API_GATEWAY,
            grafanaUrl=GRAFANA_URL,
            service=service_name,
            serviceNamespace=service_namespace,
            cluster=cluster_name,
            latencyThreshold=alert_latency,
            latency=slo_latency
        )
        if patch_service:
            update_custom_obj(SLOTH_GROUP, SLOTH_CRD_VERSION, service_name+LATENCY_CRD_POSTFIX, O11Y_NAMEPSACE, "prometheusservicelevels", latency_slo_manifest)
        else:
            create_custom_obj(SLOTH_GROUP, SLOTH_CRD_VERSION, O11Y_NAMEPSACE, "prometheusservicelevels", latency_slo_manifest)

        dashboard_manifest = dashboard_template.render(
            namespace=O11Y_NAMEPSACE,
            apiGateway=API_GATEWAY,
            service=service_name,
            cluster=cluster_name,
            deployment=deployment_name,
            deploymentNamespace=service_namespace,
            dashboarduid=dashboard_uuid,
        )
        if patch_service:
            update_configmap(service_name+DASHBOARD_CM_POSTFIX, O11Y_NAMEPSACE, dashboard_manifest)
        else:
            create_configmap(O11Y_NAMEPSACE, dashboard_manifest)

        logger.info(f"Updated resources for following service: {service_name}")


def update_custom_obj(group, version, name, namespace, plural, body, **kwargs):
    """ This will patch the custom object in the k8s cluster """
    try:
        yaml_body = yaml.safe_load(body)
    except Exception as e:
        logger.info(f"Error while converting the str to yaml, error {e}")
    kopf.adopt(yaml_body)
    try:
        custom_object_api.patch_namespaced_custom_object(
            group=group,
            version=version,
            name=name,
            namespace=namespace,
            plural=plural,
            body=yaml_body,
            **kwargs
        )
    except Exception as e:
        logger.info(f"Error while patching the custom object name: {name}, error: {e}")
    return True


def create_custom_obj(group, version, namespace, plural, body, **kwargs):
    """ This will create the custom object in the k8s cluster """
    try:
        yaml_body = yaml.safe_load(body)
    except Exception as e:
        logger.info(f"Error while converting the str to yaml, error {e}")
    kopf.adopt(yaml_body)
    try:
        custom_object_api.create_namespaced_custom_object(
            group=group,
            version=version,
            namespace=namespace,
            plural=plural,
            body=yaml_body,
            **kwargs
        )
    except Exception as e:
        logger.info(f"Error while creating the custom object, error: {e}")
    return True


def create_configmap(namespace, body):
    """ This will create the configmap in the k8s cluster """
    try:
        yaml_body = yaml.safe_load(body)
    except Exception as e:
        logger.info(f"Error while converting the str to yaml, error {e}")
    kopf.adopt(yaml_body)
    try:
        core_v1_api.create_namespaced_config_map(namespace=namespace, body=yaml_body)
    except Exception as e:
        logger.info(f"Error while creating the configmap, error: {e}")
    return True


def update_configmap(name, namespace, body):
    """ This will patch the configmap in the k8s cluster """
    try:
        yaml_body = yaml.safe_load(body)
    except Exception as e:
        logger.info(f"Error while converting the str to yaml, error {e}")
    kopf.adopt(yaml_body)
    try:
        core_v1_api.patch_namespaced_config_map(name=name, namespace=namespace, body=yaml_body)
    except Exception as e:
        logger.info(f"Error while patching the configmap name: {name}, error: {e}")
    return True


def transform_spec(old=None, new=None):
    """ This will extract the services from the old and new specs and add them to the new map and return those maps """
    old_spec = deepcopy(old)
    old_spec["spec"] = {}
    for service in old.get("spec", {}).get("services", []):
        old_spec["spec"][service["serviceName"]] = service

    new_spec = deepcopy(new)
    new_spec["spec"] = {}
    for service in new.get("spec", {}).get("services", []):
        new_spec["spec"][service["serviceName"]] = service

    return old_spec["spec"], new_spec["spec"]


def delete_service_nopo11y(service_list):
    """ This will delete the resources created by nopo11y operator for the given services """
    logger.info(f"List of services for which the nopo11y resources needs to be deleted: {service_list}")
    for service in service_list:
        try:
            custom_object_api.delete_namespaced_custom_object(
                group=PROMETHEUS_GROUP,
                version=PROMETHEUS_CRD_VERSION,
                name=service+ALERT_CRD_POSTFIX,
                namespace=O11Y_NAMEPSACE,
                plural="prometheusrules",
            )
        except Exception as e:
            logger.info(f"Error while deleting the alert prometheusrules crd created by nopo11y operator for the following service: {service}, error: {e}")

        try:
            custom_object_api.delete_namespaced_custom_object(
                group=SLOTH_GROUP,
                version=SLOTH_CRD_VERSION,
                name=service+AVAILABILITY_SLO_CRD_POSTFIX,
                namespace=O11Y_NAMEPSACE,
                plural="prometheusservicelevels",
            )
        except Exception as e:
            logger.info(f"Error while deleting the availability prometheusservicelevels crd created by nopo11y operator for the following service: {service}, error: {e}")

        try:
            custom_object_api.delete_namespaced_custom_object(
                group=SLOTH_GROUP,
                version=SLOTH_CRD_VERSION,
                name=service+LATENCY_CRD_POSTFIX,
                namespace=O11Y_NAMEPSACE,
                plural="prometheusservicelevels",
            )
        except Exception as e:
            logger.info(f"Error while deleting the latency prometheusservicelevels crd created by nopo11y operator for the following service: {service}, error: {e}")

        try:
            core_v1_api.delete_namespaced_config_map(namespace=O11Y_NAMEPSACE, name=service+DASHBOARD_CM_POSTFIX)
        except Exception as e:
            logger.info(f"Error while deleting the dashboard configmap created by nopo11y operator for the following service: {service}, error: {e}")

        logger.info(f"Deleted nopo11y resources for the following service: {service}")
    return True
