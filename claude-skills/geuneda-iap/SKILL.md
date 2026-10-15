---
name: geuneda-iap
description: com.geuneda.iap 패키지(네임스페이스 Geuneda.Iap, 선택 어셈블리 Geuneda.Iap.Analytics)와 Unity IAP 어댑터 패키지 com.geuneda.iap.unity(Geuneda.Iap.Unity)로 인앱 결제 코드를 작성하거나 수정할 때 사용하는 스킬. IIapService·IapService·IapServiceOptions 로 상품을 초기화·구매(PurchaseAsync)·복구(RecoverAsync)·복원(RestoreAsync)·보유 조회(CheckEntitlementAsync)하거나, 게임 서버 지급을 IPurchaseFulfiller·FulfillmentResult(Granted, AlreadyGranted, RetryLater, Rejected)로 구현하거나, IapOrder(영수증, 거래 ID, App Store 서명 SignedTransaction, Payload)를 서버로 보내거나, IapResultCodes(7000 블록)로 결제 결과 안내를 고르거나, OrderSettled·OrderFailed·PurchaseConfirmed·StoreUiChanged 이벤트를 쓰거나, UnityIapStore(Unity IAP 5.4.4 StoreController)를 붙이거나, IIapStore 로 다른 스토어(원스토어 등) 어댑터를 만들거나, IapRevenueLogger 로 확정한 구매를 analytics 매출 이벤트로 기록하거나, HttpPurchaseFulfiller(Geuneda.Iap.Http)로 결제 서버에 지급을 맡기거나, ASP.NET Core 결제 서버 Geuneda.Iap.Server(AddGeunedaIap, MapGeunedaIap, IPurchaseLedger 영수증 원장, IPurchaseGrantor, Google Play·App Store 영수증 검증, IapRedeemCodes)를 구현하거나, 결제 후 지급 누락·중복 지급·미확정(pending) 주문 복구를 다룰 때 활성화한다.
---

# Geuneda IAP

인앱 결제다. 결제한 주문은 게임의 지급자(서버 지급)가 지급을 확인한 뒤에만 스토어 거래를 닫아, 결제했는데 지급되지 않은 주문이 스토어에 남아 다시 처리되게 한다. 새 구매, 이전 실행의 결제, 결제창 시간 초과 뒤 늦게 온 결제, 승인 대기 뒤 승인, 중복 거래가 모두 같은 지급 경로를 지난다.

## 패키지 정보

- **버전**: iap 0.1.0(main 의 [Unreleased]: 결제 서버 `Server~`, HTTP 지급자), iap.unity 0.1.0
- **네임스페이스 / 어셈블리**: `Geuneda.Iap`. 선택 어셈블리 `Geuneda.Iap.Analytics`(analytics 0.2.0 이상), `Geuneda.Iap.Http`(http 0.1.0 이상, `versionDefines` 로 켜짐). 어댑터 `Geuneda.Iap.Unity`. .NET 서버 `Geuneda.Iap.Server`(`Server~`, .NET 10, Google.Apis.Auth 1.77.0)
- **설치**: `https://github.com/geuneda/geuneda-iap.git`, `https://github.com/geuneda/geuneda-iap-unity.git` (core, UniTask git URL 도 함께)
- **의존성**: iap 은 `com.geuneda.core` 0.4.0, `com.cysharp.unitask` 2.5.10(Unity 2021.3+). iap.unity 는 여기에 `com.unity.purchasing` 5.4.4(Unity 2022.3+, UPM 의존성이라 함께 설치)
- **기여 가이드**: 각 패키지 루트의 `AGENTS.md`
- **출처**: Lucky Defense Percent Purchase 와 게임 상점 코드(로드맵 4-2). 서버 지급 뒤 Confirm, '이미 지급'도 Confirm, 구매·복구 상호 배제, 같은 상품 미확정 주문 먼저, 중복 거래 재조회, 결제창 동안만 핑퐁 중지, 확정 성공 한 곳에서 매출을 따랐다. 복구 때 항상 재조회, 포그라운드 복귀·백오프 재시도, 늦은 결제 지급, 확정만 재시도, 원인별 결과 코드와 실패 이벤트, 실패 이유 명시 매핑으로 레퍼런스 약점을 보완했다

