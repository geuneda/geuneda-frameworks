# Geuneda Account API 레퍼런스

네임스페이스 `Geuneda.Account`, 서버 `Geuneda.Account.Server`. 결과는 core `Result`/`Result<T>`.

## 인증 (`Runtime/Auth/`)

### interface IAuthService / sealed class AuthService : IAuthService, IDisposable

| 멤버 | 설명 |
|------|------|
| `AuthService(AuthServiceOptions)` | 저장된 로그인을 읽어 둠(형식이 깨졌으면 지움). 메인 스레드. 필수 설정 누락·시간 설정 범위 밖·제공자 이름 중복은 `ArgumentException` |
| `bool IsSignedIn`, `string AccountId`, `bool HasSavedLogin` | 이번 실행 로그인 여부, 계정(로그인 아니면 null), 저장된 로그인 여부 |
| `event Action<SignInResult> SignedIn` | 로그인·자동 로그인·계정 전환 성공 |
| `event Action<SignOutReason> SignedOut` | `SignedOut`(로그아웃), `LoginExpired`(서버가 refresh 토큰 거절), `AccountDeleted` |
| `UniTask<Result<SignInResult>> SignInAsync(string platform, ct)` | 제공자 로그인 → `POST login`. 미등록 플랫폼은 `ArgumentException` |
| `UniTask<Result<SignInResult>> SignInAsync(PlatformCredential, ct)` | 받은 자격으로 로그인(연동 충돌 후 그 계정으로) |
| `UniTask<Result<SignInResult>> SignInSilentlyAsync(ct)` | 저장된 로그인으로 `POST refresh`. 없으면 `NotSignedIn`, 서버 거절이면 저장된 로그인 삭제 |
| `UniTask<Result<string>> GetAccessTokenAsync(ct)` | 남은 수명 < min(margin, 수명/2) 이면 재발급(single-flight). 로그인 아니면 `NotSignedIn` |
| `void InvalidateAccessToken(string)` | 지금 토큰이면 다음 요청에서 재발급 |
| `UniTask<Result> SignOutAsync(ct)` | 로컬 먼저 삭제, 서버 `logout`·제공자 `SignOutAsync` 는 best effort. 저장소를 지우지도 덮어쓰지도 못하면 `StorageFailed` |
| `GetLinksAsync`, `LinkAsync(platform)`, `TransferAsync(credential)`, `UnlinkAsync(platform)`, `DeleteAccountAsync()` | 인증된 호출. `InvalidAccessToken` 이면 재발급 후 한 번 재시도, `AccountNotFound` 면 `SignedOut(AccountDeleted)`. 요청 중 로그인이 바뀌면 `NotSignedIn` 이고 응답을 적용하지 않음 |
| `Dispose()` | 진행 중 요청 취소(`Cancelled`), 늦은 결과는 적용하지 않음. 저장된 로그인은 둠 |

### sealed class AuthServiceOptions

`IHttpClient AuthClient`(기본 주소 `https://.../auth/`), `ISecureStore SecureStore`, `IAppSession Session`, `IList<IAuthProvider> Providers`, `TimeSpan AccessTokenRefreshMargin`(기본 1분), `TimeSpan RequestTimeout`(인증 서버 요청마다, 기본 15초).

### 결과 형식

- `SignInResult`: `AccountId`, `IsNewAccount`, `IsSaved`(이번 로그인을 이 기기에 저장했는지. false 면 이전 저장값은 지움, 그것도 못 한 다른 계정 전환은 `StorageFailed` 로 거절)
- `LinkResult`: `IsConflict`, `Links`(연동했을 때), `ConflictAccountId`, `Credential`(충돌일 때). 공개 팩토리 `Linked(links)`, `Conflict(accountId, credential)`
- `LinkedPlatform`: `Platform`, `LinkedAt`(DateTimeOffset)
- `PlatformCredential(platform, credential)`: `ToString` 은 자격을 숨김

### interface IAuthProvider

`string Platform`, `UniTask<Result<PlatformCredential>> SignInAsync(ct)`(사용자 취소 `Cancelled`, SDK 실패 `PlatformSignInFailed`), `UniTask SignOutAsync(ct)`(던지지 않음).

