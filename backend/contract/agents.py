from __future__ import annotations

import json
from typing import List, Optional

from openai_client import chat_completion

from .schemas import AgentMessage, NegotiationGoal, Proposal


_BASE_INSTRUCTIONS = [
    "You are an expert contract negotiator.",
    "Return JSON only with keys: agent, content, proposals.",
    "Each proposal must include clause_id, proposed_text, rationale, citations.",
    "Citations must quote exact substrings from the clause text.",
    "Do not use abstract placeholders like mutual agreement or to be determined.",
    "Each proposal must include at least one citation.",
]


def _dump_message(message: AgentMessage) -> dict:
    if hasattr(message, "model_dump"):
        return message.model_dump()
    return message.dict()


def _dump_goal(goal: Optional[NegotiationGoal]) -> Optional[dict]:
    if goal is None:
        return None
    if hasattr(goal, "model_dump"):
        return goal.model_dump()
    return goal.dict()


def _build_prompt(
    role: str,
    clauses: dict[str, str],
    tags: dict[str, List[str]],
    history: List[AgentMessage],
    goal: Optional[NegotiationGoal],
) -> str:
    return json.dumps(
        {
            "role": role,
            "instructions": _BASE_INSTRUCTIONS,
            "clauses": clauses,
            "clause_tags": tags,
            "goal": _dump_goal(goal),
            "history": [_dump_message(message) for message in history],
            "mediator_requirements": {
                "required": role == "mediator",
                "settlement_options": "Provide 2-3 options, each a full sentence.",
                "final_recommendation": "Must exactly match one of settlement_options.",
            },
        }
    )


def _parse_agent_message(role: str, response: str) -> AgentMessage:
    try:
        payload = json.loads(response)
        proposals = [Proposal(**item) for item in payload.get("proposals", [])]
        return AgentMessage(
            agent=payload.get("agent", role),
            content=payload.get("content", ""),
            proposals=proposals,
            settlement_options=payload.get("settlement_options", []) or [],
            final_recommendation=payload.get("final_recommendation"),
        )
    except Exception:
        return AgentMessage(agent=role, content=response, proposals=[])


def run_party_agent(
    role: str,
    clauses: dict[str, str],
    tags: dict[str, List[str]],
    history: List[AgentMessage],
    goal: Optional[NegotiationGoal],
) -> AgentMessage:
    prompt = _build_prompt(role, clauses, tags, history, goal)
    response = chat_completion(prompt)
    return _parse_agent_message(role, response)


def run_mediator_agent(
    clauses: dict[str, str],
    tags: dict[str, List[str]],
    history: List[AgentMessage],
    goal: Optional[NegotiationGoal],
) -> AgentMessage:
    prompt = _build_prompt("mediator", clauses, tags, history, goal)
    response = chat_completion(prompt)
    return _parse_agent_message("mediator", response)
