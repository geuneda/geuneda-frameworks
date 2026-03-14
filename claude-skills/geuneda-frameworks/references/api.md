# Geuneda Frameworks - 패키지 의존성 맵 및 참조

## 패키지 의존성 전체 맵

### 시각적 의존성 다이어그램

```
                    +-----------------------+
                    |    Unity 6000.0+      |
                    +-----------+-----------+
                                |
        +-----------------------+-----------------------+
        |                       |                       |
   +----v----+           +------v------+         +------v------+
   | UniTask  |           | Addressables|         | Input System|
   +----+----+           +------+------+         +------+------+
        |                       |                       |
   +----v----+           +------v------+         +------v------+
   | services |           | assetsimporter|       |inputextensions|
   +----+----+           +--------------+        +--------------+
        |
   +----v-------+
   |  gamedata   |
   +----+--------+
        |
   +----v----+
   | uiservice|  <-- services + UniTask + Addressables
   +----------+

   +-----------+     +-------------+
   | statechart|     |   nativeui  |
   +-----------+     +-------------+
   (독립)              (독립)

   +---------------------+     +--------------------+
   | notificationservice |     | googlesheetimporter|
   +---------------------+     +--------------------+
   (Mobile Notifications)       (독립, Editor 전용)
```

## 패키지별 상세 정보

### 1. com.geuneda.gamedata

**역할**: 게임 데이터 (Observable, ConfigsProvider, floatP)
**의존성**: Newtonsoft.Json, UniTask, TextMeshPro
**의존하는 패키지**: services
**네임스페이스**: `Geuneda.DataExtensions`
**어셈블리**: `Geuneda.GameData` (Runtime), `Geuneda.GameData.Editor` (Editor)
**저장소**: `https://github.com/geuneda/geuneda-gamedata.git`
**서브모듈 경로**: `Packages/com.geuneda.gamedata`

> 참고: 기존 `com.geuneda.dataextensions`와 `com.geuneda.configsprovider`가 통합된 패키지이다.

주요 기능:
- Observable 컬렉션 (ObservableField, ObservableList, ObservableDictionary 등)
- ComputedField (의존성 추적 기반 파생 값)
- ConfigsProvider (타입 안전 설정 저장소)
- ConfigsSerializer (JSON 직렬화/역직렬화)
- floatP / MathfloatP (결정론적 부동소수점)
- Unity 직렬화 헬퍼 (UnitySerializedDictionary, EnumSelector)

---

### 2. com.geuneda.services

**역할**: 게임 서비스 (DI, 메시지 브로커, 오브젝트 풀링)
**의존성**: gamedata
**의존하는 패키지**: uiservice
**네임스페이스**: `Geuneda.Services`
**저장소**: `https://github.com/geuneda/geuneda-services.git`
**서브모듈 경로**: `Packages/com.geuneda.services`

주요 기능:
- 서비스 로케이터 / 의존성 주입
- 메시지 브로커 (이벤트 시스템)
- 오브젝트 풀링
- 틱 시스템

---

### 3. com.geuneda.uiservice

**역할**: UI 관리 서비스 (MVP 패턴)
**의존성**: services, UniTask 2.5.10+, Addressables 2.6.0+
**의존하는 패키지**: 없음 (최상위)
**네임스페이스**: `Geuneda.UiService`, `Geuneda.UiService.Views`
**저장소**: `https://github.com/geuneda/geuneda-uiservice.git`
**서브모듈 경로**: `Packages/com.geuneda.uiservice`

주요 기능:
- UI 프레젠터 생명주기 관리
- 피처 조합 시스템
- UI Toolkit 통합
- 다양한 에셋 로딩 전략
- UI 세트 (그룹 관리)
- 다중 인스턴스 지원

---

### 4. com.geuneda.statechart

**역할**: 계층적 유한 상태 머신 (HFSM)
**의존성**: 없음
**의존하는 패키지**: 없음
**네임스페이스**: `Geuneda.Statechart`
**저장소**: `https://github.com/geuneda/geuneda-statechart.git`
**서브모듈 경로**: `Packages/com.geuneda.statechart`

주요 기능:
- 상태 정의 및 전환
- 계층적 상태 (중첩 상태)
- Guard 조건
- 진입/종료 액션

---

### 5. com.geuneda.inputextensions

**역할**: Unity Input System 확장
**의존성**: Unity Input System 1.17.0
**의존하는 패키지**: 없음
**네임스페이스**: `Geuneda.InputExtensions`
**저장소**: `https://github.com/geuneda/geuneda-inputextensions.git`
**서브모듈 경로**: `Packages/com.geuneda.inputextensions`

주요 기능:
- 포인터 드래그 처리
- 스와이프 제스처 감지
- 탭 제스처 감지
- 게임패드 입력 확장

---

### 6. com.geuneda.nativeui

**역할**: 네이티브 UI 헬퍼 (iOS/Android)
**의존성**: 없음
**의존하는 패키지**: 없음
**네임스페이스**: `Geuneda.NativeUi`
**저장소**: `https://github.com/geuneda/geuneda-nativeui.git`
**서브모듈 경로**: `Packages/com.geuneda.nativeui`

