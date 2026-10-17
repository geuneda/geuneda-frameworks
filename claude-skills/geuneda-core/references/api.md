# Geuneda Core API 레퍼런스

네임스페이스와 어셈블리: `Geuneda.Core`. 모든 공개 타입은 `Runtime/` 아래에 있다. 사용 패턴과 함정은 [../SKILL.md](../SKILL.md) 참고.

---

## 로거 (`Runtime/Logging/`)

### enum LogLevel : byte (`[Flags]`)

`None = 0`, `Verbose = 1`, `Debug = 2`, `Info = 4`, `Warning = 8`, `Error = 16`, `Fatal = 32`, `All = 63`.

### sealed class ModuleLogger

| 멤버 | 설명 |
|------|------|
| `const LogLevel DefaultLevels` | `Info \| Warning \| Error \| Fatal` |
| `ModuleLogger(string module)` | 모듈 이름이 null 이거나 비면 `ArgumentException` |
| `string Module { get; }` | 로그에 붙는 모듈 이름 |
| `LogLevel EnabledLevels { get; set; }` | 출력할 레벨. 기본 `DefaultLevels`. 스레드 안전(Volatile) |
| `bool IsEnabled(LogLevel level)` | 하나라도 켜져 있으면 `true` |
| `void Enable(LogLevel levels)` / `void Disable(LogLevel levels)` | 레벨 켜기/끄기. 동시 변경을 잃지 않음(Interlocked) |
| `void Verbose(string message, Object context = null, ...)` | `[Conditional("UNITY_EDITOR"), Conditional("DEVELOPMENT_BUILD"), Conditional("GEUNEDA_LOG_DEBUG")]` |
| `void Debug(string message, Object context = null, ...)` | Verbose 와 같은 조건부 컴파일 |
| `void Info(...)` / `void Warning(...)` / `void Error(string message, ...)` | |
| `void Error(Exception exception, string message = null, Object context = null, ...)` | 메시지 생략 시 예외 메시지. `exception` 이 null 이면 `ArgumentNullException` |
| `T Fatal<T>(T exception, string message = null, Object context = null, ...) where T : Exception` | Fatal 로그 후 같은 예외 반환. `exception` 이 null 이면 `ArgumentNullException` |

모든 로그 메서드는 끝에 `[CallerMemberName] string member, [CallerFilePath] string file, [CallerLineNumber] int line` 을 받는다(직접 넘기지 않음). 출력 대상의 예외는 잡아서 `UnityEngine.Debug.LogException` 으로 남긴다.

### static class Log

| 멤버 | 설명 |
|------|------|
| `ILogSink Sink { get; set; }` | 모든 로거의 출력 대상. 기본 `UnityConsoleSink`. null 이면 `ArgumentNullException` |
| `void ResetSink()` | 기본값으로 되돌림 |

`[RuntimeInitializeOnLoadMethod(SubsystemRegistration)]` 에서 `ResetSink()` 를 호출하고, 생성된 뒤 살아 있는 모든 `ModuleLogger` 의 `EnabledLevels` 를 `DefaultLevels` 로 되돌린다(약한 참조 목록).

### interface ILogSink

`void Write(in LogEntry entry)`. 여러 스레드에서 불릴 수 있다.

### readonly struct LogEntry

필드: `LogLevel Level`, `string Module`, `string Message`, `Exception Exception`, `UnityEngine.Object Context`, `string CallerMember`, `string CallerFile`, `int CallerLine`. 생성자는 같은 순서로 모두 받는다.

### sealed class UnityConsoleSink : ILogSink

- `Write`: `Debug.LogFormat(LogType, LogOption.None, context, "{0}", Format(entry))`. Verbose/Debug/Info 는 `Log`, Warning 은 `Warning`, Error/Fatal 은 `Error`. 예외가 있으면 이어서 `Debug.LogException(exception, context)`.
- `static string Format(in LogEntry entry)`: `[모듈] 메시지`.

---

## 결과 규약 (`Runtime/Results/`)

### readonly struct Result

