# Geuneda Consent API 레퍼런스

네임스페이스 `Geuneda.Consent`(어댑터 `Geuneda.Consent.Ump`, `Geuneda.Consent.Att`, 에디터 `Geuneda.Consent.Att.Editor`). consent 0.1.0, consent.ump 0.1.0, consent.att 0.1.0.

## 서비스

### interface IConsentService / sealed class ConsentService : IConsentService

| 멤버 | 설명 |
|------|------|
| `ConsentService(ConsentServiceOptions options)` | null 이면 `ArgumentNullException`. 공급자가 없을 때 추적 상태는 iOS 면 `NotManaged`, 그 밖은 `NotSupported` |
| `ConsentSnapshot Snapshot` | 읽을 때마다 공급자에서 모음 |
| `TermsConsent Terms` | 등록한 약관(없으면 null) |
| `UniTask<Result> RunAsync(CancellationToken ct = default)` | 약관 → 광고 동의 → 추적 허용. 멈춤: `TermsDeclined`, `Cancelled`, `InProgress`. 계속: 그 밖의 실패(첫 실패를 돌려줌). 진입과 단계마다 취소 확인 |
| `UniTask<Result> ShowPrivacyOptionsAsync(CancellationToken ct = default)` | 광고 동의 공급자 없으면 `InvalidOperationException`. 실행 중이면 `InProgress` |

### sealed class ConsentServiceOptions

| 속성 | 뜻 |
|------|----|
| `TermsConsent Terms` | 첫 단계 |
| `IAdConsentProvider AdConsent` | 두 번째(UMP: `UmpAdConsent`) |
| `ITrackingAuthorization Tracking` | 마지막(ATT: `AttTrackingAuthorization`) |

### readonly struct ConsentSnapshot

| 멤버 | 뜻 |
|------|----|
| `AdConsentState Ads` | 공급자 없으면 `AdConsentState.NotManaged` |
| `TrackingStatus Tracking` | |
| `bool TrackingAllowed` | `Authorized` 또는 `NotSupported` |
| `IReadOnlyList<TermsAgreement> Terms` | 정의한 항목의 저장된 답(없거나 읽기 전이면 빈 목록) |

## 광고 동의

### readonly struct AdConsentState

| 멤버 | 뜻 |
|------|----|
| `AdConsentState(AdConsentStatus status, bool canRequestAds, bool privacyOptionsRequired, bool gdprApplies, string tcfPurposeConsents)` | 공급자가 만든다 |
| `static AdConsentState NotManaged` | 공급자 없음(요청·개인화 허용) |
| `AdConsentStatus Status` | `NotManaged` 0, `Unknown` 1, `NotRequired` 2, `Required` 3, `Obtained` 4 |
| `bool CanRequestAds` | UMP `canRequestAds` |
| `bool PrivacyOptionsRequired` | 개인정보 옵션 버튼 필요 |
| `bool GdprApplies` | TCF `IABTCF_gdprApplies == 1` |
| `string TcfPurposeConsents` | TCF `IABTCF_PurposeConsents`(없으면 빈 문자열) |
| `bool PersonalizedAds` | `CanRequestAds && (!GdprApplies \|\| 목적 1·3·4 동의)` |
| `bool HasPurposeConsent(int purpose)` | 1 부터, 범위 밖 false |

### interface IAdConsentProvider

| 멤버 | 뜻 |
|------|----|
| `AdConsentState State` | 요청을 시작한 뒤에는 실패해도 지난 결과. 첫 요청 전에는 모를 수 있음 |
| `UniTask<Result> RequestAsync(CancellationToken ct)` | 정보 받기 → 필요하면 폼 |
| `UniTask<Result> ShowPrivacyOptionsAsync(CancellationToken ct)` | 개인정보 옵션 폼 |

### sealed class UmpAdConsent : IAdConsentProvider (Geuneda.Consent.Ump)

| 멤버 | 뜻 |
|------|----|
| `UmpAdConsent(UmpOptions options = null)` | `UpdateTimeout` 0 이하 `ArgumentOutOfRangeException`, `TestDeviceHashedIds` null `ArgumentException` |
| `RequestAsync` | 실패: `NetworkError`, `Timeout`(정보 받기 시간 초과, SDK 폼 로드 시간 초과), `AdConsentUpdateFailed`, `AdConsentFormFailed`, `Cancelled`, `InProgress` |
| `ShowPrivacyOptionsAsync` | 실패: `AdConsentFormFailed`, `NetworkError`, `Timeout`, `Cancelled`, `InProgress` |
| `void Reset()` | 기기의 동의 지움(디버그). 작업 중 `InvalidOperationException` |

### sealed class UmpOptions

| 속성 | 기본값 |
|------|--------|
| `TimeSpan UpdateTimeout` | 10초 |
| `bool TagForUnderAgeOfConsent` | false |
| `UmpDebugGeography DebugGeography` | `Disabled`(0). `Eea` 1, `RegulatedUsState` 3, `Other` 4 |
| `IReadOnlyList<string> TestDeviceHashedIds` | 빈 배열 |

