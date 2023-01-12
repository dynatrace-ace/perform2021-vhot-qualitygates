keptn auth --endpoint=https://api.keptn.$(kubectl get cm -n keptn keptn-domain -ojsonpath={.data.app_domain}) --api-token=$(kubectl get secret keptn-api-token -n keptn -ojsonpath={.data.keptn-api-token} | base64 --decode)

DT_TENANT=YOUR_TENANT_URL
DT_API_TOKEN=YOUR_API_TOKEN
DT_PAAS_TOKEN=YOUR_PAAS_TOKEN

kubectl -n keptn create secret generic dynatrace --from-literal="DT_TENANT=$DT_TENANT" --from-literal="DT_API_TOKEN=$DT_API_TOKEN"  --from-literal="DT_PAAS_TOKEN=$DT_PAAS_TOKEN"
kubectl apply -f https://raw.githubusercontent.com/keptn-contrib/dynatrace-service/0.7.0/deploy/manifests/dynatrace-service/dynatrace-service.yaml
kubectl apply -f https://raw.githubusercontent.com/keptn-contrib/dynatrace-sli-service/0.4.0/deploy/service.yaml
keptn configure monitoring dynatrace --suppress-websocket
#keptn configure monitoring dynatrace --project=simplenodeproject --suppress-websocket