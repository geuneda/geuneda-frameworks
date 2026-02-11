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
   |dataextensions|
   +----+--------+
        |
   +----v----+
   | uiservice|  <-- services + UniTask + Addressables
   +----------+

   +-----------+     +------------------+     +-------------+
   | statechart|     | configsprovider  |     |   nativeui  |
   +-----------+     +------------------+     +-------------+
   (독립)              (독립)                    (독립)

   +---------------------+     +--------------------+
   | notificationservice |     | googlesheetimporter|
   +---------------------+     +--------------------+
   (Mobile Notifications)       (독립, Editor 전용)
```

## 패키지별 상세 정보

### 1. com.geuneda.dataextensions

**역할**: 데이터 타입 확장 유틸리티
**의존성**: 없음 (기반 패키지)
**의존하는 패키지**: services
**네임스페이스**: `Geuneda.DataExtensions`
**저장소**: `https://github.com/geuneda/geuneda-dataextensions.git`
**서브모듈 경로**: `Packages/com.gamelovers.dataextensions`

주요 기능:
- Observable 컬렉션 (ObservableList, ObservableDictionary 등)
- 데이터 타입 확장 메서드
- 직렬화 유틸리티

---

### 2. com.geuneda.services

**역할**: 게임 서비스 (DI, 메시지 브로커, 오브젝트 풀링)
**의존성**: dataextensions
**의존하는 패키지**: uiservice
**네임스페이스**: `Geuneda.Services`
**저장소**: `https://github.com/geuneda/geuneda-services.git`
**서브모듈 경로**: `Packages/com.gamelovers.services`

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
**서브모듈 경로**: `Packages/com.gamelovers.uiservice`

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
**서브모듈 경로**: `Packages/com.gamelovers.statechart`

주요 기능:
- 상태 정의 및 전환
- 계층적 상태 (중첩 상태)
- Guard 조건
- 진입/종료 액션

---

### 5. com.geuneda.configsprovider

**역할**: 설정 제공자
**의존성**: 없음
**의존하는 패키지**: 없음
**네임스페이스**: `Geuneda.ConfigsProvider`
**저장소**: `https://github.com/geuneda/geuneda-configsprovider.git`
**서브모듈 경로**: `Packages/com.gamelovers.configsprovider`

주요 기능:
- ScriptableObject 기반 설정 관리
- 설정 데이터 제공 시스템

---

### 6. com.geuneda.inputextensions

**역할**: Unity Input System 확장
**의존성**: Unity Input System 1.17.0
**의존하는 패키지**: 없음
**네임스페이스**: `Geuneda.InputExtensions`
**저장소**: `https://github.com/geuneda/geuneda-inputextensions.git`
**서브모듈 경로**: `Packages/com.gamelovers.inputextensions`

주요 기능:
- 포인터 드래그 처리
- 스와이프 제스처 감지
- 탭 제스처 감지
- 게임패드 입력 확장

---

### 7. com.geuneda.nativeui

**역할**: 네이티브 UI 헬퍼 (iOS/Android)
**의존성**: 없음
**의존하는 패키지**: 없음
**네임스페이스**: `Geuneda.NativeUi`
**저장소**: `https://github.com/geuneda/geuneda-nativeui.git`
**서브모듈 경로**: `Packages/com.gamelovers.nativeui`

주요 기능:
- 네이티브 알림 다이얼로그
- 토스트 메시지
- 플랫폼별 UI 인터랙션

---

### 8. com.geuneda.notificationservice

**역할**: 알림 서비스 (로컬/푸시)
**의존성**: Unity Mobile Notifications 2.4.2
**의존하는 패키지**: 없음
**네임스페이스**: `Geuneda.NotificationService`
**저장소**: `https://github.com/geuneda/geuneda-notificationservice.git`
**서브모듈 경로**: `Packages/com.gamelovers.notificationservice`

주요 기능:
- 로컬 알림 예약/취소
- 원격 알림 수신
- 알림 채널 관리

---

### 9. com.geuneda.googlesheetimporter

**역할**: Google Sheets 데이터 임포터 (Editor 전용)
**의존성**: 없음
**의존하는 패키지**: 없음
**네임스페이스**: `Geuneda.GoogleSheetImporter`
**저장소**: `https://github.com/geuneda/geuneda-googlesheetimporter.git`
**서브모듈 경로**: `Packages/com.gamelovers.googlesheetimporter`

주요 기능:
- Google Sheets에서 게임 데이터 임포트
- ScriptableObject로 자동 변환
- Editor 메뉴 통합

---

### 10. com.geuneda.assetsimporter

**역할**: 에셋 임포터 (Addressables 기반)
**의존성**: Unity Addressables 2.7.6+
**의존하는 패키지**: 없음
**네임스페이스**: `Geuneda.AssetsImporter`
**저장소**: `https://github.com/geuneda/geuneda-assetsimporter.git`
**서브모듈 경로**: `Packages/com.gamelovers.assetsimporter`

주요 기능:
- Addressables 에셋 로드/인스턴스화/언로드
- 씬 관리
- 에셋 설정 임포트

---

