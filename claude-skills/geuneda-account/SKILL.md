---
name: geuneda-account
description: com.geuneda.account 패키지(네임스페이스 Geuneda.Account, 서버 Geuneda.Account.Server)로 코드를 작성하거나 수정할 때 사용하는 스킬. AuthService 로 게스트·플랫폼 로그인·자동 로그인(SignInSilentlyAsync)·로그아웃을 하거나, GetAccessTokenAsync·AuthTokenMiddleware 로 게임 서버 요청과 실시간 RPC 로그인에 access 토큰을 넣거나, 연동·충돌(LinkResult.IsConflict)·옮겨오기·해제·계정 삭제를 다루거나, IAuthProvider 제공자를 만들거나, AppSession 세션 ID·백그라운드 시간 초과·세션 이벤트를 쓰거나, ASP.NET Core 인증 서버(AddGeunedaAccount, MapGeunedaAccount, IAccountStore, IRefreshTokenStore, IPlatformVerifier, IAccessTokenValidator)를 구현하거나, AccountResultCodes(3000 블록)를 처리할 때 활성화한다.
---

# Geuneda Account

계정 인증과 앱 세션이다. 플랫폼 제공자(게스트 기본)로 로그인하고, refresh 토큰은 core 보안 저장소에, access 토큰은 메모리에 두고 재발급을 한 번만 보낸다. 같은 프로토콜의 ASP.NET Core 인증 서버(`Server~/`)를 함께 둔다. 결과는 core 결과 규약(`Result`)을 따른다.

## 패키지 정보

- **네임스페이스 / 어셈블리**: `Geuneda.Account`
- **설치**: `https://github.com/geuneda/geuneda-account.git` (core, http, UniTask git URL 도 함께)
- **의존성**: `com.geuneda.core` 0.2.0(ISecureStore, Result, AppEnv), `com.geuneda.http` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1
- **최소 Unity 버전**: 2021.3
- **서버**: `Server~/` 의 .NET 10 솔루션 `Geuneda.Account.Server.slnx`. DTO 와 결과 코드는 `Runtime/Protocol/` 을 링크
- **기여 가이드**: 패키지 루트의 `AGENTS.md`

## 핵심 API

전체 시그니처는 `references/api.md`.

- `new AuthService(new AuthServiceOptions { AuthClient, SecureStore, Session, Providers })` → `IAuthService`. `MainInstaller.Bind<IAuthService>`.
- `SignInAsync(platform)`, `SignInAsync(PlatformCredential)`, `SignInSilentlyAsync()` → `Result<SignInResult>`(`AccountId`, `IsNewAccount`, `IsSaved`). `HasSavedLogin`, `IsSignedIn`, `AccountId`, 이벤트 `SignedIn`, `SignedOut(SignOutReason)`.
- `GetAccessTokenAsync()` → `Result<string>`, `InvalidateAccessToken(token)`, `SignOutAsync()`.
- `GetLinksAsync()`, `LinkAsync(platform)` → `Result<LinkResult>`(`IsConflict`, `ConflictAccountId`, `Credential`, `Links`), `TransferAsync(credential)`, `UnlinkAsync(platform)`, `DeleteAccountAsync()`.
- `AuthTokenMiddleware(auth)`: 게임 서버 http 클라이언트에 넣는다(order 를 재시도보다 작게, 즉 바깥).
- `GuestAuthProvider(secureStore)`, `IAuthProvider`(`Platform`, `SignInAsync`, `SignOutAsync`), `AccountPlatforms`(guest, apple, google).
- `AppSession`(`BindApplicationLifecycle`, `Start`, `End`, `SessionId`, `NextSessionId`, 이벤트 `Started`/`Paused`/`Resumed`/`Ended(SessionEndReason)`).
- `AccountResultCodes`: 서버 3001~3011(`InvalidCredential`, `UnsupportedPlatform`, `InvalidRefreshToken`, `RefreshTokenReused`, `InvalidAccessToken`, `AccountNotFound`, `LoginConflict`, `PlatformAlreadyLinked`, `LastLogin`, `BadRequest`, `RetryLater`(503)), 클라이언트 3100~3104(`NotSignedIn`, `PlatformSignInFailed`, `InvalidResponse`, `StorageFailed`, `SessionChanged`).

## 사용 패턴

