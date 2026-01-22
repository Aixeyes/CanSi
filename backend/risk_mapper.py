"""
6단계: 위험 유형 매핑
"""

from typing import List
from models import Clause, Precedent


class RiskMapper:
    """위험 유형 분류 및 매핑"""
    
    RISK_CATEGORIES = {
        "일방적_해지": ["일방적", "즉시 해지", "통지"],
        "무제한_배상": ["무제한", "모든 손해", "전액 배상"],
        "책임_회피": ["책임 없음", "면책", "배상 거부"],
        "강제_집행": ["강제", "즉시 집행", "이의제기 불가"],
        "개인정보": ["개인정보", "민감정보", "수집 동의"],
        "불공정_조항": ["부당한", "합리성 없는", "차별"],
    }
    
    @staticmethod
    def map_risk_category(clause: Clause, precedents: List[Precedent]) -> str:
        """
        조항을 위험 카테고리로 분류
        
        Args:
            clause: 분류 대상 조항
            precedents: 관련 판례 (추가 참고용)
            
        Returns:
            위험 카테고리 (예: "일방적_해지")
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
