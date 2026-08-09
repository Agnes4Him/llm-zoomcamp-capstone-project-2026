# HealthSecure AI — RAG + Agentic Insurance Assistant

## Project overview
HealthSecure AI is an intelligent assistant for a fictional insurance company. It combines:

- a knowledge base of insurance documents,
- a Postgres-backed agent tooling layer,
- a retriever-augmented generation (RAG) flow built with Pinecone and LangChain,
- a FastAPI service for question answering, feedback, and monitoring.

The system is designed to answer insurance-related questions, retrieve policy details, and answer member and non-member-specific inquiries such as claim status, enrollment, plans, e.t.c.

---

## What this project solves
Insurance systems have many policies, procedures, and member-specific rules, and documents to address questions from the general public. HealthSecure AI helps users:

- search policy documents without reading everything,
- ask questions in natural language,
- retrieve member details via tools,
- collect user feedback,
- monitor system performance and cost.

This is a hybrid solution: an LLM powers the assistant, a vector store enables retrieval from the knowledge base, and a structured agent layer provides direct database access when needed.

---

## What is implemented

- **Knowledge-base retrieval** using Pinecone vector database and OpenAI embedding models.
- **RAG flow** via `main/app/rag.py` and `main/app/rag_helper.py`.
- **Agent tooling** with three tools in `main/app/tools.py`:
  - `search_knowledge_base`
  - `get_member`
  - `get_claim_status`
- **LLM backend** configured in `main/app/llm.py` using OpenAI chat models.
- **PostgreSQL persistence** in `main/scripts/init_postgres_db.sql`.
- **FastAPI API** in `main/api.py` for question answering, feedback submission, and monitoring.
- **Local development** support with `main/docker-compose.yaml`.
- **Kubernetes manifests** for local `Kind cluster` and cloud deployment in `kubernetes/`.
- **Cloud infrastructure** bootstrapped via Terraform in `infrastructures/`.
- **Monitoring** via feedback collection, a simple monitoring endpoint, and Grafana manifests.
- **CI/CD Pipelines** with GitHub Actions for the automated provisioning of Cloud Infrastructures, and the build and push of the API Docker image to then be pulled into Cloud-provisioned Kubernetes cluster through FluxCD.
---

## Evaluation criteria mapping

| Criteria | Status | Notes |
|---|---|---|
| Problem description | ✅ | Documented in README and architecture overview. |
| Retrieval flow | ✅ | Uses Pinecone vector retrieval plus LLM prompts. |
| Retrieval evaluation | ⚠️ | Retrieval is implemented; explicit multi-approach evaluation can be added. |
| LLM evaluation | ⚠️ | LLM answers are stored and feedback is collected; more formal prompt comparison is future work. |
| Interface | ✅ | FastAPI web API and example test agent CLI path. |
| Ingestion pipeline | ✅ | Automated ingestion via `main/app/ingest.py`. |
| Monitoring | ✅ | Feedback stored and Grafana integration available. |
| Containerization | ✅ | Dockerfile + docker-compose + Kubernetes manifests. |
| Reproducibility | ✅ | `pyproject.toml`, env guidance, and deployment paths included. |
| Bonus / cloud | ✅ | Cloud deployment scaffolded using Terraform + k3s + Flux. |

---

## Repository structure

- `main/` - primary application code and runtime files. UV is initialized here
  - `api.py` — FastAPI service entrypoint
  - `Dockerfile`
  - `docker-compose.yaml` — local service stack (Postgres, API, Grafana)
  - `pyproject.toml` — Python dependencies
  - `app/` — core app logic
    - `agent.py` — LangChain agent construction
    - `rag.py` — retrieval interface
    - `rag_helper.py` — Pinecone embedding/vector helper
    - `tools.py` — agent tools and database lookups
    - `database.py` — Postgres engine and schema helpers
    - `ingest.py` — knowledge-base ingestion
    - `llm.py` — LLM creation
    - `test_agent.py` - for interacting with the agent via the terminal
    - `test_monitoring` - contains queries that retrieve monitoring data stored in database
  - `scripts/` — database initialization SQL script
  - `knowledge-base/` — insurance knowledge documents
- `kubernetes/` — Kubernetes deployment manifests
- `infrastructures/` — Terraform cloud infrastructure
- `.github` - stores pipeline workflows for infrastructures and FastAPI

---

## Setup and configuration

### Prerequisites

- Python 3.14+
- Docker / Docker Compose
- `uv` CLI (`pip install uv`) or Python environment with `uvicorn`
- Postgres (local or via Docker Compose - Amazon RDS for PostgreSQL was used in Cloud Deployment)
- `kubectl` for Kubernetes deployments (comes with Docker if installed as Docker Desktop on Windows)
- `kind` for local K8s cluster
- `k3s` for cloud K8s deployment
- Terraform for cloud infrastructure
- Pinecone account and API key
- OpenAI API key
- AWS account and IAM credentials for admnistrator access (can be more scoped to limit access)

### Environment variables

Create `main/.env` with values for:

