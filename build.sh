##########################################
#  VARIABLES                             #
##########################################
monaco_version="v1.1.0" 
domain="nip.io"
jenkins_chart_version="3.3.18"
git_org="perform"
git_repo="perform"
git_user="dynatrace"
git_pwd="dynatrace"
git_email="perform2021@dt-perform.com"
shell_user="ace"
keptn_version=0.7.2

app1Repo="carts"
releaseBranchPipeline="jenkins-release-branch"
stagingPipelineRepo="k8s-deploy-staging"

# These need to be set as environment variables prior to launching the script
#export DYNATRACE_ENVIRONMENT_ID=     # only the environmentid (abc12345) is needed. script assumes a sprint tenant 
##for testing purposes using a full tenant url
#export DYNATRACE_TOKEN=              # for Perform vHOT we get a token that is both an API and PaaS token

##########################################
#  DO NOT MODIFY ANYTHING IN THIS SCRIPT #
##########################################

home_folder=$1
clone_folder=$2
source_repo=$3

echo "variables"
echo $home_folder
echo $clone_folder
echo $source_repo

echo "Installing packages"
sudo snap install jq 
sudo snap install docker
sudo chmod 777 /var/run/docker.sock

# Create Dynatrace Tokens
printf "Creating PAAS Token for Dynatrace Environment ${DT_CLUSTER_URL}/e/$DT_ENVIRONMENT_ID\n\n"

paas_token_body='{
                    "scopes": [
                        "InstallerDownload"
                    ],
                    "name": "vhot-qgs-paas"
                  }'

DT_PAAS_TOKEN_RESPONSE=$(curl -k -s --location --request POST "${DT_CLUSTER_URL}/e/$DT_ENVIRONMENT_ID/api/v2/apiTokens" \
--header "Authorization: Api-Token $DT_ENVIRONMENT_TOKEN" \
--header "Content-Type: application/json" \
--data-raw "${paas_token_body}")
DYNATRACE_PAAS_TOKEN=$(echo $DT_PAAS_TOKEN_RESPONSE | jq -r '.token' )

printf "Creating API Token for Dynatrace Environment ${DT_CLUSTER_URL}/e/$DT_ENVIRONMENT_ID\n\n"

api_token_body='{
                "scopes": [
                    "DataExport", "PluginUpload", "DcrumIntegration", "AdvancedSyntheticIntegration", "ExternalSyntheticIntegration", 
                    "LogExport", "ReadConfig", "WriteConfig", "DTAQLAccess", "UserSessionAnonymization", "DataPrivacy", "CaptureRequestData", 
                    "Davis", "DssFileManagement", "RumJavaScriptTagManagement", "TenantTokenManagement", "ActiveGateCertManagement", "RestRequestForwarding", 
                    "ReadSyntheticData", "DataImport", "auditLogs.read", "metrics.read", "metrics.write", "entities.read", "entities.write", "problems.read", 
                    "problems.write", "networkZones.read", "networkZones.write", "activeGates.read", "activeGates.write", "credentialVault.read", "credentialVault.write", 
                    "extensions.read", "extensions.write", "extensionConfigurations.read", "extensionConfigurations.write", "extensionEnvironment.read", "extensionEnvironment.write", 
                    "metrics.ingest", "securityProblems.read", "securityProblems.write", "syntheticLocations.read", "syntheticLocations.write", "settings.read", "settings.write", 
                    "tenantTokenRotation.write", "slo.read", "slo.write", "releases.read", "apiTokens.read", "apiTokens.write", "logs.read", "logs.ingest"
                ],
                "name": "vhot-qgs-api-token"
                }'

DT_API_TOKEN_RESPONSE=$(curl -k -s --location --request POST "${DT_CLUSTER_URL}/e/$DT_ENVIRONMENT_ID/api/v2/apiTokens" \
--header "Authorization: Api-Token $DT_ENVIRONMENT_TOKEN" \
--header "Content-Type: application/json" \
--data-raw "${api_token_body}")
DYNATRACE_TOKEN=$(echo $DT_API_TOKEN_RESPONSE | jq -r '.token' )

echo "Retrieving Dynatrace Environment details"
# IMPORTANT! This values should be already in place before executing this script. 
# export DYNATRACE_ENVIRONMENT_ID="https://test.live.dynatrace.com/"
# export DYNATRACE_TOKEN="tokenid"
# export DYNATRACE_PAAS_TOKEN="paas token"

