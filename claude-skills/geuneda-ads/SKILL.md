---
name: geuneda-ads
description: com.geuneda.ads 패키지(네임스페이스 Geuneda.Ads, 선택 어셈블리 Geuneda.Ads.Analytics)와 AppLovin MAX 어댑터 패키지 com.geuneda.ads.max(Geuneda.Ads.Max)로 광고 코드를 작성하거나 수정할 때 사용하는 스킬. IAdService·AdService·AdServiceOptions 로 보상형(ShowRewardedAsync)·전면(ShowInterstitialAsync) 광고를 표시하거나, AdsResultCodes(8000 블록, NotRewarded·NotReady·DisplayFailed)와 Timeout·InProgress 결과로 보상 지급·안내를 고르거나, 시간 초과 뒤 늦게 온 보상(LateRewarded, AdLateReward)을 지급하거나, ShowingChanged 로 광고 동안 실시간 핑을 멈추거나, ShowSettled(AdShowReport)·Clicked·LoadFailed 로 광고 분석 이벤트를 남기거나, RevenuePaid(AdRevenue)·AdRevenueLogger 로 노출 수익을 analytics 광고 노출 이벤트로 기록하거나, MaxAdMediation·MaxAdMediationOptions 로 MAX 보상형·전면 단위를 붙이거나, IAdMediation 으로 다른 미디에이션(LevelPlay, AdMob 등) 어댑터를 만들거나, 광고 Hidden 콜백 누락으로 다음 광고가 막히는 문제·보상 미지급·늦은 콜백 섞임을 다룰 때 활성화한다.
---

# Geuneda Ads

보상형·전면 광고다. 표시 요청마다 결과를 한 번만 정하고, 미디에이션 SDK 가 닫힘 콜백을 주지 않아도 시간 초과로 끝내 다음 광고가 막히지 않게 한다. 시간 초과 뒤 늦게 온 보상은 이벤트로 넘겨 게임이 지급을 정하고, 앞 광고의 늦은 콜백을 광고 식별 값으로 걸러 다음 광고에 섞이지 않게 한다.

## 패키지 정보

- **버전**: ads 0.1.0, ads.max 0.1.0
- **네임스페이스 / 어셈블리**: `Geuneda.Ads`. 선택 어셈블리 `Geuneda.Ads.Analytics`(analytics 0.2.0 이상, `versionDefines` 로 켜짐). 어댑터 `Geuneda.Ads.Max`(MAX `com.applovin.mediation.ads` 8.6.3 이상이 있을 때만 컴파일, Assets 설치는 define `GEUNEDA_ADS_MAX`)
- **설치**: `https://github.com/geuneda/geuneda-ads.git`, `https://github.com/geuneda/geuneda-ads-max.git` (core, UniTask git URL 도 함께). MAX 는 게임이 AppLovin 레지스트리(Integration Manager)로 설치한다(의존성 아님)
- **의존성**: ads 는 `com.geuneda.core` 0.4.0, `com.cysharp.unitask` 2.5.10(Unity 2021.3+). ads.max 는 `com.geuneda.ads` 0.1.0
- **기여 가이드**: 각 패키지 루트의 `AGENTS.md`
- **출처**: Lucky Defense Percent `PercentAds`·`PercentAdsMax`(재로드 2초→30초 백오프, show 단위 구독과 1회 실행, 보상은 Hidden 에서 확정)와 SpellDefense `AppLovinAdService`(세션당 한 번 확정, 닫힘 뒤 2초 보상 대기, Android 복귀 뒤 20초, 절대 300초)를 뼈대로 했다(로드맵 4-3). Percent 는 타임아웃이 없어 Hidden 이 오지 않으면 그 실행 동안 보상형이 막힌다. SpellDefense 의 약점(iOS 300초 상한이 표시 중 광고를 끊어 보상 유실, 강제 종료 뒤 늦은 콜백 전부 버림, bool 결과, placement 로만 구분, 준비 안 됨 때 백오프 건너뜀, iOS 표시 실패 무응답이면 5분 대기)을 고쳤다

## 핵심 API

전체 시그니처는 `references/api.md`.

