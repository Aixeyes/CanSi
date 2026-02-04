"""
FastAPI entrypoint for the contract analysis pipeline.
"""

from __future__ import annotations

import os
import tempfile
from dataclasses import asdict, is_dataclass
from enum import Enum
from typing import Any, Optional

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.responses import JSONResponse

from pipeline import ContractAnalysisPipeline


def _serialize(obj: Any) -> Any:
    if is_dataclass(obj):
        return _serialize(asdict(obj))
    if isinstance(obj, Enum):
        return obj.value
    if isinstance(obj, list):
        return [_serialize(item) for item in obj]
    if isinstance(obj, dict):
        return {key: _serialize(value) for key, value in obj.items()}
    return obj


def _build_pipeline() -> ContractAnalysisPipeline:
    return ContractAnalysisPipeline()

def _clean_raw_text(text: str) -> str:
    """Remove OCR replacement characters that render as '??' in some fonts."""
    if not text:
        return text
    return text.replace("\uFFFD", "")

def _clean_raw_html(html: str) -> str:
    """Remove OCR replacement characters from HTML payload."""
    if not html:
        return html
    return html.replace("\uFFFD", "")

def _normalize_with_map(text: str) -> tuple[str, list[int]]:
    """Normalize text for matching while tracking original indices."""
    normalized = []
    index_map = []
    last_was_space = False
    for i, ch in enumerate(text):
        if ch.isspace():
            if not last_was_space:
                normalized.append(" ")
                index_map.append(i)
                last_was_space = True
            continue
        normalized.append(ch.lower())
        index_map.append(i)
        last_was_space = False
    return "".join(normalized), index_map

def _find_spans(haystack: str, needle: str) -> list[tuple[int, int]]:
    spans = []
    start = 0
    while True:
        idx = haystack.find(needle, start)
        if idx == -1:
            break
        spans.append((idx, idx + len(needle)))
        start = idx + len(needle)
    return spans

def _build_highlights(raw_text: str, clauses: list) -> list[dict]:
    if not raw_text or not clauses:
        return []
    normalized_text, index_map = _normalize_with_map(raw_text)
    highlights = []
    seen = set()
    for clause in clauses:
        targets = clause.highlight_sentences or [clause.content]
        for target in targets:
            if not target:
                continue
            normalized_target, _ = _normalize_with_map(target)
            normalized_target = normalized_target.strip()
            if not normalized_target:
                continue
            for start, end in _find_spans(normalized_text, normalized_target):
                if end <= 0:
                    continue
                orig_start = index_map[start]
                orig_end = index_map[end - 1] + 1
                key = (orig_start, orig_end)
                if key in seen:
                    continue
                seen.add(key)
                highlights.append(
                    {
                        "start": orig_start,
                        "end": orig_end,
                        "risk_level": clause.risk_level.value if clause.risk_level else None,
                        "clause_id": clause.id,
                        "article_num": clause.article_num,
                        "title": clause.title,
                    }
                )
    highlights.sort(key=lambda item: item["start"])
    return highlights

def _max_risk_level(clauses: list) -> Optional[str]:
    order = {"low": 1, "medium": 2, "high": 3, "critical": 4}
    highest = None
    highest_score = 0
    for clause in clauses:
        level = getattr(clause, "risk_level", None)
        value = level.value if level else None
        score = order.get(value or "", 0)
        if score > highest_score:
            highest_score = score
            highest = value
    return highest


def _format_result_for_app(result: Any) -> dict:
    risky_clauses = result.risky_clauses or []
    raw_text = _clean_raw_text(result.raw_text)
    raw_html = _clean_raw_html(getattr(result, "raw_html", None))
    highlights = []
    for clause in risky_clauses[:3]:
        title = clause.title or clause.article_num
        reason = clause.risk_reason or ""
        highlights.append(f"{title}: {reason}".strip(": "))

    return {
        "contract_type": result.contract_type,
        "raw_text": raw_text,
        "raw_html": raw_html,
        "text_highlights": _build_highlights(raw_text, risky_clauses),
        "summary": {
            "risk_level": _max_risk_level(result.risky_clauses),
            "total_clauses": len(result.clauses),
            "risky_count": len(result.risky_clauses),
            "highlights": highlights,
        },
        "risky_clauses": _serialize(result.risky_clauses),
        "laws": _serialize(getattr(result, "laws", [])),
        "debate": {
            "transcript": result.debate_transcript,
            "by_clause": _serialize(getattr(result, "debate_by_clause", None)),
        },
        "report": result.llm_summary,
    }


app = FastAPI(title="CanSi API", version="0.1.0")
pipeline = _build_pipeline()


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/analyze/file")
async def analyze_file(file: UploadFile = File(...)) -> JSONResponse:
    if not file.filename:
        raise HTTPException(status_code=400, detail="File name is required.")

    suffix = os.path.splitext(file.filename)[1] or ".dat"
    temp_path = None

    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            temp_path = tmp.name
            contents = await file.read()
            tmp.write(contents)

        result = pipeline.analyze(temp_path)
        return JSONResponse(content=_format_result_for_app(result))
    finally:
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except OSError:
                pass
