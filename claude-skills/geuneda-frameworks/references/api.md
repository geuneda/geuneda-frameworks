# Geuneda Frameworks - 패키지별 상세 카드

모든 값은 2026-10-14 시점 각 패키지의 `package.json` 과 asmdef 기준이다. 작업 전에 해당 파일로 다시 확인한다. 의존성 그래프와 설치 규칙은 `SKILL.md` 를 본다.

공통:
- 레포: `https://github.com/geuneda/geuneda-<패키지>.git`(패키지 이름의 점은 `-`, 예: `account.apple` -> `geuneda-account-apple`)
- 서브모듈 경로: `Packages/com.geuneda.<패키지>`
- 기본 브랜치: core, http, realtime, account, account.apple, account.google, appsetting, resource, servertime, analytics, analytics.firebase, analytics.airbridge, analytics.appsflyer, analytics.facebook, iap, iap.unity, ads, ads.max, consent, consent.ump, consent.att, banword, notice, coupon, webview, webview.gree, gamesystems 는 `main`, 나머지는 `master`

---

## 1. com.geuneda.gamedata

- **버전 / 최소 Unity**: 2.0.0 / 6000.0. 2.0.0 은 core 의존성을 추가한 호환성 파괴 버전이며 core 를 넣지 않을 기존 프로젝트는 `#v1.2.0` 으로 고정한다
- **package.json 의존성**: `com.geuneda.core` 0.4.0(로거), `com.unity.nuget.newtonsoft-json` 3.2.1, `com.cysharp.unitask` 2.5.10, `com.unity.ugui` 2.0.0
- **이 패키지에 의존하는 패키지**: services, googlesheetimporter
- **어셈블리**: `Geuneda.GameData`(Runtime, `Geuneda.Core`·`UniTask` + `Newtonsoft.Json.dll` 참조, `allowUnsafeCode`), `Geuneda.GameData.Editor`(Editor)
- **네임스페이스**: `Geuneda.DataExtensions`(Runtime), `Geuneda.DataExtensions.Editor` 와 `GeunedaEditor.GameData`(Editor)
- **주요 기능**:
  - Observable: `ObservableField`, `ObservableList`, `ObservableDictionary`, `ObservableHashSet`, Resolver 변형, `ObservableBatch`, `ComputedField`
  - 설정: `ConfigsProvider`, `ConfigsSerializer`, `ConfigsScriptableObject`, `IConfigBackendService`
  - 결정론적 수학: `floatP`, `MathfloatP`
  - 보안 값: `SecureInt`, `SecureLong`, `SecureFloat`, `SecureDouble`, `SecureFloatP`, `SecureValueMonitor`(변조 감지 static 이벤트, D2 예외)
  - 직렬화/유틸: `UnitySerializedDictionary`, `SerializableType`, `EnumSelector`, JSON 컨버터, 검증 어트리뷰트
  - 에디터: Config Browser, Observable Debug 창, 스키마 마이그레이션(`MigrationRunner`)
- **샘플**: Reactive UI Demo (uGUI), Reactive UI Demo (UI Toolkit), Designer Workflow, Migration
- **테스트**: `Geuneda.GameData.Editor.Tests`(`Tests/Editor`), `Geuneda.GameData.PlayMode.Tests`(`Tests/PlayMode`)
- **문서**: `README.md`

---

## 2. com.geuneda.services

- **버전 / 최소 Unity**: 5.2.0 / 6000.3
- **package.json 의존성**: `com.geuneda.core` 0.4.0, `com.geuneda.gamedata` 1.0.0, `com.unity.addressables` 1.21.20, `com.cysharp.unitask` 2.5.10
- **이 패키지에 의존하는 패키지**: gamesystems, servertime
- **어셈블리**: `Geuneda.Services`(Runtime, `Geuneda.Core`, `Geuneda.GameData` 와 Addressables/UniTask 계열 참조), `Geuneda.Services.Editor`(Editor)
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

- **버전 / 최소 Unity**: 3.1.0 / 6000.0. 3.1.0 은 uGUI 같은 레이어 정렬(루트 Canvas `레이어 + 연 순위`)과 여러 팝업 큐의 로드 중 대기를 바꾼 동작 변경(API 동일)이고, 3.0.0 은 core 의존성을 추가한 호환성 파괴 버전이며(core 를 넣지 않을 프로젝트는 `#v2.0.0`), 2.0.0 은 `IUiService` 에 멤버를 추가한 호환성 파괴 버전이다(그 전 프로젝트는 `#v1.3.2`)
- **package.json 의존성**: `com.geuneda.core` 0.4.0(로거), `com.unity.addressables` 2.6.0, `com.cysharp.unitask` 2.5.10, `com.unity.ugui` 2.0.0
- **선택 의존성**(asmdef `versionDefines`): `com.unity.inputsystem` 1.0.0 이상 → `GEUNEDA_INPUT_SYSTEM`(`ReadsBackInput` 이 `<Keyboard>/escape` 액션 사용, 없으면 레거시 Input Manager)
- **이 패키지에 의존하는 패키지**: 없음. gamedata/services 에도 의존하지 않는다.
- **어셈블리**: `Geuneda.UiService`(Runtime), `Geuneda.UiService.Editor`(Editor)
- **네임스페이스**: `Geuneda.UiService`, `Geuneda.UiService.Views`, `GeunedaEditor.UiService`(Editor)
- **주요 기능**: `UiService`/`IUiService`, `UiPresenter`, UI Set(`UiSetConfig`), 프레젠터 피처(`TimeDelayFeature`, `AnimationDelayFeature`, `UiToolkitPresenterFeature` 등), 에셋 로더(Addressables, Resources, Prefab Registry), 다중 인스턴스(`UiInstanceId`), 뒤로가기(`HandlesBack`/`OnBackPressed`, `HandleBack`, `AddBackHandler`, `BackUnhandled`, `ReadsBackInput`), 팝업 큐(`IUiPopupQueue`/`UiPopupQueue`: 우선순위, 키 중복 방지, `Hold`, `Drained`), 모달 dim(`IsModal`, `DimColor`), 입력 차단(`BlockInput` → `UiInputBlock`), 표시 상태 이벤트(`PresenterOpened`/`PresenterClosed`, `TryGetUi`)
- **테스트**: `Geuneda.UiService.Tests`(`Tests/EditMode`), `Geuneda.UiService.Tests.PlayMode`(`Tests/PlayMode`)
- **문서**: `README.md`, `docs/`(getting-started, core-concepts, navigation, api-reference, advanced, troubleshooting), `AGENTS.md`

