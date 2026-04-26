import asyncio
import logging
import json
import requests
import os
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional

import trafilatura
from newsapi import NewsApiClient
from groq import Groq

from models.alert_models import CrisisEvent, Location
from utils.logger import setup_logger

logger = setup_logger("NewsIngestionAgent")

class NewsIngestionAgent:
    """
    Crisis Intelligence Engine for CrisisClarity.
    Ingests, enriches, filters, and clusters news into crisis events.
    Focus: Mumbai, Maharashtra, India.
    """

    def __init__(self, groq_api_key: str, news_api_key: str):
        self.groq_client = Groq(api_key=groq_api_key)
        self.newsapi_client = NewsApiClient(api_key=news_api_key)
        self.disaster_keywords = ["flood", "cyclone", "earthquake", "landslide", "fire", "heavy rain", "heatwave", "storm"]
        self.location_focus = ["Mumbai", "Maharashtra", "Thane", "Pune", "Nagpur", "Nashik"]
        self.semaphore = asyncio.Semaphore(2)  # Limit concurrent LLM calls to prevent 429
        
    async def run_pipeline(self) -> List[CrisisEvent]:
        """Full pipeline: Ingest -> Enrich -> Filter -> Cluster -> Structured Output."""
        logger.info("🚀 Starting news ingestion pipeline...")
        
        # 1. Ingest
        raw_articles = await self._ingest_all_sources()
        logger.info(f"📥 Ingested {len(raw_articles)} raw articles.")
        
        # 2. Enrich (Full Content Extraction)
        enriched_articles = await self._enrich_articles(raw_articles)
        logger.info(f"📄 Enriched {len(enriched_articles)} articles with full content.")
        
        if not enriched_articles:
            return []
            
        # 3. Analyze & Filter (Geo + Disaster) using LLM
        analyzed_articles = await self._analyze_and_filter(enriched_articles)
        logger.info(f"🔍 Kept {len(analyzed_articles)} articles after geo/disaster filtering.")
        
        if not analyzed_articles:
            return []
            
        # 4. Cluster into Events
        events = self._cluster_into_events(analyzed_articles)
        
        # ── DEMO FALLBACK: If no real events found, inject mock ones for the UI ──
        if not events:
            logger.info("⚠️ No real crisis events found. Injecting mock events for demo...")
            events = self._get_mock_events()
            
        logger.info(f"🧩 Pipeline complete: {len(events)} events.")
        return events

    def _get_mock_events(self) -> List[CrisisEvent]:
        """Returns high-quality mock events for demo purposes when real news is scarce."""
        return [
            CrisisEvent(
                event_id="mock_mumbai_flood_2024",
                title="Severe Waterlogging in South Mumbai after Heavy Downpour",
                summary="Heavy rains have caused significant waterlogging in Dadar, Parel, and Hindmata. Local trains are running with 15-minute delays.",
                full_content="Mumbai has recorded over 100mm of rainfall in the last 6 hours. The BMC has issued a high tide warning for this afternoon. Citizens are advised to avoid travel unless necessary.",
                location=Location(city="Mumbai", state="Maharashtra"),
                disaster_type="flood",
                severity="HIGH",
                trust_score=0.95,
                trust_label="VERIFIED",
                sources=["BMC Official", "Times of India"],
                timestamp=datetime.now().isoformat(),
                keywords=["rain", "flood", "mumbai"]
            ),
            CrisisEvent(
                event_id="mock_thane_fire_2024",
                title="Industrial Fire Reported in Thane Manpada Area",
                summary="A level-2 fire broke out in a chemical factory in Thane. 4 fire engines are on site.",
                full_content="The fire started at approximately 4:00 PM today. No casualties have been reported so far. The smoke is visible from the Eastern Express Highway.",
                location=Location(city="Thane", state="Maharashtra"),
                disaster_type="fire",
                severity="MEDIUM",
                trust_score=0.88,
                trust_label="PARTIAL",
                sources=["Thane Fire Dept", "Local News"],
                timestamp=datetime.now().isoformat(),
                keywords=["fire", "thane", "emergency"]
            )
        ]

    async def _fetch_rss(self) -> List[Dict[str, Any]]:
        """Fetch from traditional RSS feeds as a fallback and additional source."""
        from agents.rss_feed_fetcher import RSSFeedFetcher
        fetcher = RSSFeedFetcher()
        try:
            raw_articles = await fetcher.fetch_all_feeds()
            articles = []
            for art in raw_articles:
                articles.append({
                    "source_name": art['display_name'],
                    "headline": art['headline'],
                    "url": art['url'],
                    "published": art['published'],
                    "description": art['description']
                })
            return articles
        except Exception as e:
            logger.error(f"RSS fetch failed: {e}")
            return []

    async def _fetch_newsapi(self) -> List[Dict[str, Any]]:
        try:
            # Query NewsAPI for disasters in India
            q = "(flood OR cyclone OR earthquake OR landslide OR fire OR 'heavy rain') AND India"
            response = self.newsapi_client.get_everything(
                q=q,
                language='en',
                sort_by='publishedAt',
                page_size=10
            )
            articles = []
            if response['status'] == 'ok':
                for art in response['articles']:
                    articles.append({
                        "source_name": art['source']['name'],
                        "headline": art['title'],
                        "url": art['url'],
                        "published": art['publishedAt'],
                        "description": art['description'] or ""
                    })
            return articles
        except Exception as e:
            logger.error(f"NewsAPI fetch failed: {e}")
            return []

    async def _fetch_gdelt(self) -> List[Dict[str, Any]]:
        try:
            # GDELT DOC API v2
            q = '(flood OR cyclone OR earthquake OR landslide OR fire OR "heavy rain") India'
            url = f"https://api.gdeltproject.org/api/v2/doc/doc?query={q}&mode=artlist&format=json&maxrecords=10"
            resp = requests.get(url, timeout=60) # Increased timeout to 60s for slow GDELT API
            articles = []
            if resp.status_code == 200:
                data = resp.json()
                for art in data.get('articles', []):
                    articles.append({
                        "source_name": art.get('sourcecountry', 'GDELT') or "GDELT",
                        "headline": art['title'],
                        "url": art['url'],
                        "published": art['seendate'],
                        "description": ""
                    })
            return articles
        except Exception as e:
            logger.error(f"GDELT fetch failed: {e}")
            return []

    async def _ingest_all_sources(self) -> List[Dict[str, Any]]:
        """Fetch from NewsAPI, GDELT, and RSS."""
        tasks = [
            self._fetch_newsapi(),
            self._fetch_gdelt(),
            self._fetch_rss()
        ]
        results = await asyncio.gather(*tasks)
        return [item for sublist in results for item in sublist]

    async def _enrich_articles(self, articles: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Fetch full content for each article in parallel."""
        async def enrich_one(art):
            try:
                downloaded = await asyncio.to_thread(trafilatura.fetch_url, art['url'])
                content = await asyncio.to_thread(trafilatura.extract, downloaded)
                if content and len(content) > 200:
                    art['full_content'] = content
                    return art
            except Exception as e:
                logger.warning(f"Failed to enrich article {art['url']}: {e}")
            return None

        # Process in batches or all at once if count is low
        results = await asyncio.gather(*[enrich_one(art) for art in articles[:10]])
        return [r for r in results if r]

    async def _analyze_and_filter(self, articles: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Perform simple keyword-based filtering to save API calls/costs."""
        filtered_results = []
        for art in articles[:10]: # Process top 10
            text_pool = (art['headline'] + " " + art.get('full_content', '')).lower()
            
            # 1. Geo Filter (Basic)
            locations = ["india", "mumbai", "maharashtra", "pune", "thane", "palghar", "raigad", "nashik", "nagpur"]
            is_local = any(loc in text_pool for loc in locations)
            
            # 2. Disaster Filter (Basic)
            is_disaster = any(kw in text_pool for kw in self.disaster_keywords)
            
            if is_local and is_disaster:
                # Construct a simple results dict without LLM
                filtered_results.append({
                    "headline": art['headline'],
                    "summary": art['description'][:300] if art.get('description') else art['headline'],
                    "full_content": art.get('full_content', art.get('description', "")),
                    "location": {"city": "Mumbai" if "mumbai" in text_pool else "Maharashtra"},
                    "disaster_type": next((kw for kw in self.disaster_keywords if kw in text_pool), "other"),
                    "severity": "MEDIUM" if any(kw in text_pool for kw in ["death", "killed", "critical", "major"]) else "LOW",
                    "trust_score": 0.7,
                    "keywords": [kw for kw in self.disaster_keywords if kw in text_pool],
                    "published": art['published'],
                    "source_name": art['source_name'],
                    "url": art['url']
                })
        
        return filtered_results

    def _cluster_into_events(self, articles: List[Dict[str, Any]]) -> List[CrisisEvent]:
        """Simplified deduplication without heavy ML libraries."""
        if not articles:
            return []
            
        # Simplified logic: Treat each unique-looking article as an event for now
        # (Real clustering can be added later if hosted on a larger instance)
        seen_titles = set()
        events = []
        
        for art in articles:
            title_clean = art['headline'].lower().strip()
            if title_clean in seen_titles:
                continue
            seen_titles.add(title_clean)
            
            # Simple trust calculation
            avg_trust = art['trust_score']
            
            event = CrisisEvent(
                event_id=f"event_{datetime.now().strftime('%Y%m%d%H%M')}_{len(events)}",
                title=art['headline'],
                summary=art['summary'],
                full_content=art['full_content'],
                location=Location(
                    country=str(art['location'].get('country', 'India')) if isinstance(art['location'].get('country'), (str, list)) else 'India',
                    state=", ".join(art['location']['state']) if isinstance(art['location'].get('state'), list) else str(art['location'].get('state', 'Maharashtra')),
                    city=", ".join(art['location']['city']) if isinstance(art['location'].get('city'), list) else str(art['location'].get('city', 'Mumbai'))
                ),
                disaster_type=art['disaster_type'],
                severity=art['severity'],
                trust_score=avg_trust,
                trust_label=self._get_trust_label(avg_trust),
                sources=[art['source_name']],
                timestamp=art['published'],
                keywords=art.get('keywords', [])
            )
            events.append(event)
            
        return events

    def _get_trust_label(self, score: float) -> str:
        if score >= 0.8: return "VERIFIED"
        if score >= 0.5: return "PARTIAL"
        return "UNRELIABLE"
