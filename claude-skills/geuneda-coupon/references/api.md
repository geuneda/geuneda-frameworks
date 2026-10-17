# Geuneda Coupon API 레퍼런스

네임스페이스 `Geuneda.Coupon`(Unity asmdef `Geuneda.Coupon`, 참조 `Geuneda.Core`, `Geuneda.Http`, `UniTask`), 서버 `Geuneda.Coupon.Server`(`Server~/src/Geuneda.Coupon.Server`, net10.0). coupon 0.1.0.

## 클라이언트

### interface ICouponService / sealed class CouponService

| 멤버 | 설명 |
|------|------|
| `CouponService(CouponServiceOptions options)` | 메인 스레드(`Application.version`). null 은 `ArgumentNullException`, HTTP 클라이언트·경로 없음·제한 시간 0 이하는 `ArgumentException` |
| `UniTask<Result<CouponRedemption<TGrant>>> RedeemAsync<TGrant>(string code, CancellationToken ct = default)` | 다듬은 코드를 POST. 코드 모양이 아니면 보내지 않고 `InvalidCode`. 미리 취소면 `Cancelled` |

### sealed class CouponServiceOptions

| 속성 | 기본 | 설명 |
|------|------|------|
| `IHttpClient HttpClient` | 필수 | 서버 접두사까지 담은 기본 주소, 인증 미들웨어 |
| `string Route` | `CouponRoutes.Redeem` | |
| `string Platform` | `CouponPlatforms.Current` | |
| `string AppVersion` | `Application.version` | |
| `string Country` | null | ISO 3166-1 두 글자 |
| `TimeSpan RequestTimeout` | 10초 | |

### sealed class CouponRedemption<TGrant>

`CampaignId`, `Grant`(없으면 default), `RedeemedAt`, `AlreadyRedeemed`.

### 결과 판정

| 응답 | 결과 |
|------|------|
| 200, code 0, 캠페인 ID 있음 | 성공 |
| 200, code 11005, 캠페인 ID 있음 | 성공(`AlreadyRedeemed`) |
| 200·400·401·413·415·429, 양수 code | `Fail(code)`(429 는 메시지에 남은 초) |
| 그 상태들에서 code 없음·음수·본문 못 읽음 | 401 `Unauthorized`, 429 `TooManyAttempts`, 400·413·415 `BadRequest`, 그 밖 `HttpResultCodes.InvalidResponse` |
| 그 밖의 상태(5xx, 404, 프록시) | `HttpResultCodes.HttpError` |
| 전송 실패 | 그대로(`NetworkError`, `Timeout`, `Cancelled`) |

## 공유 (`Runtime/Protocol`)

- `CouponRedeemRequest { Code, Platform, AppVersion, Country }`
- `CouponRedeemResponse<TGrant> { int? Code, Message, CampaignId, Grant, DateTimeOffset? RedeemedAt, int? RetryAfterSeconds }`
- `CouponResultCodes`(11001~11013, `IsCodeFailure`), `CouponCodes.TryNormalize`(MinLength 4, MaxLength 64), `CouponPlatforms`(`Android`, `Ios`, `Standalone`, `WebGl`, Unity 에만 `Current`), `CouponRoutes.Redeem`

## 서버

| 멤버 | 설명 |
|------|------|
| `IServiceCollection.AddGeunedaCoupon(Action<CouponServerOptions> configure = null)` → `CouponServerBuilder` | `ICouponRedeemer`·`CouponAdmin`(요청 범위), 기본 `InMemoryCouponAttemptStore`, `TimeProvider.System`, 옵션 검증(시작 때) |
| `CouponServerBuilder.AddStore<T>(lifetime = Scoped)`, `AddInMemoryStore()` | 저장소 |
| `AddGrantor<T>(lifetime = Scoped)` | 지급자 |
| `AddAttemptStore<T>(lifetime = Singleton)` | 실패 기록 |
| `AddContextResolver<T>(lifetime = Scoped)` | 맥락 해석기(선택) |
| `IEndpointRouteBuilder.MapGeunedaCoupon(string prefix, Func<HttpContext, Task<string>> resolveAccountId)` → `RouteHandlerBuilder` | `POST {prefix}/redeem`. 저장소·지급자 없으면 `InvalidOperationException` |
| `CouponServerOptions` | `MaxFailures` 10(≥1), `FailureWindow` 1시간(>0), `MaxRequestBytes` 4096(≥256) |

