"""
4단계: 공공 판례 API 호출 및 DB 구축
"""

from typing import List, Optional
from models import Precedent


class PrecedentFetcher:
    """판례 API 호출 및 DB 구축"""
    
    def __init__(self, api_url: Optional[str] = None):
        """
        Args:
            api_url: 판례 API URL (국가법령정보센터, 대법원 판례 등)
        """
        self.api_url = api_url or "https://www.law.go.kr/API/OpenServiceList"
        self.precedents_db: List[Precedent] = []
    
    def fetch_precedents(self, keyword: str, limit: int = 10) -> List[Precedent]:
        """
        판례 검색
        
        Args:
            keyword: 검색 키워드
            limit: 최대 결과 수
            
        Returns:
            판례 목록
        """
        # TODO: 실제 API 호출 구현 (국가법령정보센터, 판례검색 API 등)
        # 현재는 더미 데이터 반환
        precedents = [
            Precedent(
                case_id="2020가합12345",
                court="서울중앙지방법원",
                date="2020-06-15",
                case_name="계약 분쟁 사건",
                summary="일방적 해지 조항은 공정거래법 위반으로 판단",
                key_paragraph="계약서의 일방적 해지 조항은 계약의 균형을 해치는 것으로 보임"
            )
        ]
        
        self.precedents_db.extend(precedents)
        return precedents
    
    def get_precedents_by_keyword(self, keyword: str) -> List[Precedent]:
        """키워드로 판례 DB 검색"""
        results = []
        keyword_lower = keyword.lower()
        
        for precedent in self.precedents_db:
            if (keyword_lower in precedent.summary.lower() or 
                keyword_lower in precedent.key_paragraph.lower()):
                results.append(precedent)
        
        return results
    
    def add_precedent(self, precedent: Precedent):
        """판례 수동 추가"""
        self.precedents_db.append(precedent)
    
    def get_all_precedents(self) -> List[Precedent]:
        """모든 판례 반환"""
        return self.precedents_db
