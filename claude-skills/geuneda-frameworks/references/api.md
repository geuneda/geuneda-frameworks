# Geuneda Frameworks - 패키지별 상세 카드

모든 값은 2026-10-12 시점 각 패키지의 `package.json` 과 asmdef 기준이다. 작업 전에 해당 파일로 다시 확인한다. 의존성 그래프와 설치 규칙은 `SKILL.md` 를 본다.

공통:
- 레포: `https://github.com/geuneda/geuneda-<패키지>.git`
- 서브모듈 경로: `Packages/com.geuneda.<패키지>`
- 기본 브랜치: core 와 gamesystems 는 `main`, 나머지는 `master`

---

## 1. com.geuneda.gamedata

- **버전 / 최소 Unity**: 1.0.4 / 6000.0
- **package.json 의존성**: `com.unity.nuget.newtonsoft-json` 3.2.1, `com.cysharp.unitask` 2.5.10, `com.unity.ugui` 2.0.0
- **이 패키지에 의존하는 패키지**: services, googlesheetimporter
- **어셈블리**: `Geuneda.GameData`(Runtime, `UniTask` + `Newtonsoft.Json.dll` 참조, `allowUnsafeCode`), `Geuneda.GameData.Editor`(Editor)
- **네임스페이스**: `Geuneda.DataExtensions`(Runtime), `Geuneda.DataExtensions.Editor` 와 `GeunedaEditor.GameData`(Editor)
- **주요 기능**:
  - Observable: `ObservableField`, `ObservableList`, `ObservableDictionary`, `ObservableHashSet`, Resolver 변형, `ObservableBatch`, `ComputedField`
  - 설정: `ConfigsProvider`, `ConfigsSerializer`, `ConfigsScriptableObject`, `IConfigBackendService`
  - 결정론적 수학: `floatP`, `MathfloatP`
  - 직렬화/유틸: `UnitySerializedDictionary`, `SerializableType`, `EnumSelector`, JSON 컨버터, 검증 어트리뷰트
  - 에디터: Config Browser, Observable Debug 창, 스키마 마이그레이션(`MigrationRunner`)
- **샘플**: Reactive UI Demo (uGUI), Reactive UI Demo (UI Toolkit), Designer Workflow, Migration
- **테스트**: `Geuneda.GameData.Editor.Tests`(`Tests/Editor`), `Geuneda.GameData.PlayMode.Tests`(`Tests/PlayMode`)
- **문서**: `README.md`

---

## 2. com.geuneda.services

- **버전 / 최소 Unity**: 2.1.4 / 6000.3
- **package.json 의존성**: `com.geuneda.gamedata` 1.0.0, `com.unity.addressables` 1.21.20, `com.cysharp.unitask` 2.5.10
- **이 패키지에 의존하는 패키지**: gamesystems
- **어셈블리**: `Geuneda.Services`(Runtime, `Geuneda.GameData` 와 Addressables/UniTask 계열 참조), `Geuneda.Services.Editor`(Editor)
- **네임스페이스**:
  - `Geuneda.Services`: `MainInstaller`, `Installer`, `MessageBrokerService`, `TickService`, `CoroutineService`, `PoolService`, `DataService`, `RngService`, `TimeService`, `CommandService<>`, `VersionServices`, `AssetResolverService`
  - `Geuneda.Services.Pooling`: `IPoolService`, `IObjectPool<T>`, `ObjectPool<T>`, `GameObjectPool`, `GameObjectPool<T>`, `IPoolEntitySpawn`, `IPoolEntityDespawn` 등
  - `Geuneda.Services.Commands`: `IGameCommand<>`, `ICommandService<>` 등 커맨드 계약
  - `Geuneda.Services.AssetsImporter`: `IAssetLoader`, `ISceneLoader`, `AddressablesAssetLoader`, `AssetConfigsScriptableObject<TId,TAsset>`, `AddressableConfig`, `AssetReferenceScene`
  - Editor: `Geuneda.Services.Editor.Explorer`, `Geuneda.Services.Versioning.Editor`, `Geuneda.Services.AssetsImporter.Editor`, `Geuneda.Services.AddressableIds.Editor`, `Geuneda.Services.Inspectors.Editor`, `Geuneda.Services.Scaffolders.Editor`
- **에디터 도구**: `Tools > Geuneda > Services Explorer`, `Tools > Geuneda > Assets Importer / Addressable Ids / Versioning` 메뉴, `Assets > Create > Geuneda Services` 스캐폴더
- **흡수 이력**: `com.geuneda.assetsimporter` v0.5.2 를 v2.0.0 에서 흡수. 별도 패키지로 함께 넣지 않는다. 옛 `Geuneda.AssetsImporter.*` 네임스페이스는 `Geuneda.Services.AssetsImporter.*` 로, `AssetResolverService` 는 `Geuneda.Services` 로 옮겨졌다.
- **테스트**: `Geuneda.Services.Editor.Tests`(`Tests/EditMode`), `Geuneda.Services.Tests.Playmode`(`Tests/PlayMode`)
- **문서**: `README.md`, `docs/`(서비스별 문서), `MIGRATION.md`, `AGENTS.md`, `CLAUDE.md`, `Tests/AGENTS.md`

