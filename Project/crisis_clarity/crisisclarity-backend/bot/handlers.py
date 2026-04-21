"""
CrisisClarity — Telegram Bot Command & Callback Handlers

Agentic AI Syllabus — CO4, Module IV: Autonomous Agents.
The Telegram bot acts as the user-facing interface for the
multi-agent system. It delivers verified alerts with trust
badges and collects comprehension feedback (HITL).

Preserves ALL existing functionality from the Node.js bot:
- /start with userId deep-linking for verification
- /ping health check
- General message handler with chat_id display

NEW Python-only features:
- /status: Shows latest alert with trust score badge
- /alerts: Lists last 5 alerts with status labels
- Inline keyboard callbacks for comprehension feedback
"""

import os
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import ContextTypes
from dotenv import load_dotenv

from firebase.alert_repository import (
    get_latest_alert,
    get_active_alerts,
    update_comprehension_feedback,
)
from firebase.alert_repository_v2 import get_active_alerts_full, get_alerts_by_filter
from utils.logger import setup_logger

load_dotenv()
logger = setup_logger("telegram_handlers")


# ─── /start COMMAND ───────────────────────────────────────────────────────────

async def start_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """
    Handle /start command. Supports deep-linking with userId.
    
    Drop-in replacement for the Node.js bot's /start handler.
    - With userId param (/start userId123): send verification code + chat_id
    - Without param: send welcome message with chat_id
    """
    chat_id = update.effective_chat.id
    user_id_param = context.args[0] if context.args else None

    logger.info(f"📨 /start from chat {chat_id}, userId: {user_id_param or 'none'}")

    if user_id_param:
        message = (
            f"🔐 *Verification Code:* `{user_id_param}`\n\n"
            f"📱 *Your Chat ID:* `{chat_id}`\n\n"
            f"📋 *How to verify:*\n"
            f"1️⃣ Copy the Verification Code\n"
            f"2️⃣ Copy the Chat ID\n"
            f"3️⃣ Go back to Crisis Clarity app\n"
            f"4️⃣ Paste both fields\n"
            f"5️⃣ Tap \"VERIFY & LINK\"\n\n"
            f"✅ You will start receiving alerts immediately!"
        )
        logger.info(f"✅ Sent verification to user {user_id_param}")
    else:
        message = (
            f"🤖 *Welcome to Crisis Clarity Bot!*\n\n"
            f"This bot sends you real-time crisis alerts for your area.\n\n"
            f"*Your Chat ID:* `{chat_id}`\n\n"
            f"📱 *To get started:*\n"
            f"1. Open the Crisis Clarity app\n"
            f"2. Complete signup\n"
            f"3. Click \"Open Telegram Bot\"\n"
            f"4. Come back here and press Start\n"
            f"5. Copy the verification code\n\n"
            f"⚠️ *Note:* Only users who sign up through the app will receive alerts.\n\n"
            f"*Commands:*\n"
            f"/status — Latest alert with trust score\n"
            f"/alerts — Last 5 alerts\n"
            f"/ping — Check bot health"
        )
        logger.info(f"📢 Welcome message sent to chat {chat_id}")

    await context.bot.send_message(chat_id=chat_id, text=message, parse_mode="Markdown")


# ─── /ping COMMAND ────────────────────────────────────────────────────────────

