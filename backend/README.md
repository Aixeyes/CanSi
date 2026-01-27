# CanSi - 계약서 독소조항 분석 시스템

## 📋 개요

**CanSi**는 AI를 활용하여 계약서의 위험한 조항(독소조항)을 자동으로 분석하고, 관련 판례와 법적 근거를 제시하는 시스템입니다.

### 주요 기능
- 🔤 **OCR 기반 텍스트 추출** (Upstage API)
- 🔍 **자동 위험 조항 탐지** (Rule-based + LLM)
- 📚 **관련 판례 검색 및 연결**
- 🎯 **유사도 기반 판례 매칭** (Embedding)
- 🗣️ **갑/을 토론 기반 협상 시뮬레이션**
- 🏠 **부동산 계약 유형 자동 감지** (전세/월세/매매/임대)
- 🤖 **LLM 기반 상세 분석** (OpenAI)

---

## 🏗️ 시스템 아키텍처

### 파이프라인 구성

```
계약서 (PDF/이미지)
    ↓
[1] 🔤 OCR (Upstage)          → 텍스트 추출
    ↓
[2] ✏️ 텍스트 정제            → 조항 분리 ("제N조" 패턴)
    ↓
[2-1] 🤖 LLM 보정 분리         → 규칙 분리 실패 시 보정
    ↓
[3] ⚠️ 위험 평가              → LLM 기반 위험도 판정
    ↓
[4] 📚 판례 수집              → 공공 API에서 관련 판례
    ↓
[5] 🔍 유사도 검색            → 임베딩 기반 매칭
    ↓
[6] 🗂️ 위험 분류              → 일방적_해지, 무제한_배상 등
    ↓
[7] 🗣️ 갑/을 토론             → 부동산 계약 유형 자동 감지 후 협상 논의
    ↓
[8] 🤖 LLM 요약               → 상세 분석 보고서 생성
    ↓
📊 분석 결과
```

---

## 🚀 설치 및 환경 설정

### 1. 필수 패키지 설치

```bash
# 기본 패키지
pip install requests

# 임베딩 & 유사도 검색 (선택)
pip install sentence-transformers scikit-learn

# LLM 연동 (선택)
pip install openai
```

### FastAPI 실행 (선택)
```bash
pip install fastapi uvicorn
uvicorn api:app --reload --port 8000
```

#### API 사용 예시
```bash
# 헬스 체크
curl http://127.0.0.1:8000/health

# 파일 분석 (PDF/이미지 업로드)
curl -X POST "http://127.0.0.1:8000/analyze/file" ^
  -H "accept: application/json" ^
  -H "Content-Type: multipart/form-data" ^
  -F "file=@contract.pdf"
```

### 2. 환경 변수 설정

#### Windows (PowerShell)
```powershell
$env:UPSTAGE_API_KEY = "your-upstage-api-key"
$env:OPENAI_API_KEY = "your-openai-api-key"
```

#### Windows (Command Prompt)
```cmd
set UPSTAGE_API_KEY=your-upstage-api-key
set OPENAI_API_KEY=your-openai-api-key
```

#### Linux/Mac
```bash
export UPSTAGE_API_KEY=your-upstage-api-key
export OPENAI_API_KEY=your-openai-api-key
```

---

## 💻 사용 방법

### 입력 / 출력 구조

#### 입력
- 파일 업로드: PDF 또는 이미지 파일
- API 엔드포인트: `POST /analyze/file` (multipart/form-data, `file` 필드)

#### 출력 (JSON)
```json
{
  "contract_type": "jeonse",
  "summary": {
    "risk_level": "high",
    "total_clauses": 12,
    "risky_count": 3,
    "highlights": ["제5조: 보증금 반환 기한 불명확"]
  },
  "risky_clauses": [
    {
      "id": "clause_5",
      "article_num": "제5조",
      "title": "보증금 반환",
      "content": "...",
      "risk_level": "high",
      "risk_reason": "..."
    }
  ],
  "debate": {
    "transcript": [
      {"speaker": "갑", "content": "..."},
      {"speaker": "을", "content": "..."}
    ]
  },
  "report": "..."
}
```

### 기본 사용법

```python
from pipeline import ContractAnalysisPipeline

# 파이프라인 초기화
pipeline = ContractAnalysisPipeline()

# 계약서 분석
result = pipeline.analyze("contract.pdf")

# 결과 출력
print(f"총 조항: {len(result.clauses)}")
print(f"위험 조항: {len(result.risky_clauses)}")
print(f"\n{result.llm_summary}")

# 결과 저장
pipeline.export_result(result, "analysis_result.json")
```

### 각 단계별 사용

