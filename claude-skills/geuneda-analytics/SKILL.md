---
name: geuneda-analytics
description: com.geuneda.analytics 패키지(네임스페이스 Geuneda.Analytics, 선택 어셈블리 Geuneda.Analytics.Collector·Geuneda.Analytics.Account, 서버 Geuneda.Analytics.Server)로 분석 이벤트 로깅 코드를 작성하거나 수정할 때 사용하는 스킬. IAnalyticsService·AnalyticsService·AnalyticsOptions 로 이벤트를 기록하거나(LogEvent, SetUserId, SetUserProperty, AddSink), AnalyticsSinks 비트로 받는 곳(콘솔, 자사 수집, Firebase, Airbridge, AppsFlyer, Facebook, Custom)을 고르거나, IAnalyticsSink 로 sink 를 만들거나, 실패한 sink 만 저장·재전송(백오프, 포그라운드 복귀, 네트워크 복구, 다음 실행)을 다루거나, CollectorSink 로 자사 수집 서버에 배치를 보내거나, AppSessionAnalytics 로 account 세션 ID·세션 이벤트를 붙이거나, IAnalyticsClock 으로 서버 시각을 쓰거나, ASP.NET Core 수집 서버(AddGeunedaAnalytics, MapGeunedaAnalytics, IAnalyticsEventStore, CollectedEvent)를 구현하거나, 배치 형식 AnalyticsWire 를 다룰 때 활성화한다.
---

# Geuneda Analytics

분석 이벤트 로깅이다. 이벤트를 기록한 순간의 공통 맥락(시각, 순번, 세션, 사용자, 앱)과 함께 만들어 비트로 고른 sink 마다 따로 큐에 넣고 보낸다. 한 sink 가 실패하면 그 sink 의 배치만 디스크에 저장해 그 sink 로만 다시 보낸다. 같은 형식을 받는 ASP.NET Core 수집 서버(`Server~/`)를 함께 둔다.

## 패키지 정보

- **버전**: 0.1.0
- **네임스페이스 / 어셈블리**: `Geuneda.Analytics`. 선택 어셈블리 `Geuneda.Analytics.Collector`(http 패키지가 있을 때), `Geuneda.Analytics.Account`(account 패키지가 있을 때)는 `versionDefines` 로 자동으로 켜진다
- **설치**: `https://github.com/geuneda/geuneda-analytics.git` (core, UniTask git URL 도 함께. 자사 수집은 http, 세션 연동은 account 도)
- **의존성**: `com.geuneda.core` 0.4.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1
- **최소 Unity 버전**: 2021.3
- **서버**: `Server~/` 의 .NET 10 솔루션 `Geuneda.Analytics.Server.slnx`. 배치 형식 상수는 `Runtime/Protocol/AnalyticsWire.cs` 를 링크
- **벤더 어댑터**(D3: SDK 를 쓰는 게임만 설치): `com.geuneda.analytics.firebase`, `com.geuneda.analytics.airbridge`, `com.geuneda.analytics.appsflyer`, `com.geuneda.analytics.facebook`(예정)
- **기여 가이드**: 패키지 루트의 `AGENTS.md`
- **출처**: Lucky Defense Percent EventLogging(로드맵 4-1). sink 비트 팬아웃, 실패 sink 만 저장·재전송, 기록 시점 맥락 스냅샷은 따랐고, 재전송 트리거(백오프·복귀·네트워크 복구·다음 실행), 배치 전송, 4xx/5xx 규칙, 평문 저장(하드코딩 키 제거), 잠금 없는 저장(교착 회피), sink 별 큐, 이벤트 ID 중복 제거로 보완했다

## 핵심 API

전체 시그니처는 `references/api.md`.