## 추적 허용

### enum TrackingStatus

`NotManaged` 0(iOS 인데 공급자 없음), `NotSupported` 1(Android·에디터·iOS 14 미만), `NotDetermined` 2, `Restricted` 3, `Denied` 4, `Authorized` 5.

### interface ITrackingAuthorization / sealed class AttTrackingAuthorization (Geuneda.Consent.Att)

| 멤버 | 뜻 |
|------|----|
| `TrackingStatus Status` | 기기에 저장된 답(읽을 때마다 네이티브) |
| `UniTask<Result> RequestAsync(CancellationToken ct)` | 묻지 않았으면 묻고 답을 기다림(앱 활성 대기). 답이 무엇이든 성공. 실패: `Cancelled`(창 전 취소는 묻지 않음, 창 뒤 취소는 기다리기만 그만둠), `InProgress` |

### sealed class AttUsageDescription : ScriptableObject (Geuneda.Consent.Att.Editor)

| 멤버 | 뜻 |
|------|----|
| `string Description` | Info.plist `NSUserTrackingUsageDescription` |
| `IReadOnlyList<LocalizedDescription> Localized` | `Language`(`.lproj` 이름), `Description` → `<언어>.lproj/InfoPlist.strings` |

iOS 빌드 후처리(순서 1000): 에셋이 둘 이상·잘못됨·에셋도 다른 도구의 문구도 없음이면 `BuildFailedException`. AppTrackingTransparency 를 UnityFramework 에 약하게 링크.

## 자사 약관

### sealed class TermsConsent

| 멤버 | 뜻 |
|------|----|
| `TermsConsent(IReadOnlyList<TermsItem> items, ITermsPrompt prompt, ITermsStore store = null, Func<DateTimeOffset> clock = null)` | 비었거나 ID 중복이면 `ArgumentException`. 기본 저장소 `PlayerPrefsTermsStore`, 기본 시계 `UtcNow` |
| `IReadOnlyList<TermsItem> Items` | 정의 순서 |
| `bool IsLoaded` | 저장소를 읽었는지 |
| `IReadOnlyList<TermsAgreement> Agreements` | 정의한 항목의 저장된 답. 읽기 전 `InvalidOperationException` |
| `bool IsAgreed(string id)` | 지금 버전에 동의. 모르는 ID `ArgumentException`, 읽기 전 `InvalidOperationException` |
| `bool TryGetAgreement(string id, out TermsAgreement agreement)` | 버전이 다를 수 있음 |
| `UniTask<Result> EnsureAsync(CancellationToken ct = default)` | 읽기(처음) → 물을 항목이 있으면 화면 → 저장. 실패: `TermsDeclined`(저장 실패여도, 처리기가 필수 철회해도), `Cancelled`, `InProgress`(겹침, 처리기 안 호출, 처리기 작업 저장 중), 저장소 코드 |
| `UniTask<Result> SetAgreedAsync(string id, bool agreed, CancellationToken ct = default)` | 한 항목 변경. 같은 버전 같은 답이면 저장 생략 |
| `event Action<TermsAgreement> Changed` | 저장 뒤 항목마다, 저장 순서대로, 처리기마다 예외 격리 |

### sealed class TermsItem / readonly struct TermsAgreement

`TermsItem(string id, int version, bool required)`: 빈 ID `ArgumentException`, 버전 1 미만 `ArgumentOutOfRangeException`. `TermsAgreement(string id, int version, bool agreed, DateTimeOffset decidedAt)`.

### interface ITermsPrompt / sealed class TermsPromptRequest

`UniTask<IReadOnlyDictionary<string, bool>> ShowAsync(TermsPromptRequest request, CancellationToken ct)`: 빠진 항목은 거절, 묻지 않은 ID·null 은 `InvalidOperationException`, 취소는 `OperationCanceledException`. `TermsPromptRequest.Items`(물을 항목), `TryGetPrevious(string id, out TermsAgreement previous)`.

### interface ITermsStore / sealed class PlayerPrefsTermsStore

`LoadAsync(ct)` → `Result<IReadOnlyList<TermsAgreement>>`, `SaveAsync(agreements, ct)` → `Result`. `PlayerPrefsTermsStore(string key = "geuneda.consent.terms")`: JSON(JsonUtility, 시각은 unix ms), 읽을 수 없는 값은 Warning 뒤 빈 목록, `PlayerPrefsException` 은 `TermsSaveFailed`.

## 결과 코드 (ConsentResultCodes, 9000 블록)

| 코드 | 값 |
|------|----|
| `TermsDeclined` | 9001 |
| `AdConsentUpdateFailed` | 9002 |
| `AdConsentFormFailed` | 9003 |
| `TermsSaveFailed` | 9004 |