| 멤버 | 설명 |
|------|------|
| `bool IsSuccess { get; }` | 성공 여부. `default` 는 false |
| `int Code { get; }` | 성공이면 `ResultCodes.Success`(0), 실패면 1 이상. `default` 는 `ResultCodes.Unknown` |
| `string Message { get; }` | 로그·디버깅용 설명. 없으면 null |
| `static Result Ok()` | 성공 |
| `static Result Fail(int code, string message = null)` | 실패. `code` 가 0 이하면 `ArgumentOutOfRangeException` |
| `static Result FromException(Exception exception)` | `ResultCodes.FromException` 의 코드 + 예외 메시지. null 이면 `ArgumentNullException`. 변환만 하므로 정상 실패 예외만 타입별로 잡아 넘긴다. 로그는 호출자가 남김 |
| `string ToString()` | `Success`, `Failure(코드)`, `Failure(코드): 메시지` |

### readonly struct Result&lt;T&gt;

| 멤버 | 설명 |
|------|------|
| `IsSuccess`, `Code`, `Message` | `Result` 와 같음 |
| `T Value { get; }` | 성공한 값. 실패면 `InvalidOperationException` |
| `bool TryGetValue(out T value)` | 성공이면 true 와 값, 실패면 false 와 `default` |
| `static Result<T> Ok(T value)` | 성공. 값이 null 이어도 됨 |
| `static Result<T> Fail(int code, string message = null)` | `Result.Fail` 과 같음 |
| `static Result<T> FromException(Exception exception)` | `Result.FromException` 과 같음 |
| `static implicit operator Result(Result<T> result)` | 값을 버리고 성공 여부·코드·메시지만 남김 |
| `string ToString()` | 성공이면 `Success(값)`, 실패면 `Result` 와 같음 |

### static class ResultCodes

| 상수 | 값 | 뜻 |
|------|----|----|
| `Success` | 0 | 성공 |
| `Unknown` | 1 | 분류하지 않은 실패. 예외 변환 기본값, `default` 결과 |
| `Cancelled` | 2 | 호출자나 사용자가 취소 |
| `Timeout` | 3 | 시간 초과 |
| `NetworkError` | 4 | 네트워크 연결 불가·끊김 |
| `InProgress` | 5 | 같은 작업이 이미 진행 중이라 거절 |

`static int FromException(Exception exception)`: `OperationCanceledException`(`TaskCanceledException` 포함) → `Cancelled`, `TimeoutException` → `Timeout`, 그 밖 → `Unknown`. null 이면 `ArgumentNullException`.

코드 범위: 0 성공, 1~999 core 공용, 1000~99999 패키지별 1000 단위 블록(core `README.md` "결과 코드 범위" 표에 등록: 1000 http, 2000 realtime, 3000 account, 4000 appsetting, 5000 resource, 6000 servertime, 7000 iap, 8000 ads, 9000 consent, 10000 notice, 다음 빈 블록 11000), 100000~100999 실시간 RPC 서버 프레임워크(realtime `RpcStatusCodes`), 101000 이상 게임.

---

## 빌드 환경 (`Runtime/Environment/`)

### enum AppEnvironment

`Dev = 1`, `QA = 2`, `Prod = 3`.

### static class AppEnv

| 멤버 | 설명 |
|------|------|
| `AppEnvironment Current { get; }` | `GEUNEDA_ENV_PROD` 면 Prod, `GEUNEDA_ENV_QA` 면 QA, `GEUNEDA_ENV_DEV` 면 Dev. define 이 없으면 에디터·개발 빌드는 Dev, 릴리스 빌드는 Prod. 실행 중 바뀌지 않음 |
| `bool IsDev` / `bool IsQA` / `bool IsProd` | `Current` 비교 |
| `string Name` | `dev`, `qa`, `prod` |

컴파일 규칙(`AppEnv.cs` 의 `#error`): 환경 define 은 많아야 하나. 운영 빌드에서 코드를 빼는 조건은 `#if !GEUNEDA_ENV_PROD && (UNITY_EDITOR || DEVELOPMENT_BUILD || GEUNEDA_ENV_DEV || GEUNEDA_ENV_QA)` 다(define 없는 릴리스 빌드도 Prod).

`internal static AppEnvironment Resolve(bool prodDefined, bool qaDefined, bool devDefined, bool editorOrDevelopmentBuild)`: 결정 함수(테스트용, `InternalsVisibleTo("Geuneda.Core.Tests.EditMode")`).

