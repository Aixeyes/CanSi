import os
import tempfile
from dataclasses import asdict, is_dataclass
from datetime import datetime
from enum import Enum
from typing import Any, Optional
from uuid import uuid4
from threading import Lock

import mysql.connector
from fastapi import FastAPI, File, HTTPException, Query, UploadFile
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, EmailStr
from pipeline import ContractAnalysisPipeline
app = FastAPI()
pipeline = ContractAnalysisPipeline()
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
STATIC_DIR = os.path.join(BASE_DIR, "static")
if os.path.isdir(STATIC_DIR):
    app.mount("/ui", StaticFiles(directory=STATIC_DIR, html=True), name="ui")

ANALYSIS_STORE: dict[str, dict[str, Any]] = {}
ANALYSIS_LOCK = Lock()
ANALYSIS_TTL_SECONDS = int(os.getenv("ANALYSIS_TTL_SECONDS", "3600"))
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


def _normalize_reason(reason: Any) -> str:
    if reason is None:
        return ""
    if isinstance(reason, str):
        text = reason.strip()
        if not text:
            return ""
        if text.startswith("```"):
            stripped = text.strip("`").strip()
            if stripped.lower().startswith("json"):
                stripped = stripped[4:].strip()
            text = stripped
        if text[0] in ("{", "["):
            try:
                import json

                parsed = json.loads(text)
                if isinstance(parsed, dict):
                    if "rationale" in parsed:
                        return str(parsed.get("rationale") or "").strip()
                    if "reason" in parsed:
                        return str(parsed.get("reason") or "").strip()
                    return json.dumps(parsed, ensure_ascii=False)
                if isinstance(parsed, list):
                    return "\n".join([str(item).strip() for item in parsed if str(item).strip()])
            except Exception:
                return text
        return text
    if isinstance(reason, (dict, list)):
        try:
            import json

            if isinstance(reason, dict):
                if "rationale" in reason:
                    return str(reason.get("rationale") or "").strip()
                if "reason" in reason:
                    return str(reason.get("reason") or "").strip()
            return json.dumps(reason, ensure_ascii=False)
        except Exception:
            return str(reason)
    return str(reason)


def _parse_json_object(text: str) -> dict:
    if not text:
        return {}
    cleaned = text.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.strip("`").strip()
        if cleaned.lower().startswith("json"):
            cleaned = cleaned[4:].strip()
    try:
        parsed = json.loads(cleaned)
        return parsed if isinstance(parsed, dict) else {}
    except Exception:
        pass
    try:
        start = cleaned.find("{")
        end = cleaned.rfind("}")
        if start >= 0 and end > start:
            snippet = cleaned[start : end + 1]
            parsed = json.loads(snippet)
            return parsed if isinstance(parsed, dict) else {}
    except Exception:
        return {}
    return {}


def _split_points_from_text(text: str) -> tuple[list[str], list[str]]:
    if not text:
        return ([], [])
    separators = ["\n", ".", "。", "!", "?", "·"]
    chunks = [text]
    for sep in separators:
        next_chunks = []
        for chunk in chunks:
            next_chunks.extend(chunk.split(sep))
        chunks = next_chunks
    sentences = [s.strip() for s in chunks if s.strip()]
    common = []
    coordination = []
    common_markers = ("공통", "양측", "합의", "일치", "공감", "같이", "공동")
    for sentence in sentences:
        if any(marker in sentence for marker in common_markers):
            common.append(sentence)
        else:
            coordination.append(sentence)
    return (coordination, common)
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
def _format_result_for_app(result: Any, analysis_id: str) -> dict:
    risky_clauses = result.risky_clauses or []
    article_to_clause_id = {}
    clause_id_to_reason = {}
    for clause in risky_clauses:
        article_num = getattr(clause, "article_num", None)
        clause_id = getattr(clause, "id", None)
        if article_num and clause_id and article_num not in article_to_clause_id:
            article_to_clause_id[article_num] = clause_id
        if clause_id and clause_id not in clause_id_to_reason:
            raw_reason = _serialize(getattr(clause, "risk_reason", None))
            clause_id_to_reason[clause_id] = _normalize_reason(raw_reason)

    return {
        "analysis_id": analysis_id,
        "raw_text": _serialize(result.raw_text),
        "risky_clauses": _serialize(risky_clauses),
        "risky_article_nums": list(article_to_clause_id.keys()),
        "article_to_clause_id": article_to_clause_id,
        "clause_id_to_reason": clause_id_to_reason,
    }

