"""
CrisisClarity — Alert Repository v2 (Firestore CRUD for Master System Engine)

Extends the original alert_repository with batch management,
event scoring updates, filtered queries, and seeding capabilities.
Keeps backward compatibility with Flutter's AlertModel expectations.
"""

import json
import os
from typing import Optional, Dict, Any, List
from datetime import datetime, timezone

from firebase_admin import firestore
from firebase.firestore_client import get_firestore_client, is_firestore_available
from utils.logger import setup_logger

logger = setup_logger("alert_repository_v2")

# ── Constants ─────────────────────────────────────────────────────────────────
ALERTS_COLLECTION = "alerts"
SYSTEM_STATE_DOC = "system_state"
SYSTEM_COLLECTION = "system"
BATCH_SIZE = 12  # Increased for demo to show more simultaneous events


# ─── SEEDING ──────────────────────────────────────────────────────────────────

def seed_events_from_json(json_path: str = "news_data.json") -> int:
    """
    Upload events from news_data.json to Firestore.
    Uses event_id as document ID for idempotency.
    Assigns batch_group (0, 1, 2) for rotation.
    Sets all events to isActive=False initially.

    Returns:
        Number of events seeded
    """
    db = get_firestore_client()
    if not db:
        logger.warning("Firestore not available — cannot seed events")
        return 0

    if not os.path.exists(json_path):
        logger.error(f"News data file not found: {json_path}")
        return 0

    with open(json_path, "r", encoding="utf-8") as f:
        events = json.load(f)

    count = 0
    for i, event in enumerate(events):
        event_id = event.get("event_id", f"EVT-{i+1:03d}")
        batch_group = i // BATCH_SIZE  # 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2

        # Map to Firestore schema compatible with Flutter AlertModel
        doc_data = _map_event_to_firestore(event, batch_group)

        try:
            db.collection(ALERTS_COLLECTION).document(event_id).set(doc_data, merge=True)
            count += 1
            logger.info(f"  ✅ Seeded {event_id} → batch {batch_group}")
        except Exception as e:
            logger.error(f"  ❌ Failed to seed {event_id}: {e}")

    logger.info(f"📦 Seeded {count}/{len(events)} events to Firestore")
    return count


def _map_event_to_firestore(event: dict, batch_group: int) -> dict:
    """Map a news_data.json event to the Firestore schema."""
    location = event.get("location", {})
    ai = event.get("ai_analysis", {})
    timestamps = event.get("timestamps", {})

    return {
        # Core fields (Flutter AlertModel compatible)
        "title": event.get("title", ""),
        "description": event.get("full_description", event.get("summary", "")),
        "disasterType": event.get("disaster_type", "unknown"),
        "severity": event.get("severity", "LOW").lower(),
        "affectedZones": [location.get("city", "Mumbai")],
        "postedBy": "CrisisClarity Engine",
        "isActive": False,  # Scheduler will activate
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,

        # v2 extended fields
        "event_id": event.get("event_id", ""),
        "summary": event.get("summary", ""),
        "full_description": event.get("full_description", ""),
        "location": location,
        "severity_score": event.get("severity_score", 0.0),
        "confidence_score": event.get("confidence_score", 0.0),
        "trust_label": event.get("trust_label", "UNVERIFIED"),
        "trustScore": int(event.get("confidence_score", 0.0) * 100),
        "trustStatus": _trust_label_to_status(event.get("trust_label", "UNVERIFIED")),
        "keywords": event.get("keywords", []),
        "sources": event.get("sources", []),
        "ai_analysis": ai,
        "batch_group": batch_group,
        "display_time": timestamps.get("display_time", ""),
        "expiry_time": timestamps.get("expiry_time", ""),

        # Feedback counters
        "understood": 0,
        "notUnderstood": 0,
        "totalViews": 0,

        # Verification fields
        "sourcesChecked": [s.get("source_name", "") for s in event.get("sources", [])],
        "verificationReason": f"Verified by {len(event.get('sources', []))} source(s)",
        "hasConflict": False,
        "usingRealData": True,
    }


def _trust_label_to_status(label: str) -> str:
    """Convert trust_label to Flutter-compatible trustStatus."""
    label_upper = label.upper()
    if label_upper == "VERIFIED":
        return "verified"
    elif label_upper in ("PARTIALLY_VERIFIED", "PARTIAL"):
        return "partial"
    elif label_upper in ("UNVERIFIED", "LOW"):
        return "fake"
    return "partial"


# ─── BATCH MANAGEMENT ─────────────────────────────────────────────────────────

def get_total_batches() -> int:
    """Get total number of batches based on seeded events."""
    db = get_firestore_client()
    if not db:
        return 0

    try:
        docs = db.collection(ALERTS_COLLECTION).stream()
        max_batch = -1
        for doc in docs:
            data = doc.to_dict()
            bg = data.get("batch_group", 0)
            if bg > max_batch:
                max_batch = bg
        return max_batch + 1 if max_batch >= 0 else 0
    except Exception as e:
        logger.error(f"Error getting total batches: {e}")
        return 3  # Default to 3 batches


