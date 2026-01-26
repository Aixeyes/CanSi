"""
데이터 모델 정의
"""

from dataclasses import dataclass, field
from typing import List, Optional
from enum import Enum


class RiskType(str, Enum):
    """위험 유형 분류"""
    CRITICAL = "critical"   # 매우 높음
    HIGH = "high"           # 높음
    MEDIUM = "medium"       # 중간
    LOW = "low"             # 낮음


@dataclass
class Clause:
    """계약 조항"""
    id: str
    article_num: str                    # 조항 번호 (예: "제1조", "제2조")
    title: str                          # 조항 제목
    content: str                        # 조항 내용
    risk_level: Optional[RiskType] = None
    risk_reason: Optional[str] = None
    related_precedents: List = field(default_factory=list)


@dataclass
class Precedent:
    """판례 정보"""
    case_id: str
    court: str                          # 법원
    date: str                           # 선고일자
    case_name: str                      # 사건명
    case_number: str = ""              # 사건번호
    case_type_name: str = ""            # 사건종류명
    case_type_code: Optional[int] = None
    court_type_code: Optional[int] = None
    decision_type: str = ""            # 판결유형
    decision_result: str = ""          # 선고
    source_name: str = ""              # 데이터출처명
    detail_link: str = ""              # 판례상세링크
    issues: str = ""                   # 판시사항
    summary: str = ""                  # 판결요지
    key_paragraph: str = ""            # 문제 문단
    full_text: str = ""                # 판례내용
    reference_statutes: str = ""       # 참조조문
    reference_precedents: str = ""     # 참조판례
    embedding: Optional[List[float]] = None
    similarity_score: Optional[float] = None


@dataclass
class ContractAnalysisResult:
    """계약서 분석 결과"""
    filename: str
    raw_text: str                       # OCR 추출 텍스트
    clauses: List[Clause]
    risky_clauses: List[Clause]
    precedents: List[Precedent]
    llm_summary: Optional[str] = None
