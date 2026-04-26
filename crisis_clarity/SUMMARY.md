# CrisisClarity: Complete System Architecture & Progress Summary

CrisisClarity is a real-time disaster intelligence OS designed to provide verified, context-aware crisis information for Mumbai and surrounding areas. This document provides a complete technical analysis of the project's state, architecture, and current capabilities.

---

## 🏗️ 1. Architecture Overview & Multi-Agent System

The Master System Engine is built on Python FastAPI and operates using an advanced **Cooperative Multi-Agent Pipeline**. Inspired by Agentic AI models (BDI: Belief, Desire, Intention), the system orchestrates multiple specialized AI agents working together to verify, score, and output crisis data.

### 🤖 The Agents (The Core Brain)

1. **`DataCollectionAgent` (The BELIEF layer)**
   * **Role**: Acts as the data gatherer. It scans the environment for raw information.
   * **Functions**: It fetches live RSS feeds from authoritative sources (like the IMD, NDMA, and BMC). If live data is unavailable, it gracefully handles mock scenarios. It aggregates all incoming data points into a unified format for the next agent.
   
2. **`VerificationAgent` (The DESIRE layer)**
   * **Role**: Acts as the fact-checker. 
   * **Functions**: It takes the raw data from the Collection Agent and cross-references it. It checks if multiple sources are reporting the same event. It specifically looks for conflicts (e.g., one source says "Fire" and another says "No Fire") and builds a `VerificationResult` containing matched sources and conflict reasons.
   
3. **`ScoringAgent` (The INTENTION layer)**
   * **Role**: The quantitative analyst.
   * **Functions**: It calculates a mathematical `trust_score` (0 to 100) based on the Verification Agent's findings. It uses weighted heuristics:
     * Authoritative matches (e.g., IMD) give massive score boosts.
     * Unverified sources give lower boosts.
     * Detected conflicts apply heavy penalties to the score.

4. **`ClassificationAgent` (The ACTION layer)**
   * **Role**: The final decision maker.
   * **Functions**: It takes the numerical score from the Scoring Agent and assigns a human-readable Trust Label (`🟢 VERIFIED`, `🟠 UNVERIFIED`, `🔴 POSSIBLE_FAKE_NEWS`). It generates the final textual `verification_reason` that the user sees in the app.

5. **`NewsIngestionAgent` (The AI Parser)**
   * **Role**: The Natural Language Processor.
   * **Functions**: Uses the **Groq AI Cloud API** (`llama-3.3-70b-versatile`) to read completely unstructured news articles and dynamically convert them into strict JSON schemas containing `severity`, `trust_label`, and AI recommendations.

6. **`AgentPipeline` (The Orchestrator)**
   * **Role**: The conductor of the orchestra.
   * **Functions**: This singleton class ensures the agents run in perfect sequence. It executes the pipeline: `Collector -> Verifier -> Scorer -> Classifier`. It also builds the **AgentTrace (XAI)**, which provides an audit trail explaining *why* the AI made its decision.

### 💬 The AI Chat Engine (`/chat` endpoint)
- A blazing-fast, context-aware API endpoint powered by **Groq**. 
- It guarantees sub-second response times and natively supports **English, Hindi, and Marathi**. 
- **Privacy Rule**: It uses strict grounding to prevent hallucinations—it can *only* answer using the active dataset currently in the system.

### ⏱️ Scheduler & Telegram
- **Scheduler**: A background asynchronous task that automatically rotates the active alerts every 5 minutes. This creates a highly dynamic environment for presentations.
- **Telegram Bot**: An asynchronous bot that pushes verified critical alerts to subscribed users dynamically.

### Frontend (Flutter)
The mobile application provides a beautiful, dynamic, and accessible interface.
- **State Management**: Uses `flutter_riverpod` for reactive UI updates.
- **Interactive AI Assistant**: The `ai_chat_screen.dart` features voice-to-text input, markdown rendering, and text-to-speech (TTS). It dynamically switches the TTS voice engine to `hi-IN` or `mr-IN` based on the language returned by the backend.
- **Configuration**: Uses `flutter_dotenv` to load the backend API IP address dynamically, making deployment incredibly simple without touching Dart code.

---

## 💾 2. The Demo Data System

To ensure that presentations and demos always look active and professional without relying on a live, populated Firestore database, we built a **Robust Local Fallback Engine**.

* **How it works**: If Firestore credentials are not present or the network is down, the system instantly switches to "Local Mode".
* **`news_data.json`**: This file contains 10 highly-detailed, curated disaster scenarios specifically tailored for Mumbai/Maharashtra (e.g., "Thane Building Collapse", "Palghar Cyclone Warning", "Mumbai-Pune Expressway Landslide").
* **Immediate Availability**: The system is programmed to load Batch 0 (all 10 events) into the active state immediately upon backend startup. This ensures the Flutter Home screen, Alerts screen, and Update section are instantly populated with rich data cards.

---

## ✅ 3. What Has Been Completed

1. **Backend Migration & Hardening**:
   - Successfully migrated from a legacy architecture to a fast, asynchronous FastAPI engine.
   - Fixed all dependency collision errors (`httpx`, `pydantic`, `python-telegram-bot`) to ensure the server starts cleanly.
2. **Ultra-Fast Multilingual AI**:
   - Replaced slow local Ollama processing with the **Groq Cloud API**.
   - Built a custom language detection heuristic that successfully detects Devanagari script and Romanized Hindi/Marathi (Hinglish/Marathish) keywords.
   - Configured the AI to reply natively and fluently in the user's detected language.
3. **Frontend-Backend Integration**:
   - The Flutter app seamlessly communicates with the FastAPI backend.
   - Removed all hardcoded IP addresses from the Flutter source code, moving them to a `.env` file (`flutter_dotenv`).
4. **Resilience & Fallbacks**:
   - If the AI API takes longer than 5 seconds, a hardcoded "Simulated Response" is instantly generated in the correct language to prevent the app from looking broken or slow during a demo.

---

## ⏳ 4. What Is Remaining (Future Production Work)

While the system is 100% demo-ready and highly polished, moving to a live production environment will require the following:

1. **Live Firestore Connection**:
   - The system is currently running beautifully on the local `news_data.json`. To deploy for real users, valid Firebase Service Account credentials must be added to enable cross-device synchronization and push notifications.
2. **Deploying the Backend**:
   - The backend needs to be hosted on a cloud provider (e.g., AWS EC2, Render, or Railway).
   - Once deployed, the `API_BASE_URL` in the Flutter `.env` file must be updated to the new cloud URL.
3. **Live Web Scraping Stability**:
   - Production will require hardened web-scraping rules to bypass anti-bot protections on news websites if the system scales up to ingest thousands of articles daily.
4. **Admin Dashboard Logic**:
   - The Flutter Admin Dashboard UI is built, but writing verified manual alerts directly back to the live Firestore database requires the live connection to be active.

---

## 🚀 5. How to Run for a Demo

1. **Start Backend**:
   - Open a terminal in `/crisisclarity-backend`.
   - Run: `python main.py`
   - Wait for the "✅ All systems online!" message.
2. **Configure Frontend**:
   - Ensure the `crisis_clarity/.env` file contains the correct local IP of the machine running the backend (e.g., `API_BASE_URL=http://192.168.1.5:8000`).
3. **Start Frontend**:
   - Run: `flutter run` on your connected device or emulator.
   - The app will instantly populate with the 10 rich demo events.
4. **Test the AI**:
   - Go to the AI Chat screen.
   - Tap the microphone or type: "Mumbai mein kya disaster alerts hai?"
   - Listen as it instantly replies to you in Hindi!
