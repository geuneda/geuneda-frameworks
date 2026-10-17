# Geuneda Account API 레퍼런스

네임스페이스 `Geuneda.Account`, 서버 `Geuneda.Account.Server`. 결과는 core `Result`/`Result<T>`.

## 인증 (`Runtime/Auth/`)

### interface IAuthService : IDisposable / sealed class AuthService : IAuthService

| 멤버 | 설명 |
|------|------|
| `AuthService(AuthServiceOptions)` | 저장된 로그인을 읽어 둠(형식이 깨졌으면 지움). 메인 스레드. 필수 설정 누락·시간 설정 범위 밖·제공자 이름 중복은 `ArgumentException` |
| `bool IsSignedIn`, `string AccountId`, `bool HasSavedLogin` | 이번 실행 로그인 여부, 계정(로그인 아니면 null), 저장된 로그인 여부 |
| `event Action<SignInResult> SignedIn` | 로그인·자동 로그인·계정 전환 성공 |
| `event Action<SignOutReason> SignedOut` | `SignedOut`(로그아웃), `LoginExpired`(서버가 refresh 토큰 거절), `AccountDeleted` |
| `UniTask<Result<SignInResult>> SignInAsync(string platform, ct)` | 제공자 로그인 → `POST login`. 미등록 플랫폼은 `ArgumentException` |
| `UniTask<Result<SignInResult>> SignInAsync(PlatformCredential, ct)` | 받은 자격으로 로그인(연동 충돌 후 그 계정으로. 충돌 자격이면 id 토큰 대신 안의 1회용 티켓을 보냄) |
| `UniTask<Result<SignInResult>> SignInSilentlyAsync(ct)` | 저장된 로그인으로 `POST refresh`. 없으면 `NotSignedIn`, 서버 거절이면 저장된 로그인 삭제 |
| `UniTask<Result<string>> GetAccessTokenAsync(ct)` | 남은 수명 < min(margin, 수명/2) 이면 재발급(single-flight). 로그인 아니면 `NotSignedIn` |
| `void InvalidateAccessToken(string)` | 지금 토큰이면 다음 요청에서 재발급 |
| `UniTask<Result> SignOutAsync(ct)` | 로컬 먼저 삭제, 서버 `logout`·제공자 `SignOutAsync` 는 best effort. 저장소를 지우지도 덮어쓰지도 못하면 `StorageFailed` |
| `GetLinksAsync`, `LinkAsync(platform)`, `TransferAsync(credential)`, `UnlinkAsync(platform)`, `DeleteAccountAsync()` | 인증된 호출. `InvalidAccessToken` 이면 재발급 후 한 번 재시도, `AccountNotFound` 면 `SignedOut(AccountDeleted)`. 요청 중 로그인이 바뀌면 `NotSignedIn` 이고 응답을 적용하지 않음 |
| `Dispose()` | 진행 중 요청 취소(`Cancelled`), 늦은 결과는 적용하지 않음. 저장된 로그인은 둠. 인터페이스가 `IDisposable` 이라 `MainInstaller.CleanDispose<IAuthService>()` 로 정리 |

### sealed class AuthServiceOptions

`IHttpClient AuthClient`(기본 주소 `https://.../auth/`), `ISecureStore SecureStore`, `IAppSession Session`, `IList<IAuthProvider> Providers`, `TimeSpan AccessTokenRefreshMargin`(기본 1분), `TimeSpan RequestTimeout`(인증 서버 요청마다, 기본 15초).

### 결과 형식

- `SignInResult`: `AccountId`, `IsNewAccount`, `IsSaved`(이번 로그인을 이 기기에 저장했는지. false 면 이전 저장값은 지움, 그것도 못 한 다른 계정 전환은 `StorageFailed` 로 거절)
- `LinkResult`: `IsConflict`, `Links`(연동했을 때), `ConflictAccountId`, `Credential`(충돌일 때. 안에 서버가 준 1회용 충돌 티켓(internal)이 있어 로그인·옮겨오기가 id 토큰 대신 보냄. 발급부터 5분, 한 번). 공개 팩토리 `Linked(links)`, `Conflict(accountId, credential)`
- `LinkedPlatform`: `Platform`, `LinkedAt`(DateTimeOffset)
- `PlatformCredential(platform, credential)`: `ToString` 은 자격을 숨김

