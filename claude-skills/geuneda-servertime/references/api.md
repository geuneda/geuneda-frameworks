# Geuneda Server Time API 레퍼런스

네임스페이스 `Geuneda.ServerTime`. 결과는 core `Result`/`Result<T>`. 버전 0.2.0.

## 동기화 (`Runtime/`)

### interface IServerTimeSync : IDisposable / sealed class ServerTimeSync : IServerTimeSync

| 멤버 | 설명 |
|------|------|
| `ServerTimeSync(ITimeManipulator time, IEnumerable<IServerTimeSource> sources, ServerTimeSyncOptions options = null, IMonotonicClock clock = null)` | `options` 가 null 이면 기본값, `clock` 이 null 이면 core `MonotonicClock`(시간 서비스와 같은 시계여야 함). `time`·`sources` null 은 `ArgumentNullException`, 원천이 없거나 null 원천이 있으면 `ArgumentException`, `ResyncInterval` 이 1초(`MinResyncInterval`) 미만, `RetryDelay` 가 100ms(`MinRetryDelay`) 미만, `MaxRoundTrip` 이 0 이하이거나 `MaxRetryDelay` 가 `RetryDelay` 보다 작으면 `ArgumentOutOfRangeException` |
| `UniTask<Result<ServerTimeSample>> SyncAsync(CancellationToken ct = default)` | 원천을 순서대로 시도해 처음 성공하고 왕복이 `MaxRoundTrip` 이하인 표본을 적용(`SetServerTime(ServerUtc + (지금 - ReceivedAt))`, Info 로그에 기기 시계와의 차이). 왕복이 길면 `RoundTripTooLong` 으로 보고 다음 원천. 원천이 결과 대신 던진 예외(버그·오용)는 그대로 던지고 다음 원천을 시도하지 않음, 호출자 취소로 난 취소 예외는 `Cancelled`. 모두 실패하면 첫 실패 코드와 `원천 이름: 결과` 목록(Warning 로그). 원천 사이에 취소되면 `Cancelled`. 원천이 다른 스레드에서 끝나도(예외 포함) 메인 스레드로 돌아와 적용 |
| `void Start()` | 백그라운드 동기화 시작. 이미 돌고 있으면 무시. 플레이 중이면 `OnApplicationPause`·`OnApplicationQuit`·`OnDestroy` 를 받는 숨은 `DontDestroyOnLoad` 오브젝트(`HideInHierarchy`)를 만듦. 앱 종료(에디터는 플레이 정지)·오브젝트 파괴 때 스스로 멈춤. 원천이 예외를 던지면 Error 로그 후 멈춤 |
| `void Stop()` | `Start` 가 시작한 백그라운드 동기화를 멈춤(직접 부른 `SyncAsync` 는 그 호출의 토큰으로 취소). 상태를 먼저 비우고 숨은 오브젝트를 끊어 삭제한 뒤 진행 중인 요청을 취소(취소 콜백 안에서 `Start` 해도 새 실행은 남음, 콜백 예외는 `AggregateException`) |
| `void Dispose()` | `Stop()`. 여러 번 불러도 됨. `IServerTimeSync` 가 `IDisposable` 이라(0.2.0) `MainInstaller.CleanDispose<IServerTimeSync>()` 가 부르고 바인딩을 지움 |

백그라운드 루프의 다음 대기:

- 일시정지 뒤 복귀를 받았으면 0(그때 재시도 횟수도 0 으로)
- n 번 연속 실패했으면 `min(MaxRetryDelay, RetryDelay × 2^(n-1))` × (0.5 + 0.5 × 무작위)(틱으로 계산)
- 맞춘 적 없으면 0, 아니면 `ResyncInterval - (지금 - 마지막 성공)`(0 이상)

일시정지 없이 받은 `OnApplicationPause(false)`(Unity 가 컴포넌트 시작 때 부름)는 무시한다. 맞추는 중에 복귀하면 끝난 뒤 한 번 더 맞춘다.

### sealed class ServerTimeSyncOptions

