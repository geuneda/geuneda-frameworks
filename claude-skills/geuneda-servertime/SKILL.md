---
name: geuneda-servertime
description: com.geuneda.servertime 패키지(네임스페이스 Geuneda.ServerTime)로 서버 시간 동기화 코드를 작성하거나 수정할 때 사용하는 스킬. IServerTimeSync·ServerTimeSync·ServerTimeSyncOptions 로 서버 시각을 맞추거나(SyncAsync, Start/Stop 백그라운드 동기화, 지수 백오프 재시도, 30분 재동기화, 포그라운드 복귀 재동기화), NTP(NtpTimeSource, time.google.com)·HTTPS Date 헤더(HttpDateTimeSource)·게임 서버 API 시각을 IServerTimeSource 원천으로 쓰거나 직접 구현하거나, ServerTimeSample 로 왕복 지연을 보정하거나, ServerTimeResultCodes(6000 블록: InvalidResponse, RoundTripTooLong)를 처리하거나, services 시간 서비스의 IsServerTime·TimeAdjusted 로 일일 초기화 기준 시각과 타이머를 다루거나, 기기 시계 조작 방지(서버 기준점 + 단조 시계)를 설계할 때 활성화한다.
---

# Geuneda Server Time

서버 시간 동기화다. 시간 원천(NTP, HTTPS `Date` 헤더, 직접 구현)에서 서버 시각을 가져와 왕복 지연을 보정하고 services 시간 서비스의 기준점(`ITimeManipulator.SetServerTime`)으로 넣는다. 이후 현재 시각은 core 단조 시계로 흐르므로 기기 시계를 바꿔도 영향받지 않는다. 결과는 core 결과 규약(`Result`)을 따른다.

## 패키지 정보

- **버전**: 0.1.0
- **네임스페이스 / 어셈블리**: `Geuneda.ServerTime`
- **설치**: `https://github.com/geuneda/geuneda-servertime.git` (core, gamedata, services, http, UniTask git URL 도 함께)
- **의존성**: `com.geuneda.core` 0.4.0(Result, ModuleLogger, `IMonotonicClock`), `com.geuneda.services` 5.0.0(`ITimeManipulator`), `com.geuneda.http` 0.1.0(`HttpDateTimeSource`), `com.cysharp.unitask` 2.5.10. services 와 http 가 서로 의존하지 않도록 동기화를 별도 패키지로 뺐다
- **최소 Unity 버전**: 6000.3
- **기여 가이드**: 패키지 루트의 `AGENTS.md`
- **출처**: Lucky Defense Percent.Time(로드맵 2-2). NTP 먼저·HTTP 대체, 단조 시계 기준점, `IsServerTime` 은 따랐고, 왕복 지연 보정·재동기화·포그라운드 복귀 재동기화·지수 백오프·잠자기 포함 단조 시계·NTP 응답 검증·DNS 포함 전체 제한 시간·백그라운드를 건넌 표본 버리기로 보완했다

## 핵심 API

전체 시그니처는 `references/api.md`.

- `new ServerTimeSync(ITimeManipulator time, IEnumerable<IServerTimeSource> sources, ServerTimeSyncOptions options = null, IMonotonicClock clock = null)` → `IServerTimeSync`. `MainInstaller.Bind<IServerTimeSync>`.
- `SyncAsync(ct)` → `Result<ServerTimeSample>`. 원천을 순서대로 시도해 처음 성공한 표본으로 맞춘다. 모두 실패하면 첫 실패 코드와 원천별 실패 내용.
- `Start()` / `Stop()`: 백그라운드 동기화. `Dispose()` 는 `Stop()`.
- `ServerTimeSyncOptions`: `ResyncInterval`(30분), `RetryDelay`(5초), `MaxRetryDelay`(5분), `MaxRoundTrip`(10초).
- `IServerTimeSource`: `string Name`, `FetchAsync(IMonotonicClock clock, CancellationToken ct)` → `Result<ServerTimeSample>`.
- `NtpTimeSource(host = "time.google.com", port = 123, timeout = 5초)`, `HttpDateTimeSource(IHttpClient http, string uri, timeout = 5초)`.
- `ServerTimeSample(DateTime serverUtc, TimeSpan receivedAt, TimeSpan roundTrip)`: 받은 순간의 서버 시각(`Kind` 는 `Utc`), 그 순간의 단조 시계 값, 왕복.
- `ServerTimeResultCodes`: `InvalidResponse` 6001, `RoundTripTooLong` 6002.
- 맞췄는지는 services `ITimeService.IsServerTime`, 시각이 바뀐 것은 `ITimeService.TimeAdjusted`.