def _prune_store():
    if ANALYSIS_TTL_SECONDS <= 0:
        return
    cutoff = datetime.utcnow().timestamp() - ANALYSIS_TTL_SECONDS
    stale_ids = []
    for analysis_id, entry in ANALYSIS_STORE.items():
        created_at = entry.get("created_at")
        if created_at and created_at.timestamp() < cutoff:
            stale_ids.append(analysis_id)
    for analysis_id in stale_ids:
        ANALYSIS_STORE.pop(analysis_id, None)

def _store_result(result: Any) -> str:
    analysis_id = uuid4().hex
    with ANALYSIS_LOCK:
        _prune_store()
        ANALYSIS_STORE[analysis_id] = {
            "result": result,
            "created_at": datetime.utcnow(),
            "debate_by_clause": {},
            "debate_summary": {},
        }
    return analysis_id

def _get_entry(analysis_id: str) -> dict[str, Any]:
    with ANALYSIS_LOCK:
        _prune_store()
        entry = ANALYSIS_STORE.get(analysis_id)
    if not entry:
        raise HTTPException(status_code=404, detail="Analysis not found")
    return entry

def _find_clause(result: Any, clause_id: str):
    for clause in result.risky_clauses or []:
        if clause.id == clause_id:
            return clause
    for clause in result.clauses or []:
        if clause.id == clause_id:
            return clause
    return None
@app.get("/")
def read_root():
    return {"message": "Hello from FastAPI + Docker!"}
@app.get("/health")
def health():
    return {"status": "ok"}

def _format_transcript_text(transcript: list[dict]) -> str:
    if not transcript:
        return ""
    lines = []
    for turn in transcript:
        speaker = turn.get("speaker", "")
        content = turn.get("content", "")
        lines.append(f"{speaker}: {content}".strip())
    return "\n".join(lines)
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
        result = pipeline.analyze(temp_path, run_debate=False)
        analysis_id = _store_result(result)
        return JSONResponse(content=_format_result_for_app(result, analysis_id))
    finally:
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except OSError:
                pass

@app.get("/analysis/{analysis_id}/clauses/{clause_id}/debate/summary")
def get_clause_debate_summary(analysis_id: str, clause_id: str) -> JSONResponse:
    entry = _get_entry(analysis_id)
    result = entry["result"]
    clause = _find_clause(result, clause_id)
    if not clause:
        raise HTTPException(status_code=404, detail="Clause not found")
    summary_cache = entry["debate_summary"]
    if clause_id in summary_cache:
        return JSONResponse(
            content={
                "clause_id": clause_id,
                "article_num": clause.article_num,
                "title": clause.title,
                "summary": summary_cache[clause_id],
            }
        )
    transcript_cache = entry["debate_by_clause"]
    transcript = transcript_cache.get(clause_id)
    if transcript is None:
        transcript = pipeline.debate_agents.run(
            [clause],
            raw_text=result.raw_text,
            contract_type=result.contract_type,
        )
        transcript_cache[clause_id] = transcript
    judge_reply = None
    landlord_reply = None
    tenant_reply = None
    for turn in reversed(transcript):
        speaker = turn.get("speaker")
        if not landlord_reply and speaker == "임대인 변호사":
            landlord_reply = turn.get("content")
        if not tenant_reply and speaker == "임차인 변호사":
            tenant_reply = turn.get("content")
        if not judge_reply and speaker == "판사":
            judge_reply = turn.get("content")
        if judge_reply and landlord_reply and tenant_reply:
            break

    summary: dict[str, Any] = {}
    if judge_reply:
        try:
            summary = _parse_json_object(judge_reply)
        except Exception:
            summary = {}
    if not summary:
        # Fallback to a plain summary if judge output is missing or invalid.
        transcript_text = _format_transcript_text(transcript)
        summary = {"neutral_summary": pipeline.llm_summarizer.generate_debate_summary(transcript_text)}
    if "common_points" not in summary and "common" in summary:
        summary["common_points"] = summary.get("common") or []
    if "coordination_points" not in summary:
        summary["coordination_points"] = []

    common_points = summary.get("common_points") or []
    coordination_points = summary.get("coordination_points") or []
    if isinstance(common_points, str):
        common_points = [common_points]
    if isinstance(coordination_points, str):
        coordination_points = [coordination_points]
    if not common_points:
        source_text = ""
        if coordination_points:
            source_text = "\n".join([str(item) for item in coordination_points])
        elif summary.get("neutral_summary"):
            source_text = str(summary.get("neutral_summary") or "")
        if source_text:
            coordination_points, common_points = _split_points_from_text(source_text)
    summary["common_points"] = common_points
    summary["coordination_points"] = coordination_points
    if "perspective_points" not in summary:
        summary["perspective_points"] = {
            "landlord": [landlord_reply] if landlord_reply else [],
            "tenant": [tenant_reply] if tenant_reply else [],
        }
    summary_cache[clause_id] = summary
    return JSONResponse(
        content={
            "clause_id": clause_id,
            "article_num": clause.article_num,
            "title": clause.title,
            "summary": summary,
            "perspective_points": summary.get("perspective_points", {}),
            "common_points": summary.get("common_points", []),
            "coordination_points": summary.get("coordination_points", []),
        }
    )

