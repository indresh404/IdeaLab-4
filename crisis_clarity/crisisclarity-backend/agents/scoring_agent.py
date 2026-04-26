"""
CrisisClarity — Agent 3: ScoringAgent

Agentic AI Syllabus — CO3, Module III:
LLM-Powered Agents with Tool Calling.
Scoring function acts as a reward model, evaluating
agent observations and assigning utility values.
Ref: Utility-based agents, Memory-Augmented scoring.

BDI Architecture Role: INTENTION
Converts verification analysis into a numeric confidence level.
"""

from typing import List, Dict, Any
from models.verification_models import MatchResult, ScoreBreakdown
from utils.logger import setup_logger, log_agent_step

logger = setup_logger("ScoringAgent")


class ScoringAgent:
    """
    Agentic AI Syllabus — CO3, Module III:
    LLM-Powered Agents with Tool Calling.
    Scoring function acts as a reward model, evaluating
    agent observations and assigning utility values.
    Ref: Utility-based agents, Memory-Augmented scoring.

    Scoring logic:
      Base score starts at 0.
      + 40 if admin source present and matches
      + 30 if news source present and matches
      + 20 if social source present and matches
      - 30 if conflict_detected is True
      - 15 if only one source total
      + 10 bonus if all three sources agree
      Clamp: max(0, min(100, score))
    """

    def __init__(self):
        self.agent_name = "ScoringAgent"

    def score(self, match_result: MatchResult, collected_data: List[Dict[str, Any]]) -> ScoreBreakdown:
        """Calculate trust score from verification result."""
        log_agent_step(logger, self.agent_name, "score_start",
                       f"matched={match_result.matched_sources}, conflict={match_result.conflict_detected}")

        matched_names = [s.lower() for s in match_result.matched_sources]
        
        admin_pts = 0
        news_pts = 0
        social_pts = 0
        news_count = 0
        
        # Calculate scores based on dynamic trust weights
        for source in collected_data:
            s_name = source["source_name"].lower()
            if s_name in matched_names:
                weight = source.get("trust_weight", 20)
                if source["source"] == "admin":
                    admin_pts = weight
                elif source["source"] in ["news_source", "official_disaster"]:
                    # Keep the highest weight for news sources
                    news_pts = max(news_pts, weight)
                    news_count += 1
                elif source["source"] == "social_media":
                    social_pts = weight

        conflict_pen = -30 if match_result.conflict_detected else 0
        solo_pen = -15 if len(collected_data) <= 1 else 0

        # Consensus bonus: If multiple news/official sources agree
        agree_bonus = 10 if news_count >= 2 else 0
        
        # If admin, news and social all agree
        has_admin = any(s["source"] == "admin" for s in collected_data)
        has_news = any(s["source"] in ["news_source", "official_disaster"] for s in collected_data)
        has_social = any(s["source"] == "social_media" for s in collected_data)
        
        if has_admin and has_news and has_social:
            all_types_matched = True
            for stype in ["admin", "news_source", "official_disaster", "social_media"]:
                # Logic simplified: if we have admin in matched, and news in matched, and social in matched
                pass
            # Existing simple logic for "all three"
            all_matched_types = set()
            for source in collected_data:
                if source["source_name"].lower() in matched_names:
                    all_matched_types.add(source["source"])
            
            if "admin" in all_matched_types and \
               ("news_source" in all_matched_types or "official_disaster" in all_matched_types) and \
               "social_media" in all_matched_types:
                agree_bonus += 5 # Additional 5 if all 3 layers agree

        raw = admin_pts + news_pts + social_pts + conflict_pen + solo_pen + agree_bonus
        final = max(0, min(100, raw))

        breakdown = ScoreBreakdown(
            admin_match=admin_pts,
            news_match=news_pts,
            social_match=social_pts,
            conflict_penalty=conflict_pen,
            solo_source_penalty=solo_pen,
            all_agree_bonus=agree_bonus,
            final_score=final,
        )

        log_agent_step(logger, self.agent_name, "score_complete",
                       f"admin={admin_pts} news={news_pts} social={social_pts} "
                       f"conflict={conflict_pen} solo={solo_pen} bonus={agree_bonus} => {final}")
        return breakdown