---

## 메인 스레드 디스패처 (`Runtime/Threading/`)

### static class MainThreadDispatcher

| 멤버 | 설명 |
|------|------|
| `bool IsMainThread { get; }` | 지금 스레드가 Unity 메인 스레드면 true. 메인 스레드는 플레이 세션 시작 때 기록하며, 한 번도 플레이하지 않은 편집 모드에서는 false |
| `void Post(Action action)` | 메인 스레드의 다음 처리 때 실행하도록 넣음. 어느 스레드에서든 호출 가능, null 이면 `ArgumentNullException`. 메인 스레드에서 불러도 바로 실행하지 않음 |

- 처리: PlayerLoop `Update` 단계의 `ScriptRunBehaviourUpdate` 바로 앞에 넣은 `MainThreadDispatcherUpdate` 가 매 프레임 쌓인 작업을 넣은 순서대로 모두 실행. 처리 중에 넣은 작업은 다음 프레임. 작업 예외는 `ModuleLogger("Geuneda.Core.MainThreadDispatcher")` 로 Error 를 남기고 계속.
- `SubsystemRegistration` 에서 남은 작업을 버리고 메인 스레드 ID 를 기록한 뒤 처리 단계를 다시 넣음(도메인 리로드 끈 Enter Play Mode 대응).
- 내부(테스트용, InternalsVisibleTo): `ProcessQueue()`, `ResetState()`.

---

## 설정 에셋 (`Runtime/Config/`, `Editor/`)

### sealed class ConfigAssetLoader

| 멤버 | 설명 |
|------|------|
| `const string UserSuffix = ".user"` | 개인 덮어쓰기 에셋 이름 접미사 |
| `ConfigAssetLoader(Func<string, Object> fallbackLoad = null)` | 대체 로더는 Resources 에 없을 때 경로로 부름 |
| `static string GetPath(Type type)` | `[ConfigAssetPath]` 값, 없으면 `type.Name`. null 이면 `ArgumentNullException` |
| `T Load<T>() where T : ScriptableObject` | 에디터만 `경로.user`(`Editor/Resources` 에 둠) → `Resources.Load(경로)` → 대체 로더. 없거나 타입이 다르면 `InvalidOperationException` |
| `bool TryLoad<T>(out T asset) where T : ScriptableObject` | 없으면 false. 타입이 다르면 `InvalidOperationException` |

캐시 없음. `.user` 를 쓰면 `Geuneda.Core.ConfigAssets` 로거로 Info 를 남긴다. 테스트용 internal 생성자 `(Func<string, Object> resourcesLoad, Func<string, Object> fallbackLoad, bool loadUserOverride)`.

### sealed class ConfigAssetPathAttribute