---

## 4. com.geuneda.statechart

- **버전 / 최소 Unity**: 0.11.0 / 2022.3. 0.11.0 은 core 의존성을 추가한 호환성 파괴 버전이며 core 를 넣지 않을 기존 프로젝트는 `#v0.10.0` 으로 고정한다
- **package.json 의존성**: `com.geuneda.core` 0.4.0(로거), `com.cysharp.unitask` 2.5.10
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

- **버전 / 최소 Unity**: 0.3.0 / 2021.3. 0.3.0 은 core 의존성을 추가한 호환성 파괴 버전이며 core 를 넣지 않을 기존 프로젝트는 `#v0.2.8` 로 고정한다
- **package.json 의존성**: `com.geuneda.core` 0.4.0(로거, `MainThreadDispatcher`)
- **어셈블리**: `Geuneda.NativeUi`(iOS 네이티브 코드 `Runtime/Plugins/iOS/NativeUi.m` 포함)
- **네임스페이스**: `Geuneda.NativeUi`
- **주요 기능**: `NativeUiService.ShowAlertPopUp`, `NativeUiService.ShowToastMessage`(iOS/Android, 에디터에서는 로그만)
- **테스트**: 없음
- **문서**: `README.md`

---

## 7. com.geuneda.notificationservice

- **버전 / 최소 Unity**: 0.3.0 / 2021.3. 0.3.0 은 core 의존성을 추가한 호환성 파괴 버전이며 core 를 넣지 않을 기존 프로젝트는 `#v0.2.0` 으로 고정한다
- **package.json 의존성**: `com.geuneda.core` 0.4.0(로거), `com.unity.mobile.notifications` 2.4.2
- **어셈블리**: `Geuneda.NotificationService`
- **네임스페이스**: `Geuneda.NotificationService`
- **주요 기능**: `MobileNotificationService`(알림 생성/예약/취소/해제, 앱 안 알림 설정 `IsEnabled`, OS 권한 `Permission`/`RequestPermission`), `GameNotificationChannel`, Android/iOS 플랫폼 구현
- **테스트**: PlayMode `Geuneda.NotificationService.Tests.PlayMode`
- **문서**: `README.md`

---

## 8. com.geuneda.googlesheetimporter

- **버전 / 최소 Unity**: 0.10.0 / 6000.0 (`type: tool`)
- **package.json 의존성**: `com.unity.nuget.newtonsoft-json` 2.0.0, `com.geuneda.gamedata` 1.0.0
- **어셈블리**: `Geuneda.GoogleSheetImporter`(Runtime, `Geuneda.GameData` 참조), `Geuneda.GoogleSheetImporter.Editor`(Editor)
- **네임스페이스**: `Geuneda.GoogleSheetImporter`(Runtime: `CsvParser`, `ParseIgnoreAttribute`), `GeunedaEditor.GoogleSheetImporter`(Editor: 임포터)
- **주요 기능**: Google 스프레드시트를 ScriptableObject 설정 데이터로 임포트. 진입점은 `Assets > Create > ScriptableObjects > Editor > GoogleSheetImporter`, `Tools > GoogleSheet Importer > Import Google Sheet Data`, `Tools > GoogleSheet Importer > Select GoogleSheetImporter.asset`
- **샘플**: Importers Example
- **테스트**: `Geuneda.GoogleSheetImporter.Editor.Tests`(`Tests/Editor`)
- **문서**: `README.md`

---

## 9. com.geuneda.gamesystems

- **버전 / 최소 Unity**: 0.3.1 / 6000.3
- **package.json 의존성**: `com.geuneda.core` 0.4.0(로거), `com.geuneda.services` 5.1.0(`MainInstaller.BindingChanged`)
- **어셈블리**: 기능마다 하나. 현재 `Geuneda.GameSystems.RedDot`(`Geuneda.Core`·`Geuneda.Services` 참조)와 에디터 `Geuneda.GameSystems.RedDot.Editor`(디버그 창)
- **네임스페이스**: `Geuneda.GameSystems.<기능>`, 현재 `Geuneda.GameSystems.RedDot`
- **주요 기능**: 레드닷. '/' 경로 트리 알림 배지, 리프 값의 조상 합산, 뮤트, 경로 단위 구독(`IRedDotService`, `RedDotService`, `RedDotBinding`, `RedDotView`), 일괄 변경(`BeginBatch`/`RedDotBatch`), MainInstaller 늦은 바인딩·교체 추적, 알림 순환 상한, `Tools > Geuneda > RedDot Debugger`
- **테스트**: `Geuneda.GameSystems.Tests.EditMode`(`Tests/EditMode`), `Geuneda.GameSystems.Tests.PlayMode`(`Tests/PlayMode`)
- **문서**: `README.md`, `AGENTS.md`, `CLAUDE.md`

---

## 10. com.geuneda.core

