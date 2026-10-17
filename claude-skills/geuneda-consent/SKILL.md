---
name: geuneda-consent
description: com.geuneda.consent 패키지(네임스페이스 Geuneda.Consent)와 어댑터 패키지 com.geuneda.consent.ump(Geuneda.Consent.Ump, Google UMP)·com.geuneda.consent.att(Geuneda.Consent.Att, iOS ATT)로 앱 시작 동의 코드를 작성하거나 수정할 때 사용하는 스킬. IConsentService·ConsentService·ConsentServiceOptions 로 자사 약관 → 광고 동의(UMP) → 추적 허용(ATT) 순서를 실행하거나(RunAsync), ConsentSnapshot(AdConsentState 의 CanRequestAds·PersonalizedAds·PrivacyOptionsRequired·TCF 값, TrackingStatus·TrackingAllowed, 약관 답)으로 MAX·AppsFlyer·Firebase 등 SDK 에 동의 값을 넘기고 초기화하거나, ConsentResultCodes(9000 블록, TermsDeclined·AdConsentUpdateFailed·AdConsentFormFailed·TermsSaveFailed)와 Cancelled·InProgress·NetworkError·Timeout 결과를 처리하거나, TermsConsent·TermsItem(항목별 버전, 필수·선택)·ITermsPrompt(게임 동의 화면)·ITermsStore(PlayerPrefsTermsStore, 서버 저장)로 이용약관·개인정보·마케팅 푸시·야간 푸시 동의와 약관 개정 시 다시 묻기를 다루거나, SetAgreedAsync·Changed 로 설정 화면의 수신 동의 변경과 서버 기록·수신 동의 결과 안내를 하거나, UmpAdConsent·UmpOptions(UpdateTimeout, DebugGeography, TestDeviceHashedIds)로 GDPR 동의 폼과 개인정보 옵션 폼(ShowPrivacyOptionsAsync)을 띄우거나, AttTrackingAuthorization 과 AttUsageDescription(추적 설명 문구, 언어별 InfoPlist.strings)으로 ATT 를 묻거나, IAdConsentProvider·ITrackingAuthorization 으로 다른 CMP 공급자를 만들 때 활성화한다.
---

# Geuneda Consent

앱 시작 때 받는 동의를 정해진 순서(자사 약관 → 광고 동의 → 추적 허용)로 처리한다. 등록한 단계만 실행하고, 실패는 결과 코드로, SDK 에 넘길 값은 스냅샷 하나로 준다. SDK 에 값을 넘기고 초기화하는 것은 게임이 한다.

## 패키지 정보

- **버전**: consent 0.1.0, consent.ump 0.1.0, consent.att 0.1.0
- **네임스페이스 / 어셈블리**: `Geuneda.Consent`, 어댑터 `Geuneda.Consent.Ump`, `Geuneda.Consent.Att`(에디터 `Geuneda.Consent.Att.Editor`)
- **설치**: `https://github.com/geuneda/geuneda-consent.git`, `https://github.com/geuneda/geuneda-consent-ump.git`, `https://github.com/geuneda/geuneda-consent-att.git` (core, UniTask git URL 도 함께)
- **의존성**: consent 는 `com.geuneda.core` 0.4.0, UniTask 2.5.10(Unity 2021.3+). 어댑터는 `com.geuneda.consent` 0.1.0. consent.ump 는 External Dependency Manager for Unity(EDM4U)가 있어야 한다(UMP SDK Android 3.2.0+, iOS 파드 ~> 3.0 을 받음)
- **기여 가이드**: 각 패키지 루트의 `AGENTS.md`
- **출처**: Lucky Defense Percent `UserAgreement`(UMP·ATT·자사 동의 서비스, UMP 초기화 예외를 코드로, 10초 타임아웃)를 따르고 약관 항목별 버전, UMP 판정의 GDPR(기기 지역 목록 대신), 한 곳에서 순서 실행, 개인정보 옵션 폼을 더했다(로드맵 4-4). SpellDefense 의 ATT 폴링(500ms, 60초)은 completion 콜백으로 바꿨다

## 핵심 API

전체 시그니처는 `references/api.md`.