`ConfigAssetPathAttribute(string path)`: `\` → `/`, 공백·앞뒤 `/` 제거. 비면 `ArgumentException`. `string Path`.

### struct EnvValue<T> ([Serializable])

`EnvValue(T dev, T qa, T prod)`, `T Value`(= `Get(AppEnv.Current)`), `T Get(AppEnvironment environment)`(정의되지 않은 값이면 `ArgumentOutOfRangeException`). 직렬화 필드 `_dev`, `_qa`, `_prod`.

### Geuneda.Core.Editor.UserConfigAssetBuildGuard (internal, IPreprocessBuildWithReport)

`이름.user.확장자`(대소문자 무시) 에셋이 경로에 `Editor` 세그먼트가 없거나 `Assets/StreamingAssets/` 아래에 있으면 `BuildFailedException`. Resources 뿐 아니라 씬 참조·Addressables·StreamingAssets(원본 복사) 경로도 막기 위해서다. `internal static FindUserAssetsThatCanShip(IEnumerable<string>)`.

---

## 설치·기기 ID (`Runtime/Identity/`, `Runtime/Plugins/iOS/GeunedaKeychain.mm`)

### interface IAppIdentity

`string InstallId { get; }`, `string DeviceId { get; }`. `MainInstaller` 에는 이 인터페이스로 바인딩한다.

### sealed class AppIdentity : IAppIdentity

| 멤버 | 설명 |
|------|------|
| `AppIdentity()` | PlayerPrefs, (iOS 플레이어면) 키체인, `SystemInfo.deviceUniqueIdentifier` 로 만듦. 메인 스레드 |
| `string InstallId { get; }` | PlayerPrefs `geuneda.core.installId` 의 GUID(`N` 형식). 없으면 만들어 저장. 앱 데이터가 지워지면 새로, 백업 복원으로 PlayerPrefs 가 되살아나면 이전 값 |
| `string DeviceId { get; }` | iOS: 키체인(서비스 `<번들 ID>.geuneda`, 계정 `geuneda.core.deviceId`, `AfterFirstUnlockThisDeviceOnly`) GUID. 없으면 만들어 추가, 읽기 실패·추가 실패면 그 실행만 플랫폼 ID. 그 밖: `SystemInfo.deviceUniqueIdentifier`, 지원 안 하면(`n/a`, 빈 값) PlayerPrefs `geuneda.core.deviceId` GUID |

internal: `IKeyValueStore`(`PlayerPrefsStore`), 테스트용 생성자 `(IKeyValueStore, ISecureStore, Func<string>)`. 기기 ID 에는 iOS 플레이어에서만 `IosKeychainStore` 를 쓴다(Android 키스토어 값은 재설치로 사라지므로 쓰지 않음).

## 보안 저장소 (`Runtime/SecureStorage/`, `Runtime/Plugins/`, `Editor/AndroidProguardRules*.cs`)

### interface ISecureStore

| 멤버 | 설명 |
|------|------|
| `SecureReadResult TryRead(string key, out string value)` | Found(값, 빈 문자열 가능), NotFound(value null), Failed(있는지 모름, 덮어쓰지 말 것) |
| `bool TryWrite(string key, string value)` | 추가 또는 덮어쓰기. 실패하면 false |
| `bool TryDelete(string key)` | 없어도 true. 실패하면 false |

### enum SecureReadResult

`Found`, `NotFound`, `Failed`.

### sealed class PlatformSecureStore : ISecureStore

인자 검사(빈 키 `ArgumentException`, null 값 `ArgumentNullException`, 키·값의 NUL 문자 `ArgumentException`) 후 플랫폼 구현에 넘긴다. 메인 스레드.

| 플랫폼 | 구현(internal) | 저장 |
|--------|---------------|------|
| 에디터 | `PlayerPrefsSecureStore` | PlayerPrefs `geuneda.secure.<key>` 평문 |
| iOS 플레이어 | `IosKeychainStore` | 키체인 generic password, 서비스 `<번들 ID>.geuneda`, 계정 = key, `AfterFirstUnlockThisDeviceOnly` |
| Android 플레이어 API 23 이상 | `AndroidKeystoreStore` | 키스토어 별칭 `geuneda.core.securestore` 의 AES-256-GCM 키, SharedPreferences `geuneda.core.securestore` 에 Base64(IV 12 + 암호문 + 태그 16), 저장 키를 AAD 로 |
| Android API 22 이하, 그 밖 | `PlayerPrefsSecureStore` | 평문, 만들 때 Warning |

네이티브(iOS): `char* GeunedaKeychain_Copy(const char* key, int* status)`(malloc 문자열, 없으면 NULL + OSStatus), `int GeunedaKeychain_Set(const char* key, const char* value)`(갱신, 없으면 추가), `int GeunedaKeychain_Delete(const char* key)`(OSStatus, 없으면 errSecItemNotFound).

네이티브(Android): `com.geuneda.core.GeunedaSecureStore` 의 `static String read(Context, String)`(없거나 복호화 못 하면 null, 그 값은 지움), `static void write(Context, String, String)`, `static void delete(Context, String)`. 실패는 예외 → C# 에서 Failed/false.

에디터: `AndroidProguardRulesHook`(`#if UNITY_ANDROID`, `IPostGenerateGradleAndroidProject`)가 `AndroidProguardRules.Rule`(`-keep class com.geuneda.core.GeunedaSecureStore { public static *; }`)을 `unityLibrary/proguard-unity.txt` 에 넣는다.

## 결정론적 난수 (`Runtime/Random/`)

