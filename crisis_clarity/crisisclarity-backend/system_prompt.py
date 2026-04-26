"""
CrisisClarity — Master System Prompt v2.0

This module contains the system prompt used by the AI chatbot
to answer user questions about currently active crisis events.
The prompt enforces strict grounding: the AI can ONLY answer
from the active alerts dataset, never hallucinate.
"""


def build_system_prompt(active_alerts: list[dict], news_feed: list[dict] = None) -> str:
    """
    Build the full system prompt with currently active alerts and live news injected.

    Args:
        active_alerts: List of active alert dicts from Firestore (Official)
        news_feed: List of live news events from intelligence engine (Unofficial)

    Returns:
        Complete system prompt string for Groq LLM
    """
    # Build the context blocks
    alerts_context = _format_alerts_for_context(active_alerts)
    news_context = _format_news_for_context(news_feed or [])

    return f"""You are the **CrisisClarity Intelligence Engine**, an AI assistant for a real-time disaster intelligence system focused on Mumbai/Maharashtra, India.

## YOUR ROLE
You help citizens understand current crisis events by answering questions based on the datasets provided below. You distinguish between **OFFICIAL ALERTS** (from government/admins) and **LIVE NEWS INTELLIGENCE** (extracted from news reports).

## 🏛️ OFFICIAL ACTIVE ALERTS (VERIFIED)
{alerts_context}

## 📡 LIVE NEWS INTELLIGENCE (REAL-TIME FEED)
{news_context}

## HOW TO ANSWER QUERIES

### (A) News-based factual question
Example: "How many died in the Dadar tree collapse?"
→ Search BOTH Official Alerts and Live News Feed.
→ Prioritize Official Alerts if they cover the same event.
→ Extract and return ONLY facts present in the data.
→ If the answer is not in the data, say "This information is not available in the current records."

### (B) Filter/category query
Example: "Any fire news?" or "Show me industrial accidents"
→ Filter both datasets by disaster_type.
→ Return matching events as a list with title, location, severity, and summary.

### (C) Location-based query
→ Filter both datasets by location (city field).
→ Return top 3-5 matching events.

### (D) Safety/advice query
→ Find relevant data in both datasets.
→ Return the recommended_action or safety advice provided.
→ Add general safety advice if needed.

## RESPONSE FORMAT (STRICT)
Always structure your response like this:

📰 **[Event Title]**
📍 Location: [city, state]
📝 [Summary or answer to the question]
🔴 Severity: [severity] | Trust: [trust_label]
ℹ️ Source: [Official Alert | Live News Feed]

⚠️ **Safety Advice**
[Recommended action from the data]

## HARD RULES — NEVER BREAK THESE
1. NEVER invent or fabricate news that is not in the datasets provided.
2. If you don't know the answer from the data, say "I don't have enough information about this specifically in my current live feed."
3. Distinguish between Official and News sources.
"""


def build_filter_prompt(query: str, active_alerts: list[dict]) -> str:
    """
    Build a prompt specifically for filter/search queries.
    Returns a simpler prompt focused on matching alerts.
    """
    alerts_context = _format_alerts_for_context(active_alerts)

    return f"""You are CrisisClarity AI. Given the active alerts below, answer the user's query.

ACTIVE ALERTS:
{alerts_context}

USER QUERY: {query}

Instructions:
- If the user asks to filter by type (fire, flood, etc.), return ONLY matching events
- If the user asks about a location, filter by that location
- Return results as a numbered list with: Title, Location, Severity, one-line Summary
- If no matches, say "No matching alerts found in the current active dataset."
- NEVER make up events. Only use the data above.
"""


