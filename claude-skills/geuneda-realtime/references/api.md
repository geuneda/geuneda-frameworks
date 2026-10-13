# Geuneda Realtime API 레퍼런스

네임스페이스: `Geuneda.Realtime`. 어셈블리: `Geuneda.Realtime`, 선택 `Geuneda.Realtime.MessagePack`. 사용 패턴과 함정은 [../SKILL.md](../SKILL.md) 참고.

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
- `MessagePackRpcSerializer(MessagePackSerializerOptions options = null)` — Name `msgpack`. `org.nuget.messagepack` ≥ 3.0.0 또는 `GEUNEDA_MESSAGEPACK` 일 때만 컴파일.

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

## 코드

- `static class RealtimeResultCodes` — `RangeStart = 2000`(코드 아님), `NotConnected = 2001`, `NotReconnectable = 2002`, `Closed = 2003`, `InvalidResponse = 2004`, `ProtocolMismatch = 2005`.
- `static class RealtimeCloseCodes` — `Normal 1000`, `GoingAway 1001`, `ProtocolError 1002`, `UnsupportedData 1003`, `Abnormal 1006`, `MessageTooBig 1009`, `PolicyRangeStart 4000`, `PolicyRangeEnd 4999`, `DuplicateLogin 4001`, `Maintenance 4002`, `Kicked 4003`, `static bool IsReconnectable(int)`.
- `readonly struct RealtimeDisconnectInfo { int CloseStatus; string Reason; bool WillReconnect; }`, `enum RealtimeState { Disconnected, Connecting, Connected }`.
