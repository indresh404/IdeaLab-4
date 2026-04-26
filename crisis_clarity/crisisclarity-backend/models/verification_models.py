"""
CrisisClarity — Verification Result Models
Agentic AI Syllabus — CO6, Module VI: Ethics & Safety — Explainable AI for Agents.

These models provide the Explainable AI (XAI) layer, ensuring every
verification decision is fully transparent and auditable.
Human-in-the-Loop (HITL) design: citizens can inspect agentTrace
to understand WHY the system reached its verdict.
"""

from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field


class ScoreBreakdown(BaseModel):
    """
    Detailed breakdown of how the trust score was calculated.
    This is the core XAI component — every point is accounted for.
    CO6: Explainable AI requires full decision transparency.
    """
    admin_match: int = Field(0, description="Points from admin source (+40 if present and matching)")
    news_match: int = Field(0, description="Points from news source (+30 if present and matching)")
    social_match: int = Field(0, description="Points from social source (+20 if present and matching)")
    conflict_penalty: int = Field(0, description="Penalty for conflicts (-30)")
    solo_source_penalty: int = Field(0, description="Penalty for single source (-15)")
    all_agree_bonus: int = Field(0, description="Bonus if all 3 sources agree (+10)")
    final_score: int = Field(0, description="Final clamped score (0-100)")


class MatchResult(BaseModel):
    """
    Cross-verification result from the VerificationAgent.
    Tracks which sources agree and where conflicts exist.
    """
    matched_sources: List[str] = Field(default_factory=list, description="Sources that agree")
    conflict_detected: bool = Field(False, description="True if location or disaster_type mismatch")
    conflict_reason: Optional[str] = Field(None, description="Human-readable conflict explanation")
    location_score: float = Field(0.0, description="Location matching score")
    disaster_type_score: float = Field(0.0, description="Disaster type matching score")
    severity_score: float = Field(0.0, description="Severity matching score")


class AgentTrace(BaseModel):
    """
    Full trace of all agent decisions — the XAI audit trail.
    CO6: Every agent's contribution is recorded for transparency.

    BDI Architecture Mapping:
    - dataCollected: Belief (world state gathered by DataCollectionAgent)
    - verificationResult: Desire (what should be true, checked by VerificationAgent)
    - scoreBreakdown: Intention (confidence level from ScoringAgent)
    """
    data_collected: List[Dict[str, Any]] = Field(
        default_factory=list,
        description="Raw data from all sources (DataCollectionAgent output)"
    )
    verification_result: Optional[Dict[str, Any]] = Field(
        None,
        description="Cross-verification analysis (VerificationAgent output)"
    )
    score_breakdown: Optional[Dict[str, Any]] = Field(
        None,
        description="Score calculation details (ScoringAgent output)"
    )


class VerificationResult(BaseModel):
    """
    Complete verification output — returned by the agent pipeline.
    This is the final response sent to Flutter and stored in Firestore.
    
    CO5: Multi-Agent Coordination — this model aggregates outputs
    from all 4 agents into a single coherent result.
    """
    trust_score: int = Field(0, ge=0, le=100, description="Trust score 0-100")
    trust_status: str = Field("PARTIALLY_VERIFIED", description="VERIFIED | PARTIALLY_VERIFIED | POSSIBLE_FAKE_NEWS")
    trust_label: str = Field("⚠️ PARTIALLY_VERIFIED", description="Emoji + status label")
    sources_checked: List[str] = Field(default_factory=list, description="List of source names checked")
    verification_reason: str = Field("", description="Human-readable explanation")
    conflict_detected: bool = Field(False, description="Whether conflicts were found")
    conflict_reason: Optional[str] = Field(None, description="Conflict details if any")
    agent_trace: Optional[AgentTrace] = Field(None, description="Full XAI audit trail")
    using_real_data: bool = Field(False, description="True if real-time RSS data was used")
    partial_real_data: bool = Field(False, description="True if some real data was used along with mock")


class DemoScenario(BaseModel):
    """A pre-built demo scenario for testing."""
    scenario_id: str
    name: str
    description: str
    expected_score_range: str
    expected_status: str
    sources: List[Dict[str, Any]]