@app.get("/analysis/{analysis_id}/clauses/{clause_id}/debate/transcript")
def get_clause_debate_transcript(analysis_id: str, clause_id: str) -> JSONResponse:
    entry = _get_entry(analysis_id)
    result = entry["result"]
    clause = _find_clause(result, clause_id)
    if not clause:
        raise HTTPException(status_code=404, detail="Clause not found")
    transcript_cache = entry["debate_by_clause"]
    transcript = transcript_cache.get(clause_id)
    if transcript is None:
        transcript = pipeline.debate_agents.run(
            [clause],
            raw_text=result.raw_text,
            contract_type=result.contract_type,
        )
        transcript_cache[clause_id] = transcript
    return JSONResponse(
        content={
            "clause_id": clause_id,
            "article_num": clause.article_num,
            "title": clause.title,
            "transcript": transcript,
        }
    )
class SignupRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
class UpdateProfileRequest(BaseModel):
    email: EmailStr
    name: Optional[str] = None
    password: Optional[str] = None
class ProfileResponse(BaseModel):
    id: int
    name: str
    email: EmailStr
    created_at: datetime
@app.post("/signup")
def signup(req: SignupRequest):
    conn = None
    cur = None
    try:
        conn = mysql.connector.connect(
            host=os.getenv("DB_HOST", "db"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=os.getenv("DB_USER", "app_user"),
            password=os.getenv("DB_PASSWORD", "app_pass"),
            database=os.getenv("DB_NAME", "app_db"),
        )
        cur = conn.cursor()
        cur.execute("SELECT id FROM users WHERE email=%s", (req.email,))
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Email already exists")
        cur.execute(
            "INSERT INTO users (name, email, password_hash) VALUES (%s, %s, %s)",
            (req.name, req.email, req.password),
        )
        conn.commit()
        return {"result": "ok"}
    except Exception as e:
        # 🔥 이 줄이 핵심
        print("SIGNUP ERROR >>>", repr(e))
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        try:
            if cur is not None:
                cur.close()
            if conn is not None:
                conn.close()
        except Exception:
            pass
@app.get("/profile", response_model=ProfileResponse)
def get_profile(email: EmailStr = Query(...)):
    conn = None
    cur = None
    try:
        conn = mysql.connector.connect(
            host=os.getenv("DB_HOST", "db"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=os.getenv("DB_USER", "app_user"),
            password=os.getenv("DB_PASSWORD", "app_pass"),
            database=os.getenv("DB_NAME", "app_db"),
        )
        cur = conn.cursor(dictionary=True)
        cur.execute(
            "SELECT id, name, email, created_at FROM users WHERE email=%s",
            (str(email),),
        )
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="User not found")
        return row
    except HTTPException:
        raise
    except Exception as e:
        print("PROFILE ERROR >>>", repr(e))
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        try:
            if cur is not None:
                cur.close()
            if conn is not None:
                conn.close()
        except Exception:
            pass
@app.put("/profile", response_model=ProfileResponse)
def update_profile(req: UpdateProfileRequest):
    if not req.name and not req.password:
        raise HTTPException(status_code=400, detail="Nothing to update")
    conn = None
    cur = None
    try:
        conn = mysql.connector.connect(
            host=os.getenv("DB_HOST", "db"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=os.getenv("DB_USER", "app_user"),
            password=os.getenv("DB_PASSWORD", "app_pass"),
            database=os.getenv("DB_NAME", "app_db"),
        )
        cur = conn.cursor(dictionary=True)
        updates = []
        params = []
        if req.name:
            updates.append("name=%s")
            params.append(req.name)
        if req.password:
            updates.append("password_hash=%s")
            params.append(req.password)
        params.append(str(req.email))
        cur.execute(
            f"UPDATE users SET {', '.join(updates)} WHERE email=%s",
            tuple(params),
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="User not found")
        conn.commit()
        cur.execute(
            "SELECT id, name, email, created_at FROM users WHERE email=%s",
            (str(req.email),),
        )
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="User not found")
        return row
    except HTTPException:
        raise
    except Exception as e:
        print("PROFILE UPDATE ERROR >>>", repr(e))
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        try:
            if cur is not None:
                cur.close()
            if conn is not None:
                conn.close()
        except Exception:
            pass
