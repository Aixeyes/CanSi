import os
from typing import Any, List

try:
    import requests
except ImportError as exc:
    raise ImportError(
        "필수 패키지가 없습니다: requests. `pip install requests`로 설치하세요."
    ) from exc

from models import Precedent
from embedding_manager import EmbeddingManager


class PrecedentFetcher:
    def __init__(self, api_url: str | None = None, api_key: str | None = None) -> None:
        self.api_url = (
            api_url or os.getenv("PRECEDENT_API_URL") or "https://www.law.go.kr/DRF/lawSearch.do"
        )
        self.api_key = api_key or os.getenv("PRECEDENT_API_KEY")
        self._local_store: List[Precedent] = []
        self._embedding_manager = EmbeddingManager()

    def _build_embedding_source(self, precedent: Precedent) -> str:
        parts = [
            precedent.case_name,
            precedent.issues,
            precedent.summary,
            precedent.key_paragraph,
            precedent.full_text,
        ]
        return " ".join([p for p in parts if p]).strip()

    def _extract_items(self, data: Any) -> List[dict]:
        if isinstance(data, list):
            return [item for item in data if isinstance(item, dict)]
        if not isinstance(data, dict):
            return []
        if "prec" in data and isinstance(data["prec"], list):
            return [item for item in data["prec"] if isinstance(item, dict)]
        for value in data.values():
            if isinstance(value, dict) and "prec" in value:
                prec_list = value.get("prec")
                if isinstance(prec_list, list):
                    return [item for item in prec_list if isinstance(item, dict)]
        return []

    def _fetch_detail(self, detail_link: str) -> dict:
        if not detail_link:
            return {}
        try:
            response = requests.get(
                detail_link,
                params={"OC": self.api_key, "type": "JSON"},
                timeout=30,
            )
            response.raise_for_status()
            data = response.json() or {}
            if isinstance(data, dict):
                return data
        except Exception:
            return {}
        return {}

    def _extract_detail_fields(self, data: dict) -> dict:
        if not isinstance(data, dict):
            return {}
        return {
            "issues": str(data.get("판시사항", "")),
            "summary": str(data.get("판결요지", "")),
            "reference_statutes": str(data.get("참조조문", "")),
            "reference_precedents": str(data.get("참조판례", "")),
            "full_text": str(data.get("판례내용", "")),
        }

    def fetch_precedents(self, keyword: str) -> List[Precedent] | str:
        if self.api_key == "api필요":
            return "api필요"
        base_term = "부동산"
        keyword = keyword.strip()
        if base_term not in keyword:
            keyword = f"{keyword} {base_term}".strip()
        response = requests.get(
            self.api_url,
            params={
                "OC": self.api_key,
                "target": "prec",
                "type": "JSON",
                "query": keyword,
                "display": 20,
                "page": 1,
            },
            timeout=30,
        )
        response.raise_for_status()
        data = response.json() or {}
        items = self._extract_items(data)
        precedents = []
        for item in items:
            detail_link = str(item.get("판례상세링크", ""))
            detail_data = self._fetch_detail(detail_link)
            detail_fields = self._extract_detail_fields(detail_data)

            precedent = Precedent(
                case_id=str(item.get("판례일련번호", "")),
                court=str(item.get("법원명", "")),
                date=str(item.get("선고일자", "")),
                case_name=str(item.get("사건명", "")),
                case_number=str(item.get("사건번호", "")),
                case_type_name=str(item.get("사건종류명", "")),
                case_type_code=item.get("사건종류코드"),
                court_type_code=item.get("법원종류코드"),
                decision_type=str(item.get("판결유형", "")),
                decision_result=str(item.get("선고", "")),
                source_name=str(item.get("데이터출처명", "")),
                detail_link=detail_link,
                issues=detail_fields.get("issues", ""),
                summary=detail_fields.get("summary", ""),
                key_paragraph=detail_fields.get("issues", ""),
                full_text=detail_fields.get("full_text", ""),
                reference_statutes=detail_fields.get("reference_statutes", ""),
                reference_precedents=detail_fields.get("reference_precedents", ""),
            )
            embedding_source = self._build_embedding_source(precedent)
            if embedding_source:
                embedding = self._embedding_manager.generate_embedding(embedding_source)
                if isinstance(embedding, list):
                    precedent.embedding = embedding
            precedents.append(precedent)
        return precedents

    def get_precedents_by_keyword(self, keyword: str) -> List[Precedent]:
        keyword = keyword.lower()
        results: List[Precedent] = []
        for precedent in self._local_store:
            haystack = " ".join(
                [precedent.case_name, precedent.summary, precedent.key_paragraph]
            ).lower()
            if keyword in haystack:
                results.append(precedent)
        return results

    def add_precedent(self, precedent: Precedent) -> None:
        embedding_source = self._build_embedding_source(precedent)
        if embedding_source and precedent.embedding is None:
            embedding = self._embedding_manager.generate_embedding(embedding_source)
            if isinstance(embedding, list):
                precedent.embedding = embedding
        self._local_store.append(precedent)