주요 기능:
- 네이티브 알림 다이얼로그
- 토스트 메시지
- 플랫폼별 UI 인터랙션

---

### 7. com.geuneda.notificationservice

**역할**: 알림 서비스 (로컬/푸시)
**의존성**: Unity Mobile Notifications 2.4.2
**의존하는 패키지**: 없음
**네임스페이스**: `Geuneda.NotificationService`
**저장소**: `https://github.com/geuneda/geuneda-notificationservice.git`
**서브모듈 경로**: `Packages/com.geuneda.notificationservice`

주요 기능:
- 로컬 알림 예약/취소
- 원격 알림 수신
- 알림 채널 관리

---

### 8. com.geuneda.googlesheetimporter

**역할**: Google Sheets 데이터 임포터 (Editor 전용)
**의존성**: 없음
**의존하는 패키지**: 없음
**네임스페이스**: `Geuneda.GoogleSheetImporter`
**저장소**: `https://github.com/geuneda/geuneda-googlesheetimporter.git`
**서브모듈 경로**: `Packages/com.geuneda.googlesheetimporter`

주요 기능:
- Google Sheets에서 게임 데이터 임포트
- ScriptableObject로 자동 변환
- Editor 메뉴 통합

---

### 9. com.geuneda.assetsimporter

**역할**: 에셋 임포터 (Addressables 기반)
**의존성**: Unity Addressables 2.7.6+
**의존하는 패키지**: 없음
**네임스페이스**: `Geuneda.AssetsImporter`
**저장소**: `https://github.com/geuneda/geuneda-assetsimporter.git`
**서브모듈 경로**: `Packages/com.geuneda.assetsimporter`

주요 기능:
- Addressables 에셋 로드/인스턴스화/언로드
- 씬 관리
- 에셋 설정 임포트

---

## manifest.json 전체 의존성

```json
{
  "dependencies": {
    "com.geuneda.gamedata": "https://github.com/geuneda/geuneda-gamedata.git",
    "com.geuneda.services": "https://github.com/geuneda/geuneda-services.git",
    "com.geuneda.uiservice": "https://github.com/geuneda/geuneda-uiservice.git",
    "com.geuneda.statechart": "https://github.com/geuneda/geuneda-statechart.git",
    "com.geuneda.inputextensions": "https://github.com/geuneda/geuneda-inputextensions.git",
    "com.geuneda.nativeui": "https://github.com/geuneda/geuneda-nativeui.git",
    "com.geuneda.notificationservice": "https://github.com/geuneda/geuneda-notificationservice.git",
    "com.geuneda.googlesheetimporter": "https://github.com/geuneda/geuneda-googlesheetimporter.git",
    "com.geuneda.assetsimporter": "https://github.com/geuneda/geuneda-assetsimporter.git",
    "com.cysharp.unitask": "https://github.com/Cysharp/UniTask.git?path=src/UniTask/Assets/Plugins/UniTask",
    "com.unity.addressables": "2.7.6",
    "com.unity.inputsystem": "1.17.0",
    "com.unity.mobile.notifications": "2.4.2",
    "com.unity.test-framework": "1.6.0",
    "com.unity.ugui": "2.0.0"
  }
}
```

## 패키지 카테고리별 분류

### 핵심 패키지 (Core)
대부분의 프로젝트에서 사용:
- `gamedata` - 기반 유틸리티 (Observable, ConfigsProvider, floatP)
- `services` - DI, 메시지, 풀링
- `uiservice` - UI 관리

### 게임플레이 패키지 (Gameplay)
게임 로직에 직접 사용:
- `statechart` - 상태 머신
- `inputextensions` - 입력 처리

### 인프라 패키지 (Infrastructure)
빌드, 에셋, 데이터 파이프라인:
- `assetsimporter` - 에셋 로딩
- `googlesheetimporter` - 데이터 임포트 (Editor 전용)

### 플랫폼 패키지 (Platform)
모바일/네이티브 기능:
- `nativeui` - 네이티브 다이얼로그
- `notificationservice` - 알림

## 일반적인 프로젝트 구성 예시

### 최소 구성 (기본 게임)
```json
{
  "com.geuneda.gamedata": "...",
  "com.geuneda.services": "..."
}
```

### 표준 구성 (UI 포함 게임)
```json
{
  "com.geuneda.gamedata": "...",
  "com.geuneda.services": "...",
  "com.geuneda.uiservice": "...",
  "com.geuneda.statechart": "...",
  "com.geuneda.assetsimporter": "..."
}
```

### 풀 구성 (모바일 게임)
```json
{
  "com.geuneda.gamedata": "...",
  "com.geuneda.services": "...",
  "com.geuneda.uiservice": "...",
  "com.geuneda.statechart": "...",
  "com.geuneda.assetsimporter": "...",
  "com.geuneda.inputextensions": "...",
  "com.geuneda.nativeui": "...",
  "com.geuneda.notificationservice": "...",
  "com.geuneda.googlesheetimporter": "..."
}
```
