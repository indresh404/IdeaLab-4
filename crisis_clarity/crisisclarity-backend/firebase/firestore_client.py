"""
CrisisClarity — Firebase Firestore Client
Agentic AI Syllabus — CO4, Module IV: Autonomous Agents.

The Firestore client provides the persistent memory layer for agents.
In the BDI (Belief-Desire-Intention) architecture, Firestore stores
the agent's Beliefs — the observed world state that agents read from
and write back to after processing.

Uses Firebase Admin SDK with service account credentials.
"""

import os
from typing import Optional

import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

from utils.logger import setup_logger

load_dotenv()
logger = setup_logger("firestore_client")

# Singleton Firestore client
_db: Optional[firestore.Client] = None  # type: ignore
_initialized: bool = False


def get_firestore_client() -> Optional[firestore.Client]:  # type: ignore
    """
    Get or create the Firestore client singleton.
    
    Initializes Firebase Admin SDK using service account JSON.
    Returns None if credentials are not available (graceful degradation).
    
    CO4: Autonomous agents need persistent state — Firestore provides
    the shared memory that all agents read from and write to.
    """
    global _db, _initialized
    
    if _initialized:
        return _db
    
    _initialized = True
    
    cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "./firebase-service-account.json")
    
    # Also check for the legacy path from existing backend
    if not os.path.exists(cred_path):
        legacy_path = os.getenv("FIREBASE_CREDENTIALS", "serviceAccountKey.json")
        if os.path.exists(legacy_path):
            cred_path = legacy_path
    
    if not os.path.exists(cred_path):
        logger.warning(f"⚠️ Firebase credentials not found at '{cred_path}'. Firestore features disabled.")
        logger.warning("   Place your service account JSON file and set FIREBASE_CREDENTIALS_PATH in .env")
        _db = None
        return None
    
    try:
        # Check if Firebase is already initialized (e.g., by another module)
        if not firebase_admin._apps:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        
        _db = firestore.client()
        logger.info("✅ Firebase Firestore initialized successfully")
        return _db
    except Exception as e:
        logger.error(f"❌ Failed to initialize Firestore: {e}")
        _db = None
        return None


def is_firestore_available() -> bool:
    """Check if Firestore is available and connected."""
    return get_firestore_client() is not None
