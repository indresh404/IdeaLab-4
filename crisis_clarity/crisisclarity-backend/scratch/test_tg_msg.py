import os
import asyncio
from telegram import Bot
from telegram.constants import ParseMode
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env"))

async def test_msg():
    bot = Bot(token=os.getenv("TELEGRAM_BOT_TOKEN"))
    try:
        user_id_param = "user_123_456"
        message = (
            f"🔐 *Verification Code:* `{user_id_param}`\n\n"
            f"📱 *Your Chat ID:* `12345`\n\n"
            f"📋 *How to verify:*\n"
            f"1️⃣ Copy the Verification Code\n"
            f"2️⃣ Copy the Chat ID\n"
            f"3️⃣ Go back to Crisis Clarity app\n"
            f"4️⃣ Paste both fields\n"
            f"5️⃣ Tap \"VERIFY & LINK\"\n\n"
            f"✅ You will start receiving alerts immediately!"
        )
        await bot.send_message(chat_id=1234567, text=message, parse_mode="Markdown")
    except Exception as e:
        print("Error:", type(e).__name__, e)

if __name__ == "__main__":
    asyncio.run(test_msg())