#### [1] OCR - 텍스트 추출
```python
from ocr import UpstageOCR, get_extracted_text

ocr = UpstageOCR()
result = ocr.extract_text_from_file("contract.pdf")
text = get_extracted_text(result)
```

#### [2] 텍스트 정제 & 조항 분리
```python
from text_processor import TextProcessor

processor = TextProcessor()
clauses = processor.split_clauses_with_fallback(raw_text)

for clause in clauses:
    print(f"{clause.article_num}: {clause.title}")
```

#### [3] 위험도 평가
```python
from risk_assessor import RiskAssessor

assessor = RiskAssessor()
risky_clauses = assessor.filter_risky_clauses(clauses)

for clause in risky_clauses:
    print(f"{clause.article_num} - 위험도: {clause.risk_level.value}")
```

### 토론 결과 사용
```python
from debate_agents import DebateAgents

debater = DebateAgents()
transcript = debater.run(risky_clauses, raw_text=raw_text, rounds=2)
```

---

## 📊 데이터 모델

### Clause (조항)
```python
@dataclass
class Clause:
    id: str                           # 조항 ID
    article_num: str                  # 조항 번호 (제1조, 제2조, ...)
    title: str                        # 조항 제목
    content: str                      # 조항 내용
    risk_level: Optional[RiskType]    # 위험도 (CRITICAL, HIGH, MEDIUM, LOW)
    risk_reason: Optional[str]        # 위험 이유
```

### Precedent (판례)
```python
@dataclass
class Precedent:
    case_id: str                      # 사건 ID
    court: str                        # 법원 이름
    date: str                         # 판결일
    case_name: str                    # 사건명
    summary: str                      # 판례 요지
    key_paragraph: str                # 핵심 문단
    similarity_score: Optional[float] # 유사도 (0~1)
```

### ContractAnalysisResult (분석 결과)
```python
@dataclass
class ContractAnalysisResult:
    filename: str
    raw_text: str
    clauses: List[Clause]
    risky_clauses: List[Clause]
    precedents: List[Precedent]
    llm_summary: Optional[str]
    debate_transcript: Optional[List[dict]]  # 갑/을 토론 로그
    contract_type: Optional[str]             # 전세/월세/매매/임대
```

---

## ⚠️ 위험 조항 카테고리

| 카테고리 | 설명 | 위험도 |
|---------|------|--------|
| **일방적_해지** | 일방적 계약 해지, 즉시 해지 | 🔴 CRITICAL |
| **무제한_배상** | 무제한 손해배상, 전액 배상 | 🔴 CRITICAL |
| **책임_회피** | 책임 없음, 면책, 배상 거부 | 🟡 HIGH |
| **강제_집행** | 강제 집행, 이의제기 불가 | 🟡 HIGH |
| **개인정보** | 개인정보 수집, 민감정보 | 🟡 HIGH |
| **불공정_조항** | 부당한 조건, 차별 조항 | 🟠 MEDIUM |

---

## 🧪 테스트

### 빠른 테스트
```cmd
cd c:\Users\noeun\CanSi\backend
set UPSTAGE_API_KEY=test-key
python -c "from text_processor import TextProcessor; from risk_assessor import RiskAssessor; ..."
```

### 테스트 결과
```
✓ 조항 분리: 3개 조항 추출
✓ 위험 조항 필터링: 2개 위험 조항
✓ 모든 테스트 완료!
```

---

## 🔧 향후 계획

- [ ] OpenAI API 연동 (GPT 기반 요약)
- [ ] 공공 판례 API 통합
- [ ] 프론트엔드 웹 인터페이스
- [ ] Docker 컨테이너화
- [ ] 대시보드 및 통계 분석

---

## 📝 파일 구조

```
backend/
├── api.py                    # FastAPI 엔드포인트
├── models.py                 # 데이터 모델
├── ocr.py                    # [1] OCR (Upstage)
├── text_processor.py         # [2] 텍스트 정제
├── risk_assessor.py          # [3] 위험도 평가
├── precedent_fetcher.py      # [4] 판례 수집
├── embedding_manager.py      # [5] 유사도 검색
├── risk_mapper.py            # [6] 위험 분류
├── debate_agents.py          # [7] 갑/을 토론
├── llm_summarizer.py         # [8] LLM 요약
├── openai_client.py          # OpenAI 클라이언트
├── pipeline.py               # 메인 파이프라인
└── README.md                 # 이 파일
```

---

## 📞 문제 해결

**UPSTAGE_API_KEY 에러**
→ 환경변수 설정 확인

**ModuleNotFoundError**
→ `pip install requests` 실행

**조항 분리 실패**
→ 계약서가 "제N조" 패턴을 따르는지 확인

---

## 📄 라이선스

CanSi © 2026. All rights reserved.
