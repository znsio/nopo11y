# Deployment Commands

cd charts/

helm upgrade --install sentry-webhook . -n canvas -f environments/prod-values.yaml