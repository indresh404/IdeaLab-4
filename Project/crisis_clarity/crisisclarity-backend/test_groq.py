import os
from groq import Groq
try:
    client = Groq(api_key="test")
    print("Groq client initialized successfully!")
except Exception as e:
    print(f"Groq initialization failed: {e}")