| 속성 | 기본 | 설명 |
|------|------|------|
| `TimeSpan ResyncInterval` | 30분 | 성공한 뒤 다시 맞추는 간격. 최소 `MinResyncInterval`(1초) |
| `TimeSpan RetryDelay` | 5초 | 모든 원천이 실패한 뒤 첫 재시도 대기 상한. 실패마다 두 배. 최소 `MinRetryDelay`(100ms, 대기가 0 이 되어 메인 스레드를 양보하지 않고 도는 것을 막음) |
| `TimeSpan MaxRetryDelay` | 5분 | 재시도 대기 상한의 최댓값 |
| `TimeSpan MaxRoundTrip` | 10초 | 받아들이는 최대 왕복. 넘으면 표본을 버리고(`RoundTripTooLong`) 다음 원천 |

## 시간 원천

### interface IServerTimeSource

| 멤버 | 설명 |
|------|------|
| `string Name` | 로그 이름(예: `ntp:time.google.com`) |
| `UniTask<Result<ServerTimeSample>> FetchAsync(IMonotonicClock clock, CancellationToken ct)` | 보내기 직전·받은 직후에 `clock` 을 읽어 왕복을 보정한 표본. 정상 실패는 `NetworkError`·`Timeout`·`Cancelled`·`InvalidResponse`. 제한 시간은 원천이 정함. 어느 스레드에서 끝나도 됨 |

### readonly struct ServerTimeSample

| 멤버 | 설명 |
|------|------|
| `ServerTimeSample(DateTime serverUtc, TimeSpan receivedAt, TimeSpan roundTrip)` | `serverUtc.Kind` 가 `Utc` 가 아니면 `ArgumentException`, `roundTrip` 이 음수면 `ArgumentOutOfRangeException` |
| `DateTime ServerUtc` | `ReceivedAt` 순간의 서버 시각 추정값(UTC) |
| `TimeSpan ReceivedAt` | 응답을 받은 순간의 `IMonotonicClock.Elapsed` |
| `TimeSpan RoundTrip` | 네트워크 왕복(서버 처리 시간을 뺄 수 있으면 뺌). 추정 오차는 대략 이 값의 절반 이내 |

### sealed class NtpTimeSource : IServerTimeSource

| 멤버 | 설명 |
|------|------|
| `const string DefaultHost = "time.google.com"`, `const int DefaultPort = 123`, `static readonly TimeSpan DefaultTimeout`(5초) | |
| `NtpTimeSource(string host = DefaultHost, int port = DefaultPort, TimeSpan? timeout = null)` | 빈 호스트는 `ArgumentException`, 포트 1~65535 밖·제한 시간 0 이하는 `ArgumentOutOfRangeException`. `Name` 은 `ntp:<host>` |
| `FetchAsync` | SNTP v4 요청. DNS 조회·보내기·받기와 시각 측정을 스레드 풀 작업 하나에서 하고, 주소가 여러 개면 소켓 오류 때 다음 주소. DNS 부터 응답까지 전체 제한 시간을 넘으면 `Timeout`(소켓 수신 시간 초과 포함, 호출자 취소와 한곳에서 가름), DNS·소켓 실패는 `NetworkError`. 정상 실패만 결과로 바꾸고 예상하지 못한 예외는 던짐(제한 시간·취소로 돌아간 뒤에 끝난 작업의 예외는 Error 로그). 메인 스레드에서 불렸으면 메인 스레드로 돌아옴. WebGL 은 바로 `NetworkError` |

