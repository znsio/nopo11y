from fastapi import FastAPI, Request
import base64
import json
import os
import logging
import logging.config
import requests

# Constants (replace with your actual values)
LOGGING_LEVEL = str(os.getenv("LOG_LEVEL", "INFO"))
SENTRY_API_TOKEN = str(os.getenv("SENTRY_API_TOKEN", ""))
SENTRY_ORG_SLUG = str(os.getenv("SENTRY_ORG_SLUG", ""))
TEAM_NAME = str(os.getenv("DEFAULT_TEAM", ""))
BASE_URL = str(os.getenv("SENTRY_HOST_URL", ""))

SENTRY_META_KEY = "znsio.nopo11y.com/enable-sentry"
SENTRY_TEAM_META_KEY = "znsio.nopo11y.com/sentry-team"

ENV_VAR_NAME = "SENTRY_DSN"

# Headers
headers = {
    'Authorization': f'Bearer {SENTRY_API_TOKEN}',
    'Content-Type': 'application/json',
}

LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": True,
    "formatters": {
        "standard": {"format": "%(asctime)s [%(levelname)s] %(name)s: %(message)s"},
    },
    "handlers": {
        "default": {
            "level": "INFO",
            "formatter": "standard",
            "class": "logging.StreamHandler",
            "stream": "ext://sys.stdout",  # Default is stderr
        },
    },
    "loggers": {
        "": {  # root logger
            "level": LOGGING_LEVEL, #"INFO",
            "handlers": ["default"],
            "propagate": False,
        },
        "uvicorn.error": {
            "level": "DEBUG",
            "handlers": ["default"],
        },
        "uvicorn.access": {
            "level": "DEBUG",
            "handlers": ["default"],
        },
    },
}

logging.config.dictConfig(LOGGING_CONFIG)
logger = logging.getLogger(__name__)

app = FastAPI()


@app.post("/mutate")
async def mutate(request: Request):
    # Parse the AdmissionReview request
    admission_review = await request.json()

    # Extract the object (pod template within the Deployment) being mutated
    request_object = admission_review['request']['object']
    
    # Initialize the patch list
    patch = []

    # Check if the specific annotation is present in the Deployment metadata
    if "annotations" in request_object["metadata"] and \
       request_object["metadata"]["annotations"].get(SENTRY_META_KEY) == "true":

        team = request_object["metadata"]["annotations"].get(SENTRY_TEAM_META_KEY, TEAM_NAME)
        deployment_name = request_object["metadata"]["name"]
        project_dsn = fetch_project_dsn(deployment_name) or ""

        team_exists = create_team(team)
        if not team_exists:
            logger.error("Unable to create the team: {team}")
            return

        if not project_dsn:
            logger.info(f"Unable to find project, creating new project: {deployment_name}")
            project = create_project(team, deployment_name)
            if project:
                logger.info(f"Following project has been created: {deployment_name}")
                project_dsn = fetch_project_dsn(deployment_name)

        logger.info(f"After project creation::Project dsn: {project_dsn}, Deployment name: {deployment_name}")
        logger.info("Injecting sentry dsn into deployment environment variables")

        # Iterate over each container in the pod spec
        for idx, container in enumerate(request_object["spec"]["template"]["spec"]["containers"]):
            # Path to the container's env array in the JSON structure
            env_path = f"/spec/template/spec/containers/{idx}/env"

            # Check if the environment variable already exists
            env_vars = container.get("env", [])
            env_var_exists = False
            for env_idx, env_var in enumerate(env_vars):
                if env_var["name"] == ENV_VAR_NAME:
                    # Environment variable exists, create a patch to update it
                    patch.append({
                        "op": "replace",
                        "path": f"{env_path}/{env_idx}/value",
                        "value": project_dsn
                    })
                    env_var_exists = True
                    break

            # If the environment variable doesn't exist, create a patch to add it
            if not env_var_exists:
                if "env" not in container:
                    # Add env array if it doesn't exist
                    patch.append({
                        "op": "add",
                        "path": env_path,
                        "value": [
                            {
                                "name": ENV_VAR_NAME,
                                "value": project_dsn
                            }
                        ]
                    })
                else:
                    # Append to the existing env array
                    patch.append({
                        "op": "add",
                        "path": f"{env_path}/-",
                        "value": {
                            "name": ENV_VAR_NAME,
                            "value": project_dsn
                        }
                    })


    # Create the patch as a JSONPatch
    patch_json = json.dumps(patch)
    patch_base64 = base64.b64encode(patch_json.encode()).decode()

    # AdmissionReview response
    admission_response = {
        "uid": admission_review['request']['uid'],
        "allowed": True,
        "patchType": "JSONPatch",
        "patch": patch_base64
    }

    # Return the AdmissionReview response with the patch
    return {
        "apiVersion": "admission.k8s.io/v1",
        "kind": "AdmissionReview",
        "response": admission_response
    }


# Create a new project
def create_project(team_slug: str, project_name: str):
    url = f'{BASE_URL}/teams/{SENTRY_ORG_SLUG}/{team_slug}/projects/'
    data = {
        'name': project_name
    }
    response = requests.post(url, json=data, headers=headers, verify=True)
    logger.debug(f"create_project::response.status_code: {response.status_code}")
    logger.debug(f"create_project::respons.text: {response.text}")
    return response.status_code == 201


# Delete a project
# def delete_project(project_slug):
#     url = f'{BASE_URL}/projects/{SENTRY_ORG_SLUG}/{project_slug}/'
#     response = requests.delete(url, headers=headers, verify=True)
#     logger.debug(f"delete_project::response.status_code {response.status_code}")
#     logger.debug(f"delete_project::response.text {response.text}")
#     return response.status_code == 204


# Fetch project DSN
def fetch_project_dsn(project_slug: str):
    if not project_slug:
        logger.error(f"fetch_project_dsn::invalid project_slug: {project_slug}")
        return False

    url = f'{BASE_URL}/projects/{SENTRY_ORG_SLUG}/{project_slug}/keys/'
    response = requests.get(url, headers=headers, verify=True)
    logger.debug(f"fetch_project_dsn::response.status_code {response.status_code}")
    logger.debug(f"fetch_project_dsn::response.text {response.text}")
    if response.status_code == 200:
        logger.info(f"Project with name: {project_slug} found in {SENTRY_ORG_SLUG} organization in Sentry")
        keys = response.json()
        if keys:
            return keys[0].get('dsn', {}).get('public')

    return False

# Create a new team
def create_team(team_slug: str):
    url = f'{BASE_URL}/organizations/{SENTRY_ORG_SLUG}/teams/'
    data = {
        'slug': team_slug
    }
    response = requests.post(url, json=data, headers=headers, verify=True)
    logger.debug(f"create_team::response.status_code {response.status_code}")
    logger.debug(f"create_team::response.text {response.text}")
    return response.status_code in {201, 409}


# Run the FastAPI app with SSL
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=9443, ssl_keyfile="/certs/key", ssl_certfile="/certs/cert")
