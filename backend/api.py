"""
FastAPI entrypoint for the contract analysis pipeline.
"""

from __future__ import annotations

import os
import tempfile
from dataclasses import asdict, is_dataclass
from enum import Enum
from typing import Any

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.responses import JSONResponse

from pipeline import ContractAnalysisPipeline


class NoOpLLMClient:
    """Fallback LLM client when OPENAI_API_KEY is missing."""

    def generate(self, prompt: str, system_prompt: str | None = None) -> str:
        return "LLM disabled (missing OPENAI_API_KEY)"


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
    if os.getenv("OPENAI_API_KEY"):
        return ContractAnalysisPipeline()
    return ContractAnalysisPipeline(llm_client=NoOpLLMClient())


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
        return JSONResponse(content=_serialize(result))
    finally:
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except OSError:
                pass
