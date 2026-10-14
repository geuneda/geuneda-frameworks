# Geuneda Analytics API 레퍼런스

네임스페이스 `Geuneda.Analytics`(선택 어셈블리는 `Geuneda.Analytics.Collector`, `Geuneda.Analytics.Account`, 서버는 `Geuneda.Analytics.Server`). 버전 0.1.0.

## 서비스 (`Runtime/`)

### interface IAnalyticsService : IDisposable / sealed class AnalyticsService : IAnalyticsService

| 멤버 | 설명 |
|------|------|
| `AnalyticsService(AnalyticsOptions options)` | 메인 스레드에서 만든다. null 은 `ArgumentNullException`, 범위 밖 설정은 `ArgumentOutOfRangeException`. 플레이 중이면 숨은 `DontDestroyOnLoad` 수명 오브젝트(`HideInHierarchy`)를 만든다 |
| `AnalyticsSinks DefaultSinks` | 설정의 기본 sink |
| `string UserId` | 지금 사용자 ID(없으면 null) |
| `IReadOnlyDictionary<string, string> UserProperties` | 지금 사용자 속성. 바뀔 때마다 새 사전 |
| `void LogEvent(string name, IReadOnlyDictionary<string, object> parameters = null)` | `DefaultSinks` 로 기록 |
| `void LogEvent(string name, IReadOnlyDictionary<string, object> parameters, AnalyticsSinks sinks)` | 고른 sink 중 등록된 것으로 기록. 빈·공백 이름, `None`, 빈 파라미터 이름, 지원하지 않는 값은 `ArgumentException`(메시지에 파라미터 이름) |
| `void SetUserId(string userId)` | null·빈 문자열은 해제. 모든 sink 에 알림 |
| `void SetUserProperty(string name, string value)` | value null 은 제거. 빈 이름은 `ArgumentException`. 모든 sink 에 알림 |
| `void AddSink(IAnalyticsSink sink)` | 비트 하나가 아니면·`MaxBatchSize` < 1·음수 `BatchDelay` 는 `ArgumentException`, 같은 비트는 `InvalidOperationException`. 지금 사용자 ID(null 포함)·속성을 알리고 저장된 배치를 보낸다(지금 `MaxBatchSize` 보다 큰 저장 배치는 나눠 저장 후) |
| `void Dispose()` | 수명 오브젝트 삭제, 메모리 이벤트(보내는 중 배치 포함) 저장, 대기·요청 취소(sink 의 취소 콜백 예외는 Error 로그 후 다른 sink 도 정리). 이후 호출은 `ObjectDisposedException`(Dispose 는 여러 번 가능). `MainInstaller.CleanDispose<IAnalyticsService>()` 로 부를 수 있다 |

다른 스레드에서 부르면 `InvalidOperationException`.

### sealed class AnalyticsOptions

| 속성 | 기본 | 설명 |
|------|------|------|
| `IAppIdentity Identity` | null | 설치 ID |
| `IAnalyticsClock Clock` | 기기 시계 | 이벤트 시각, 서버 시각 여부 |
| `IAnalyticsSessionSource Session` | null | 세션 ID |
| `AnalyticsSinks DefaultSinks` | `All` | |
| `string StorageDirectory` | `persistentDataPath/geuneda-analytics` | sink 마다 하위 폴더 |
| `int MaxStoredBatchesPerSink` | 500 | 넘으면 오래된 파일부터 삭제(Warning). 최소 1 |
| `int MaxQueuedEventsPerSink` | 1000 | 넘으면 디스크로 옮김. 디스크에 못 쓰면(5초 동안 다시 안 씀) 오래된 것부터 버림(Warning). 최소 1 |
| `TimeSpan RetryDelay` | 5초 | 첫 재시도 대기 상한, 실패마다 두 배, 실제 대기 50~100%. 최소 `MinRetryDelay`(100ms) |
| `TimeSpan MaxRetryDelay` | 5분 | `RetryDelay` 이상 |

## 이벤트

### sealed class AnalyticsEvent

`AnalyticsEvent(string id, string name, IReadOnlyList<AnalyticsParameter> parameters, DateTime timestampUtc, bool isServerTime, long sequence, string sessionId, string userId, IReadOnlyDictionary<string, string> userProperties, AnalyticsAppInfo app)`: 빈 id·이름, `Local` 시각은 `ArgumentException`, null app 은 `ArgumentNullException`. 목록·사전은 복사하지 않는다.

속성 `Id`, `Name`, `Parameters`, `TimestampUtc`(`Kind` Utc), `IsServerTime`, `Sequence`, `SessionId`, `UserId`, `UserProperties`, `App`. `bool TryGetParameter(string name, out AnalyticsValue value)`.

### readonly struct AnalyticsParameter

