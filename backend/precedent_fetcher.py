import os
from typing import List

try:
    import requests
except ImportError as exc:
    raise ImportError(
        "필수 패키지가 없습니다: requests. `pip install requests`로 설치하세요."
    ) from exc

from .models import Precedent


class PrecedentFetcher:
    def __init__(self, api_url: str | None = None, api_key: str | None = None) -> None:
        self.api_url = api_url or os.getenv("PRECEDENT_API_URL") or ""
        self.api_key = api_key or os.getenv("PRECEDENT_API_KEY") or "api필요"
        self._local_store: List[Precedent] = []

    def fetch_precedents(self, keyword: str) -> List[Precedent] | str:
        if self.api_key == "api필요":
            return "api필요"
        if not self.api_url:
            return []
        response = requests.get(
            self.api_url,
            params={"q": keyword},
            headers={"Authorization": f"Bearer {self.api_key}"},
            timeout=30,
        )
        response.raise_for_status()
        items = response.json() or []
        precedents = []
        for item in items:
            precedents.append(
                Precedent(
                    precedent_id=str(item.get("id", "")),
                    title=str(item.get("title", "")),
                    summary=str(item.get("summary", "")),
                    keywords=item.get("keywords", []) or [],
                )
            )
        return precedents

    def get_precedents_by_keyword(self, keyword: str) -> List[Precedent]:
        return [p for p in self._local_store if keyword in p.keywords]

    def add_precedent(self, precedent: Precedent) -> None:
        self._local_store.append(precedent)
