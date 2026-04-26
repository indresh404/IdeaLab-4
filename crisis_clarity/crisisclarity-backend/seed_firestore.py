"""
CrisisClarity — Firestore Seeder Script

Standalone script to upload all events from news_data.json to Firestore.
Run this once to initialize the database, or re-run to update.

Usage:
    python seed_firestore.py
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from dotenv import load_dotenv
load_dotenv()

from firebase.alert_repository_v2 import seed_events_from_json, is_firestore_seeded
from firebase.firestore_client import is_firestore_available


def main():
    print("=" * 60)
    print("🌐 CrisisClarity — Firestore Seeder")
    print("=" * 60)

    if not is_firestore_available():
        print("\n❌ Firestore is NOT available.")
        print("   Make sure firebase-service-account.json exists")
        print("   and FIREBASE_CREDENTIALS_PATH is set in .env")
        return

    print("\n✅ Firestore connected!")

    if is_firestore_seeded():
        print("\n⚠️  Firestore already has seeded events.")
        response = input("   Re-seed (overwrite)? [y/N]: ").strip().lower()
        if response != "y":
            print("   Skipped.")
            return

    print("\n📦 Seeding events from news_data.json...")
    count = seed_events_from_json("news_data.json")
    print(f"\n✅ Done! Seeded {count} events to Firestore.")
    print("   Events are grouped into batches of 5.")
    print("   The scheduler will activate batches cyclically.")


if __name__ == "__main__":
    main()
