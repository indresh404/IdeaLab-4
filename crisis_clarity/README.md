# CrisisClarity: Real-Time Disaster Intelligence OS

**CrisisClarity** is a full-stack, AI-powered disaster intelligence platform designed to provide verified, context-aware crisis information, primarily targeted for Mumbai and Maharashtra. It uses a **Cooperative Multi-Agent Pipeline** to verify disaster news, filter out fake news, and alert users in their native language using advanced LLMs and specialized Indic language models.

---

## 🏗️ Architecture & Technologies

CrisisClarity is divided into two main components: an ultra-fast **Python FastAPI Backend** that handles AI orchestration, and a dynamic **Flutter Mobile App** for end-users.

### 1. The Mobile App (Flutter)
The frontend is a beautifully designed, highly dynamic mobile application.
- **Framework:** Flutter (Dart)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** GoRouter (`go_router`)
- **Key Features:**
  - **Live Disaster Dashboard:** Dynamic alert feeds updated in real-time.
  - **Multilingual AI Voice Assistant:** Voice-to-Text and Text-to-Speech (TTS) integration. Seamlessly speaks and understands English, Hindi, and Marathi.
  - **Firebase Integration:** Auth, Firestore, Cloud Messaging.
  - **Beautiful Animations:** Lottie, Shimmer, and Animate_Do.

### 2. The Master System Engine (Python FastAPI)
The backend is the "Brain" of the operation, built on a robust Multi-Agent BDI (Belief-Desire-Intention) architecture.
- **Framework:** FastAPI
- **AI Models:** Groq Cloud API (LLaMA 3.1) for blazing-fast inference, **Sarvam AI** for native Indic language Translation and Text-to-Speech.
- **Key Features:**
  - **Multi-Agent Pipeline:** 5 specialized agents that work together to collect, verify, and score disaster data.
  - **Demo Scheduler:** A background task that rotates active alerts every 5 minutes to simulate a live, rapidly-changing disaster environment.
  - **Local Fallback Engine:** Instantly falls back to curated `news_data.json` scenarios if Firebase or live feeds are unavailable.
  - **Telegram Bot:** Asynchronously pushes verified critical alerts to subscribed users.

---

## 🤖 The Multi-Agent Pipeline (XAI)

The core verification engine uses a specialized Multi-Agent setup to ensure zero hallucinations and absolute clarity.

1. **`DataCollectionAgent` (Belief):** Scans the environment, fetching live RSS feeds (IMD, NDMA, BMC) or simulated JSON data. Aggregates unstructured data into a unified format.
2. **`VerificationAgent` (Desire):** The fact-checker. Cross-references data points across multiple sources. Detects conflicts (e.g., one source reports a fire, another denies it).
3. **`ScoringAgent` (Intention):** Calculates a mathematical `trust_score` (0-100). Applies heavy penalties for conflicts and massive boosts for authoritative sources.
4. **`ClassificationAgent` (Action):** Generates a human-readable Trust Label (`🟢 VERIFIED`, `🟠 UNVERIFIED`, `🔴 POSSIBLE_FAKE_NEWS`) and provides an XAI (Explainable AI) trace detailing *why* the decision was made.
5. **`NewsIngestionAgent` & `CrisisScoringAgent`:** Natural Language Processors powered by Groq to parse completely unstructured news articles into strict JSON schemas.

---

## 💬 Multilingual AI Chat & Sarvam Integration

CrisisClarity features a deeply integrated, highly localized AI chat system (`/chat` endpoint).
- **Context-Aware:** The AI is strictly grounded in the *active* disaster dataset. It will not hallucinate events outside of its current scope.
- **Sarvam AI Layer:** 
  - **Translation:** User queries in Hindi or Marathi are instantly translated to English via Sarvam, processed by Groq LLaMA, and then translated back to the user's native tongue.
  - **Text-to-Speech:** Generates lifelike localized audio responses for the Flutter frontend using Sarvam TTS.

---

## 📡 Core API Endpoints

The FastAPI backend exposes the following primary endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/active-alerts` | GET | Returns all currently active alerts (driven by the 5-min scheduler). |
| `/alerts/filter` | GET | Filters active alerts by location, severity, disaster type, or trust. |
| `/chat` | POST | Context-aware AI chatbot endpoint. Uses Groq + Sarvam for native language replies. |
| `/verify-alert` | POST | Runs a specific alert through the 4-agent verification pipeline. |
| `/translate` | POST | High-speed translation endpoint via Sarvam. |
| `/text-to-speech` | POST | Generates localized audio (TTS) for the given text. |
| `/send-telegram/{id}` | POST | Sends a Telegram notification with verification badges to a specific chat. |
| `/system-status` | GET | Returns the health of the AI agents, Scheduler, and Firebase connection. |

---

## 🚀 How to Run Locally

### 1. Backend (FastAPI)
```bash
cd crisisclarity-backend
# Install dependencies
pip install -r requirements.txt
# Set your environment variables in .env (GROQ_API_KEY, SARVAM_API_KEY, TELEGRAM_BOT_TOKEN)
# Run the server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Frontend (Flutter)
```bash
# Ensure your .env in the root flutter project points to your backend IP
# e.g., API_BASE_URL=http://192.168.x.x:8000
flutter pub get
flutter run
```

---

## ✅ Progress & Current Status
- **Completed:** Full backend migration to FastAPI, Sarvam+Groq multilingual AI integration, 5-agent XAI verification pipeline, robust offline-demo scheduler, Flutter Riverpod integration, and dynamic Telegram bot.
- **Next Steps (Production):** Live Firestore real-time syncing, Cloud Deployment (AWS/Render), and hardening Web Scraping for daily bulk ingestion.
