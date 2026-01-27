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
    highlights = []
    for clause in risky_clauses[:3]:
        title = clause.title or clause.article_num
        reason = clause.risk_reason or ""
        highlights.append(f"{title}: {reason}".strip(": "))

    return {
        "contract_type": result.contract_type,
        "summary": {
            "risk_level": _max_risk_level(result.risky_clauses),
            "total_clauses": len(result.clauses),
            "risky_count": len(result.risky_clauses),
            "highlights": highlights,
        },
        "risky_clauses": _serialize(result.risky_clauses),
        "debate": {"transcript": result.debate_transcript},
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