def set_batch_active(batch_group: int) -> int:
    """
    Activate all events in the given batch group.
    Returns number of events activated.
    """
    db = get_firestore_client()
    if not db:
        return 0

    try:
        query = db.collection(ALERTS_COLLECTION).where("batch_group", "==", batch_group)
        docs = query.stream()
        count = 0
        for doc in docs:
            doc.reference.update({
                "isActive": True,
                "status": "active",
                "updatedAt": firestore.SERVER_TIMESTAMP,
            })
            count += 1
        logger.info(f"✅ Activated batch {batch_group}: {count} events")
        return count
    except Exception as e:
        logger.error(f"❌ Error activating batch {batch_group}: {e}")
        return 0


def deactivate_all_events() -> int:
    """
    Deactivate ALL events. Called before activating a new batch.
    Returns number of events deactivated.
    """
    db = get_firestore_client()
    if not db:
        return 0

    try:
        query = db.collection(ALERTS_COLLECTION).where("isActive", "==", True)
        docs = query.stream()
        count = 0
        for doc in docs:
            doc.reference.update({
                "isActive": False,
                "status": "inactive",
                "updatedAt": firestore.SERVER_TIMESTAMP,
            })
            count += 1
        logger.info(f"🔕 Deactivated {count} events")
        return count
    except Exception as e:
        logger.error(f"❌ Error deactivating events: {e}")
        return 0


# ─── ACTIVE ALERTS QUERIES ────────────────────────────────────────────────────

def get_active_alerts_full() -> List[Dict[str, Any]]:
    """
    Get all currently active alerts with FULL data (v2 schema).
    Used by the AI chatbot for context building.
    """
    db = get_firestore_client()
    if not db:
        logger.warning("Firestore not available — returning empty alerts")
        return []

    try:
        query = db.collection(ALERTS_COLLECTION).where("isActive", "==", True)
        docs = query.stream()
        alerts = []
        for doc in docs:
            data = doc.to_dict()
            data["doc_id"] = doc.id
            alerts.append(data)

        logger.info(f"📄 Fetched {len(alerts)} active alerts (full)")
        return alerts
    except Exception as e:
        logger.error(f"❌ Error fetching active alerts: {e}")
        return []


