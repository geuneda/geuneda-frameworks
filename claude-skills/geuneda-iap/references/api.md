# Geuneda IAP API 레퍼런스

네임스페이스 `Geuneda.Iap`(선택 어셈블리 `Geuneda.Iap.Analytics`·`Geuneda.Iap.Http`, 어댑터 `Geuneda.Iap.Unity`, .NET 서버 `Geuneda.Iap.Server`). iap 0.2.0(결제 서버·HTTP 지급자 포함), iap.unity 0.1.0.

## 서비스

### interface IIapService / sealed class IapService : IIapService, IDisposable

| 멤버 | 설명 |
|------|------|
| `IapService(IIapStore store, IPurchaseFulfiller fulfiller, IapServiceOptions options)` | 메인 스레드에서 만든다. null 은 `ArgumentNullException`, 빈 상품 목록·null 항목·겹치는 ID·스토어 ID 는 `ArgumentException`, 범위 밖 시간은 `ArgumentOutOfRangeException`. 플레이 중이면 숨은 수명 오브젝트(일시정지·복귀)를 만든다 |
| `bool IsInitialized` | 연결과 상품 조회가 끝났는지 |
| `IReadOnlyList<IapProduct> Products` | 스토어에서 받은 상품(정의에 있는 것만) |
| `bool IsStoreUiOpen` | 결제창·복원 요청이 열려 있는지 |
| `bool TryGetProduct(string productId, out IapProduct product)` | |
| `UniTask<Result> InitializeAsync(CancellationToken ct = default)` | single-flight. 연결 실패 `StoreUnavailable`, 상품 없음 `NoProducts`, 시간 초과 `Timeout`. 성공하면 뒤에서 복구를 시작한다. 실패 뒤 포그라운드 복귀 때 다시 한다 |
| `UniTask<Result<PurchaseSettlement>> PurchaseAsync(string productId, string payload = null, CancellationToken ct = default)` | 정의에 없거나 빈 ID 는 `ArgumentException`(태스크 예외). 코드는 `IapResultCodes` 와 `Cancelled`·`Timeout`·`InProgress` |
| `UniTask<Result<RecoverySummary>> RecoverAsync(CancellationToken ct = default)` | 재조회 후 미확정 주문 지급(거절했던 것 포함). 조회 실패 코드 그대로 |
| `UniTask<Result<IReadOnlyList<IapOrder>>> RestoreAsync(CancellationToken ct = default)` | 스토어 복원(App Store) → 재조회·지급 → 보유 비소모성·구독(`Origin` Restored). 구매 중이면 `InProgress` |
| `UniTask<Result<IapEntitlementStatus>> CheckEntitlementAsync(string productId, CancellationToken ct = default)` | 스토어 계정 기준 보유 상태 |
| `event Action ProductsUpdated` | 초기화 성공 때 |
| `event Action<bool> StoreUiChanged` | 결제창·복원 열림(true)/닫힘(false) |
| `event Action<PurchaseSettlement> OrderSettled` | 지급이 끝난 주문마다 한 번 |
| `event Action<IapOrderFailure> OrderFailed` | 지급 재시도 예정, 거절, 확정 실패, 종류 모르는 주문 |
| `event Action<PurchaseSettlement> PurchaseConfirmed` | 매출 지점, 거래마다 한 번. 지급 결과가 `IIapRedeemResponse` 면 이 기기가 닫았고 `Granted` 일 때(`AlreadyConfirmed` 여도), 그 밖은 스토어 `Confirmed` 일 때 |
| `void Dispose()` | `IIapService : IDisposable`. 기다리는 호출은 `Cancelled`, 열린 거래는 스토어에 남는다. 이후 호출은 `ObjectDisposedException` |

이벤트 처리기 예외는 Error 로그 후 다른 처리기와 흐름을 계속한다. 다른 스레드에서 부르면 `InvalidOperationException`.

### sealed class IapServiceOptions

| 속성 | 기본 | 설명 |
|------|------|------|
| `IReadOnlyList<IapProductDefinition> Products` | 필수 | 파는 상품(판매 중단 상품도 남김) |
| `TimeSpan ConnectTimeout` | 30초 | |
| `TimeSpan FetchTimeout` | 15초 | 상품·주문·보유 조회 |
| `TimeSpan StoreResponseTimeout` | 3분 | 결제창·복원 응답. 넘으면 `Timeout`, 늦은 결제는 뒤에서 지급 |
| `TimeSpan FulfillTimeout` | 30초 | 지급자 한 번. 넘으면 다시 시도할 주문 |
| `TimeSpan ConfirmTimeout` | 15초 | |
| `TimeSpan RetryDelay` | 5초 | 최소 `MinRetryDelay`(1초). 두 배씩, 50~100% 무작위 |
| `TimeSpan MaxRetryDelay` | 5분 | `RetryDelay` 이상 |
| `bool RecoverOnResume` | true | 포그라운드 복귀 때 재조회 |

