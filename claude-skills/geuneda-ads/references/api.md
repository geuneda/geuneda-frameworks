# Geuneda Ads API 레퍼런스

네임스페이스 `Geuneda.Ads`(선택 어셈블리 `Geuneda.Ads.Analytics`, 어댑터 `Geuneda.Ads.Max`). ads 0.1.0, ads.max 0.1.0.

## 서비스

### interface IAdService : IDisposable / sealed class AdService : IAdService

| 멤버 | 설명 |
|------|------|
| `AdService(IAdMediation mediation, AdServiceOptions options = null)` | 메인 스레드에서 만든다. null 미디에이션은 `ArgumentNullException`, 범위 밖 시간은 `ArgumentOutOfRangeException`. 플레이 중이면 숨은 수명 오브젝트(매 프레임 판정, 일시정지·포커스)를 만든다. 미디에이션이 이미 초기화돼 있으면 바로 불러온다 |
| `bool IsInitialized` | 미디에이션 초기화가 끝났는지 |
| `bool IsShowing` | 전체 화면 광고 표시 중(결과 전) |
| `bool IsReady(AdFormat format)` | 초기화됐고 단위가 있고 SDK 에 광고가 있는지. 알 수 없는 형식은 `ArgumentOutOfRangeException` |
| `UniTask<Result> ShowRewardedAsync(string placement = null)` | 성공 = 보상 받음. 실패 코드는 아래 표 |
| `UniTask<Result> ShowInterstitialAsync(string placement = null)` | 성공 = 닫힘 |
| `event Action<bool> ShowingChanged` | 열림(true) / 결과(false) |
| `event Action<AdShowEvent> Displayed` | 표시 콜백(결과를 정한 표시의 늦은 콜백도, `IsSettled`) |
| `event Action<AdShowEvent> Clicked` | 표시마다 한 번 |
| `event Action<AdShowReport> ShowSettled` | 요청마다 한 번(거절 포함), 호출자 완료 직전 |
| `event Action<AdLateReward> LateRewarded` | 실패로 정한 보상형 표시의 늦은 보상, 표시마다 많아야 한 번 |
| `event Action<AdRevenue> RevenuePaid` | 노출 수익 |
| `event Action<AdLoadFailure> LoadFailed` | 로드 실패·시간 초과와 재시도 대기 |
| `void Dispose()` | 표시 중이면 보상을 받았으면 성공, 아니면 `Cancelled`. 미디에이션 구독 해제. 두 번 불러도 됨 |

### sealed class AdServiceOptions

| 속성 | 기본값 | 범위 |
|------|--------|------|
| `RetryDelay` | 2초 | `MinRetryDelay`(100ms) ~ 하루 |
| `MaxRetryDelay` | 30초 | `RetryDelay` ~ 하루 |
| `LoadTimeout` | 60초 | `MinLoadTimeout`(1초) 이상 |
| `ForegroundGrace` | 20초 | 0 보다 큼 |
| `AbsoluteTimeout` | 5분 | `ForegroundGrace` 이상 |
| `RewardGrace` | 2초 | 0 이상 |
| `AdPausesApp` | null(미디에이션의 `PausesApp`) | |

## 결과 코드

| 코드 | 상수 | 뜻 |
|------|------|----|
| 2 | `ResultCodes.Cancelled` | 표시 중 `Dispose` |
| 3 | `ResultCodes.Timeout` | 닫힘 콜백 없음 |
| 5 | `ResultCodes.InProgress` | 다른 전체 화면 광고 표시 중 |
| 8001 | `AdsResultCodes.NotInitialized` | SDK 초기화 전 |
| 8002 | `AdsResultCodes.NotReady` | 불러온 광고 없음 |
| 8003 | `AdsResultCodes.Unavailable` | 그 플랫폼에 단위 없음 |
| 8004 | `AdsResultCodes.DisplayFailed` | SDK 표시 실패 |
| 8005 | `AdsResultCodes.NotRewarded` | 보상 전에 닫음 |

## 데이터

| 타입 | 멤버 |
|------|------|
| `enum AdFormat` | `Rewarded` 1, `Interstitial` 2 |
| `enum AdSettleReason` | `Rejected` 1, `Closed` 2, `DisplayFailed` 3, `DisplayTimeout` 4, `ForegroundTimeout` 5, `AbsoluteTimeout` 6, `Disposed` 7 |
| `sealed class AdDetails` | `AdDetails(unitId, networkName, networkPlacement, creativeId, identity)`, `UnitId`, `NetworkName`, `NetworkPlacement`, `CreativeId`, `Identity`(불러온 광고 하나, 모르면 null), `static Unknown`. 빈 문자열은 null |
| `readonly struct AdError` | `AdError(int code, string message)`, `Code`(SDK 값), `Message` |
| `readonly struct AdPaid` | `AdPaid(double? amount, string currency, string precision)` |
| `sealed class AdShowReport` | `ShowId`(1부터, 거절은 0), `Format`, `Placement`, `Result`, `Reason`, `Displayed`, `Elapsed`, `Ad`, `Error` |
| `sealed class AdShowEvent` | `ShowId`, `Format`, `Placement`, `Ad`, `IsSettled` |
| `sealed class AdLateReward` | `ShowId`, `Placement`, `Ad`, `SettledResult` |
| `sealed class AdRevenue` | `ShowId`(모르면 0), `Format`, `Placement`, `Platform`, `Ad`, `Amount`(null 이면 모름, 음수·NaN 도 null), `Currency`, `Precision` |
| `sealed class AdLoadFailure` | `Format`, `Error`(시간 초과면 null), `TimedOut`, `Attempt`(1부터), `RetryDelay` |