## 핵심 API

전체 시그니처는 `references/api.md`.

- `new IapService(IIapStore store, IPurchaseFulfiller fulfiller, IapServiceOptions options)` → `IIapService`(`IDisposable`). 메인 스레드에서만. 스토어 어댑터는 게임이 따로 정리한다.
- `IapServiceOptions`: `Products`(필수, `IapProductDefinition` 목록), `ConnectTimeout` 30초, `FetchTimeout` 15초, `StoreResponseTimeout` 3분(결제창), `FulfillTimeout` 30초, `ConfirmTimeout` 15초, `RetryDelay` 5초(최소 1초), `MaxRetryDelay` 5분, `RecoverOnResume` true.
- `new IapProductDefinition(id, IapProductType.Consumable|NonConsumable|Subscription, storeSpecificId = null)`.
- `InitializeAsync(ct)` → `Result`(연결 → 상품 조회 → 뒤에서 복구 시작). `PurchaseAsync(productId, payload = null, ct)` → `Result<PurchaseSettlement>`. `RecoverAsync(ct)` → `Result<RecoverySummary>`(`Granted`, `Retrying`, `Rejected`, `Unresolved`). `RestoreAsync(ct)` → `Result<IReadOnlyList<IapOrder>>`(보유 비소모성·구독). `CheckEntitlementAsync(productId, ct)` → `Result<IapEntitlementStatus>`. `IsInitialized`, `Products`, `TryGetProduct`, `IsStoreUiOpen`.
- 이벤트: `OrderSettled(PurchaseSettlement)` 주문마다 한 번, `OrderFailed(IapOrderFailure)`(`Code`, `Message`, `Attempts`, `WillRetry`), `PurchaseConfirmed(PurchaseSettlement)` 매출 지점(거래마다 한 번: 결제 서버 응답이면 서버 첫 지급 `Granted` 를 닫을 때, 그 밖은 스토어 `Confirmed`), `StoreUiChanged(bool)`, `ProductsUpdated`. `IIapService : IDisposable`.
- `IPurchaseFulfiller.FulfillAsync(IapOrder, ct)` → `FulfillmentResult.Granted(response)`, `AlreadyGranted(response, message)`, `RetryLater(message)`, `Rejected(message)`. `default` 는 정의되지 않은 값(Error 후 재시도).
- `IapOrder`: `ProductId`, `StoreProductId`, `Definition`, `StoreName`, `TransactionId`, `Receipt`, `SignedTransaction`(App Store JWS), `OriginalTransactionId`, `Origin`(`Purchase`, `Recovered`, `Restored`), `Payload`, `Price`(decimal), `CurrencyCode`, `ProductTitle`.
- `PurchaseSettlement`: `Order`, `Fulfillment`, `IsConfirmed`(false 면 지급은 됐고 확정만 재시도 중), `IsAwaited`(PurchaseAsync 가 받는 결과인지).
- `new UnityIapStore()`(Unity IAP 기본 스토어), `new UnityIapStore(StoreController, storeName)`. `Dispose()`.
- `new IapRevenueLogger(iap, analytics, sinks = null, paidAmount = null)` → 확정 성공마다 `LogPurchase`. `paidAmount(PurchaseSettlement) → IapPaidAmount?`(금액, 통화)는 서버가 확인한 실결제(null 이면 기록 안 함). 기본 `DefaultPaidAmount` 는 지급 결과가 결제 서버 응답이면 테스트 결제·환불 제외하고 서버 금액, 그 밖은 구독 null, 표시 가격과 상품 조회 통화. `Dispose()`.
- `new HttpPurchaseFulfiller<TGrant>(IHttpClient http)`(Geuneda.Iap.Http): 결제 서버 `POST purchases` 로 지급. 결과 `Response` 는 `IapRedeemResponse<TGrant>`(`Grant`, `Code`, `IsTest`, `PaidAmount`, `PaidCurrency`, `ExpiresAt`). 다른 경로(RPC)는 `order.ToRedeemRequest()`, `response.ToFulfillmentResult()`.
- 서버: `services.AddGeunedaIap(o => o.Products.Add(new IapServerProduct(id, type, googlePlayId, appStoreId))).AddGooglePlay(o => { o.PackageName = ...; o.ServiceAccountKeyJson = ...; }).AddAppStore(o => o.BundleId = ...).AddGrantor<T>().AddLedger<T>()`, `app.MapGeunedaIap("/iap", ctx => accountId)`. 게임은 `IPurchaseGrantor`(원장 트랜잭션 안에서 지급)와 `IPurchaseLedger`(유일 키 + 지급 한 트랜잭션, 확인 대기 조회·표시)를 구현한다.