## 상품

| 타입 | 멤버 |
|------|------|
| `enum IapProductType` | `Consumable` 1, `NonConsumable` 2, `Subscription` 3 |
| `sealed class IapProductDefinition` | `(string id, IapProductType type, string storeSpecificId = null)`, `Id`, `Type`, `StoreSpecificId`(null 이면 Id) |
| `sealed class IapProduct` | `(definition, localizedPriceString, decimal price, currencyCode, title, description, isAvailable)`, `Definition`, `Id`, `Type`, `LocalizedPriceString`, `Price`, `CurrencyCode`, `Title`, `Description`, `IsAvailable` |

## 지급 계약

| 타입 | 멤버 |
|------|------|
| `interface IPurchaseFulfiller` | `UniTask<FulfillmentResult> FulfillAsync(IapOrder order, CancellationToken ct)`. 예외는 Error 로그 후 다시 시도 |
| `enum FulfillmentStatus` | `Granted` 1, `AlreadyGranted` 2, `RetryLater` 3, `Rejected` 4 |
| `readonly struct FulfillmentResult` | `Granted(object response = null)`, `AlreadyGranted(object response = null, string message = null)`, `RetryLater(string message = null)`, `Rejected(string message = null)`, `Status`, `Message`, `Response`, `IsGranted` |

## 주문과 결과

| 타입 | 멤버 |
|------|------|
| `enum IapOrderOrigin` | `Purchase` 1(이번 실행 구매, 늦은 결제 포함), `Recovered` 2, `Restored` 3 |
| `sealed class IapOrder` | `Definition`(정의에 없으면 null), `ProductId`, `StoreProductId`, `StoreName`, `TransactionId`, `Receipt`, `SignedTransaction`, `OriginalTransactionId`, `Origin`, `Payload`, `Price`, `CurrencyCode`, `ProductTitle` |
| `sealed class PurchaseSettlement` | `Order`, `Fulfillment`, `IsConfirmed`, `IsAwaited` |
| `sealed class IapOrderFailure` | `Order`, `Code`, `Message`, `Attempts`, `WillRetry` |
| `readonly struct RecoverySummary` | `Granted`, `Retrying`, `Rejected`, `Unresolved`, `Total` |
| `enum IapEntitlementStatus` | `Unknown`, `NotEntitled`, `EntitledUntilConsumed`, `EntitledButNotFinished`, `FullyEntitled` |

## 결과 코드 `IapResultCodes`

`NotInitialized` 7001, `StoreUnavailable` 7002, `ProductNotFound` 7003, `ProductUnavailable` 7004, `UserCancelled` 7005, `Deferred` 7006, `PaymentDeclined` 7007, `DuplicateTransaction` 7008, `FulfillmentPending` 7009, `FulfillmentRejected` 7010, `StoreValidationFailed` 7011, `ExistingPurchasePending` 7012, `StoreError` 7013, `NoProducts` 7014, `UnknownProduct` 7015(이벤트만), `ConfirmFailed` 7016(이벤트만). 공용 `Cancelled` 2, `Timeout` 3, `InProgress` 5.

## 스토어 어댑터 계약

