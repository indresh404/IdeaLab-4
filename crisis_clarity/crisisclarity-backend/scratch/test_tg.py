import os
import sys
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env"))
print("TELEGRAM_BOT_TOKEN:", bool(os.getenv("TELEGRAM_BOT_TOKEN")))

from telegram.constants import ParseMode
print("ParseMode.MARKDOWN:", ParseMode.MARKDOWN)

import asyncio
from telegram import Bot

async def test_bot():
    token = os.getenv("TELEGRAM_BOT_TOKEN")
    if not token:
        print("No token")
        return
    bot = Bot(token=token)
    try:
        me = await bot.get_me()
        print("Bot is working:", me.username)
    except Exception as e:
        print("Error getting me:", e)

if __name__ == "__main__":
    asyncio.run(test_bot())
