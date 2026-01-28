"""
계약서 위험 조항에 대한 변호사/검사 페르소나 토론 에이전트.
"""

import os
from typing import Dict, List, Optional

from models import Clause
from openai_client import chat_completion


# 임대인 측 변호사 시스템 프롬프트 (부동산 계약서 검토용)
LANDLORD_LAWYER_SYSTEM_PROMPT = (
    "You are a lawyer representing the landlord in a real estate contract review. "  # 임대인 대리 변호사 역할
    "Reduce clauses that excessively increase the landlord's liability or costs, "  # 임대인 책임/비용 과도 조항 축소
    "and propose landlord-favorable revisions. "  # 임대인에게 유리한 수정안 제시
    "Call out core risks such as deposit return conditions, defect liability scope, "  # 보증금 반환, 하자 책임 범위 등 핵심 리스크
    "restoration obligations, late payment/termination, damage caps, and toxic clauses. "  # 원상복구, 연체/해지, 손해배상 한도, 독소조항
    "Respond in Korean."  # 한국어로 응답
)

# 임차인 측 변호사 시스템 프롬프트 (부동산 계약서 검토용)
TENANT_LAWYER_SYSTEM_PROMPT = (
    "You are a lawyer representing the tenant in a real estate contract review. "  # 임차인 대리 변호사 역할
    "Reduce clauses that are unfair or risky for the tenant, "  # 임차인에게 불리/위험한 조항 축소
    "and propose revisions needed for tenant protection. "  # 임차인 보호에 필요한 수정안 제시
    "Call out core risks such as deposit protection, repair duties, landlord notice/termination "  # 보증금 보호, 하자 수리, 통지/해지 요건
    "requirements, brokerage liability, dispute resolution, and toxic clauses. "  # 중개책임, 분쟁해결, 독소조항
    "Respond in Korean."  # 한국어로 응답
)


class DebateAgents:
    def __init__(self, model: str | None = None) -> None:
        self.model = model or os.getenv("OPENAI_DEBATE_MODEL") or "gpt-4o"

    def run(
        self,
        clauses: List[Clause],
        raw_text: Optional[str] = None,
        rounds: int = 2,
        contract_type: Optional[str] = None,
    ) -> List[Dict[str, str]]:
        if not os.getenv("OPENAI_API_KEY"):
            return [{"speaker": "system", "content": "API 키가 필요합니다."}]

        if not contract_type:
            contract_type = self._detect_contract_type(raw_text or "")
        context = self._format_clauses(clauses)
        transcript: List[Dict[str, str]] = []
        for _ in range(rounds):
            landlord_reply = self._reply(
                "임대인 변호사",
                LANDLORD_LAWYER_SYSTEM_PROMPT,
                contract_type,
                context,
                transcript,
            )
            transcript.append({"speaker": "임대인 변호사", "content": landlord_reply})
            tenant_reply = self._reply(
                "임차인 변호사",
                TENANT_LAWYER_SYSTEM_PROMPT,
                contract_type,
                context,
                transcript,
            )
            transcript.append({"speaker": "임차인 변호사", "content": tenant_reply})
        return transcript

    def _reply(
        self,
        role: str,
        system_prompt: str,
        contract_type: str,
        context: str,
        transcript: List[Dict[str, str]],
    ) -> str:
        history = self._format_history(transcript)
        prompt = (
            f"Contract type: {contract_type}\n"
            "Below is a summary of risky clauses in a real estate contract.\n"
            f"{context}\n\n"
            "Conversation so far:\n"
            f"{history}\n\n"
            f"You are speaking as the '{role}' party. "
            "Address or refute the other side and propose concrete revisions in 3-5 sentences. "
            "Respond in Korean."
        )
        return chat_completion(prompt=prompt, model=self.model, system_prompt=system_prompt)

    @staticmethod
    def _format_clauses(clauses: List[Clause]) -> str:
        if not clauses:
            return "- 위험 조항이 발견되지 않았습니다."
        lines = []
        for clause in clauses:
            risk_level = clause.risk_level.value if clause.risk_level else "unknown"
            title = clause.title or "제목 없음"
            content = (clause.content or "").strip()
            snippet = content[:300] + ("..." if len(content) > 300 else "")
            lines.append(
                f"- {clause.article_num} {title} (risk={risk_level}): {snippet}"
            )
        return "\n".join(lines)

    @staticmethod
    def _format_history(transcript: List[Dict[str, str]]) -> str:
        if not transcript:
            return "- (없음)"
        recent = transcript[-4:]
        lines = [f"{turn['speaker']}: {turn['content']}" for turn in recent]
        return "\n".join(lines)

    @staticmethod
    def _detect_contract_type(text: str) -> str:
        if not text:
            return "unknown"
        normalized = text.lower()
        if any(keyword in normalized for keyword in ["전세", "보증금"]):
            return "jeonse"
        if any(keyword in normalized for keyword in ["월세", "임대료", "차임"]):
            return "monthly_rent"
        if any(keyword in normalized for keyword in ["매매", "매도", "매수", "분양", "중도금"]):
            return "sale"
        if any(keyword in normalized for keyword in ["임차", "임대", "임차인"]):
            return "lease"
        return "real_estate_general"

    def detect_contract_type(self, raw_text: str) -> str:
        return self._detect_contract_type(raw_text)