## manifest.json 전체 의존성

```json
{
  "dependencies": {
    // Geuneda 패키지
    "com.geuneda.dataextensions": "https://github.com/geuneda/geuneda-dataextensions.git",
    "com.geuneda.services": "https://github.com/geuneda/geuneda-services.git",
    "com.geuneda.uiservice": "https://github.com/geuneda/geuneda-uiservice.git",
    "com.geuneda.statechart": "https://github.com/geuneda/geuneda-statechart.git",
    "com.geuneda.configsprovider": "https://github.com/geuneda/geuneda-configsprovider.git",
    "com.geuneda.inputextensions": "https://github.com/geuneda/geuneda-inputextensions.git",
    "com.geuneda.nativeui": "https://github.com/geuneda/geuneda-nativeui.git",
    "com.geuneda.notificationservice": "https://github.com/geuneda/geuneda-notificationservice.git",
    "com.geuneda.googlesheetimporter": "https://github.com/geuneda/geuneda-googlesheetimporter.git",
    "com.geuneda.assetsimporter": "https://github.com/geuneda/geuneda-assetsimporter.git",
    // 외부 의존성
    "com.cysharp.unitask": "https://github.com/Cysharp/UniTask.git?path=src/UniTask/Assets/Plugins/UniTask",
    "com.unity.addressables": "2.7.6",
    "com.unity.editorcoroutines": "1.0.1",
    "com.unity.ext.nunit": "2.0.5",
    "com.unity.ide.rider": "3.0.38",
    "com.unity.ide.visualstudio": "2.0.26",
    "com.unity.inputsystem": "1.17.0",
    "com.unity.mobile.notifications": "2.4.2",
    "com.unity.test-framework": "1.6.0",
    "com.unity.ugui": "2.0.0",
    // Unity 모듈
    "com.unity.modules.animation": "1.0.0",
    "com.unity.modules.assetbundle": "1.0.0",
    "com.unity.modules.audio": "1.0.0",
    "com.unity.modules.imgui": "1.0.0",
    "com.unity.modules.jsonserialize": "1.0.0",
    "com.unity.modules.ui": "1.0.0",
    "com.unity.modules.uielements": "1.0.0",
    "com.unity.modules.unitywebrequest": "1.0.0"
  }
}
```

## 서브모듈 매핑

`.gitmodules` 파일에 정의된 서브모듈과 manifest.json의 패키지 이름 매핑:

| 서브모듈 경로 | 원본 저장소 (레거시) | manifest 패키지명 |
|---------------|---------------------|-------------------|
| `Packages/com.gamelovers.dataextensions` | Unity-DataTypeExtensions | `com.geuneda.dataextensions` |
| `Packages/com.gamelovers.services` | Services | `com.geuneda.services` |
| `Packages/com.gamelovers.uiservice` | com.gamelovers.uiservice | `com.geuneda.uiservice` |
| `Packages/com.gamelovers.statechart` | Statechart-HFSM | `com.geuneda.statechart` |
| `Packages/com.gamelovers.configsprovider` | Unity-ConfigsProvider | `com.geuneda.configsprovider` |
| `Packages/com.gamelovers.inputextensions` | com.gamelovers.inputextensions | `com.geuneda.inputextensions` |
| `Packages/com.gamelovers.nativeui` | com.gamelovers.nativeui | `com.geuneda.nativeui` |
| `Packages/com.gamelovers.notificationservice` | com.gamelovers.notificationservice | `com.geuneda.notificationservice` |
| `Packages/com.gamelovers.googlesheetimporter` | Unity-GoogleSheet-Importer | `com.geuneda.googlesheetimporter` |
| `Packages/com.gamelovers.assetsimporter` | Unity-AssetsImporter | `com.geuneda.assetsimporter` |

## 패키지 카테고리별 분류

### 핵심 패키지 (Core)
대부분의 프로젝트에서 사용:
- `dataextensions` - 기반 유틸리티
- `services` - DI, 메시지, 풀링
- `uiservice` - UI 관리

### 게임플레이 패키지 (Gameplay)
게임 로직에 직접 사용:
- `statechart` - 상태 머신
- `inputextensions` - 입력 처리
- `configsprovider` - 설정 관리

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
  "com.geuneda.dataextensions": "...",
  "com.geuneda.services": "..."
}
```

### 표준 구성 (UI 포함 게임)
```json
{
  "com.geuneda.dataextensions": "...",
  "com.geuneda.services": "...",
  "com.geuneda.uiservice": "...",
  "com.geuneda.statechart": "...",
  "com.geuneda.assetsimporter": "..."
}
```

### 풀 구성 (모바일 게임)
```json
{
  "com.geuneda.dataextensions": "...",
  "com.geuneda.services": "...",
  "com.geuneda.uiservice": "...",
  "com.geuneda.statechart": "...",
  "com.geuneda.assetsimporter": "...",
  "com.geuneda.inputextensions": "...",
  "com.geuneda.nativeui": "...",
  "com.geuneda.notificationservice": "...",
  "com.geuneda.configsprovider": "...",
  "com.geuneda.googlesheetimporter": "..."
}
```
