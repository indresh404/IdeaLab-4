"""
CrisisClarity — Crisis Scoring Agent (v2)

Autonomous agent that processes a single event from news_data.json format,
runs classification → scoring → verification, and returns enriched event
with computed severity_score, confidence_score, trust_label, and ai_analysis.

Uses Groq LLM when available, falls back to rule-based scoring.
"""

import os
import json
from typing import Dict, Any, Optional, List
from utils.logger import setup_logger

logger = setup_logger("CrisisScoringAgent")


# ── Keyword-based severity weights ───────────────────────────────────────────

SEVERITY_KEYWORDS = {
    "deaths": {"died", "killed", "dead", "fatality", "fatal", "casualties", "death"},
    "infrastructure": {"collapsed", "collapse", "destroyed", "damaged", "derailed", "blocked"},
    "transport": {"disruption", "diverted", "closed", "delayed", "stranded", "stuck"},
    "weather": {"heavy rainfall", "cyclone", "storm", "heatwave", "earthquake", "tremor"},
    "population": {"evacuated", "evacuation", "trapped", "rescued", "hospitalized", "affected"},
    "fire_explosion": {"fire", "blaze", "explosion", "smoke", "flames", "burning", "gas leak"},
}

SOURCE_CREDIBILITY = {
    "IMD": 0.95,
    "NDTV": 0.85,
    "Times of India": 0.85,
    "Hindustan Times": 0.85,
    "BMC": 0.90,
    "BMC Official": 0.92,
    "NDRF": 0.95,
    "National Center for Seismology": 0.95,
    "MSETCL": 0.88,
    "MMRDA": 0.88,
    "MSRDC": 0.88,
    "HPCL": 0.85,
    "Local Mumbai News": 0.65,
    "Mumbai Local Post": 0.40,
    "Twitter": 0.30,
}


