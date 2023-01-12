#!/usr/bin/env bash

set -euo pipefail

export DT_TENANT=$(cat ~/creds.json | jq -r .dynatraceTenant)
export DT_API_TOKEN=$(cat ~/creds.json | jq -r .dynatraceApiToken)
export DT_PAAS_TOKEN=$(cat ~/creds.json | jq -r .dynatracePaasToken)

# Create dynatrace secret
kubectl -n keptn create secret generic dynatrace --from-literal="DT_TENANT=$DT_TENANT" --from-literal="DT_API_TOKEN=$DT_API_TOKEN" --from-literal="KEPTN_API_URL=$KEPTN_ENDPOINT" --from-literal="KEPTN_API_TOKEN=$(kubectl get secret keptn-api-token -n keptn -ojsonpath='{.data.keptn-api-token}' | base64 --decode)" --from-literal="KEPTN_BRIDGE_URL=$KEPTN_BRIDGE"

# Create dynatrace service
kubectl apply -n keptn -f https://raw.githubusercontent.com/keptn-contrib/dynatrace-service/0.10.0/deploy/service.yaml
kubectl -n keptn rollout status -w deployment.apps/dynatrace-service

# This is needed for when the dynatrace secret values are changed
echo "Deleting pod..."
kubectl -n keptn delete po -l run=dynatrace-service

echo "Waiting for Dynatrace service to be available..."
sleep 60

# Configure dynatrace monitoring for keptn
keptn configure monitoring dynatrace

# Confirm dynatrace service is running
kubectl get svc dynatrace-service -n keptn