| 타입 | 멤버 |
|------|------|
| `interface IIapStore` | `Name`, `IsConnected`, 이벤트 `OrderPending(IapStoreOrder)`, `PurchaseFailed(IapStorePurchaseFailure)`, `PurchaseDeferred(string productId)`, `Disconnected(string)`, `ConnectAsync(ct)` → `Result`, `FetchProductsAsync(definitions, ct)` → `Result<IReadOnlyList<IapProduct>>`(일부만 받으면 받은 것), `FetchOrdersAsync(ct)` → `Result<IapStoreOrders>`(실패를 빈 목록으로 돌려주지 않음), `Purchase(IapProductDefinition)`(결과는 이벤트, 호출 안에서 올려도 됨), `ConfirmAsync(IapStoreOrder, ct)` → `IapConfirmResult`(시간 초과 뒤 같은 거래로 다시 불리면 앞 요청의 닫힌 결과를 돌려줌), `RestoreAsync(ct)` → `Result`, `CheckEntitlementAsync(definition, ct)` → `Result<IapEntitlementStatus>` |
| `sealed class IapStoreOrder` | `(productId, transactionId, receipt, isKnownProduct, native, signedTransaction = null, originalTransactionId = null)`. 빈 거래 ID 는 `ArgumentException`. `IsKnownProduct` false 면 지급·확정하지 않음. `Native` 는 확정에 돌려줌 |
| `sealed class IapStoreOrders` | `(pending, owned, deferredCount)`, `Pending`, `Owned`, `DeferredCount` |
| `readonly struct IapStorePurchaseFailure` | `(productId, reason, message)` |
| `enum IapStoreFailureReason` | `Unknown`, `StoreUnavailable`, `ExistingPurchasePending`, `ProductUnavailable`, `ValidationFailed`, `UserCancelled`, `PaymentDeclined`, `DuplicateTransaction` |
| `readonly struct IapConfirmResult` | `Confirmed()`, `AlreadyConfirmed(message)`, `Failed(reason, message)`, `Status`(`IapConfirmStatus`: `Confirmed`, `AlreadyConfirmed`, `Failed`), `Reason`, `Message`. `default` 는 실패 |

## Unity IAP 어댑터 (`Geuneda.Iap.Unity`)

| 멤버 | 설명 |
|------|------|
| `UnityIapStore()` | `UnityIAPServices.StoreController()` 와 기본 스토어 이름 |
| `UnityIapStore(StoreController controller, string storeName)` | |
| `void Dispose()` | 구독 해제, 기다리는 요청 취소. 컨트롤러는 그대로 |

자동 재전달 끄기, 상품 조회 `NoRetriesPolicy`, 닫힌 확정 결과 기억(`ConfirmTracker`), 실패 이유 멤버별 대응, `jwsRepresentation` → `SignedTransaction`, 확정 `DuplicateTransaction` → `AlreadyConfirmed`, Apple 플랫폼만 `RestoreTransactions`.

## 매출 기록 (`Geuneda.Iap.Analytics`, analytics 0.2.0 이상)

| 멤버 | 설명 |
|------|------|
| `IapRevenueLogger(IIapService iap, IAnalyticsService analytics, AnalyticsSinks? sinks = null, Func<PurchaseSettlement, IapPaidAmount?> paidAmount = null)` | `PurchaseConfirmed` 마다 `LogPurchase(new AnalyticsPurchase(ProductId, 총액 ÷ 수량, 통화, 수량, TransactionId, ProductTitle))`. 수량은 결제 서버 응답이면 서버가 확인한 수량, 그 밖은 1. null 이면 Info 후 기록 안 함, 음수·통화 코드 없음은 Warning |
| `static IapPaidAmount? DefaultPaidAmount(PurchaseSettlement)` | 총액. 지급 결과가 `IIapRedeemResponse` 면 테스트 결제·`Revoked` 는 null, 서버 총액이 있으면 그것. 그 밖은 구독 null(무료 체험·할인), `IapOrder.Price` × 서버 수량과 `CurrencyCode`(없으면 null). 이벤트 단가 = 총액 ÷ 서버 수량 |
| `readonly struct IapPaidAmount` | `(decimal amount, string currencyCode)`, `Amount`, `CurrencyCode`. 서버가 확인한 거래 통화를 쓴다 |
| `void Dispose()` | 구독 해제 |

## 결제 서버 와이어 형식 (`Runtime/Protocol`, 서버와 공유)

