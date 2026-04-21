"""
CrisisClarity — Alert Data Models
Agentic AI Syllabus — CO2, Module II: Core Components of Agentic Systems.

Pydantic models ensure type-safe data flow between agents.
These models represent the structured environment state that agents
observe and act upon (Perception → Decision → Action loop).
"""

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class SourceData(BaseModel):
    """
    Represents a single data source observation.
    Each source provides a partial view of the environment (POMDP).
    """
    source: str = Field(..., description="Source identifier: 'admin', 'news', or 'social'")
    location: str = Field(..., description="Reported disaster location")
    disaster_type: str = Field(..., description="Type: flood, fire, storm, evacuation")
    severity: str = Field(..., description="Severity: low, medium, high, critical")
    description: str = Field(..., description="Human-readable description of the event")
    timestamp: str = Field(..., description="ISO8601 timestamp of the report")
    trust_weight: int = Field(0, description="Base trust weight for this source type")


class AlertData(BaseModel):
    """
    Core alert structure matching Firestore schema.
    Maps to Flutter AlertModel fields.
    """
    alert_id: str = Field(..., description="Firestore document ID")
    title: str = Field("", description="Alert title (English)")
    title_hi: str = Field("", description="Alert title (Hindi)")
    title_mr: str = Field("", description="Alert title (Marathi)")
    description: str = Field("", description="Alert description (English)")
    description_hi: str = Field("", description="Alert description (Hindi)")
    description_mr: str = Field("", description="Alert description (Marathi)")
    simplified_en: str = Field("", description="Simplified description (English)")
    simplified_hi: str = Field("", description="Simplified description (Hindi)")
    simplified_mr: str = Field("", description="Simplified description (Marathi)")
    disaster_type: str = Field("unknown", description="Type of disaster")
    severity: str = Field("low", description="Severity level")
    affected_zones: List[str] = Field(default_factory=list, description="List of affected areas")
    posted_by: str = Field("", description="Admin user who posted")
    is_active: bool = Field(True, description="Whether alert is currently active")
    created_at: Optional[str] = Field(None, description="ISO8601 creation timestamp")
    updated_at: Optional[str] = Field(None, description="ISO8601 last update timestamp")


class AlertVerificationRequest(BaseModel):
    """Request body for POST /verify-alert endpoint."""
    alertId: str = Field(..., description="Firestore alert document ID")
    scenario: Optional[str] = Field(None, description="Demo scenario: 'A', 'B', 'C', or null for real alert")


class TelegramSendRequest(BaseModel):
    """Request body for POST /send-telegram/{alertId} endpoint."""
    chat_ids: Optional[List[int]] = Field(None, description="Specific chat IDs to send to. If null, sends to all subscribed.")

class Location(BaseModel):
    """Specific geo-coordinates or administrative region."""
    country: Optional[str] = "India"
    state: Optional[str] = "Maharashtra"
    city: Optional[str] = "Mumbai"


class CrisisEvent(BaseModel):
    """
    Structured intelligence event aggregated from multiple sources.
    Behaves like a 'Crisis Intelligence Engine' output.
    """
    event_id: str = Field(..., description="Unique event identifier")
    title: str = Field(..., description="Clean, aggregated event title")
    summary: str = Field(..., description="High-level situational summary")
    full_content: str = Field(..., description="Cleaned, enriched primary content")
    location: Location = Field(default_factory=Location)
    disaster_type: str = Field(..., description="flood, cyclone, earthquake, etc.")
    severity: str = Field(..., description="LOW, MEDIUM, HIGH, CRITICAL")
    trust_score: float = Field(0.0, description="Aggregated trust score (0-1)")
    trust_label: str = Field("UNRELIABLE", description="VERIFIED, PARTIAL, UNRELIABLE")
    sources: List[str] = Field(default_factory=list, description="List of source names confirmed")
    timestamp: str = Field(..., description="ISO8601 timestamp of the latest update")
    keywords: List[str] = Field(default_factory=list, description="Extracted disaster keywords")
