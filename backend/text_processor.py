"""
2단계: 텍스트 정제 및 조항 분리
"""

import json
import re
from typing import List

from openai_client import chat_completion
from models import Clause


class TextProcessor:
    """텍스트 정제 및 조항 분리"""
    
    @staticmethod
    def clean_text(text: str) -> str:
        """
        텍스트 정제
        - 특수문자 정리
        - 불필요한 공백 제거
        - 줄바꿈 정리
        """
        # 중복 공백 제거
        text = re.sub(r' +', ' ', text)
        # 중복 줄바꿈 정리 (최대 2줄까지만)
        text = re.sub(r'\n\n+', '\n\n', text)
        # 양끝 공백 제거
        text = text.strip()
        return text
    
    @staticmethod
    def split_clauses(text: str) -> List[Clause]:
        """
        조항 분리
        
        예상 형식:
        제1조 제목
        조항 내용...
        
        제2조 제목
        조항 내용...
        """
        clauses = []
        
        # "제n조" 패턴으로 분리
        clause_pattern = r'제(\d+)조\s+(.+?)(?=제\d+조|$)'
        matches = re.finditer(clause_pattern, text, re.DOTALL)
        
        for match in matches:
            clause_num = match.group(1)
            clause_text = match.group(2).strip()
            
            # 첫 줄을 제목으로, 나머지를 내용으로
            lines = clause_text.split('\n', 1)
            title = lines[0].strip()
            content = lines[1].strip() if len(lines) > 1 else ""
            
            clause = Clause(
                id=f"clause_{clause_num}",
                article_num=f"제{clause_num}조",
                title=title,
                content=content
            )
            clauses.append(clause)
        
        return clauses

    def split_clauses_with_fallback(self, text: str) -> List[Clause]:
        """
        규칙 기반 분리가 실패하거나 품질이 낮을 때 LLM 보정 분리를 시도한다.
        """
        clauses = self.split_clauses(text)
        if clauses and not (len(clauses) == 1 and len(text) > 1000):
            return clauses
        return self._split_clauses_with_llm(text, fallback=clauses)

    def _split_clauses_with_llm(
        self,
        text: str,
        fallback: List[Clause],
    ) -> List[Clause]:
        prompt = (
            "Split the following Korean contract into clauses. "
            "Return JSON only as a list of objects with keys: article_num, title, content. "
            "article_num should be like '제1조' if present, otherwise use '조항N'. "
            "Do not omit any content. Respond in Korean.\n\n"
            f"{text}"
        )
        try:
            content = chat_completion(prompt=prompt, model="gpt-4o")
            payload = json.loads(content)
            clauses: List[Clause] = []
            for idx, item in enumerate(payload, start=1):
                article_num = str(item.get("article_num") or f"조항{idx}").strip()
                title = str(item.get("title") or "무제").strip()
                body = str(item.get("content") or "").strip()
                clause = Clause(
                    id=f"clause_{idx}",
                    article_num=article_num,
                    title=title,
                    content=body,
                )
                clauses.append(clause)
            return clauses or fallback
        except Exception:
            return fallback