- `new AnalyticsService(AnalyticsOptions)` → `IAnalyticsService`(`IDisposable`). `MainInstaller.Bind<IAnalyticsService>`, 정리는 `MainInstaller.CleanDispose<IAnalyticsService>()`. `Dispose` 는 메모리 이벤트를 저장하고 요청을 취소한다.
- `AnalyticsOptions`: `Identity`(설치 ID), `Clock`(`IAnalyticsClock`, 기본 기기 시계), `Session`(`IAnalyticsSessionSource`), `DefaultSinks`(기본 `All`), `StorageDirectory`(기본 `persistentDataPath/geuneda-analytics`), `MaxStoredBatchesPerSink` 500, `MaxQueuedEventsPerSink` 1000, `RetryDelay` 5초(최소 100ms), `MaxRetryDelay` 5분.
- `LogEvent(name, IReadOnlyDictionary<string, object> parameters = null)`, `LogEvent(name, parameters, AnalyticsSinks sinks)`, `SetUserId(string)`, `SetUserProperty(name, value)`, `AddSink(IAnalyticsSink)`, `DefaultSinks`, `UserId`, `UserProperties`.
- `AnalyticsSinks`(`[Flags]`): `Console` 1, `Collector` 2, `Firebase` 4, `Airbridge` 8, `AppsFlyer` 16, `Facebook` 32, `Custom1`~`Custom4`(1<<24~27), `All`.
- `IAnalyticsSink`: `Id`(비트 하나), `MaxBatchSize`, `BatchDelay`, `IsReady`, `SendAsync(events, ct)` → `AnalyticsSendResult`(`Delivered`, `Retry`, `Rejected`), `SetUserId`, `SetUserProperty`.
- `AnalyticsEvent`: `Id`, `Name`, `Parameters`(`AnalyticsParameter`: `Name`, `Value`), `TimestampUtc`, `IsServerTime`, `Sequence`, `SessionId`, `UserId`, `UserProperties`, `App`(`AnalyticsAppInfo`: `InstallId`, `AppVersion`, `Platform`, `Environment`, `DeviceModel`, `OperatingSystem`), `TryGetParameter`.
- `AnalyticsValue`: `Type`(`String`, `Integer`, `Float`, `Boolean`), `StringValue`/`IntegerValue`/`FloatValue`/`BooleanValue`(다른 형식이면 예외), `FromObject`, `ToObject`, `ToString`(문화권 무관).
- `ConsoleSink`: core 로거(`Geuneda.Analytics.Console`, Info)로 `이름 {키=값}`.
- `CollectorSink(IHttpClient, CollectorSinkOptions { Endpoint, MaxBatchSize = 50, BatchDelay = 10초, MaxBodyBytes = 1 MiB, Timeout = 15초 })`.
- `AppSessionAnalytics(IAppSession)`: `SessionId`, `LogSessionEvents(analytics, sinks)`, `Dispose`. 이벤트 이름 상수 `SessionStartEvent` 등, 파라미터 `ReasonParameter`.
- 서버: `services.AddGeunedaAnalytics(o => ...)`, `services.AddSingleton<IAnalyticsEventStore, ...>()`, `app.MapGeunedaAnalytics("/analytics")`(→ `POST /analytics/events`, `RouteHandlerBuilder`), `AnalyticsServerOptions`(`MaxBodyBytes` 1 MiB, `MaxEventsPerBatch` 500, `MaxNameLength` 100, `MaxParameters` 100, `MaxStringLength` 1000), `IAnalyticsEventStore.AppendAsync` → `AnalyticsAppendResult`(`Accepted`, `Duplicates`), `CollectedEvent`, `InMemoryAnalyticsEventStore`.

## 사용 패턴

```csharp
var session = new AppSessionAnalytics(appSession);                 // account 가 있을 때. 부트스트랩 소유자가 보관
var analytics = new AnalyticsService(new AnalyticsOptions
{
    Identity = MainInstaller.Resolve<IAppIdentity>(),
    Session = session,
    Clock = new TimeServiceAnalyticsClock(MainInstaller.Resolve<ITimeService>())
});

if (!AppEnv.IsProd) analytics.AddSink(new ConsoleSink());
analytics.AddSink(new CollectorSink(collectorHttp, new CollectorSinkOptions { Endpoint = "analytics/events" }));
session.LogSessionEvents(analytics, AnalyticsSinks.Collector);     // Firebase 는 session_start 를 예약해 둠
MainInstaller.Bind<IAnalyticsService>(analytics);

analytics.SetUserId(accountId);
analytics.LogEvent("stage_clear", new Dictionary<string, object> { { "stage", 3 }, { "result", "win" } });
analytics.LogEvent("ad_reward", parameters, AnalyticsSinks.Collector | AnalyticsSinks.Airbridge);

// 정리(재부트스트랩·종료): 세션 구독을 먼저 끊고 서비스를 닫는다
session.Dispose();
MainInstaller.CleanDispose<IAnalyticsService>();

// services ITimeService 를 시계로
public sealed class TimeServiceAnalyticsClock : IAnalyticsClock
{
    private readonly ITimeService _time;
    public TimeServiceAnalyticsClock(ITimeService time) { _time = time; }
    public DateTime UtcNow => _time.DateTimeUtcNow;
    public bool IsServerTime => _time.IsServerTime;
}
```

```csharp
// 수집 서버(ASP.NET Core)
builder.Services.AddGeunedaAnalytics();
builder.Services.AddSingleton<IAnalyticsEventStore, MyDbAnalyticsEventStore>();   // 이벤트 ID 고유 키
app.MapGeunedaAnalytics("/analytics").RequireRateLimiting("analytics");
```

## 규칙

