"""
3단계: 위험 조항 필터링 (Rule-based)
"""

from typing import List, Tuple
from models import Clause, RiskType


class RiskAssessor:
    """을(甲) 기준 위험 조항 필터링"""
    
    # 위험 키워드 정의
    CRITICAL_KEYWORDS = {
        "critical": ["무제한", "일방적", "즉시 해지", "전액 배상", "전적으로 책임"],
        "high": ["배상", "손해배상", "책임", "이의제기 불가", "강제 집행"],
        "medium": ["수정 불가", "변경 불가", "의무", "조건"]
    }
    
    @staticmethod
    def assess_clause(clause: Clause) -> Tuple[RiskType, str]:
        """
        조항의 위험도 평가
        
        Returns:
            (위험 수준, 위험 사유)
        """
        text = (clause.title + " " + clause.content).lower()
        
        # CRITICAL 체크
        for keyword in RiskAssessor.CRITICAL_KEYWORDS["critical"]:
            if keyword in text:
                return RiskType.CRITICAL, f"위험 키워드 '{keyword}' 감지"
        
        # HIGH 체크
        for keyword in RiskAssessor.CRITICAL_KEYWORDS["high"]:
            if keyword in text:
                return RiskType.HIGH, f"위험 키워드 '{keyword}' 감지"
        
        # MEDIUM 체크
        for keyword in RiskAssessor.CRITICAL_KEYWORDS["medium"]:
            if keyword in text:
                return RiskType.MEDIUM, f"주의 키워드 '{keyword}' 감지"
        
        return RiskType.LOW, "위험 요소 없음"
    
    @staticmethod
    def filter_risky_clauses(clauses: List[Clause]) -> List[Clause]:
        """위험 조항만 필터링"""
        risky_clauses = []
        
        for clause in clauses:
            risk_level, reason = RiskAssessor.assess_clause(clause)
            clause.risk_level = risk_level
            clause.risk_reason = reason
            
            if risk_level in [RiskType.CRITICAL, RiskType.HIGH, RiskType.MEDIUM]:
                risky_clauses.append(clause)
        
        return risky_clauses