## 사용 패턴

```csharp
using System.Threading;
using Cysharp.Threading.Tasks;
using Geuneda.Http;
using Geuneda.ServerTime;
using Geuneda.Services;

public static async UniTask InitializeAsync(CancellationToken cancellationToken)
{
    var time = new TimeService();
    MainInstaller.Bind<ITimeService>(time);
    MainInstaller.Bind<ITimeManipulator>(time);

    // 재시도 미들웨어 없는 클라이언트(실패한 시도까지 왕복에 들어가 추정이 어긋남)
    var http = new HttpClientBuilder().Build();
    var sync = new ServerTimeSync(time, new IServerTimeSource[]
    {
        new NtpTimeSource(),                                            // time.google.com
        new HttpDateTimeSource(http, "https://api.mygame.com/health")  // NTP 가 막힌 망·WebGL 대체
    });
    MainInstaller.Bind<IServerTimeSync>(sync);

    // 부팅 때 한 번 기다리고(실패해도 진행할지 게임이 정함), 이후는 백그라운드로 맞춘다
    var result = await sync.SyncAsync(cancellationToken);

    // 초기화 자체가 취소되면 백그라운드 동기화를 시작하지 않는다(등록한 바인딩 정리는 초기화 소유자가 함)
    cancellationToken.ThrowIfCancellationRequested();

    if (!result.IsSuccess)
    {
        // 네트워크 실패: 기기 시계 기준으로 진행(time.IsServerTime == false). Start 가 계속 다시 시도
    }

    sync.Start();
}
```

```csharp
// 일일 초기화: 서버 시각을 받은 뒤에만 판정하고, 시각이 바뀌면 타이머를 다시 계산한다
var time = MainInstaller.Resolve<ITimeService>();
time.TimeAdjusted += delta => RescheduleDailyReset();   // 재동기화로 음수일 수 있음

if (time.IsServerTime && time.DateTimeUtcNow >= nextResetUtc)
{
    ResetDaily();
}
```

결과:

| 상황 | 결과 코드 |
|------|-----------|
| 성공 | 0 |
| 호출자 취소 | `ResultCodes.Cancelled` |
| 원천 제한 시간 초과 | `ResultCodes.Timeout` |
| DNS 실패, 연결·전송 실패, WebGL 의 NTP | `ResultCodes.NetworkError` |
| NTP 응답 검증 실패, `Date` 헤더 없음·형식 오류, 2024년 이전 시각 | `InvalidResponse` 6001 |
| 왕복이 `MaxRoundTrip` 보다 김 | `RoundTripTooLong` 6002 |
| 원천이 결과 대신 던진 예외(버그·오용) | `SyncAsync` 가 그대로 던짐. 백그라운드 동기화는 Error 로그 후 멈춤 |
| null 시간 서비스·원천 목록·`IHttpClient`, 빈 목록·null 원천, `ResyncInterval` 1초·`RetryDelay` 100ms 미만, 0 이하 `MaxRoundTrip`, `MaxRetryDelay` < `RetryDelay`, 빈 호스트·잘못된 포트·http(s) 절대 주소가 아닌 URI·0 이하 제한 시간, UTC 가 아닌 표본·음수 왕복 | 예외 |

## 규칙

