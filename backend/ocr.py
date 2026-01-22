import requests
import os
from typing import Optional
import base64


class UpstageOCR:
    """Upstage OCR API를 사용하는 클래스"""
    
    def __init__(self, api_key: Optional[str] = None):
        """
        Args:
            api_key: Upstage API 키 (환경변수 UPSTAGE_API_KEY에서 자동 로드)
        """
        self.api_key = api_key or os.getenv("UPSTAGE_API_KEY")
        if not self.api_key:
            raise ValueError("UPSTAGE_API_KEY 환경변수를 설정해주세요.")
        
        self.api_url = "https://api.upstage.ai/v1/document-ai/ocr"
        self.headers = {
            "Authorization": f"Bearer {self.api_key}"
        }
    
    def extract_text_from_file(self, file_path: str) -> dict:
        """
        파일 경로에서 OCR 추출
        
        Args:
            file_path: 이미지 파일 경로
            
        Returns:
            OCR 결과 (텍스트, 좌표 등)
        """
        with open(file_path, "rb") as f:
            files = {
                "document": f
            }
            response = requests.post(
                self.api_url,
                headers=self.headers,
                files=files
            )
        
        return self._handle_response(response)
    
    def extract_text_from_url(self, image_url: str) -> dict:
        """
        URL의 이미지에서 OCR 추출
        
        Args:
            image_url: 이미지 URL
            
        Returns:
            OCR 결과
        """
        data = {
            "document_url": image_url
        }
        
        response = requests.post(
            self.api_url,
            headers=self.headers,
            json=data
        )
        
        return self._handle_response(response)
    
    def extract_text_from_base64(self, image_base64: str, mime_type: str = "image/jpeg") -> dict:
        """
        Base64 인코딩된 이미지에서 OCR 추출
        
        Args:
            image_base64: Base64 인코딩된 이미지 문자열
            mime_type: 이미지의 MIME 타입 (기본: image/jpeg)
            
        Returns:
            OCR 결과
        """
        # base64 형식으로 데이터 URI 생성
        data_uri = f"data:{mime_type};base64,{image_base64}"
        
        data = {
            "document": data_uri
        }
        
        response = requests.post(
            self.api_url,
            headers=self.headers,
            json=data
        )
        
        return self._handle_response(response)
    
    def _handle_response(self, response: requests.Response) -> dict:
        """
        API 응답 처리
        
        Args:
            response: requests Response 객체
            
        Returns:
            파싱된 결과
        """
        if response.status_code != 200:
            raise Exception(
                f"OCR 요청 실패: {response.status_code}\n{response.text}"
            )
        
        return response.json()


def get_extracted_text(result: dict) -> str:
    """
    OCR 결과에서 텍스트만 추출
    
    Args:
        result: OCR API 응답 결과
        
    Returns:
        추출된 텍스트
    """
    if "text" in result:
        return result["text"]
    elif "pages" in result:
        # 여러 페이지인 경우
        all_text = []
        for page in result["pages"]:
            if "text" in page:
                all_text.append(page["text"])
        return "\n---\n".join(all_text)
    
    return ""


if __name__ == "__main__":
    # 사용 예시
    ocr = UpstageOCR()
    
    # 파일에서 추출
    # result = ocr.extract_text_from_file("image.jpg")
    # print(get_extracted_text(result))
