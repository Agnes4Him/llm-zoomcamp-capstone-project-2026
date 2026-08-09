# HealthSecure AI — RAG + Agentic Insurance Assistant

## Project overview
HealthSecure AI is an intelligent assistant for a fictional insurance company. It combines:

- a knowledge base of insurance documents,
- a Postgres-backed agent tooling layer,
- a retriever-augmented generation (RAG) flow built with Pinecone and LangChain,
- a FastAPI service for question answering, feedback, and monitoring.

The system is designed to answer insurance-related questions, retrieve policy details, and answer member-specific inquiries such as claim status.

> Placeholder screenshot: `![App preview](PLACEHOLDER_IMAGE_URL)`
> Placeholder demo video: `https://example.com/your-demo-video`

---

## What this project solves
Insurance systems have many policies, procedures, and member-specific rules. HealthSecure AI helps users:

- search policy documents without reading everything,
- ask questions in natural language,
- retrieve member and claim status via tools,
- collect user feedback,
- monitor system performance and cost.

This is a hybrid solution: an LLM powers the assistant, a vector store enables retrieval from the knowledge base, and a structured agent layer provides direct database access when needed.

---

## What is implemented

- **Knowledge-base retrieval** using Pinecone vector embeddings from OpenAI embedding models.
- **RAG flow** via `main/app/rag.py` and `main/app/rag_helper.py`.
- **Agent tooling** with three tools in `main/app/tools.py`:
  - `search_knowledge_base`
  - `get_member`
  - `get_claim_status`
- **LLM backend** configured in `main/app/llm.py` using OpenAI chat models.
- **FastAPI API** in `main/api.py` for question answering, feedback submission, and monitoring.
- **PostgreSQL persistence** for conversations and feedback in `main/scripts/init_postgres_db.sql`.
- **Local development** support with `main/docker-compose.yaml`.
- **Kubernetes manifests** for local Kind deploy and cloud deployment in `kubernetes/`.
- **Cloud infrastructure** bootstrapped via Terraform in `infrastructures/`.
- **Monitoring** via feedback collection, a simple monitoring endpoint, and Grafana manifests.

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

> Notes: This README is intended to replace `README2.md` as the main project documentation.

---

## Repository structure

- `main/` - primary application code and runtime files
  - `api.py` — FastAPI service entrypoint
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
- `main/scripts/` — database initialization SQL
- `main/knowledge-base/` — insurance knowledge documents
- `kubernetes/` — Kubernetes deployment manifests
- `infrastructures/` — Terraform cloud infrastructure

---

## Key demo modes

### 1) Local deployment without Kubernetes

Ingest the knowledge base:

```bash
cd main
uv run python -c "from app.ingest import add_documents_to_vectorstore; add_documents_to_vectorstore()"
```

This is the fastest path to run the API locally.

```bash
cd main
uv run uvicorn api:app --host 0.0.0.0 --port 5000 --reload
```

Load the DB schema automatically by starting the API, because `main/api.py` runs `initialize_database()` on startup.

### 2) Local deployment with Kind Kubernetes

1. Create the Kind cluster:

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

### 3) Cloud deployment with k3s

The project includes cloud bootstrap support for k3s via Terraform and EC2 user-data.

The EC2 bootstrap script is in:
- `infrastructures/modules/ec2/user-data.sh.tpl`

It installs k3s, Traefik, External Secrets Operator, Flux, and Grafana.

> Placeholder cloud demo video: `https://example.com/cloud-demo`

---

## Setup and configuration

### Prerequisites

- Python 3.14+
- Docker / Docker Compose
- `uv` CLI (`pip install uv`) or Python environment with `uvicorn`
- Postgres (local or via Docker Compose)
- `kubectl` for Kubernetes deployments
- `kind` for local K8s cluster
- `k3s` for cloud K8s deployment
- Terraform for cloud infrastructure
- Pinecone account and API key
- OpenAI API key

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
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_REGION` for cloud deployment

Do not commit secrets to git.

### Install dependencies

```bash
cd main
uv install
```

Or with pip:

```bash
cd main
python -m pip install -r requirements.txt
```

### Initialize the database

Start the API once, and the DB schema is created automatically.

```bash
cd main
uv run uvicorn api:app --host 0.0.0.0 --port 5000 --reload
```

If you need an explicit SQL initialization step:

```bash
cd main
uv run python -c "from app.database import initialize_database; initialize_database()"
```

### Ingest documents into Pinecone

```bash
cd main
uv run python -c "from app.ingest import add_documents_to_vectorstore; add_documents_to_vectorstore()"
```

---

## Running the application

### Start locally with Docker Compose

```bash
cd main
docker-compose up -d
```

This starts:

- Postgres database
- FastAPI API server
- Grafana monitoring UI

### API endpoints

- `POST /api/question` — submit a user question
- `POST /api/feedback` — submit feedback for a conversation
- `GET /api/monitoring` — view recent conversation + feedback records

### Example request

```bash
curl -X POST http://localhost:5000/api/question \
  -H 'Content-Type: application/json' \
  -d '{"message":"What is the deductible for Gold members?","history":[]}'
```

### Example feedback submission

```bash
curl -X POST http://localhost:5000/api/feedback \
  -H 'Content-Type: application/json' \
  -d '{"question":"What is my deductible?","response":"Your deductible is $500.","rating":"5","conversation_id":1,"source":"ui","score":5}'
```
** Note **
There's a `test_agent.py` file that can also be used to test `/api/question` endpoint.

---

## Monitoring and evaluation

- Conversation records, token counts, response time, and cost are stored in Postgres.
- Feedback records are stored in Postgres and linked to conversation IDs.
- Grafana is available on port `3000` when running via Docker Compose.
- The project includes saved example monitoring queries in `main/performance-queries`.

### Monitoring queries

Use the `main/performance-queries` file to inspect:

- recent activity and feedback
- cost, latency, and token trends
- model performance
- slowest and highest-cost calls
- feedback distribution
- conversations without feedback
- correlation of low feedback with cost or latency

---

## Deployment notes

### Local Kind cluster

The local Kubernetes manifests are in `kubernetes/local-deployment/`.

### Cloud deployment

The Terraform infrastructure is in `infrastructures/`.

The cloud deployment path includes:

- EC2 instance provisioning
- ECR repository setup
- RDS Postgres database
- IAM roles for EC2 access to RDS and ECR
- k3s bootstrap script via `infrastructures/modules/ec2/user-data.sh.tpl`
- Flux and Grafana manifests in `kubernetes/supporting-services/`

### Flux / Traefik / External Secrets

The project includes manifests for:

- Flux OCIRepository and Kustomization
- Traefik gateway controller
- External Secrets Operator
- Grafana deployment and service

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

## Notes and next steps

- `README2.md` contains earlier deployment notes and commands; this README is the primary documentation.
- The codebase includes multiple deployment modes: local, Kind, and cloud k3s.
- Screenshots and demo videos should be added after recording.
- Consider adding formal retrieval and prompt evaluation reports for full project evaluation.

---