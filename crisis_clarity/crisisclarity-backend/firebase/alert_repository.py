"""
CrisisClarity — Alert Repository (Firestore CRUD)
Agentic AI Syllabus — CO4, Module IV: Autonomous Agents.

Repository pattern for reading and writing alert verification results
to Firebase Firestore. This acts as the persistent Belief store in
the BDI architecture — agents update their beliefs here after processing.

Non-blocking async writes ensure the agent pipeline stays responsive.
"""

from typing import Optional, Dict, Any, List
from datetime import datetime

from firebase_admin import firestore

from firebase.firestore_client import get_firestore_client
from models.verification_models import VerificationResult
from utils.logger import setup_logger

logger = setup_logger("alert_repository")


# ─── READ OPERATIONS ──────────────────────────────────────────────────────────


def get_alert_by_id(alert_id: str) -> Optional[Dict[str, Any]]:
    """
    Fetch a single alert document from Firestore.
    
    Returns the alert data dict or None if not found.
    Maps Firestore fields to the structure expected by agents.
    """
    db = get_firestore_client()
    if not db:
        logger.warning("Firestore not available — cannot fetch alert")
        return None
    
    try:
        doc_ref = db.collection("alerts").document(alert_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            logger.warning(f"Alert {alert_id} not found in Firestore")
            return None
        
        data = doc.to_dict()
        data["alert_id"] = doc.id
        logger.info(f"📄 Fetched alert {alert_id}: type={data.get('disasterType')}, zones={data.get('affectedZones')}")
        return data
    except Exception as e:
        logger.error(f"❌ Error fetching alert {alert_id}: {e}")
        return None


def get_active_alerts(limit: int = 5) -> List[Dict[str, Any]]:
    """
    Fetch the latest active alerts from Firestore.
    Used by the Telegram /alerts command.
    """
    db = get_firestore_client()
    if not db:
        return []
    
    try:
        query = (
            db.collection("alerts")
            .where("isActive", "==", True)
            .order_by("createdAt", direction=firestore.Query.DESCENDING)
            .limit(limit)
        )
        docs = query.stream()
        
        alerts = []
        for doc in docs:
            data = doc.to_dict()
            data["alert_id"] = doc.id
            alerts.append(data)
        
        logger.info(f"📄 Fetched {len(alerts)} active alerts")
        return alerts
    except Exception as e:
        logger.error(f"❌ Error fetching active alerts: {e}")
        return []


def get_latest_alert() -> Optional[Dict[str, Any]]:
    """
    Get the single most recent active alert.
    Used by the Telegram /status command.
    """
    alerts = get_active_alerts(limit=1)
    return alerts[0] if alerts else None


def get_verification_result(alert_id: str) -> Optional[Dict[str, Any]]:
    """
    Fetch stored verification result for an alert.
    Returns the verification fields from the alert document.
    """
    alert = get_alert_by_id(alert_id)
    if not alert:
        return None
    
    # Extract verification-specific fields
    return {
        "trust_score": alert.get("trustScore", 0),
        "trust_status": alert.get("trustStatus", "pending"),
        "trust_label": _format_trust_label(alert.get("trustStatus", "pending"), alert.get("trustScore", 0)),
        "sources_checked": alert.get("sourcesChecked", []),
        "verification_reason": alert.get("verificationReason", "Not yet verified"),
        "conflict_detected": alert.get("hasConflict", False),
        "conflict_reason": alert.get("conflictReason", None),
        "agent_trace": alert.get("agentTrace", None),
    }


# ─── WRITE OPERATIONS ─────────────────────────────────────────────────────────


def save_verification_result(alert_id: str, result: VerificationResult) -> bool:
    """
    Write verification result back to the Firestore alert document.
    
    CO4: After the agent pipeline completes, beliefs are persisted
    so the Flutter app can read the updated verification state.
    
    Updates these fields on the alert document:
    - trustScore, trustStatus, verificationReason
    - sourcesChecked, hasConflict, conflictReason
    - agentTrace (full XAI audit trail)
    - updatedAt timestamp
    """
    db = get_firestore_client()
    if not db:
        logger.warning("Firestore not available — verification result not saved")
        return False
    
    try:
        doc_ref = db.collection("alerts").document(alert_id)
        
        # Map to Flutter expected values
        status_map = {
            "VERIFIED": "verified",
            "PARTIALLY_VERIFIED": "partial",
            "POSSIBLE_FAKE_NEWS": "fake"
        }
        trust_status = status_map.get(result.trust_status, "partial")

        # Prepare update payload — matches Flutter AlertModel fields
        update_data = {
            "trustScore": result.trust_score,
            "trustStatus": trust_status,
            "verificationReason": result.verification_reason,
            "sourcesChecked": result.sources_checked,
            "hasConflict": result.conflict_detected,
            "conflictReason": result.conflict_reason,
            "usingRealData": result.using_real_data,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }
        
        # Store agent trace as a nested map for XAI
        if result.agent_trace:
            update_data["agentTrace"] = {
                "dataCollected": result.agent_trace.data_collected,
                "verificationResult": result.agent_trace.verification_result,
                "scoreBreakdown": result.agent_trace.score_breakdown,
            }
        
        doc_ref.update(update_data)
        logger.info(f"✅ Saved verification for alert {alert_id}: score={result.trust_score}, status={result.trust_status}")
        return True
    except Exception as e:
        logger.error(f"❌ Error saving verification for {alert_id}: {e}")
        return False


def update_comprehension_feedback(alert_id: str, feedback_type: str) -> bool:
    """
    Update comprehension feedback counters (Understood / Not Understood).
    Called when a Telegram user taps the feedback buttons.
    
    Args:
        alert_id: Firestore document ID
        feedback_type: 'understood' or 'not_understood'
    """
    db = get_firestore_client()
    if not db:
        return False
    
    try:
        doc_ref = db.collection("alerts").document(alert_id)
        
        if feedback_type == "understood":
            doc_ref.update({"understood": firestore.Increment(1)})
        elif feedback_type == "not_understood":
            doc_ref.update({"notUnderstood": firestore.Increment(1)})
        else:
            logger.warning(f"Unknown feedback type: {feedback_type}")
            return False
        
        logger.info(f"📊 Updated feedback for alert {alert_id}: {feedback_type}")
        return True
    except Exception as e:
        logger.error(f"❌ Error updating feedback for {alert_id}: {e}")
        return False


# ─── HELPERS ───────────────────────────────────────────────────────────────────


def _format_trust_label(status: str, score: int) -> str:
    """Format a trust label with emoji for display."""
    status_lower = status.lower()
    if status_lower == "verified":
        return f"✅ VERIFIED (Score: {score}/100)"
    elif status_lower == "partial":
        return f"⚠️ PARTIALLY VERIFIED (Score: {score}/100)"
    elif status_lower == "fake":
        return f"🔴 POSSIBLE FAKE NEWS (Score: {score}/100)"
    else:
        return f"❓ PENDING (Score: {score}/100)"
