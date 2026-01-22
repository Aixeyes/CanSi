"""
7단계: LLM 독소조항 요약 및 설명
"""

from typing import List, Optional
from models import Clause, Precedent


class LLMSummarizer:
    """LLM을 사용한 독소조항 요약 및 설명"""
    
    def __init__(self, llm_client=None):
        """
        Args:
            llm_client: generate(prompt: str, system_prompt: Optional[str]) -> str 형태의 클라이언트
                       예: OpenAIClient 또는 HuggingFace 래퍼
        """
        self.llm_client = llm_client
    
    def generate_summary(
        self,
        clause: Clause,
        risk_category: str,
        similar_precedents: Optional[List[Precedent]] = None
    ) -> str:
        """
        LLM을 사용하여 독소조항 요약 생성
        
        Args:
            clause: 조항
            risk_category: 위험 카테고리
            similar_precedents: 관련 판례 (선택사항)
            
        Returns:
            LLM 생성 요약
        """
        if similar_precedents is None:
            similar_precedents = []
        
        # 프롬프트 생성
        prompt = self._build_prompt(clause, risk_category, similar_precedents)
        
        if self.llm_client:
            return self.llm_client.generate(prompt)

        return "LLM 응답 대기"
    
    def _build_prompt(
        self, 
        clause: Clause, 
        risk_category: str,
        similar_precedents: List[Precedent]
    ) -> str:
        """
        LLM 프롬프트 생성
        """
        prompt = f"""다음 계약서 조항을 분석하고 위험성을 설명해주세요.

[조항 정보]
- 조항번호: {clause.article_num}
- 제목: {clause.title}
- 내용: {clause.content}
- 위험도: {clause.risk_level.value if clause.risk_level else 'N/A'}
- 위험 이유: {clause.risk_reason or 'N/A'}
- 위험 카테고리: {risk_category}

[요청 사항]
1. 이 조항이 을(甲)에게 미치는 영향을 설명하세요.
2. 왜 위험한지 구체적으로 설명하세요.
3. 법적 근거가 있다면 설명하세요.
4. 개선 방안을 제시하세요.
"""
        
        if similar_precedents:
            prompt += "\n[관련 판례]\n"
            for i, precedent in enumerate(similar_precedents, 1):
                prompt += f"{i}. {precedent.case_name} ({precedent.date})\n"
                prompt += f"   - 법원: {precedent.court}\n"
                prompt += f"   - 요지: {precedent.summary}\n"
                if precedent.similarity_score:
                    prompt += f"   - 유사도: {precedent.similarity_score:.2%}\n"
        
        return prompt
    
    def generate_comprehensive_report(self, risky_clauses: List[Clause]) -> str:
        """전체 독소조항 분석 보고서 생성"""
        report = "# 계약서 독소조항 분석 보고서\n\n"
        report += f"## 분석 개요\n"
        report += f"- 총 분석 조항: {len(risky_clauses)}개\n\n"
        
        for i, clause in enumerate(risky_clauses, 1):
            report += f"### {i}. {clause.article_num} - {clause.title}\n"
            report += f"- **위험도**: {clause.risk_level.value.upper() if clause.risk_level else 'N/A'}\n"
            report += f"- **이유**: {clause.risk_reason or 'N/A'}\n"
            report += f"- **내용**: {clause.content}\n\n"
        
        return report