def get_news_feed() -> List[Dict[str, Any]]:
    """
    Get all currently active events from the 'news_feed' collection.
    These are the live results from the NewsIngestionAgent.
    """
    # Check local mode first if firestore is specifically not available
    if not is_firestore_available():
        if os.path.exists("live_news.json"):
            try:
                with open("live_news.json", "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception as e:
                logger.error(f"❌ Error reading live_news.json: {e}")
        return []

    db = get_firestore_client()
    if not db:
        # Fallback to local if client failed
        if os.path.exists("live_news.json"):
            with open("live_news.json", "r", encoding="utf-8") as f:
                return json.load(f)
        return []

    try:
        docs = db.collection("news_feed").order_by("timestamp", direction=firestore.Query.DESCENDING).limit(10).stream()
        events = []
        for doc in docs:
            data = doc.to_dict()
            data["doc_id"] = doc.id
            events.append(data)
        return events
    except Exception as e:
        logger.error(f"❌ Error fetching news feed from Firestore: {e}")
        # Final fallback
        if os.path.exists("live_news.json"):
            with open("live_news.json", "r", encoding="utf-8") as f:
                return json.load(f)
        return []


def get_alerts_by_filter(
    disaster_type: Optional[str] = None,
    location: Optional[str] = None,
    trust_label: Optional[str] = None,
    severity: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """
    Get active alerts filtered by disaster_type, location, trust_label, or severity.
    Filtering is done in-memory after fetching active alerts
    (Firestore doesn't support OR queries easily).
    """
    alerts = get_active_alerts_full()

    filtered = []
    for alert in alerts:
        # Disaster type filter
        if disaster_type:
            alert_dtype = alert.get("disaster_type", alert.get("disasterType", "")).lower()
            if disaster_type.lower() not in alert_dtype:
                continue

        # Location filter
        if location:
            loc = alert.get("location", {})
            loc_str = ""
            if isinstance(loc, dict):
                loc_str = f"{loc.get('city', '')} {loc.get('state', '')}".lower()
            elif isinstance(loc, str):
                loc_str = loc.lower()

            # Also check affectedZones
            zones = alert.get("affectedZones", [])
            zones_str = " ".join(zones).lower()

            if location.lower() not in loc_str and location.lower() not in zones_str:
                continue

        # Trust label filter
        if trust_label:
            alert_trust = alert.get("trust_label", alert.get("trustStatus", "")).upper()
            if trust_label.upper() not in alert_trust:
                continue

        # Severity filter
        if severity:
            alert_sev = alert.get("severity", "").lower()
            if severity.lower() != alert_sev:
                continue

        filtered.append(alert)

    # Sort by severity_score descending
    filtered.sort(key=lambda x: x.get("severity_score", 0), reverse=True)
    return filtered


# ─── AGENT SCORE UPDATES ──────────────────────────────────────────────────────

def update_event_scores(
    event_id: str,
    severity_score: float,
    confidence_score: float,
    severity_label: str,
    trust_label: str,
    ai_analysis: Optional[Dict[str, str]] = None,
) -> bool:
    """
    Update an event with computed agent scores.
    Called by the scheduler after running the AI pipeline on each event.
    """
    db = get_firestore_client()
    if not db:
        return False

    try:
        doc_ref = db.collection(ALERTS_COLLECTION).document(event_id)

        update_data = {
            "severity_score": severity_score,
            "confidence_score": confidence_score,
            "severity": severity_label.lower(),
            "trust_label": trust_label,
            "trustScore": int(confidence_score * 100),
            "trustStatus": _trust_label_to_status(trust_label),
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }

        if ai_analysis:
            update_data["ai_analysis"] = ai_analysis
            update_data["verificationReason"] = ai_analysis.get("risk_summary", "")

        doc_ref.update(update_data)
        logger.info(f"📊 Updated scores for {event_id}: sev={severity_score:.2f}, conf={confidence_score:.2f}, trust={trust_label}")
        return True
    except Exception as e:
        logger.error(f"❌ Error updating scores for {event_id}: {e}")
        return False


# ─── SYSTEM STATE ─────────────────────────────────────────────────────────────

def get_system_state() -> Dict[str, Any]:
    """Get the current system state (batch number, rotation time, etc.)."""
    db = get_firestore_client()
    if not db:
        return {"current_batch": 0, "total_batches": 3, "last_rotation": None}

    try:
        doc = db.collection(SYSTEM_COLLECTION).document(SYSTEM_STATE_DOC).get()
        if doc.exists:
            return doc.to_dict()
        return {"current_batch": 0, "total_batches": 3, "last_rotation": None}
    except Exception as e:
        logger.error(f"Error getting system state: {e}")
        return {"current_batch": 0, "total_batches": 3, "last_rotation": None}


def update_system_state(current_batch: int, total_batches: int) -> bool:
    """Update the system state after a rotation."""
    db = get_firestore_client()
    if not db:
        return False

    try:
        db.collection(SYSTEM_COLLECTION).document(SYSTEM_STATE_DOC).set({
            "current_batch": current_batch,
            "total_batches": total_batches,
            "last_rotation": firestore.SERVER_TIMESTAMP,
            "rotation_interval_seconds": 300,
        }, merge=True)
        return True
    except Exception as e:
        logger.error(f"Error updating system state: {e}")
        return False


def is_firestore_seeded() -> bool:
    """Check if Firestore has been seeded with events."""
    db = get_firestore_client()
    if not db:
        return False

    try:
        docs = db.collection(ALERTS_COLLECTION).limit(1).stream()
        for doc in docs:
            data = doc.to_dict()
            # Check if it has v2 fields (batch_group)
            if "batch_group" in data:
                return True
        return False
    except Exception:
        return False


# ─── LOCAL FALLBACK (when Firestore is not available) ─────────────────────────

_local_events: List[Dict[str, Any]] = []
_local_active_batch: int = 0


def load_local_events(json_path: str = "news_data.json", force_reload: bool = False) -> List[Dict[str, Any]]:
    """Load events from local JSON file as fallback."""
    global _local_events

    if _local_events and not force_reload:
        return _local_events

    if not os.path.exists(json_path):
        logger.warning(f"Local news data not found: {json_path}")
        return []

    with open(json_path, "r", encoding="utf-8") as f:
        _local_events = json.load(f)

    # Assign batch groups
    for i, event in enumerate(_local_events):
        event["batch_group"] = i // BATCH_SIZE
        event["isActive"] = (event["batch_group"] == 0)  # Make first batch immediately active

    logger.info(f"📦 Loaded {len(_local_events)} events from local JSON")
    return _local_events


def get_local_active_alerts() -> List[Dict[str, Any]]:
    """Get active alerts from local storage (fallback mode)."""
    events = load_local_events()
    return [e for e in events if e.get("batch_group") == _local_active_batch and e.get("isActive")]


def rotate_local_batch() -> int:
    """Rotate local batch (fallback mode). Returns new batch number."""
    global _local_active_batch
    
    # Force reload to pick up any new live_news.json data
    events = load_local_events(force_reload=True)
    total_batches = (len(events) // BATCH_SIZE) + (1 if len(events) % BATCH_SIZE else 0)

    # Deactivate current
    for e in events:
        e["isActive"] = False

    # Advance batch
    _local_active_batch = (_local_active_batch + 1) % total_batches

    # Activate new batch
    activated = 0
    for e in events:
        if e.get("batch_group") == _local_active_batch:
            e["isActive"] = True
            activated += 1

    logger.info(f"🔄 Local rotation → batch {_local_active_batch}, activated {activated} events")
    return _local_active_batch