- **버전 / 최소 Unity**: 0.5.1 / 2021.3
- **package.json 의존성**: 없음
- **이 패키지에 의존하는 패키지**: services, http, realtime, account, appsetting, resource, servertime, analytics, iap, ads, consent, notice, coupon, webview, gamedata, statechart, uiservice, nativeui, notificationservice, gamesystems(banword 는 선택 로더만)
- **어셈블리**: `Geuneda.Core`, `Geuneda.Core.Editor`(Editor, 빌드 가드, Android R8 keep 규칙 훅)
- **네임스페이스**: `Geuneda.Core`, `Geuneda.Core.Editor`
- **주요 기능**: 모듈별 로거(`ModuleLogger`, `LogLevel`, `Log.Sink`/`ILogSink`, `UnityConsoleSink`), 결과 규약(`Result`, `Result<T>`, `ResultCodes`, 패키지별 코드 범위), 빌드 환경(`AppEnv`, `AppEnvironment`, define `GEUNEDA_ENV_DEV`/`QA`/`PROD`, 없으면 에디터·개발 빌드 Dev, 릴리스 빌드 Prod), 메인 스레드 디스패처(`MainThreadDispatcher`), 설정 에셋(`ConfigAssetLoader`, `[ConfigAssetPath]`, `EnvValue<T>`, 에디터 `.user` 빌드 가드), 설치·기기 ID(`IAppIdentity`/`AppIdentity`, iOS 키체인 플러그인), 보안 저장소(`ISecureStore`/`PlatformSecureStore`/`SecureReadResult`, iOS 키체인, Android 키스토어 Java 플러그인), 결정론적 난수(`Pcg32`, PCG32 + SplitMix64 스트림 + Lemire 범위 + O(log n) `Advance`, 서버 링크 가능), 단조 시계(`IMonotonicClock`/`MonotonicClock`, Android `CLOCK_BOOTTIME`·macOS `CLOCK_MONOTONIC` libc, iOS 플러그인 `GeunedaMonotonicClock.mm`, 그 밖은 `Stopwatch`), 인증 암호화(`AesEncryption`: 버전 1 = AES-256-CBC + HMAC-SHA256 encrypt-then-MAC, HKDF 키 분리, 연관 데이터, 서버는 `Runtime/Cryptography`·`Runtime/Results` 링크), 기기 키(`IDeviceKeyProvider`/`DeviceKeyProvider`, 키체인·키스토어 없는 플레이어는 실패, 에디터는 PlayerPrefs 평문에 둠), 공용 결과 코드 6~9
- **테스트**: EditMode `Geuneda.Core.Tests.EditMode`, PlayMode `Geuneda.Core.Tests.PlayMode`
- **문서**: `README.md`, `AGENTS.md`(static 허용 목록 D2: `Log`, `MainThreadDispatcher`, gamedata `SecureValueMonitor`, services `MainInstaller`)

---

## 11. com.geuneda.http

- **버전 / 최소 Unity**: 0.1.0 / 2021.3
- **package.json 의존성**: `com.geuneda.core` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1, `com.unity.modules.unitywebrequest` 1.0.0
- **어셈블리**: `Geuneda.Http`
- **네임스페이스**: `Geuneda.Http`
- **주요 기능**: `IHttpClient`/`HttpClient`/`HttpClientBuilder`, 바꾸지 않는 `HttpRequest`·`HttpResponse`, 미들웨어 `(order, 등록 순서)` 체인(`IHttpMiddleware`, `HttpHandler`), `UnityWebRequestTransport`, 선택형 `TimeoutMiddleware`·`RetryMiddleware`·`DefaultHeadersMiddleware`, `HttpResultCodes`(1000 블록)
- **테스트**: EditMode `Geuneda.Http.Tests.EditMode`, PlayMode `Geuneda.Http.Tests.PlayMode`(로컬 HttpListener)
- **문서**: `README.md`, `AGENTS.md`

---

## 12. com.geuneda.realtime

- **버전 / 최소 Unity**: 0.2.0 / 2021.3
- **package.json 의존성**: `com.geuneda.core` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1
- **선택 의존성**: `org.nuget.messagepack` 3.x(+ `org.nuget.microsoft.net.stringtools`) 또는 define `GEUNEDA_MESSAGEPACK` 이 있으면 `Geuneda.Realtime.MessagePack` 컴파일
- **어셈블리**: `Geuneda.Realtime`, `Geuneda.Realtime.MessagePack`(선택)
- **네임스페이스**: `Geuneda.Realtime`
- **주요 기능**: `IRealtimeClient`/`RealtimeClient`/`RealtimeClientOptions`(single-flight 연결, 연결마다 `LoginAsync`, 지수 백오프+지터 재연결, 정책 종료 4000~4999 재연결 안 함), `IRpcCaller.CallAsync`, `Subscribe<TPush>`, 이름 해시 경로 `RpcMethod`/`RpcTopic`(FNV-1a), 바이너리 프레임 `RpcFrame`/`RpcFrameCodec`, `IRpcSerializer`(`JsonRpcSerializer`, `MessagePackRpcSerializer`), `IRealtimeTransport`/`ClientWebSocketTransport`, `RealtimeResultCodes`(2000 블록), `RealtimeCloseCodes`
- **계약·서버**: `[RpcService]` 계약에서 소스 생성기(`Runtime/Generator` 분석기 DLL, Roslyn 4.3)가 클라이언트 프록시(`XxxClient`)와 서버 라우트(`GeneratedRpcRoutes`)를 만듦. ASP.NET Core 서버 `Geuneda.Realtime.Server`·생성기 소스·샘플·xUnit 테스트는 `Server~/`(.NET 10, Unity 가 가져오지 않음)
- **테스트**: EditMode `Geuneda.Realtime.Tests.EditMode`(가짜 전송, 로컬 TcpListener WebSocket 서버, 생성된 클라이언트, `[Explicit]` 샘플 서버 상호 운용), `Geuneda.Realtime.MessagePack.Tests.EditMode`(MessagePack 이 있을 때만), `dotnet test Server~/Geuneda.Realtime.Server.slnx`
- **문서**: `README.md`(서버용 프로토콜 포함), `AGENTS.md`

---

## 13. com.geuneda.account

- **버전 / 최소 Unity**: 0.3.0 / 2021.3
- **package.json 의존성**: `com.geuneda.core` 0.2.0, `com.geuneda.http` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1
- **어셈블리 / 네임스페이스**: `Geuneda.Account`
- **주요 기능**: `IAuthService`/`AuthService`(게스트·제공자 로그인, `SignInSilentlyAsync`, `GetAccessTokenAsync` 재발급 single-flight, 로그아웃, 연동·충돌·옮겨오기·해제·계정 삭제, 계정 작업 동시 하나 `InProgress`), `AuthTokenMiddleware`(Bearer, 401 재발급 후 한 번 재전송, `RetryMiddleware` 바깥), `IAuthProvider`/`GuestAuthProvider`, `IAppSession`/`AppSession`(다음 세션 ID 예약, 백그라운드 10분 시간 초과, 대칭 이벤트), `IAuthService`·`IAppSession` 은 `IDisposable`, `AccountResultCodes`(3000 블록)
- **서버**: `Server~/` 의 ASP.NET Core 인증 서버 `Geuneda.Account.Server`(`AddGeunedaAccount`/`MapGeunedaAccount`, JWT, refresh 회전·재사용 감지, `IAccountStore`·`IRefreshTokenStore`·`IPlatformVerifier`(`AddGuest`, `AddApple`, `AddGoogle`, 공개 키 캐시 `OpenIdConnectKeyCache`), 게임 서버용 `AddGeunedaAccessTokenValidation`, `IOneTimeValueStore`(nonce·충돌 티켓), `POST nonce`, 409 `conflictTicket`), 샘플 서버, xUnit 테스트(.NET 10)
- **테스트**: EditMode `Geuneda.Account.Tests.EditMode`(가짜 인증 서버 전송, `[Explicit]` 샘플 서버 상호 운용), `dotnet test Server~/Geuneda.Account.Server.slnx`
- **문서**: `README.md`(서버 경로 표 포함), `AGENTS.md`