- `new ConsentService(new ConsentServiceOptions { Terms, AdConsent, Tracking })` → `IConsentService`. null 단계는 건너뛴다. 순서는 고정(약관 → 광고 동의 → 추적 허용).
- `RunAsync(ct)` → `Result`. 취소·필수 약관 거절·진행 중이면 멈추고, 그 밖의 실패(UMP 연결·설정 오류, 약관 저장 실패)는 다음 단계를 계속한 뒤 첫 실패를 돌려준다(메시지 앞에 `terms`/`ads`/`tracking`). 결과와 상관없이 상태는 `Snapshot`.
- `Snapshot`(`ConsentSnapshot`): `Ads`(`AdConsentState`: `Status`, `CanRequestAds`, `PersonalizedAds`(GDPR 아님 또는 TCF 목적 1·3·4), `PrivacyOptionsRequired`, `GdprApplies`, `TcfPurposeConsents`, `HasPurposeConsent(n)`), `Tracking`(`TrackingStatus`), `TrackingAllowed`(Authorized 또는 ATT 없는 플랫폼), `Terms`(약관 답).
- `ShowPrivacyOptionsAsync(ct)`: 광고 동의 다시 고르기(공급자 없으면 예외).
- `TermsConsent(items, prompt, store = null, clock = null)`: `EnsureAsync`, `SetAgreedAsync(id, agreed)`, `IsAgreed(id)`, `TryGetAgreement`, `Agreements`, `IsLoaded`, `Changed`.
- `TermsItem(id, version, required)`, `TermsAgreement(Id, Version, Agreed, DecidedAt)`, `ITermsPrompt.ShowAsync(TermsPromptRequest, ct)` → `IReadOnlyDictionary<string, bool>`(빠진 항목은 거절), `TermsPromptRequest.Items`, `TryGetPrevious(id)`.
- `ITermsStore`(`LoadAsync`, `SaveAsync`), 기본 `PlayerPrefsTermsStore(key = "geuneda.consent.terms")`.
- `new UmpAdConsent(UmpOptions options = null)`: `UpdateTimeout` 10초, `TagForUnderAgeOfConsent`, `DebugGeography`(`Disabled`, `Eea`, `RegulatedUsState`, `Other`), `TestDeviceHashedIds`. `Reset()`(디버그).
- `new AttTrackingAuthorization()`: iOS 14+ 에서 묻고 답(`Status`)을 기다림. 그 밖은 `NotSupported`.
- 결과 코드 `ConsentResultCodes`: `TermsDeclined` 9001, `AdConsentUpdateFailed` 9002, `AdConsentFormFailed` 9003, `TermsSaveFailed` 9004. 그 밖은 core `ResultCodes`(`Cancelled`, `InProgress`, `NetworkError`, `Timeout`).

## 사용 패턴

```csharp
using Geuneda.Consent;
using Geuneda.Consent.Att;
using Geuneda.Consent.Ump;
using Geuneda.Core;
using Geuneda.Services;

var terms = new TermsConsent(new[]
{
    new TermsItem("tos", 1, required: true),
    new TermsItem("privacy", 1, required: true),
    new TermsItem("push.marketing", 1, required: false),
    new TermsItem("push.night", 1, required: false)
}, new TermsPopupPrompt(uiService));                       // ITermsPrompt 는 게임 UI
terms.Changed += agreement => api.RecordTermsAsync(agreement).Forget();   // 서버 기록·수신 동의 결과 안내

var consent = new ConsentService(new ConsentServiceOptions
{
    Terms = terms,
    AdConsent = new UmpAdConsent(),
    Tracking = new AttTrackingAuthorization()
});
MainInstaller.Bind<IConsentService>(consent);

var result = await consent.RunAsync(ct);
if (result.Code == ConsentResultCodes.TermsDeclined) { ShowQuitNotice(); return; }
if (result.Code == ResultCodes.Cancelled || result.Code == ResultCodes.InProgress) return;   // 흐름이 끝나지 않음: SDK 초기화 안 함
// 그 밖의 실패(UMP 연결 실패 등)는 지난 결과로 계속

var snapshot = consent.Snapshot;
MaxSdk.SetHasUserConsent(snapshot.Ads.PersonalizedAds && snapshot.TrackingAllowed);   // 레퍼런스가 넘긴 방식
if (snapshot.Ads.CanRequestAds) MaxSdk.InitializeSdk();

// 설정 화면
privacyButton.SetActive(consent.Snapshot.Ads.PrivacyOptionsRequired);
await consent.ShowPrivacyOptionsAsync(ct);
await consent.Terms.SetAgreedAsync("push.marketing", isOn, ct);
```

## 규칙

