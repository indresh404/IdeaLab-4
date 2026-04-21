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

## ☸️ Phase 3: Scaling (Kubernetes)
For production-level disaster response, the system is ready for Kubernetes (`DevOps/k8s/`).
- **High Availability**: 3 replicas of the backend ensure that if one pod fails, the system stays online.
- **Self-Healing**: Kubernetes Liveness and Readiness probes monitor the app health.
- **Secrets Management**: Sensitive keys are abstracted into K8s Secrets.
- **Auto-scaling**: Ready for Horizontal Pod Autoscaler (HPA) to handle traffic spikes during a real-world crisis.

## 🔁 Phase 4: Automation (CI/CD)
The `.github/workflows/backend-deploy.yml` automates the entire lifecycle:
1. **Lint & Test**: Checks code quality on every Pull Request.
2. **Security Audit**: Uses `pip-audit` to scan for vulnerable dependencies before building.
3. **Build & Push**: Automatically builds the Docker image and pushes it to Docker Hub.
4. **Auto-Deploy**: Automatically updates the Kubernetes cluster with the new image on every push to `main`.

## 🔐 Phase 5: DevSecOps Hardening
- **Image Scanning**: Recommended integration with Trivy for container vulnerability scanning.
- **Secret Protection**: `.dockerignore` prevents local `.env` and `firebase-service-account.json` from ever entering the image.
- **Network Isolation**: Docker Compose uses a private internal network for inter-service communication.

## ☁️ Phase 6: Cloud Strategy
The current setup is compatible with:
- **AWS**: Deploy using EKS (Kubernetes) or ECS (Docker Compose).
- **GCP**: Native support for GKE.
- **Railway/Render**: Simple one-click deployment using the provided Dockerfile.

---
**Developer Note**: To launch locally for testing, ensure your `.env` is configured and run `docker-compose up`.
