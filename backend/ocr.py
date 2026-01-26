import os
from typing import Any, Dict

try:
    import requests
except ImportError as exc:
    raise ImportError(
        "필수 패키지가 없습니다: requests. `pip install requests`로 설치하세요."
    ) from exc


def get_extracted_text(ocr_result: Any) -> str:
    if isinstance(ocr_result, str):
        return ocr_result
    if isinstance(ocr_result, dict):
        if "text" in ocr_result and isinstance(ocr_result["text"], str):
            return ocr_result["text"]
        if "content" in ocr_result and isinstance(ocr_result["content"], str):
            return ocr_result["content"]
        if isinstance(ocr_result.get("pages"), list):
            texts = []
            for page in ocr_result["pages"]:
                if not isinstance(page, dict):
                    continue
                page_text = page.get("text")
                if isinstance(page_text, str) and page_text.strip():
                    texts.append(page_text)
                    continue
                page_content = page.get("content")
                if isinstance(page_content, str) and page_content.strip():
                    texts.append(page_content)
            return "\n\n".join(texts)
    return ""


class UpstageOCR:
    def __init__(self, api_key: str | None = None, api_url: str | None = None) -> None:
        self.api_key = api_key or os.getenv("UPSTAGE_API_KEY")
        self.api_url = (
            api_url or os.getenv("UPSTAGE_OCR_URL") or "https://api.upstage.ai/v1/document-ai/ocr"
        )

    def _headers(self) -> Dict[str, str]:
        return {
            "Authorization": f"Bearer {self.api_key}",
        }

    def extract_text_from_file(self, file_path: str) -> str:
        with open(file_path, "rb") as file_handle:
            response = requests.post(
                self.api_url,
                files={"document": file_handle},
                headers=self._headers(),
                timeout=60,
            )
        response.raise_for_status()
        return get_extracted_text(response.json())

    def extract_text_from_url(self, url: str) -> str:
        payload = {"url": url}
        response = requests.post(
            self.api_url,
            json=payload,
            headers=self._headers(),
            timeout=60,
        )
        response.raise_for_status()
        return get_extracted_text(response.json())

    def extract_text_from_base64(self, base64_data: str) -> str:
        payload = {"base64": base64_data}
        response = requests.post(
            self.api_url,
            json=payload,
            headers=self._headers(),
            timeout=60,
        )
        response.raise_for_status()
        return get_extracted_text(response.json())
