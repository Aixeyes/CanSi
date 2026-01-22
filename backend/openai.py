"""
OpenAI 클라이언트/유틸 모듈
"""

from __future__ import annotations

import os
from typing import Optional


class OpenAIClient:
    """OpenAI API 호출 래퍼."""

    def __init__(
        self,
        api_key: Optional[str] = None,
        model: str = "gpt-4o-mini",
        timeout_s: int = 30,
    ) -> None:
        """
        Args:
            api_key: OpenAI API 키 (기본: OPENAI_API_KEY)
            model: 기본 모델명
            timeout_s: 요청 타임아웃(초)
        """
        self.api_key = api_key or os.getenv("OPENAI_API_KEY")
        if not self.api_key:
            raise ValueError("OPENAI_API_KEY 환경변수를 설정해주세요.")

        self.model = model
        self.timeout_s = timeout_s

        try:
            from openai import OpenAI  # type: ignore
        except ImportError as exc:
            raise ImportError("openai 패키지가 필요합니다. `pip install openai`") from exc

        self._client = OpenAI(api_key=self.api_key, timeout=self.timeout_s)

    def generate(self, prompt: str, system_prompt: Optional[str] = None) -> str:
        """단일 프롬프트 호출."""
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})

        response = self._client.chat.completions.create(
            model=self.model,
            messages=messages,
        )
        return response.choices[0].message.content.strip()
