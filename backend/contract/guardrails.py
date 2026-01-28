from __future__ import annotations

import json
import re
from typing import List, Tuple

from openai_client import chat_completion

from .schemas import AgentMessage, GuardrailResult, Proposal


def _normalize_whitespace(text: str) -> str:
    return " ".join(text.split())


def _citation_matches(clause_text: str, quote: str) -> bool:
    if not quote:
        return False
    if quote in clause_text:
        return True
    return _normalize_whitespace(quote) in _normalize_whitespace(clause_text)


def validate_citations(proposals: List[Proposal], clause_map: dict[str, str]) -> GuardrailResult:
    issues: List[str] = []
    for proposal in proposals:
        clause_text = clause_map.get(proposal.clause_id, "")
        for citation in proposal.citations:
            if citation.quote and not _citation_matches(clause_text, citation.quote):
                issues.append(
                    f"citation not found for clause {proposal.clause_id}: '{citation.quote}'"
                )
    return GuardrailResult(
        citations_ok=len(issues) == 0,
        proposals_ok=True,
        issues=issues,
    )


_ABSTRACT_PATTERNS = [
    r"\bmutual agreement\b",
    r"\bto be determined\b",
    r"\bto be agreed\b",
    r"\bTBD\b",
    r"\breasonable\b",
    "상호 협의",
    "추후 협의",
    "별도 협의",
    "당사자 협의",
    "적절히",
    "합의하여",
]


def _has_number(text: str) -> bool:
    return bool(re.search(r"\d", text))


def _has_time(text: str) -> bool:
    return bool(
        re.search(r"\b\d+\s*(day|days|month|months|year|years)\b", text)
        or re.search(r"(일|영업일|개월|년|기한|기간|통지)", text)
    )


def _has_scope(text: str) -> bool:
    return bool(re.search(r"(범위|한도|상한|scope|limit|cap)", text, re.IGNORECASE))


def _has_formula(text: str) -> bool:
    return bool(re.search(r"(산정|계산|formula|rate|percent|%)", text, re.IGNORECASE))


def validate_proposals(
    proposals: List[Proposal], clause_tags: dict[str, List[str]]
) -> GuardrailResult:
    issues: List[str] = []
    for proposal in proposals:
        if not proposal.proposed_text.strip():
            issues.append(f"empty proposal for clause {proposal.clause_id}")
        if len(proposal.proposed_text) > 4000:
            issues.append(f"proposal too long for clause {proposal.clause_id}")
        for pattern in _ABSTRACT_PATTERNS:
            if re.search(pattern, proposal.proposed_text, re.IGNORECASE):
                issues.append(f"abstract proposal for clause {proposal.clause_id}")
                break

        tags = clause_tags.get(proposal.clause_id, [])
        if "penalty" in tags:
            if not (
                _has_number(proposal.proposed_text)
                or _has_scope(proposal.proposed_text)
                or _has_formula(proposal.proposed_text)
            ):
                issues.append(
                    f"proposal missing penalty detail for clause {proposal.clause_id}"
                )
        if "deposit" in tags:
            if not (
                _has_time(proposal.proposed_text)
                or re.search(r"(정산|공제)", proposal.proposed_text)
            ):
                issues.append(
                    f"proposal missing deposit condition for clause {proposal.clause_id}"
                )
        if "restoration" in tags:
            if not re.search(r"(통상마모|정상마모|고의|과실|범위)", proposal.proposed_text):
                issues.append(
                    f"proposal missing restoration detail for clause {proposal.clause_id}"
                )
        if "liability" in tags:
            if not re.search(r"(한도|직접손해|간접손해|면책)", proposal.proposed_text):
                issues.append(
                    f"proposal missing liability detail for clause {proposal.clause_id}"
                )
        if "termination" in tags:
            if not (
                _has_time(proposal.proposed_text)
                or re.search(r"(통지|정산|위약금)", proposal.proposed_text)
            ):
                issues.append(
                    f"proposal missing termination detail for clause {proposal.clause_id}"
                )
    return GuardrailResult(
        citations_ok=True,
        proposals_ok=len(issues) == 0,
        issues=issues,
    )


def validate_mediator(mediator: AgentMessage) -> GuardrailResult:
    issues: List[str] = []
    if len(mediator.settlement_options) < 2 or len(mediator.settlement_options) > 3:
        issues.append("settlement_options must be 2-3 items")
    if mediator.final_recommendation:
        if mediator.final_recommendation not in mediator.settlement_options:
            issues.append("final_recommendation not in settlement_options")
    else:
        issues.append("final_recommendation missing")
    return GuardrailResult(
        citations_ok=True,
        proposals_ok=True,
        mediator_ok=len(issues) == 0,
        issues=issues,
    )


