# Geuneda Frameworks - 공용 규칙

geuneda-frameworks 패키지를 쓰는 모든 Unity 프로젝트에 적용하는 공통 규칙.
프로젝트별 CLAUDE.md 에서 "geuneda-frameworks CLAUDE.md 공용 규칙을 따른다"로 참조한다.

패키지 목록, 버전, 설치, 의존성은 [README.md](README.md) 가 기준이다. 이 레포 자체(호스트 프로젝트, 서브모듈)를 작업할 때의 규칙은 [AGENTS.md](AGENTS.md) 를 따른다.

## 금지 패턴

- 싱글톤 금지 (MainInstaller 서비스 로케이터 사용)
- static mutable state 금지 (서비스를 통해 접근). 예외는 서비스 로케이터 `MainInstaller`(바인딩과 `BindingChanged` 처리기), 로거(`Geuneda.Core` 의 `Log`/`ModuleLogger`), 메인 스레드 디스패처(`MainThreadDispatcher`), 보안 값 변조 알림(`Geuneda.DataExtensions` 의 `SecureValueMonitor`)뿐이다(결정 D2, core `AGENTS.md`)
- 2단계 이상 MonoBehaviour 상속 금지
- MonoBehaviour에 비즈니스 로직 직접 구현 금지
- God class 금지 (단일 책임 원칙)
- Resources 폴더 사용 최소화 (Addressables 사용)
- Find/FindObjectOfType 사용 금지 -> 서비스 로케이터 사용
- `async void` 금지 -> `async UniTaskVoid` (UniTask only)

## 실패 처리

- 실행 중 일어날 수 있는 실패(네트워크, 타임아웃, 취소, 서버 거절, 중복 실행)는 `Geuneda.Core` 의 `Result`/`Result<T>` 코드로 돌려준다. 예외를 밖으로 던지지 않는다
- 오용(잘못된 인자, 잘못된 상태에서 호출)은 결과로 숨기지 않고 즉시 예외로 거절한다
- 예외를 결과로 바꿀 때는 정상 실패 예외(취소, 타임아웃, 연결 실패)만 타입별로 잡는다. `catch (Exception)` 으로 오용·버그를 `Unknown` 결과로 숨기지 않는다. 정상 실패는 Error 로그로 남기지 않는다
- 결과 코드 범위: 0 성공, 1~999 core 공용(`ResultCodes`), 패키지별 1000 단위 블록, 실시간 RPC 서버 프레임워크 100000~100999, 게임 101000 이상(core `README.md`)

## 빌드 환경

- 서버 주소, 로그 레벨, 분석 환경처럼 환경마다 다른 값은 `Geuneda.Core` 의 `AppEnv.Current` 로 고른다. 환경을 직접 문자열이나 별도 플래그로 만들지 않는다
- 환경은 `GEUNEDA_ENV_DEV` / `GEUNEDA_ENV_QA` / `GEUNEDA_ENV_PROD` define 하나로 정한다. 없으면 에디터·개발 빌드는 Dev, 릴리스 빌드는 Prod 이므로 QA 릴리스 빌드에는 `GEUNEDA_ENV_QA` 를 꼭 넣는다
- 운영 빌드에서 빠져야 하는 코드(치트, 디버그 메뉴)는 `#if !GEUNEDA_ENV_PROD && (UNITY_EDITOR || DEVELOPMENT_BUILD || GEUNEDA_ENV_DEV || GEUNEDA_ENV_QA)` 로 감싼다(`AppEnv.Current` 가 Prod 가 아닌 경우와 같은 조건)

## 설정 에셋

- 설정 ScriptableObject 는 부트스트랩에서 `Geuneda.Core` 의 `ConfigAssetLoader` 로 읽어 `MainInstaller` 에 바인딩한다. 사용하는 쪽에서 `Resources.Load` 를 직접 부르지 않는다
- 환경마다 다른 값은 `EnvValue<T>` 필드로 둔다. 비밀 값은 넣지 않는다(모든 환경 값이 빌드에 들어감)
- 개인 덮어쓰기는 `Editor/Resources` 폴더에 `이름.user.asset` 으로 두고 gitignore 한다. Editor 폴더 밖(또는 StreamingAssets 안)에 `.user` 에셋이 있으면 플레이어 빌드가 실패한다

## 식별자

- 설치 ID 와 기기 ID 는 `Geuneda.Core` 의 `AppIdentity` 를 부트스트랩에서 만들어 `MainInstaller.Bind<IAppIdentity>` 로 바인딩하고 `IAppIdentity` 로 받는다. `SystemInfo.deviceUniqueIdentifier` 나 PlayerPrefs GUID 를 직접 만들지 않는다

## 스레드

- SDK 콜백처럼 다른 스레드에서 받은 작업은 `Geuneda.Core` 의 `MainThreadDispatcher.Post` 로 메인 스레드에 넘긴 뒤 Unity API 를 부른다(UniTask 코드는 `UniTask.SwitchToMainThread` 도 가능)

## CBD 설계 원칙

- MonoBehaviour는 단일 책임 (Unity 연결 역할만)
- 비즈니스 로직은 POCO 클래스로 분리
- 상속 대신 컴포넌트 조합
- 인터페이스 기반 추상화, 구체 타입 직접 참조 최소화

### 권장 구조

- Model: POCO + ObservableField 상태 관리
- View: MonoBehaviour, Unity 표시만
- Presenter: 로직 담당 클래스, View와 분리
- Config: ScriptableObject 또는 ConfigsProvider
- Service: MainInstaller 바인딩, 인터페이스 접근

## 핵심 API 패턴

