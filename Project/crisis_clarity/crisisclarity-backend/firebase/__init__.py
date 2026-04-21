"""CrisisClarity Firebase Package — Firestore client and alert repository."""

from .firestore_client import get_firestore_client, is_firestore_available
from .alert_repository import (
    get_alert_by_id,
    get_active_alerts,
    get_latest_alert,
    get_verification_result,
    save_verification_result,
    update_comprehension_feedback,
)

__all__ = [
    "get_firestore_client",
    "is_firestore_available",
    "get_alert_by_id",
    "get_active_alerts",
    "get_latest_alert",
    "get_verification_result",
    "save_verification_result",
    "update_comprehension_feedback",
]
