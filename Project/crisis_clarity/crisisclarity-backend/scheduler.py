"""
CrisisClarity — 5-Minute Rotation Scheduler

Background scheduler that runs as an async task inside FastAPI lifespan.
Every 5 minutes:
  1. Deactivates current batch of events
  2. Activates next batch (cyclic rotation)
  3. Runs AI agent pipeline on each newly activated event
  4. Updates Firestore with computed scores
  5. Pushes high-severity alerts to Telegram

The scheduler supports both Firestore and local JSON fallback modes.
"""

import asyncio
import os
import json
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any

from firebase.firestore_client import is_firestore_available
from firebase.alert_repository_v2 import (
    seed_events_from_json,
    is_firestore_seeded,
    deactivate_all_events,
    set_batch_active,
    get_total_batches,
    get_active_alerts_full,
    update_event_scores,
    get_system_state,
    update_system_state,
    load_local_events,
    get_local_active_alerts,
    rotate_local_batch,
    BATCH_SIZE,
)
from agents.crisis_scoring_agent import CrisisScoringAgent
from agents.news_ingestion_agent import NewsIngestionAgent
from utils.logger import setup_logger

logger = setup_logger("Scheduler")

# ── Configuration ────────────────────────────────────────────────────────────
ROTATION_INTERVAL_SECONDS = 300  # 5 minutes
NEWS_FETCH_INTERVAL_SECONDS = 1800 # 30 minutes
INITIAL_DELAY_SECONDS = 5       # Wait before first rotation on startup


