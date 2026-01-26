from __future__ import annotations

import re
from typing import List, Tuple

from models import Clause, RiskType
from text_processor import TextProcessor


_RISK_RULES: List[Tuple[RiskType, List[str], str]] = [
    (RiskType.CRITICAL, ["termination", "immediate termination"], "termination risk"),
    (RiskType.HIGH, ["indemnity", "liability", "penalty"], "liability risk"),
    (RiskType.MEDIUM, ["payment", "late fee", "interest"], "payment risk"),
    (RiskType.LOW, ["notice", "governing law", "jurisdiction"], "procedural risk"),
]


def _normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip().lower()


def _tag_risk(clause: Clause) -> Clause:
    content = _normalize(f"{clause.title} {clause.content}")
    for risk_level, keywords, reason in _RISK_RULES:
        for keyword in keywords:
            if keyword in content:
                clause.risk_level = risk_level
                clause.risk_reason = reason
                return clause
    return clause


def _detect_tags(text: str) -> List[str]:
    content = _normalize(text)
    tags: List[str] = []
    if "위약금" in content or "penalty" in content:
        tags.append("penalty")
    if "보증금" in content or "deposit" in content or "반환" in content:
        tags.append("deposit")
    if "원상복구" in content or "restoration" in content:
        tags.append("restoration")
    if "손해배상" in content or "책임" in content or "liability" in content:
        tags.append("liability")
    if "해지" in content or "해제" in content or "termination" in content:
        tags.append("termination")
    return tags


def split_and_tag(raw_text: str) -> List[Clause]:
    processor = TextProcessor()
    clean_text = processor.clean_text(raw_text)
    clauses = processor.split_clauses(clean_text)
    return [_tag_risk(clause) for clause in clauses]


def split_and_tag_with_processor(raw_text: str, processor: TextProcessor) -> List[Clause]:
    clean_text = processor.clean_text(raw_text)
    clauses = processor.split_clauses(clean_text)
    return [_tag_risk(clause) for clause in clauses]


def build_clause_tags(clauses: List[Clause]) -> dict[str, List[str]]:
    return {
        clause.id: _detect_tags(f"{clause.title or ''} {clause.content}")
        for clause in clauses
    }


def ensure_clause_tags(
    clauses: List[Clause], provided_tags: dict[str, List[str]] | None = None
) -> dict[str, List[str]]:
    tags = build_clause_tags(clauses)
    if provided_tags:
        for clause_id, tag_list in provided_tags.items():
            if tag_list:
                tags[clause_id] = list({*tags.get(clause_id, []), *tag_list})
    return tags