### 캠페인

- `CouponCampaign(string id, CouponKind kind, string sharedCode = null, string reward = null, DateTimeOffset? startsAt = null, DateTimeOffset? endsAt = null, bool enabled = true, int? maxRedemptions = null, CouponConditions conditions = null)`: 규칙 위반은 `ArgumentException`. `CheckAvailability(now)` → 0 또는 `Disabled`·`NotStarted`·`Expired`.
- `CouponKind`: `Shared` 1, `Unique` 2.
- `CouponConditions(IEnumerable<string> platforms = null, IEnumerable<string> countries = null, string minAppVersion = null)`, `None`, `Allows(CouponContext)`.
- `CouponContext(accountId, platform, appVersion, country)`: 다듬음(플랫폼 소문자, 국가 대문자 두 글자, 앱 버전 64자 이하, 아니면 null).
- `ICouponContextResolver.ResolveAsync(HttpContext, CouponContext reported, ct)`: 계정 ID 를 바꾸면 500.

### 운영

- `CouponAdmin.AddCampaignAsync(campaign)` → `CouponAddResult`(`Added`, `DuplicateId`, `DuplicateCode`)
- `UpdateCampaignAsync(campaign)` → bool(없으면 false, 종류·공용 코드 변경은 `ArgumentException`)
- `AddCodesAsync(campaignId, codes)` → `CouponCodesAddResult { Added, Duplicates }`(형식 오류는 `ArgumentException`, 없는·공용 캠페인은 `InvalidOperationException`)

### 저장소·실패 기록·지급

- `ICouponStore`: `AddCampaignAsync`, `UpdateCampaignAsync`, `GetCampaignAsync`, `AddCodesAsync`, `FindCodeAsync` → `CouponCodeMatch { Campaign, Code }`, `FindRedemptionAsync` → `CouponRedemptionRecord { CampaignId, AccountId, Code, RedeemedAt, GrantJson }`, `RedeemAsync(CouponRedeemAttempt, Func<CancellationToken, Task<CouponStoreGrant>>, ct)` → `CouponStoreRedeemResult { Outcome(Recorded, Duplicate, CodeUsed, SoldOut, NotGranted), Record }`. 메모리 구현 `InMemoryCouponStore`(`GetRedemptionCount`).
- `ICouponAttemptStore`: `TryReserveAsync(accountId, at, since, limit, ct)` → `CouponAttemptReservation { ReservationId, IsReserved, Entries }`, `ReleaseAsync(accountId, reservationId, ct)`. 메모리 구현 `InMemoryCouponAttemptStore`.
- `ICouponGrantor.GrantAsync(CouponGrant, ct)` → `CouponGrantResult`(`Granted(object response = null)`, `Rejected(string)`, `RetryLater(string)`, `Status`, `Response`, `Message`; default 는 500).
- `ICouponRedeemer.RedeemAsync(string code, CouponContext context, ct)` → `CouponRedeemOutcome { Code, Message, Record, RetryAfterSeconds }`.

## 테스트

- Unity EditMode `Geuneda.Coupon.Tests.EditMode`(`SampleServerInteropTest` 는 명시 실행, `GEUNEDA_COUPON_INTEROP_URL`).
- .NET `dotnet test "Server~/Geuneda.Coupon.Server.slnx"`(xUnit, Kestrel).
- 샘플 서버: `dotnet run --project "Server~/samples/Geuneda.Coupon.SampleServer" --no-launch-profile -- --urls http://127.0.0.1:5699`.