- `new AdService(IAdMediation mediation, AdServiceOptions options = null)` → `IAdService`(`IDisposable`). 메인 스레드에서만. 미디에이션 어댑터는 게임이 따로 정리한다.
- `ShowRewardedAsync(placement = null)` → `Result`: 성공 = 보상 조건 충족. `ShowInterstitialAsync(placement = null)` → `Result`: 성공 = 닫힘. 결과는 반드시 온다.
- 실패 코드: `AdsResultCodes.NotRewarded` 8005(보상 전에 닫음), `NotReady` 8002, `NotInitialized` 8001, `Unavailable` 8003(그 플랫폼에 단위 없음), `DisplayFailed` 8004, `ResultCodes.InProgress`(다른 광고 표시 중), `ResultCodes.Timeout`(닫힘 콜백 없음), `ResultCodes.Cancelled`(표시 중 `Dispose`).
- `IsInitialized`, `IsShowing`, `IsReady(AdFormat)`.
- 이벤트: `ShowingChanged(bool)`, `Displayed(AdShowEvent)`, `Clicked(AdShowEvent)`(표시마다 한 번), `ShowSettled(AdShowReport)`(거절 포함 요청마다 한 번, `Reason`: Rejected·Closed·DisplayFailed·DisplayTimeout·ForegroundTimeout·AbsoluteTimeout·Disposed), `LateRewarded(AdLateReward)`, `RevenuePaid(AdRevenue)`(`Amount` 모르면 null, `Currency`, `Platform`), `LoadFailed(AdLoadFailure)`.
- `AdServiceOptions`: `RetryDelay` 2초(최소 100ms), `MaxRetryDelay` 30초, `LoadTimeout` 60초, `ForegroundGrace` 20초, `AbsoluteTimeout` 5분, `RewardGrace` 2초(0 이면 닫힘에서 바로 실패), `AdPausesApp` null(미디에이션의 `PausesApp`, MAX 는 Android·iOS 기기에서 true).
- MAX: `new MaxAdMediation(new MaxAdMediationOptions { RewardedAdUnitId, InterstitialAdUnitId })`(`IDisposable`). 플랫폼별 ID 는 게임이 `#if UNITY_IOS` 로 고른다. `PlatformName` "AppLovin", `RevenueCurrency` "USD".
- `new AdRevenueLogger(IAdService ads, IAnalyticsService analytics, AnalyticsSinks? sinks = null)`: 노출 수익 → `LogAdImpression`(형식 `rewarded`/`interstitial`, 모르는 금액·잘못된 통화는 건너뜀).

## 사용 패턴

```csharp
using Geuneda.Ads;
using Geuneda.Ads.Analytics;
using Geuneda.Ads.Max;
using Geuneda.Core;
using Geuneda.Services;

// 부트스트랩: 게임이 동의·개인정보·뮤트 뒤 SDK 를 초기화한다
MaxSdk.SetHasUserConsent(consent);
MaxSdk.SetMuted(muted);
MaxSdk.InitializeSdk();

var mediation = new MaxAdMediation(new MaxAdMediationOptions
{
#if UNITY_IOS
    RewardedAdUnitId = IosRewardedUnit, InterstitialAdUnitId = IosInterstitialUnit
#else
    RewardedAdUnitId = AndroidRewardedUnit, InterstitialAdUnitId = AndroidInterstitialUnit
#endif
});
var ads = new AdService(mediation);                    // 초기화가 끝나면 서비스가 광고를 불러온다
var revenueLogger = new AdRevenueLogger(ads, analytics);
ads.LateRewarded += OnLateRewarded;
ads.ShowingChanged += showing => realtime.SetPingPaused(showing);
MainInstaller.Bind<IAdService>(ads);

// 보상형
var result = await MainInstaller.Resolve<IAdService>().ShowRewardedAsync("revive");
if (result.IsSuccess) GrantRevive();
else if (result.Code == AdsResultCodes.NotReady) Toast("광고를 불러오는 중입니다");
else if (result.Code == ResultCodes.Timeout) Toast("광고 결과를 확인하지 못했습니다"); // 늦게 보상이 오면 LateRewarded

// 늦은 보상: 호출자는 이미 실패를 받았다. 위치마다 지금 줄 수 있는지 게임이 정한다
void OnLateRewarded(AdLateReward reward)
{
    if (reward.Placement == "stamina") GrantStamina();
}

// 종료: revenueLogger.Dispose(); MainInstaller.CleanDispose<IAdService>(); mediation.Dispose();
```

## 규칙