## 미디에이션 어댑터 계약 `IAdMediation`

| 멤버 | 설명 |
|------|------|
| `string Platform` | 분석의 광고 플랫폼(예: AppLovin). 비면 수익 기록이 실패 |
| `bool IsInitialized` / `event Action Initialized` | SDK 초기화(게임이 함) |
| `bool PausesApp` | 표시 중 앱(플레이어 루프)이 멈추는지. true 면 복귀 뒤 `ForegroundGrace` 동안 닫힘이 없을 때 `ForegroundTimeout` |
| `bool IsAvailable(AdFormat)` | 그 플랫폼에 단위가 있는지 |
| `bool IsReady(AdFormat)` | 불러온 광고가 있는지 |
| `void Load(AdFormat)` | 결과는 `Loaded`/`LoadFailed` |
| `void Show(AdFormat, string placement)` | 결과는 `Displayed` → (`Rewarded`) → `Hidden`, 또는 `DisplayFailed`. 호출 안에서 올려도 됨 |
| `event Action<AdFormat, AdDetails> Loaded` | 만료 광고를 SDK 가 다시 불러온 경우도 새 정보로 |
| `event Action<AdFormat, AdError> LoadFailed` | |
| `event Action<AdFormat, AdDetails> Displayed`, `Rewarded`, `Clicked`, `Hidden` | |
| `event Action<AdFormat, AdError, AdDetails> DisplayFailed` | |
| `event Action<AdFormat, AdDetails, AdPaid> RevenuePaid` | |

이벤트는 어느 스레드에서 올려도 된다(서비스가 `MainThreadDispatcher` 로 넘김). `AdDetails.Identity` 는 로드와 그 광고의 콜백에서 같아야 하고(SDK 가 콜백마다 다르게 주면 어댑터가 로드 때 값으로 되살림) 보장할 수 없으면 null.

서비스는 결과를 정한 최근 표시 `AdService.RetainedSettledShows`(4)개를 늦은 콜백용으로 들고, `Tick` 사이가 `AdService.FrameGap`(1초) 이상이면 앱을 멈추는 미디에이션의 복귀 뒤 닫힘 대기를 그때부터 세고, 그 뒤 `AdService.ResumeSettle`(1초) 안에 생긴 시간 기준 확정은 조건이 1초와 `ResumeSettleFrames`(2) 프레임 더 이어질 때만 한다. SDK 표시 호출도 열림 알림 뒤에 큐로 실행한다.

## MAX 어댑터 (`Geuneda.Ads.Max`, MAX 8.6.3 이상)

| 멤버 | 설명 |
|------|------|
| `MaxAdMediation(MaxAdMediationOptions options)` | null 은 `ArgumentNullException`, 두 형식 같은 단위 ID 는 `ArgumentException`. MAX 콜백 18개 구독 |
| `MaxAdMediationOptions.RewardedAdUnitId`, `InterstitialAdUnitId` | 실행 중인 플랫폼의 ID. 비우면 그 형식 `Unavailable` |
| `const string PlatformName = "AppLovin"`, `const string RevenueCurrency = "USD"` | |
| `void Dispose()` | MAX 콜백 해제. 뒤의 `Load`·`Show` 는 `ObjectDisposedException` |

- 단위가 설정한 것과 같은 콜백만 넘긴다. `OnExpiredAdReloadedEvent` → `Loaded`(새 광고).
- 식별 값 `"{NetworkName}|{NetworkPlacement}|{CreativeIdentifier}|{LatencyMillis}"`, 로드 지연·광고 소재가 모두 없으면 null. 표시 실패는 최근 로드 8개 중 지연을 뺀 정보가 같은 가장 최근 것의 식별 값(MAX iOS 가 표시 실패의 지연을 오류 지연으로 바꿈), 없으면 null.
- `PausesApp`: Android·iOS 기기에서 true(Android 광고 액티비티, iOS 플러그인의 `UnityPause`), 에디터·그 밖 false.
- `AdInfo.Revenue` -1 → `AdPaid.Amount` null, 정확도는 `RevenuePrecision`.
- 오류는 `(int) ErrorInfo.Code`, `ErrorInfo.Message`.

## 노출 수익 기록 (`Geuneda.Ads.Analytics`, analytics 0.2.0 이상)

| 멤버 | 설명 |
|------|------|
| `AdRevenueLogger(IAdService ads, IAnalyticsService analytics, AnalyticsSinks? sinks = null)` | `RevenuePaid` 구독. null 은 `ArgumentNullException` |
| `static string FormatName(AdFormat)` | `rewarded`, `interstitial` |
| `void Dispose()` | 구독 해제 |

`AnalyticsAdImpression(platform, networkName, FormatName(format), unitId, amount, currency, placement)` 로 `LogAdImpression`. 금액을 모르면 건너뛰고(Debug), 통화가 영문 3자가 아니면 건너뛴다(Warning).

## 테스트 어셈블리

- `Geuneda.Ads.Tests.EditMode`(가짜 미디에이션·시계), `Geuneda.Ads.Analytics.Tests.EditMode`(analytics 가 있을 때), `Geuneda.Ads.Tests.PlayMode`(수명 오브젝트, 다른 스레드 콜백).
- `Geuneda.Ads.Max.Tests.EditMode`(`MaxSdkCallbacks.ForwardEvent` JSON 주입), `Geuneda.Ads.Max.Tests.PlayMode`(MAX 에디터 스텁 전 과정). MAX 가 있을 때만 컴파일.