async def ping_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /ping command — health check. Same as Node.js bot."""
    chat_id = update.effective_chat.id
    await context.bot.send_message(chat_id=chat_id, text="🏓 Pong! Bot is working!")
    logger.info(f"🏓 Ping received from {chat_id}")


# ─── /status COMMAND (NEW) ───────────────────────────────────────────────────

async def status_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """
    NEW: Show latest active alert with trust score badge.
    Displays: 🟢 VERIFIED / 🟡 PARTIAL / 🔴 FAKE with score.
    """
    chat_id = update.effective_chat.id
    logger.info(f"📊 /status from chat {chat_id}")

    alert = get_latest_alert()

    if not alert:
        await context.bot.send_message(
            chat_id=chat_id,
            text="ℹ️ No active alerts at this time.\nStay safe! 🙏",
        )
        return

    badge = _format_trust_badge(alert.get("trustStatus", "pending"), alert.get("trustScore", 0))
    zones = ", ".join(alert.get("affectedZones", ["Unknown"]))
    dtype = alert.get("disasterType", "unknown").capitalize()
    severity = alert.get("severity", "unknown").capitalize()

    message = (
        f"📊 *Latest Alert Status*\n\n"
        f"📍 *Location:* {zones}\n"
        f"⚠️ *Type:* {dtype}\n"
        f"🔴 *Severity:* {severity}\n\n"
        f"─── VERIFICATION ───\n"
        f"{badge}\n\n"
        f"_{alert.get('verificationReason', 'Awaiting verification...')}_\n\n"
        f"Reply /alerts for more alerts"
    )

    await context.bot.send_message(chat_id=chat_id, text=message, parse_mode="Markdown")


# ─── /alerts COMMAND (NEW) ───────────────────────────────────────────────────

async def alerts_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """
    NEW: List last 5 active alerts with status labels.
    """
    chat_id = update.effective_chat.id
    logger.info(f"📋 /alerts from chat {chat_id}")

    alerts = get_active_alerts(limit=5)

    if not alerts:
        await context.bot.send_message(
            chat_id=chat_id,
            text="ℹ️ No active alerts at this time.\nStay safe! 🙏",
        )
        return

    lines = ["📋 *Recent Alerts*\n"]
    for i, alert in enumerate(alerts, 1):
        badge = _format_trust_badge_short(alert.get("trustStatus"), alert.get("trustScore", 0))
        zones = ", ".join(alert.get("affectedZones", [])[:2])
        dtype = alert.get("disasterType", "?").capitalize()
        lines.append(f"{i}. {badge} *{dtype}* — {zones}")

    lines.append("\nReply /status for detailed latest alert")
    message = "\n".join(lines)

    await context.bot.send_message(chat_id=chat_id, text=message, parse_mode="Markdown")


# ─── /news COMMAND (NEW v2) ──────────────────────────────────────────────────

async def news_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """
    NEW v2: List all currently active alerts from the rotation batch.
    Shows event title, severity, confidence, and location.
    """
    chat_id = update.effective_chat.id
    logger.info(f"📰 /news from chat {chat_id}")

    try:
        active = get_active_alerts_full()
    except Exception:
        active = []

    if not active:
        await context.bot.send_message(
            chat_id=chat_id,
            text="ℹ️ No active alerts at this time.\nThe system rotates every 5 minutes — check back soon! 🔄",
        )
        return

    lines = [f"📰 *Active Crisis Alerts ({len(active)} events)*\n"]
    for i, a in enumerate(active, 1):
        title = a.get("title", "No title")[:50]
        sev = a.get("severity", "unknown").upper()
        conf = int(a.get("confidence_score", 0) * 100)
        trust = a.get("trust_label", "UNKNOWN")
        loc = a.get("location", {})
        city = loc.get("city", "Unknown") if isinstance(loc, dict) else str(loc)

        badge = "🔴" if sev in ("CRITICAL", "HIGH") else "🟡" if sev == "MEDIUM" else "🟢"
        lines.append(f"{badge} *{i}. {title}*")
        lines.append(f"   📍 {city} | ⚠️ {sev} | ✅ {conf}% {trust}")

    lines.append("\nUse /filter \_type\_ to filter by disaster type")
    await context.bot.send_message(chat_id=chat_id, text="\n".join(lines), parse_mode="Markdown")


# ─── /filter COMMAND (NEW v2) ────────────────────────────────────────────────

async def filter_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """
    NEW v2: Filter active alerts by disaster type.
    Usage: /filter fire  or  /filter flood
    """
    chat_id = update.effective_chat.id
    filter_type = context.args[0].lower() if context.args else None

    if not filter_type:
        await context.bot.send_message(
            chat_id=chat_id,
            text="Usage: /filter <type>\n\nExamples:\n/filter fire\n/filter flood\n/filter earthquake",
        )
        return

    logger.info(f"🔍 /filter {filter_type} from chat {chat_id}")

    try:
        filtered = get_alerts_by_filter(disaster_type=filter_type)
    except Exception:
        filtered = []

    if not filtered:
        await context.bot.send_message(
            chat_id=chat_id,
            text=f"ℹ️ No active alerts matching *{filter_type}* at this time.",
            parse_mode="Markdown",
        )
        return

    lines = [f"🔍 *Alerts: {filter_type.capitalize()}* ({len(filtered)} found)\n"]
    for i, a in enumerate(filtered, 1):
        title = a.get("title", "No title")[:50]
        sev = a.get("severity", "unknown").upper()
        lines.append(f"{i}. ⚠️ *{title}*\n   🔴 {sev} | Confidence: {int(a.get('confidence_score', 0) * 100)}%")

    await context.bot.send_message(chat_id=chat_id, text="\n".join(lines), parse_mode="Markdown")


# ─── GENERAL MESSAGE HANDLER ─────────────────────────────────────────────────

async def message_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle general messages. Updated with new commands."""
    chat_id = update.effective_chat.id
    message = (
        f"🤖 *Crisis Clarity Bot*\n\n"
        f"This bot automatically sends you crisis alerts.\n"
        f"You don't need to send messages here.\n\n"
        f"*Your Chat ID:* `{chat_id}`\n\n"
        f"*Commands:*\n"
        f"/start — Get started\n"
        f"/news — Active alerts (current batch)\n"
        f"/filter — Filter by type\n"
        f"/status — Latest alert status\n"
        f"/alerts — Last 5 alerts\n"
        f"/ping — Bot health check"
    )
    await context.bot.send_message(chat_id=chat_id, text=message, parse_mode="Markdown")


