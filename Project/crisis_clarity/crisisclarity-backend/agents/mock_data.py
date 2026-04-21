"""
CrisisClarity — Mock Data & Demo Scenarios
Agentic AI Syllabus — CO4, Module IV: Tool-Using & Autonomous Agents.

Pre-built demo scenarios simulate multi-source data collection
for demonstration purposes. In production, these would be replaced
by real API calls to news aggregators, social media monitors,
and government alert feeds.

Three scenarios test the full spectrum of trust verification:
  Scenario A: HIGH TRUST — admin + news agree (expected score ~90)
  Scenario B: MEDIUM TRUST — admin only, no confirmation (expected score ~25)
  Scenario C: LOW TRUST — social only, conflicts detected (expected score ~5)
"""

from datetime import datetime, timedelta
from typing import List, Dict, Any


# ─── INDIVIDUAL MOCK SOURCES ──────────────────────────────────────────────────


def _now_iso() -> str:
    """Current time as ISO8601 string."""
    return datetime.utcnow().isoformat() + "Z"


def _minutes_ago(minutes: int) -> str:
    """Time N minutes ago as ISO8601 string."""
    return (datetime.utcnow() - timedelta(minutes=minutes)).isoformat() + "Z"


# ─── SCENARIO A: HIGH TRUST ──────────────────────────────────────────────────
# Admin + News + Social all report flood in Kurla, high severity
# Scoring: admin(40) + news(30) + social(20) + all_agree(10) = 100 → VERIFIED

SCENARIO_A_SOURCES: List[Dict[str, Any]] = [
    {
        "source": "admin",
        "location": "Kurla",
        "disaster_type": "flood",
        "severity": "high",
        "description": "Heavy flooding reported in Kurla East. Water level rising near railway station. Residents advised to evacuate low-lying areas.",
        "timestamp": _minutes_ago(5),
        "trust_weight": 40,
    },
    {
        "source": "news",
        "location": "Kurla",
        "disaster_type": "flood",
        "severity": "high",
        "description": "NDTV reports severe waterlogging in Kurla area. BMC teams deployed. Local trains suspended on Harbour line.",
        "timestamp": _minutes_ago(3),
        "trust_weight": 30,
    },
    {
        "source": "social",
        "location": "Kurla",
        "disaster_type": "flood",
        "severity": "high",
        "description": "Kurla station completely flooded! Water entering platforms. Stay away from the area. #MumbaiRains #KurlaFlood",
        "timestamp": _minutes_ago(1),
        "trust_weight": 20,
    },
]


# ─── SCENARIO B: MEDIUM TRUST ────────────────────────────────────────────────
# Only admin alert, no news or social media confirmation
# Scoring: admin(40) + solo_penalty(-15) = 25 → POSSIBLE_FAKE_NEWS
# Demonstrates that even admin-only alerts need corroboration

SCENARIO_B_SOURCES: List[Dict[str, Any]] = [
    {
        "source": "admin",
        "location": "Dharavi",
        "disaster_type": "storm",
        "severity": "medium",
        "description": "Storm warning issued for Dharavi and surrounding areas. Strong winds expected. Secure loose objects and stay indoors.",
        "timestamp": _minutes_ago(10),
        "trust_weight": 40,
    },
]


# ─── SCENARIO C: LOW TRUST ───────────────────────────────────────────────────
# Only social media, conflicts with no admin confirmation
# Social says "massive fire" but no official source
# Expected: trustScore ~5, POSSIBLE_FAKE_NEWS, conflictDetected: true

SCENARIO_C_SOURCES: List[Dict[str, Any]] = [
    {
        "source": "social",
        "location": "Andheri",
        "disaster_type": "fire",
        "severity": "critical",
        "description": "MASSIVE FIRE in Andheri West!!! Multiple buildings on fire!!! Everyone evacuate NOW!!! #MumbaiFire #Breaking",
        "timestamp": _minutes_ago(2),
        "trust_weight": 20,
    },
]


# ─── SCENARIO METADATA ───────────────────────────────────────────────────────


DEMO_SCENARIOS: Dict[str, Dict[str, Any]] = {
    "A": {
        "scenario_id": "A",
        "name": "HIGH TRUST — Flood in Kurla",
        "description": "Admin and news sources both confirm flooding in Kurla East. Multiple trusted sources agree on disaster type and severity. Expected result: VERIFIED with high trust score.",
        "expected_score_range": "80-100",
        "expected_status": "VERIFIED",
        "sources": SCENARIO_A_SOURCES,
        "mock_alert": {
            "alert_id": "demo_scenario_a",
            "title": "Severe Flooding in Kurla East",
            "disasterType": "flood",
            "severity": "high",
            "affectedZones": ["Kurla East", "Kurla West"],
            "description": "Heavy flooding reported near Kurla railway station. Water level rising rapidly.",
            "isActive": True,
        },
    },
    "B": {
        "scenario_id": "B",
        "name": "MEDIUM TRUST — Storm Warning in Dharavi",
        "description": "Only admin has issued the alert. No news or social media confirmation available. Limited verification. Expected result: PARTIALLY_VERIFIED or lower.",
        "expected_score_range": "20-40",
        "expected_status": "PARTIALLY_VERIFIED or POSSIBLE_FAKE_NEWS",
        "sources": SCENARIO_B_SOURCES,
        "mock_alert": {
            "alert_id": "demo_scenario_b",
            "title": "Storm Warning for Dharavi",
            "disasterType": "storm",
            "severity": "medium",
            "affectedZones": ["Dharavi"],
            "description": "Storm warning with strong winds expected in Dharavi area.",
            "isActive": True,
        },
    },
    "C": {
        "scenario_id": "C",
        "name": "LOW TRUST — Unverified Fire Report",
        "description": "Only social media reports a massive fire in Andheri. No admin or news confirmation. Sensationalized language. Expected result: POSSIBLE_FAKE_NEWS with conflict detected.",
        "expected_score_range": "0-20",
        "expected_status": "POSSIBLE_FAKE_NEWS",
        "sources": SCENARIO_C_SOURCES,
        "mock_alert": {
            "alert_id": "demo_scenario_c",
            "title": "Unverified Fire Report — Andheri",
            "disasterType": "fire",
            "severity": "critical",
            "affectedZones": ["Andheri West"],
            "description": "Social media reports of fire in Andheri. NOT CONFIRMED by official sources.",
            "isActive": True,
        },
    },
}


def get_demo_scenario(scenario_key: str) -> Dict[str, Any]:
    """
    Get a demo scenario by key (A, B, or C).
    
    Returns the full scenario dict including sources and mock alert data.
    Raises KeyError if scenario doesn't exist.
    """
    key = scenario_key.upper()
    if key not in DEMO_SCENARIOS:
        raise KeyError(f"Unknown scenario '{scenario_key}'. Valid options: A, B, C")
    return DEMO_SCENARIOS[key]


def get_all_demo_scenarios() -> List[Dict[str, Any]]:
    """
    Get all demo scenarios for the GET /demo-scenarios endpoint.
    Returns a list of scenario metadata (without full source data for brevity).
    """
    return [
        {
            "scenario_id": s["scenario_id"],
            "name": s["name"],
            "description": s["description"],
            "expected_score_range": s["expected_score_range"],
            "expected_status": s["expected_status"],
            "source_count": len(s["sources"]),
            "sources_present": [src["source"] for src in s["sources"]],
        }
        for s in DEMO_SCENARIOS.values()
    ]