### struct Pcg32

PCG32(XSH-RR). 상태: 64비트 LCG 상태, 홀수 증가값(스트림 번호를 SplitMix64 로 섞은 값 `<< 1 | 1`), `Position`. 연산은 모두 unchecked, UnityEngine 참조 없음. 스레드 안전하지 않음.

| 멤버 | 설명 |
|------|------|
| `Pcg32(ulong seed, ulong stream)` | `pcg32_srandom_r(seed, SplitMix64(stream))` 와 같은 초기화. `Position` 0. 증가값이 섞은 값의 하위 63비트라 스트림 공간은 2^63(섞은 값이 최상위 비트만 다른 번호 한 쌍은 같은 수열) |
| `ulong Position` | 만든 뒤 쓴 32비트 출력 수(2^64 를 법으로) |
| `uint NextUInt()` | 다음 32비트 값. `default` 값이면 `InvalidOperationException` |
| `uint NextUInt(uint bound)` | [0, bound) Lemire. bound 0 이면 `ArgumentOutOfRangeException`(진행 안 함) |
| `int NextInt(int min, int max)` | [min, max). `min >= max` 면 `ArgumentOutOfRangeException` |
| `int NextIntInclusive(int min, int max)` | [min, max]. `min > max` 면 `ArgumentOutOfRangeException`. int 전체 범위는 32비트 출력 그대로. `min == max` 도 한 단계 진행 |
| `void Advance(ulong delta)` | O(log n) 건너뛰기. 뒤로 n 은 `Advance(unchecked(0UL - n))` |

internal(테스트용): `static Pcg32 FromSequence(ulong initState, ulong initSequence)`(SplitMix64 없이 `pcg32_srandom_r`), `static ulong SplitMix64(ulong)`.

## 단조 시계 (`Runtime/Time/`, `Runtime/Plugins/iOS/GeunedaMonotonicClock.mm`)

### interface IMonotonicClock

`TimeSpan Elapsed { get; }`: 기준점 이후 흐른 시간. 기기 시계(`DateTime.UtcNow`) 변경에 영향받지 않고 줄어들지 않는다. 기준점은 정해져 있지 않아(보통 기기 부팅) 두 값의 차이로 쓴다. 어느 스레드에서 읽어도 된다.

### sealed class MonotonicClock : IMonotonicClock

| 멤버 | 설명 |
|------|------|
| `MonotonicClock()` | 네이티브 시계를 한 번 확인해(`DllNotFoundException`·`EntryPointNotFoundException`·실패 반환이면) `Stopwatch` 로 바꿈. 인스턴스 안에서는 바꾸지 않음 |
| `TimeSpan Elapsed` | 아래 표의 시계 값 |
| `bool IncludesSleep` | 네이티브 시계를 쓰는지. `Stopwatch` 면 false |

| 플랫폼 | 시계 | 잠자기 포함 |
|--------|------|------------|
| Android 플레이어 | libc `clock_gettime(CLOCK_BOOTTIME)`(7) | 예 |
| iOS 플레이어 | 플러그인 `int64_t GeunedaMonotonicClock_Nanoseconds()` → `clock_gettime_nsec_np(CLOCK_MONOTONIC)` | 예 |
| macOS 에디터·플레이어 | libc `clock_gettime(CLOCK_MONOTONIC)`(6) | 예 |
| 그 밖(Windows, Linux, WebGL), 네이티브 실패 | `Stopwatch` | 플랫폼에 따름 |

플랫폼 분기는 에디터 define(`UNITY_EDITOR_OSX`)을 먼저 본다(에디터에서도 빌드 대상의 `UNITY_ANDROID`/`UNITY_IOS` 가 켜짐). `timespec` 필드는 `IntPtr`(32비트 Android 대응). iOS 만 플러그인을 쓰는 것은 IL2CPP 가 `__Internal` 로 선언한 시스템 함수가 시스템 헤더 선언과 충돌할 수 있어서다.

쓰는 곳: services `TimeService`(현재 시각 진행), servertime `ServerTimeSync`·`IServerTimeSource`(왕복 보정). 테스트는 `Elapsed` 를 직접 정하는 가짜 구현을 넘긴다.
