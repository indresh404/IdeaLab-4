# CrisisClarity DevOps Documentation (Production Grade)

This folder contains the complete infrastructure-as-code and orchestration logic for the CrisisClarity Backend system. 

## 🏗️ Phase 1: Dockerization (Foundation)
The backend is now fully containerized using a **multi-stage Dockerfile** located in `/crisisclarity-backend/Dockerfile`.
- **Minimal Footprint**: Uses `python:3.10-slim` to reduce image size.
- **Security**: Runs as a non-root user (`crisisuser`) to prevent privilege escalation attacks.
- **Health Checks**: Integrated Docker health checks to ensure the FastAPI app is responding.
- **Optimization**: Multi-stage build separates build dependencies from the runtime environment.

## ⚙️ Phase 2: Orchestration (Docker Compose)
The `DevOps/docker-compose.yml` file allows you to launch the entire ecosystem with one command:
```bash
docker-compose up -d
```
### Services Included:
1. **FastAPI Backend**: The core AI system.
2. **Redis**: Used for high-speed caching of Agent Pipeline results to reduce API costs and latency.
3. **PostgreSQL**: Production-grade database for storing AI logs, user alerts, and system state.
4. **Ollama**: Local LLM service container, enabling hybrid AI (Cloud Groq + Local Ollama).
5. **Nginx**: Reverse proxy for load balancing and security.

## ☸️ Phase 3: Local Orchestration (Minikube)
For learning and local demonstrations, we use **Minikube** to simulate a production Kubernetes environment.
- **Local Deployment**: We build images locally and load them into the Minikube cache using `minikube image load`.
- **Manifests**: We use standard K8s Deployment and Service manifests located in `DevOps/k8s/`.
- **Access**: Services are exposed using `minikube service crisisclarity-service` to provide a local URL for testing.

## 🔁 Phase 4: Automation (Simplified CI/CD)
The `.github/workflows/backend-deploy.yml` follows a high-stability "Clean Pipeline" approach:
1. **Lint & Test**: Every push is checked with `flake8` for code quality.
2. **Security Audit**: `pip-audit` scans for vulnerable dependencies to ensure the app is production-safe.
3. **Build & Push**: The pipeline builds a tagged Docker image and pushes it to **Docker Hub** (`indresh404/crisisclarity-backend`).
4. **Cloud Ready**: The Docker Hub image is now ready to be pulled by any cloud provider (Render, AWS, etc.) for final deployment.

## 🚀 How to Run the Kubernetes Demo Locally
1. **Start Cluster**: `minikube start`
2. **Build Image**: `docker build -t crisisclarity-backend ./crisis_clarity/crisisclarity-backend`
3. **Load to Cluster**: `minikube image load crisisclarity-backend`
4. **Deploy**: `kubectl apply -f crisis_clarity/DevOps/k8s/`
5. **View App**: `minikube service crisisclarity-service`

---
**Developer Note**: This architecture prioritizes **security** (pip-audit) and **portability** (Docker Hub) before moving to full-scale cloud orchestration.

Promethus + Grafana