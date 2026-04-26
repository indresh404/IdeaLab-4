import os
import requests
import json
import logging
import base64
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger("SarvamUtils")

class SarvamUtils:
    """
    Utility class for interacting with Sarvam AI APIs for translation and TTS.
    """
    TRANSLATE_URL = "https://api.sarvam.ai/translate"
    TTS_URL = "https://api.sarvam.ai/text-to-speech"
    API_KEY = os.getenv("SARVAM_API_KEY")

    @classmethod
    def translate(cls, text: str, source_lang: str = "auto", target_lang: str = "en-IN") -> str:
        """
        Translates text using Sarvam AI API.
        """
        if not cls.API_KEY:
            logger.error("SARVAM_API_KEY not found in environment")
            return text

        if source_lang == target_lang:
            return text

        headers = {
            "api-subscription-key": cls.API_KEY,
            "Content-Type": "application/json"
        }

        payload = {
            "input": text,
            "source_language_code": source_lang,
            "target_language_code": target_lang,
            "model": "mayura:v1"
        }

        try:
            response = requests.post(cls.TRANSLATE_URL, json=payload, headers=headers, timeout=10)
            response.raise_for_status()
            data = response.json()
            return data.get("translated_text", text)
        except Exception as e:
            logger.error(f"❌ Sarvam Translation Error: {e}")
            return text

    @classmethod
    def text_to_speech(cls, text: str, lang: str = "en-IN", speaker: str = "aditya") -> str:
        """
        Converts text to speech using Sarvam AI API.
        Returns base64 encoded audio string.
        """
        if not cls.API_KEY:
            logger.error("SARVAM_API_KEY not found in environment")
            return ""

        headers = {
            "api-subscription-key": cls.API_KEY,
            "Content-Type": "application/json"
        }

        # Map language codes to Sarvam format if needed
        lang_map = {
            "English": "en-IN",
            "Hindi": "hi-IN",
            "Marathi": "mr-IN"
        }
        target_lang = lang_map.get(lang, lang)

        payload = {
            "text": text,
            "target_language_code": target_lang,
            "speaker": speaker,
            "pitch": 0,
            "loudness": 1,
            "pace": 1.0
        }

        try:
            response = requests.post(cls.TTS_URL, json=payload, headers=headers, timeout=15)
            response.raise_for_status()
            data = response.json()
            return data.get("audio_content", "")
        except Exception as e:
            logger.error(f"❌ Sarvam TTS Error: {e}")
            return ""

sarvam = SarvamUtils()
