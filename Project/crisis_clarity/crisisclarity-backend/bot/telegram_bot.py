"""
CrisisClarity — Python Telegram Bot (replaces Node.js bot)

Agentic AI Syllabus — CO4, Module IV: Autonomous Agents.
The Telegram bot is the user-facing autonomous agent that operates
independently, listening for commands and delivering verified alerts.
Uses polling for local development (no webhooks needed).

Drop-in replacement for the Node.js telegram_bot.js with ALL
existing functionality preserved plus new Python-only features.

Usage:
    python bot/telegram_bot.py
    (or run from the crisisclarity-backend directory)
"""

import os
import sys
import asyncio

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv
from telegram.ext import (
    ApplicationBuilder,
    CommandHandler,
    MessageHandler,
    CallbackQueryHandler,
    filters,
)

from bot.handlers import (
    start_handler,
    ping_handler,
    status_handler,
    alerts_handler,
    news_handler,
    filter_handler,
    message_handler,
    feedback_callback_handler,
)
from utils.logger import setup_logger

load_dotenv()
logger = setup_logger("telegram_bot")


def setup_application():
    """
    Setup the Telegram application with all handlers.
    Returns the application object.
    """
    token = os.getenv("TELEGRAM_BOT_TOKEN", "")
    if not token or token == "your_token_here":
        logger.error("❌ TELEGRAM_BOT_TOKEN not set in .env!")
        return None

    # Build the application
    app = ApplicationBuilder().token(token).build()

    # ── Register command handlers ──
    app.add_handler(CommandHandler("start", start_handler))
    app.add_handler(CommandHandler("ping", ping_handler))
    app.add_handler(CommandHandler("status", status_handler))
    app.add_handler(CommandHandler("alerts", alerts_handler))
    app.add_handler(CommandHandler("news", news_handler))
    app.add_handler(CommandHandler("filter", filter_handler))

    # ── Register callback query handler for inline keyboards ──
    app.add_handler(CallbackQueryHandler(feedback_callback_handler))

    # ── Register general message handler (must be last) ──
    app.add_handler(MessageHandler(filters.TEXT & (~filters.COMMAND), message_handler))
    
    return app


async def run_bot_async():
    """
    Run the bot asynchronously. Useful for integration with other async frameworks.
    Wrapped with error handling so Telegram conflicts don't crash the server.
    """
    app = setup_application()
    if not app:
        return

    logger.info("🤖 Starting Telegram Bot in polling mode (async)...")
    try:
        async with app:
            await app.initialize()
            await app.start()
            await app.updater.start_polling(drop_pending_updates=True)
            # Keep running until cancelled
            try:
                while True:
                    await asyncio.sleep(3600)
            except asyncio.CancelledError:
                await app.updater.stop()
                await app.stop()
                await app.shutdown()
    except Exception as e:
        logger.warning(f"⚠️ Telegram bot error (harmless in reload mode): {e}")


def main():
    """Start the Telegram bot with polling (blocking)."""
    app = setup_application()
    if not app:
        logger.error("Failed to setup Telegram application.")
        sys.exit(1)

    # ── Start polling ──
    logger.info("🤖 Crisis Clarity Telegram Bot starting...")
    logger.info("📋 Commands: /start, /ping, /status, /alerts")
    logger.info("🔄 Using polling mode (local development)")

    app.run_polling()


if __name__ == "__main__":
    import asyncio
    main()