## 사용 패턴

```csharp
public sealed class ShopFulfiller : IPurchaseFulfiller
{
    public async UniTask<FulfillmentResult> FulfillAsync(IapOrder order, CancellationToken ct)
    {
        if (!_api.IsSignedIn) return FulfillmentResult.RetryLater("not signed in");   // 로그인 뒤 RecoverAsync
        var res = await _api.BuyAsync(order.ProductId, order.StoreName, order.TransactionId, order.Receipt,
            order.SignedTransaction, order.Payload, ct);
        switch (res.Status)
        {
            case BuyStatus.Granted: return FulfillmentResult.Granted(res);   // 응답 전체(보상, 실결제 금액·통화)
            case BuyStatus.Duplicate: return FulfillmentResult.AlreadyGranted(res);   // 오류 아님
            case BuyStatus.InvalidReceipt: return FulfillmentResult.Rejected(res.Message);
            default: return FulfillmentResult.RetryLater(res.Message);
        }
    }
}

var store = new UnityIapStore();
var iap = new IapService(store, new ShopFulfiller(api), new IapServiceOptions
{
    Products = new[]
    {
        new IapProductDefinition("gem_100", IapProductType.Consumable),
        new IapProductDefinition("no_ads", IapProductType.NonConsumable),
        new IapProductDefinition("vip_month", IapProductType.Subscription, "com.game.vip.month")
    }
});
MainInstaller.Bind<IIapService>(iap);
iap.OrderSettled += s => { if (!s.IsAwaited && s.Fulfillment.Status == FulfillmentStatus.Granted) ShowReward(((BuyResponse) s.Fulfillment.Response).Rewards); };
iap.OrderFailed += f => remoteLog.Warn("iap_order_failed", f.ToString());
iap.StoreUiChanged += open => realtime.SuspendPingTimeout(open);
var revenue = new IapRevenueLogger(iap, analytics,   // analytics 가 있을 때
    paidAmount: s => { var r = (BuyResponse) s.Fulfillment.Response; return new IapPaidAmount(r.PaidAmount, r.PaidCurrency); });   // 서버가 확인한 금액·통화
await iap.InitializeAsync();

// 로그인 직후, 실시간 재연결 직후
await iap.RecoverAsync();

var r = await iap.PurchaseAsync("gem_100", payload: selectedRewardId);
if (r.IsSuccess) ShowReward(((BuyResponse) r.Value.Fulfillment.Response).Rewards);
else if (r.Code == IapResultCodes.UserCancelled) { }
else if (r.Code == ResultCodes.Timeout || r.Code == ResultCodes.Cancelled || r.Code == IapResultCodes.Deferred ||
         r.Code == IapResultCodes.DuplicateTransaction || r.Code == IapResultCodes.FulfillmentPending)
    ShowToast("purchase_processing");   // 결제됐을 수 있다. 끝나면 OrderSettled
else ShowToast("purchase_failed");

// 정리
revenue.Dispose();
MainInstaller.CleanDispose<IIapService>();
store.Dispose();
```

결제 서버(`Server~`)를 쓰면 지급자를 직접 만들지 않는다:

