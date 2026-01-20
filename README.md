---
# MainProject
---
# CanSi

#### *Can I Sign This?*

> **AI 기반 계약서 분석 서비스**

---

## 📌 프로젝트 소개

CanSi는
법률 지식이 없는 일반 사용자도 **안심하고 계약에 서명할 수 있도록**
OCR과 AI를 활용해 **계약서를 분석**하고,

* ❗ 사용자에게 **불리한 조항을 탐지**
* ✅ **유리한 조건을 제안**
* 📖 어려운 법률 문장을 **이해하기 쉬운 언어로 설명**

해주는 **계약 보호 AI 서비스**입니다.

---

## 🎯 프로젝트 목적

* 계약서의 **정보 비대칭 문제 해결**
* 법을 몰라서 발생하는 **불공정 계약 예방**
* 전문가 도움 없이도 **사전 리스크 인지 가능**

> ✨ *“사인하기 전에, AI에게 한 번 더 묻다”*
>
> ---

## 📎 기타

* 본 프로젝트는 **AIX 3기 Bootcamp 메인 프로젝트**입니다.
* 협업 및 문서 관리는 **Notion**을 통해 진행합니다.

---

✨ **CanSi — Can I Sign This?**
*당신의 계약을, AI가 먼저 읽어드립니다.*

---

## 🧑‍🤝‍🧑 팀 구성 및 역할

### 🔹 기획 · 문서

* 장예슬, 노은찬, 김영우

📊 데이터 수집

* 노은찬, 장예슬, 박상현

### 🎨 UI / UX

* 장예슬,조성현

### 💻 Frontend

* 조성현, 장예슬 , 박상현

### ⚙️ Backend

* 김영우, 노은찬, 조성현, 박상현

### 🗄 Database

* 노은찬, 박상현, 조성현

### 🌐 Domain

* 김영우


### 🤖 AI / Model

* 박상현, 노은찬

### 🔧 Git / Docker

* 박상현, 노은찬

###


## 📁 프로젝트 구조

본 프로젝트는 **모노레포(Monorepo) 구조**로 구성되어 있으며,
각 영역을 역할별로 분리하여 개발 및 배포 효율성을 높였습니다.

```
mobaextreme/
├─ frontend/              # Flutter 기반 사용자 애플리케이션
├─ backend/               # OCR · AI · API 서버 (Python)
├─ realtime/              # 실시간 처리 / WebSocket 서버
├─ docker-compose.yml     # 전체 서비스 통합 실행 설정
└─ README.md              # 프로젝트 전체 문서
```

* **frontend/**
  사용자와 직접 상호작용하는 모바일 UI 영역

* **backend/**
  계약서 OCR 처리, AI 분석, 비즈니스 로직 및 API 제공

* **realtime/**
  분석 진행 상태, 실시간 알림 등을 위한 실시간 처리 서버

* **docker-compose.yml**
  모든 서비스를 한 번에 실행·관리하기 위한 Docker 설정 파일

---

## 🛠 기술 스택

| 구분            | 기술                      |
| ------------- | ----------------------- |
| Frontend      | Flutter, Android Studio |
| Backend       | Python                  |
| OCR           | Upstage OCR             |
| Database      | SQL                     |
| DevOps        | Docker                  |
| Collaboration | Git, Notion             |
| Environment   | WSL2 (Ubuntu 20.04)     |

---


## ⚙️ 개발 환경 설정 (WSL2)

### 1️⃣ PowerShell 관리자 실행

---

### 2️⃣ Linux용 Windows 하위 시스템 활성화

```bash
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

---

### 3️⃣ WSL 설치

```bash
wsl.exe --install
```

---

### 4️⃣ WSL 최신 버전 업데이트

```bash
wsl.exe --update
```

---

### 5️⃣ WSL2 기본 버전 설정

```bash
wsl --set-default-version 2
```

---

### 6️⃣ Ubuntu 20.04 설치

```bash
wsl --install -d Ubuntu-20.04
```

---

### 7️⃣ Ubuntu 실행

```bash
wsl -d Ubuntu-20.04
```

---

### 8️⃣ 설치 확인

```bash
wsl -l -v
```