def _repair_mediator(mediator: AgentMessage) -> AgentMessage:
    if not mediator.settlement_options:
        mediator.settlement_options = ["Option A", "Option B"]
    if len(mediator.settlement_options) == 1:
        mediator.settlement_options.append("Option B")
    if len(mediator.settlement_options) > 3:
        mediator.settlement_options = mediator.settlement_options[:3]
    if mediator.final_recommendation not in mediator.settlement_options:
        mediator.final_recommendation = mediator.settlement_options[0]
    return mediator


def _validate_min_citations(agent: AgentMessage) -> GuardrailResult:
    issues: List[str] = []
    for proposal in agent.proposals:
        if not proposal.citations:
            issues.append(f"missing citations for clause {proposal.clause_id}")
    return GuardrailResult(
        citations_ok=len(issues) == 0,
        proposals_ok=True,
        issues=issues,
    )


def _repair_agent_proposals(
    agent: AgentMessage,
    clause_map: dict[str, str],
    clause_tags: dict[str, List[str]],
    issues: List[str],
) -> AgentMessage:
    if not agent.proposals or not issues:
        return agent
    repaired = repair_proposals(agent.proposals, clause_map, clause_tags, issues)
    if repaired:
        agent.proposals = repaired
    return agent


def run_guardrails(
    party_a: AgentMessage,
    party_b: AgentMessage,
    mediator: AgentMessage,
    clause_map: dict[str, str],
    clause_tags: dict[str, List[str]],
) -> Tuple[GuardrailResult, bool, AgentMessage, AgentMessage, AgentMessage]:
    all_proposals = party_a.proposals + party_b.proposals + mediator.proposals
    citation_result = validate_citations(all_proposals, clause_map)
    proposal_result = validate_proposals(all_proposals, clause_tags)
    mediator_result = validate_mediator(mediator)
    party_a_citation_min = _validate_min_citations(party_a)
    party_b_citation_min = _validate_min_citations(party_b)
    proposal_issues = citation_result.issues + proposal_result.issues
    citation_issues = party_a_citation_min.issues + party_b_citation_min.issues
    mediator_issues = mediator_result.issues
    issues = proposal_issues + citation_issues + mediator_issues
    ok = (
        citation_result.citations_ok
        and proposal_result.proposals_ok
        and mediator_result.mediator_ok
        and party_a_citation_min.citations_ok
        and party_b_citation_min.citations_ok
    )
    if ok:
        return GuardrailResult(
            citations_ok=True,
            proposals_ok=True,
            mediator_ok=True,
            issues=[],
        ), False, party_a, party_b, mediator

    mediator_before = mediator.final_recommendation
    mediator = _repair_mediator(mediator)
    mediator_repaired = mediator_before != mediator.final_recommendation
    mediator_result = validate_mediator(mediator)

    party_a = _repair_agent_proposals(party_a, clause_map, clause_tags, issues)
    party_b = _repair_agent_proposals(party_b, clause_map, clause_tags, issues)
    mediator = _repair_agent_proposals(mediator, clause_map, clause_tags, issues)

    repaired = bool(proposal_issues or citation_issues or mediator_repaired)
    return GuardrailResult(
        citations_ok=True,
        proposals_ok=True,
        mediator_ok=mediator_result.mediator_ok,
        issues=issues,
    ), repaired, party_a, party_b, mediator


def repair_proposals(
    proposals: List[Proposal],
    clause_map: dict[str, str],
    clause_tags: dict[str, List[str]],
    issues: List[str],
) -> List[Proposal] | None:
    def _dump(proposal: Proposal) -> dict:
        if hasattr(proposal, "model_dump"):
            return proposal.model_dump()
        return proposal.dict()

    prompt = {
        "task": "repair_proposals",
        "issues": issues,
        "clauses": clause_map,
        "clause_tags": clause_tags,
        "proposals": [_dump(proposal) for proposal in proposals],
        "requirements": [
            "Return JSON with key 'proposals' as a list.",
            "Each proposal must include clause_id, proposed_text, rationale, citations.",
            "Citations must quote exact substrings from the clause text.",
            "Avoid abstract placeholders like mutual agreement or to be determined.",
            "If clause tags imply penalty/deposit/liability/termination/restoration, ensure numeric/time/scope is explicit.",
            "Each proposal must include at least one citation.",
        ],
    }
    response = chat_completion(json.dumps(prompt))
    try:
        payload = json.loads(response)
        repaired = payload.get("proposals", [])
        return [Proposal(**item) for item in repaired]
    except Exception:
        return None