---

## 14. com.geuneda.account.apple

- **버전 / 최소 Unity**: 0.2.0 / 2021.3(iOS 13+)
- **package.json 의존성**: `com.geuneda.account` 0.3.0, `com.geuneda.core` 0.2.0, `com.cysharp.unitask` 2.5.10
- **어셈블리 / 네임스페이스**: `Geuneda.Account.Apple`, 에디터 `Geuneda.Account.Apple.Editor`
- **주요 기능**: `AppleAuthProvider`(ASAuthorizationController 네이티브 플러그인 `Runtime/Plugins/iOS/GeunedaAppleSignIn.mm`, 서버 nonce 의 SHA-256 을 `ASAuthorizationAppleIDRequest.nonce` 에), 빌드 후처리 `AppleSignInCapability`(Sign in with Apple entitlement)
- **테스트**: EditMode `Geuneda.Account.Apple.Tests.EditMode`. 실기 확인은 iOS 빌드
- **문서**: `README.md`(설정), `AGENTS.md`

---

## 15. com.geuneda.account.google

- **버전 / 최소 Unity**: 0.2.0 / 2021.3(Android API 23+, compileSdk 34+, iOS 13+)
- **package.json 의존성**: `com.geuneda.account` 0.3.0, `com.geuneda.core` 0.2.0, `com.geuneda.http` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1
- **어셈블리 / 네임스페이스**: `Geuneda.Account.Google`
- **주요 기능**: `GoogleAuthProvider(GoogleAuthOptions)`. Android 는 Credential Manager Android 라이브러리 플러그인(`GeunedaGoogleSignIn.androidlib`: Gradle 의존성 `androidx.credentials` 1.3.0, `googleid` 1.1.1, `androidx.core` 1.8.0, `androidx.loader` 1.0.0, R8 consumer 규칙), iOS 는 SDK 없이 ASWebAuthenticationSession + OAuth PKCE 와 토큰 엔드포인트 교환, nonce 는 `setNonce`·인가 요청 `nonce`
- **테스트**: EditMode `Geuneda.Account.Google.Tests.EditMode`(PKCE RFC 7636 예시, 토큰 교환 가짜 전송, 설정 검사). 실기 확인은 Android·iOS 빌드
- **문서**: `README.md`(Google Cloud 콘솔 설정), `AGENTS.md`

---

## 16. com.geuneda.appsetting

