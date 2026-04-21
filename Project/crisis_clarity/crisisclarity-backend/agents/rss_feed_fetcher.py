import feedparser
import asyncio
import logging
from datetime import datetime
from agents.rss_cache import rss_cache

logger = logging.getLogger("RSSFeedFetcher")

class RSSFeedFetcher:
    def __init__(self):
        self.feed_configs = [
            {
                "name": "times_of_india",
                "url": "https://timesofindia.indiatimes.com/rssfeedstopstories.cms",
                "backup_url": "https://timesofindia.indiatimes.com/rss.cms",
                "source_type": "news",
                "trust_weight": 28,
                "display_name": "Times of India"
            },
            {
                "name": "ndtv_india",
                "url": "https://feeds.feedburner.com/ndtvnews-india-news",
                "backup_url": None,
                "source_type": "news",
                "trust_weight": 28,
                "display_name": "NDTV India"
            },
            {
                "name": "gdacs",
                "url": "https://www.gdacs.org/xml/rss.xml",
                "backup_url": None,
                "source_type": "official_disaster",
                "trust_weight": 35,
                "display_name": "GDACS (UN Disaster)"
            },
            {
                "name": "reliefweb_india",
                "url": "https://reliefweb.int/updates/rss.xml?primary_country=119",
                "backup_url": None,
                "source_type": "official_disaster",
                "trust_weight": 30,
                "display_name": "ReliefWeb India"
            }
        ]

        self.disaster_keywords = [
            "flood", "flooding", "waterlogging", "cyclone", "storm",
            "fire", "earthquake", "landslide", "tsunami", "drought",
            "emergency", "alert", "warning",
            "heavy rain", "rainfall", "cloudburst", "high tide",
            "infrastructure collapse", "accident", "explosion"
        ]

        self.location_keywords = [
            "mumbai", "maharashtra", "pune", "nagpur", "thane",
            "navi mumbai", "kalyan", "nashik", "aurangabad",
            "konkan", "vidarbha", "marathwada",
            "kurla", "dharavi", "andheri", "bandra", "dadar",
            "borivali", "malad", "kandivali", "vasai", "virar",
            "panvel", "raigad", "ratnagiri", "sindhudurg",
            "india", "indian"
        ]

    async def fetch_feed(self, feed_config: dict) -> list[dict]:
        try:
            url = feed_config["url"]
            feed = await asyncio.to_thread(feedparser.parse, url)
            
            if not feed.entries and feed_config.get("backup_url"):
                logger.info(f"Primary feed empty for {feed_config['name']}, trying backup...")
                url = feed_config["backup_url"]
                feed = await asyncio.to_thread(feedparser.parse, url)

            articles = []
            for entry in feed.entries[:20]:
                title = entry.get("title", "")
                summary = entry.get("summary", "") or entry.get("description", "")
                link = entry.get("link", "")
                published = entry.get("published", "") or entry.get("updated", "")
                
                full_text = f"{title} {summary}"
                full_text_lower = full_text.lower()

                # Relevance checking
                is_disaster = any(kw in full_text_lower for kw in self.disaster_keywords)
                
                if feed_config["name"] == "gdacs":
                    is_relevant_location = True # Global disaster feed, filter later by content
                else:
                    is_relevant_location = any(kw in full_text_lower for kw in self.location_keywords)

                # Special check for GDACS: must have 'india' in text if we are treating location as True
                if feed_config["name"] == "gdacs" and "india" not in full_text_lower:
                    is_relevant_location = False

                if is_disaster and is_relevant_location:
                    info = self.extract_disaster_info(full_text)
                    
                    articles.append({
                        "source": feed_config["name"],
                        "source_type": feed_config["source_type"],
                        "display_name": feed_config["display_name"],
                        "trust_weight": feed_config["trust_weight"],
                        "location": info["location"],
                        "disaster_type": info["disaster_type"],
                        "severity": info["severity"],
                        "description": summary[:200] if summary else "",
                        "headline": title,
                        "url": link,
                        "published": published,
                        "fetched_at": datetime.utcnow().isoformat(),
                        "confidence": 0.75 if feed_config["name"] == "gdacs" else 0.5
                    })
            
            return articles

        except Exception as e:
            logger.warning(f"RSS fetch failed for {feed_config['name']}: {str(e)}")
            return []

    def extract_disaster_info(self, text: str) -> dict:
        text_lower = text.lower()
        
        # Disaster Type
        if any(kw in text_lower for kw in ["flood", "flooding", "waterlog", "inundation", "heavy rain", "rainfall", "cloudburst"]):
            disaster_type = "flood"
        elif any(kw in text_lower for kw in ["fire", "blaze", "inferno", "arson"]):
            disaster_type = "fire"
        elif any(kw in text_lower for kw in ["cyclone", "storm", "hurricane", "typhoon", "wind"]):
            disaster_type = "storm"
        elif any(kw in text_lower for kw in ["earthquake", "tremor", "quake", "seismic"]):
            disaster_type = "earthquake"
        elif any(kw in text_lower for kw in ["evacuate", "evacuation", "displaced"]):
            disaster_type = "evacuation"
        elif any(kw in text_lower for kw in ["landslide", "mudslide"]):
            disaster_type = "landslide"
        else:
            disaster_type = "general_disaster"

        # Severity
        if any(kw in text_lower for kw in ["critical", "catastrophic", "massive", "major", "severe", "deadly", "fatal", "deaths", "killed", "red alert", "extreme"]):
            severity = "critical"
        elif any(kw in text_lower for kw in ["high", "heavy", "serious", "significant", "orange alert", "large", "widespread"]):
            severity = "high"
        elif any(kw in text_lower for kw in ["moderate", "medium", "yellow alert", "warning"]):
            severity = "medium"
        else:
            severity = "low"

        # Location
        p1 = ["kurla", "dharavi", "andheri", "bandra", "dadar", "borivali", "malad", "kandivali", "thane", "navi mumbai", "vasai", "virar", "panvel"]
        p2 = ["mumbai", "pune", "nagpur", "nashik", "aurangabad"]
        p3 = ["maharashtra", "konkan", "vidarbha", "raigad", "ratnagiri"]
        p4 = ["india"]

        extracted_location = "Maharashtra"
        for priority_list in [p1, p2, p3, p4]:
            found = False
            for loc in priority_list:
                if loc in text_lower:
                    extracted_location = loc.capitalize()
                    found = True
                    break
            if found:
                break
        
        return {
            "disaster_type": disaster_type,
            "severity": severity,
            "location": extracted_location
        }

    async def fetch_all_feeds(self) -> list[dict]:
        cached = rss_cache.get("all_feeds")
        if cached is not None:
            return cached

        tasks = [self.fetch_feed(config) for config in self.feed_configs]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        flattened = []
        for res in results:
            if isinstance(res, list):
                flattened.extend(res)
            elif isinstance(res, Exception):
                logger.error(f"Async feed task failed: {str(res)}")

        rss_cache.set("all_feeds", flattened)
        return flattened

    def deduplicate(self, articles: list[dict]) -> list[dict]:
        seen_keys = set()
        deduped = []
        
        for art in articles:
            key = f"{art['disaster_type']}_{art['location']}_{art['source_type']}"
            if key not in seen_keys:
                deduped.append(art)
                seen_keys.add(key)
        
        return deduped[:10]
