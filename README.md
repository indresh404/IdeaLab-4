# 🚨 CrisisClarity: Real-Time Disaster Intelligence 

<p align="center">
  <img src="crisis_clarity/assets/icons/Logo.png" width="25%" />
</p>

**CrisisClarity** is a full-stack, AI-powered disaster intelligence platform designed to deliver **verified, multilingual, and context-aware crisis information** in real time. Built specifically for high-risk regions like Mumbai and Maharashtra, it combines **Multi-Agent AI, FastAPI, Flutter, and Production-Grade DevOps** to transform fragmented disaster communication into a unified, trustworthy system.

---

## 🌍 Problem Statement

During disasters, critical information is often:

- ❌ Scattered across multiple sources
- ❌ Difficult to verify (fake news, rumors)
- ❌ Not available in local languages (Marathi/Hindi)
- ❌ Too slow to act upon
- ❌ One-way broadcast with no citizen feedback

This leads to **panic, misinformation, delayed response, and preventable casualties**.

---

## 💡 Solution

CrisisClarity solves this using:

- 🤖 **4-Agent BDI Verification Pipeline** (Belief-Desire-Intention)
- 🌐 **Real-Time Alert Aggregation** (RSS feeds from IMD, NDMA, Times of India, NDTV, GDACS, ReliefWeb)
- 🧠 **Explainable AI (XAI) Trust Scoring** (0-100 with audit trail)
- 🗣️ **Multilingual AI** (English, Hindi, Marathi via Groq LLaMA 3.3)
- 📱 **Modern Mobile App** (Flutter with voice I/O)
- 📡 **Telegram Alert Automation** with comprehension feedback
- 🐳 **Production DevOps** (Docker, Kubernetes, GitHub Actions CI/CD)

---

## 🏗️ System Architecture

### 🔷 High-Level Flow

Admin Alert → Firebase/Fallback JSON
        ↓
DataCollectionAgent (Belief) → RSS Feeds (TOI, NDTV, GDACS, ReliefWeb)
        ↓
VerificationAgent (Desire) → Cross-source consistency check
        ↓
ScoringAgent (Intention) → Trust score (0-100) with weights
        ↓
ClassificationAgent (Action) → Trust label + XAI reason
        ↓
FastAPI Backend → Enriched Alert
        ↓
Flutter App / AI Chat / Telegram Bot (with comprehension buttons)

---

## 🤖 Multi-Agent System (Core Innovation)

CrisisClarity uses a **BDI-based Cooperative Multi-Agent Pipeline** with full explainability.

### 1. 🧠 DataCollectionAgent (Belief Layer)

- **Role:** Gather raw world state from multiple sources
- **Input:** Admin alert ID (location, disaster type, severity)
- **Sources with trust weights:**
  - Firebase Admin Alert (Weight: 40)
  - Times of India RSS (Weight: 28)
  - NDTV RSS (Weight: 28)
  - GDACS UN Disaster Feed (Weight: 35)
  - ReliefWeb India (Weight: 30)
  - Mock Social Media (Weight: 20)
- **Logic:** Keyword extraction for `disaster_type` (flood/fire/storm/landslide) and `severity`
- **Optimization:** 15-minute RSS cache
- **Output:** Structured list of `SourceResult` objects

### 2. 🔍 VerificationAgent (Desire Layer)

- **Role:** Cross-validate consistency across all collected sources
- **Logic:** Compares admin alert against each external source
- **Detects:** Conflicts (e.g., Admin says "No Fire" but News says "Major Fire")
- **Output:** `VerificationResult` with `matched_sources`, `conflict_detected`, `conflict_reason`

### 3. 📊 ScoringAgent (Intention Layer)

- **Role:** Quantitative trust calculation
- **Formula (Weighted Heuristics):**
  - Base Score = 0
  - Admin source match: +40
  - UN/GDACS match: +35
  - News match (TOI/NDTV): +28 each
  - Conflict Penalty: -50 if any conflict detected
- **Output:** `ScoreBreakdown` with final `trust_score` (0-100)

### 4. 🏷️ ClassificationAgent (Action Layer)

- **Role:** Human-readable verdict & XAI explanation
- **Logic:**
  - Score ≥ 70 → 🟢 `VERIFIED`
  - Score 30-69 → 🟠 `PARTIALLY_VERIFIED`
  - Score < 30 → 🔴 `POSSIBLE_FAKE_NEWS`
- **XAI Output:** `verification_reason` string with full audit trail
- **Output:** Final alert enriched with `trustStatus`, `trustLabel`, `agentTrace`

### 5. 📰 NewsIngestionAgent (AI Parser)