---

## 3. com.geuneda.uiservice

- **버전 / 최소 Unity**: 1.3.2 / 6000.0
- **package.json 의존성**: `com.unity.addressables` 2.6.0, `com.cysharp.unitask` 2.5.10, `com.unity.ugui` 2.0.0
- **이 패키지에 의존하는 패키지**: 없음. gamedata/services 에도 의존하지 않는다.
- **어셈블리**: `Geuneda.UiService`(Runtime), `Geuneda.UiService.Editor`(Editor)
- **네임스페이스**: `Geuneda.UiService`, `Geuneda.UiService.Views`, `GeunedaEditor.UiService`(Editor)
- **주요 기능**: `UiService`/`IUiService`, `UiPresenter`, UI Set(`UiSetConfig`), 프레젠터 피처(`TimeDelayFeature`, `AnimationDelayFeature`, `UiToolkitPresenterFeature` 등), 에셋 로더(Addressables, Resources, Prefab Registry), 다중 인스턴스(`UiInstanceId`)
- **테스트**: `Geuneda.UiService.Tests`(`Tests/EditMode`), `Geuneda.UiService.Tests.PlayMode`(`Tests/PlayMode`)
- **문서**: `README.md`, `docs/`(getting-started, core-concepts, api-reference, advanced, troubleshooting), `AGENTS.md`

---

## 4. com.geuneda.statechart

- **버전 / 최소 Unity**: 0.9.6 / 2022.3
- **package.json 의존성**: `com.cysharp.unitask` 2.5.10
- **어셈블리**: `Geuneda.Statechart`
- **네임스페이스**: `Geuneda.StatechartMachine`(내부 구현은 `Geuneda.StatechartMachine.Internal`)
- **주요 기능**: `Statechart`, `IStateFactory` 로 상태 구성. Simple, Nest, Split, Choice, Wait, TaskWait, Leave, Initial, Final 상태, `StatechartEvent` 기반 전환
- **테스트**: `Geuneda.Statechart.Editor.Tests`(`Tests/Editor`)
- **문서**: `README.md`

---

## 5. com.geuneda.inputextensions

- **버전 / 최소 Unity**: 1.0.4 / 2019.4
- **package.json 의존성**: `com.unity.inputsystem` 1.1.1, `com.unity.ugui` 1.0.0
- **어셈블리**: `Geuneda.InputExtensions`
- **네임스페이스**: `Input`, `Input.Controls`(어셈블리 이름과 다르다. `Input` 이 `UnityEngine.Input` 을 가린다)
- **주요 기능**: `PointerInputManager`(드래그), `GestureController`(스와이프/탭), `GamepadInputManager`, `.inputactions` 생성 래퍼 `PointerControls`/`GamepadControls`
- **테스트**: 없음
- **문서**: `README.md`

---

## 6. com.geuneda.nativeui

- **버전 / 최소 Unity**: 0.2.7 / 2020.3
- **package.json 의존성**: 없음
- **어셈블리**: `Geuneda.NativeUi`(iOS 네이티브 코드 `Runtime/Plugins/iOS/NativeUi.m` 포함)
- **네임스페이스**: `Geuneda.NativeUi`
- **주요 기능**: `NativeUiService.ShowAlertPopUp`, `NativeUiService.ShowToastMessage`(iOS/Android, 에디터에서는 로그만)
- **테스트**: 없음
- **문서**: `README.md`

---

## 7. com.geuneda.notificationservice

- **버전 / 최소 Unity**: 0.1.9 / 2021.3
- **package.json 의존성**: `com.unity.mobile.notifications` 2.4.2
- **어셈블리**: `Geuneda.NotificationService`
- **네임스페이스**: `Geuneda.NotificationService`
- **주요 기능**: `MobileNotificationService`(알림 생성/예약/취소/해제, 앱 안 알림 설정 `IsEnabled`, OS 권한 `Permission`/`RequestPermission`), `GameNotificationChannel`, Android/iOS 플랫폼 구현
- **테스트**: PlayMode `Geuneda.NotificationService.Tests.PlayMode`
- **문서**: `README.md`

---

## 8. com.geuneda.googlesheetimporter

