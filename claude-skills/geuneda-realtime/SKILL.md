---
name: geuneda-realtime
description: com.geuneda.realtime 패키지(네임스페이스 Geuneda.Realtime, 서버 Geuneda.Realtime.Server)로 코드를 작성하거나 수정할 때 사용하는 스킬. [RpcService] 계약 인터페이스를 쓰거나, 생성된 XxxClient 프록시로 RPC 를 부르거나, RealtimeClient 연결·LoginAsync·재연결·정책 종료(4000~4999)를 다루거나, Subscribe 로 서버 푸시를 받거나, ASP.NET Core 서버(AddRealtimeRpc, MapRealtimeRpc, IRpcContext, RpcStatusException, IRealtimeSessions)를 구현하거나, 생성기 진단 GRPC001~011 을 해결하거나, JSON/MessagePack 직렬화와 프레임 프로토콜을 확인할 때 활성화한다.
---

# Geuneda Realtime

WebSocket 실시간 RPC 클라이언트와 같은 계약을 쓰는 ASP.NET Core 서버다. 클라이언트는 연결 관리(single-flight 연결, 연결마다 재로그인, 지수 백오프 재연결)와 세션(요청 ID 매칭, 서버 푸시, 핑퐁)을 나누고, 결과는 core 결과 규약(`Result`)을 따른다. `[RpcService]` 계약 하나에서 소스 생성기가 클라이언트 프록시와 서버 라우트 표를 만든다.

## 패키지 정보

- **네임스페이스 / 어셈블리**: `Geuneda.Realtime`, 선택 어셈블리 `Geuneda.Realtime.MessagePack`
- **설치**: `https://github.com/geuneda/geuneda-realtime.git` (core, UniTask git URL 도 함께)
- **의존성**: `com.geuneda.core` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1. MessagePack 은 선택(`org.nuget.messagepack` 3.x + `org.nuget.microsoft.net.stringtools`, 또는 `GEUNEDA_MESSAGEPACK` define)
- **최소 Unity 버전**: 2021.3 (WebGL 은 별도 전송 필요). 소스 생성기는 Roslyn 4.3 이 있는 Unity(6000.3 에서 확인)
- **서버**: 패키지의 `Server~/`(Unity 가 가져오지 않음) .NET 10 솔루션 `Geuneda.Realtime.Server.slnx`. 게임 서버는 Unity 계약 폴더를 링크하고 서버 프로젝트·생성기(analyzer)를 경로로 참조
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
// 계약(Unity asmdef: Geuneda.Realtime, Geuneda.Core, UniTask 참조, noEngineReferences). 서버가 같은 파일을 컴파일한다
[RpcService]
public interface IShopRpc
{
    Task<BuyProductRes> BuyProduct(BuyProductReq request);
    Task<ShopStateRes> GetState();                         // 인자 없음
    public sealed class BuyProductReq { public int ProductId; }
    public sealed class BuyProductRes { public int Gold; }
    public sealed class ShopStateRes { public int[] Products; }
}
[RpcService]
public interface ISessionRpc
{
    [RpcAllowAnonymous] Task<LoginRes> Login(LoginReq request);
    public sealed class LoginReq { public string AccessToken; }
    public sealed class LoginRes { public string UserId; }
}

// 클라이언트: 생성된 ShopRpcClient / SessionRpcClient
var client = new RealtimeClient(new RealtimeClientOptions
{
    ServerUri = new Uri(config.RealtimeUrl),                    // wss://
    LoginAsync = async (caller, token) => await new SessionRpcClient(caller).Login(new ISessionRpc.LoginReq { AccessToken = auth.AccessToken }, token)
});
client.Disconnected += info => { if (!info.WillReconnect) ShowDisconnectedPopup(info.CloseStatus); };
MainInstaller.Bind<IRealtimeClient>(client);
MainInstaller.Bind<IShopRpcClient>(new ShopRpcClient(client));

var result = await shop.BuyProduct(new IShopRpc.BuyProductReq { ProductId = id }, token);
if (!result.TryGetValue(out var response))
{
    if (result.Code == ResultCodes.NetworkError || result.Code == ResultCodes.Timeout) ShowRetryPopup();
    else if (result.Code == RealtimeResultCodes.NotReconnectable) GoToTitle();
    return;
}

_mailSubscription = realtime.Subscribe<MailArrived>(RpcTopic.Of("Mail/Arrived"), OnMailArrived);   // OnDestroy 에서 Dispose

// 서버(ASP.NET Core)
builder.Services.AddScoped<IShopRpc, ShopRpc>();
builder.Services.AddRealtimeRpc(options => options.AddRoutes(GeneratedRpcRoutes.All));   // 네임스페이스 = 계약을 컴파일한 어셈블리 이름
app.UseWebSockets();
app.MapRealtimeRpc("/rpc");

public sealed class SessionRpc : ISessionRpc
{
    private readonly IRpcContext _context;
    public SessionRpc(IRpcContext context) => _context = context;
    public async Task<ISessionRpc.LoginRes> Login(ISessionRpc.LoginReq request)
    {
        var userId = await _auth.VerifyAsync(request.AccessToken) ?? throw new RpcStatusException(GameErrors.InvalidToken); // 101000 이상
        _context.SignIn(userId);                                  // 같은 사용자의 이전 세션은 4001 로 닫힘
        return new ISessionRpc.LoginRes { UserId = userId };
    }
}
```

## 함정

- 서버 응답 상태는 0 성공, **100000 이상만** 그 값이 실패 코드다. 1~99999·음수는 `InvalidResponse` 다(공용 코드와 겹치지 않게). 100000~100999 는 서버 프레임워크(`RpcStatusCodes`: InternalError, Unauthenticated, MethodNotFound, BadRequest, Overloaded), 게임 오류 코드는 101000 부터 정한다.
- 계약 메서드는 `Task<TRes> M(TReq)`, `Task M(TReq)`, `Task<TRes> M()` (+ 끝 `CancellationToken`)만 된다. 오버로드·제네릭·속성·`ValueTask`·상속은 생성기 빌드 오류(GRPC001~010). 같은 인터페이스 이름이 다른 네임스페이스에 있으면 경로가 겹쳐 오류다. 계약 asmdef 가 UniTask·Geuneda.Core 를 참조하지 않으면 GRPC011. 생성 이름(`XxxClient`, `IXxxClient`, `XxxMethods`, `_caller`, `GeneratedRpcRoutes`)과 겹치면 GRPC012~014.
- 서버는 세션마다 요청을 받은 순서대로 하나씩 실행하고, 대기가 넘치면 Overloaded(100004)로 거절한다. `[RpcAllowAnonymous]` 없는 메서드는 `IRpcContext.SignIn` 전에 Unauthenticated(100001). 정상 실패는 `throw new RpcStatusException(code)`(로그 없음), 다른 예외는 InternalError(100000) + 오류 로그.
- 서버 구현은 `IRpcContext.CallAborted`(또는 계약의 `CancellationToken`)를 외부 호출에 넘긴다. 세션이 닫히면 취소되고, 닫힌 세션의 `SignIn` 은 `OperationCanceledException` 이다. 서버 MessagePack 옵션에는 `.WithSecurity(MessagePackSecurity.UntrustedData)`.
- 생성기 소스(`Server~/src/Geuneda.Realtime.Generator`)를 고치면 Release 빌드로 `Runtime/Generator` DLL 을 갱신한다. `Tests/EditMode/Interop/` 는 샘플 서버가 링크하므로 Unity 전용 코드를 두지 않는다.
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