- **Role:** Natural Language Processor
- **Powered by:** **Groq Cloud API** (`llama-3.3-70b-versatile`)
- **Function:** Converts unstructured news → strict JSON schema (severity, trust_label, AI recommendations)

### 6. 🎼 AgentPipeline (Orchestrator)

- **Role:** Conductor of the orchestra
- **Execution:** `Collector → Verifier → Scorer → Classifier`
- **Output:** `AgentTrace` (full audit log for XAI compliance)

---

## 💬 AI Chat System

- ⚡ **Powered by:** Groq Cloud API (sub-second inference)
- 🌍 **Multilingual:** English, Hindi, Marathi (auto-detection)
- 🧠 **Context-aware:** Uses ONLY active alerts (no hallucinations)
- 🎤 **Voice support:** Voice-to-text + Text-to-Speech (TTS)
- 🔄 **Fallback:** Hardcoded response if API > 5 seconds

### Example:
> *"Mumbai mein kya alerts hai?"*

➡️ Responds instantly in Hindi with verified alerts from current dataset.

---

## 📡 Telegram Bot Integration

### Features:
- 🤖 **Async Bot** using `python-telegram-bot` v20
- 🔘 **Inline Buttons** on each alert:
  - ✅ **Understood** → Increments Firestore `understoodCount`
  - ❓ **Not Clear** → Flags alert for admin review
  - 🔁 **Re-Verify** → Triggers fresh agent pipeline
- 📊 **Commands:** `/start`, `/ping`, `/status`, `/alerts`
- 🌐 **Multilingual summaries** via Groq (Marathi/Hindi/English)

### n8n Automation:
- Reads Google Sheets user registry
- Generates personalized alert summaries via Groq
- Sends targeted Telegram messages automatically

---

## 🗣️ MULTILINGUAL AI STACK

### Primary LLM: Groq Cloud (llama-3.3-70b-versatile)

- Ultra-fast inference (200+ tokens/sec)
- Translation: English ↔ Hindi ↔ Marathi
- Summarization & simplification
- Unstructured news parsing

### Translation & TTS: Sarvam AI

- Context-preserving native language translation
- Text-to-Speech for voice output
- Dynamic voice engine switching (hi-IN, mr-IN)

---

## 📱 Mobile Application (Flutter)

### Tech Stack:
- **Framework:** Flutter (Dart)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Navigation:** GoRouter (`go_router`)
- **Configuration:** `flutter_dotenv` (no hardcoded URLs)

### Features:
- 📊 **Live Disaster Dashboard** (real-time alert feed)
- 🤖 **AI Chat Assistant** (voice + text)
- 🎤 **Voice Input** + **Audio Output**
- 🔔 **Push Notifications** (Firebase Cloud Messaging)
- ✨ **Animations:** Lottie, Shimmer, Animate_Do
- 🛡️ **Admin Dashboard:** Live comprehension analytics

---

## ⚙️ Backend (FastAPI)

### Key Features:
- ⚡ Async ultra-fast APIs
- 🤖 4-agent BDI orchestration
- 🧠 Groq LLM integration
- 📡 RSS feed aggregation (TOI, NDTV, GDACS, ReliefWeb)
- ⏱️ Scheduler system (5-minute rotation)
- 📡 Telegram automation
- 💾 Local fallback engine (10 curated scenarios)

---

## 📡 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/active-alerts` | GET | Get all live alerts |
| `/alerts/filter` | GET | Filter alerts by location/severity/trust |
| `/chat` | POST | AI chatbot (multilingual, grounded) |
| `/verify-alert` | POST | Run 4-agent verification pipeline |
| `/re-verify/{id}` | POST | Force fresh verification |
| `/alert/{id}/verification` | GET | Get stored verification result |
| `/demo-scenarios` | GET | Return 3 test scenarios |
| `/send-telegram/{id}` | POST | Send alert via Telegram |
| `/system-status` | GET | Health check (AI agents + Firebase) |

---

## 🐳 Production DevOps Pipeline

### Philosophy: Security-first, portable, cloud-ready infrastructure.

### Phase 1: Dockerization
```dockerfile
# Multi-stage build
FROM python:3.10-slim as builder
# ... build dependencies

FROM python:3.10-slim
RUN adduser --disabled-password --gecos '' crisisuser
USER crisisuser
# Security: non-root, privilege escalation disabled
HEALTHCHECK --interval=30s CMD curl -f http://localhost:8000/health
```

### Phase 2: Docker Compose (Local Ecosystem)
```yaml
services:
  fastapi:     # CrisisClarity backend
  redis:       # Agent result caching
  postgres:    # Production logs
  ollama:      # Local LLM (hybrid AI)
  nginx:       # Reverse proxy/load balancer
```

