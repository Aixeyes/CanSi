import os
from typing import Any, Dict

try:
    import requests
except ImportError as exc:
    raise ImportError(
        "필수 패키지가 없습니다: requests. `pip install requests`로 설치하세요."
    ) from exc


class UpstageOCR:
    def __init__(self, api_key: str | None = None, api_url: str | None = None) -> None:
        self.api_key = api_key or os.getenv("UPSTAGE_API_KEY") or "api필요"
        self.api_url = (
            api_url or os.getenv("UPSTAGE_OCR_URL") or "https://api.upstage.ai/v1/document-ai/ocr"
        )

    def _headers(self) -> Dict[str, str]:
        return {
            "Authorization": f"Bearer {self.api_key}",
        }

    def extract_text_from_file(self, file_path: str) -> str:
        if self.api_key == "api필요":
            return "api필요"
        with open(file_path, "rb") as file_handle:
            response = requests.post(
                self.api_url,
                files={"document": file_handle},
                headers=self._headers(),
                timeout=60,
            )
        response.raise_for_status()
        return self._extract_text(response.json())

    def extract_text_from_url(self, url: str) -> str:
        if self.api_key == "api필요":
            return "api필요"
        payload = {"url": url}
        response = requests.post(
            self.api_url,
            json=payload,
            headers=self._headers(),
            timeout=60,
        )
        response.raise_for_status()
        return self._extract_text(response.json())

    def extract_text_from_base64(self, base64_data: str) -> str:
        if self.api_key == "api필요":
            return "api필요"
        payload = {"base64": base64_data}
        response = requests.post(
            self.api_url,
            json=payload,
            headers=self._headers(),
            timeout=60,
        )
        response.raise_for_status()
        return self._extract_text(response.json())

    def _extract_text(self, response_json: Dict[str, Any]) -> str:
        if "text" in response_json and isinstance(response_json["text"], str):
            return response_json["text"]
        if "content" in response_json and isinstance(response_json["content"], str):
            return response_json["content"]
        return ""
