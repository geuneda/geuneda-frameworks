---
name: geuneda-account
description: com.geuneda.account 패키지(네임스페이스 Geuneda.Account, 서버 Geuneda.Account.Server)와 제공자 패키지 com.geuneda.account.apple(Geuneda.Account.Apple)·com.geuneda.account.google(Geuneda.Account.Google)로 코드를 작성하거나 수정할 때 사용하는 스킬. AuthService 로 게스트·플랫폼 로그인·자동 로그인(SignInSilentlyAsync)·로그아웃을 하거나, GetAccessTokenAsync·AuthTokenMiddleware 로 게임 서버 요청과 실시간 RPC 로그인에 access 토큰을 넣거나, 연동·충돌(LinkResult.IsConflict)·옮겨오기·해제·계정 삭제를 다루거나, IAuthProvider 제공자를 만들거나 AppleAuthProvider·GoogleAuthProvider(GoogleAuthOptions)를 등록하거나, AppSession 세션 ID·백그라운드 시간 초과·세션 이벤트를 쓰거나, ASP.NET Core 인증 서버(AddGeunedaAccount, MapGeunedaAccount, AddApple, AddGoogle, IAccountStore, IRefreshTokenStore, IPlatformVerifier, IAccessTokenValidator)를 구현하거나, AccountResultCodes(3000 블록)를 처리할 때 활성화한다.
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
- **제공자 패키지**(D3: 네이티브 코드와 Android Gradle 의존성은 설치한 게임에만):
  - `com.geuneda.account.apple` 0.2.0(`https://github.com/geuneda/geuneda-account-apple.git`): `Geuneda.Account.Apple.AppleAuthProvider`. iOS 13+ Sign in with Apple, capability 는 빌드 후처리가 넣음. 의존성 account 0.3.0, core 0.2.0, UniTask
  - `com.geuneda.account.google` 0.2.0(`https://github.com/geuneda/geuneda-account-google.git`): `Geuneda.Account.Google.GoogleAuthProvider(GoogleAuthOptions)`. Android Credential Manager, iOS 는 SDK 없이 ASWebAuthenticationSession + PKCE. 의존성 account 0.3.0, core 0.2.0, http 0.1.0, UniTask, Newtonsoft
  - 서버 검증기 `AddApple`/`AddGoogle` 은 account 0.2.0 부터, id 토큰 replay 방어(서버 발급 nonce, 연동 충돌 티켓)와 `IAuthService`·`IAppSession` 의 `IDisposable` 은 account 0.3.0·제공자 0.2.0 부터(호환성 파괴: 셋을 함께 올리고, 이전 프로젝트는 account 0.2.0·제공자 0.1.0 태그를 고정)

## 핵심 API

전체 시그니처는 `references/api.md`.