모두 `Geuneda.Services` 네임스페이스다(풀 타입만 `Geuneda.Services.Pooling`). 자세한 사용법은 `/geuneda-services` 스킬을 쓴다.

### DI 등록과 해제

```csharp
MainInstaller.Bind<IMyService>(new MyService());     // T 는 인터페이스여야 한다(클래스면 ArgumentException)
MainInstaller.CleanDispose<IPoolService>();          // IDisposable 서비스: Dispose 후 바인딩 제거
MainInstaller.Clean();                               // 모든 바인딩 제거
```

- `MainInstaller.Bind<T>` 는 인터페이스 하나만 받는다. 한 인스턴스를 여러 인터페이스로 묶으려면 인터페이스마다 따로 `Bind` 한다.
- 같은 인터페이스를 두 번 `Bind` 하면 예외가 난다.

### 서비스 접근

```csharp
var service = MainInstaller.Resolve<IMyService>();                  // 바인딩이 없으면 ArgumentException
if (MainInstaller.TryResolve<IMyService>(out var svc)) { /* ... */ }
```

### 이벤트 (MessageBroker)

```csharp
public struct MyMessage : IMessage { public int Value; }

var broker = MainInstaller.Resolve<IMessageBrokerService>();
broker.Subscribe<MyMessage>(OnMyMessage);            // 인스턴스 메서드만 가능(static 이면 ArgumentException)
broker.Publish(new MyMessage { Value = 1 });         // 핸들러 안에서 구독/해제가 일어나면 PublishSafe 사용
broker.Unsubscribe<MyMessage>(this);                 // 해제 필수. 구독자는 액션의 Target(구독한 객체)
broker.UnsubscribeAll(this);                         // 이 객체의 모든 구독 해제
```

`Unsubscribe<T>()` 처럼 인자 없이 부르면 그 메시지 타입의 구독자 전체가 해제되니 주의한다.

### 오브젝트 풀링

```csharp
using Geuneda.Services.Pooling;

// Bullet : MonoBehaviour, bulletPrefab : Bullet
var poolService = MainInstaller.Resolve<IPoolService>();
poolService.AddPool(new GameObjectPool<Bullet>(20, bulletPrefab));  // 같은 타입의 풀은 하나만
var bullet = poolService.Spawn<Bullet>();
poolService.Despawn(bullet);
```

## 프레임워크 스킬 필수 규칙

Geuneda API 코드를 작성하거나 고치기 전에 해당 스킬을 invoke 해서 API 사양을 확인한다.

| using 네임스페이스 | 필수 스킬 |
|-------------------|----------|
| `Geuneda.DataExtensions`, `Geuneda.DataExtensions.Editor`, `GeunedaEditor.GameData` | `/geuneda-gamedata` |
| `Geuneda.Services`, `Geuneda.Services.*` (Pooling, Commands, AssetsImporter, 에디터 네임스페이스 포함) | `/geuneda-services` |
| `Geuneda.UiService`, `Geuneda.UiService.Views`, `GeunedaEditor.UiService` | `/geuneda-uiservice` |
| `Geuneda.StatechartMachine` | `/geuneda-statechart` |
| `Input`, `Input.Controls` (inputextensions, 어셈블리 이름은 `Geuneda.InputExtensions`) | `/geuneda-inputextensions` |
| `Geuneda.NativeUi` | `/geuneda-nativeui` |
| `Geuneda.NotificationService` | `/geuneda-notificationservice` |
| `Geuneda.GoogleSheetImporter`, `GeunedaEditor.GoogleSheetImporter` | `/geuneda-googlesheetimporter` |
| `Geuneda.GameSystems.*` (예: `Geuneda.GameSystems.RedDot`) | `/geuneda-gamesystems` |
| `Geuneda.Core` | `/geuneda-core` |
| `Geuneda.Http` | `/geuneda-http` |
| `Geuneda.Realtime`, `Geuneda.Realtime.Server`, `[RpcService]` 계약 | `/geuneda-realtime` |
| `Geuneda.Account`, `Geuneda.Account.Server`, `Geuneda.Account.Apple`, `Geuneda.Account.Google` | `/geuneda-account` |
| `Geuneda.AppSetting`, `Geuneda.AppSetting.Server` | `/geuneda-appsetting` |
| `Geuneda.Resource` | `/geuneda-resource` |
| `Geuneda.ServerTime` | `/geuneda-servertime` |
| `Geuneda.Analytics`, `Geuneda.Analytics.Collector`, `Geuneda.Analytics.Account`, `Geuneda.Analytics.Server`, `Geuneda.Analytics.Firebase`, `Geuneda.Analytics.Airbridge`, `Geuneda.Analytics.AppsFlyer`, `Geuneda.Analytics.Facebook` | `/geuneda-analytics` |
| `Geuneda.Iap`, `Geuneda.Iap.Analytics`, `Geuneda.Iap.Unity` | `/geuneda-iap` |

| 작업 유형 | 필수 스킬 |
|----------|----------|
| 프레임워크 구조/의존성 변경, 패키지 선택 | `/geuneda-frameworks` |

- 하나의 파일이 여러 네임스페이스를 쓰면 관련 스킬을 모두 invoke 한다.
- 에이전트에게 위임할 때 invoke 할 스킬을 명시한다.
- inputextensions 의 `Input` 네임스페이스는 `UnityEngine.Input` 을 가린다. 레거시 입력 API 는 `UnityEngine.Input` 으로 완전한 이름을 쓴다.

## 패키지 간 영향

gamedata 를 services, googlesheetimporter 가 쓰고, services 를 gamesystems, servertime 이 쓴다. 하위 패키지 API 를 바꾸면 상위 패키지도 확인한다. 전체 의존성은 [README.md](README.md#의존성) 를 본다.
