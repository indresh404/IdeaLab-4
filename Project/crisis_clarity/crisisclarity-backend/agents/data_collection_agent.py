"""
CrisisClarity — Agent 1: DataCollectionAgent

Agentic AI Syllabus — CO4, Module IV:
Tool-Using & Autonomous Agents.
Implements Planner-Executor architecture where this agent
acts as the data planner, collecting structured inputs
from multiple sources before reasoning begins.
Ref: AutoGPT-style workflow, API Integration patterns.

BDI Architecture Role: BELIEF
This agent gathers the world state — it forms the agent team's
beliefs about what is happening by collecting observations from
multiple sources (admin alerts, news feeds, social media).
"""

from typing import List, Dict, Any, Optional
from datetime import datetime

from models.alert_models import SourceData
from firebase.alert_repository import get_alert_by_id
from agents.news_ingestion_agent import NewsIngestionAgent
from agents.mock_data import get_demo_scenario
from utils.logger import setup_logger, log_agent_step
import os

logger = setup_logger("DataCollectionAgent")


class DataCollectionAgent:
    """
    Agentic AI Syllabus — CO4, Module IV:
    Tool-Using & Autonomous Agents.
    Implements Planner-Executor architecture where this agent
    acts as the data planner, collecting structured inputs
    from multiple sources before reasoning begins.
    Ref: AutoGPT-style workflow, API Integration patterns.
    
    Sources and their trust weights:
    - admin_alert: Highest trust (weight 40). Comes from Firebase Firestore.
    - news_source: Medium trust (weight 28-35). News Intelligence Engine (RSS+NewsAPI+GDELT).
    - social_media: Low trust (weight 20). Mock JSON representing Twitter/social.
    
    BDI Role: BELIEF — Gathering the world state.
    """

    def __init__(self):
        self.agent_name = "DataCollectionAgent"
        self.news_intelligence = NewsIngestionAgent(
            groq_api_key=os.getenv("GROQ_API_KEY"),
            news_api_key=os.getenv("NEWS_API_KEY")
        )
        log_agent_step(logger, self.agent_name, "initialized", "Ready to collect multi-source data")

    async def collect(
        self,
        alert_id: str,
        scenario: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        Collect data from multiple sources for a given alert.
        
        CO4: This method implements the Perception component of the
        agent loop — observing the environment state from multiple
        partially observable sources (POMDP).
        """
        log_agent_step(logger, self.agent_name, "collect_start",
                       f"alertId={alert_id}, scenario={scenario}")

        collected_sources: List[Dict[str, Any]] = []

        if scenario:
            # ── DEMO MODE: Use pre-built scenarios ──
            collected_sources = self._collect_from_scenario(scenario)
        else:
            # ── PRODUCTION MODE: Fetch from Firestore + Real RSS + Mock Social ──
            # 1. Admin Alert from Firestore
            firestore_sources = self._collect_from_firestore(alert_id)
            collected_sources.extend(firestore_sources)

            # 2. Real News from Intelligence Engine
            real_news = await self._collect_from_news()
            
            if real_news:
                collected_sources.extend(real_news)
                for s in collected_sources:
                    if s.get("is_real_data"):
                        s["using_real_data"] = True
            else:
                # Fallback to mock news if RSS fails or no relevant news found
                logger.warning("No real-time RSS articles found, using mock news data for demo")
                mock_scenario = self._collect_from_scenario("A") # Default to Scenario A news
                # Filter for just news sources from the mock
                mock_news = [s for s in mock_scenario if s["source"] == "news_source"]
                for s in mock_news:
                    s["is_real_data"] = False
                    s["using_real_data"] = False
                collected_sources.extend(mock_news)

            # 3. Social Media (Always Mock for Demo)
            mock_social = {
                "source": "social_media",
                "source_name": "Twitter/X (Mock)",
                "location": firestore_sources[0]["location"] if firestore_sources else "Mumbai",
                "disaster_type": firestore_sources[0]["disaster_type"] if firestore_sources else "flood",
                "severity": "high",
                "description": "Seeing lots of posts about waterlogging in the area. Stay safe everyone!",
                "trust_weight": 20,
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "is_real_data": False
            }
            collected_sources.append(mock_social)

        log_agent_step(logger, self.agent_name, "collect_complete",
                       f"Collected {len(collected_sources)} source(s): "
                       f"{[s['source'] for s in collected_sources]}")

        return collected_sources

    async def _collect_from_news(self) -> List[Dict[str, Any]]:
        """Fetch and map high-fidelity intelligence events from News Ingestion Engine."""
        try:
            events = await self.news_intelligence.run_pipeline()
            
            logger.info(f"News Intelligence Engine found {len(events)} crisis events")
            
            mapped_sources = []
            for ev in events:
                mapped_sources.append({
                    "source": "news_source",
                    "source_name": ", ".join(ev.sources),
                    "location": f"{ev.location.city}, {ev.location.state}",
                    "disaster_type": ev.disaster_type,
                    "severity": ev.severity.lower(),
                    "description": ev.summary,
                    "trust_weight": int(ev.trust_score * 40),
                    "timestamp": ev.timestamp,
                    "is_real_data": True,
                    "article_url": "", # Events are aggregated
                    "headline": ev.title,
                    "full_content": ev.full_content
                })
            return mapped_sources
        except Exception as e:
            logger.error(f"Error in _collect_from_news: {str(e)}")
            return []

    def _collect_from_scenario(self, scenario_key: str) -> List[Dict[str, Any]]:
        """Load pre-built demo scenario data."""
        log_agent_step(logger, self.agent_name, "scenario_load",
                       f"Loading demo scenario '{scenario_key}'")
        
        try:
            scenario = get_demo_scenario(scenario_key)
            sources = scenario["sources"]
            for s in sources:
                s["is_real_data"] = False
            log_agent_step(logger, self.agent_name, "scenario_loaded",
                           f"Scenario '{scenario['name']}' — {len(sources)} source(s)")
            return sources
        except KeyError as e:
            log_agent_step(logger, self.agent_name, "scenario_error", str(e))
            return []

    def _collect_from_firestore(self, alert_id: str) -> List[Dict[str, Any]]:
        """Fetch real alert from Firestore and construct the admin source."""
        log_agent_step(logger, self.agent_name, "firestore_fetch",
                       f"Fetching alert {alert_id} from Firestore")
        
        alert_data = get_alert_by_id(alert_id)
        
        if not alert_data:
            log_agent_step(logger, self.agent_name, "firestore_miss",
                           f"Alert {alert_id} not found — returning empty")
            return []
        
        # Construct admin source from Firestore data
        admin_source: Dict[str, Any] = {
            "source": "admin",
            "location": ", ".join(alert_data.get("affectedZones", ["Unknown"])),
            "disaster_type": alert_data.get("disasterType", "unknown"),
            "severity": alert_data.get("severity", "low"),
            "description": alert_data.get("description", ""),
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "trust_weight": 40,
            "is_real_data": True
        }
        
        log_agent_step(logger, self.agent_name, "firestore_source_built",
                       f"Admin source: type={admin_source['disaster_type']}, "
                       f"location={admin_source['location']}, "
                       f"severity={admin_source['severity']}")
        
        return [admin_source]