### interface IAuthProvider

`string Platform`, `bool RequiresNonce`, `UniTask<Result<PlatformCredential>> SignInAsync(string nonce, ct)`(사용자 취소 `Cancelled`, SDK 실패 `PlatformSignInFailed`), `UniTask SignOutAsync(ct)`(던지지 않음).

- `RequiresNonce` 면 `AuthService` 가 로그인·연동 전에 `POST nonce` 로 받은 원문을 넘기고(받지 못하면 그 결과 코드로 끝, 제공자를 부르지 않음), 제공자가 돌려준 자격에 그 nonce 를 붙여 요청 `nonce` 로 보낸다. false 면 `nonce` 는 null.
- `PlatformCredential(platform, credential)`: 공개 생성자는 그대로. `AuthService` 가 붙이는 nonce·충돌 티켓은 internal 이다(공개 API 변경 없음).

- `GuestAuthProvider(ISecureStore)`: 키 `geuneda.account.<env>.guestSecret` 의 32바이트 Base64url 비밀 값. 없으면 만들어 저장(저장 실패면 `PlatformSignInFailed`), 읽기 `Failed` 면 만들지 않음. 로그아웃해도 지우지 않음.

### sealed class AuthTokenMiddleware : IHttpMiddleware

`RetryMiddleware` 바깥(order 가 작음)에 둔다. `Authorization: Bearer <token>`. 응답 401 이면 `InvalidateAccessToken` → 재발급 실패면 그 결과 코드, 새 토큰이 다르고 계정이 그대로면 한 번만 재전송. 토큰을 못 얻으면 요청을 보내지 않고 그 결과 코드.

## 세션 (`Runtime/Session/`)

### interface IAppSession : IDisposable / sealed class AppSession : IAppSession

| 멤버 | 설명 |
|------|------|
| `AppSession()`, `AppSession(TimeSpan backgroundTimeout)` | 기본 10분 |
| `void BindApplicationLifecycle()` | 숨은 GameObject(DontDestroyOnLoad)로 `OnApplicationPause`/`OnApplicationQuit` 연결 |
| `bool IsActive`, `string SessionId`, `string NextSessionId`, `SessionInfo Current` | ID 는 16자리 16진수, 시간순 |
| `SessionInfo Start()` | `NextSessionId` 로 시작, 다음 ID 예약. 진행 중이면 먼저 `Ended(Restarted)` |
| `void End()` | `Ended(Ended)` |
| 이벤트 | `Started`, `Paused`, `Resumed`, `Ended(SessionInfo, SessionEndReason)`. 시간 초과면 `Ended(BackgroundTimeout)` 다음 `Started` |

`SessionEndReason`: `Ended`, `BackgroundTimeout`, `Restarted`, `ApplicationQuit`.

## 코드 (`Runtime/Protocol/AccountResultCodes.cs`)

| 코드 | 이름 | HTTP |
|------|------|------|
| 3001 | `InvalidCredential` | 401 |
| 3002 | `UnsupportedPlatform` | 400 |
| 3003 | `InvalidRefreshToken` | 401 |
| 3004 | `RefreshTokenReused` | 401 |
| 3005 | `InvalidAccessToken` | 401 |
| 3006 | `AccountNotFound` | 404 |
| 3007 | `LoginConflict`(+ `conflictAccountId`) | 409 |
| 3008 | `PlatformAlreadyLinked` | 409 |
| 3009 | `LastLogin` | 409 |
| 3010 | `BadRequest` | 400 |
| 3011 | `RetryLater`(같은 로그인의 동시 재발급이 계속 겹침, 1회용 값 저장소가 가득 참) | 503(클라이언트에서는 `HttpError`) |
| 3012 | `NonceMissing`(nonce 가 필요한 플랫폼인데 요청에 없음) | 400 |
| 3013 | `NonceMismatch`(id 토큰의 `nonce` 클레임이 없거나 요청 nonce 와 다름) | 401 |
| 3014 | `InvalidNonce`(발급하지 않았거나, 만료되었거나, 이미 쓴 nonce) | 401 |
| 3015 | `InvalidConflictTicket`(발급하지 않았거나, 만료되었거나, 이미 썼거나, 다른 계정의 충돌 티켓) | 401 |
| 3100 | `NotSignedIn` | 클라이언트 |
| 3101 | `PlatformSignInFailed` | 클라이언트 |
| 3102 | `InvalidResponse` | 클라이언트(5xx 는 본문과 관계없이 http `HttpError`) |
| 3103 | `StorageFailed` | 클라이언트(로그아웃 시 저장소 삭제 실패) |
| 3104 | `SessionChanged` | 클라이언트(토큰을 받는 동안 세션이 3번 넘게 바뀜, 다시 시도) |