```csharp
var secureStore = new PlatformSecureStore();
var session = new AppSession();
session.BindApplicationLifecycle();
var options = new AuthServiceOptions
{
    AuthClient = new HttpClientBuilder().WithBaseAddress("https://auth.example.com/auth/").Build(),
    SecureStore = secureStore,
    Session = session
};
options.Providers.Add(new GuestAuthProvider(secureStore));
var auth = new AuthService(options);

// 타이틀: 저장된 로그인이 있으면 자동 로그인. 실패 종류를 나눈다
if (auth.HasSavedLogin)
{
    var silent = await auth.SignInSilentlyAsync(ct);
    if (silent.IsSuccess) { /* 로비 */ return; }
    if (silent.Code == ResultCodes.NetworkError || silent.Code == ResultCodes.Timeout || silent.Code == HttpResultCodes.HttpError)
    {
        /* 저장된 로그인은 남아 있다. 다시 시도 안내 후 끝낸다(게스트로 넘어가면 다른 계정으로 바뀜) */
        return;
    }
    // InvalidRefreshToken 등: 저장된 로그인이 지워졌다. 로그인 선택 화면으로
}

// 로그인 선택 화면에서 사용자가 고른 플랫폼으로
var result = await auth.SignInAsync(chosenPlatform, ct);

auth.SignedOut += reason => GoToTitle(reason);

var gameClient = new HttpClientBuilder().WithBaseAddress("https://game.example.com/")
    .AddMiddleware(new AuthTokenMiddleware(auth), order: -100)   // 재시도보다 바깥
    .AddMiddleware(new RetryMiddleware(), order: 0).Build();

// 연동 충돌: 사용자에게 고르게 한다. 옮겨오기는 그 계정의 로그인 수단을 빼앗으므로(마지막 수단이면 그 계정에 다시 못 들어감) 명시적으로 확인받는다
var link = await auth.LinkAsync(platform, ct);
if (link.IsSuccess && link.Value.IsConflict)
{
    var choice = await AskConflictChoice(link.Value.ConflictAccountId);   // 게임 UI
    if (choice == ConflictChoice.UseOtherAccount)
        await auth.SignInAsync(link.Value.Credential, ct);
    else if (choice == ConflictChoice.MoveToThisAccount && await ConfirmMove())
        await auth.TransferAsync(link.Value.Credential, ct);
    // 취소면 아무것도 하지 않는다
}
```

서버:

```csharp
builder.Services.AddGeunedaAccount(o => { o.Issuer = ...; o.Audience = ...; o.SigningCredentials = ...; })
    .AddGuest().AddPlatformVerifier<MyVerifier>();
builder.Services.AddScoped<IAccountStore, MyDbAccountStore>();
builder.Services.AddScoped<IRefreshTokenStore, MyDbRefreshTokenStore>();
app.MapGeunedaAccount("/auth");

// 게임 서버(실시간 RPC 등)
builder.Services.AddGeunedaAccessTokenValidation(o => { o.Issuer = ...; o.Audience = ...; o.SigningKeys.Add(key); });
var validation = await validator.ValidateAsync(accessToken);   // AccountId, SessionId
```

## 함정

- 메인 스레드에서 쓴다. 공개 메서드는 오용(등록하지 않은 플랫폼, null 자격)을 바로 예외로 던진다.
- 로그인·로그아웃·연동·옮겨오기·해제·삭제는 동시에 하나만이다. 겹치면 `ResultCodes.InProgress` 이고 기다리지 않는다(버튼 중복 클릭 방지). `GetAccessTokenAsync` 는 잠그지 않는다.
- 자동 로그인 실패가 `NetworkError` 면 저장된 로그인이 남아 있으니 다시 시도한다. `InvalidRefreshToken`/`RefreshTokenReused` 면 저장된 로그인이 지워졌으니 로그인 화면으로 간다.
- 연동 충돌은 실패가 아니라 `LinkResult.IsConflict` 다. `Credential` 의 id 토큰은 수명이 짧으니 바로 쓴다.
- 요청 중 로그인이 바뀌면(다른 계정 로그인, 로그아웃) 그 응답은 `NotSignedIn` 으로 끝나고 지금 로그인에 적용되지 않는다. 테스트 대역은 `LinkResult.Linked/Conflict`, 서버 `AccessTokenValidation.Valid/Invalid` 로 결과를 만든다.
- 로그아웃 결과가 `StorageFailed` 면 이 기기의 저장된 로그인을 지우지 못한 것이다(메모리상 로그아웃은 됨). 로그인 결과의 `IsSaved` 가 false 면 이번 실행만 확실한 로그인 상태다(다음 실행 자동 로그인은 보장 못 함). 저장소 오류로 이전 저장값도 못 지운 채 다른 계정으로 바꾸면 로그인이 `StorageFailed` 로 거절된다.
- 인증 서버 클라이언트(`AuthClient`)에는 `AuthTokenMiddleware` 를 넣지 않는다. 기본 주소는 접두사까지, 끝에 `/`.
- `AuthTokenMiddleware` 는 `RetryMiddleware` 보다 바깥(order 가 작음)에 둔다. 안쪽에 두면 재시도 사이에 다른 계정으로 로그인했을 때 이전 요청이 새 계정의 토큰으로 나간다.
- iOS 는 키체인이라 앱을 지워도 로그인이 남는다(재설치 후 자동 로그인). Android 는 앱을 지우면 로그인과 게스트 비밀 값이 사라진다. 게스트에게는 플랫폼 연동을 권한다.
- 서버 access 토큰 검증은 서명·발급자·대상·만료만 본다. 탈퇴 계정의 토큰도 만료 전까지 통과하므로 필요하면 게임 서버가 계정을 확인한다. 게임 서버의 계정 데이터 삭제는 게임 몫이다.
- 서버 `IRefreshTokenStore.TryRotateAsync` 는 현재 토큰 비교 + 로그인 상태 교체 + 새 토큰 기록 추가를 원자적으로 해야 한다(데이터베이스는 한 트랜잭션). 메모리 저장소는 샘플·테스트용(만료 정리 없음, 재시작하면 사라짐).
- 서버 로그에 토큰·자격 원문을 남기지 않는다. 로그인 횟수 제한은 호스트가 rate limiter 로 붙인다.
