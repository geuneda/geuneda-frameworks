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