응답 검증(실패는 `InvalidResponse`): 48바이트 이상, 서버 모드(4), 버전 3~4, 계층 0(Kiss-o'-Death) 거절, 윤초 표시 3·계층 16 이상 거절, originate 가 요청 전송 타임스탬프의 암호학적 난수와 같음, 수신·전송 타임스탬프 있음, 2024-01-01 이후. 서버 시각 = 전송 타임스탬프 + (왕복 - 서버 처리 시간) / 2. 타임스탬프는 RFC 4330 3절의 두 시대(최상위 비트 0 이면 2036-02-07 06:28:16 UTC 기준)로 읽는다. 연결한 UDP 소켓이라 다른 주소의 데이터그램은 받지 않는다.

### sealed class HttpDateTimeSource : IServerTimeSource

| 멤버 | 설명 |
|------|------|
| `static readonly TimeSpan DefaultTimeout` | 5초 |
| `HttpDateTimeSource(IHttpClient http, string uri, TimeSpan? timeout = null)` | null `http` 는 `ArgumentNullException`, http·https 절대 주소가 아니면 `ArgumentException`, 제한 시간 0 이하는 `ArgumentOutOfRangeException`. `Name` 은 `http:<호스트>` |
| `FetchAsync` | `HEAD` + `Cache-Control: no-cache` + 제한 시간. 전송 실패는 http 결과 코드 그대로. 상태 코드는 보지 않음. `Date`(RFC 9110 IMF-fixdate)가 없거나 형식이 틀리거나 2024년 이전이면 `InvalidResponse`. 서버 시각 = `Date` + 0.5초 + 왕복 / 2 |

재시도 미들웨어가 있는 클라이언트를 넘기면 실패한 시도까지 왕복에 들어가 추정이 어긋난다. 재시도 없는 클라이언트를 넘긴다.

## 코드 (`ServerTimeResultCodes`, 6000 블록)

| 코드 | 이름 | 뜻 |
|------|------|----|
| 6000 | `RangeStart` | 블록 시작. 코드로 쓰지 않음 |
| 6001 | `InvalidResponse` | 응답에서 쓸 수 있는 시각을 얻지 못함(NTP 응답 검증 실패, `Date` 헤더 없음·형식 오류, 2024년 이전 시각) |
| 6002 | `RoundTripTooLong` | 왕복이 `MaxRoundTrip` 보다 길어 표본을 버림 |

연결 실패·제한 시간·취소는 core `ResultCodes.NetworkError`·`Timeout`·`Cancelled`. 원천이 던진 예외는 결과 코드로 바꾸지 않는다.

## services 시간 서비스와의 관계

- 동기화는 `ITimeManipulator.SetServerTime(DateTime)` 만 부른다. 이후 `ITimeService.IsServerTime` 은 true, 현재 시각이 바뀐 양은 `ITimeService.TimeAdjusted`(음수 가능).
- 현재 시각 = 서버 기준점 + core 단조 시계 경과(+ `AddTime` 오프셋). 기기 시계 변경에 영향받지 않는다.
- 시간 서비스와 동기화는 같은 `IMonotonicClock` 이어야 한다. 테스트는 `Elapsed` 를 직접 정하는 가짜 시계를 `TimeService(clock)` 과 `ServerTimeSync(..., clock: clock)` 에 함께 넘긴다.

## 테스트

EditMode `Geuneda.ServerTime.Tests.EditMode`: `NtpPacketTest`(요청 형식, 왕복·서버 처리 보정, 버전·모드·계층·윤초·Kiss-o'-Death·originate·2024년 이전 거절, 두 시대 변환), `NtpTimeSourceTest`(127.0.0.1 가짜 UDP 서버로 실제 소켓·스레드 풀, 메인 스레드 복귀, 제한 시간·취소·없는 호스트), `HttpDateTimeSourceTest`(가짜 `IHttpClient`, 로컬 `HttpListener` 와 실제 UnityWebRequest 로 `HEAD` 의 `Date`), `ServerTimeSyncTest`(가짜 원천·시계·지연으로 순서·대체·긴 왕복·원천 예외 전파·취소, 재동기화 간격, 지수 백오프와 상한, 최소 설정, 포그라운드 복귀, Stop/Start 와 취소 콜백 재진입, `CleanDispose<IServerTimeSync>()`·`Dispose` 두 번). PlayMode `Geuneda.ServerTime.Tests.PlayMode`: `ServerTimeSyncLifecycleTest`(시작 직후 한 번만 동기화, 일시정지·복귀, 오브젝트 파괴·`OnApplicationQuit`·`CleanDispose<IServerTimeSync>()` 가 멈춤, 옛 오브젝트의 늦은 파괴).
