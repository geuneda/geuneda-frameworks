# Geuneda Realtime API 레퍼런스

네임스페이스: `Geuneda.Realtime`(클라이언트·공유), `Geuneda.Realtime.Server`(서버). 어셈블리: `Geuneda.Realtime`, 선택 `Geuneda.Realtime.MessagePack`, 서버 `Geuneda.Realtime.Server`(.NET 10, `Server~/`), 분석기 `Geuneda.Realtime.Generator`. 사용 패턴과 함정은 [../SKILL.md](../SKILL.md) 참고.

---

## interface IRpcCaller

| 멤버 | 설명 |
|------|------|
| `UniTask<Result<TResponse>> CallAsync<TRequest, TResponse>(RpcMethod method, TRequest request, CancellationToken ct = default)` | 상태 0 → 본문을 읽은 값, 100000 이상 → 그 코드, 그 밖의 상태·본문 해석 실패 → `InvalidResponse`, 끊김 `NetworkError`, 시간 초과 `Timeout`, 취소 `Cancelled` |
| `UniTask<Result> CallAsync<TRequest>(RpcMethod method, TRequest request, CancellationToken ct = default)` | 본문을 읽지 않는 호출. 결과 규칙은 같음 |

## interface IRealtimeClient : IRpcCaller, IDisposable / sealed class RealtimeClient

| 멤버 | 설명 |
|------|------|
| `RealtimeState State` | `Disconnected`, `Connecting`, `Connected` |
| `event Action<RealtimeDisconnectInfo> Disconnected` | 연결된 세션이 끊겼을 때. `CloseStatus`, `Reason`, `WillReconnect` |
| `event Action<Result> Reconnected` | 자동 재연결이 끝났을 때(성공 또는 마지막 실패) 한 번 |
| `UniTask<Result> ConnectAsync(CancellationToken ct = default)` | 연결+로그인. single-flight. 정책 종료 상태도 풀고 다시 시도 |
| `IDisposable Subscribe<TPush>(RpcTopic topic, Action<TPush> handler)` | 푸시 구독. 같은 토픽에 여러 핸들러 가능. handler null → `ArgumentNullException` |
| `void Dispose()` | 연결을 닫고 재연결을 멈춤. 진행 중 호출·연결은 `Closed`, 이후 호출은 `ObjectDisposedException` |
| `RealtimeClient(RealtimeClientOptions options)` | options·ServerUri·Serializer·Transport null → `ArgumentNullException`, ws/wss 가 아니거나 시간·횟수 범위 밖 → `ArgumentException` |

## sealed class RealtimeClientOptions (생성 때 복사)

| 속성 | 기본값 | 설명 |
|------|--------|------|
| `Uri ServerUri` | (필수) | `wss://` 권장 |
| `IRpcSerializer Serializer` | `JsonRpcSerializer` | |
| `IRealtimeTransport Transport` | `ClientWebSocketTransport` | |
| `Func<IRpcCaller, CancellationToken, UniTask<Result>> LoginAsync` | null | 연결마다 메인 스레드에서 부름. 실패면 연결 실패, 예외는 그대로 전달. 토큰을 무시해도 `ConnectTimeout`·Dispose 가 들음 |
| `bool ConnectOnCall` | true | 끄면 연결 없을 때 `NotConnected` |
| `TimeSpan ConnectTimeout` | 10초 | 연결+로그인 |
| `TimeSpan RequestTimeout` | 10초 | 보내기 차례 대기부터 |
| `TimeSpan PingInterval` | 15초 | `Zero` 면 핑 없음 |
| `TimeSpan PingTimeout` | 10초 | 퐁이 `Interval + Timeout` 동안 없으면 끊김(1006) |
| `int MaxReconnectAttempts` | 5 | 0 이면 자동 재연결 안 함 |
| `TimeSpan ReconnectBaseDelay` / `ReconnectMaxDelay` | 1초 / 30초 | n 번째 대기 = `min(Max, Base × 2^n)` × [0.5, 1.0) |
| `Action<Action> CallbackDispatcher` | `UniTask.Post` | 이벤트·푸시 실행 위치. 스레드 안전해야 함 |

## 경로

- `readonly struct RpcMethod { string Name; uint Id; static RpcMethod Of(string name); }` — 이름이 비면 `ArgumentException`.
- `readonly struct RpcTopic { string Name; uint Id; static RpcTopic Of(string name); }`
- `static class Fnv1a32 { static uint Hash(string value); }` — UTF-8, offset 2166136261, prime 16777619.