- **원천 순서**: 목록 순서대로 시도해 처음 성공한 표본을 쓴다. 원천이 결과 대신 던진 예외(버그·오용)는 숨기지 않는다. `SyncAsync` 는 그대로 던지고(다음 원천을 시도하지 않음), 백그라운드 동기화는 Error 로그를 남기고 멈춘다. 직접 만드는 원천은 정상 실패(네트워크, 제한 시간, 취소, 응답 검증)만 결과 코드로 돌려준다.
- **왕복 보정**: 표본은 응답을 받은 순간의 서버 시각 추정값과 그 순간의 단조 시계 값이다. 적용할 때 받은 뒤 흐른 시간을 더해 `SetServerTime` 에 넣는다(`ServerUtc + (지금 - ReceivedAt)`). 왕복이 `MaxRoundTrip` 보다 긴 표본은 버린다(응답을 기다리는 동안 앱이 백그라운드에 있었으면 추정이 크게 틀림).
- **같은 시계**: 시간 서비스와 동기화는 같은 `IMonotonicClock` 을 써야 한다. 둘 다 기본 생성자면 core `MonotonicClock` 이다. `TimeService(clock)` 로 만들었다면 `ServerTimeSync(..., clock: clock)` 로 같은 시계를 넘긴다.
- **백그라운드 동기화(`Start`)**: 맞춘 적 없으면 바로 맞춘다. 실패하면 `RetryDelay` 부터 두 배씩 `MaxRetryDelay` 까지 기다렸다 다시 시도한다(대기는 상한의 50~100% 무작위). 성공하면 `ResyncInterval` 마다 다시 맞춘다. 이미 돌고 있으면 `Start` 는 아무것도 하지 않고, `Stop` 은 진행 중인 요청을 취소한다. 앱이 끝나거나(에디터에서는 플레이를 멈출 때) 숨은 수명 오브젝트가 파괴되면 스스로 멈춘다. 설정 최솟값은 `ResyncInterval` 1초, `RetryDelay` 100ms(`ServerTimeSyncOptions.MinResyncInterval`/`MinRetryDelay`).
- **포그라운드 복귀**: `Start` 는 플레이 중에만 숨은 `DontDestroyOnLoad` 컴포넌트(`HideInHierarchy`)를 만들어 `OnApplicationPause` 를 받는다. 일시정지를 먼저 받은 복귀만 본다(Unity 문서상 오브젝트가 시작할 때도 오는 `OnApplicationPause(false)` 대비). 일시정지 뒤에 돌아오면 기다리던 중이면 바로, 맞추는 중이면 끝난 뒤 한 번 더 맞추고 재시도 간격을 처음으로 되돌린다. 에디트 모드에서는 컴포넌트를 만들지 않는다.
- **스레드**: 메인 스레드에서 부른다. 원천이 다른 스레드에서 끝나도 메인 스레드로 돌아와 시간 서비스를 바꾼다.
- **재동기화로 시각이 조금 뒤로 갈 수 있다**: `TimeAdjusted` 의 값이 음수일 수 있다. 타이머는 `TimeAdjusted` 에서 다시 계산한다.
- **직접 구현 원천**: 보내기 직전·받은 직후의 `clock.Elapsed` 로 왕복을 재고 서버 시각(UTC)에 왕복의 절반을 더해 `new ServerTimeSample(serverUtc, receivedAt, roundTrip)` 을 만든다. 정상 실패는 `Result` 코드로 돌려주고, 제한 시간은 원천이 정한다. 어느 스레드에서 끝나도 된다.

## 원천 고르기

| 원천 | 정확도 | 비고 |
|------|--------|------|
| `NtpTimeSource` | 수십 ms | UDP 123, DNS 조회부터 응답까지 제한 시간 5초, 서버 작업 없음. 일부 망은 UDP 123 을 막고 WebGL 은 바로 `NetworkError` |
| `HttpDateTimeSource` | 1~2초 | 자사 서버 주소로 `HEAD` 를 보내 `Date` 헤더를 씀(서버 작업 없음). HTTPS 면 위조가 어려움 |
| 직접 구현 `IServerTimeSource` | 서버에 따름 | 게임 서버 API·실시간 RPC 가 밀리초 시각을 줄 때 |

보통 `NtpTimeSource` 다음에 `HttpDateTimeSource` 를 둔다.

## 함정

- `HttpDateTimeSource` 에는 재시도 미들웨어(`RetryMiddleware`) 없는 `IHttpClient` 를 넘긴다. 실패한 시도까지 왕복에 들어가 추정이 어긋난다(실패하면 `ServerTimeSync` 가 다시 시도).
- `HttpDateTimeSource` 는 상태 코드를 보지 않는다(404 도 서버 시계의 `Date` 를 담음). `Cache-Control: no-cache` 를 보내지만 CDN 캐시를 거치지 않는 API 주소를 쓴다. `Date` 는 초 단위라 0.5초와 왕복의 절반을 더한다.
- 동기화 전(`IsServerTime == false`)에는 생성할 때의 기기 시계 기준이다. 보상·일일 초기화처럼 조작이 문제 되는 판정은 서버 시각을 받은 뒤에 하거나 서버가 한다.
- 기기 시계 조작은 막는다(현재 시각은 서버 기준점 + 단조 시계). 동기화 성공 로그(Info)에 기기 시계와의 차이를 남긴다. NTP 응답 위조와 HTTPS 인증서를 심은 프록시는 막지 못하므로 위조가 문제 되는 값은 서버가 판정한다.
- `SyncAsync` 가 실패한 뒤 계속 진행할지는 게임이 정한다. 실패해도 `Start` 가 계속 다시 시도한다.
- `SetServerTime` 을 직접 부르면 왕복 보정·재동기화가 없다. 서버 시각은 이 패키지로 넣는다.
- static 가변 상태가 없다. 인스턴스로 만들어 `MainInstaller` 에 `IServerTimeSync` 로 바인딩한다.
