# CrisisClarity — Multi-Agent Disaster Verification Backend

> Transforms CrisisClarity from an "Alert Display App with n8n automation" into an
> "Intelligent Multi-Agent Disaster Verification Platform" with explainable AI verdicts.

## 🏗️ Architecture

### BDI (Belief-Desire-Intention) Agent Mapping

| Agent | BDI Role | Purpose | Syllabus |
|-------|----------|---------|----------|
| **DataCollectionAgent** | 🧠 Belief | Gathers world state from multiple sources | CO4 — Module IV |
| **VerificationAgent** | 💭 Desire | Determines what should be true (cross-checks consistency) | CO2 — Module II |
| **ScoringAgent** | 🎯 Intention | Calculates confidence level (0-100 trust score) | CO3 — Module III |
| **ClassificationAgent** | ⚡ Action | Produces human-readable verdict with XAI explanation | CO5/CO6 — Module V-VI |

### Execution Flow

```
Admin posts alert (Flutter) → Firestore
         ↓
Flutter calls POST /verify-alert
         ↓
    AgentPipeline.run(alertId)
         ↓
  ┌─────────────────────────────────────────┐
  │ 1. DataCollectionAgent.collect()        │ → Fetches Firestore + mock sources
  │ 2. VerificationAgent.verify()           │ → Cross-checks location/type/severity
  │ 3. ScoringAgent.score()                 │ → Calculates weighted trust score
  │ 4. ClassificationAgent.classify()       │ → VERIFIED / PARTIAL / FAKE_NEWS
  └─────────────────────────────────────────┘
         ↓
  Writes result to Firestore (agentTrace = XAI audit)
         ↓
  Returns JSON to Flutter → displays AI Verification Report
         ↓
  POST /send-telegram/{alertId} → sends alert with trust badge
```

## 📁 Project Structure

```
crisisclarity-backend/
├── main.py                          # FastAPI app with all endpoints
├── .env                             # Environment secrets
├── requirements.txt                 # Python dependencies
├── agents/
│   ├── data_collection_agent.py     # Agent 1 — Multi-source data collector
│   ├── verification_agent.py        # Agent 2 — Cross-verification engine
│   ├── scoring_agent.py             # Agent 3 — Trust score calculator
│   ├── classification_agent.py      # Agent 4 — Status classifier + XAI
│   ├── agent_pipeline.py            # Orchestrator — runs all 4 in sequence
│   └── mock_data.py                 # 3 demo scenarios + mock source data
├── bot/
│   ├── telegram_bot.py              # Main Python bot (replaces Node.js)
│   ├── alert_sender.py              # send_alert_with_verification()
│   └── handlers.py                  # /start /ping /status /alerts + callbacks
├── firebase/
│   ├── firestore_client.py          # Firebase Admin SDK setup
│   └── alert_repository.py          # Read/write alert verification results
├── models/
│   ├── alert_models.py              # Pydantic models for alert data
│   └── verification_models.py       # VerificationResult, ScoreBreakdown, etc.
└── utils/
    ├── groq_client.py               # Groq API wrapper for LLM simplification
    └── logger.py                    # Structured logging for agent traces
```

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd crisisclarity-backend
pip install -r requirements.txt
```

### 2. Configure Environment

Copy your Firebase service account JSON to the backend directory:
```bash
cp path/to/your-service-account.json ./firebase-service-account.json
```

Edit `.env` with your actual credentials:
```env
TELEGRAM_BOT_TOKEN=your_real_bot_token
GROQ_API_KEY=your_groq_api_key
FIREBASE_CREDENTIALS_PATH=./firebase-service-account.json
```

### 3. Run the FastAPI Backend

```bash
uvicorn main:app --reload
```

The API will be available at `http://localhost:8000`.
Interactive docs at `http://localhost:8000/docs`.

### 4. Run the Telegram Bot

```bash
python bot/telegram_bot.py
```

## 🧪 Demo Walkthrough

### Step 1: View Demo Scenarios
```bash
curl http://localhost:8000/demo-scenarios
```

### Step 2: Test HIGH TRUST (Scenario A)
```bash
curl -X POST http://localhost:8000/verify-alert \
  -H "Content-Type: application/json" \
  -d '{"alertId": "demo_a", "scenario": "A"}'
```
**Expected:** trustScore ~90, status: VERIFIED, sources: [admin, news]

### Step 3: Test MEDIUM TRUST (Scenario B)
```bash
curl -X POST http://localhost:8000/verify-alert \
  -H "Content-Type: application/json" \
  -d '{"alertId": "demo_b", "scenario": "B"}'
```
**Expected:** trustScore ~25, status: POSSIBLE_FAKE_NEWS, sources: [admin]

### Step 4: Test LOW TRUST / FAKE NEWS (Scenario C)
```bash
curl -X POST http://localhost:8000/verify-alert \
  -H "Content-Type: application/json" \
  -d '{"alertId": "demo_c", "scenario": "C"}'
```
**Expected:** trustScore ~5, status: POSSIBLE_FAKE_NEWS, conflictDetected: true

### Step 5: Test Telegram Bot
```bash
python bot/telegram_bot.py
# Then in Telegram: /start, /ping, /status, /alerts
```

## 📡 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/verify-alert` | Run 4-agent verification pipeline |
| GET | `/alert/{id}/verification` | Get stored verification result |
| POST | `/re-verify/{id}` | Re-run full pipeline |
| GET | `/demo-scenarios` | Get 3 test scenarios |
| POST | `/send-telegram/{id}` | Send Telegram alert with verification badge |
| GET | `/health` | Health check |

## 🤖 Telegram Bot Commands

| Command | Description | Origin |
|---------|-------------|--------|
| `/start` | Verification flow + welcome message | Existing (Node.js) |
| `/ping` | Health check | Existing (Node.js) |
| `/status` | Latest alert with trust score badge | **NEW** (Python) |
| `/alerts` | Last 5 alerts with status labels | **NEW** (Python) |

### Inline Keyboard Buttons (on each alert)
- ✅ **Understood** — Updates Firebase comprehension counter
- ❓ **Not Clear** — Flags alert as unclear
- 🔁 **Re-Verify** — Requests fresh verification

## 📚 Agentic AI Syllabus Mapping

| Course Outcome | Module | Implementation |
|---------------|--------|----------------|
| CO1 — Introduction | Module I | System architecture, agent definitions |
| CO2 — Core Components | Module II | VerificationAgent (environment modeling, POMDPs) |
| CO3 — LLM Tool-Use | Module III | ScoringAgent (reward model), Groq API integration |
| CO4 — Autonomous Agents | Module IV | DataCollectionAgent (planner-executor pattern) |
| CO5 — Multi-Agent Systems | Module V | AgentPipeline (cooperative coordination) |
| CO6 — Ethics & Safety | Module VI | ClassificationAgent (XAI, HITL feedback) |

## 🔒 Security Notes

- All credentials stored in `.env` (never committed to git)
- Firebase uses service account JSON (not hardcoded)
- Telegram bot token rotated via @BotFather if compromised
- CORS configured for production domain restriction