- **버전 / 최소 Unity**: 0.2.0 / 2021.3
- **package.json 의존성**: `com.geuneda.core` 0.2.0, `com.geuneda.http` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1
- **어셈블리 / 네임스페이스**: `Geuneda.AppSetting`
- **주요 기능**: `IAppSettingService`/`AppSettingService`/`AppSettingServiceOptions`(서명된 설정 문서를 받아 검증, 메모리에만 둠, `RefreshAsync` single-flight, ETag 조건부 요청, 낮은 판 무시, 실패 시 `Current` 유지, `Changed`), `AppSetting`(앱 버전 정확히 같은 노드 또는 `*`, `GetAccess(utcNow)` -> `AppAccess` 열림·내부·점검·업데이트 필요, `NewerVersions`, `TryGetEndpoint`, `GetFeatures<T>`), 문서 모델(`AppSettingDocument`, `AppVersionSetting`, `MaintenanceNotice`, `AppPlatformStatus`, `AppSettingPlatforms`), 리소스 매니페스트(`resources` 노드, `AppSettingResource`, `AppSetting.Resources`. 이름·크기·해시·주소 규칙은 두 모드 모두 적용, com.geuneda.resource 의 `ResourceEntry` 로 옮김), `AppSettingPublicKey`(RSA PKCS#1 v1.5 SHA-256, modulus·exponent, 2048 비트 이상), `AppSettingResultCodes`(4000 블록)
- **서명·배포**: `Server~/` 의 `Geuneda.AppSetting.Server`(`AppSettingSigningKey`, `AppSettingSigner`, `AppSettingPublicKeys`, `AppSettingResources`, `AddGeunedaAppSetting`/`MapGeunedaAppSetting` ETag·304 배포 헬퍼), 서명 CLI `geuneda-appsetting`(`keygen`, `public-key`, `sign`, `resource`, `verify`), 샘플 서버, xUnit 테스트(.NET 10). 문서 해석 코드(`Runtime/Document/`)를 클라이언트와 함께 컴파일
- **테스트**: EditMode `Geuneda.AppSetting.Tests.EditMode`(봉투·서명, 본문 규칙, 판정, 가짜 문서 서버, CLI 서명 픽스처, `[Explicit]` 샘플 서버 상호 운용), `dotnet test Server~/Geuneda.AppSetting.Server.slnx`
- **문서**: `README.md`(문서 형식, 서명 도구, 배포), `AGENTS.md`

---

## 17. com.geuneda.resource

- **버전 / 최소 Unity**: 0.1.0 / 2021.3
- **package.json 의존성**: `com.geuneda.core` 0.2.0, `com.geuneda.http` 0.1.0, `com.cysharp.unitask` 2.5.10
- **어셈블리 / 네임스페이스**: `Geuneda.Resource`
- **주요 기능**: `IResourceCache`/`ResourceCache`/`ResourceCacheOptions`(`CheckAsync` 받을 항목과 총 크기, `DownloadAsync` 맞지 않는 것만 받기·동시 다운로드 제한·한 번에 하나, `LoadBytesAsync` 확인한 바이트, `GetFilePathAsync`), `ResourceEntry`(카테고리, 버전, 크기, SHA-256, URL. 이름은 경로를 벗어나지 못하게 제한), `ResourceCheck`, `ResourceDownloadProgress`, `ResourceResultCodes`(5000 블록). 받은 바이트를 검증한 뒤 임시 파일 → 이름 바꾸기로 저장, 새 버전 저장 뒤 옛 버전 삭제, 파일 입출력·해시는 스레드 풀
- **의존하지 않는 것**: appsetting(매니페스트는 게임이 `AppSetting.Resources` 에서 `ResourceEntry` 로 옮김)
- **테스트**: EditMode `Geuneda.Resource.Tests.EditMode`(가짜 파일 서버·같은 스레드 작업자, 항목 규칙, 로컬 HttpListener 와 실제 UnityWebRequest·스레드 풀)
- **문서**: `README.md`, `AGENTS.md`

---

## 18. com.geuneda.servertime

- **버전 / 최소 Unity**: 0.2.0 / 6000.3
- **package.json 의존성**: `com.geuneda.core` 0.4.0, `com.geuneda.services` 5.0.0, `com.geuneda.http` 0.1.0, `com.cysharp.unitask` 2.5.10
- **어셈블리 / 네임스페이스**: `Geuneda.ServerTime`
- **주요 기능**: `IServerTimeSync`/`ServerTimeSync`/`ServerTimeSyncOptions`(`SyncAsync` 원천을 순서대로 시도해 처음 성공한 표본에 받은 뒤 흐른 시간을 더해 `ITimeManipulator.SetServerTime`, `MaxRoundTrip`(10초)보다 긴 표본은 버림, `Start`/`Stop` 백그라운드 동기화: 실패하면 `RetryDelay`(5초)부터 두 배씩 `MaxRetryDelay`(5분)까지, 성공하면 `ResyncInterval`(30분)마다, 포그라운드 복귀 때 바로), `IServerTimeSource`, `NtpTimeSource`(기본 `time.google.com`, UDP 123, 제한 시간 5초, originate·모드·계층·윤초 표시 검증), `HttpDateTimeSource`(`IHttpClient` 로 `HEAD`, `Date` 헤더, 정확도 1~2초), `ServerTimeSample`(받은 순간의 서버 시각, 그 순간의 단조 시계 값, 왕복), `ServerTimeResultCodes`(6000 블록). `IServerTimeSync` 는 `IDisposable`(0.2.0, `MainInstaller.CleanDispose<IServerTimeSync>()`)
- **시계**: 시간 서비스와 같은 `IMonotonicClock` 을 써야 한다(둘 다 기본 생성자면 core `MonotonicClock`)
- **테스트**: EditMode `Geuneda.ServerTime.Tests.EditMode`(NTP 패킷 검증·왕복 보정, 127.0.0.1 가짜 UDP 서버, 가짜 `IHttpClient`·로컬 HttpListener 와 실제 UnityWebRequest, 가짜 원천·시계·지연으로 백오프·재동기화·포그라운드 복귀)
- **문서**: `README.md`, `AGENTS.md`

---

## 19. com.geuneda.analytics

- **버전 / 최소 Unity**: 0.2.1 / 2021.3
- **package.json 의존성**: `com.geuneda.core` 0.4.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1
- **선택 의존성**(asmdef `versionDefines`): `com.geuneda.http` 0.1.0 이상 → `Geuneda.Analytics.Collector`, `com.geuneda.account` 0.1.0 이상 → `Geuneda.Analytics.Account`
- **어셈블리 / 네임스페이스**: `Geuneda.Analytics`, `Geuneda.Analytics.Collector`, `Geuneda.Analytics.Account`
- **주요 기능**: `IAnalyticsService`/`AnalyticsService`/`AnalyticsOptions`(`LogEvent` 기록 시점 공통 맥락 스냅샷: ID, 시각·서버 시각 여부, 설치별 순번, 세션, 사용자 ID·속성, 앱 정보), `AnalyticsSinks` 비트, `IAnalyticsSink`(`MaxBatchSize`, `BatchDelay`, `IsReady`, `SendAsync` → `Delivered`/`Retry`/`Rejected`), sink 별 큐와 실패 sink 만 평문 JSON 저장·재전송(백오프 5초→5분, 포그라운드 복귀, 네트워크 복구, 다음 실행), `ConsoleSink`, `CollectorSink`(자사 수집 배치 POST), `AppSessionAnalytics`(세션 ID·세션 이벤트), `AnalyticsWire`(배치 형식)
- **서버**: `Server~/Geuneda.Analytics.Server.slnx`(.NET 10): `AddGeunedaAnalytics`, `MapGeunedaAnalytics`(`POST {prefix}/events`, 이벤트별 검증), `IAnalyticsEventStore`(ID 중복 제거), `InMemoryAnalyticsEventStore`, 샘플 서버
- **표준 이벤트**: `AnalyticsStandardEvents`(`purchase`, `ad_impression`), `AnalyticsPurchase`, `AnalyticsAdImpression`, `LogPurchase`·`LogAdImpression` 확장 메서드, 어댑터용 `TryRead`
- **벤더 어댑터**: 별도 패키지(D3) `com.geuneda.analytics.firebase`·`airbridge`·`appsflyer`·`facebook`(아래 20절)
- **테스트**: EditMode `Geuneda.Analytics.Tests.EditMode`, `Geuneda.Analytics.Collector.Tests.EditMode`(http 있을 때, `[Explicit]` 샘플 서버 상호 운용), `Geuneda.Analytics.Account.Tests.EditMode`(account 있을 때), PlayMode `Geuneda.Analytics.Tests.PlayMode`. 서버 `dotnet test "Server~/Geuneda.Analytics.Server.slnx"`
- **문서**: `README.md`, `AGENTS.md`

---

## 20. com.geuneda.analytics.firebase / .airbridge / .appsflyer / .facebook

- **버전 / 최소 Unity**: 각 0.1.0 / 2021.3(appsflyer 2023.1)
- **package.json 의존성**: `com.geuneda.analytics` 0.2.0, `com.geuneda.core` 0.4.0, `com.cysharp.unitask` 2.5.10. 벤더 SDK 는 게임이 먼저 설치(Firebase Unity SDK, Airbridge Unity SDK 4.x 어셈블리 `AirbridgeSDK`, AppsFlyer Unity 플러그인 7.x 어셈블리 `AppsFlyer`, Facebook SDK for Unity + uGUI)
- **어셈블리 / 네임스페이스**: `Geuneda.Analytics.Firebase`, `Geuneda.Analytics.Airbridge`, `Geuneda.Analytics.AppsFlyer`, `Geuneda.Analytics.Facebook`. asmdef `defineConstraints: ["!GEUNEDA_SKIP_VENDOR_ADAPTERS"]`(호스트는 이 define 으로 제외)
- **주요 기능**: `FirebaseAnalyticsSink`(`MarkReady`, 이름 규칙·제한, `purchase`·`ad_impression`), `AirbridgeAnalyticsSink`(카테고리·시맨틱 속성, 주문 완료·광고 노출), `AppsFlyerAnalyticsSink`(`MarkReady`, `af_purchase`·`logAdRevenue`), `FacebookAnalyticsSink`(`FB.IsInitialized`, `LogPurchase`·`AdImpression`). 모두 `HandleEvent` 옵션
- **테스트**: EditMode `Geuneda.Analytics.<Vendor>.Tests.EditMode`(SDK 호출 대역). 호스트에서는 컴파일되지 않으므로 SDK 를 넣은 별도 프로젝트에서 실행
- **문서**: 각 `README.md`, `AGENTS.md`

---

## 21. com.geuneda.iap / .iap.unity

- **버전 / 최소 Unity**: iap 0.3.0, iap.unity 0.1.0 / iap 2021.3, iap.unity 2022.3, 결제 서버 .NET 10
- **package.json 의존성**: iap 은 `com.geuneda.core` 0.4.0, `com.cysharp.unitask` 2.5.10. iap.unity 는 `com.geuneda.iap` 0.1.0, `com.geuneda.core` 0.4.0, `com.cysharp.unitask` 2.5.10, `com.unity.purchasing` 5.4.4
- **선택 의존성**(asmdef `versionDefines`): `com.geuneda.analytics` 0.2.0 이상 → `Geuneda.Iap.Analytics`, `com.geuneda.http` 0.1.0 이상 → `Geuneda.Iap.Http`
- **어셈블리 / 네임스페이스**: `Geuneda.Iap`, `Geuneda.Iap.Analytics`, `Geuneda.Iap.Http`, `Geuneda.Iap.Unity`, .NET 서버 `Geuneda.Iap.Server`(`Server~`)
- **주요 기능**: `IIapService`/`IapService`/`IapServiceOptions`(`InitializeAsync`, `PurchaseAsync`, `RecoverAsync`, `RestoreAsync`, `CheckEntitlementAsync`), 게임이 구현하는 `IPurchaseFulfiller`(`Granted`/`AlreadyGranted` 뒤에만 확정, `RetryLater` 백오프, `Rejected` 열어 둠), 이벤트 `OrderSettled`·`OrderFailed`·`PurchaseConfirmed`·`StoreUiChanged`, `IapResultCodes`(7000 블록), 스토어 계약 `IIapStore`, `UnityIapStore`(Unity IAP 5.4.4), `IapRevenueLogger`(거래의 첫 닫힘 때 `LogPurchase`), 공유 와이어 형식 `IapRedeemRequest`/`IapRedeemResponse<TGrant>`/`IapRedeemCodes`(7100~7199), `HttpPurchaseFulfiller<TGrant>`, 서버 `AddGeunedaIap`·`AddGooglePlay`·`AddAppStore`·`AddGrantor`·`AddLedger`·`MapGeunedaIap`, 게임 구현 `IPurchaseGrantor`·`IPurchaseLedger`·`IPurchaseNotificationHandler`, 서버 알림 `MapGeunedaIapGooglePlayNotifications`·`MapGeunedaIapAppStoreNotifications`(환불 회수, 구독 상태)
- **테스트**: EditMode `Geuneda.Iap.Tests.EditMode`, `Geuneda.Iap.Analytics.Tests.EditMode`(analytics 있을 때), `Geuneda.Iap.Http.Tests.EditMode`(http 있을 때), 서버 `dotnet test "Server~/Geuneda.Iap.Server.slnx"`, `Geuneda.Iap.Unity.Tests.EditMode`, PlayMode `Geuneda.Iap.Unity.Tests.PlayMode`(define `IAP_FAKE_STORE_DEFAULT`)
- **문서**: 각 `README.md`, `AGENTS.md`

---

## 22. com.geuneda.ads / .ads.max

- **버전 / 최소 Unity**: ads 0.1.0, ads.max 0.1.0 / 둘 다 2021.3
- **package.json 의존성**: ads 는 `com.geuneda.core` 0.4.0, `com.cysharp.unitask` 2.5.10. ads.max 는 `com.geuneda.ads` 0.1.0(AppLovin MAX `com.applovin.mediation.ads` 는 AppLovin 레지스트리 패키지라 의존성 아님)
- **선택 의존성**(asmdef `versionDefines`): `com.geuneda.analytics` 0.2.0 이상 → `Geuneda.Ads.Analytics`. ads.max 의 `Geuneda.Ads.Max` 는 `com.applovin.mediation.ads` 8.6.3 이상 → `GEUNEDA_ADS_MAX`(Assets 설치면 직접 define), 없으면 컴파일되지 않음(호스트에 MAX 없음)
- **어셈블리 / 네임스페이스**: `Geuneda.Ads`, `Geuneda.Ads.Analytics`, `Geuneda.Ads.Max`
- **주요 기능**: `IAdService`/`AdService`/`AdServiceOptions`(`ShowRewardedAsync`, `ShowInterstitialAsync`, `IsReady`), 이벤트 `ShowingChanged`·`Displayed`·`Clicked`·`ShowSettled`(`AdShowReport`)·`LateRewarded`(`AdLateReward`)·`RevenuePaid`(`AdRevenue`)·`LoadFailed`, `AdsResultCodes`(8000 블록), 미디에이션 계약 `IAdMediation`, `MaxAdMediation`(MAX 8.6.3+), `AdRevenueLogger`(노출 수익 → `LogAdImpression`)
- **테스트**: EditMode `Geuneda.Ads.Tests.EditMode`, `Geuneda.Ads.Analytics.Tests.EditMode`(analytics 있을 때), PlayMode `Geuneda.Ads.Tests.PlayMode`, MAX 가 있을 때 EditMode `Geuneda.Ads.Max.Tests.EditMode`·PlayMode `Geuneda.Ads.Max.Tests.PlayMode`(에디터 스텁)
- **문서**: 각 `README.md`, `AGENTS.md`

---

## 23. com.geuneda.consent / .consent.ump / .consent.att

- **버전 / 최소 Unity**: consent 0.1.0, consent.ump 0.1.0, consent.att 0.1.0 / 모두 2021.3
- **package.json 의존성**: consent 는 `com.geuneda.core` 0.4.0, `com.cysharp.unitask` 2.5.10, `com.unity.modules.jsonserialize`. consent.ump·consent.att 는 `com.geuneda.consent` 0.1.0, `com.geuneda.core` 0.4.0, UniTask 2.5.10. consent.ump 는 EDM4U 가 있어야 함(`Editor/GeunedaConsentUmpDependencies.xml`: Android `com.google.android.ump:user-messaging-platform` 3.2.0, iOS 파드 `GoogleUserMessagingPlatform` ~> 3.0)
- **어셈블리 / 네임스페이스**: `Geuneda.Consent`, `Geuneda.Consent.Ump`, `Geuneda.Consent.Att`, `Geuneda.Consent.Att.Editor`
- **네이티브**: consent.ump 는 `Runtime/Plugins/Android/GeunedaUmp.androidlib`(UMP `compileOnly`, INTERNET 권한, R8 keep)와 `Runtime/Plugins/iOS/GeunedaUmp.mm`. consent.att 는 `Runtime/Plugins/iOS/GeunedaAtt.mm` 과 iOS 빌드 후처리(추적 설명 문구, AppTrackingTransparency 약한 링크)
- **주요 기능**: `IConsentService`/`ConsentService`/`ConsentServiceOptions`(`RunAsync`, `ShowPrivacyOptionsAsync`, `Snapshot`), `ConsentSnapshot`·`AdConsentState`·`TrackingStatus`, `TermsConsent`(`TermsItem`, `ITermsPrompt`, `ITermsStore`, `PlayerPrefsTermsStore`), `ConsentResultCodes`(9000 블록), 공급자 계약 `IAdConsentProvider`·`ITrackingAuthorization`, `UmpAdConsent`·`UmpOptions`, `AttTrackingAuthorization`, 에디터 설정 `AttUsageDescription`
- **테스트**: EditMode `Geuneda.Consent.Tests.EditMode`, `Geuneda.Consent.Ump.Tests.EditMode`, `Geuneda.Consent.Att.Tests.EditMode`(호스트에서 실행됨). 네이티브는 EDM4U 를 넣은 별도 프로젝트에서 Android 에뮬레이터·iOS 시뮬레이터로 확인
- **문서**: 각 `README.md`, `AGENTS.md`

## 24. com.geuneda.banword

- **버전 / 최소 Unity**: 0.1.1 / 2021.3
- **package.json 의존성**: 없음
- **어셈블리 / 네임스페이스**: `Geuneda.BanWord`(`noEngineReferences: true`), 선택 `Geuneda.BanWord.Resource`(com.geuneda.resource 가 있을 때만, `versionDefines` → `GEUNEDA_BANWORD_RESOURCE`, 네임스페이스는 `Geuneda.BanWord`). 서버는 `Server~/src/Geuneda.BanWord`(net10.0, `Runtime/*.cs` 링크)
- **주요 기능**: `IBanWordFilter`/`BanWordFilter`(`Contains`, `Find`, `Mask`, 금칙·허용 표시를 가진 Aho-Corasick 오토마톤 하나, 허용어 하나가 완전히 덮으면 뺌, 불변·스레드 안전), `BanWordMatch`, `BanWordList.TryParse`(`[denied]`/`[allowed]` 단어장 파일), 대소문자 접기 표(유니코드 17.0 C·S, BMP, `Tools~/generate_case_folding.py` 로 생성). `BanWordResourceLoader`(resource 캐시에서 지금 항목 → 마지막 항목(PlayerPrefs) → 내장 단어장, 실패는 취소뿐)
- **테스트**: EditMode `Geuneda.BanWord.Tests.EditMode`, `Geuneda.BanWord.Resource.Tests.EditMode`(호스트에서 실행됨). 같은 파일을 `Server~/tests/Geuneda.BanWord.Tests`(NUnit 3)가 .NET 10 에서 돌림: `dotnet test Server~/Geuneda.BanWord.Server.slnx`
- **문서**: `README.md`, `AGENTS.md`

## 25. com.geuneda.notice

- **버전 / 최소 Unity**: 0.1.0 / 2021.3
- **package.json 의존성**: `com.geuneda.core` 0.4.0, `com.geuneda.http` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1
- **어셈블리 / 네임스페이스**: `Geuneda.Notice`. 서버는 `Server~/src/Geuneda.Notice.Server`(net10.0, ASP.NET Core, Newtonsoft 13.0.3, `Runtime/Document/*.cs` 링크, 네임스페이스 `Geuneda.Notice.Server`)
- **주요 기능**: `INoticeService`/`NoticeService`/`NoticeServiceOptions`(`RefreshAsync` single-flight·ETag, `GetNotices`·`GetUnreadCount`·`GetPopups`, `MarkRead`·`IsRead`, `SnoozeForToday`·`IsSnoozed`, `Language`, `Changed`), `Notice`, 문서 `NoticeDocument`(`Parse` strict·관대, `ToUtf8Json`, `ActiveAt`)·`NoticeItem`·`NoticeContent`·`NoticePlatforms`, `NoticeResultCodes`(10000 블록). 서버 `AddGeunedaNotice`·`AddFileSource`·`AddSource<T>`·`MapGeunedaNotice`·`INoticeSource`
- **테스트**: EditMode `Geuneda.Notice.Tests.EditMode`(호스트에서 실행됨, `SampleServerInteropTest` 는 명시 실행). .NET: `dotnet test Server~/Geuneda.Notice.Server.slnx`(`Geuneda.Notice.Document.Tests` 는 Unity 문서 테스트를 링크한 NUnit 3, `Geuneda.Notice.Server.Tests` 는 xUnit)
- **문서**: `README.md`, `AGENTS.md`

## 26. com.geuneda.coupon

- **버전 / 최소 Unity**: 0.1.1 / 2021.3(실제 DB 저장소 안내 `docs/db-store.md`)
- **package.json 의존성**: `com.geuneda.core` 0.4.0, `com.geuneda.http` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1
- **어셈블리 / 네임스페이스**: `Geuneda.Coupon`. 서버는 `Server~/src/Geuneda.Coupon.Server`(net10.0, ASP.NET Core, `Runtime/Protocol/*.cs` 링크, 네임스페이스 `Geuneda.Coupon.Server`)
- **주요 기능**: `ICouponService`/`CouponService`/`CouponServiceOptions`(`RedeemAsync<TGrant>`), `CouponRedemption<TGrant>`(`AlreadyRedeemed`), 공유 `CouponRedeemRequest`·`CouponRedeemResponse<TGrant>`·`CouponResultCodes`(11000 블록)·`CouponCodes`·`CouponPlatforms`·`CouponRoutes`. 서버 `AddGeunedaCoupon`·`MapGeunedaCoupon`·`CouponServerBuilder`, `CouponCampaign`(Shared·Unique)·`CouponConditions`·`CouponAdmin`, `ICouponStore`·`InMemoryCouponStore`, `ICouponAttemptStore`(원자 예약)·`InMemoryCouponAttemptStore`, `ICouponGrantor`·`CouponGrantResult`, `ICouponContextResolver`, `ICouponRedeemer`
- **테스트**: EditMode `Geuneda.Coupon.Tests.EditMode`(호스트에서 실행됨, `SampleServerInteropTest` 는 명시 실행). .NET: `dotnet test Server~/Geuneda.Coupon.Server.slnx`(xUnit, Kestrel)
- **문서**: `README.md`, `AGENTS.md`

## 27. com.geuneda.webview / .webview.gree

- **버전 / 최소 Unity**: webview 0.2.1, webview.gree 0.2.0 / 모두 2021.3
- **package.json 의존성**: webview 는 `com.geuneda.core` 0.4.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1, `com.unity.modules.ui` 1.0.0. webview.gree 는 `com.geuneda.webview` 0.2.0(gree unity-webview `net.gree.unity-webview` 와 uGUI 는 게임이 설치, `?path=/dist/package-nofragment` 커밋 `20f14061` 으로 확인)
- **어셈블리 / 네임스페이스**: `Geuneda.WebView`, 선택 `Geuneda.WebView.Notice`(com.geuneda.notice 가 있을 때, `GEUNEDA_WEBVIEW_NOTICE`), `Geuneda.WebView.Coupon`(com.geuneda.coupon 이 있을 때, `GEUNEDA_WEBVIEW_COUPON`), `Geuneda.WebView.Gree`(gree 가 있을 때, `GEUNEDA_WEBVIEW_GREE`, 참조 `unity-webview`)
- **주요 기능**: `IWebViewService : IDisposable`/`WebViewService`/`WebViewServiceOptions`(`OpenAsync` 브리지 준비로 성공, `Close`·`Closed`, `HandleBack`, `AddCommand`, `Emit`), `WebViewCommandHandler`·`WebViewCommand`, `WebViewResultCodes`(12000 블록), 어댑터 계약 `IWebViewFactory`·`IWebViewNative`·`IWebViewNativeListener`·`WebViewNativeSettings`(이동 제한 정규식)·`WebViewMargins`, `NoticeWebViewCommands`(notice.list·read·refresh, notice.changed), `CouponWebViewCommands`(coupon.redeem), `GreeWebViewFactory`. 페이지 쪽 `Web~/geuneda-webview.js`, 샘플 `Web~/notice.html`·`coupon.html`
- **테스트**: EditMode `Geuneda.WebView.Tests.EditMode`, `Geuneda.WebView.Notice.Tests.EditMode`, `Geuneda.WebView.Coupon.Tests.EditMode`(호스트에서 실행됨), `Geuneda.WebView.Services.Tests.EditMode`(services 가 있을 때). JS `node --test "Web~/tests/*.test.mjs"`. PlayMode `Geuneda.WebView.Gree.Tests.PlayMode`(gree 가 있을 때만 컴파일, 호스트에는 gree 가 없음, `GreeWebViewInteropTest` 는 명시 실행)
- **문서**: 각 `README.md`, `AGENTS.md`

---

## 호스트 프로젝트 manifest.json

호스트 레포 `Packages/manifest.json` 의 주요 항목(Unity 모듈과 IDE 패키지는 생략). 호스트에서는 같은 이름의 서브모듈 폴더가 우선 사용된다.

```json
{
  "dependencies": {
    "com.geuneda.core": "https://github.com/geuneda/geuneda-core.git",
    "com.geuneda.http": "https://github.com/geuneda/geuneda-http.git",
    "com.geuneda.realtime": "https://github.com/geuneda/geuneda-realtime.git",
    "com.geuneda.account": "https://github.com/geuneda/geuneda-account.git",
    "com.geuneda.account.apple": "https://github.com/geuneda/geuneda-account-apple.git",
    "com.geuneda.account.google": "https://github.com/geuneda/geuneda-account-google.git",
    "com.geuneda.appsetting": "https://github.com/geuneda/geuneda-appsetting.git",
    "com.geuneda.resource": "https://github.com/geuneda/geuneda-resource.git",
    "com.geuneda.servertime": "https://github.com/geuneda/geuneda-servertime.git",
    "com.geuneda.analytics": "https://github.com/geuneda/geuneda-analytics.git",
    "com.geuneda.analytics.firebase": "https://github.com/geuneda/geuneda-analytics-firebase.git",
    "com.geuneda.analytics.airbridge": "https://github.com/geuneda/geuneda-analytics-airbridge.git",
    "com.geuneda.analytics.appsflyer": "https://github.com/geuneda/geuneda-analytics-appsflyer.git",
    "com.geuneda.analytics.facebook": "https://github.com/geuneda/geuneda-analytics-facebook.git",
    "com.geuneda.iap": "https://github.com/geuneda/geuneda-iap.git",
    "com.geuneda.iap.unity": "https://github.com/geuneda/geuneda-iap-unity.git",
    "com.geuneda.ads": "https://github.com/geuneda/geuneda-ads.git",
    "com.geuneda.ads.max": "https://github.com/geuneda/geuneda-ads-max.git",
    "com.geuneda.consent": "https://github.com/geuneda/geuneda-consent.git",
    "com.geuneda.consent.ump": "https://github.com/geuneda/geuneda-consent-ump.git",
    "com.geuneda.consent.att": "https://github.com/geuneda/geuneda-consent-att.git",
    "com.geuneda.banword": "https://github.com/geuneda/geuneda-banword.git",
    "com.geuneda.notice": "https://github.com/geuneda/geuneda-notice.git",
    "com.geuneda.coupon": "https://github.com/geuneda/geuneda-coupon.git",
    "com.geuneda.webview": "https://github.com/geuneda/geuneda-webview.git",
    "com.geuneda.webview.gree": "https://github.com/geuneda/geuneda-webview-gree.git",
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
  "com.geuneda.core": "https://github.com/geuneda/geuneda-core.git",
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
