#!/bin/bash

set -e

exec > >(tee /var/log/bootstrap.log)
exec 2>&1

echo "Updating system"

apt-get update -y
apt-get upgrade -y

echo "Installing Docker"
apt-get install -y docker.io
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

echo "Installing k3s"
curl -sfL https://get.k3s.io | sh -
systemctl enable k3s


echo "Waiting for k3s"
for i in {1..60}
do
  if kubectl get nodes >/dev/null 2>&1
  then
    break
  fi

  sleep 5
done

echo "Waiting for node to become Ready"
until kubectl get nodes | grep -q " Ready"
do
  sleep 5
done

echo "Installing AWS CLI"
if ! command -v aws >/dev/null 2>&1; then
    snap install aws-cli --classic
fi
aws --version

echo "Creating api namespace"
kubectl create namespace api --dry-run=client -o yaml | kubectl apply -f -

echo "Creating ECR pull secret"
kubectl create secret docker-registry ecr-secret \
--docker-server=759907441676.dkr.ecr.eu-west-2.amazonaws.com \
--docker-username=AWS \
--docker-password=$(aws ecr get-login-password --region eu-west-2) \
-n api \
--dry-run=client -o yaml | kubectl apply -f -

mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
echo "export KUBECONFIG=/home/ubuntu/.kube/config" >> /home/ubuntu/.bashrc
chown -R ubuntu:ubuntu /home/ubuntu/.kube
export KUBECONFIG=/home/ubuntu/.kube/config

echo "Installing Helm"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "Installing Gateway API CRDs"
kubectl apply -f \
https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml


echo "Installing Traefik Gateway Controller"
helm repo add traefik https://traefik.github.io/charts
helm repo update

helm upgrade --install traefik traefik/traefik \
--namespace traefik \
--create-namespace \
--set providers.kubernetesGateway.enabled=true

kubectl rollout status deployment/traefik \
-n traefik \
--timeout=300s

echo "Waiting for Traefik Gateway..."
until kubectl get gateway traefik-gateway -n traefik >/dev/null 2>&1; do
  sleep 5
done
echo "Traefik Gateway found"

echo "Updating traefik-gateway Gateway..."
kubectl patch gateway traefik-gateway \
  -n traefik \
  --type='json' \
  -p='[
    {
      "op": "replace",
      "path": "/spec/listeners/0/allowedRoutes/namespaces/from",
      "value": "All"
    },
    {
      "op": "replace",
      "path": "/spec/listeners/1/allowedRoutes/namespaces/from",
      "value": "All"
    }
  ]'

echo "Installing External Secrets Operator"
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm upgrade --install external-secrets \
external-secrets/external-secrets \
--namespace external-secrets \
--create-namespace

kubectl rollout status deployment/external-secrets \
-n external-secrets \
--timeout=300s

echo "Installing Flux"
curl -s https://fluxcd.io/install.sh | bash
flux install

kubectl wait \
--for=condition=Available \
deployment \
--all \
-n flux-system \
--timeout=300s

echo "Creating bootstrap manifests"
mkdir -p /opt/bootstrap

cat <<EOF >/opt/bootstrap/oci-repository.yaml
${flux_repo}
EOF

cat <<EOF >/opt/bootstrap/kustomization.yaml
${flux_kustomization}
EOF

cat <<EOF >/opt/bootstrap/grafana-namespace.yaml
${grafana_namespace}
EOF

cat <<EOF >/opt/bootstrap/grafana-deployment.yaml
${grafana_deployment}
EOF

cat <<EOF >/opt/bootstrap/grafana-service.yaml
${grafana_service}
EOF

cat <<EOF >/opt/bootstrap/grafana-httproute.yaml
${grafana_httproute}
EOF

echo "Applying Flux OCI GitOps"
kubectl apply -f /opt/bootstrap/oci-repository.yaml
kubectl apply -f /opt/bootstrap/kustomization.yaml

echo "Applying Grafana"
kubectl apply -f /opt/bootstrap/grafana-namespace.yaml
kubectl apply -f /opt/bootstrap/grafana-deployment.yaml
kubectl apply -f /opt/bootstrap/grafana-service.yaml
kubectl apply -f /opt/bootstrap/grafana-httproute.yaml

echo "Bootstrap completed"