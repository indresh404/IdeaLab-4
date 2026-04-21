"""
CrisisClarity — Agent 4: ClassificationAgent

Agentic AI Syllabus — CO5, CO6, Module V-VI:
Multi-Agent Coordination + Ethics & Safety.
Final classification is the output of the agent team's
coordinated decision. XAI explanation ensures Human-in-the-Loop
(HITL) by showing citizens WHY the verdict was reached.
Ref: CrewAI role-based output, Explainable AI for Agents.

BDI Architecture Role: ACTION
Converts the numeric score into a human-readable verdict
and generates the explanation that citizens will see.
"""

from typing import List, Dict, Any, Optional
from models.verification_models import ScoreBreakdown, MatchResult
from utils.logger import setup_logger, log_agent_step

logger = setup_logger("ClassificationAgent")


class ClassificationAgent:
    """
    Agentic AI Syllabus — CO5, CO6, Module V-VI:
    Multi-Agent Coordination + Ethics & Safety.
    Final classification is the output of the agent team's
    coordinated decision. XAI explanation ensures Human-in-the-Loop
    (HITL) by showing citizens WHY the verdict was reached.
    Ref: CrewAI role-based output, Explainable AI for Agents.

    Rules:
      80-100 -> "VERIFIED"              (green, ✅)
      40-79  -> "PARTIALLY_VERIFIED"    (amber, ⚠️)
      0-39   -> "POSSIBLE_FAKE_NEWS"    (red,   🔴)
    """

    def __init__(self):
        self.agent_name = "ClassificationAgent"

    def classify(
        self,
        score_breakdown: ScoreBreakdown,
        match_result: MatchResult,
        collected_data: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """
        Convert score to status label and generate explanation.
        
        CO6: The explanation templates ensure full transparency —
        citizens can understand WHY the system reached its verdict.
        """
        score = score_breakdown.final_score
        log_agent_step(logger, self.agent_name, "classify_start", f"score={score}")

        # Check for real data usage
        has_real = any(source.get("is_real_data", False) for source in collected_data)
        has_mock = any(not source.get("is_real_data", False) for source in collected_data)
        
        using_real = has_real and not has_mock
        partial_real = has_real and has_mock

        if score >= 80:
            status = "VERIFIED"
            label = "✅ VERIFIED"
        elif score >= 40:
            status = "PARTIALLY_VERIFIED"
            label = "⚠️ PARTIALLY_VERIFIED"
        else:
            status = "POSSIBLE_FAKE_NEWS"
            label = "🔴 POSSIBLE_FAKE_NEWS"

        reason = self._generate_reason(
            status, score, match_result, collected_data
        )

        log_agent_step(logger, self.agent_name, "classify_complete",
                       f"status={status}, label={label}")

        return {
            "trust_score": score,
            "trust_status": status,
            "trust_label": label,
            "verification_reason": reason,
            "using_real_data": using_real,
            "partial_real_data": partial_real,
        }

    def _generate_reason(
        self,
        status: str,
        score: int,
        match_result: MatchResult,
        collected_data: List[Dict[str, Any]],
    ) -> str:
        """Generate human-readable explanation using templates. CO6: XAI."""
        sources = match_result.matched_sources
        source_count = len(collected_data)

        # Determine location and disaster type from first source
        location = collected_data[0]["location"] if collected_data else "Unknown"
        dtype = collected_data[0]["disaster_type"] if collected_data else "unknown"

        if status == "VERIFIED":
            return (
                f"Multiple trusted sources confirm this event in {location}. "
                f"Admin and news sources agree on {dtype} severity."
            )
        elif status == "PARTIALLY_VERIFIED":
            return (
                f"Limited verification available. Only {source_count} source(s) "
                f"reported this event. Treat with moderate caution."
            )
        else:
            conflict_info = match_result.conflict_reason or "No official confirmation available"
            return (
                f"⚠️ Conflicting or unverified reports detected. {conflict_info}. "
                f"Do not rely on this alert without official confirmation."
            )
