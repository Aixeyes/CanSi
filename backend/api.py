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

from pydantic import BaseModel, EmailStr
import mysql.connector

from pipeline import ContractAnalysisPipeline
from contract.router import router as contract_router, set_pipeline


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
set_pipeline(pipeline)
app.include_router(contract_router)


# ======================
# Health Check
# ======================
@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


# ======================
# Signup (추가된 부분)
# ======================
class SignupRequest(BaseModel):
    name: str
    email: EmailStr
    password: str


@app.post("/signup")
def signup(req: SignupRequest):
    conn = mysql.connector.connect(
        host=os.getenv("DB_HOST", "db"),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", "root123"),
        database=os.getenv("DB_NAME", "app_db"),
    )
    cur = conn.cursor()

    # 이메일 중복 체크
    cur.execute("SELECT id FROM users WHERE email = %s", (req.email,))
    if cur.fetchone():
        cur.close()
        conn.close()
        raise HTTPException(status_code=400, detail="Email already exists")

    # 유저 생성
    cur.execute(
        "INSERT INTO users (name, email, password) VALUES (%s, %s, %s)",
        (req.name, req.email, req.password),
    )
    conn.commit()

    cur.close()
    conn.close()
    return {"result": "ok"}


# ======================
# Analyze File
# ======================
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

