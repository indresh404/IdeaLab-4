"""
CrisisClarity — Agent 2: VerificationAgent

Agentic AI Syllabus — CO2, Module II:
Core Components of Agentic Systems.
Implements Environment Modeling in a partially observable
environment (POMDPs) — we cannot observe all news sources
directly, so we reason under uncertainty using match scores.
Ref: STRIPS planning, Reward Design for Autonomous Agents.

BDI Architecture Role: DESIRE
"""

from typing import List, Dict, Any
from models.verification_models import MatchResult
from utils.logger import setup_logger, log_agent_step

logger = setup_logger("VerificationAgent")
SEVERITY_LEVELS = ["low", "medium", "high", "critical"]


class VerificationAgent:
    """
    Agentic AI Syllabus — CO2, Module II:
    Core Components of Agentic Systems.
    Implements Environment Modeling in a partially observable
    environment (POMDPs) — we cannot observe all news sources
    directly, so we reason under uncertainty using match scores.
    Ref: STRIPS planning, Reward Design for Autonomous Agents.
    """

    def __init__(self):
        self.agent_name = "VerificationAgent"

    def verify(self, collected_data: List[Dict[str, Any]]) -> MatchResult:
        """Cross-check all collected source data for consistency."""
        log_agent_step(logger, self.agent_name, "verify_start", f"{len(collected_data)} source(s)")

        if not collected_data:
            return MatchResult(matched_sources=[], conflict_detected=False,
                               conflict_reason="No data available for verification")

        if len(collected_data) == 1:
            src = collected_data[0]
            return MatchResult(matched_sources=[src["source"]], conflict_detected=False,
                               location_score=1.0, disaster_type_score=1.0, severity_score=1.0)

        sorted_src = sorted(collected_data, key=lambda s: s.get("trust_weight", 0), reverse=True)
        ref = sorted_src[0]
        matched = [ref["source"]]
        conflicts = []
        t_loc = t_type = t_sev = 0.0
        n = 0

        for other in sorted_src[1:]:
            n += 1
            ls = self._cmp_loc(ref["location"], other["location"])
            ts = self._cmp_type(ref["disaster_type"], other["disaster_type"])
            ss = self._cmp_sev(ref["severity"], other["severity"])
            t_loc += ls; t_type += ts; t_sev += ss

            if ts >= 0 and ls > 0:
                matched.append(other["source"])
            else:
                parts = []
                if ts < 0:
                    parts.append(f"{other['source'].capitalize()} reports {other['disaster_type']} but {ref['source']} reports {ref['disaster_type']}")
                if ls <= 0:
                    parts.append(f"Location mismatch: {other['source']} says '{other['location']}' vs '{ref['location']}'")
                conflicts.append("; ".join(parts) if parts else "Minor inconsistency")

        result = MatchResult(
            matched_sources=matched,
            conflict_detected=len(conflicts) > 0,
            conflict_reason="; ".join(conflicts) if conflicts else None,
            location_score=round(t_loc / n, 2) if n else 0,
            disaster_type_score=round(t_type / n, 2) if n else 0,
            severity_score=round(t_sev / n, 2) if n else 0,
        )
        log_agent_step(logger, self.agent_name, "verify_complete", f"matched={matched}, conflict={result.conflict_detected}")
        return result

    def _cmp_loc(self, a: str, b: str) -> float:
        a, b = a.lower().strip(), b.lower().strip()
        if a == b: return 1.0
        if a in b or b in a: return 0.5
        if set(a.replace(",","").split()) & set(b.replace(",","").split()): return 0.5
        return 0.0

    def _cmp_type(self, a: str, b: str) -> float:
        return 1.0 if a.lower().strip() == b.lower().strip() else -1.0

    def _cmp_sev(self, a: str, b: str) -> float:
        a, b = a.lower().strip(), b.lower().strip()
        if a == b: return 1.0
        try:
            diff = abs(SEVERITY_LEVELS.index(a) - SEVERITY_LEVELS.index(b))
            return 0.5 if diff == 1 else -1.0
        except ValueError:
            return 0.0
