---
name: geuneda-coupon
description: com.geuneda.coupon 패키지(네임스페이스 Geuneda.Coupon, 서버 Geuneda.Coupon.Server)로 쿠폰 코드 사용 코드를 작성하거나 수정할 때 사용하는 스킬. ICouponService·CouponService·CouponServiceOptions 로 쿠폰 코드를 서버에 보내 지급 결과(CouponRedemption<TGrant>, AlreadyRedeemed)를 받거나, CouponResultCodes(11000 블록: InvalidCode, Expired, CodeUsed, SoldOut, NotEligible, TooManyAttempts 등)로 안내 문구를 고르거나, CouponCodes.TryNormalize 로 코드를 다듬거나, ASP.NET Core 서버에서 AddGeunedaCoupon·MapGeunedaCoupon·CouponServerBuilder(AddStore, AddInMemoryStore, AddGrantor, AddAttemptStore, AddContextResolver)로 쿠폰 엔드포인트를 붙이거나, CouponCampaign(공용 코드 Shared, 개별 일회용 코드 Unique, 기간, 한도, CouponConditions 플랫폼·국가·최소 앱 버전)·CouponAdmin(AddCampaignAsync, AddCodesAsync, UpdateCampaignAsync)으로 캠페인을 등록하거나, ICouponGrantor·CouponGrantResult 로 보상을 지급하거나, ICouponStore·ICouponAttemptStore 를 게임 DB·Redis 로 구현하거나, ICouponContextResolver 로 국가·플랫폼을 서버 값으로 정하거나, ICouponRedeemer 를 다른 통로(실시간 RPC)에서 부를 때 활성화한다.
---

# Geuneda Coupon

쿠폰 사용. 클라이언트는 코드를 보내고 결과를 받기만 하고, 판정과 지급은 서버가 한다(보상은 서버가 지급). 서버 라이브러리가 공용·개별 일회용 코드, 기간, 대상 조건, 계정별 실패 제한을 판정하고 사용 기록과 게임 지급을 저장소의 한 트랜잭션으로 묶는다.

## 패키지 정보

- **버전**: 0.1.1
- **네임스페이스 / 어셈블리**: `Geuneda.Coupon`(Unity), 서버 `Geuneda.Coupon.Server`
- **설치**: `https://github.com/geuneda/geuneda-coupon.git`(core, http, UniTask git URL 도 함께). Unity 2021.3+
- **서버**: `Server~/src/Geuneda.Coupon.Server/Geuneda.Coupon.Server.csproj`(net10.0, ASP.NET Core)를 ProjectReference 로 참조. `Runtime/Protocol` 을 링크해 같은 DTO·결과 코드·코드 규칙
- **기여 가이드**: 패키지 루트의 `AGENTS.md`. 실제 DB 저장소 구현 예시(Postgres·Redis, 실제 DB 동시 요청 시험 결과)는 패키지의 `docs/db-store.md`
- **출처**: Lucky Defense Percent `Marketings.Coupon`(서버 지급, 이유 코드), SpellDefense 쿠폰(성공 판정 혼란)의 보완(로드맵 5-2 2단위)

## 핵심 API

전체 시그니처는 `references/api.md`.

