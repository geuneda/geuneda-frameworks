---
name: geuneda-frameworks
description: Geuneda Unity 패키지 프레임워크 전체의 구조, 의존성, 개발/테스트 방법을 이해할 때 사용하는 스킬. 패키지 간 관계를 파악하고, 새 패키지를 추가하거나, 프레임워크 전체에 영향을 주는 변경을 할 때 활성화한다. 개별 패키지의 API 사용법은 해당 패키지의 스킬을 참조한다.
---

# Geuneda Frameworks

Geuneda Unity UPM 패키지들을 개발, 테스트, 검증하는 Unity 6 호스트 프로젝트. 10개의 독립 UPM 패키지로 구성된 프레임워크 생태계를 제공하며, 각 패키지는 독립적인 Git 저장소와 package.json을 가진다. 이 스킬은 프레임워크 전체를 이해하고 패키지 간 관계를 파악하는 데 사용된다.

## 활성화 시점

- Geuneda 프레임워크 전체 구조를 이해해야 할 때
- 패키지 간 의존성 관계를 파악해야 할 때
- 새로운 패키지를 프레임워크에 추가할 때
- 프레임워크 전체에 영향을 주는 변경(Unity 버전 업그레이드 등)을 할 때
- 어떤 패키지를 사용해야 할지 결정해야 할 때
- 패키지 개발 환경을 설정할 때
- 서브모듈 관련 Git 작업을 수행할 때

## 프로젝트 정보

- **프로젝트명**: geuneda-frameworks
- **Unity 버전**: 6000.0+
- **C# 버전**: C# 9.0 (명시적 네임스페이스, global usings 미사용)
- **저장소**: `https://github.com/geuneda/geuneda-frameworks.git`
- **소스 경로**: `/Users/teamsparta/Documents/GitHub/geuneda-frameworks/`
- **라이선스**: MIT
- **원본**: GameLovers Frameworks by Miguel Tomas

## 패키지 생태계

### 포함된 패키지 (10개)

| 패키지 | 패키지명 | 설명 | 저장소 |
|--------|----------|------|--------|
| **dataextensions** | `com.geuneda.dataextensions` | 데이터 타입 확장 유틸리티 | geuneda-dataextensions |
| **services** | `com.geuneda.services` | 게임 서비스 (DI, 메시지 브로커, 풀링) | geuneda-services |
| **uiservice** | `com.geuneda.uiservice` | UI 관리 서비스 (MVP 패턴) | geuneda-uiservice |
| **statechart** | `com.geuneda.statechart` | 상태머신 (HFSM) | geuneda-statechart |
| **configsprovider** | `com.geuneda.configsprovider` | 설정 제공자 | geuneda-configsprovider |
| **inputextensions** | `com.geuneda.inputextensions` | 입력 확장 | geuneda-inputextensions |
| **nativeui** | `com.geuneda.nativeui` | 네이티브 UI 헬퍼 | geuneda-nativeui |
| **notificationservice** | `com.geuneda.notificationservice` | 알림 서비스 | geuneda-notificationservice |
| **googlesheetimporter** | `com.geuneda.googlesheetimporter` | 구글 시트 임포터 | geuneda-googlesheetimporter |
| **assetsimporter** | `com.geuneda.assetsimporter` | 에셋 임포터 | geuneda-assetsimporter |

## 의존성 트리

```
dataextensions (기반 패키지 - 의존성 없음)
    |
    v
services (dataextensions 의존)
    |
    v
uiservice (services, UniTask, Addressables 의존)

statechart (독립)

configsprovider (독립)

inputextensions (Unity Input System 의존)

nativeui (독립, 플랫폼별 네이티브 코드)

notificationservice (Unity Mobile Notifications 의존)

googlesheetimporter (독립, Editor 전용)

assetsimporter (Addressables 의존)
```

### 핵심 의존 체인

가장 중요한 의존성 체인은 다음과 같다:

```
dataextensions -> services -> uiservice
```

이 세 패키지는 계층적으로 의존하므로, 하위 패키지 API 변경 시 상위 패키지에 영향을 준다.

### 외부 의존성

| 외부 패키지 | 버전 | 사용처 |
|-------------|------|--------|
| `com.unity.addressables` | 2.7.6+ | uiservice, assetsimporter |
| `com.cysharp.unitask` | latest | uiservice, services |
| `com.unity.inputsystem` | 1.17.0 | inputextensions |
| `com.unity.mobile.notifications` | 2.4.2 | notificationservice |
| `com.unity.test-framework` | 1.6.0 | 테스트 |
| `com.unity.ugui` | 2.0.0 | uiservice (Views) |

## 프로젝트 구조