### Phase 3: Kubernetes (Minikube)
```bash
minikube start
docker build -t crisisclarity-backend .
minikube image load crisisclarity-backend
kubectl apply -f DevOps/k8s/   # Deployments + Services
minikube service crisisclarity-service
```

### Phase 4: CI/CD (GitHub Actions)
**.github/workflows/backend-deploy.yml:**
1. **Lint:** `flake8` code quality
2. **Test:** Agent unit tests
3. **Security Audit:** `pip-audit` (CVE scanning)
4. **Build:** Docker multi-stage build
5. **Push:** Docker Hub (`indresh404/crisisclarity-backend`)

### Monitoring (Planned):
- Prometheus + Grafana for metrics (agent latency, trust score distribution, RSS fetch success)

---

## 💾 Local Fallback Engine

### Why?
To ensure demos **never fail** without internet or Firebase.

### How it works:
- Uses `news_data.json` with 10 curated disaster scenarios
- Loads instantly on startup (Batch 0 → all 10 events)
- Triggers automatically when Firestore unavailable

### Example scenarios:
- 🌊 Mumbai Flood Alert (Andheri subway submerged)
- 🏗️ Thane Building Collapse (Ghodbunder Road)
- 🌪️ Palghar Cyclone Warning (high tide + evacuation)
- 🏔️ Mumbra Landslide (heavy rainfall warning)
- 🔥 Pune Industrial Fire (chemical factory)

---

## 🔥 Completed Features

### Core Backend:
✅ FastAPI async server  
✅ 4-agent BDI verification pipeline  
✅ Groq LLM integration (llama-3.3-70b)  
✅ RSS feed aggregation (5 sources)  
✅ Trust scoring with weighted heuristics  
✅ XAI audit trail (agentTrace)  
✅ Local fallback system (10 scenarios)  
✅ 5-minute scheduler simulation  

### Messaging:
✅ Telegram bot (async, inline buttons)  
✅ Multilingual summaries via Groq  
✅ Comprehension tracking (Understood/Not Clear)  
✅ n8n automation ready  

### Mobile App:
✅ Flutter + Riverpod state management  
✅ AI chat screen (voice + TTS ready)  
✅ Dynamic backend URL via .env  
✅ Beautiful animations (Lottie, Shimmer)  

### DevOps:
✅ Docker multi-stage build  
✅ Docker Compose (5 services)  
✅ Kubernetes manifests (Minikube tested)  
✅ GitHub Actions CI/CD (lint → test → security → push)  
✅ Security: non-root containers, dependency scanning  

---

## 🚧 Future Scope (Production)

| Task | Priority |
|------|----------|
| ☁️ Cloud deployment (AWS/Render/Railway) | High |
| 🔥 Live Firestore sync (cross-device) | High |
| 🛰️ Satellite + drone data integration | Medium |
| 🚑 SOS emergency system | Medium |
| 📊 Prometheus + Grafana monitoring | Low |
| 🎤 Sarvam TTS full integration | Low |
| 📍 Rescue team tracking dashboard | Low |

---

## 🧪 How to Run Locally

### Prerequisites:
- Python 3.10+
- Flutter SDK
- Docker (optional, for full ecosystem)
- Groq API key (free tier available)

### 1️⃣ Backend (FastAPI)

```bash
cd crisisclarity-backend
pip install -r requirements.txt

# Create .env file
cat > .env << EOF
GROQ_API_KEY=your_groq_api_key
FIREBASE_CREDENTIALS=path/to/firebase.json  # optional
TELEGRAM_BOT_TOKEN=your_telegram_token      # optional
EOF

# Run server (with local fallback auto-enabled)
python main.py
# Server running at http://localhost:8000
```

### 2️⃣ Frontend (Flutter)

```bash
cd crisis_clarity

# Configure backend URL
echo "API_BASE_URL=http://192.168.x.x:8000" > .env   # Use your local IP

# Get dependencies
flutter pub get

# Run app
flutter run
```

### 3️⃣ Docker Compose (Full Ecosystem)

```bash
cd DevOps
docker-compose up -d
# Services: FastAPI, Redis, Postgres, Ollama, Nginx
# Access at http://localhost
```

### 4️⃣ Kubernetes (Minikube)

```bash
minikube start
docker build -t crisisclarity-backend ./crisisclarity-backend
minikube image load crisisclarity-backend
kubectl apply -f DevOps/k8s/
minikube service crisisclarity-service
```

### 5️⃣ Telegram Bot (Optional)

```bash
python bot/telegram_bot.py
# Bot runs in polling mode
# Search @CrisisClarityBot on Telegram
```

