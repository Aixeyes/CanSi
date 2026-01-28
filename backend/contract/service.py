from __future__ import annotations

import os
import tempfile
from typing import List, Optional

from models import Clause, RiskType
from ocr import UpstageOCR, get_extracted_text

from .agents import run_mediator_agent, run_party_agent
from .clause_utils import (
    ensure_clause_tags,
    split_and_tag,
    split_and_tag_with_processor,
)
from .guardrails import run_guardrails
from .schemas import (
    AgentMessage,
    ClauseInput,
    ClauseHistoryEntry,
    NegotiationGoal,
    NegotiationResponse,
    RoundResult,
)


class ContractNegotiationService:
    def __init__(self) -> None:
        self.ocr = UpstageOCR()

    def negotiate_text(
        self,
        raw_text: str,
        rounds: int,
        goal: Optional[NegotiationGoal] = None,
        processor: Optional[object] = None,
    ) -> NegotiationResponse:
        if processor is not None:
            clauses = split_and_tag_with_processor(raw_text, processor)
        else:
            clauses = split_and_tag(raw_text)
        clause_tags = ensure_clause_tags(clauses)
        return self._negotiate(raw_text, clauses, clause_tags, rounds, goal)

    def negotiate_file(
        self, file_path: str, rounds: int, goal: Optional[NegotiationGoal] = None
    ) -> NegotiationResponse:
        ocr_result = self.ocr.extract_text_from_file(file_path)
        raw_text = get_extracted_text(ocr_result)
        clauses = split_and_tag(raw_text)
        clause_tags = ensure_clause_tags(clauses)
        return self._negotiate(raw_text, clauses, clause_tags, rounds, goal)

    def negotiate_clauses(
        self,
        clauses: List[Clause],
        rounds: int,
        goal: Optional[NegotiationGoal] = None,
        raw_text: str = "",
        provided_tags: Optional[dict[str, List[str]]] = None,
    ) -> NegotiationResponse:
        clause_tags = ensure_clause_tags(clauses, provided_tags)
        return self._negotiate(raw_text, clauses, clause_tags, rounds, goal)

    def _negotiate(
        self,
        raw_text: str,
        clauses: List[Clause],
        clause_tags: dict[str, List[str]],
        rounds: int,
        goal: Optional[NegotiationGoal],
    ) -> NegotiationResponse:
        clause_map = {clause.id: clause.content for clause in clauses}
        history: List[AgentMessage] = []
        round_results: List[RoundResult] = []
        clause_history: dict[str, List[ClauseHistoryEntry]] = {}

        for round_index in range(1, rounds + 1):
            party_a = run_party_agent(
                "gap_counsel", clause_map, clause_tags, history, goal
            )
            history.append(party_a)

            party_b = run_party_agent(
                "eul_counsel", clause_map, clause_tags, history, goal
            )
            history.append(party_b)

            mediator = run_mediator_agent(clause_map, clause_tags, history, goal)
            history.append(mediator)

            guardrails, repaired, party_a, party_b, mediator = run_guardrails(
                party_a, party_b, mediator, clause_map, clause_tags
            )

            round_results.append(
                RoundResult(
                    round_index=round_index,
                    party_a=party_a,
                    party_b=party_b,
                    mediator=mediator,
                    guardrails=guardrails,
                    repaired=repaired,
                )
            )

            for agent_message in (party_a, party_b, mediator):
                for proposal in agent_message.proposals:
                    entry = ClauseHistoryEntry(
                        round_index=round_index,
                        agent=agent_message.agent,
                        content=agent_message.content,
                        proposals=[proposal],
                    )
                    clause_history.setdefault(proposal.clause_id, []).append(entry)

        final_summary = "Negotiation completed."
        return NegotiationResponse(
            rounds=rounds,
            raw_text=raw_text,
            round_results=round_results,
            clause_history=clause_history,
            final_summary=final_summary,
        )


def negotiate_from_upload(file_bytes: bytes, suffix: str, rounds: int) -> NegotiationResponse:
    temp_path = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            temp_path = tmp.name
            tmp.write(file_bytes)
        service = ContractNegotiationService()
        return service.negotiate_file(temp_path, rounds)
    finally:
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except OSError:
                pass


def normalize_clause_inputs(
    clauses: List[ClauseInput],
) -> tuple[List[Clause], dict[str, List[str]]]:
    clause_objects: List[Clause] = []
    tags: dict[str, List[str]] = {}
    for item in clauses:
        risk_level = None
        if item.risk_level:
            try:
                risk_level = RiskType(item.risk_level)
            except ValueError:
                risk_level = None
        clause_objects.append(
            Clause(
                id=item.id,
                article_num=item.title or "",
                title=item.title or "",
                content=item.content,
                risk_level=risk_level,
                risk_reason=item.risk_reason,
            )
        )
        if item.tags:
            tags[item.id] = item.tags
    return clause_objects, tags