- `GuestAuthProvider(ISecureStore)`: 키 `geuneda.account.<env>.guestSecret` 의 32바이트 Base64url 비밀 값. 없으면 만들어 저장(저장 실패면 `PlatformSignInFailed`), 읽기 `Failed` 면 만들지 않음. 로그아웃해도 지우지 않음.

### sealed class AuthTokenMiddleware : IHttpMiddleware

`RetryMiddleware` 바깥(order 가 작음)에 둔다. `Authorization: Bearer <token>`. 응답 401 이면 `InvalidateAccessToken` → 재발급 실패면 그 결과 코드, 새 토큰이 다르고 계정이 그대로면 한 번만 재전송. 토큰을 못 얻으면 요청을 보내지 않고 그 결과 코드.

## 세션 (`Runtime/Session/`)

### interface IAppSession / sealed class AppSession : IAppSession, IDisposable

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
| 3011 | `RetryLater`(같은 로그인의 동시 재발급이 계속 겹침) | 503(클라이언트에서는 `HttpError`) |
| 3100 | `NotSignedIn` | 클라이언트 |
| 3101 | `PlatformSignInFailed` | 클라이언트 |
| 3102 | `InvalidResponse` | 클라이언트(5xx 는 본문과 관계없이 http `HttpError`) |
| 3103 | `StorageFailed` | 클라이언트(로그아웃 시 저장소 삭제 실패) |
| 3104 | `SessionChanged` | 클라이언트(토큰을 받는 동안 세션이 3번 넘게 바뀜, 다시 시도) |

## 서버 (`Server~/src/Geuneda.Account.Server/`)

| API | 설명 |
|-----|------|
| `IServiceCollection.AddGeunedaAccount(Action<AccountServerOptions>)` → `AccountServerBuilder` | 옵션 `Issuer`, `Audience`, `SigningCredentials`(필수), `AccessTokenLifetime` 1시간, `RefreshTokenLifetime` 30일, `RefreshReuseGrace` 30초, `ClockSkew` 1분. `IAccessTokenValidator` 도 등록 |
| `AccountServerBuilder.AddGuest()`, `AddPlatformVerifier<T>()`, `AddInMemoryStores()` | 검증기(싱글턴), 메모리 저장소(샘플·테스트) |
| `IEndpointRouteBuilder.MapGeunedaAccount(prefix = "/auth")` → `RouteGroupBuilder` | 시작 검사(옵션·서명 시험, 저장소 등록, 검증기 이름 중복) |
| `IServiceCollection.AddGeunedaAccessTokenValidation(Action<AccessTokenValidationOptions>)` | 게임 서버용 검증기(`Issuer`, `Audience`, `SigningKeys`, `ClockSkew`) |
| `IAccessTokenValidator.ValidateAsync(token, ct)` → `AccessTokenValidation` | `IsValid`, `AccountId`(sub), `SessionId`(sid), `ExpiresAt`, `FailureReason`. 공개 팩토리 `Valid(...)`, `Invalid(reason)` |
| `IPlatformVerifier` | `Platform`, `VerifyAsync(credential, ct)` → `PlatformVerification.Valid(subject)`/`Invalid(reason)` |
| `GuestPlatformVerifier` | Base64url 32~64바이트 → SHA-256 16진수 고유 ID |
| `IAccountStore` | `FindOrCreateAsync`, `ExistsAsync`, `GetLinksAsync`, `LinkAsync`/`TransferAsync`(`LinkOutcome`), `UnlinkAsync`(`UnlinkOutcome`), `DeleteAsync`. 고유성·플랫폼당 하나·마지막 수단을 원자적으로 |
| `IRefreshTokenStore` | `CreateAsync(family, token)`, `FindTokenAsync(hash)`, `FindFamilyAsync(id)`, `TryRotateAsync(familyId, expectedCurrentHash, updated, newToken)`(원자적), `RevokeFamilyAsync`, `RevokeAccountAsync`. `RefreshTokenFamily`(FamilyId, AccountId, SessionId, CurrentTokenHash, PreviousTokenHash, RotatedAt, CreatedAt, RevokedAt), `RefreshTokenRecord`(TokenHash, FamilyId, IssuedAt, ExpiresAt) |

경로와 본문은 패키지 README 의 "서버" 표를 본다. 요청 본문 16KB 제한, 오류 `{code, message, conflictAccountId?}`.
