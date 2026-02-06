"""
계약서 위험 조항에 대한 변호사/검사 페르소나 토론 에이전트.
"""

import math
import os
from typing import Dict, List, Optional

from models import Clause
from openai_client import chat_completion


# 임대인 측 변호사 시스템 프롬프트 (부동산 계약서 검토용)
LANDLORD_LAWYER_SYSTEM_PROMPT = (
    "You are a lawyer representing the landlord in a real estate contract review. "  # 임대인 대리 변호사 역할
    "Focus on reducing clauses that overly increase the landlord's liability or costs "  # 임대인 책임/비용 과도 조항 축소
    "and propose landlord-favorable revisions.\n"  # 임대인에게 유리한 수정안 제시
    "Output in Korean with 3 short bullet points, each with: (1) issue, (2) risk, (3) suggested edit.\n"  # 한국어 3개 불릿, 이슈/리스크/수정안 포함
    "Prioritize: deposit return conditions, defect liability scope, restoration obligations, "  # 보증금 반환, 하자 책임 범위, 원상복구
    "late payment/termination, damage caps, and toxic clauses.\n"  # 연체/해지, 손해배상 한도, 독소조항 우선
    "Do not repeat the other side's view."  # 상대 주장 반복 금지
)

# 임차인 측 변호사 시스템 프롬프트 (부동산 계약서 검토용)
TENANT_LAWYER_SYSTEM_PROMPT = (
    "You are a lawyer representing the tenant in a real estate contract review. "  # 임차인 대리 변호사 역할
    "Focus on reducing clauses that are unfair or risky for the tenant and propose "  # 임차인에게 불리/위험한 조항 축소
    "revisions needed for tenant protection.\n"  # 임차인 보호에 필요한 수정안 제시
    "Output in Korean with 3 short bullet points, each with: (1) issue, (2) risk, (3) suggested edit.\n"  # 한국어 3개 불릿, 이슈/리스크/수정안 포함
    "Prioritize: deposit protection, repair duties, landlord notice/termination requirements, "  # 보증금 보호, 수리 의무, 통지/해지 요건
    "brokerage liability, dispute resolution, and toxic clauses.\n"  # 중개책임, 분쟁해결, 독소조항 우선
    "Do not repeat the other side's view."  # 상대 주장 반복 금지
)



# 중재자 시스템 프롬프트 (판사 역할)
MEDIATOR_SYSTEM_PROMPT = (
    "You are a judge presiding over a contract clause dispute between landlord and tenant lawyers.\n"  # 판사 역할: 임대인/임차인 변호사 분쟁 심리
    "Maintain a firm, judicial tone and provide a concise determination-style summary.\n"  # 판사 톤 유지 + 간결한 결정문 스타일 요약
    "Return ONLY a JSON object with the following keys:\n"  # JSON만 반환
    "perspective_points: {\"landlord\": [..], \"tenant\": [..]},\n"  # 관점별 요지
    "coordination_points: [..],\n"  # 조율할 부분(상충/미합의 쟁점)
    "issue_count: <number>,\n"  # 쟁점 개수
    "common_points: [..]\n"  # 공통 요지
    "Rules:\n"  # 규칙
    "- Use short bullet-style sentences in Korean.\n"  # 한국어 짧은 불릿 문장
    "- perspective_points must reflect each side's distinct arguments.\n"  # 관점별로 구분된 주장 필요
    "- coordination_points should list conflicting or unresolved points.\n"  # 조율이 필요한 쟁점 정리
    "- common_points must be overlapping or repeated points.\n"  # 공통/반복되는 포인트만
    "- No extra text outside JSON."  # JSON 외 텍스트 금지
)