- `new CouponService(CouponServiceOptions)` → `ICouponService`. 필수 `HttpClient`(기본 주소에 서버 접두사, 인증 미들웨어). 기본 `Route` = `redeem`, `Platform` = `CouponPlatforms.Current`, `AppVersion` = `Application.version`, `Country` 없음, `RequestTimeout` 10초.
- `RedeemAsync<TGrant>(code, ct)` → `Result<CouponRedemption<TGrant>>`(`CampaignId`, `Grant`, `RedeemedAt`, `AlreadyRedeemed`).
- `CouponResultCodes`: 11001 `InvalidCode`, 11002 `NotStarted`, 11003 `Expired`, 11004 `Disabled`, 11005 `AlreadyRedeemed`(클라이언트는 성공), 11006 `CodeUsed`, 11007 `SoldOut`, 11008 `NotEligible`, 11009 `GrantRejected`, 11010 `GrantDeferred`, 11011 `TooManyAttempts`, 11012 `BadRequest`, 11013 `Unauthorized`, `IsCodeFailure(code)`.
- `CouponCodes.TryNormalize(raw, out normalized)`: 공백·탭·`-` 제거, ASCII 대문자, 영숫자 4~64자.
- 서버: `services.AddGeunedaCoupon(o => { o.MaxFailures; o.FailureWindow; o.MaxRequestBytes })` → `.AddStore<T>()`/`.AddInMemoryStore()`, `.AddGrantor<T>()`, `.AddAttemptStore<T>()`, `.AddContextResolver<T>()`. `app.MapGeunedaCoupon("/coupons", resolveAccountId)` → `POST /coupons/redeem`.
- 캠페인: `new CouponCampaign(id, CouponKind.Shared|Unique, sharedCode, reward, startsAt, endsAt, enabled, maxRedemptions, conditions)`, `new CouponConditions(platforms, countries, minAppVersion)`, `CouponAdmin.AddCampaignAsync/AddCodesAsync/UpdateCampaignAsync`.
- 지급자: `ICouponGrantor.GrantAsync(CouponGrant{Campaign, Code, Context, AccountId, RedeemedAt})` → `CouponGrantResult.Granted(response)`/`Rejected(msg)`/`RetryLater(msg)`.

## 사용 패턴

```csharp
var coupons = new CouponService(new CouponServiceOptions
{
    HttpClient = new HttpClientBuilder().WithBaseAddress("https://game.example.com/coupons/").AddMiddleware(authTokenMiddleware).Build()
});
MainInstaller.Bind<ICouponService>(coupons);

var result = await coupons.RedeemAsync<MyGrant>(input.text, token);
if (result.TryGetValue(out var redemption))
{
    if (redemption.AlreadyRedeemed) ShowToast("이미 사용한 쿠폰");   // 보상을 다시 더하지 않음
    else ShowRewards(redemption.Grant);
    await SyncWalletFromServerAsync();
}
else if (result.Code == ResultCodes.Timeout || result.Code == ResultCodes.NetworkError) ShowRetry();   // 같은 코드를 다시 보내면 안전
else ShowToast(MessageFor(result.Code));
```

서버:

```csharp
builder.Services.AddGeunedaCoupon().AddStore<DbCouponStore>().AddGrantor<WalletGrantor>().AddAttemptStore<RedisAttemptStore>();
app.MapGeunedaCoupon("/coupons", async context =>
{
    var header = context.Request.Headers.Authorization.ToString();
    var token = header.StartsWith("Bearer ") ? header.Substring(7) : null;
    var validation = await context.RequestServices.GetRequiredService<IAccessTokenValidator>().ValidateAsync(token, context.RequestAborted);
    return validation.IsValid ? validation.AccountId : null;
});
// 운영 도구
await admin.AddCampaignAsync(new CouponCampaign("welcome", CouponKind.Shared, "WELCOME2026", reward: "{\"gem\":100}", maxRedemptions: 10000));
await admin.AddCampaignAsync(new CouponCampaign("collab", CouponKind.Unique, reward: "{\"skin\":\"a\"}"));
await admin.AddCodesAsync("collab", partnerCodes);
```

## 규칙

- **처리 순서**: 실패 예약(한도면 429) → 다듬기·찾기 → 이 계정의 이전 사용(있으면 기간과 상관없이 처음 결과 `AlreadyRedeemed`) → 켜짐·기간·조건 → 저장소 트랜잭션(중복 → 개별 코드 사용 → 전체 한도 → 지급 → 기록).
- **실패 제한**: 코드 실패(`IsCodeFailure`)만 센다. 판정 전에 원자적으로 예약하고 코드 실패가 아니면 지워, 동시 요청도 한도 안에서만 판정한다. 기본 1시간 10번.
- **같은 계정의 재요청은 안전**: 처음 지급 결과를 돌려준다. 같은 캠페인의 다른 개별 코드도 `AlreadyRedeemed`(코드는 쓰이지 않음).
- **공용·개별 코드는 한 이름 공간**: 겹치면 등록이 거절된다.
- **클라이언트 값은 위조 가능**: 플랫폼·앱 버전·국가 조건이 중요하면 `ICouponContextResolver` 나 지급자 `Rejected` 로 서버 값을 쓴다.
- **지급자는 저장소 트랜잭션 안**: 롤백 뒤 다시 불릴 수 있으므로 게임 쓰기는 모두 그 트랜잭션에 넣는다. 예외는 500.
- **성공 판정(클라이언트)**: HTTP 200 + 결과 코드 + 캠페인 ID 가 있을 때만. 5xx·프록시 JSON 은 `HttpError`·`InvalidResponse`, 본문 없는 401·429·4xx 는 상태로 코드.