DT_TENANT="$DT_CLUSTER_URL/e/$DT_ENVIRONMENT_ID"

echo "Virtual machine IP: $VM_IP"

ingress_domain="$VM_IP.$domain"
echo "Ingress domain: $ingress_domain"

cd 
#chown -R dtu_training:dtu_training /home/dtu_training/
##############################
# Download Monaco + add PATH #
##############################
# wget https://github.com/dynatrace-oss/dynatrace-monitoring-as-code/releases/download/v1.0.1/monaco-linux-amd64 -O $home_folder/monaco
# chmod +x $home_folder/monaco
# cp $home_folder/monaco /usr/local/bin



##############################
# Install k3s and Helm       #
##############################

echo "Installing k3s"
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.18.3+k3s1 K3S_KUBECONFIG_MODE="644" sh -s - --no-deploy=traefik
echo "Waiting 30s for kubernetes nodes to be available..."
sleep 30
# Use k3s as we haven't setup kubectl properly yet
k3s kubectl wait --for=condition=ready nodes --all --timeout=60s
# Force generation of $home_folder/.kube
kubectl get nodes
# Configure kubectl so we can use "kubectl" and not "k3 kubectl"
cp /etc/rancher/k3s/k3s.yaml $home_folder/.kube/config
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "Installing Helm"
sudo snap install helm --classic
helm repo add stable https://charts.helm.sh/stable
helm repo add incubator https://charts.helm.sh/incubator

##############################
# Install Dynatrace OneAgent #
##############################
echo "Dynatrace OneAgent - Install"
kubectl create namespace dynatrace
helm repo add dynatrace https://raw.githubusercontent.com/Dynatrace/helm-charts/master/repos/stable
sed \
    -e "s|DYNATRACE_ENVIRONMENT_PLACEHOLDER|$DT_TENANT|"  \
    -e "s|DYNATRACE_TOKEN_PLACEHOLDER|$DYNATRACE_TOKEN|g"  \
    -e "s|DYNATRACE_PAAS_TOKEN_PLACEHOLDER|$DYNATRACE_PAAS_TOKEN|g"  \
    $home_folder/$clone_folder/box/helm/oneagent-values.yml > $home_folder/$clone_folder/box/helm/oneagent-values-gen.yml

helm install dynatrace-oneagent-operator dynatrace/dynatrace-oneagent-operator -n dynatrace --values $home_folder/$clone_folder/box/helm/oneagent-values-gen.yml --wait

# Wait for Dynatrace pods to signal Ready
echo "Dynatrace OneAgent - Waiting for Dynatrace resources to be available..."
kubectl wait --for=condition=ready pod --all -n dynatrace --timeout=60s


##############################
# Install keptn cli      #
##############################
cd $home_folder
curl -sL https://get.keptn.sh | KEPTN_VERSION=$keptn_version bash 


##############################
# Install ingress-nginx      #
##############################

echo "Installing ingress-nginx"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace --wait

#### Ingress for carts app

sed -e "s|INGRESS_PLACEHOLDER|$ingress_domain|g"  \
     $home_folder/$clone_folder/box/carts/manifest/carts-temp.yml > $home_folder/$clone_folder/box/carts/manifest/carts.yml

sed -e "s|INGRESS_PLACEHOLDER|$ingress_domain|g"  \
     $home_folder/$clone_folder/box/k8s-deploy-staging/carts-temp.yml > $home_folder/$clone_folder/box/k8s-deploy-staging/carts.yml
##############################
# Install Gitea + config     #
##############################

echo "Gitea - Install using Helm"
helm repo add k8s-land https://charts.k8s.land

sed \
    -e "s|INGRESS_PLACEHOLDER|$ingress_domain|"  \
    $home_folder/$clone_folder/box/helm/gitea-values.yml > $home_folder/$clone_folder/box/helm/gitea-values-gen.yml

helm install gitea k8s-land/gitea -f $home_folder/$clone_folder/box/helm/gitea-values-gen.yml --namespace gitea --create-namespace

kubectl -n gitea rollout status deployment gitea-gitea
echo "Gitea - Sleeping for 60s"
sleep 60