# ─── INLINE KEYBOARD CALLBACK HANDLER ────────────────────────────────────────

async def feedback_callback_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """
    Handle inline keyboard button callbacks for comprehension feedback.
    
    Buttons: [✅ Understood] [❓ Not Clear] [🔁 Re-Verify]
    Updates Firebase comprehension counters.
    CO6: Human-in-the-Loop — citizens provide feedback on alert clarity.
    """
    query = update.callback_query
    await query.answer()

    data = query.data  # Format: "feedback:{alert_id}:{type}"
    parts = data.split(":")

    if len(parts) != 3 or parts[0] != "feedback":
        return

    alert_id = parts[1]
    feedback_type = parts[2]

    if feedback_type == "understood":
        update_comprehension_feedback(alert_id, "understood")
        await query.edit_message_reply_markup(reply_markup=None)
        await query.message.reply_text("✅ Thank you for your feedback! Stay safe.")
    elif feedback_type == "not_clear":
        update_comprehension_feedback(alert_id, "not_understood")
        await query.edit_message_reply_markup(reply_markup=None)
        await query.message.reply_text(
            "📝 We noted your feedback. We'll work on making alerts clearer.\n"
            "If you need help, contact your local disaster helpline: *1078 (NDRF)*",
            parse_mode="Markdown",
        )
    elif feedback_type == "reverify":
        await query.edit_message_reply_markup(reply_markup=None)
        await query.message.reply_text(
            "🔄 Re-verification requested. Check the app for updated results.",
        )

    logger.info(f"📊 Feedback received: alert={alert_id}, type={feedback_type}")


# ─── HELPERS ──────────────────────────────────────────────────────────────────

def _format_trust_badge(status: str, score: int) -> str:
    """Format full trust badge with emoji and score."""
    s = (status or "").lower()
    if s in ("verified",):
        return f"🟢 *VERIFIED* (Score: {score}/100)"
    elif s in ("partial", "partially_verified", "partiallyverified"):
        return f"🟡 *PARTIALLY VERIFIED* (Score: {score}/100)"
    elif s in ("fake", "possible_fake_news", "possiblefakenews"):
        return f"🔴 *POSSIBLE FAKE NEWS* (Score: {score}/100)"
    return f"❓ *PENDING* (Score: {score}/100)"


def _format_trust_badge_short(status: str, score: int) -> str:
    """Short badge for alert lists."""
    s = (status or "").lower()
    if s in ("verified",):
        return f"🟢 {score}"
    elif s in ("partial", "partially_verified", "partiallyverified"):
        return f"🟡 {score}"
    elif s in ("fake", "possible_fake_news", "possiblefakenews"):
        return f"🔴 {score}"
    return f"❓ {score}"


def build_feedback_keyboard(alert_id: str) -> InlineKeyboardMarkup:
    """Build inline keyboard with comprehension feedback buttons."""
    keyboard = [
        [
            InlineKeyboardButton("✅ Understood", callback_data=f"feedback:{alert_id}:understood"),
            InlineKeyboardButton("❓ Not Clear", callback_data=f"feedback:{alert_id}:not_clear"),
        ],
        [
            InlineKeyboardButton("🔁 Re-Verify", callback_data=f"feedback:{alert_id}:reverify"),
        ],
    ]
    return InlineKeyboardMarkup(keyboard)