def _format_alerts_for_context(alerts: list[dict]) -> str:
    """Format alert list into a readable context string for the LLM."""
    if not alerts:
        return "No official active alerts at this time."

    parts = []
    for i, alert in enumerate(alerts, 1):
        location = alert.get("location", {})
        if isinstance(location, dict):
            loc_str = f"{location.get('city', 'Unknown')}, {location.get('state', '')}"
        else:
            loc_str = str(location)

        ai = alert.get("ai_analysis", {})
        parts.append(f"""--- OFFICIAL ALERT {i}: {alert.get('event_id', f'EVT-{i:03d}')} ---
Title: {alert.get('title', 'No title')}
Summary: {alert.get('summary', '')}
Full Description: {alert.get('full_description', alert.get('description', ''))}
Location: {loc_str}
Disaster Type: {alert.get('disaster_type', alert.get('disasterType', 'unknown'))}
Severity: {alert.get('severity', 'unknown')}
Trust Label: {alert.get('trust_label', alert.get('trustStatus', 'unknown'))}
Recommended Action: {ai.get('recommended_action', 'N/A') if isinstance(ai, dict) else 'N/A'}
""")

    return "\n".join(parts)


def _format_news_for_context(news: list[dict]) -> str:
    """Format news events into context block."""
    if not news:
        return "No live news intelligence available at this time."

    parts = []
    for i, art in enumerate(news, 1):
        location = art.get("location", {})
        loc_str = f"{location.get('city', 'Unknown')}, {location.get('state', 'India')}"
        parts.append(f"""--- LIVE NEWS {i} ---
Title: {art.get('title', 'No title')}
Summary: {art.get('summary', 'No summary')}
Location: {loc_str}
Disaster Type: {art.get('disaster_type', 'unknown')}
Severity: {art.get('severity', 'LOW')}
Trust Label: {art.get('trust_label', 'UNVERIFIED')}
Timestamp: {art.get('timestamp', 'Recent')}
""")
    return "\n".join(parts)


# ── Quick query type detection (rule-based, no LLM needed) ──────────────────

FILTER_KEYWORDS = {
    "fire": ["fire", "blaze", "burning", "flames"],
    "flood": ["flood", "waterlogging", "rain", "submerged", "water"],
    "earthquake": ["earthquake", "tremor", "seismic", "quake"],
    "cyclone": ["cyclone", "storm", "hurricane", "wind"],
    "landslide": ["landslide", "mudslide", "debris"],
    "industrial accident": ["chemical", "gas leak", "factory", "industrial", "explosion"],
    "infrastructure failure": ["bridge", "building", "collapse", "power", "water contamination"],
    "heatwave": ["heat", "heatwave", "temperature", "hot"],
}

LOCATION_KEYWORDS = [
    "mumbai", "thane", "navi mumbai", "pune", "nashik",
    "andheri", "borivali", "dadar", "kurla", "chembur",
    "dharavi", "colaba", "bandra", "malad", "ghatkopar",
    "kasara", "mahul", "worli",
]


def detect_query_type(query: str) -> dict:
    """
    Detect the type of user query without using LLM.

    Returns:
        dict with keys:
            - type: "filter" | "location" | "factual" | "safety" | "general"
            - disaster_type: str or None (for filter queries)
            - location: str or None (for location queries)
    """
    ql = query.lower().strip()

    # Check for filter queries
    for dtype, keywords in FILTER_KEYWORDS.items():
        for kw in keywords:
            if kw in ql:
                return {"type": "filter", "disaster_type": dtype, "location": None}

    # Check for location queries
    for loc in LOCATION_KEYWORDS:
        if loc in ql:
            return {"type": "location", "disaster_type": None, "location": loc}

    # Check for safety queries
    safety_words = ["safe", "precaution", "advice", "should i", "evacuate", "shelter", "help"]
    if any(w in ql for w in safety_words):
        return {"type": "safety", "disaster_type": None, "location": None}

    # Check for greetings (only if the query is short to avoid catching long questions)
    indic_greetings = ["namaste", "namaskar", "नमस्ते", "नमस्कार", "shukriya", "dhanyawad"]
    greetings = ["hi", "hello", "hey", "what can you do", "who are you"] + indic_greetings
    if len(ql.split()) <= 4 and any(g in ql for g in greetings):
        return {"type": "general", "disaster_type": None, "location": None}

    # Default: factual question
    return {"type": "factual", "disaster_type": None, "location": None}
