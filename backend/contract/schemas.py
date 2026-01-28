from __future__ import annotations

from typing import Any, List, Optional

from pydantic import BaseModel, Field


class Citation(BaseModel):
    clause_id: str
    quote: str


class Proposal(BaseModel):
    clause_id: str
    proposed_text: str
    rationale: str = ""
    citations: List[Citation] = Field(default_factory=list)


class AgentMessage(BaseModel):
    agent: str
    content: str
    proposals: List[Proposal] = Field(default_factory=list)
    settlement_options: List[str] = Field(default_factory=list)
    final_recommendation: Optional[str] = None


class GuardrailResult(BaseModel):
    citations_ok: bool
    proposals_ok: bool
    mediator_ok: bool = True
    issues: List[str] = Field(default_factory=list)


class RoundResult(BaseModel):
    round_index: int
    party_a: AgentMessage
    party_b: AgentMessage
    mediator: AgentMessage
    guardrails: GuardrailResult
    repaired: bool = False


class NegotiationRequest(BaseModel):
    rounds: int = Field(1, ge=1, le=3)
    contract_text: Optional[str] = None
    clauses: Optional[List["ClauseInput"]] = None
    goal: Optional["NegotiationGoal"] = None
    metadata: Optional[dict[str, Any]] = None


class NegotiationResponse(BaseModel):
    rounds: int
    raw_text: str
    round_results: List[RoundResult]
    clause_history: dict[str, List["ClauseHistoryEntry"]]
    final_summary: str


class NegotiationGoal(BaseModel):
    role: Optional[str] = None
    priorities: List[str] = Field(default_factory=list)
    red_lines: List[str] = Field(default_factory=list)


class ClauseInput(BaseModel):
    id: str
    title: Optional[str] = None
    content: str
    risk_level: Optional[str] = None
    risk_reason: Optional[str] = None
    tags: List[str] = Field(default_factory=list)


class ClauseHistoryEntry(BaseModel):
    round_index: int
    agent: str
    content: str
    proposals: List[Proposal] = Field(default_factory=list)


try:
    NegotiationRequest.model_rebuild()
    NegotiationResponse.model_rebuild()
except AttributeError:  # Pydantic v1
    NegotiationRequest.update_forward_refs()
    NegotiationResponse.update_forward_refs()