## 서버 (`Server~/src/Geuneda.Account.Server/`)

| API | 설명 |
|-----|------|
| `IServiceCollection.AddGeunedaAccount(Action<AccountServerOptions>)` → `AccountServerBuilder` | 옵션 `Issuer`, `Audience`, `SigningCredentials`(필수), `AccessTokenLifetime` 1시간, `RefreshTokenLifetime` 30일, `RefreshReuseGrace` 30초, `ClockSkew` 1분, `NonceLifetime` 5분(최대 5분, nonce·충돌 티켓). `IAccessTokenValidator` 도 등록 |
| `AccountServerBuilder.AddGuest()`, `AddPlatformVerifier<T>()`, `AddInMemoryStores()` | 검증기(싱글턴), 메모리 저장소(샘플·테스트. 계정, refresh 토큰, `InMemoryOneTimeValueStore`) |
| `IEndpointRouteBuilder.MapGeunedaAccount(prefix = "/auth")` → `RouteGroupBuilder` | 시작 검사(옵션·서명 시험, 저장소 등록(`IOneTimeValueStore` 포함), 검증기 이름 중복). `POST nonce` 도 연결(인증 없음) |
| `IServiceCollection.AddGeunedaAccessTokenValidation(Action<AccessTokenValidationOptions>)` | 게임 서버용 검증기(`Issuer`, `Audience`, `SigningKeys`, `ClockSkew`) |
| `IAccessTokenValidator.ValidateAsync(token, ct)` → `AccessTokenValidation` | `IsValid`, `AccountId`(sub), `SessionId`(sid), `ExpiresAt`, `FailureReason`. 공개 팩토리 `Valid(...)`, `Invalid(reason)` |
| `IPlatformVerifier` | `Platform`, `RequiresNonce`, `VerifyAsync(credential, nonce, ct)` → `PlatformVerification.Valid(subject)`/`Invalid(reason)`/`NonceMismatch(reason)`(`IsNonceMismatch`). `nonce` 는 `RequiresNonce` 면 비지 않고 아니면 null. 저장소 확인·소비는 서버가 검증 뒤에 함 |
| `GuestPlatformVerifier` | Base64url 32~64바이트 → SHA-256 16진수 고유 ID. `RequiresNonce` false |
| nonce 흐름 | `POST nonce` → `{nonce, expiresIn}`(Base64url 43자, 1회용). 로그인·연동·옮겨오기 요청 `nonce`. 순서: 요청에 없음 400 `NonceMissing` → 검증기 클레임 불일치 401 `NonceMismatch` → `IOneTimeValueStore.TryConsumeAsync(Nonce, …)` 실패 401 `InvalidNonce` |
| 충돌 티켓 | 연동 충돌 409 `{code, message, conflictAccountId, conflictTicket}`. 티켓은 플랫폼·고유 ID·요청 계정에 묶이고 `NonceLifetime` 동안 1회. 로그인 `{platform, conflictTicket, sessionId?}` 는 티켓만으로, 옮겨오기 `{platform, conflictTicket}` 는 티켓을 받은 계정만(다른 계정이면 401 `InvalidConflictTicket`, 티켓 소비). 티켓과 자격·nonce 동시 전송, `POST links` 의 티켓은 400. 저장 실패면 503 |
| `IOneTimeValueStore` | nonce 와 충돌 티켓. `TryAddAsync(OneTimeValue, now, ct)` → bool(가득 차면 false → 503 `RetryLater`), `TryConsumeAsync(kind, hash, now, ct)` → `OneTimeValue`/null(원자적 삭제, 만료면 null). `OneTimeValue`(Kind `OneTimeValueKind.Nonce`/`ConflictTicket`, Hash = 원문 SHA-256 16진 소문자, ExpiresAt, 티켓만 Platform·Subject·AccountId). `InMemoryOneTimeValueStore(capacity = 100000)`: 두 용도 합계 상한, 넣을 때 만료 기록 정리(소비한 기록도 상한의 두 배 넘게 붙잡지 않음), 가득 차면 새 값 거절, 서버 한 대용 |
| `AccountServerBuilder.AddApple(o => o.Audiences...)`, `AddGoogle(o => o.ClientIds...)` | `AppleIdTokenVerifier`, `GoogleIdTokenVerifier`(공통 `OpenIdConnectPlatformVerifier`). id 토큰의 서명(발급자 JWKS)·발급자(애플 `https://appleid.apple.com`, 구글 `Issuer`·`LegacyIssuer`)·대상·만료(`ClockSkew` 기본 5분, 음수 거절)·`nonce` 클레임(`protected virtual NonceClaimOf`: 구글 원문, 애플 SHA-256 16진 소문자)을 검사하고 `sub` 를 고유 ID 로. `RequiresNonce` true. 대상이 비면 예외. account 0.2.0(nonce 는 0.3.0) |
| `OpenIdConnectKeyCache(metadataAddress, IDocumentRetriever, TimeProvider)` | 공개 키 캐시. `GetAsync`(12시간마다 갱신, 실패하면 옛 키 유지·5분 뒤 재시도), `RefreshAsync(seen)`(모르는 키: 다시 받기를 기다림, 5분 안에 받았으면 그대로), 동시 요청 한 번, 한 번 받기 10초 제한, 서명 키 없는 응답은 실패, 키가 없는데 받기 실패하면 30초 동안 바로 실패. 키를 확인하지 못하면 `InvalidOperationException`(500) |
| `IAccountStore` | `FindOrCreateAsync`, `ExistsAsync`, `GetLinksAsync`, `LinkAsync`/`TransferAsync`(`LinkOutcome`), `UnlinkAsync`(`UnlinkOutcome`), `DeleteAsync`. 고유성·플랫폼당 하나·마지막 수단을 원자적으로 |
| `IRefreshTokenStore` | `CreateAsync(family, token)`, `FindTokenAsync(hash)`, `FindFamilyAsync(id)`, `TryRotateAsync(familyId, expectedCurrentHash, updated, newToken)`(원자적), `RevokeFamilyAsync`, `RevokeAccountAsync`. `RefreshTokenFamily`(FamilyId, AccountId, SessionId, CurrentTokenHash, PreviousTokenHash, RotatedAt, CreatedAt, RevokedAt), `RefreshTokenRecord`(TokenHash, FamilyId, IssuedAt, ExpiresAt) |