---

## 🔐 Security & Production Readiness

- ✅ **No Hardcoded Secrets:** All credentials in `.env` (excluded via `.gitignore`)
- ✅ **Non-Root Containers:** Docker runs as `crisisuser` (UID 1000)
- ✅ **Dependency Scanning:** `pip-audit` in CI/CD catches vulnerable packages
- ✅ **CORS:** Restricted to production domains
- ✅ **Firebase Auth:** Service account JSON mounted as secret in K8s
- ✅ **Health Checks:** Docker + K8s liveness/readiness probes

---

## 📊 Firebase Firestore Schema

**Collection:** `alerts`

| Field | Type | Description |
|-------|------|-------------|
| `trustScore` | number | 0-100 trust score |
| `trustStatus` | string | VERIFIED / PARTIALLY_VERIFIED / POSSIBLE_FAKE_NEWS |
| `verificationReason` | string | XAI explanation |
| `sourcesChecked` | array | List of RSS sources used |
| `conflictDetected` | boolean | Cross-source conflict flag |
| `agentTrace` | map | Full audit trail (4-agent output) |
| `understoodCount` | number | Telegram comprehension count |
| `notUnderstoodCount` | number | Telegram confusion count |
| `comprehensionPct` | number | Calculated percentage |
| `translations` | map | marathi, hindi, english versions |

---

## 🧠 Academic Relevance

### Subjects:
- **Software Engineering:** SDLC, Agile methodology
- **Full Stack Development:** API design + Mobile app
- **Cloud & DevOps:** Docker, Kubernetes, CI/CD pipelines
- **Design Thinking:** User-centered multilingual design
- **Agentic AI:** BDI Agents etc

---

## 🌍 SDG Alignment

| SDG | Goal | Implementation |
|-----|------|----------------|
| **SDG 11** | Sustainable Cities & Communities | Real-time disaster alerts for urban resilience |
| **SDG 13** | Climate Action | Early warning for floods, cyclones, landslides |
| **SDG 16** | Peace, Justice & Strong Institutions | Trust scoring combats misinformation |

---

## 🚀 Key Innovations

- 🔍 **Explainable AI (XAI):** Every alert has `trust_score` + `verification_reason` + `agentTrace`
- 🤖 **Multi-Agent Verification:** 4 specialized BDI agents with weighted source trust
- 🌐 **Multilingual + Voice:** English, Hindi, Marathi with TTS ready
- ⚡ **Ultra-Fast Inference:** Groq Cloud (200+ tokens/sec)
- 📴 **Offline Fallback:** 10 curated scenarios, zero dependency on internet
- 🔘 **Two-Way Feedback:** Telegram comprehension buttons close the communication loop
- 🐳 **Production DevOps:** Docker → Compose → K8s → CI/CD pipeline

---

## 📁 Project Structure

```
crisisclarity/
├── crisis_clarity/assets/icons/
│   └── Logo.png                     # App logo
├── crisisclarity-backend/           # FastAPI backend
│   ├── main.py                      # Entry point
│   ├── agents/                      # 4-agent pipeline
│   │   ├── data_collection_agent.py
│   │   ├── verification_agent.py
│   │   ├── scoring_agent.py
│   │   └── classification_agent.py
│   ├── models/                      # Pydantic schemas
│   ├── utils/                       # RSS, fallback engine
│   └── requirements.txt
├── crisis_clarity/                  # Flutter app
│   ├── lib/
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── ai_chat_screen.dart
│   │   │   └── admin_dashboard.dart
│   │   ├── providers/               # Riverpod state
│   │   └── services/                # API calls
│   └── .env                         # Backend URL
├── Docs/                            # Project documentation
│   ├── Indresh [33] (CrisisClarity) - [PPT].pptx
│   ├── MONTHLY REPORT.pdf
│   └── PROJECT REPORT.pdf
├── DevOps/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── k8s/                         # Kubernetes manifests
│   └── prometheus/                  # Monitoring configs
├── bot/
│   └── telegram_bot.py              # Async Telegram bot
├── .github/workflows/
│   └── backend-deploy.yml           # CI/CD pipeline
└── news_data.json                   # Local fallback scenarios
```

---

## 👨‍💻 Author

**Indresh Kumar**
B.E. Computer Engineering (Semester IV)
IDEA Lab Project

---

## Acknowledgments

- **Groq Cloud** for ultra-fast LLM inference
- **Firebase** for real-time database
- **Python Telegram Bot** community
- **Flutter** for cross-platform excellence

---


## ⭐ If You Like This Project

Give it a ⭐ on GitHub and support open-source disaster-tech!
```
