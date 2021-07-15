#!/bin/bash
set -e

echo "Configure nginx-ingress and Keptn"

# Get Ingress gateway IP-Address
export VM_IP=$(curl -s ifconfig.me)

# Check if IP-Address is not empty or pending
if [ -z "$VM_IP" ] || [ "$VM_IP" = "Pending" ] ; then
 	echo "VM_IP is empty. Make sure that the Ingress gateway is ready"
	exit 1
fi

# Applying ingress-manifest
kubectl apply -f - <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
  name: keptn
  namespace: keptn
spec:
  rules:
  - host: keptn.$VM_IP.nip.io
    http:
      paths:
      - backend:
          serviceName: api-gateway-nginx
          servicePort: 80
EOF