| 타입 | 멤버 |
|------|------|
| `sealed class IapRedeemRequest` | `Store`, `ProductId`, `TransactionId`, `Receipt`, `SignedTransaction`, `Payload` |
| `sealed class IapRedeemResponse<TGrant> : IIapRedeemResponse` | `Status`, `Code`, `Message`, `Grant`(Granted·Duplicate 에만), `ProductId`, `TransactionId`, `Quantity`, `IsTest`, `PaidAmount`(decimal?), `PaidCurrency`, `ExpiresAt`(구독) |
| `interface IIapRedeemResponse` | 형식 인자 없이 `Status`, `Code`, `ProductId`, `TransactionId`, `Quantity`, `IsTest`, `PaidAmount`(수량 포함 총액), `PaidCurrency` |
| `enum IapRedeemStatus` | `Granted` 1, `AlreadyGranted` 2, `RetryLater` 3, `Rejected` 4(`FulfillmentStatus` 와 같은 값) |
| `static class IapRedeemCodes` | `None` 0, `Duplicate` 7101, `OwnedByOtherAccount` 7102, `Revoked` 7103, `InvalidReceipt` 7104, `AppMismatch` 7105, `ProductMismatch` 7106, `UnsupportedStore` 7107, `EnvironmentNotAllowed` 7108, `PaymentPending` 7109, `StoreUnavailable` 7110, `GrantRejected` 7111, `GrantDeferred` 7112, `BadRequest` 7113, `Unauthorized` 7114 |
| `static class IapStoreNames` | `GooglePlay`, `AppleAppStore`, `MacAppStore`, `Fake`("fake") |
| `static class IapRoutes` | `Purchases` = "purchases" |
| `static class IapRedeemResults` | `ToRedeemRequest(this IapOrder)`, `ToFulfillmentResult<TGrant>(this IapRedeemResponse<TGrant>)`(null·모르는 상태는 `RetryLater`, Response 는 응답 자체) |

## HTTP 지급자 (`Geuneda.Iap.Http`, http 0.1.0 이상)

| 멤버 | 설명 |
|------|------|
| `HttpPurchaseFulfiller<TGrant>(IHttpClient http, string route = IapRoutes.Purchases)` | `POST {기본 주소}purchases`. 기본 주소는 서버 접두사까지(`.../iap/`). 인증은 http 미들웨어(account `AuthTokenMiddleware`). 연결 실패·시간 초과·5xx·본문 오류·모르는 상태는 `RetryLater`, 401 은 `RetryLater`, 400 은 `Rejected` |

## 결제 서버 (`Server~`, `Geuneda.Iap.Server`, .NET 10)

