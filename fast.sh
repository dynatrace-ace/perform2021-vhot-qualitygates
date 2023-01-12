

keptn install --endpoint-service-type=ClusterIP 
./bootstrap/box/scripts/exposeKeptn.sh
export KEPTN_ENDPOINT=http://$(kubectl -n keptn get ingress keptn -ojsonpath='{.spec.rules[0].host}')/api
export KEPTN_API_TOKEN=$(kubectl get secret keptn-api-token -n keptn -ojsonpath={.data.keptn-api-token} | base64 --decode)
keptn auth --endpoint=$KEPTN_ENDPOINT --api-token=$KEPTN_API_TOKEN
 
export KEPTN_BRIDGE=http://$(kubectl -n keptn get ingress keptn -ojsonpath='{.spec.rules[0].host}')/bridge
echo $KEPTN_BRIDGE
keptn configure bridge --output

./bootstrap/box/scripts/installDynatraceServiceForKeptn.sh
kubectl apply -n keptn -f https://raw.githubusercontent.com/keptn-contrib/dynatrace-sli-service/0.7.0/deploy/service.yaml 