class CrisisScoringAgent:
    """
    Processes a single crisis event and computes:
    - severity_score (0-1): How severe is this event?
    - confidence_score (0-1): How confident are we in the report?
    - trust_label: VERIFIED | PARTIALLY_VERIFIED | UNVERIFIED
    - ai_analysis: {risk_summary, recommended_action}
    """

    def __init__(self, groq_api_key: Optional[str] = None):
        self.groq_api_key = groq_api_key or os.getenv("GROQ_API_KEY")
        self._groq_client = None

    def _get_groq(self):
        """Lazy-load Groq client."""
        if self._groq_client is not None:
            return self._groq_client
        if not self.groq_api_key:
            return None
        try:
            from groq import Groq
            self._groq_client = Groq(api_key=self.groq_api_key)
            return self._groq_client
        except Exception as e:
            logger.warning(f"Groq client init failed: {e}")
            return None

    async def process_event(self, event: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process a single event through the full agent pipeline.

        Args:
            event: Event dict from news_data.json format

        Returns:
            Enriched event dict with computed scores
        """
        event_id = event.get("event_id", "UNKNOWN")
        logger.info(f"🧠 Processing event {event_id}: {event.get('title', '')[:50]}...")

        # Step 1: Compute severity score
        severity_score = self._compute_severity_score(event)

        # Step 2: Compute confidence score
        confidence_score = self._compute_confidence_score(event)

        # Step 3: Determine trust label
        trust_label = self._determine_trust_label(event, confidence_score)

        # Step 4: Determine severity category
        severity_label = self._severity_score_to_label(severity_score)

        # Step 5: Generate AI analysis (LLM or rule-based)
        ai_analysis = await self._generate_ai_analysis(event, severity_score, confidence_score)

        # Update event with computed values
        event["severity_score"] = round(severity_score, 2)
        event["confidence_score"] = round(confidence_score, 2)
        event["trust_label"] = trust_label
        event["severity"] = severity_label
        event["ai_analysis"] = ai_analysis

        logger.info(
            f"  ✅ {event_id}: severity={severity_score:.2f} ({severity_label}), "
            f"confidence={confidence_score:.2f}, trust={trust_label}"
        )

        return event

    def _compute_severity_score(self, event: Dict[str, Any]) -> float:
        """
        Compute severity_score (0-1) based on:
        - Death/casualty keywords
        - Infrastructure damage keywords
        - Transport disruption keywords
        - Weather intensity keywords
        - Population impact keywords
        - Disaster type weight
        """
        text = f"{event.get('title', '')} {event.get('summary', '')} {event.get('full_description', '')}".lower()

        score = 0.0
        max_score = 0.0

        # Keyword-based scoring
        weights = {
            "deaths": 0.30,
            "infrastructure": 0.20,
            "transport": 0.15,
            "weather": 0.10,
            "population": 0.15,
            "fire_explosion": 0.10,
        }

        for category, keywords in SEVERITY_KEYWORDS.items():
            weight = weights.get(category, 0.1)
            max_score += weight
            if any(kw in text for kw in keywords):
                score += weight

        # Disaster type base weight
        dtype_weights = {
            "fire": 0.75,
            "earthquake": 0.60,
            "cyclone": 0.70,
            "flood": 0.55,
            "landslide": 0.50,
            "industrial accident": 0.72,
            "infrastructure failure": 0.45,
            "heatwave": 0.40,
        }
        dtype = event.get("disaster_type", "").lower()
        dtype_base = dtype_weights.get(dtype, 0.35)

        # Combine keyword score with type base
        keyword_score = (score / max_score) if max_score > 0 else 0
        final_score = 0.4 * dtype_base + 0.6 * keyword_score

        # Boost if specific high-impact words found
        if any(w in text for w in ["died", "killed", "dead", "death"]):
            final_score = min(1.0, final_score + 0.15)
        if any(w in text for w in ["trapped", "rescued"]):
            final_score = min(1.0, final_score + 0.10)
        if any(w in text for w in ["evacuated", "evacuation"]):
            final_score = min(1.0, final_score + 0.08)

        return min(1.0, max(0.0, final_score))

    def _compute_confidence_score(self, event: Dict[str, Any]) -> float:
        """
        Compute confidence_score (0-1) based on:
        - Number of sources
        - Credibility of sources
        - Source agreement (do they report the same facts?)
        """
        sources = event.get("sources", [])
        num_sources = len(sources)

        if num_sources == 0:
            return 0.10

        # Base score from number of sources
        if num_sources >= 3:
            base = 0.70
        elif num_sources == 2:
            base = 0.50
        else:
            base = 0.25

        # Source credibility boost
        total_cred = 0.0
        for source in sources:
            name = source.get("source_name", "")
            cred = SOURCE_CREDIBILITY.get(name, 0.50)
            total_cred += cred

        avg_cred = total_cred / num_sources if num_sources > 0 else 0.50
        cred_boost = avg_cred * 0.30  # Up to 0.30 from credibility

        # Source agreement (simple: check if snippets overlap in key terms)
        agreement_score = 0.0
        if num_sources >= 2:
            snippets = [s.get("snippet", "").lower() for s in sources]
            # Check if key disaster words appear across multiple snippets
            all_words = set()
            for s in snippets:
                all_words.update(s.split())

            common_words = set()
            for word in all_words:
                count = sum(1 for s in snippets if word in s)
                if count >= 2 and len(word) > 4:  # Non-trivial word in 2+ sources
                    common_words.add(word)

            agreement_score = min(0.15, len(common_words) * 0.02)

        final = min(1.0, base + cred_boost + agreement_score)
        return max(0.0, final)

    def _determine_trust_label(self, event: Dict[str, Any], confidence: float) -> str:
        """
        Determine trust_label based on sources and confidence.
        Rules:
        - 3+ credible sources → VERIFIED
        - 2 sources or mixed credibility → PARTIALLY_VERIFIED
        - 1 low-credibility source → UNVERIFIED
        """
        sources = event.get("sources", [])
        num_sources = len(sources)

        # Count credible sources (credibility > 0.6)
        credible_count = 0
        for source in sources:
            name = source.get("source_name", "")
            cred = SOURCE_CREDIBILITY.get(name, 0.50)
            if cred >= 0.60:
                credible_count += 1

        if credible_count >= 3:
            return "VERIFIED"
        elif credible_count >= 2 or (num_sources >= 2 and confidence >= 0.50):
            return "PARTIALLY_VERIFIED"
        else:
            return "UNVERIFIED"

    def _severity_score_to_label(self, score: float) -> str:
        """Convert severity score (0-1) to category label."""
        if score >= 0.75:
            return "CRITICAL"
        elif score >= 0.55:
            return "HIGH"
        elif score >= 0.35:
            return "MEDIUM"
        else:
            return "LOW"

    async def _generate_ai_analysis(
        self, event: Dict[str, Any], severity: float, confidence: float
    ) -> Dict[str, str]:
        """
        Generate ai_analysis using Groq LLM.
        Falls back to rule-based if LLM is not available.
        """
        # Try LLM first
        groq = self._get_groq()
        if groq:
            try:
                return await self._llm_analysis(groq, event, severity, confidence)
            except Exception as e:
                logger.warning(f"LLM analysis failed, using rule-based: {e}")

        # Rule-based fallback
        return self._rule_based_analysis(event, severity)

    async def _llm_analysis(
        self, groq, event: Dict[str, Any], severity: float, confidence: float
    ) -> Dict[str, str]:
        """Use Groq LLM to generate risk summary and recommended action."""
        prompt = f"""Analyze this disaster event and provide:
1. A one-sentence risk summary (what's the main danger)
2. A one-sentence recommended action for citizens

Event: {event.get('title', '')}
Description: {event.get('full_description', event.get('summary', ''))[:500]}
Type: {event.get('disaster_type', '')}
Location: {json.dumps(event.get('location', {}))}
Severity Score: {severity:.2f}

Respond in this exact JSON format only, no other text:
{{"risk_summary": "...", "recommended_action": "..."}}"""

        response = groq.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[
                {"role": "system", "content": "You are a disaster risk analyst. Respond ONLY in valid JSON format."},
                {"role": "user", "content": prompt},
            ],
            temperature=0.3,
            max_tokens=200,
        )

        text = response.choices[0].message.content.strip()

        # Try to parse JSON from response
        try:
            # Handle case where LLM wraps in markdown
            if "```" in text:
                text = text.split("```")[1]
                if text.startswith("json"):
                    text = text[4:]
                text = text.strip()

            result = json.loads(text)
            return {
                "risk_summary": result.get("risk_summary", "Analysis unavailable"),
                "recommended_action": result.get("recommended_action", "Follow official instructions"),
            }
        except json.JSONDecodeError:
            logger.warning(f"Could not parse LLM JSON, using rule-based")
            return self._rule_based_analysis(event, severity)

    def _rule_based_analysis(self, event: Dict[str, Any], severity: float) -> Dict[str, str]:
        """Generate analysis without LLM."""
        dtype = event.get("disaster_type", "unknown").lower()
        location = event.get("location", {})
        city = location.get("city", "the area") if isinstance(location, dict) else "the area"

        risk_templates = {
            "flood": f"Urban flooding in {city}, risk of water damage and transport disruption",
            "fire": f"Active fire emergency in {city}, risk of smoke inhalation and property damage",
            "earthquake": f"Seismic activity near {city}, potential structural damage",
            "cyclone": f"Cyclone approaching {city}, coastal flooding and high wind risk",
            "landslide": f"Landslide blocking infrastructure near {city}",
            "industrial accident": f"Industrial hazard in {city}, potential toxic exposure",
            "infrastructure failure": f"Infrastructure compromise in {city}, public safety risk",
            "heatwave": f"Extreme heat conditions in {city}, health risk for vulnerable populations",
        }

        action_templates = {
            "flood": "Avoid low-lying areas and waterlogged roads. Move to higher ground if needed.",
            "fire": "Evacuate if nearby. Close windows, wear mask outdoors. Call 101 for fire brigade.",
            "earthquake": "Drop, Cover, Hold. Stay away from buildings and power lines.",
            "cyclone": "Stay indoors, away from coast. Secure loose objects. Follow BMC updates.",
            "landslide": "Avoid affected route. Use alternate roads. Check MSRDC for updates.",
            "industrial accident": "Avoid the area. Wear N95 mask outdoors. Close windows and doors.",
            "infrastructure failure": "Avoid affected area. Report issues to BMC helpline 1916.",
            "heatwave": "Stay indoors 12-4 PM. Drink water frequently. Check on elderly neighbors.",
        }

        # Use existing ai_analysis if present
        existing = event.get("ai_analysis", {})
        if existing and existing.get("risk_summary") and existing.get("recommended_action"):
            return existing

        return {
            "risk_summary": risk_templates.get(dtype, f"Emergency situation in {city}"),
            "recommended_action": action_templates.get(dtype, "Stay alert and follow official instructions. Call 112 for emergencies."),
        }

    async def process_batch(self, events: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Process a batch of events through the agent pipeline."""
        results = []
        for event in events:
            enriched = await self.process_event(event)
            results.append(enriched)
        return results