| 멤버 | 설명 |
|------|------|
| `services.AddGeunedaIap(Action<IapServerOptions>)` → `IapServerBuilder` | 옵션: `Products`(`IapServerProduct(id, type, googlePlayId = null, appStoreId = null)`, 게임·스토어 ID 겹침 금지), `AllowTestPurchases` true, `MaxRequestBytes` 1MB, `AcknowledgementRetryInterval` 5분 |
| `IapServerBuilder.AddGooglePlay(Action<GooglePlayOptions>)` | `PackageName`(필수), `ServiceAccountKeyJson`·`ServiceAccountKeyFile`(없으면 ADC), `AcknowledgeAfterGrant` true, `ReadOrderTotal` false, `RequestTimeout` 10초. 확인 작업자(호스트 서비스)도 등록. 토큰은 `IGooglePlayAccessTokenSource` 로 바꿀 수 있음 |
| `AddAppStore(Action<AppStoreOptions>)` | `BundleId`(필수), `AllowSandbox` true, `OnlineChecks` true, `RootCertificates`(비면 내장 `AppleRootCertificates.AppleRootCaG3`) |
| `AddFakeStore()` | 가짜 스토어 주문을 검증 없이(Production 이면 시작 실패) |
| `AddVerifier<T>()` | `IStoreVerifier`: `Stores`, `LedgerStore`, `VerifyAsync(request, product, ct)` → `StoreVerification`(`Verified`, `Invalid`, `AppMismatch`, `ProductMismatch`, `EnvironmentNotAllowed`, `Revoked`, `Pending`, `Unavailable`), `AcknowledgeAsync(record, product, ct)` → bool(끝났으면 true) |
| `AddGrantor<T>(lifetime = Scoped)` | `IPurchaseGrantor.GrantAsync(PurchaseGrant{AccountId, Product, Purchase, Payload, Quantity(지급할 수량)}, ct)` → `GrantResult.Granted(response)`·`Rejected(msg)`·`RetryLater(msg)`. 원장 트랜잭션 안에서 불림 |
| `AddLedger<T>(lifetime = Scoped)`, `AddInMemoryLedger()` | `IPurchaseLedger`: `FindAsync(store, txId)`, `RedeemAsync(record, grant, ct)` → `LedgerRedeemResult`(`Recorded`, `Duplicate`, `NotGranted`), `FindDueAcknowledgementsAsync(now, limit)`, `MarkAcknowledgedAsync(store, txId)`, `DeferAcknowledgementAsync(store, txId, dueAt)`, `UpdateRefundAsync(RefundChange{Store, TransactionId, RefundedQuantity, ChangedAt, Mode(EventOrdered·NeverDecrease), ProductId, StoreProductId, Quantity}, apply)` → `LedgerRefundResult`(`Changed`, `Unchanged`, `Stale`, `RecordedBeforeGrant`), `FindByOriginalTransactionAsync(store, originalTxId)`(지급 기록만), `UpdateSubscriptionAsync(store, subscriptionId, next(stored), deliver)` → `Delivered`·`Stale`·`Skipped`. `RedeemAsync` 의 grant 콜백 인자는 지급 전 환불 기록(없으면 null) |
| `endpoints.MapGeunedaIap(prefix, Func<HttpContext, Task<string>> resolveAccountId)` → `RouteHandlerBuilder` | `POST {prefix}/purchases`. null 계정 401, JSON 아님 415, 초과 413, 형식 오류 400, 그 밖 200(+본문 status), 지급자·원장 예외 500. 설정 오류는 여기서 예외 |
| `IPurchaseRedeemer.RedeemAsync(accountId, request, ct)` → `IapRedeemResponse<object>` | 요청 범위. RPC 등에서 직접 호출 |
| `AddNotificationHandler<T>(lifetime = Scoped)` | `IPurchaseNotificationHandler`: `OnRefundedAsync(PurchaseRefund)`, `OnRefundReversedAsync(PurchaseRefund)`(원장 트랜잭션 안), `OnSubscriptionChangedAsync(SubscriptionUpdate)` |
| `MapGeunedaIapGooglePlayNotifications(prefix)` | `POST {prefix}/notifications/google-play`. `GooglePlayOptions.NotificationAudience`·`NotificationServiceAccountEmail` 필수(Pub/Sub 푸시 OIDC) |
| `MapGeunedaIapAppStoreNotifications(prefix)` | `POST {prefix}/notifications/app-store`(V2). `AppStoreOptions.AppAppleId` 를 넣으면 운영 알림의 앱 ID 확인 |
| `PurchaseRefund` | `Record`(바뀌기 전), `AccountId`, `Product`, `Quantity`(이번 회수·복구 수), `RefundedQuantity`(누적), `IsFullRefund`, `Reason`, `ObservedAt` |
| `SubscriptionUpdate` | `Store`, `SubscriptionId`(Google 구매 토큰, App Store 원래 거래 ID), `LinkedSubscriptionId`, `StoreProductId`, `Product`, `AccountId`(원장, 없으면 null — 다시 오지 않으니 구독 ID 로 저장해 지급자가 연결), `State`, `ExpiresAt`, `GracePeriodExpiresAt`, `AutoRenewing`, `IsTest`, `NotificationType`, `ObservedAt`, `LatestTransactionId` |
| `VerifiedPurchase` | `Store`(원장 스토어), `TransactionId`, `StoreProductId`, `ProductType`, `OrderId`, `OriginalTransactionId`, `Quantity`, `PurchasedAt`, `ExpiresAt`, `SubscriptionState`(`IapSubscriptionState`: `Active`, `Canceled`, `GracePeriod`, `OnHold`, `Paused`, `Expired`), `IsTest`, `AccountToken`, `PaidAmount`, `PaidCurrency`, `RequiresAcknowledgement`, `SubscriptionId`(구독만), `ObservedAt`(Google 조회 시각, App Store 서명 시각), `AutoRenewing`(Google) |
| `PurchaseRecord`(record) | `Store`, `TransactionId`, `AccountId`, `ProductId`, `StoreProductId`, `OrderId`, `OriginalTransactionId`, `Quantity`, `IsTest`, `PurchasedAt`, `RedeemedAt`, `PaidAmount`, `PaidCurrency`, `ExpiresAt`, `GrantResponse`(JSON), `AcknowledgementDueAt`(확인 대기면 다음 시도 시각), `RefundedQuantity`, `RefundedAt`, `IsFullyRefunded`, `IsGranted`(false 면 지급 전 환불 기록, `AccountId` null) |

## 테스트 어셈블리

`Geuneda.Iap.Tests.EditMode`, `Geuneda.Iap.Analytics.Tests.EditMode`, `Geuneda.Iap.Http.Tests.EditMode`(http 있을 때, `SampleServerInteropTest` 는 명시 실행 + `GEUNEDA_IAP_INTEROP_URL`), `Geuneda.Iap.Unity.Tests.EditMode`, `Geuneda.Iap.Unity.Tests.PlayMode`(define `IAP_FAKE_STORE_DEFAULT` 필요). 서버는 `dotnet test "Server~/Geuneda.Iap.Server.slnx"`.