class CrisisScheduler:
    """
    5-minute batch rotation scheduler.

    Manages the cyclic activation of event batches and runs
    the AI agent pipeline on each batch.
    """

    def __init__(self):
        self.current_batch: int = 0
        self.total_batches: int = 3
        self.scoring_agent = CrisisScoringAgent()
        self.news_agent = NewsIngestionAgent(
            groq_api_key=os.getenv("GROQ_API_KEY", ""),
            news_api_key=os.getenv("NEWS_API_KEY", "")
        )
        self.is_running: bool = False
        self.last_rotation: Optional[datetime] = None
        self.last_news_fetch: Optional[datetime] = None
        self.use_firestore: bool = False
        self._rotation_task: Optional[asyncio.Task] = None
        self._news_task: Optional[asyncio.Task] = None

    async def initialize(self):
        """
        Initialize the scheduler:
        1. Check if Firestore is available
        2. Seed events if not already done
        3. Load initial state
        4. Activate first batch
        """
        logger.info("🚀 Initializing CrisisClarity Scheduler...")

        self.use_firestore = is_firestore_available()

        if self.use_firestore:
            logger.info("  ✅ Firestore available — using cloud mode")

            # Seed if needed
            if not is_firestore_seeded():
                logger.info("  📦 Seeding Firestore with news_data.json...")
                count = seed_events_from_json("news_data.json")
                logger.info(f"  📦 Seeded {count} events")
            else:
                logger.info("  📦 Firestore already seeded")

            # Get total batches
            self.total_batches = get_total_batches()
            if self.total_batches == 0:
                self.total_batches = 3

            # Load state
            state = get_system_state()
            self.current_batch = state.get("current_batch", 0)

        else:
            logger.info("  ⚠️ Firestore not available — using local JSON mode")
            events = load_local_events("news_data.json")
            self.total_batches = (len(events) // BATCH_SIZE) + (1 if len(events) % BATCH_SIZE else 0)
            if self.total_batches == 0:
                self.total_batches = 3

        logger.info(f"  📊 Total batches: {self.total_batches}")
        logger.info(f"  📊 Current batch: {self.current_batch}")

        # Activate first batch immediately
        await self._rotate()
        # Trigger first news fetch
        await self._fetch_and_save_news()

    async def start(self):
        """Start all background loops."""
        self.is_running = True
        logger.info(f"⏱️ Scheduler started — rotating every {ROTATION_INTERVAL_SECONDS}s")
        
        # Start rotation loop
        self._rotation_task = asyncio.create_task(self._rotation_loop())
        # Start news ingestion loop
        self._news_task = asyncio.create_task(self._news_ingestion_loop())

    async def _rotation_loop(self):
        while self.is_running:
            try:
                await asyncio.sleep(ROTATION_INTERVAL_SECONDS)
                await self._rotate()
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"❌ Rotation loop error: {e}")
                await asyncio.sleep(30)

    async def _news_ingestion_loop(self):
        """Separate loop for news ingestion (less frequent)."""
        while self.is_running:
            try:
                await asyncio.sleep(NEWS_FETCH_INTERVAL_SECONDS)
                await self._fetch_and_save_news()
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"❌ News ingestion loop error: {e}")
                await asyncio.sleep(60)

    def stop(self):
        """Stop all background tasks."""
        self.is_running = False
        if self._rotation_task:
            self._rotation_task.cancel()
        if self._news_task:
            self._news_task.cancel()
        logger.info("⏹️ Scheduler stopped")

    async def _rotate(self):
        """
        Perform one rotation cycle:
        1. Deactivate current batch
        2. Advance to next batch
        3. Activate next batch
        4. Run AI agents on the batch
        5. Push high-severity alerts
        """
        logger.info(f"\n{'='*60}")
        logger.info(f"🔄 ROTATION — Batch {self.current_batch} → {(self.current_batch) % self.total_batches}")
        logger.info(f"{'='*60}")

        if self.use_firestore:
            await self._rotate_firestore()
        else:
            await self._rotate_local()

        self.last_rotation = datetime.now(timezone.utc)
        logger.info(f"✅ Rotation complete. Next rotation in {ROTATION_INTERVAL_SECONDS}s")

    async def _rotate_firestore(self):
        """Rotation using Firestore."""
        # Step 1: Deactivate all current events
        deactivated = deactivate_all_events()
        logger.info(f"  🔕 Deactivated {deactivated} events")

        # Step 2: Advance batch counter
        self.current_batch = (self.current_batch + 1) % self.total_batches

        # Step 3: Activate new batch
        activated = set_batch_active(self.current_batch)
        logger.info(f"  ✅ Activated batch {self.current_batch}: {activated} events")

        # Step 4: Run AI agent pipeline on active events
        active_alerts = get_active_alerts_full()
        logger.info(f"  🧠 Running AI pipeline on {len(active_alerts)} events...")

        for alert in active_alerts:
            try:
                event_id = alert.get("event_id", alert.get("doc_id", ""))

                # Process through scoring agent
                enriched = await self.scoring_agent.process_event(alert)

                # Update Firestore with computed scores
                update_event_scores(
                    event_id=event_id,
                    severity_score=enriched.get("severity_score", 0),
                    confidence_score=enriched.get("confidence_score", 0),
                    severity_label=enriched.get("severity", "LOW"),
                    trust_label=enriched.get("trust_label", "UNVERIFIED"),
                    ai_analysis=enriched.get("ai_analysis"),
                )
            except Exception as e:
                logger.error(f"  ❌ Error processing {alert.get('event_id', '?')}: {e}")

        # Step 5: Update system state
        update_system_state(self.current_batch, self.total_batches)

        # Step 6: Check for high-severity alerts to push
        await self._push_critical_alerts(active_alerts)

    async def _rotate_local(self):
        """Rotation using local JSON (fallback mode)."""
        # Advance batch
        self.current_batch = rotate_local_batch()

        # Get active events
        active = get_local_active_alerts()
        logger.info(f"  📦 Local batch {self.current_batch}: {len(active)} events active")

        # Run scoring agent on each
        for event in active:
            try:
                await self.scoring_agent.process_event(event)
            except Exception as e:
                logger.error(f"  ❌ Error processing {event.get('event_id', '?')}: {e}")

    async def _push_critical_alerts(self, alerts: List[Dict[str, Any]]):
        """Push high-severity alerts to Telegram."""
        critical_alerts = []
        for alert in alerts:
            severity_score = alert.get("severity_score", 0)
            dtype = alert.get("disaster_type", alert.get("disasterType", "")).lower()

            # Push if severity > 0.7 OR fire OR flood with transport disruption
            should_push = (
                severity_score > 0.7
                or dtype == "fire"
                or (dtype == "flood" and "transport" in str(alert.get("keywords", [])).lower())
            )

            if should_push:
                critical_alerts.append(alert)

        if critical_alerts:
            logger.info(f"  🚨 {len(critical_alerts)} critical alert(s) to push to Telegram")
            # Telegram push will be handled by the bot module
            # For now, just log the alerts
            for a in critical_alerts:
                logger.info(f"    📢 {a.get('event_id', '?')}: {a.get('title', '')[:60]}...")

    async def _fetch_and_save_news(self):
        """Run the news ingestion pipeline and save results to Firestore."""
        logger.info("📡 Starting scheduled news ingestion...")
        try:
            events = await self.news_agent.run_pipeline()
            if not events:
                logger.info("📡 No news events found.")
                return

            if self.use_firestore:
                from firebase.firestore_client import get_db
                db = get_db()
                batch = db.batch()
                
                news_ref = db.collection("news_feed")
                for event in events:
                    doc_ref = news_ref.document(event.event_id)
                    batch.set(doc_ref, event.model_dump())
                
                batch.commit()
                logger.info(f"📡 Saved {len(events)} events to 'news_feed' collection.")
            else:
                # LOCAL MODE: Save to a separate JSON file for the repository to pick up
                local_news_path = "live_news.json"
                try:
                    event_dicts = [e.model_dump() for e in events]
                    with open(local_news_path, "w", encoding="utf-8") as f:
                        json.dump(event_dicts, f, indent=4)
                    logger.info(f"📡 Local mode: Saved {len(events)} events to {local_news_path}")
                except Exception as e:
                    logger.error(f"❌ Failed to save local news: {e}")
            
            self.last_news_fetch = datetime.now(timezone.utc)
        except Exception as e:
            logger.error(f"❌ Scheduled news fetch failed: {e}")

    def get_status(self) -> Dict[str, Any]:
        """Get current scheduler status."""
        return {
            "is_running": self.is_running,
            "current_batch": self.current_batch,
            "total_batches": self.total_batches,
            "last_rotation": self.last_rotation.isoformat() if self.last_rotation else None,
            "last_news_fetch": self.last_news_fetch.isoformat() if self.last_news_fetch else None,
            "rotation_interval_minutes": ROTATION_INTERVAL_SECONDS // 60,
            "news_fetch_interval_minutes": NEWS_FETCH_INTERVAL_SECONDS // 60,
            "mode": "firestore" if self.use_firestore else "local_json",
        }


# ── Singleton ─────────────────────────────────────────────────────────────────
_scheduler: Optional[CrisisScheduler] = None


def get_scheduler() -> CrisisScheduler:
    """Get or create the scheduler singleton."""
    global _scheduler
    if _scheduler is None:
        _scheduler = CrisisScheduler()
    return _scheduler
