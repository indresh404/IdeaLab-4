"""
CrisisClarity — Groq LLM Client
Agentic AI Syllabus — CO3, Module III: LLM-Powered Agents with Tool Calling.

This module wraps the Groq API for LLM-based text simplification.
Uses llama-3.3-70b-versatile model as specified in the n8n workflow.
The LLM acts as a tool that agents can invoke for natural language
processing tasks (alert simplification, multilingual translation).

Ref: LLM Tool-Use patterns, ReAct (Reasoning + Acting) framework.
"""

import os
from typing import Optional
from groq import Groq
from dotenv import load_dotenv

from utils.logger import setup_logger

load_dotenv()
logger = setup_logger("groq_client")

# Groq client singleton
_client: Optional[Groq] = None


def get_groq_client() -> Optional[Groq]:
    """
    Get or create the Groq API client singleton.
    Returns None if GROQ_API_KEY is not configured.
    """
    global _client
    if _client is not None:
        return _client
    
    api_key = os.getenv("GROQ_API_KEY")
    if not api_key or api_key == "your_groq_key_here":
        logger.warning("⚠️ GROQ_API_KEY not set. LLM features will be disabled.")
        return None
    
    try:
        _client = Groq(api_key=api_key)
        logger.info("✅ Groq client initialized (model: llama-3.3-70b-versatile)")
        return _client
    except Exception as e:
        logger.error(f"❌ Failed to initialize Groq client: {e}")
        return None


async def simplify_alert_text(text: str, language: str = "en") -> str:
    """
    Use Groq LLM to simplify alert text for better comprehension.
    
    CO3: LLM as a tool — the agent invokes the LLM to transform
    complex disaster terminology into simple, actionable language.
    
    Args:
        text: Original alert text
        language: Target language code ('en', 'hi', 'mr')
    
    Returns:
        Simplified text, or original if LLM is unavailable
    """
    client = get_groq_client()
    if not client:
        return text
    
    lang_names = {"en": "English", "hi": "Hindi", "mr": "Marathi"}
    target_lang = lang_names.get(language, "English")
    
    prompt = f"""Simplify this disaster alert for a common citizen in {target_lang}. 
Use simple words. Keep it under 3 sentences. Include actionable steps if possible.

Alert: {text}

Simplified version:"""
    
    try:
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": "You are a disaster communication expert. Simplify alerts for citizens."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            max_tokens=200
        )
        result = response.choices[0].message.content.strip()
        logger.info(f"✅ LLM simplification complete ({target_lang}): {len(result)} chars")
        return result
    except Exception as e:
        logger.error(f"❌ Groq API error: {e}")
        return text
