# Sentry webhook
--------
This program watch for deployment event into k8s cluster and creates project and team into sentry using annotations and inject the project dsn into your deployment as an environment variable. It's a non-blocking mutating webhook with timout of 10s. If project and team already exists then it will fetch dsn and inject into deployment as an environment variable.

## How it works.
---------------

* Deploy the `sentry-webhook` chart, you can find it in charts directory of this repository.

* Annotate your application deployment with following annotations,
```yaml
metadata:
    annotations:
        znsio.nopo11y.com/enable-sentry: "true"
        znsio.nopo11y.com/sentry-team: "my_team"
```
*Note:* Replace `my-team` with the name of your team.

* That's it. You can now use `SENTRY_DSN` environment variable in your application.

## Build docker image
---------------
Dockerfile present in this directory has a instructions for building the docker image.
```sh
docker build -t <your-registry>:<docker-tag> .
```