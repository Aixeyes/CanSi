from __future__ import annotations

from typing import Optional, TYPE_CHECKING

from fastapi import APIRouter, Body, HTTPException
from fastapi.responses import JSONResponse

from .schemas import NegotiationRequest
from .service import ContractNegotiationService, normalize_clause_inputs

if TYPE_CHECKING:
    from pipeline import ContractAnalysisPipeline


router = APIRouter(prefix="/contract", tags=["contract"])
service = ContractNegotiationService()
_pipeline: Optional["ContractAnalysisPipeline"] = None


def set_pipeline(pipeline: "ContractAnalysisPipeline") -> None:
    global _pipeline
    _pipeline = pipeline


def _dump_response(result) -> dict:
    if hasattr(result, "model_dump"):
        return result.model_dump()
    return result.dict()


@router.post("/negotiate")
async def negotiate_contract(
    request: NegotiationRequest = Body(...),
) -> JSONResponse:
    if request.rounds < 1 or request.rounds > 3:
        raise HTTPException(status_code=400, detail="rounds must be 1-3")

    if request.contract_text:
        processor = _pipeline.text_processor if _pipeline else None
        result = service.negotiate_text(
            request.contract_text, request.rounds, request.goal, processor
        )
        return JSONResponse(content=_dump_response(result))

    if request.clauses:
        clause_objects, provided_tags = normalize_clause_inputs(request.clauses)
        result = service.negotiate_clauses(
            clause_objects,
            request.rounds,
            request.goal,
            raw_text="",
            provided_tags=provided_tags,
        )
        return JSONResponse(content=_dump_response(result))

    raise HTTPException(
        status_code=400, detail="contract_text or clauses is required"
    )
