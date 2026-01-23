import json
import os
from typing import Optional, Tuple

try:
    from openai import OpenAI
except ImportError as exc:
    raise ImportError(
        "필수 패키지가 없습니다: openai. `pip install openai`로 설치하세요."
    ) from exc

from .models import Clause, RiskType


class RiskAssessor:
    def __init__(self, model: Optional[str] = None) -> None:
        self.model = model or os.getenv("OPENAI_RISK_MODEL") or "gpt-4o"
        self.api_key = os.getenv("OPENAI_API_KEY") or "api필요"
        self._client = OpenAI(api_key=self.api_key) if self.api_key != "api필요" else None

    def assess_clause(self, clause: Clause) -> Tuple[Optional[RiskType], str]:
        if self.api_key == "api필요":
            return "api필요"
        prompt = (
            "You are a legal risk assistant. Assess the risk level of the clause below.\n"
            "Return JSON only: {\"risk\": \"low|medium|high\", \"rationale\": \"...\"}\n"
            "Write the rationale in Korean.\n"
            f"Clause:\n{clause.text}"
        )
        response = self._client.chat.completions.create(
            model=self.model,
            messages=[{"role": "user", "content": prompt}],
        )
        content = response.choices[0].message.content or ""
        try:
            payload = json.loads(content)
            risk_raw = str(payload.get("risk", "")).lower()
            risk = self._map_risk(risk_raw)
            rationale = str(payload.get("rationale", "")).strip()
            return risk, rationale
        except json.JSONDecodeError:
            risk = self._map_risk(content.lower())
            return risk, content.strip()

    def filter_risky_clauses(self, clauses: list[Clause]) -> list[Clause]:
        risky: list[Clause] = []
        for clause in clauses:
            risk, rationale = self.assess_clause(clause)
            clause.risk = risk
            clause.rationale = rationale
            if risk in (RiskType.MEDIUM, RiskType.HIGH):
                risky.append(clause)
        return risky

    def _map_risk(self, value: str) -> Optional[RiskType]:
        if "high" in value:
            return RiskType.HIGH
        if "medium" in value:
            return RiskType.MEDIUM
        if "low" in value:
            return RiskType.LOW
        return None