echo "Gitea - Create initial user $git_user"
kubectl exec -t $(kubectl -n gitea get po -l app=gitea-gitea -o jsonpath='{.items[0].metadata.name}') -n gitea -- bash -c 'su - git -c "/usr/local/bin/gitea --custom-path /data/gitea --config /data/gitea/conf/app.ini  admin create-user --username '$git_user' --password '$git_pwd' --email '$git_email' --admin --access-token"' > gitea_install.txt

gitea_pat=$(grep -oP 'Access token was successfully created... \K(.*)' gitea_install.txt)

echo "Gitea - PAT: $gitea_pat"
echo "Gitea - URL: http://gitea.$ingress_domain"

ingress_domain=$ingress_domain gitea_pat=$gitea_pat bash -c 'while [[ "$(curl -s -o /dev/null -w "%{http_code}" http://gitea.$ingress_domain/api/v1/admin/orgs?access_token=$gitea_pat)" != "200" ]]; do sleep 5; done'

echo "Gitea - Create org $git_org..."
curl -k -d '{"full_name":"'$git_org'", "visibility":"public", "username":"'$git_org'"}' -H "Content-Type: application/json" -X POST "http://gitea.$ingress_domain/api/v1/orgs?access_token=$gitea_pat"
echo "Gitea - Create repo $git_repo..."
curl -k -d '{"name":"'$git_repo'", "private":false, "auto-init":true}' -H "Content-Type: application/json" -X POST "http://gitea.$ingress_domain/api/v1/org/$git_org/repos?access_token=$gitea_pat"
echo "Gitea - Git config..."
git config --global user.email "$git_email" && git config --global user.name "$git_user" && git config --global http.sslverify false
cd $home_folder
echo "Gitea - Adding resources to repo $git_org/$git_repo"
git clone http://$git_user:$gitea_pat@gitea.$ingress_domain/$git_org/$git_repo
cp -r $home_folder/$clone_folder/box/repo/. $home_folder/$git_repo
cd $home_folder/$git_repo && git add . && git commit -m "Initial commit, enjoy"
cd $home_folder/$git_repo && git push http://$git_user:$gitea_pat@gitea.$ingress_domain/$git_org/$git_repo

## Adding pipeline resources

echo "Gitea - Create repo $app1Repo..."
curl -k -d '{"name":"'$app1Repo'", "private":false, "auto-init":true}' -H "Content-Type: application/json" -X POST "http://gitea.$ingress_domain/api/v1/org/$git_org/repos?access_token=$gitea_pat"
cd $home_folder

git clone http://$git_user:$gitea_pat@gitea.$ingress_domain/$git_org/$app1Repo
cp -r $home_folder/$clone_folder/box/$app1Repo/. $home_folder/$app1Repo

cd $home_folder/$app1Repo && git add . && git commit -m "Initial commit, enjoy"

cd $home_folder/$app1Repo && git push http://$git_user:$gitea_pat@gitea.$ingress_domain/$git_org/$app1Repo

echo "Gitea - Create repo $stagingPipelineRepo..."
curl -k -d '{"name":"'$stagingPipelineRepo'", "private":false, "auto-init":true}' -H "Content-Type: application/json" -X POST "http://gitea.$ingress_domain/api/v1/org/$git_org/repos?access_token=$gitea_pat"
cd $home_folder
git clone http://$git_user:$gitea_pat@gitea.$ingress_domain/$git_org/$stagingPipelineRepo
cp -r $home_folder/$clone_folder/box/$stagingPipelineRepo/. $home_folder/$stagingPipelineRepo
cd $home_folder/$stagingPipelineRepo && git add . && git commit -m "Initial commit, enjoy"
cd $home_folder/$stagingPipelineRepo && git push http://$git_user:$gitea_pat@gitea.$ingress_domain/$git_org/$stagingPipelineRepo

echo "Gitea - Create repo $releaseBranchPipeline..."
curl -k -d '{"name":"'$releaseBranchPipeline'", "private":false, "auto-init":true}' -H "Content-Type: application/json" -X POST "http://gitea.$ingress_domain/api/v1/org/$git_org/repos?access_token=$gitea_pat"
cd $home_folder
git clone http://$git_user:$gitea_pat@gitea.$ingress_domain/$git_org/$releaseBranchPipeline
cp -r $home_folder/$clone_folder/box/$releaseBranchPipeline/. $home_folder/$releaseBranchPipeline
cd $home_folder/$releaseBranchPipeline && git add . && git commit -m "Initial commit, enjoy"
cd $home_folder/$releaseBranchPipeline && git push http://$git_user:$gitea_pat@gitea.$ingress_domain/$git_org/$releaseBranchPipeline