- **동의 흐름을 SDK 초기화보다 먼저 끝낸다.** ads 는 MAX 초기화를 게임에 맡기므로 `RunAsync` → 값 넘기기 → `MaxSdk.InitializeSdk()` 순서. 분석 SDK 도 같다.
- **멈춘 코드면 SDK 를 초기화하지 않는다**: `TermsDeclined`(거절), `Cancelled`, `InProgress`. 나머지 실패는 경고만 남기고 `Snapshot` 으로 계속한다.
- **약관 다시 묻기**: 답 없음, 저장된 버전과 다름, 거절한 필수 항목. 같은 버전에서 거절한 선택 항목은 묻지 않는다. 약관을 개정하면 그 항목의 `version` 을 올린다. ID 는 저장 키라 출시 뒤 바꾸지 않는다.
- **약관 상태는 저장에 성공한 뒤에만 바뀐다.** 필수 거절은 저장에 실패해도 `TermsDeclined`. `Changed` 는 저장 순서대로 오고, 처리기 안에서는 `SetAgreedAsync` 만 쓴다(처리기 안의 `EnsureAsync`·`RunAsync` 는 `InProgress`). 처리기가 필수 동의를 철회하면 `EnsureAsync` 결과가 `TermsDeclined` 가 된다.
- **UMP 는 앱을 시작할 때마다 요청한다**(SDK 권장). 요청이 실패해도 상태는 지난 실행의 결과다. 첫 요청 전의 상태는 모른다(Android `Unknown`, 광고 요청 불가). 상태는 `RunAsync` 뒤에 읽는다.
- **개인정보 옵션 버튼**: `PrivacyOptionsRequired` 일 때만 설정 화면에 둔다(GDPR 필수 요건). 누른 뒤 바뀐 스냅샷을 SDK 에 다시 넘긴다.
- **한 번에 작업 하나**: 서비스, 약관, UMP 공급자 각각 겹치면 `InProgress`. UMP 폼이 떠 있는 동안 취소하면 기다리기만 그만두고, 폼이 닫힐 때까지 다음 작업은 `InProgress`.
- **오용은 예외**: 모르는 약관 ID, 저장소를 읽기 전 `IsAgreed`·`Agreements`, 동의 화면이 묻지 않은 항목에 답함·null 답, 공급자 없이 `ShowPrivacyOptionsAsync`, 작업 중 UMP `Reset`.

## 함정

- UMP 는 AdMob 앱 ID 가 있어야 한다(Android 매니페스트 `com.google.android.gms.ads.APPLICATION_ID`, iOS Info.plist `GADApplicationIdentifier`). MAX 통합 관리자는 Google 어댑터를 설치하면 넣는다. 없으면 `AdConsentUpdateFailed`. AdMob 콘솔(개인정보 보호 및 메시지)에 GDPR 메시지를 게시해야 폼이 뜬다.
- consent.ump 는 EDM4U 가 있어야 iOS 가 링크된다(`GoogleUserMessagingPlatform` 파드). EDM4U 가 없으면 Xcode 빌드에서 UMP 헤더를 못 찾는다. Android 플러그인은 UMP 를 `compileOnly` 로 써서 Google Mobile Ads 가 끌어오는 UMP 와 겹치지 않는다.
- UMP iOS 파드 3.1.0 의 최소 iOS 는 12.0 이라 Xcode 27 에서 파드 대상 오류가 난다. 게임 Podfile `post_install` 에서 파드의 `IPHONEOS_DEPLOYMENT_TARGET` 을 15.0 이상으로 올린다(패키지는 Podfile 을 고치지 않음, ump README 예시).
- ATT 후처리는 덧붙이는(Append) 빌드에서 뺀 언어의 예전 문구를 지우지 않는다. 언어를 빼면 Replace 빌드를 한다.
- consent.ump 의 Android 라이브러리가 INTERNET 권한을 더한다(UMP AAR 에는 없음, 없으면 `SecurityException` 으로 정보 받기 실패).
- 디버그 지역(`DebugGeography`)은 테스트 기기(에뮬레이터·시뮬레이터, `TestDeviceHashedIds`)에서만 적용된다. 운영 빌드에서 빼려면 `#if !GEUNEDA_ENV_PROD && (UNITY_EDITOR || DEVELOPMENT_BUILD || GEUNEDA_ENV_DEV || GEUNEDA_ENV_QA)` 로 감싼다.
- ATT 는 추적 설명 문구가 없으면 앱이 종료된다. consent.att 의 iOS 후처리가 `AttUsageDescription` 에셋(Create > Geuneda > Consent > ATT Usage Description) 문구를 넣고, 에셋도 다른 도구의 문구도 없으면 빌드를 실패시킨다.
- ATT 는 앱이 활성 상태일 때만 창이 뜬다. 공급자가 활성이 될 때까지 기다렸다 묻는다. 물었는데 `NotDetermined` 면 시스템이 창을 띄우지 않은 것이다(경고, 다음 실행에서 다시 물음).
- `PersonalizedAds` 는 TCF 목적 1·3·4 만 본다. 벤더별 동의, 정당한 이익, 미국 주 법(GPP)은 SDK 가 기기의 TCF·GPP 문자열을 직접 읽는다.
- 약관 기본 저장소는 기기 단위 PlayerPrefs 다. 계정별·법적 기록은 `ITermsStore` 나 `Changed` 로 서버에 남기고, 답한 시각은 서버 시각(`clock`)을 쓰는 것이 낫다.
- 서비스에 약관을 넣으면 부팅 때 묻는다. 로그인 때 받으려면 서비스에 넣지 말고 그때 `TermsConsent.EnsureAsync` 를 부른다.