```csharp
// 클라이언트
var http = new HttpClientBuilder().WithBaseAddress("https://game.example.com/iap/").AddMiddleware(new AuthTokenMiddleware(auth)).Build();
var iap = new IapService(store, new HttpPurchaseFulfiller<ShopGrant>(http), options);
var revenue = new IapRevenueLogger(iap, analytics);   // 기본 규칙이 서버 응답의 금액·테스트 결제·환불을 처리

// 서버(ASP.NET Core)
builder.Services.AddGeunedaIap(o => o.Products.Add(new IapServerProduct("gem_100", IapProductType.Consumable)))
    .AddGooglePlay(o => { o.PackageName = "com.company.game"; o.ServiceAccountKeyJson = secrets.GooglePlayKey; })
    .AddAppStore(o => o.BundleId = "com.company.game")
    .AddGrantor<ShopGrantor>()        // 원장 트랜잭션 안에서 인벤토리 지급 → GrantResult.Granted(new ShopGrant { ... })
    .AddLedger<SqlPurchaseLedger>();  // (Store, TransactionId) 유일 키 + 지급 한 트랜잭션, 확인 대기 조회·표시
app.MapGeunedaIap("/iap", async ctx => (await validator.ValidateAsync(BearerToken(ctx), ctx.RequestAborted)) is { IsValid: true } v ? v.AccountId : null);
```

## 규칙

- **확정은 지급 뒤에만**: `Granted`·`AlreadyGranted` 뒤에만 스토어 거래를 닫는다. `RetryLater`·지급자 예외·`FulfillTimeout` 초과는 거래를 열어 두고 백오프(5초→두 배→5분, 50~100%)로 다시 지급, `Rejected` 는 열어 두고 이번 실행에서 자동 재시도하지 않는다(`RecoverAsync`·같은 상품 구매·다음 실행 때 다시).
- **서버**: 영수증(또는 거래 ID)을 유일 키로 저장하고 지급과 같은 트랜잭션에서 처리한다. 같은 영수증이 다시 오면 `AlreadyGranted`(오류 아님). 검증과 지급 저장을 나누면 그 사이 앱 종료 때 재시도가 '이미 쓴 영수증'으로 거절돼 영구 누락된다. 시간 초과 뒤 같은 주문이 다시 올 수 있으니 멱등이어야 한다. App Store 는 `SignedTransaction`(JWS)으로 검증한다(`Receipt` 의 앱 영수증은 StoreKit 2 에서 비어 있을 수 있음). `Geuneda.Iap.Server` 가 이것을 지킨다.
- **결제 서버 처리**: 원장 확인(있으면 스토어 안 부름, 같은 계정 `Duplicate`+처음 응답, 다른 계정 `OwnedByOtherAccount`, 둘 다 `AlreadyGranted`) → 스토어 검증 → 원장 트랜잭션 안에서 지급자 → 커밋 뒤 Google 확인(acknowledge, 소비는 안 함). 확인 실패·서버 종료는 원장의 `AcknowledgementDueAt` 으로 확인 작업자가 다시 한다(실패는 뒤로 미뤄 다음 배치, 3일 기한). App Store·Mac App Store 는 원장 스토어 하나(`AppleAppStore`).
- **확실하지 않으면 닫지 않는다**: 서버는 모르는 상태·네트워크·401/403/429/5xx·상품 목록 없는 응답·OCSP 미도달을 `RetryLater`, 클라이언트 변환도 5xx·본문 오류·모르는 상태를 `RetryLater` 로 둔다. 지급 없이 닫는 것(`Revoked`)은 스토어가 환불·취소라고 분명히 답할 때만.
- **재조회**: 초기화, 포그라운드 복귀, `RecoverAsync`, 중복 거래 때 스토어를 다시 조회한다. 조회 실패는 실패 코드다(빈 목록 아님).
- **늦은 결제**: 결제창 시간 초과(`Timeout`)·호출자 취소(`Cancelled`)·승인 대기(`Deferred`) 뒤 온 결제는 그 구매의 `Payload` 로 뒤에서 지급하고 `OrderSettled(IsAwaited false)` 로 알린다. 같은 상품을 다시 사면 먼저 재조회해 그 결제가 와 있으면 그것을 지급해 돌려주고, 없을 때만 이전 페이로드를 버리고 결제창을 연다.
- **결제창과 조회 경합**: 결제창이 열린 동안 조회가 찾은 같은 상품의 새 주문은 결제창의 답이 올 때까지 보류한다(그 구매의 것일 수 있음).
- **재조회·재연결**: 조회가 실패하면 백오프로 다시 조회하고, 확정 전에는 끊긴 스토어를 다시 연결한다.
- **재진입 안전**: 이벤트는 상태를 다 바꾼 뒤 올린다. 처리기에서 `RecoverAsync`·`Dispose` 를 불러도 된다(결제창 열림 처리기에서 종료하면 결제를 시작하지 않음).
- **같은 상품 미확정 주문**: 구매하면 결제창 전에 그 주문을 먼저 지급해 결과로 돌려준다(`Origin` Recovered). 지급 뒤 확정만 남았으면 확정한 뒤 결제창을 연다.
- **확정만 실패**: 구매는 성공(`IsConfirmed` false)이고 확정만 다시 한다. `OrderSettled` 는 한 번, `PurchaseConfirmed` 는 실제 확정 때 한 번.
- **종류 모르는 주문**: 스토어나 정의가 모르는 상품은 지급·확정하지 않고 `OrderFailed(UnknownProduct)`. 판매를 그만둔 상품도 `Products` 에서 빼지 않는다(Google 은 종류 모르는 주문을 확정하면 소비 대신 승인만 해 영구 보유).
- **한 번에 하나**: 구매·복원은 하나(`InProgress`), 지급·확정은 한 줄 큐(구매 주문이 앞), 거래 ID 로 중복 제거.
- **결제됐을 수 있는 실패 코드**(`Timeout`, `Cancelled`, `Deferred`, `DuplicateTransaction`, `FulfillmentPending`)에 '결제 실패'를 띄우지 않는다.
- **오용은 예외**: 정의에 없는 상품 ID, 빈 ID, 중복 정의, 범위 밖 설정, 다른 스레드 호출, `Dispose` 뒤 호출.

