"""
5단계: 임베딩 생성 및 유사도 검색
"""

from typing import List
from models import Clause, Precedent


class EmbeddingManager:
    """임베딩 생성 및 유사도 검색"""
    
    def __init__(self, embedding_model: str = "sentence-transformers/ko-sentence-bert"):
        """
        Args:
            embedding_model: 임베딩 모델 이름
        """
        self.model_name = embedding_model
        self.embeddings = {}
        
        # TODO: 실제 구현 시 sentence-transformers 사용
        # from sentence_transformers import SentenceTransformer
        # self.model = SentenceTransformer(embedding_model)
    
    def generate_embedding(self, text: str) -> List[float]:
        """텍스트 임베딩 생성"""
        # TODO: 실제 임베딩 구현
        # embedding = self.model.encode(text)
        return []
    
    def calculate_similarity(self, text1: str, text2: str) -> float:
        """
        두 텍스트의 유사도 계산 (0~1)
        
        Returns:
            유사도 점수 (0~1)
        """
        # TODO: 실제 구현
        # embedding1 = self.generate_embedding(text1)
        # embedding2 = self.generate_embedding(text2)
        # from sklearn.metrics.pairwise import cosine_similarity
        # similarity = cosine_similarity([embedding1], [embedding2])[0][0]
        return 0.0
    
    def find_similar_precedents(
        self, 
        clause: Clause, 
        precedents: List[Precedent],
        threshold: float = 0.7
    ) -> List[Precedent]:
        """
        유사한 판례 찾기
        
        Args:
            clause: 비교 대상 조항
            precedents: 판례 목록
            threshold: 유사도 임계값
            
        Returns:
            유사도가 높은 판례 목록 (유사도순 정렬)
        """
        similar = []
        
        for precedent in precedents:
            similarity = self.calculate_similarity(
                clause.content,
                precedent.key_paragraph
            )
            
            if similarity >= threshold:
                precedent.similarity_score = similarity
                similar.append(precedent)
        
        # 유사도 순 정렬
        return sorted(similar, key=lambda x: x.similarity_score, reverse=True)