경로와 본문은 패키지 README 의 "서버" 표를 본다. 요청 본문 16KB 제한, 오류 `{code, message, conflictAccountId?}`.

## 제공자 패키지

| 패키지 / 타입 | 설명 |
|---------------|------|
| `com.geuneda.account.apple` `AppleAuthProvider` | iOS 13+ ASAuthorizationController. 자격은 애플 identityToken. `RequiresNonce` true: 서버 nonce 원문의 SHA-256 16진 소문자를 `ASAuthorizationAppleIDRequest.nonce` 에(빈 nonce 는 `ArgumentException`). iOS 16+ 는 취소 토큰이 시트를 닫는다. 빌드 후처리 `AppleSignInCapability` 가 entitlements 에 Sign in with Apple 을 넣는다. `SignOutAsync` 는 할 일 없음 |
| `com.geuneda.account.google` `GoogleAuthProvider(GoogleAuthOptions)` | `RequiresNonce` true: 서버 nonce 원문을 Android `GetSignInWithGoogleOption.Builder.setNonce`, iOS 인가 요청 `nonce` 로 그대로(빈 nonce 는 `ArgumentException`). `AndroidServerClientId`(웹 클라이언트 ID), `IosClientId`, `TokenClient`(iOS 토큰 교환용 http, 기본 15초 타임아웃), `IosEphemeralSession`. Android: Credential Manager `GetSignInWithGoogleOption`(Android 라이브러리 플러그인이 `androidx.credentials` 1.3.0, `googleid` 1.1.1, `androidx.core`, `androidx.loader` 와 R8 규칙을 가져옴), `SignOutAsync` 는 로그인 상태 지우기를 기다림. iOS: ASWebAuthenticationSession + PKCE(S256, state) → `https://oauth2.googleapis.com/token` 교환 |
