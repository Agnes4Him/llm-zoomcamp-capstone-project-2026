## Project structure

healthsecure-ai/

├── app/
│   ├── agent.py          # LangChain agent
│   ├── tools.py          # All tool definitions
│   ├── rag.py            # Pinecone retriever
│   ├── database.py       # PostgreSQL connection
│   ├── prompts.py        # System prompt
│   └── llm.py            # Bedrock LLM configuration
│
├── knowledge_base/
│   ├── 01_member_handbook.md
│   ├── 02_benefits_guide.md
│   ├── 03_coverage_policies.md
│   ├── 04_prior_authorization.md
│   ├── 05_claims_guide.md
│   └── 06_appeals_guide.md
│
├── scripts/
│   ├── ingest_documents.py
│   ├── generate_documents.py
│   └── generate_data.py
│
├── database/
│   └── schema.sql
│
├── .env
├── requirements.txt
└── main.py

## start fastapi app
uv run uvicorn api:app --host 0.0.0.0 --port 5000 --reload

## Setup Flux
Install Flux controllers
Configure ECR authentication
Create an OCIRepository
Create a Kustomization

```bash
flux install

kubectl get pods -n flux-system

kubectl apply -f flux/healthsecure-source.yaml

flux get sources oci

kubectl apply -f flux/healthsecure-app.yaml

flux get kustomizations
```

## Set up Traefik + Gatway API
Install Traefik with Gateway API enabled
```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update

helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set providers.kubernetesGateway.enabled=true \
  --set service.type=NodePort

kubectl get pods -n traefik
```
Install Gateway API CRDs
```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml

kubectl get crd | grep gateway

kubectl get gatewayclass
```

Create gateway
```bash
kubectl apply -f gateway.yaml
```

## Create K8s cluster with kind...
```bash
kind create cluster \
--name llm-project \
--config kubernetes/supporting-services/kind/kind-config.yaml          # from root
```

## Create K8s cluster with k3s...
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -          # install without default Traefik

sudo kubectl get nodes

# Configure kubectl for your user
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
```

## Setup ExternalSecret Operator
```bash
helm repo add external-secrets https://charts.external-secrets.io

helm repo update

helm install external-secrets \
external-secrets/external-secrets \
-n external-secrets \
--create-namespace

kubectl get pods -n external-secrets

kubectl apply -f secret-store.yaml
```

## Pending...
* Evaluation/ Monitoring 
* Run through EC2 user_data script and edit/adjust
* Edit Tf files and test
* test tf with pipeline
* Document