- `new AuthService(new AuthServiceOptions { AuthClient, SecureStore, Session, Providers })` → `IAuthService`. `MainInstaller.Bind<IAuthService>`.
- `SignInAsync(platform)`, `SignInAsync(PlatformCredential)`, `SignInSilentlyAsync()` → `Result<SignInResult>`(`AccountId`, `IsNewAccount`, `IsSaved`). `HasSavedLogin`, `IsSignedIn`, `AccountId`, 이벤트 `SignedIn`, `SignedOut(SignOutReason)`.
- `GetAccessTokenAsync()` → `Result<string>`, `InvalidateAccessToken(token)`, `SignOutAsync()`.
- `GetLinksAsync()`, `LinkAsync(platform)` → `Result<LinkResult>`(`IsConflict`, `ConflictAccountId`, `Credential`, `Links`), `TransferAsync(credential)`, `UnlinkAsync(platform)`, `DeleteAccountAsync()`.
- `AuthTokenMiddleware(auth)`: 게임 서버 http 클라이언트에 넣는다(order 를 재시도보다 작게, 즉 바깥).
- `GuestAuthProvider(secureStore)`, `IAuthProvider`(`Platform`, `RequiresNonce`, `SignInAsync(nonce, ct)`, `SignOutAsync`), `PlatformCredential(platform, credential)`, `AccountPlatforms`(guest, apple, google). `RequiresNonce` 인 제공자는 `AuthService` 가 먼저 `POST nonce` 로 받은 원문을 넘긴다(게스트는 false, null).
- `new AppleAuthProvider()`, `new GoogleAuthProvider(new GoogleAuthOptions { AndroidServerClientId, IosClientId, TokenClient?, IosEphemeralSession })`: 제공자 패키지. 사용자 취소는 `ResultCodes.Cancelled`, 그 밖은 `PlatformSignInFailed`.
- `AppSession`(`BindApplicationLifecycle`, `Start`, `End`, `SessionId`, `NextSessionId`, 이벤트 `Started`/`Paused`/`Resumed`/`Ended(SessionEndReason)`).
- `AccountResultCodes`: 서버 3001~3015(`InvalidCredential`, `UnsupportedPlatform`, `InvalidRefreshToken`, `RefreshTokenReused`, `InvalidAccessToken`, `AccountNotFound`, `LoginConflict`, `PlatformAlreadyLinked`, `LastLogin`, `BadRequest`, `RetryLater`(503), `NonceMissing`(400), `NonceMismatch`(401), `InvalidNonce`(401), `InvalidConflictTicket`(401)), 클라이언트 3100~3104(`NotSignedIn`, `PlatformSignInFailed`, `InvalidResponse`, `StorageFailed`, `SessionChanged`).

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
options.Providers.Add(new AppleAuthProvider());   // com.geuneda.account.apple
options.Providers.Add(new GoogleAuthProvider(new GoogleAuthOptions   // com.geuneda.account.google
{
    AndroidServerClientId = "<웹 클라이언트 ID>.apps.googleusercontent.com",
    IosClientId = "<iOS 클라이언트 ID>.apps.googleusercontent.com"
}));
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
    .AddGuest()
    .AddApple(o => o.Audiences.Add("com.company.game"))                       // 번들 ID
    .AddGoogle(o => { o.ClientIds.Add(webClientId); o.ClientIds.Add(iosClientId); })
    .AddPlatformVerifier<MyVerifier>();
builder.Services.AddScoped<IAccountStore, MyDbAccountStore>();
builder.Services.AddScoped<IRefreshTokenStore, MyDbRefreshTokenStore>();
builder.Services.AddSingleton<IOneTimeValueStore, MyRedisOneTimeValueStore>();   // nonce·충돌 티켓. 서버가 여러 대면 공유 저장소(원자적 소비). 한 대면 InMemoryOneTimeValueStore
app.MapGeunedaAccount("/auth");   // POST nonce 는 인증 없이 열리므로 rate limiter 를 붙인다