- `OPENAI_API_KEY`
- `OPENAI_CHAT_MODEL`
- `OPENAI_EMBEDDING_MODEL`
- `PINECONE_API_KEY`
- `PINECONE_INDEX_NAME_OPENAI`
- `POSTGRES_HOST`
- `POSTGRES_PORT`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DB`
- `GF_SECURITY_ADMIN_PASSWORD` (for Grafana)

Do not commit secrets to git.

## Initial testing

This was done using `jupyter notebook` located at `main/main.ipynb`

---

## How the system works

1. User sends a question to `/api/question`.
2. The FastAPI endpoint builds a conversation record and invokes the LangChain agent.
3. The agent uses tools to:
   - query the vectorstore (`search_knowledge_base`),
   - fetch member records from Postgres (`get_member`),
   - fetch claim records from Postgres (`get_claim_status`).
4. The OpenAI model generates the final answer.
5. Response cost, tokens, and latency are tracked.
6. User feedback can be submitted and stored.

---

## Key demo modes

### 1) Local deployment without Kubernetes

Initialize uv within `main`

```bash
cd main
uv sync
```

Ingest the knowledge base:

```bash
uv run python -c "from app.ingest import add_documents_to_vectorstore; add_documents_to_vectorstore()"
```

This is the fastest path to run the API locally.

```bash
uv run uvicorn api:app --host 0.0.0.0 --port 5000 --reload
```
Starting the API loads the DB schema automatically, because `main/api.py` runs `initialize_database()` on startup.

This setup will fail since the API depends on PostgreSQL database, which should already be up and running.
Hence, a better alternative is the local mode explained below.


### 2) Local deployment with docker-compose

Start Docker server

Start API, PostgreSQL and Grafana containers using docker-compose.
Edit the `main/docker-compose.yaml` file to change the API image name accordingly.

```bash
cd main
docker-compose up -d
```

Access the API swagger at `localhost:5000/docs` or send a `GET` request to the healthcheck endpoint at `localhost:5000/api/healthcheck`

Interact with the agent by running the `client` script

```bash
cd main
uv run python app/test_agent.py
```

Enter in your questions and give feedback when prompted to.
Sample questions can be found at `main/README.md`

Also, saved monitoring data can be viewed on the terminal by running the script...

```bash
uv run python app/test_monitoring.py  5       # update argument to reflect the number of records you wish to retrieve
```

Data can also be viewed directly on Grafana. 
Visit Grafana at `localhost:3000` and login using `admin/admin` as username/password

Click on the `Connection` tab and search for `PostgreSQL` >> Add Data Source >> Enter in connection to PostgreSQL credentials.

When through, stop and remove the containers

```bash
docker-compose down
```

Watch demo...

`https://example.com/your-demo-video`


### 3) Local deployment with Kind Kubernetes

1. Create a Kind cluster:

```bash
kind create cluster --name llm-project --config kubernetes/supporting-services/kind/kind-config.yaml
```

2. Apply local manifests:

```bash
kubectl apply -f kubernetes/local-deployment/
```

3. Optionally inspect services:

```bash
kubectl get pods,svc -n default
```

4. Visit the API's swagger at `localhost:30080/docs` and Grafana at `localhost:30030`

5. Follow the steps in the `#2 mode` above to run the agent client, ask questions, give feedbacks, and view monitoring data.

** Note **
`test_agent.py` needs to be updated to contain a new URL for the API.

Watch demo...

`https://example.com/cloud-demo`


### 3) Cloud deployment with k3s

The project includes cloud bootstrap support for k3s via Terraform and EC2 user-data.

The EC2 bootstrap script is in:
- `infrastructures/modules/ec2/user-data.sh.tpl`

The script installs k3s, Traefik, Gateway, External Secrets Operator, Flux, and Grafana.

The infrastructures provisioned with Terrafrom include:
- EC2 instance to run Kubernetes
- RDS database to save members data, feedbacks and conversations
- IAM role for the EC2 instance
- Networking componenents - VPC, Subnets, Internet gateway, Route Table, Security Groups
- ECR - to store API Docker images and to serve as an OCI repository for the API manifests.

Follow the steps below to setup the Cloud Infrastructure and environment to deploy the API:

* Create a secret named `healthsecuresecrets` in AWS Secrets Manager.

* Move all environments variables into this secret as JSON. See images below

![AWS Secrets Manager Console](PLACEHOLDER_IMAGE_URL)

===================================================================================================

![Select Secret Type](PLACEHOLDER_IMAGE_URL)

===================================================================================================

![Store Env Variables as JSON](PLACEHOLDER_IMAGE_URL)

* Create an S3 bucket tp serve as Remote backend for Terraform. Details of the bucket can be found
in Terraform `provisioners.tf` file

* Store the AWS credential for your admin user in GitHub under `Settings` >> `Secrets and Variables` >> `Actions` >> `Repository Secrets`.

These include:
- AWS_SECRET_ACCESS_KEY
- AWS_ACCESS_KEY_ID
- AWS_REGION

* Also store these Terraform variables as well
- TF_VAR_PASSWORD - any password of your choice. Terraform will use this at the creation of RDS database
- TF_VAR_PUBLIC_KEY - see below for more...

`TF_VAR_PUBLIC_KEY` can be generated locally and copied as follow:

Run the command

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
```

Follow the prompt and enter your path of choice to save the key pair that would be generated

Skip the rest of the prompt

Locate the path where the key pair is stored and open the public key file to copy the key

Enter this key as the value for `TF_VAR_PUBLIC_KEY`. Terraform will save this in the EC2 instance it creates.

* Push repository to GitHub and trigger the CI/CD pipeline - `deploy-infrastructure` to deploy the infrastructures

* Once complete and successful, trigger the second pipeline `deploy-api` to build and push docker image and artifacts to Amazon ECR.

* Run SSH command from your local machine to access the EC2 instance and view the cluster and workloads

```bash
ssh -i <PATH_TO_SSH_PRIVATE_KEY> ubuntu@<EC2_PUBLIC_IP_ADDRESS>
```

* View running pods

```bash
kubectl get po -n api
```

Watch demo...

`https://example.com/cloud-demo`


---

### API endpoints

- `POST /api/question` — submit a user question
- `POST /api/feedback` — submit feedback for a conversation
- `GET /api/monitoring` — view recent conversation + feedback records
