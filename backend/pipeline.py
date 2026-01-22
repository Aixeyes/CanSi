"""
계약서 독소조항 분석 파이프라인 - 메인 파이프라인
"""

import os
import json
from typing import List, Optional
from dataclasses import asdict

from ocr import UpstageOCR, get_extracted_text
from models import ContractAnalysisResult, Clause
from text_processor import TextProcessor
from risk_assessor import RiskAssessor
from precedent_fetcher import PrecedentFetcher
from embedding_manager import EmbeddingManager
from risk_mapper import RiskMapper
from llm_summarizer import LLMSummarizer
from openai import OpenAIClient


# ==================== 메인 파이프라인 ====================

class ContractAnalysisPipeline:
    """계약서 분석 전체 파이프라인"""
    
    def __init__(self, llm_client=None):
        self.ocr = UpstageOCR()
        self.text_processor = TextProcessor()
        self.risk_assessor = RiskAssessor()
        self.precedent_fetcher = PrecedentFetcher()
        self.embedding_manager = EmbeddingManager()
        self.risk_mapper = RiskMapper()
        if llm_client is None:
            llm_client = OpenAIClient()
        self.llm_summarizer = LLMSummarizer(llm_client=llm_client)
    
    def analyze(self, file_path: str) -> ContractAnalysisResult:
        """
        계약서 분석 전체 파이프라인 실행
        
        Flow:
        1. OCR (Upstage)
        2. 텍스트 정제 / 조항 분리
        3. 을 기준 위험 조항 후보 필터
        4. 공공 판례 API 호출
        5. 임베딩 생성 & 유사도 검색
        6. 위험 유형 매핑
        7. LLM 독소조항 요약
        
        Args:
            file_path: 계약서 파일 경로 (PDF 또는 이미지)
            
        Returns:
            분석 결과
        """
        filename = os.path.basename(file_path)
        
        # 1단계: OCR
        print(f"[1/7] OCR 진행 중... ({filename})")
        ocr_result = self.ocr.extract_text_from_file(file_path)
        raw_text = get_extracted_text(ocr_result)
        
        # 2단계: 텍스트 정제 및 조항 분리
        print(f"[2/7] 텍스트 정제 및 조항 분리...")
        clean_text = self.text_processor.clean_text(raw_text)
        clauses = self.text_processor.split_clauses(clean_text)
        print(f"     → 총 {len(clauses)}개 조항 추출")
        
        # 3단계: 위험 조항 필터링
        print(f"[3/7] 을 기준 위험 조항 필터링...")
        risky_clauses = self.risk_assessor.filter_risky_clauses(clauses)
        print(f"     → 위험 조항 {len(risky_clauses)}개 발견")
        
        # 4단계: 판례 데이터 수집
        print(f"[4/7] 공공 판례 API 호출...")
        all_precedents = []
        for clause in risky_clauses:
            precedents = self.precedent_fetcher.fetch_precedents(clause.title)
            all_precedents.extend(precedents)
        print(f"     → 판례 {len(all_precedents)}개 수집")
        
        # 5단계: 임베딩 생성 & 유사도 검색
        print(f"[5/7] 임베딩 생성 & 유사도 검색...")
        for clause in risky_clauses:
            similar_precedents = self.embedding_manager.find_similar_precedents(
                clause, all_precedents
            )
            clause.related_precedents = similar_precedents
        print(f"     → 유사도 검색 완료")
        
        # 6단계: 위험 유형 매핑
        print(f"[6/7] 위험 유형 매핑...")
        risk_mappings = {}
        for clause in risky_clauses:
            category = self.risk_mapper.map_risk_category(clause, all_precedents)
            risk_mappings[clause.id] = category
        print(f"     → 위험 유형 분류 완료")
        
        # 7단계: LLM 요약 생성
        print(f"[7/7] LLM 독소조항 요약 생성...")
        llm_summary = self.llm_summarizer.generate_comprehensive_report(risky_clauses)
        
        # 결과 반환
        result = ContractAnalysisResult(
            filename=filename,
            raw_text=raw_text,
            clauses=clauses,
            risky_clauses=risky_clauses,
            precedents=all_precedents,
            llm_summary=llm_summary
        )
        
        print("\n✓ 분석 완료!")
        return result
    
    def export_result(self, result: ContractAnalysisResult, output_path: str):
        """분석 결과를 JSON으로 내보내기"""
        output_data = {
            "filename": result.filename,
            "total_clauses": len(result.clauses),
            "risky_clauses_count": len(result.risky_clauses),
            "clauses": [asdict(c) for c in result.clauses],
            "risky_clauses": [asdict(c) for c in result.risky_clauses],
            "precedents": [asdict(p) for p in result.precedents],
            "summary": result.llm_summary
        }
        
        # dataclass 직렬화 문제 해결
        def serialize(obj):
            if hasattr(obj, 'value'):  # Enum
                return obj.value
            return str(obj)
        
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(output_data, f, ensure_ascii=False, indent=2, default=serialize)
        
        print(f"결과 저장: {output_path}")


# ==================== 사용 예시 ====================

if __name__ == "__main__":
    # 파이프라인 초기화
    pipeline = ContractAnalysisPipeline()
    
    # 분석 실행
    contract_file = "contract.pdf"  # 또는 .jpg, .png 등
    
    try:
        result = pipeline.analyze(contract_file)
        
        # 결과 출력
        print(f"\n{'='*50}")
        print(f"총 조항 수: {len(result.clauses)}")
        print(f"위험 조항 수: {len(result.risky_clauses)}")
        print(f"{'='*50}\n")
        print(result.llm_summary)
        
        # 결과 저장
        pipeline.export_result(result, "analysis_result.json")
        
    except FileNotFoundError:
        print(f"파일을 찾을 수 없습니다: {contract_file}")
    except Exception as e:
        print(f"오류 발생: {e}")
