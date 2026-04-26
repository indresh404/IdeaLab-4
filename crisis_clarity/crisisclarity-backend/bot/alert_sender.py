"""
CrisisClarity — Telegram Alert Sender

Async function called by FastAPI backend when a new alert is posted.
Sends formatted alert messages with verification badges and
inline feedback keyboards to subscribed users.

CO6: Human-in-the-Loop — alerts include comprehension feedback
buttons so citizens can report if they understood the alert.
"""

import os
from typing import Dict, Any, Optional, List
from telegram import Bot
from dotenv import load_dotenv

from bot.handlers import build_feedback_keyboard, _format_trust_badge
from utils.logger import setup_logger

load_dotenv()
logger = setup_logger("alert_sender")


def _get_bot() -> Optional[Bot]:
    """Get a Telegram Bot instance for sending messages."""
    token = os.getenv("TELEGRAM_BOT_TOKEN", "")
    if not token or token == "your_token_here":
        logger.warning("⚠️ TELEGRAM_BOT_TOKEN not set")
        return None
    return Bot(token=token)


async def send_alert_with_verification(
    chat_id: int,
    alert_data: Dict[str, Any],
    verification_result: Optional[Dict[str, Any]] = None,
) -> bool:
    """
    Send a formatted alert message with verification badge to a user.

    Message format includes:
    - Crisis alert header with location, type, severity
    - Action items (what to do)
    - Verification report with trust badge
    - Inline feedback buttons

    Args:
        chat_id: Telegram chat ID of the recipient
        alert_data: Alert document from Firestore
        verification_result: Optional verification data

    Returns:
        True if message was sent successfully
    """
    bot = _get_bot()
    if not bot:
        logger.error("Cannot send alert — bot not configured")
        return False

    alert_id = alert_data.get("alert_id", alert_data.get("id", "unknown"))
    location = ", ".join(alert_data.get("affectedZones", ["Mumbai"]))
    dtype = alert_data.get("disasterType", "unknown").capitalize()
    severity = alert_data.get("severity", "unknown").capitalize()
    description = alert_data.get("description", "")

    # Build action items based on disaster type
    actions = _get_action_items(alert_data.get("disasterType", "unknown"))

    # Build verification section
    if verification_result:
        score = verification_result.get("trust_score", 0)
        status = verification_result.get("trust_status", "pending")
        reason = verification_result.get("verification_reason", "")
        sources = verification_result.get("sources_checked", [])
        badge = _format_trust_badge(status, score)
        source_text = " + ".join([s.capitalize() for s in sources]) + " confirmed" if sources else "No sources"
        verif_section = (
            f"─── VERIFICATION REPORT ───\n"
            f"{badge}\n"
            f"Sources: {source_text}\n"
            f"_{reason}_"
        )
    else:
        verif_section = "─── VERIFICATION ───\n❓ *Pending verification...*"

    message = (
        f"🚨 *CRISIS CLARITY ALERT*\n\n"
        f"📍 *Location:* {location}\n"
        f"⚠️ *Type:* {dtype}\n"
        f"🔴 *Severity:* {severity}\n\n"
        f"📋 *What to do:*\n{actions}\n\n"
        f"{verif_section}\n"
        f"─────────────────────────\n"
        f"Reply /status for updates"
    )

    try:
        keyboard = build_feedback_keyboard(alert_id)
        async with bot:
            await bot.send_message(
                chat_id=chat_id,
                text=message,
                parse_mode="Markdown",
                reply_markup=keyboard,
            )
        logger.info(f"✅ Alert sent to chat {chat_id}: {dtype} in {location}")
        return True
    except Exception as e:
        logger.error(f"❌ Failed to send alert to {chat_id}: {e}")
        return False


async def send_alert_to_multiple(
    chat_ids: List[int],
    alert_data: Dict[str, Any],
    verification_result: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Send alert to multiple chat IDs. Returns success/failure counts."""
    success = 0
    failed = 0
    for cid in chat_ids:
        ok = await send_alert_with_verification(cid, alert_data, verification_result)
        if ok:
            success += 1
        else:
            failed += 1
    logger.info(f"📤 Bulk send complete: {success} sent, {failed} failed")
    return {"sent": success, "failed": failed, "total": len(chat_ids)}


def _get_action_items(disaster_type: str) -> str:
    """Get contextual action items based on disaster type."""
    actions = {
        "flood": (
            "1. Move to higher ground immediately\n"
            "2. Avoid waterlogged roads\n"
            "3. Contact NDRF: 1078"
        ),
        "fire": (
            "1. Evacuate the building immediately\n"
            "2. Call Fire Brigade: 101\n"
            "3. Do not use elevators"
        ),
        "storm": (
            "1. Stay indoors and away from windows\n"
            "2. Secure loose objects outside\n"
            "3. Keep emergency kit ready"
        ),
        "cyclone": (
            "1. Move to a sturdy shelter immediately\n"
            "2. Stay away from the coast\n"
            "3. Follow BMC updates on radio"
        ),
        "evacuation": (
            "1. Follow designated evacuation routes\n"
            "2. Carry essential documents and medicines\n"
            "3. Report to nearest relief center"
        ),
    }
    return actions.get(disaster_type.lower(), (
        "1. Stay calm and follow official instructions\n"
        "2. Keep emergency contacts ready\n"
        "3. Contact NDRF helpline: 1078"
    ))