##############################
# Create app and base settings   #
##############################

kubectl create ns dev
kubectl create ns staging
kubectl create ns production

## Deploy base files 
kubectl apply -f $home_folder/$clone_folder/box/$app1Repo/manifest/carts-db.yml

##############################
# Deploy Registry            #
##############################
kubectl create ns registry
kubectl create -f $home_folder/$clone_folder/box/helm/registry.yml

##############################
# Install Jenkins            #
##############################

echo "Jenkins - Install"

sed \
    -e "s|DOCKER_REGISTRY_URL_PLACEHOLDER|localhost:32000|" \
    -e "s|GITHUB_USER_EMAIL_PLACEHOLDER|$git_email|" \
    -e "s|GITHUB_USER_NAME_PLACEHOLDER|$git_user|" \
    -e "s|GITHUB_PERSONAL_ACCESS_TOKEN_PLACEHOLDER|$gitea_pat|" \
    -e "s|GITHUB_ORGANIZATION_PLACEHOLDER|$git_org|" \
    -e "s|DT_TENANT_URL_PLACEHOLDER|$DT_TENANT|" \
    -e "s|DT_API_TOKEN_PLACEHOLDER|$DYNATRACE_TOKEN|" \
    -e "s|INGRESS_PLACEHOLDER|$ingress_domain|" \
    -e "s|GIT_REPO_PLACEHOLDER|$git_repo|" \
    -e "s|GIT_DOMAIN_PLACEHOLDER|gitea.$ingress_domain|" \
    $home_folder/$clone_folder/box/helm/jenkins-values.yml > $home_folder/$clone_folder/box/helm/jenkins-values-gen.yml

kubectl create clusterrolebinding jenkins --clusterrole cluster-admin --serviceaccount=jenkins:jenkins
kubectl create clusterrolebinding default --clusterrole cluster-admin --serviceaccount=jenkins:default
kubectl apply -f $home_folder/$clone_folder/box/helm/k8s-jenkins-crb.yml

helm repo add jenkins https://charts.jenkins.io
helm repo update
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

helm upgrade -i jenkins jenkins/jenkins --create-namespace -f $home_folder/$clone_folder/box/helm/jenkins-values-gen.yml --version $jenkins_chart_version --namespace jenkins --wait 

# Configure persistent volume claim for jenkins jobs
echo "configure maven pvc"
kubectl apply -f $home_folder/$clone_folder/box/helm/k8s-maven-pvc.yml
kubectl apply -f $home_folder/$clone_folder/box/helm/jenkins-pvc.yml

##############################
# Deploy Dashboard           #
##############################

sed \
    -e "s|INGRESS_PLACEHOLDER|$ingress_domain|g" \
    -e "s|GITEA_USER_PLACEHOLDER|$git_user|g" \
    -e "s|GITEA_PAT_PLACEHOLDER|$gitea_pat|g" \
    -e "s|DYNATRACE_TENANT_PLACEHOLDER|$DT_TENANT|g"\
    $home_folder/$clone_folder/box/dashboard/index.html > $home_folder/$clone_folder/box/dashboard/index-gen.html

sed -e "s|INGRESS_PLACEHOLDER|$ingress_domain|" $home_folder/$clone_folder/box/helm/dashboard/values.yaml > $home_folder/$clone_folder/box/helm/dashboard/values-gen.yaml

docker build -t localhost:32000/dashboard $home_folder/$clone_folder/box/dashboard && docker push localhost:32000/dashboard

helm upgrade -i ace-dashboard $home_folder/$clone_folder/box/helm/dashboard -f $home_folder/$clone_folder/box/helm/dashboard/values-gen.yaml --namespace dashboard --create-namespace

##############################
# Credentials file #
##############################
sed \
    -e "s|DYNATRACE_ENVIRONMENT_ID|$DT_TENANT|g" \
    -e "s|DYNATRACE_TOKEN|$DYNATRACE_TOKEN|g" \
    -e "s|DYNATRACE_PAAS_TOKEN|$DYNATRACE_PAAS_TOKEN|g" \
$home_folder/$clone_folder/box/scripts/creds-template.json > $home_folder/creds.json
