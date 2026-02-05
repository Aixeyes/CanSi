import json
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
        self.doc_parse_url = (
            os.getenv("UPSTAGE_DOC_PARSE_URL")
            or "https://api.upstage.ai/v1/document-digitization"
        )
        self.doc_parse_model = os.getenv("UPSTAGE_DOC_PARSE_MODEL") or "document-parse"
        self.doc_parse_mode = os.getenv("UPSTAGE_DOC_PARSE_MODE") or "auto"

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
        return self._extract_text(self._json_from_response(response))

    def extract_html_from_file(self, file_path: str) -> str:
        if self.api_key == "api필요":
            return "api필요"
        with open(file_path, "rb") as file_handle:
            response = requests.post(
                self.doc_parse_url,
                files={"document": file_handle},
                headers=self._headers(),
                data={
                    "ocr": "force",
                    "output_formats": '["html"]',
                    "coordinates": "true",
                    "model": self.doc_parse_model,
                    "mode": self.doc_parse_mode,
                },
                timeout=120,
            )
        response.raise_for_status()
        return self._extract_html(self._json_from_response(response))

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
        return self._extract_text(self._json_from_response(response))

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
        return self._extract_text(self._json_from_response(response))

    @staticmethod
    def _json_from_response(response: requests.Response) -> Dict[str, Any]:
        # Try to decode response bytes robustly; some OCR responses have encoding issues.
        content = response.content
        for encoding in ("utf-8", "euc-kr", response.apparent_encoding):
            if not encoding:
                continue
            try:
                return json.loads(content.decode(encoding))
            except (UnicodeDecodeError, json.JSONDecodeError):
                continue
        return response.json()

    def _extract_text(self, response_json: Dict[str, Any]) -> str:
        if "text" in response_json and isinstance(response_json["text"], str):
            return response_json["text"]
        if "content" in response_json and isinstance(response_json["content"], str):
            return response_json["content"]
        return ""

    def _extract_html(self, response_json: Dict[str, Any]) -> str:
        content = response_json.get("content") if isinstance(response_json, dict) else None
        if isinstance(content, dict):
            html = content.get("html")
            if isinstance(html, str):
                return html
        html = response_json.get("html") if isinstance(response_json, dict) else None
        if isinstance(html, str):
            return html
        return ""


def get_extracted_text(result: Any) -> str:
    """
    Normalize OCR results to plain text.
    - If result is already a string, return it.
    - If result is a dict-like payload, extract common text fields.
    """
    if isinstance(result, str):
        return result
    if isinstance(result, dict):
        text = result.get("text")
        if isinstance(text, str):
            return text
        content = result.get("content")
        if isinstance(content, str):
            return content
    return ""
