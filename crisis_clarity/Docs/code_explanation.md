# 🚨 CrisisClarity: Detailed Codebase Explanation

This document provides a comprehensive, detailed breakdown of the CrisisClarity platform's codebase, specifically focusing on the 4-Agent BDI Automation, the reality of the News APIs, and the step-by-step workflow of the agent pipeline.

---

## 1. 🏗️ Project Overview & Main Features

CrisisClarity is an AI-powered disaster intelligence platform aimed at providing verified, context-aware crisis information for high-risk regions like Maharashtra. 

### Core Features:
- **Backend**: Built with **FastAPI** for ultra-fast, async request handling.
- **Multi-Agent Verification**: A custom pipeline of 4 specialized AI agents working together to verify disaster alerts.
- **Live News Ingestion**: Aggregates real-time news and official feeds using NewsAPI, GDELT, and RSS feeds.
- **Multilingual LLM & Voice**: Uses **Groq API (LLaMA 3.3)** for chat, summarization, and unstructured news parsing. Also explicitly integrates **Sarvam AI** for deep native translation (`mayura:v1` model) and Text-to-Speech (TTS) generation in English (`en-IN`), Hindi (`hi-IN`), and Marathi (`mr-IN`).
- **Frontend App**: Built with **Flutter** using Riverpod state management.
- **Telegram Bot**: Automated two-way communication allowing citizens to flag if an alert is clear or not.

---

## 2. 🤖 The 4-Agent Automation Pipeline (BDI Architecture)

The core innovation of the backend is the **AgentPipeline** (`agents/agent_pipeline.py`), which orchestrates 4 distinct agents based on the Belief-Desire-Intention (BDI) architecture.

### 🧠 Agent 1: DataCollectionAgent (Belief Layer)
**File**: `agents/data_collection_agent.py`
- **Role**: Gathers the "world state" from multiple sources.
- **How it works**: It fetches the initial Admin Alert from Firebase Firestore. Then, it calls the `NewsIngestionAgent` to pull relevant news articles from external APIs. It assigns dynamic "trust weights" to each source (e.g., Admin = 40, GDACS = 35, News = 28).

### 🔍 Agent 2: VerificationAgent (Desire Layer)
**File**: `agents/verification_agent.py`
- **Role**: Cross-validates the collected data to find consistencies or contradictions.
- **How it works**: It iterates through the collected data (Admin vs News vs Social Media). It uses specific comparison logic (`_cmp_loc`, `_cmp_type`, `_cmp_sev`) to match the location, disaster type, and severity. If a news outlet reports a "Storm" but the admin reports a "Fire", it registers a `conflict_detected = True` and logs the exact reason.

### 📊 Agent 3: ScoringAgent (Intention Layer)
**File**: `agents/scoring_agent.py`
- **Role**: Converts the text-based verification analysis into a quantitative **Trust Score (0-100)**.
- **How it works**:
  - Base score starts at 0.
  - Adds points based on the trust weights of the matched sources (e.g., +40 for Admin, +max news weight).
  - Deducts a heavy penalty (-30) if conflicts were found by the Verification Agent.
  - Deducts points (-15) if there is only a single source backing up the claim.
  - Adds a bonus (+10) if multiple high-trust sources agree.

### 🏷️ Agent 4: ClassificationAgent (Action Layer)
**File**: `agents/classification_agent.py`
- **Role**: Generates a human-readable verdict and an Explainable AI (XAI) reason.
- **How it works**:
  - Score ≥ 80 ➡️ `✅ VERIFIED`
  - Score 40-79 ➡️ `⚠️ PARTIALLY_VERIFIED`
  - Score < 40 ➡️ `🔴 POSSIBLE_FAKE_NEWS`
- **XAI output**: It uses the conflict reasons from Agent 2 and the scores from Agent 3 to generate a transparent explanation, such as: *"⚠️ Conflicting reports detected. News reports fire but Admin reports flood. Do not rely on this alert."*

---

## 3. 📰 Is the News API a Real Demo or Mocked?

**Answer: It is a Real Implementation with a Smart Mock Fallback.**

The file `agents/news_ingestion_agent.py` proves that the system actively queries live, real-world data:
1. **Real APIs Used**: It fetches live data concurrently from:
   - **NewsAPI**: Queries global news using advanced search operators (e.g., `(flood OR cyclone) AND India`).
   - **GDELT API**: A global database of human society that monitors real-time news globally.
   - **RSS Feeds** (`rss_feed_fetcher.py`): Parses XML feeds from Times of India, NDTV, GDACS (UN Disaster system), and ReliefWeb.
2. **Real Content Extraction**: It uses the `trafilatura` library to download and extract the full body text of the live web articles it finds.
3. **The Fallback Mechanism**: Since disaster intelligence is highly time-sensitive, there may be moments during a presentation where no disaster is actively happening in Maharashtra. To ensure the demo doesn't fail or look empty, the code has a fallback `_get_mock_events()` mechanism. **If the real API calls return zero relevant results, it injects high-quality mock events** (e.g., `mock_mumbai_flood_2024`).

So, it is **not a fake demo**; it is a robust production-grade system that attempts to get real live data first, and only uses mock data to maintain a presentable UI during dry spells.

---

## 4. 🔄 Complete End-to-End Workflow: How Everything Works Together

Here is exactly how a disaster alert makes its way through the system:

1. **Trigger Phase**: 
   - An admin posts a new disaster alert via the frontend, which saves to Firebase Firestore.
   - Alternatively, a background scheduler triggers a check for new global disasters.

2. **Ingestion & Collection**: 
   - `DataCollectionAgent` starts. It calls `NewsIngestionAgent.run_pipeline()`.
   - The News engine fires asynchronous requests to NewsAPI, GDELT, and RSS feeds.
   - It filters the incoming articles looking for keywords like "flood", "mumbai", "landslide" and extracts their full text.

3. **Multi-Agent Verification Pipeline**:
   - `AgentPipeline.run(alert_id)` takes over.
   - The data is passed to `VerificationAgent` to ensure the news aligns with the admin's claim.
   - It is then passed to `ScoringAgent` to calculate the mathematical Trust Score.
   - Finally, `ClassificationAgent` decides if the alert is VERIFIED or FAKE.

4. **Storage & XAI Audit**: 
   - The final Verification Result is packed with an `AgentTrace` object. This trace contains the exact data every agent saw and decided. 
   - The result is pushed to Firestore.

5. **Citizen Delivery (Frontend & Telegram)**:
   - The Flutter App reads from Firestore in real-time. It displays the Trust Score and the XAI `verification_reason` so the user knows *why* the alert was verified.
   - Simultaneously, the Telegram bot pushes an alert message to users, featuring inline buttons ("Understood", "Not Clear") that send feedback back to the server to calculate citizen comprehension.
   - If a citizen has questions, they use the Groq LLaMA 3.3 powered Chatbot in the app, which restricts its answers **strictly** to the verified alerts in the database (preventing hallucinations).
