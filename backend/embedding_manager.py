import math
import os
from typing import List, Optional

try:
    from openai import OpenAI
except ImportError as exc:
    raise ImportError(
        "필수 패키지가 없습니다: openai. `pip install openai`로 설치하세요."
    ) from exc

from models import Precedent


class EmbeddingManager:
    def __init__(self, model: Optional[str] = None) -> None:
        self.model = model or os.getenv("OPENAI_EMBEDDING_MODEL") or "text-embedding-3-small"
        self.api_key = os.getenv("OPENAI_API_KEY") or "api필요"
        self._client = OpenAI(api_key=self.api_key) if self.api_key != "api필요" else None

    def generate_embedding(self, text: str) -> List[float] | str:
        if self.api_key == "api필요":
            return "api필요"
        response = self._client.embeddings.create(model=self.model, input=text)
        return response.data[0].embedding

    def calculate_similarity(self, vector_a: List[float], vector_b: List[float]) -> float:
        if not vector_a or not vector_b or len(vector_a) != len(vector_b):
            return 0.0
        dot = sum(a * b for a, b in zip(vector_a, vector_b))
        norm_a = math.sqrt(sum(a * a for a in vector_a))
        norm_b = math.sqrt(sum(b * b for b in vector_b))
        if norm_a == 0.0 or norm_b == 0.0:
            return 0.0
        return dot / (norm_a * norm_b)

    def find_similar_precedents(
        self, target_text: str, precedents: List[Precedent], top_k: int = 3
    ) -> List[Precedent] | str:
        target_embedding = self.generate_embedding(target_text)
        if target_embedding == "api필요":
            return "api필요"
        scored: List[tuple[float, Precedent]] = []
        for precedent in precedents:
            precedent_embedding = getattr(precedent, "embedding", None)
            if not precedent_embedding:
                continue
            score = self.calculate_similarity(target_embedding, precedent_embedding)
            scored.append((score, precedent))
        scored.sort(key=lambda item: item[0], reverse=True)
        return [item[1] for item in scored[:top_k]]