```
geuneda-frameworks/
  Assets/
    Samples/              # 개발/테스트용 샘플 씬
  Packages/
    manifest.json         # 패키지 의존성 선언
    packages-lock.json    # 의존성 잠금 파일
    com.gamelovers.*/     # 서브모듈 (레거시 이름)
  ProjectSettings/        # Unity 프로젝트 설정
  UserSettings/           # 사용자별 설정
  .gitmodules             # 서브모듈 정의
  .vscode/                # VS Code 설정
  AGENTS.md               # AI 에이전트 가이드
  README.md               # 프로젝트 문서
  CONTRIBUTING.md         # 기여 가이드
  CODE_OF_CONDUCT.md      # 행동 강령
```

## 서브모듈 워크플로우

### 초기 설정

```bash
git clone https://github.com/geuneda/geuneda-frameworks.git
git submodule update --init --recursive
```

### 서브모듈 업데이트

```bash
# 모든 서브모듈을 최신으로
git submodule update --remote

# 특정 패키지만
cd Packages/com.gamelovers.services
git pull origin main
```

### 패키지 내 변경 작업

1. `Packages/<package-name>/` 디렉토리에서 직접 편집
2. 해당 패키지의 README.md/CHANGELOG.md 업데이트
3. 패키지 저장소에 별도로 커밋/푸시

### 서브모듈 이름 규칙

서브모듈 디렉토리는 `com.gamelovers.*` (레거시 이름)이고, manifest.json의 의존성은 `com.geuneda.*` (현재 이름)을 사용한다.

## 개발 가이드

### 코드 규칙

- C# 9.0 문법 사용
- 명시적 네임스페이스 사용 (global usings 금지)
- Runtime 코드에서 UnityEditor 참조 금지
- Editor 코드는 Editor/ 폴더 또는 Editor asmdef에 배치
- 외부 API 조사 시 `Library/PackageCache/`의 로컬 캐시 우선 참조

### 패키지별 AGENTS.md

일부 패키지는 자체 AGENTS.md를 포함한다. 해당 패키지 작업 시 그 파일이 최우선 참조 문서이다.

### 새 패키지 추가 절차

1. 독립 Git 저장소 생성
2. 표준 UPM 구조로 패키지 작성 (package.json, Runtime/, Editor/, Tests/)
3. `.gitmodules`에 서브모듈 추가
4. `Packages/manifest.json`에 의존성 추가
5. README.md에 패키지 정보 추가

### 테스트

- Unity Test Framework 1.6.0 사용
- Edit Mode 테스트: 순수 로직, 데이터 구조
- Play Mode 테스트: MonoBehaviour, 씬 전환, 비동기 동작
- 각 패키지는 자체 Tests/ 폴더를 가질 수 있음

## 패키지 설치 (개별 사용)

각 패키지는 독립적으로 사용할 수 있다.

```json
// Packages/manifest.json
{
  "dependencies": {
    "com.geuneda.dataextensions": "https://github.com/geuneda/geuneda-dataextensions.git",
    "com.geuneda.services": "https://github.com/geuneda/geuneda-services.git",
    "com.geuneda.uiservice": "https://github.com/geuneda/geuneda-uiservice.git"
  }
}
```

또는 Unity Package Manager > Add package from git URL 사용.

### 버전 고정

```
"com.geuneda.services": "https://github.com/geuneda/geuneda-services.git#v1.0.0"
```

## 패키지 역할 매트릭스

어떤 기능이 필요한지에 따라 적절한 패키지를 선택한다:

| 기능 | 사용할 패키지 |
|------|---------------|
| 데이터 타입 확장 (ObservableList 등) | dataextensions |
| 의존성 주입, 서비스 로케이터 | services |
| UI 생명주기 관리 (MVP) | uiservice |
| 상태머신 (계층적 FSM) | statechart |
| ScriptableObject 기반 설정 | configsprovider |
| Input System 확장 (드래그, 스와이프) | inputextensions |
| 네이티브 다이얼로그/토스트 | nativeui |
| 로컬/푸시 알림 | notificationservice |
| Google Sheets 데이터 임포트 | googlesheetimporter |
| Addressables 에셋 관리 | assetsimporter |

## 주의사항

- 서브모듈 디렉토리가 비어 있으면 `git submodule update --init --recursive` 실행
- 패키지 변경은 해당 패키지의 독립 저장소에 커밋하는 것을 권장
- manifest.json에서 `com.geuneda.*` 이름을 사용하지만, 서브모듈은 `com.gamelovers.*` 이름을 사용 (레거시)
- Runtime 코드에서 UnityEditor API를 참조하면 빌드 실패
- 패키지 간 순환 의존성은 절대 금지
- 하위 패키지(dataextensions)의 API 변경은 상위 패키지(services, uiservice)에 영향

## 참조 문서

패키지별 상세 API 및 의존성 맵은 `references/api.md` 참조.
개별 패키지의 API는 해당 패키지의 스킬을 참조:
- `geuneda-dataextensions` 스킬
- `geuneda-services` 스킬
- `geuneda-uiservice` 스킬
- `geuneda-statechart` 스킬
- `geuneda-inputextensions` 스킬
- `geuneda-nativeui` 스킬
- `geuneda-notificationservice` 스킬
- `geuneda-googlesheetimporter` 스킬
- `geuneda-assetsimporter` 스킬