`AnalyticsParameter(string name, AnalyticsValue value)`, `Name`, `Value`.

### readonly struct AnalyticsValue : IEquatable<AnalyticsValue>

| 멤버 | 설명 |
|------|------|
| `AnalyticsValueType Type` | `String` 0, `Integer` 1, `Float` 2, `Boolean` 3 |
| `String(string)`, `Integer(long)`, `Float(double)`, `Boolean(bool)` | 만들기. null 문자열은 빈 문자열, NaN·무한대는 `ArgumentException` |
| `FromObject(object)` | string, null(빈 문자열), bool, 정수형(`ulong` 은 `long.MaxValue` 까지), float·double·decimal(실수), `AnalyticsValue`. 그 밖(enum, char 등)은 `ArgumentException` |
| `StringValue`, `IntegerValue`, `FloatValue`, `BooleanValue` | 다른 형식이면 `InvalidOperationException`. `default` 는 빈 문자열 |
| `object ToObject()` | `string`, `long`, `double`, `bool` |
| `string ToString()` | 문화권 무관. 실수는 `"R"`, 불리언은 `true`/`false` |

### sealed class AnalyticsAppInfo

`AnalyticsAppInfo(installId, appVersion, platform, environment, deviceModel, operatingSystem)`, 같은 이름의 속성, `static Capture(IAppIdentity identity)`(메인 스레드), `static PlatformName(RuntimePlatform)`(`android`, `ios`, `editor`, `macos`, `windows`, `linux`, `webgl`, 그 밖은 소문자 enum 이름). 값 비교(`Equals`).

## sink

### [Flags] enum AnalyticsSinks

`None` 0, `Console` 1, `Collector` 2, `Firebase` 4, `Airbridge` 8, `AppsFlyer` 16, `Facebook` 32, `Custom1` 1<<24, `Custom2`, `Custom3`, `Custom4` 1<<27, `All` ~0. 6~23 비트는 geuneda 어댑터용 예약.

### interface IAnalyticsSink

| 멤버 | 설명 |
|------|------|
| `AnalyticsSinks Id` | 비트 하나. 저장 폴더 이름(`Id.ToString().ToLowerInvariant()`) |
| `int MaxBatchSize` | 1 이상. 등록 때 읽고 이후 바꾸지 않음 |
| `TimeSpan BatchDelay` | 0 이면 바로. 등록 때 읽음 |
| `bool IsReady` | false 면 1초마다 다시 확인 |
| `UniTask<AnalyticsSendResult> SendAsync(IReadOnlyList<AnalyticsEvent> events, CancellationToken ct)` | 한 번에 하나, 메인 스레드에서 불림. 다른 스레드에서 끝내도 됨(서비스가 메인 스레드로 복귀). 서비스를 닫으면 취소 → `Retry` 를 돌려줌 |
| `void SetUserId(string userId)`, `void SetUserProperty(string name, string value)` | 등록할 때 현재 값으로 한 번씩 |

`enum AnalyticsSendResult`: `Delivered` 0(지움), `Retry` 1(그 sink 폴더에 저장, 백오프 뒤 재전송), `Rejected` 2(버림, Warning). 정의되지 않은 값과 예외는 Error 로그 후 버림.

### sealed class ConsoleSink : IAnalyticsSink

`Id` `Console`, `MaxBatchSize` 100, `BatchDelay` 0. Info 로그 `이름 {키=값, ...}`, `user_id = ...`, `user_property 이름 = ...`.

### interface IAnalyticsClock / IAnalyticsSessionSource

`DateTime UtcNow`, `bool IsServerTime` / `string SessionId`(없으면 null). 이벤트마다 메인 스레드에서 읽는다.

## 자사 수집 (`Runtime/Collector/`, 어셈블리 `Geuneda.Analytics.Collector`)

### sealed class CollectorSink : IAnalyticsSink

`CollectorSink(IHttpClient http, CollectorSinkOptions options)`: null 은 `ArgumentNullException`, 빈 `Endpoint`, 잘못된 주소, `MaxBatchSize` 1~500 밖, 음수 `BatchDelay`, 0 이하 `Timeout` 은 `ArgumentException`. `Id` `Collector`, `IsReady` 항상 true, `SetUserId`·`SetUserProperty` 는 아무것도 안 함(이벤트에 실음).

`SendAsync`: `POST Endpoint`, 본문 `AnalyticsWire` 배치(Content-Type `application/json`), `Timeout` 이 있으면 요청 제한 시간. 결과 매핑: 2xx → `Delivered`(응답 `rejected` 는 Warning, 앞 5개 ID·이유), 응답 없음(NetworkError, Timeout, Cancelled, 미들웨어 실패 코드) → `Retry`(취소 외 Warning), 408·429·5xx → `Retry`(Warning), 본문이 `MaxBodyBytes` 초과 또는 413 → 반으로 나눠 차례로(이벤트 하나면 Error 후 버림, 한 조각이 `Retry` 면 전체 `Retry`, 하나라도 받았으면 `Delivered`), 그 밖 → `Rejected`(Error, 본문 앞 300자).