- **결과 한 번**: 표시는 닫힘, 표시 실패, 시간 초과, `Dispose` 중 하나로 한 번 끝난다. 보상형은 보상 콜백을 받았으면 어느 경로로 끝나도 성공이다.
- **보상과 닫힘 순서**: SDK 는 순서를 보장하지 않는다. 보상 전에 닫히면 `RewardGrace`(2초) 동안 보상을 기다린다(앱이 앞에 있는 시간만). 그 뒤 온 보상은 `LateRewarded`.
- **시간 초과**: 앱이 앞에 온 지 `ForegroundGrace`(20초)가 지나야 판정한다(Android 복귀 직후 SDK 큐의 콜백보다 먼저 끝내지 않음). 표시 콜백 없음은 모든 플랫폼 `DisplayTimeout`, 광고가 앱을 멈추는 미디에이션(MAX 는 Android 광고 액티비티와 iOS `UnityPause`)에서 복귀 뒤 닫힘 없음 `ForegroundTimeout`, 표시 요청부터 5분 `AbsoluteTimeout`. 1초 넘게 프레임이 돌지 않았으면(메시지 없는 UnityPause) 복귀 뒤 닫힘 대기를 그때부터 세고, 그 뒤 1초 안에 생긴 시간 초과·보상 없음은 조건이 1초·2프레임 더 이어질 때만 확정한다(늦게 들어오는 SDK 콜백 대비, 확인 시작은 다시 잡지 않아 느린 프레임에도 끝남). 광고 중에도 앱이 도는 미디에이션은 표시된 광고를 절대 상한으로만 끝낸다.
- **늦은 콜백**: 결과를 정한 최근 표시 4개가 남아 늦은 콜백을 받는다. 식별 값이 지금 광고와 다르고 그중 하나와 같으면 그 표시로, 모르거나 맞지 않으면 지금 표시로 간다. 표시된 지금 광고에 온 표시 실패는 무시한다.
- **로드**: 초기화 뒤 단위가 있는 형식을 모두 불러오고, 광고를 쓴 뒤(닫힘·표시 실패·시간 초과) 다시 불러온다. 실패는 2초부터 두 배씩 30초까지 대기, 대기 중 표시 요청은 `NotReady` 이고 대기를 건너뛰지 않는다.
- **전체 화면은 한 번에 하나**: 보상형 표시 중 전면 요청도 `InProgress`.
- **매출은 `RevenuePaid` 한 곳**: `AdRevenueLogger` 를 쓰면 결과 처리 코드에서 따로 `LogAdImpression` 하지 않는다.
- **재진입 안전**: `ShowSettled`·`ShowingChanged` 처리기나 호출자의 이어지는 코드에서 바로 다음 광고를 요청하거나 정리해도 된다. 처리기 안에서 생긴 알림은 지금 알림이 모든 구독자에게 간 뒤 순서대로 나간다. 처리기 예외는 Error 로그 뒤 계속된다.
- **오용은 예외**: 다른 스레드 호출, `Dispose` 뒤 호출, 알 수 없는 `AdFormat`, 범위 밖 설정, MAX 두 형식에 같은 단위 ID.

## 함정

- SDK 초기화는 어댑터가 하지 않는다. `MaxSdk.InitializeSdk()` 를 부르지 않으면 표시 요청은 계속 `NotInitialized` 다. 동의(UMP·ATT)는 초기화 전에 게임이 처리한다.
- `Timeout` 결과에 "보상 없음"을 단정해 띄우지 않는다. 사용자가 끝까지 봤을 수 있고 늦은 보상은 `LateRewarded` 로 온다. `LateRewarded` 를 구독하지 않으면 그 보상은 지급되지 않는다.
- `LateRewarded` 는 서비스가 살아 있는 동안만 온다. 앱을 다시 시작하면 이전 실행의 광고 콜백은 오지 않는다.
- 배치 모드·포커스 없는 에디터에서는 앱이 앞에 있지 않다고 봐 보상 대기와 시간 초과가 흐르지 않는다(실기에는 해당 없음). 테스트는 `RewardGrace = 0` 이나 내부 `HandleFocus` 를 쓴다.
- MAX 를 `Assets` 에 `.unitypackage` 로 설치했으면 `GEUNEDA_ADS_MAX` define 을 넣지 않는 한 `Geuneda.Ads.Max` 가 컴파일되지 않는다(UPM 설치만 자동 감지).
- MAX 에디터 스텁은 로드 지연·광고 소재가 없어 식별 값이 null 이고 앱도 멈추지 않는다(`PausesApp` false). 늦은 콜백 거르기와 iOS `UnityPause` 경로는 실기의 값으로만 동작한다(실기 미검증).
- 재시도를 시작한 뒤 온 앞 로드 요청의 실패는 지금 요청의 실패로 센다(SDK 가 요청을 구분해 주지 않음).
- MAX 콜백은 `keepInBackground` 이벤트를 다른 스레드에서 부른다. `MaxSdkCallbacks` 를 직접 구독해 Unity API 를 부르는 게임 코드는 메인 스레드로 넘겨야 한다(서비스·어댑터 경로는 넘김).
- 전면 광고 빈도 제한(쿨다운)과 광고 제거 상품 확인은 게임이 한다.