- **메인 스레드**: 서비스와 sink 멤버는 메인 스레드에서 쓰고 불린다. 다른 스레드에서 서비스를 부르면 `InvalidOperationException` 이다. SDK 콜백은 core `MainThreadDispatcher.Post` 로 넘긴다.
- **오용은 예외**: 빈 이벤트 이름, `None` sinks, 빈 파라미터 이름, 지원하지 않는 값 형식(enum, char, `object`, `long` 범위를 넘는 `ulong`, NaN·무한대), 잘못된 sink(비트가 하나가 아님, `MaxBatchSize` < 1, 음수 `BatchDelay`, 같은 비트 두 번), 범위 밖 설정, `Dispose` 뒤 호출.
- **sink 등록 시점**: 부트스트랩에서 먼저 등록한다. 등록 전에 기록한 이벤트는 그 sink 로 가지 않는다. SDK 초기화가 늦으면 `IsReady` 를 false 로 두면 이벤트가 기다린다(1초마다 확인).
- **sink 등록**: 등록할 때 지금 사용자 ID(null 포함)와 속성을 알린다. sink 가 다른 스레드에서 `SendAsync` 를 끝내도 서비스가 메인 스레드로 돌아와 다음 호출을 한다.
- **디스크 실패**: 쓰지 못하면 5초 동안 다시 쓰지 않고 메모리 큐가 상한을 넘으면 오래된 이벤트부터 버린다(Warning). 저장 파일·목록을 읽지 못하면 저장된 배치만 백오프 뒤 다시 시도하고 새 이벤트는 계속 보낸다. 저장된 배치가 지금 `MaxBatchSize` 보다 크면 나눠 저장한 뒤 보낸다.
- **재전송**: `Retry` 면 그 sink 의 배치만 `StorageDirectory/<sink 이름 소문자>/` 에 평문 JSON 으로 저장해 백오프(5초부터 두 배씩 5분, 50~100%) 뒤, 포그라운드 복귀, 네트워크 복구, 다음 실행의 `AddSink` 때 그 sink 로만 다시 보낸다. 새 이벤트는 백오프를 깨지 않는다. 파일은 결과가 나온 뒤 지우므로 같은 이벤트가 두 번 갈 수 있다(수집 서버가 ID 로 거름).
- **일시정지·종료**: 메모리 이벤트와 보내는 중인 배치를 저장하고 배치 대기 없이 보낸다. 그 뒤 기록한 이벤트는 바로 저장한다. 플레이 중에만 숨은 수명 오브젝트를 만든다.
- **sink 예외**: `SendAsync` 예외는 Error 로그 후 그 배치를 버린다. `SetUserId`·`SetUserProperty` 예외는 Error 로그 후 다른 sink 는 계속.
- **공통 맥락**: 이벤트는 기록한 순간의 시각·순번·세션·사용자·속성·앱 정보를 담고 재전송해도 그대로다. 순번은 설치마다 1부터 늘지만 sink 마다 빈 번호가 있어 유실 판단에 쓰지 않는다.
- **이름 규칙**: 벤더 제한(길이, 접두사, 예약 이름)은 각 어댑터가 맞춘다. 자사 수집 서버 기본 상한은 이름 100자, 파라미터 100개, 문자열 1000자이고 넘는 이벤트는 그 이벤트만 거절된다.
- **자사 수집 응답**: 2xx 받음(이벤트별 거절은 Warning), 연결 실패·타임아웃·408·429·5xx·미들웨어 실패 코드는 재시도, 본문이 `MaxBodyBytes` 를 넘거나 413 이면 반으로 나눠 다시 보냄(이벤트 하나면 버림, 한 조각이 재시도면 전체 재시도), 그 밖 4xx 는 버림(Error).
- **서버 저장소**: `AppendAsync` 는 같은 ID 를 한 번만 저장한다(한 배치 안 중복 포함). 예외를 던지면 500 → 클라이언트 재전송. `CollectedEvent.Timestamp` 는 클라이언트 시계(`IsServerTime` 이 false 면 기기 시계)라 `ReceivedAt` 과 함께 본다.

## 함정

- `session_start` 등 세션 이벤트 이름은 Firebase 가 자동 이벤트로 예약해 두었다. 세션 이벤트는 `AnalyticsSinks.Collector` 로 보낸다.
- 다른 `IAppSession.Ended` 처리기가 기록한 이벤트에는 세션 ID 가 없다(세션이 이미 끝남). 세션 끝 이벤트는 `AppSessionAnalytics` 가 끝난 세션 ID 로 기록한다.
- 앱이 포그라운드에서 비정상 종료하면 아직 보내지 않은 메모리 이벤트는 사라진다(자사 수집은 최대 `BatchDelay` 만큼).
- 벤더 SDK 로 다시 보낸 이벤트의 시각은 SDK 가 보낸 시각이다.
- 저장 파일은 평문이다. 비밀 값을 이벤트에 넣지 않는다.
- sink 의 `Id` 와 `MaxBatchSize` 는 등록 뒤 바꾸지 않는다(저장 폴더 이름, 저장 배치 크기).
- 선택 어셈블리의 define(`GEUNEDA_ANALYTICS_HTTP`, `GEUNEDA_ANALYTICS_ACCOUNT`)은 그 asmdef 안에서만 정의된다. 게임 코드의 `#if` 로 쓰지 않는다.
- static 가변 상태가 없다. 인스턴스로 만들어 `MainInstaller` 에 `IAnalyticsService` 로 바인딩한다.