## 직렬화

- `interface IRpcSerializer { string Name; byte[] Serialize<T>(T value); T Deserialize<T>(ArraySegment<byte> payload); }` — 빈 본문 → `default`, 읽기 실패는 `RpcSerializationException` 만. 스레드 안전해야 함.
- `JsonRpcSerializer(JsonSerializerSettings settings = null)` — Name `json`, UTF-8 Newtonsoft.
- `MessagePackRpcSerializer(MessagePackSerializerOptions options = null)` — Name `msgpack`, 기본 옵션은 `UntrustedData` 보안. `org.nuget.messagepack` ≥ 3.0.0 또는 `GEUNEDA_MESSAGEPACK` 일 때만 컴파일.

## 프로토콜

- `enum RpcFrameKind : byte { Request = 1, Response = 2, Push = 3, Ping = 4, Pong = 5 }`
- `readonly struct RpcFrame` — `Kind`, `Flags`, `Id`, `Value`, `Payload`; `RequestId`, `MethodId`, `Status`, `TopicId`, `Sequence`; `Request/Response/Push/Ping/Pong` 팩토리.
- `static class RpcFrameCodec { byte[] Encode(in RpcFrame); bool TryDecode(ArraySegment<byte>, out RpcFrame); }` — 빅엔디언. Request·Response 헤더 10바이트(종류, flags 0, ID u32, 값 i32), Push·Ping·Pong 6바이트. flags ≠ 0, Ping·Pong 본문, 모르는 종류, 짧은 헤더는 false.
- 서브프로토콜: `geuneda.rpc.v1.<Serializer.Name>`.

## 전송

- `interface IRealtimeTransport { UniTask<Result<IRealtimeConnection>> ConnectAsync(Uri uri, string subProtocol, CancellationToken ct); }` — 실패 `NetworkError`, 취소 `Cancelled`, 서브프로토콜 불일치 `ProtocolMismatch`.
- `interface IRealtimeConnection : IDisposable` — `SendAsync(ArraySegment<byte>, ct) → UniTask<bool>`(끊김 false), `ReceiveAsync(ct) → UniTask<RealtimeReceiveResult>`(전송 오류도 종료 결과, 취소만 예외, 배열 재사용 안 함), `CloseAsync(status, reason, ct)`(예외 없음). 결과는 어느 스레드에서 끝나도 됨.
- `readonly struct RealtimeReceiveResult { bool IsClosed; ArraySegment<byte> Message; int CloseStatus; string CloseReason; }`
- `ClientWebSocketTransport` — `ClientWebSocket`. 바이너리만, 메시지 최대 16MB(넘으면 1009), 텍스트 1003. 소켓 작업은 `ConfigureAwait(false)`.

## 계약과 생성 코드

- `[RpcService]`(interface), `[RpcAllowAnonymous]`(method). 경로 이름 `"인터페이스 이름/메서드 이름"`, ID 는 FNV-1a.
- 허용 모양: `Task<TRes> M(TReq)`, `Task M(TReq)`, `Task<TRes> M()`, `Task M()`, 그리고 각각 끝에 `CancellationToken`. 인터페이스 안의 중첩 형식·상수 허용.
- 클라이언트 생성 코드(계약 어셈블리가 `Geuneda.Realtime` 참조 시, 계약과 같은 네임스페이스·접근성):
  - `static class XxxMethods { static readonly RpcMethod <메서드>; }`
  - `interface IXxxClient`, `sealed class XxxClient(IRpcCaller caller)` — 메서드마다 `UniTask<Result<TRes>>`(응답 없으면 `UniTask<Result>`) `M(TReq request, CancellationToken cancellationToken = default)`. 인자 없는 메서드는 `M(CancellationToken)`.
- 서버 생성 코드(`Geuneda.Realtime.Server.RpcRoute` 참조 시): `namespace <어셈블리 이름> { public static class GeneratedRpcRoutes { IReadOnlyList<RpcRoute> All } }`.
- 진단(모두 오류): GRPC001 반환 형식, GRPC002 인자, GRPC003 제네릭 메서드, GRPC004 오버로드, GRPC005 제네릭 인터페이스, GRPC006 중첩 인터페이스, GRPC007 상속, GRPC008 속성·이벤트·static·기본 구현, GRPC009 인터페이스 이름 중복, GRPC010 ID 충돌, GRPC011 UniTask·Geuneda.Core 참조 없음, GRPC012 메서드 이름이 생성 멤버 이름과 같음, GRPC013 서비스끼리 생성 형식 이름이 같음, GRPC014 생성할 형식이 이미 있음. 오류가 있으면 코드를 만들지 않음. 예약어 메서드 이름은 이스케이프됨.