### sealed class CollectorSinkOptions

`string Endpoint`(필수, 상대 또는 절대), `int MaxBatchSize` 50(상한 `MaxAllowedBatchSize` 500), `TimeSpan BatchDelay` 10초, `int MaxBodyBytes` 1 MiB(1 이상), `TimeSpan? Timeout` 15초(null 이면 클라이언트 설정).

## 세션 연동 (`Runtime/Account/`, 어셈블리 `Geuneda.Analytics.Account`)

### sealed class AppSessionAnalytics : IAnalyticsSessionSource, IDisposable

| 멤버 | 설명 |
|------|------|
| `AppSessionAnalytics(IAppSession session)` | null 은 `ArgumentNullException` |
| `string SessionId` | 세션 끝 이벤트를 기록하는 동안은 끝난 세션 ID, 그 밖에는 `IAppSession.SessionId` |
| `void LogSessionEvents(IAnalyticsService analytics, AnalyticsSinks sinks)` | 한 번만(두 번째 `InvalidOperationException`), null·`None` 은 예외 |
| `void Dispose()` | 구독 해제(세션 ID 는 계속 줌) |
| 상수 | `SessionStartEvent` "session_start", `SessionPauseEvent` "session_pause", `SessionResumeEvent` "session_resume", `SessionEndEvent` "session_end", `ReasonParameter` "reason"(값 `ended`, `restarted`, `background_timeout`, `application_quit`) |

## 배치 형식 (`Runtime/Protocol/AnalyticsWire.cs`)

`Version` 1, `ContentType` `application/json`. 배치 `{"v":1,"events":[...]}`. 이벤트 필드 `id`, `name`, `time`(유닉스 ms), `serverTime`, `seq`, `params`(문자열·정수·실수·불리언), 선택 `sessionId`, `userId`, `installId`, `appVersion`, `platform`, `env`, `device`, `os`, `userProps`(문자열 값). 모르는 필드는 무시. 응답 `accepted`, `duplicates`, `rejected[{id, reason}]`.

## 서버 (`Server~/src/Geuneda.Analytics.Server`, .NET 10)

| 멤버 | 설명 |
|------|------|
| `IServiceCollection AddGeunedaAnalytics(Action<AnalyticsServerOptions> configure = null)` | 설정(1 미만이면 시작 실패)과 `TimeProvider.System`(없을 때) 등록 |
| `RouteHandlerBuilder MapGeunedaAnalytics(this IEndpointRouteBuilder, string prefix = "/analytics")` | `POST {prefix}/events`. `IAnalyticsEventStore`·`AddGeunedaAnalytics` 가 없으면 `InvalidOperationException` |
| `AnalyticsServerOptions` | `MaxBodyBytes` 1 MiB, `MaxEventsPerBatch` 500, `MaxNameLength` 100(이름, 파라미터·속성 이름, ID), `MaxParameters` 100(파라미터·속성 수), `MaxStringLength` 1000 |
| `interface IAnalyticsEventStore` | `Task<AnalyticsAppendResult> AppendAsync(IReadOnlyList<CollectedEvent>, CancellationToken)`. 같은 ID 는 한 번만 저장. 예외 → 500 |
| `readonly struct AnalyticsAppendResult` | `Accepted`, `Duplicates` |
| `sealed class CollectedEvent` | `Id`, `Name`, `Timestamp`, `IsServerTime`, `Sequence`, `SessionId`, `UserId`, `InstallId`, `AppVersion`, `Platform`, `Environment`, `Device`, `OperatingSystem`, `Parameters`(`string`/`long`/`double`/`bool`), `UserProperties`, `ReceivedAt` |
| `sealed class InMemoryAnalyticsEventStore` | 샘플·테스트용. `Events`(받은 순서 복사본) |

응답: 415(JSON 아님), 413(본문·이벤트 수 초과), 400(배치 형식: JSON 오류, 객체 아님, 버전, `events` 배열 없음), 200(이벤트별 검증: 필수 필드, 형식, 길이, 개수, 중복 필드·파라미터, 시각 범위, 짝 없는 서로게이트, `long` 범위를 넘는 정수 표기).

## 테스트 asmdef

`Geuneda.Analytics.Tests.EditMode`, `Geuneda.Analytics.Collector.Tests.EditMode`(http 있을 때), `Geuneda.Analytics.Account.Tests.EditMode`(account 있을 때), `Geuneda.Analytics.Tests.PlayMode`. 서버 `Server~/tests/Geuneda.Analytics.Server.Tests`(xUnit).
