"""
CrisisClarity — Structured Logger
Agentic AI Syllabus — CO4, Module IV: Autonomous Agents.

Structured logging is essential for tracing agent decisions
in production. Each agent step is logged with context so that
the full decision chain can be reconstructed for debugging
and explainability (XAI) purposes.
"""

import logging
import sys
import io
from datetime import datetime


def setup_logger(name: str = "crisisclarity", level: int = logging.INFO) -> logging.Logger:
    """
    Create a structured logger with consistent formatting.
    
    Agent traces are logged at INFO level for normal operation
    and DEBUG level for detailed step-by-step reasoning.
    
    Uses UTF-8 encoding on Windows to support emoji characters
    in agent trace logs.
    """
    logger = logging.getLogger(name)
    
    # Avoid duplicate handlers
    if logger.handlers:
        return logger
    
    logger.setLevel(level)
    
    # Console handler with UTF-8 support for Windows emoji handling
    stream = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    console_handler = logging.StreamHandler(stream)
    console_handler.setLevel(level)
    
    # Format: timestamp | level | module | message
    formatter = logging.Formatter(
        fmt="%(asctime)s | %(levelname)-8s | %(name)-20s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    return logger


def log_agent_step(logger: logging.Logger, agent_name: str, step: str, details: str = ""):
    """
    Log a structured agent step for the XAI trace.
    
    CO6: Every agent action is logged for transparency and auditability.
    This supports the Human-in-the-Loop principle — operators can inspect
    the full decision chain.
    
    Args:
        logger: Logger instance
        agent_name: Name of the agent (e.g., "DataCollectionAgent")
        step: Step description (e.g., "collecting_sources")
        details: Additional context
    """
    timestamp = datetime.utcnow().isoformat()
    logger.info(f"[AGENT] [{agent_name}] Step: {step} | {details} | ts={timestamp}")


def log_pipeline_event(logger: logging.Logger, event: str, alert_id: str = "", details: str = ""):
    """
    Log a pipeline-level event (start, complete, error).
    
    Args:
        logger: Logger instance
        event: Event type (e.g., "pipeline_start", "pipeline_complete")
        alert_id: The alert being processed
        details: Additional context
    """
    logger.info(f"[PIPELINE] {event} | alertId={alert_id} | {details}")


# Create default logger instance
default_logger = setup_logger()