## 함정

- `Payload` 는 메모리에만 있다. 재시작 뒤 복구한 주문은 null 이다. 지급에 꼭 필요한 선택은 결제 전에 서버에 저장하거나 복구 때 다시 묻는다.
- `UnityIapStore` 의 `StoreController` 이벤트를 다른 곳에서 구독하거나 직접 `ConfirmPurchase` 하지 않는다.
- Unity IAP 는 플레이 모드에서만 스토어를 만든다(EditMode 에서 "Store Factory not present"). 에디터 가짜 스토어 기본은 확인 창이라 자동 테스트는 define `IAP_FAKE_STORE_DEFAULT` 를 넣는다.
- Unity IAP 에도 `Result` 타입이 있다. `using UnityEngine.Purchasing;` 과 `Geuneda.Core` 를 함께 쓰면 별칭(`using Result = Geuneda.Core.Result;`)을 둔다.
- 매출은 `PurchaseConfirmed` 한 곳에서만 기록한다(`IapRevenueLogger`). 지급 화면에서 따로 `LogPurchase` 하면 두 번 잡힌다. 표시 가격(`IapOrder.Price`)은 무료 체험·할인·프로모션의 실결제 금액이 아니다.
- `IIapStore.ConfirmAsync` 를 직접 구현하면, 시간 초과 뒤 같은 거래로 다시 불렸을 때 앞 요청이 성공했으면 그 결과를 돌려준다(다시 확정하면 Google 은 실패).
- 결제 서버 응답이면 매출 근거는 서버 첫 지급(`Granted`) 하나다(서버가 Google 결제를 먼저 확인해 클라이언트 확정이 `AlreadyConfirmed` 여도 매출, `AlreadyGranted` 면 `Confirmed` 여도 매출 없음). 첫 응답이 유실되면 클라이언트 매출 이벤트는 빠지므로 정확한 집계는 서버 원장으로 한다. 서버 금액은 수량 포함 총액이다.
- 서버 App Store 검증은 인증서 내려받기를 끄고 신뢰 체인을 먼저 확인한 뒤에만 OCSP 를 묻는다(공격자 인증서의 AIA 주소로 서버가 요청하는 SSRF 방지). 직접 `X509Chain` 을 쓸 때도 같은 순서를 지킨다.
- `AllowTestPurchases`·`AllowSandbox` 를 끄면 App Store 심사 구매(운영 서버로 오는 샌드박스 결제)가 실패한다. 매출에서는 `IsTest` 로 뺀다.
- 원장을 바꾸면 이전 서버가 지급한 남은 거래가 다시 지급될 수 있다. `FindAsync` 가 이전 기록도 보게 한다.
- 서버 알림(Google RTDN, App Store Server Notifications V2: 환불 회수, 구독 갱신)은 같은 작업의 다음 단계로 진행 중이다.