// 게임 서버(실시간 RPC 등)
builder.Services.AddGeunedaAccessTokenValidation(o => { o.Issuer = ...; o.Audience = ...; o.SigningKeys.Add(key); });
var validation = await validator.ValidateAsync(accessToken);   // AccountId, SessionId
```

## 함정

- 메인 스레드에서 쓴다. 공개 메서드는 오용(등록하지 않은 플랫폼, null 자격)을 바로 예외로 던진다.
- 로그인·로그아웃·연동·옮겨오기·해제·삭제는 동시에 하나만이다. 겹치면 `ResultCodes.InProgress` 이고 기다리지 않는다(버튼 중복 클릭 방지). `GetAccessTokenAsync` 는 잠그지 않는다.
- 자동 로그인 실패가 `NetworkError` 면 저장된 로그인이 남아 있으니 다시 시도한다. `InvalidRefreshToken`/`RefreshTokenReused` 면 저장된 로그인이 지워졌으니 로그인 화면으로 간다.
- 연동 충돌은 실패가 아니라 `LinkResult.IsConflict` 다. `Credential` 안에 서버가 준 1회용 충돌 티켓이 있어 `SignInAsync(credential)`·`TransferAsync(credential)` 는 id 토큰 대신 티켓을 보낸다. 티켓은 발급부터 5분 안에 한 번만(충돌한 계정 로그인 또는 연동한 이 계정으로 옮겨오기 중 하나) 쓴다. 지나거나 두 번째면 `InvalidConflictTicket` 이라 연동부터 다시 한다.
- `IAuthService`·`IAppSession` 은 `IDisposable` 이다. 정리는 `MainInstaller.CleanDispose<IAuthService>()`·`CleanDispose<IAppSession>()`. 테스트 대역도 `Dispose` 를 구현한다.
- 애플·구글 id 토큰은 서버 발급 nonce 에 묶여 한 번만 쓰인다(replay 방어). nonce 를 받지 못하면(`NetworkError`, 5xx `HttpError`) 플랫폼 로그인 화면 없이 실패하고, 서버 거절은 `NonceMissing`(0.2.x 이하 클라이언트), `NonceMismatch`(제공자가 nonce 를 토큰에 안 묶음), `InvalidNonce`(만료·재사용) 이다. 제공자를 직접 만들면 `RequiresNonce` 를 서버 검증기와 같게 두고, 애플은 원문의 SHA-256 16진 소문자를 요청에, 구글·OIDC 는 원문을 그대로 넣는다.
- 서버 `IPlatformVerifier` 를 직접 만들면 `RequiresNonce` 와 `VerifyAsync(credential, nonce, ct)` 를 구현한다. 토큰이 nonce 에 묶이지 않았으면 `PlatformVerification.NonceMismatch`. nonce 저장소 확인·소비는 서버가 검증 뒤에 한다(검증기에서 하지 않음).
- 요청 중 로그인이 바뀌면(다른 계정 로그인, 로그아웃) 그 응답은 `NotSignedIn` 으로 끝나고 지금 로그인에 적용되지 않는다. 테스트 대역은 `LinkResult.Linked/Conflict`, 서버 `AccessTokenValidation.Valid/Invalid` 로 결과를 만든다.
- 로그아웃 결과가 `StorageFailed` 면 이 기기의 저장된 로그인을 지우지 못한 것이다(메모리상 로그아웃은 됨). 로그인 결과의 `IsSaved` 가 false 면 이번 실행만 확실한 로그인 상태다(다음 실행 자동 로그인은 보장 못 함). 저장소 오류로 이전 저장값도 못 지운 채 다른 계정으로 바꾸면 로그인이 `StorageFailed` 로 거절된다.
- 인증 서버 클라이언트(`AuthClient`)에는 `AuthTokenMiddleware` 를 넣지 않는다. 기본 주소는 접두사까지, 끝에 `/`.
- `AuthTokenMiddleware` 는 `RetryMiddleware` 보다 바깥(order 가 작음)에 둔다. 안쪽에 두면 재시도 사이에 다른 계정으로 로그인했을 때 이전 요청이 새 계정의 토큰으로 나간다.
- iOS 는 키체인이라 앱을 지워도 로그인이 남는다(재설치 후 자동 로그인). Android 는 앱을 지우면 로그인과 게스트 비밀 값이 사라진다. 게스트에게는 플랫폼 연동을 권한다.
- 서버 access 토큰 검증은 서명·발급자·대상·만료만 본다. 탈퇴 계정의 토큰도 만료 전까지 통과하므로 필요하면 게임 서버가 계정을 확인한다. 게임 서버의 계정 데이터 삭제는 게임 몫이다.
- 서버 `IRefreshTokenStore.TryRotateAsync` 는 현재 토큰 비교 + 로그인 상태 교체 + 새 토큰 기록 추가를 원자적으로 해야 한다(데이터베이스는 한 트랜잭션). 메모리 저장소는 샘플·테스트용(만료 정리 없음, 재시작하면 사라짐).
- 서버 로그에 토큰·자격 원문을 남기지 않는다. 로그인 횟수 제한은 호스트가 rate limiter 로 붙인다.
- 서버 애플·구글 검증기는 `OpenIdConnectKeyCache` 로 공개 키를 받는다(12시간 갱신, 모르는 키면 다시 받기를 기다려 재검증, 재요청 5분에 한 번). IdentityModel `ConfigurationManager` 로 바꾸지 않는다(갱신이 백그라운드라 키 교체 직후 정상 토큰이 401). 키를 확인하지 못하면 500 이다.
- 플랫폼 로그인은 앱이 전면 활성일 때 버튼으로 부른다. iOS 는 앱 장면이 활성이 아니면 시트·세션을 못 연다.
- Android 구글: 구글 화면이 떠 있는 동안 Unity 가 멈춰 취소 토큰은 앱으로 돌아온 뒤 적용되고 화면을 닫지 않는다. Credential Manager 는 콘솔 설정 오류(패키지 이름·SHA-1 미등록, 잘못된 웹 클라이언트 ID)도 `Cancelled` 로 주므로, 계정을 골랐는데 취소가 오면 logcat `Auth` 태그를 본다. Google Play 서비스가 있는 기기여야 한다.
- 구글 대상(`aud`)은 Android 가 웹(서버) 클라이언트 ID, iOS 가 iOS 클라이언트 ID 다. 서버 `AddGoogle` 에 둘 다 넣는다. 애플 대상은 번들 ID 다.
