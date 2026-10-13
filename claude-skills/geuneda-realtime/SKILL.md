---
name: geuneda-realtime
description: com.geuneda.realtime 패키지(네임스페이스 Geuneda.Realtime)로 코드를 작성하거나 수정할 때 사용하는 스킬. RealtimeClient 로 WebSocket 실시간 RPC 연결을 만들거나, LoginAsync 로 연결마다 로그인하거나, RpcMethod/RpcTopic 으로 경로를 정의하거나, CallAsync 로 요청·응답을 보내거나, Subscribe 로 서버 푸시를 받거나, Disconnected/Reconnected 와 정책 종료(4000~4999)·재연결을 처리하거나, JsonRpcSerializer/MessagePackRpcSerializer 를 고르거나, 서버(3-3)와 맞출 프레임 프로토콜을 확인할 때 활성화한다.
---

# Geuneda Realtime

WebSocket 실시간 RPC 클라이언트다. 연결 관리(single-flight 연결, 연결마다 재로그인, 지수 백오프 재연결)와 세션(요청 ID 매칭, 서버 푸시, 핑퐁)을 나누고, 결과는 core 결과 규약(`Result`)을 따른다.

## 패키지 정보

- **네임스페이스 / 어셈블리**: `Geuneda.Realtime`, 선택 어셈블리 `Geuneda.Realtime.MessagePack`
- **설치**: `https://github.com/geuneda/geuneda-realtime.git` (core, UniTask git URL 도 함께)
- **의존성**: `com.geuneda.core` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1. MessagePack 은 선택(`org.nuget.messagepack` 3.x + `org.nuget.microsoft.net.stringtools`, 또는 `GEUNEDA_MESSAGEPACK` define)
- **최소 Unity 버전**: 2021.3 (WebGL 은 별도 전송 필요)
- **기여 가이드**: 패키지 루트의 `AGENTS.md`

## 핵심 API

전체 시그니처는 `references/api.md`.

- `new RealtimeClient(new RealtimeClientOptions { ServerUri, LoginAsync, ... })` → `IRealtimeClient`. `MainInstaller.Bind<IRealtimeClient>` 로 바인딩.
- `CallAsync<TRequest, TResponse>(RpcMethod, request, ct)` → `UniTask<Result<TResponse>>`, `CallAsync<TRequest>(...)` → `UniTask<Result>`.
- `ConnectAsync(ct)`, `State`, `Subscribe<TPush>(RpcTopic, handler)` → `IDisposable`, 이벤트 `Disconnected(RealtimeDisconnectInfo)`, `Reconnected(Result)`.
- `RpcMethod.Of("IShopRpc/BuyProduct")`, `RpcTopic.Of("MailArrived")`: ID 는 이름의 FNV-1a 32비트 해시.
- `RealtimeResultCodes`(2000 블록): `NotConnected` 2001, `NotReconnectable` 2002, `Closed` 2003, `InvalidResponse` 2004, `ProtocolMismatch` 2005.
- `RealtimeCloseCodes`: 1000~1009 표준, 4000~4999 정책(`DuplicateLogin` 4001, `Maintenance` 4002, `Kicked` 4003).

## 사용 패턴

```csharp
public static class GameRpc
{
    public static readonly RpcMethod Login = RpcMethod.Of("ISessionRpc/Login");
    public static readonly RpcMethod BuyProduct = RpcMethod.Of("IShopRpc/BuyProduct");
    public static readonly RpcTopic MailArrived = RpcTopic.Of("MailArrived");
}

var client = new RealtimeClient(new RealtimeClientOptions
{
    ServerUri = new Uri(config.RealtimeUrl),                    // wss://
    LoginAsync = (caller, token) => caller.CallAsync(GameRpc.Login, new LoginRequest { AccessToken = auth.AccessToken }, token)
});
client.Disconnected += info => { if (!info.WillReconnect) ShowDisconnectedPopup(info.CloseStatus); };
MainInstaller.Bind<IRealtimeClient>(client);

var result = await realtime.CallAsync<BuyRequest, BuyResponse>(GameRpc.BuyProduct, new BuyRequest { ProductId = id }, token);
if (!result.TryGetValue(out var response))
{
    if (result.Code == ResultCodes.NetworkError || result.Code == ResultCodes.Timeout) ShowRetryPopup();
    else if (result.Code == RealtimeResultCodes.NotReconnectable) GoToTitle();
    return;
}

_mailSubscription = realtime.Subscribe<MailArrived>(GameRpc.MailArrived, OnMailArrived);   // OnDestroy 에서 Dispose
```

## 함정

- 서버 응답 상태는 0 성공, **100000 이상만** 그 값이 실패 코드다. 1~99999·음수는 `InvalidResponse` 다(공용 코드와 겹치지 않게). 서버 게임 오류 코드는 100000 이상으로 정한다.
- 취소는 예외가 아니라 `Cancelled` 다. 제한 시간·취소는 보내기 차례 대기부터 적용되고 차례 전 요청은 보내지 않지만, 이미 보낸 요청은 서버가 처리할 수 있다(결과만 버림). 구매 같은 요청은 서버에서 멱등하게.
- 연결이 없으면 첫 호출이 연결한다(`ConnectOnCall`). 끄면 `NotConnected`.
- 서버가 4000~4999 로 닫으면(로그인 중 포함) 재연결하지 않고 이후 호출은 `NotReconnectable` 이다. `ConnectAsync` 로만 다시 연결한다.
- 로그인 대리자는 연결마다(재연결 포함) 메인 스레드에서 불린다. 토큰은 URL 이 아니라 로그인 RPC 로 보낸다. 대리자가 던진 예외는 결과로 바뀌지 않고 연결을 기다리던 호출에 그대로 던져진다.
- 호출·연결 결과는 메인 스레드에서 돌려준다. 이벤트·푸시 핸들러는 `CallbackDispatcher`(기본 메인 스레드 PlayerLoop)에서 불리고, 구독 해제·Dispose 뒤에는 큐에 있던 것도 실행되지 않는다. 수신 조립·역직렬화는 백그라운드 스레드일 수 있으므로 직접 만든 직렬화·디스패처는 스레드 안전해야 한다.
- `Dispose` 뒤 `CallAsync` 는 반환된 UniTask 를 기다릴 때 `ObjectDisposedException` 이다(async 메서드). 진행 중이던 호출·연결은 `Closed`.
- 서브프로토콜은 `geuneda.rpc.v1.<직렬화 이름>`이다. 서버가 돌려주지 않거나 다른 것을 고르면 `ProtocolMismatch`(재연결 안 함).
- MessagePack 본문 타입은 `[MessagePackObject]`/`[Key]` 로 표시하고, IL2CPP 에서는 소스 생성 리졸버를 `MessagePackRpcSerializer(options)` 로 넘긴다.
- 서버 재시작 종료는 1001 로 한다. Unity 의 `ClientWebSocket` 은 1012~1014 를 받으면 무효로 보고 끊는다(클라이언트에는 1006).
- 테스트에서는 `RealtimeClientOptions.Transport` 에 가짜 `IRealtimeTransport` 를 넣고, `CallbackDispatcher = a => a()` 로 즉시 실행한다.
