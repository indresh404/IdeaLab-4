"""
CrisisClarity — Agent Pipeline Orchestrator

Agentic AI Syllabus — CO5, Module V:
Multi-Agent Systems and Coordination.
This orchestrator runs all 4 agents in sequence, implementing
a cooperative multi-agent pipeline where each agent's output
feeds into the next agent's input.

Execution Flow:
  1. DataCollectionAgent.collect() -> raw source data (BELIEF)
  2. VerificationAgent.verify()    -> match result    (DESIRE)
  3. ScoringAgent.score()          -> score breakdown  (INTENTION)
  4. ClassificationAgent.classify()-> final verdict    (ACTION)

The pipeline also constructs the agentTrace (XAI audit trail)
and persists results to Firestore.
"""

from typing import Optional
from models.verification_models import VerificationResult, AgentTrace
from agents.data_collection_agent import DataCollectionAgent
from agents.verification_agent import VerificationAgent
from agents.scoring_agent import ScoringAgent
from agents.classification_agent import ClassificationAgent
from firebase.alert_repository import save_verification_result
from utils.logger import setup_logger, log_pipeline_event

logger = setup_logger("AgentPipeline")


class AgentPipeline:
    """
    CO5: Multi-Agent Coordination — orchestrates 4 agents in sequence.
    Each agent is independent and can be unit-tested alone.
    The pipeline aggregates their outputs into a single VerificationResult.
    """

    def __init__(self):
        self.collector = DataCollectionAgent()
        self.verifier = VerificationAgent()
        self.scorer = ScoringAgent()
        self.classifier = ClassificationAgent()

    async def run(self, alert_id: str, scenario: Optional[str] = None) -> VerificationResult:
        """
        Run the full 4-agent verification pipeline.

        Args:
            alert_id: Firestore document ID (or demo ID for scenarios)
            scenario: Optional demo scenario key ('A', 'B', 'C')

        Returns:
            Complete VerificationResult with agentTrace
        """
        log_pipeline_event(logger, "pipeline_start", alert_id,
                           f"scenario={scenario}")

        # ── Step 1: DataCollectionAgent (BELIEF) ──
        collected = await self.collector.collect(alert_id, scenario)

        if not collected:
            log_pipeline_event(logger, "pipeline_no_data", alert_id)
            return VerificationResult(
                trust_score=0,
                trust_status="POSSIBLE_FAKE_NEWS",
                trust_label="🔴 POSSIBLE_FAKE_NEWS",
                sources_checked=[],
                verification_reason="No data sources available for verification.",
                conflict_detected=False,
                agent_trace=AgentTrace(data_collected=[]),
            )

        # ── Step 2: VerificationAgent (DESIRE) ──
        match_result = self.verifier.verify(collected)

        # ── Step 3: ScoringAgent (INTENTION) ──
        score_breakdown = self.scorer.score(match_result, collected)

        # ── Step 4: ClassificationAgent (ACTION) ──
        classification = self.classifier.classify(score_breakdown, match_result, collected)

        # ── Build XAI Agent Trace ──
        trace = AgentTrace(
            data_collected=collected,
            verification_result=match_result.model_dump(),
            score_breakdown=score_breakdown.model_dump(),
        )

        result = VerificationResult(
            trust_score=classification["trust_score"],
            trust_status=classification["trust_status"],
            trust_label=classification["trust_label"],
            sources_checked=match_result.matched_sources,
            verification_reason=classification["verification_reason"],
            conflict_detected=match_result.conflict_detected,
            conflict_reason=match_result.conflict_reason,
            agent_trace=trace,
            using_real_data=classification.get("using_real_data", False),
            partial_real_data=classification.get("partial_real_data", False),
        )

        # ── Persist to Firestore (non-blocking for real alerts) ──
        if scenario is None:
            save_verification_result(alert_id, result)

        log_pipeline_event(logger, "pipeline_complete", alert_id,
                           f"score={result.trust_score}, status={result.trust_status}")
        return result