## 서버 (`Geuneda.Realtime.Server`)

| 멤버 | 설명 |
|------|------|
| `IServiceCollection.AddRealtimeRpc(Action<RealtimeServerOptions>)` | 레지스트리·핸들러·`IRpcContext`(scoped) 등록. 계약 구현은 따로 `AddScoped<IShopRpc, ShopRpc>()` |
| `IEndpointRouteBuilder.MapRealtimeRpc(string pattern)` | `UseWebSockets()` 뒤. 설정·라우트 ID 중복·구현 미등록이면 `InvalidOperationException` |
| `RealtimeServerOptions` | `Routes`/`AddRoutes`, `Serializers`(기본 JSON), `MaxMessageSize` 16MB, `IdleTimeout` 60초, `MaxQueuedRequests` 256(넘치면 Overloaded), `CloseTimeout` 5초 |
| `IRpcContext` | `Session`, `Route`, `RequestId`, `CallAborted`(세션이 닫히기 시작하면 취소), `SignIn(userId)`(다른 사용자로 다시 부르면 `InvalidOperationException`, 닫히는 세션이면 `OperationCanceledException`). 호출 밖에서 쓰면 `InvalidOperationException` |
| `IRealtimeSession` | `Id`, `UserId`, `IsAuthenticated`, `SubProtocol`, `Items`, `Closed`, `PushAsync<T>(RpcTopic, T, ct) → Task<bool>`, `CloseAsync(int status)`(보낼 수 없는 코드면 `ArgumentOutOfRangeException`, 남은 요청 미실행) |
| `IRealtimeSessions` | `FindByUser(userId)`, `All`. 사용자당 세션 하나 |
| `RpcStatusException(int status, string message = null)` | 응답 상태로 실패. 100000 미만이면 `ArgumentOutOfRangeException` |
| `RpcRoute` | `Name`, `Id`, `ServiceType`, `AllowAnonymous`, `Create<TService,TReq,TRes>`/`Create<TService,TReq>`(생성 코드가 씀, ID 가 이름 해시가 아니면 `ArgumentException`), `RpcEmpty`(인자 없는 메서드의 요청 형식) |

동작: 서브프로토콜은 클라이언트가 요청한 것 중 서버 `Serializers` 의 첫 것(없으면 서브프로토콜 없이 받고 1002), 세션당 순차 실행, 핑 즉시 응답, 텍스트 1003·크기 초과 1009·잘못된 프레임 1002·무응답 1001, 클라이언트 종료 코드 되돌림.

## 코드

- `static class RealtimeResultCodes` — `RangeStart = 2000`(코드 아님), `NotConnected = 2001`, `NotReconnectable = 2002`, `Closed = 2003`, `InvalidResponse = 2004`, `ProtocolMismatch = 2005`.
- `static class RpcStatusCodes`(응답 상태, 클라이언트·서버 공유) — `Success = 0`, `InternalError = 100000`, `Unauthenticated = 100001`, `MethodNotFound = 100002`, `BadRequest = 100003`, `Overloaded = 100004`, `FrameworkRangeEnd = 100999`, `GameRangeStart = 101000`.
- `static class RpcProtocol` — `SubProtocolPrefix = "geuneda.rpc.v1."`, `SubProtocolOf(serializerName)`.
- `static class RealtimeCloseCodes` — `Normal 1000`, `GoingAway 1001`, `ProtocolError 1002`, `UnsupportedData 1003`, `Abnormal 1006`, `MessageTooBig 1009`, `PolicyRangeStart 4000`, `PolicyRangeEnd 4999`, `DuplicateLogin 4001`, `Maintenance 4002`, `Kicked 4003`, `static bool IsReconnectable(int)`.
- `readonly struct RealtimeDisconnectInfo { int CloseStatus; string Reason; bool WillReconnect; }`, `enum RealtimeState { Disconnected, Connecting, Connected }`.
