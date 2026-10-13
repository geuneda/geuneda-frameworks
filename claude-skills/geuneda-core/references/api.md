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

코드 범위: 0 성공, 1~999 core 공용, 1000~99999 패키지별 1000 단위 블록(core `README.md` "결과 코드 범위" 표에 등록), 100000 이상 게임.

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
