import os
from typing import Optional

try:
    from openai import OpenAI
except ImportError as exc:
    raise ImportError(
        "필수 패키지가 없습니다: openai. `pip install openai`로 설치하세요."
    ) from exc


class LLMSummarizer:
    def __init__(self, model: Optional[str] = None) -> None:
        self.model = model or os.getenv("OPENAI_SUMMARY_MODEL") or "gpt-4o"
        self.api_key = os.getenv("OPENAI_API_KEY") or "api필요"
        self._client = OpenAI(api_key=self.api_key) if self.api_key != "api필요" else None

    def generate_summary(self, text: str) -> str:
        if self.api_key == "api필요":
            return "api필요"
        prompt = (
            "Summarize the contract clauses concisely, focusing on key obligations and risks. "
            "Respond in Korean."
        )
        response = self._client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": prompt},
                {"role": "user", "content": text},
            ],
        )
        return response.choices[0].message.content or ""

    def generate_comprehensive_report(self, text: str) -> str:
        if self.api_key == "api필요":
            return "api필요"
        prompt = (
            "Create a comprehensive report with sections: overview, key clauses, risks, and recommendations. "
            "Respond in Korean."
        )
        response = self._client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": prompt},
                {"role": "user", "content": text},
            ],
        )
        return response.choices[0].message.content or ""