## 함정

- `InMemoryCouponStore` 는 지급을 롤백하지 않는다(기록 미커밋만 보장). 운영은 게임 DB 저장소로 구현한다.
- DB 저장소의 유일 제약은 같은 계정 중복만 막는다. 전체 한도는 `used < max` 조건부 증가나 캠페인 행 잠금, 개별 코드는 `used_by IS NULL` 조건부 갱신이나 행 잠금이 필요하다(`ICouponStore` remarks).
- DB 저장소 순서는 사용 기록 자리를 먼저 차지한다(`INSERT ... ON CONFLICT DO NOTHING` → 개별 코드 → 사용 수 → 지급 → 지급 결과 → 커밋). 기록을 맨 뒤에 넣으면서 조건부 갱신 0행을 바로 `CodeUsed`·`SoldOut` 으로 끝내면 같은 계정의 동시 요청이 처음 결과 대신 코드 실패를 받고 실패 제한에도 센다(실제 Postgres 에서 재현). 그 순서면 0행일 때 기록을 다시 읽는다. 전체 구현은 `docs/db-store.md`.
- 지급자는 저장소와 같은 요청 범위 DB 세션에서 저장소가 연 트랜잭션으로만 쓴다(지급 콜백은 트랜잭션을 넘기지 않음). 지급 호출은 롤백될 수 있어 트랜잭션 밖 부작용(외부 API, 메모리 상태)은 커밋 뒤로 미룬다.
- Postgres 에서 사용 기록이 캠페인 행을 외래 키로 참조하면 사용 수 갱신과 지급 실패 롤백이 겹칠 때 `new multixact has more than one updating member`(500)가 날 수 있다. 예시 표는 외래 키를 두지 않는다. 지급 시각은 `RETURNING` 으로 저장한 값을, 지급 결과는 `text` 열(jsonb 는 키 순서가 바뀜).
- 공용·개별 코드 한 이름 공간은 두 표의 유일 제약으로 지켜지지 않는다. 등록을 잠금으로 줄 세우거나 코드 하나를 키로 하는 표를 둔다.
- 범위는 `await using var scope = app.Services.CreateAsyncScope()` 로 연다. 동기 `using ... CreateScope()` 는 `IAsyncDisposable` 만 구현한 요청 범위 서비스에서 예외다.
- 진행 중 요청도 실패 한도에 들어가 한 계정이 `MaxFailures` 보다 많은 요청을 동시에 보내면 일부는 429 다. 켜짐·기간·조건은 트랜잭션 밖에서 판정하므로 끈 직후에도 판정을 지난 요청은 지급된다.
- `InMemoryCouponAttemptStore` 는 서버 한 대 기준이다. 여러 대면 공유 저장소(계정별 배타 세기·넣기)를 붙인다.
- 국가는 기본으로 보내지 않는다(기기 지역을 믿기 어려움). 국가 조건이 있는 캠페인은 `Country` 를 넣거나 서버 해석기를 쓴다.
- 개별 코드는 이 패키지가 만들지 않는다. 혼동 글자를 뺀 12자 이상 무작위로 만든다.
- `AddGrantor<T>` 는 같은 T 를 따로 등록해도 별도 인스턴스다(테스트에서 상태를 보려면 팩토리 등록).
- 캠페인의 종류·공용 코드는 바꿀 수 없다(새 캠페인).