class DebateAgents:
    def __init__(self, model: str | None = None) -> None:
        self.model = model or os.getenv("OPENAI_DEBATE_MODEL") or "gpt-4o"

    def run(
        self,
        clauses: List[Clause],
        raw_text: Optional[str] = None,
        rounds: int = 0,
        max_rounds: int = 2,
        contract_type: Optional[str] = None,
    ) -> List[Dict[str, str]]:
        if not os.getenv("OPENAI_API_KEY"):
            return [{"speaker": "system", "content": "API 키가 필요합니다."}]
        env_max_rounds = os.getenv("DEBATE_MAX_ROUNDS")
        if env_max_rounds:
            try:
                max_rounds = int(env_max_rounds)
            except ValueError:
                pass


        if not contract_type:
            contract_type = self._detect_contract_type(raw_text or "")
        context = self._format_clauses(clauses)
        transcript: List[Dict[str, str]] = []
        # rounds가 주어지면(>0) 그대로 사용하고, 아니면 중재자 기반 루프를 max_rounds까지 수행합니다.
        if rounds and rounds > 0:
            loop_limit = rounds
            use_mediator = False
        else:
            loop_limit = max_rounds
            use_mediator = True

        for _ in range(loop_limit):
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
            if use_mediator:
                mediator_reply = self._mediator_reply(
                    contract_type,
                    context,
                    transcript,
                )
                transcript.append({"speaker": "판사", "content": mediator_reply})
                if self._should_terminate(mediator_reply):
                    break
        return transcript

    def run_by_clause(
        self,
        clauses: List[Clause],
        raw_text: Optional[str] = None,
        rounds: int = 0,
        max_rounds: int = 2,
        contract_type: Optional[str] = None,
    ) -> List[Dict[str, object]]:
        if not clauses:
            return []
        if not contract_type:
            contract_type = self._detect_contract_type(raw_text or "")
        results: List[Dict[str, object]] = []
        for clause in clauses:
            transcript = self.run(
                [clause],
                raw_text=raw_text,
                rounds=rounds,
                max_rounds=max_rounds,
                contract_type=contract_type,
            )
            results.append(
                {
                    "clause_id": clause.id,
                    "article_num": clause.article_num,
                    "title": clause.title,
                    "transcript": transcript,
                }
            )
        return results

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

    def _mediator_reply(
        self,
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
            "Analyze the debate and return the JSON only."
        )
        return chat_completion(
            prompt=prompt,
            model=self.model,
            system_prompt=MEDIATOR_SYSTEM_PROMPT,
        )

    @staticmethod
    def _should_terminate(mediator_reply: str) -> bool:
        # 종료 기준: issue_count <= 0이면 종료, common_points 길이가 기준 이상이면 종료
        # JSON 파싱 실패 시에는 계속 진행
        try:
            import json

            data = json.loads(mediator_reply)
            issue_count = data.get("issue_count")
            common_points = data.get("common_points") or []
            min_common = int(os.getenv("DEBATE_MIN_COMMON_POINTS", "2"))
            common_ratio = float(os.getenv("DEBATE_COMMON_RATIO", "0.5"))
            if isinstance(issue_count, int) and issue_count <= 0:
                return True
            if isinstance(issue_count, int) and issue_count > 0:
                try:
                    if issue_count <= 1:
                        return True
                    if len(common_points) >= issue_count:
                        return True
                    threshold = max(min_common, math.ceil(issue_count * common_ratio))
                    return len(common_points) >= threshold
                except Exception:
                    return False
            if common_points and len(common_points) >= min_common:
                return True
            return False
        except Exception:
            return False

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
            clause_block = f"- {clause.article_num} {title} (risk={risk_level}): {snippet}"
            precedent_block = DebateAgents._format_precedents(clause.related_precedents)
            law_block = DebateAgents._format_laws(clause.related_laws)
            extras = "\n".join([b for b in [precedent_block, law_block] if b])
            if extras:
                clause_block = f"{clause_block}\n  {extras}"
            lines.append(clause_block)
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

    @staticmethod
    def _truncate(text: str, limit: int) -> str:
        text = (text or "").strip()
        if not text:
            return ""
        if len(text) <= limit:
            return text
        return text[:limit] + "..."

    @staticmethod
    def _format_precedents(precedents: List) -> str:
        if not precedents:
            return ""
        items = []
        for p in precedents[:3]:
            case = getattr(p, "case_name", "") or "사건명 없음"
            court = getattr(p, "court", "") or ""
            date = getattr(p, "date", "") or ""
            summary = getattr(p, "summary", "") or getattr(p, "key_paragraph", "") or ""
            summary = DebateAgents._truncate(summary, 160)
            meta = " ".join([part for part in [court, date] if part])
            items.append(f"* 판례: {case} ({meta}) - {summary}".strip())
        if not items:
            return ""
        return "관련 판례:\n  " + "\n  ".join(items)

    @staticmethod
    def _format_laws(laws: List) -> str:
        if not laws:
            return ""
        items = []
        for l in laws[:3]:
            title = getattr(l, "title", "") or "법령명 없음"
            date = getattr(l, "date", "") or ""
            org = getattr(l, "org", "") or ""
            summary = getattr(l, "summary", "") or getattr(l, "content", "") or ""
            summary = DebateAgents._truncate(summary, 160)
            meta = " ".join([part for part in [org, date] if part])
            items.append(f"* 법령: {title} ({meta}) - {summary}".strip())
        if not items:
            return ""
        return "관련 법령:\n  " + "\n  ".join(items)
