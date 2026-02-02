"""
6단계: 위험 유형 매핑
"""

from typing import List
import re
from models import Clause, Precedent


class RiskMapper:
    """위험 유형 분류 및 매핑"""
    
    RISK_CATEGORIES = {
        "일방적 해지": ["일방적 해지", "즉시 해지", "해지"],
        "무제한 배상": ["무제한", "모든 손해", "전액 배상"],
        "책임_면책": ["책임 없음", "면책", "배상 제외"],
        "강제_집행": ["강제", "즉시 집행", "이행 강제"],
        "개인정보": ["개인정보", "민감정보", "수집 동의"],
        "불공정조항": ["불공정", "일방적", "차별"],
    }
    
    @staticmethod
    def map_risk_category(clause: Clause, precedents: List[Precedent]) -> str:
        """
        조항을 위험 카테고리로 분류
        
        Args:
            clause: 분류 대상 조항
            precedents: 관련 판례 (추가 참고용)
            
        Returns:
            위험 카테고리 (예: "일방적 해지")
        """
        clause_text = (clause.title + " " + clause.content).lower()
        
        for category, keywords in RiskMapper.RISK_CATEGORIES.items():
            for keyword in keywords:
                if keyword in clause_text:
                    return category
        
        return "기타"
    
    @staticmethod
    def get_all_categories() -> List[str]:
        """전체 위험 카테고리 반환"""
        return list(RiskMapper.RISK_CATEGORIES.keys())

    @staticmethod
    def get_keywords_for_category(category: str) -> List[str]:
        """카테고리별 키워드 반환"""
        return RiskMapper.RISK_CATEGORIES.get(category, [])

    @staticmethod
    def find_highlight_sentences(text: str, keywords: List[str]) -> List[str]:
        """
        키워드가 포함된 문장을 찾아 반환

        Args:
            text: 대상 텍스트
            keywords: 탐색 키워드 리스트
        """
        if not text or not keywords:
            return []
        sentences: List[str] = []
        chunks = re.split(r'(?<=[\.\!\?]|[。！？])\s+', text)
        for chunk in chunks:
            parts = [p.strip() for p in re.split(r'[\r\n]+', chunk) if p.strip()]
            for part in parts:
                if any(kw in part for kw in keywords):
                    sentences.append(part)
        # 중복 제거 (순서 유지)
        seen = set()
        deduped: List[str] = []
        for sent in sentences:
            if sent not in seen:
                deduped.append(sent)
                seen.add(sent)
        return deduped