- **버전 / 최소 Unity**: 0.9.1 / 6000.0 (`type: tool`)
- **package.json 의존성**: `com.unity.nuget.newtonsoft-json` 2.0.0, `com.geuneda.gamedata` 1.0.0
- **어셈블리**: `Geuneda.GoogleSheetImporter`(Runtime, `Geuneda.GameData` 참조), `Geuneda.GoogleSheetImporter.Editor`(Editor)
- **네임스페이스**: `Geuneda.GoogleSheetImporter`(Runtime: `CsvParser`, `ParseIgnoreAttribute`), `GeunedaEditor.GoogleSheetImporter`(Editor: 임포터)
- **주요 기능**: Google 스프레드시트를 ScriptableObject 설정 데이터로 임포트. 진입점은 `Assets > Create > ScriptableObjects > Editor > GoogleSheetImporter`, `Tools > GoogleSheet Importer > Import Google Sheet Data`, `Tools > GoogleSheet Importer > Select GoogleSheetImporter.asset`
- **샘플**: Importers Example
- **테스트**: `Geuneda.GoogleSheetImporter.Editor.Tests`(`Tests/Editor`)
- **문서**: `README.md`

---

## 9. com.geuneda.gamesystems

- **버전 / 최소 Unity**: 0.2.1 / 6000.3
- **package.json 의존성**: `com.geuneda.services` 2.1.0
- **어셈블리**: 기능마다 하나. 현재 `Geuneda.GameSystems.RedDot`(`Geuneda.Services` 참조)
- **네임스페이스**: `Geuneda.GameSystems.<기능>`, 현재 `Geuneda.GameSystems.RedDot`
- **주요 기능**: 레드닷. '/' 경로 트리 알림 배지, 리프 값의 조상 합산, 뮤트, 경로 단위 구독(`IRedDotService`, `RedDotService`, `RedDotBinding`, `RedDotView`)
- **테스트**: `Geuneda.GameSystems.Tests.EditMode`(`Tests/EditMode`), `Geuneda.GameSystems.Tests.PlayMode`(`Tests/PlayMode`)
- **문서**: `README.md`, `AGENTS.md`, `CLAUDE.md`

---

## 10. com.geuneda.core

- **버전 / 최소 Unity**: 0.1.0 / 2021.3
- **package.json 의존성**: 없음
- **어셈블리**: `Geuneda.Core`
- **네임스페이스**: `Geuneda.Core`
- **주요 기능**: 모듈별 로거(`ModuleLogger`, `LogLevel`, `Log.Sink`/`ILogSink`, `UnityConsoleSink`), 결과 규약(`Result`, `Result<T>`, `ResultCodes`, 패키지별 코드 범위)
- **테스트**: EditMode `Geuneda.Core.Tests.EditMode`
- **문서**: `README.md`, `AGENTS.md`(static 허용 목록 D2)

---

## 호스트 프로젝트 manifest.json

호스트 레포 `Packages/manifest.json` 의 주요 항목(Unity 모듈과 IDE 패키지는 생략). 호스트에서는 같은 이름의 서브모듈 폴더가 우선 사용된다.

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
    "com.geuneda.gamesystems": "https://github.com/geuneda/geuneda-gamesystems.git",
    "com.cysharp.unitask": "https://github.com/Cysharp/UniTask.git?path=src/UniTask/Assets/Plugins/UniTask",
    "com.unity.addressables": "2.7.6",
    "com.unity.editorcoroutines": "1.0.1",
    "com.unity.inputsystem": "1.17.0",
    "com.unity.mobile.notifications": "2.4.2",
    "com.unity.test-framework": "1.6.0",
    "com.unity.ugui": "2.0.0"
  }
}
```

호스트 Unity 버전은 6000.3.2f1(`ProjectSettings/ProjectVersion.txt`).

## 소비 프로젝트 구성 예시

UniTask 와 git 전용 Geuneda 의존성은 자동으로 설치되지 않으므로 모두 명시한다. 값은 위 레포 URL 규칙의 git URL 이다.

### 최소 구성 (서비스 기반 게임)

```json
{
  "com.cysharp.unitask": "https://github.com/Cysharp/UniTask.git?path=src/UniTask/Assets/Plugins/UniTask",
  "com.geuneda.gamedata": "https://github.com/geuneda/geuneda-gamedata.git",
  "com.geuneda.services": "https://github.com/geuneda/geuneda-services.git"
}
```

### UI 와 상태 머신을 쓰는 게임

최소 구성에 다음을 더한다. uiservice 를 쓰면 `com.unity.ugui` 도 있어야 한다.

```json
{
  "com.geuneda.uiservice": "https://github.com/geuneda/geuneda-uiservice.git",
  "com.geuneda.statechart": "https://github.com/geuneda/geuneda-statechart.git",
  "com.geuneda.gamesystems": "https://github.com/geuneda/geuneda-gamesystems.git"
}
```

### 모바일 게임

위 구성에 필요한 것만 더한다.

```json
{
  "com.geuneda.inputextensions": "https://github.com/geuneda/geuneda-inputextensions.git",
  "com.geuneda.nativeui": "https://github.com/geuneda/geuneda-nativeui.git",
  "com.geuneda.notificationservice": "https://github.com/geuneda/geuneda-notificationservice.git",
  "com.geuneda.googlesheetimporter": "https://github.com/geuneda/geuneda-googlesheetimporter.git"
}
```
