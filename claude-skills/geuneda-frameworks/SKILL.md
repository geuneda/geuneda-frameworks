---
name: geuneda-frameworks
description: Geuneda Unity 패키지 프레임워크 전체의 구조, 의존성, 개발/테스트 방법을 이해할 때 사용하는 스킬. 어떤 com.geuneda.* 패키지를 써야 할지 고르거나, 패키지 간 의존 관계를 파악하거나, geuneda-frameworks 호스트 레포에서 서브모듈 작업, 새 패키지 추가, Unity 버전 변경처럼 여러 패키지에 영향을 주는 작업을 할 때 활성화한다. 개별 패키지 API 사용법은 해당 패키지 스킬을 쓴다.
---

# Geuneda Frameworks

Geuneda UPM 패키지 35개와 그것을 개발, 테스트, 검증하는 Unity 호스트 레포(`https://github.com/geuneda/geuneda-frameworks.git`). 각 패키지는 독립 git 레포이고 호스트 레포의 `Packages/com.geuneda.<패키지>/` 에 서브모듈로 들어 있다. 원본은 GameLovers Frameworks by Miguel Tomas, 라이선스는 MIT.

## 활성화 시점

- 어떤 패키지를 써야 할지 결정할 때
- 패키지 간 의존성이나 설치 시 함께 넣어야 할 패키지를 파악할 때
- 호스트 레포에서 서브모듈을 갱신하거나 패키지를 수정할 때
- 새 패키지를 프레임워크에 추가할 때
- Unity 버전 변경처럼 여러 패키지에 영향을 주는 변경을 할 때

## 패키지 (35개)

버전과 최소 Unity 는 2026-10-14 시점 `package.json` 값이다. 작업 전에 `package.json` 으로 다시 확인한다.

| 패키지 | 버전 | 최소 Unity | 용도 | 스킬 |
|--------|------|-----------|------|------|
| `com.geuneda.core` | 0.5.1 | 2021.3 | 바닥 패키지(의존성 없음). 모듈별 로거, 결과 규약(`Result`), 빌드 환경(`AppEnv`), 메인 스레드 디스패처, 설정 에셋 로더, 설치·기기 ID, 보안 저장소(iOS 키체인, Android 키스토어), 결정론적 난수(`Pcg32`), 단조 시계(`MonotonicClock`, 기기 시계 변경 무관, 잠든 동안에도 흐름), 인증 암호화(`AesEncryption`)·기기 키(`DeviceKeyProvider`) | `geuneda-core` |
| `com.geuneda.http` | 0.1.0 | 2021.3 | UnityWebRequest HTTP 클라이언트(미들웨어 체인, `Result<HttpResponse>`, JSON, 선택형 타임아웃·재시도) | `geuneda-http` |
| `com.geuneda.realtime` | 0.2.0 | 2021.3 | WebSocket 실시간 RPC 클라이언트(single-flight 연결, 재로그인, 지수 백오프 재연결, 서버 푸시, JSON/MessagePack 직렬화), `[RpcService]` 계약 소스 생성기, ASP.NET Core 서버(`Server~/`) | `geuneda-realtime` |
| `com.geuneda.account` | 0.3.0 | 2021.3 | 계정 인증(게스트·제공자 로그인, 자동 로그인, 재발급 single-flight, 토큰 미들웨어, 연동·옮겨오기·해제·삭제)과 앱 세션(다음 세션 ID 예약, 대칭 이벤트), ASP.NET Core 인증 서버(`Server~/`, 애플·구글 id 토큰 검증, 서버 발급 nonce·충돌 티켓 replay 방어) | `geuneda-account` |
| `com.geuneda.account.apple` | 0.2.0 | 2021.3 | account 의 Sign in with Apple 제공자(iOS 네이티브 플러그인, nonce, capability 빌드 후처리) | `geuneda-account` |
| `com.geuneda.account.google` | 0.2.0 | 2021.3 | account 의 Google 로그인 제공자(Android Credential Manager 라이브러리 플러그인, iOS PKCE, nonce) | `geuneda-account` |
| `com.geuneda.appsetting` | 0.2.0 | 2021.3 | 원격 앱 설정(서명된 설정 문서 검증, 앱 버전별 노드의 플랫폼 상태·점검 공지·서버 주소·기능 플래그로 접속 판정, 리소스 매니페스트, ETag 조건부 요청), 서명 CLI 와 ASP.NET Core 배포 헬퍼(`Server~/`) | `geuneda-appsetting` |
| `com.geuneda.resource` | 0.1.0 | 2021.3 | 원격 리소스(테이블 등 데이터 파일) 캐시(매니페스트 항목의 크기·SHA-256 판정, 검증 후 원자적 저장, 옛 버전 정리, 동시 다운로드 제한, 받기 전 용량 확인, 진행률) | `geuneda-resource` |
| `com.geuneda.analytics` | 0.2.1 | 2021.3 | 분석 이벤트 로깅(기록 시점 맥락 스냅샷, sink 비트 팬아웃, 실패 sink 만 저장·재전송, 자사 수집 배치 sink 와 ASP.NET Core 수집 서버, account 세션 연동, 구매·광고 노출 수익 표준 이벤트) | `geuneda-analytics` |
| `com.geuneda.analytics.firebase`·`.airbridge`·`.appsflyer`·`.facebook` | 0.1.0 | 2021.3(AppsFlyer 2023.1) | analytics 의 벤더 SDK sink(표준 이벤트를 벤더 표준으로 변환). 그 SDK 가 있는 게임만 설치 | `geuneda-analytics` |
| `com.geuneda.iap` | 0.3.0 | 2021.3 | 인앱 결제(지급자 확인 뒤에만 스토어 확정, 지급 재시도 백오프, 재조회 복구, 늦은 결제 지급, 중복 거래·미확정 주문 먼저, 확정만 재시도, 결과 코드 7000, analytics 매출 기록 선택, http 지급자 선택), .NET 결제 서버 `Server~`(Google Play·App Store 영수증 검증, 영수증 원장, 지급 엔드포인트, 서버 알림의 환불 회수·구독 상태) | `geuneda-iap` |
| `com.geuneda.iap.unity` | 0.1.0 | 2022.3 | iap 의 Unity IAP 5.4.4 어댑터 | `geuneda-iap` |
| `com.geuneda.ads` | 0.1.0 | 2021.3 | 보상형·전면 광고(표시마다 결과 하나, 닫힘 콜백 없으면 앱이 앞에 있는 시간으로 시간 초과, 늦은 보상 이벤트, 앞 광고 늦은 콜백 거르기, 로드 2초→30초 백오프, 결과 코드 8000, analytics 노출 수익 기록 선택) | `geuneda-ads` |
| `com.geuneda.ads.max` | 0.1.0 | 2021.3 | ads 의 AppLovin MAX 8.6.3+ 어댑터(MAX 가 있을 때만 컴파일) | `geuneda-ads` |
| `com.geuneda.consent` | 0.1.0 | 2021.3 | 앱 시작 동의(자사 약관 → UMP → ATT 순서 실행, 취소·필수 거절·진행 중만 멈춤, 결과 코드 9000, 광고 요청·개인화·추적 스냅샷, 약관 항목별 버전) | `geuneda-consent` |
| `com.geuneda.consent.ump` | 0.1.0 | 2021.3 | consent 의 Google UMP 공급자(Android·iOS 네이티브, 10초 시간 제한, 동의 폼·개인정보 옵션 폼, EDM4U 필요) | `geuneda-consent` |
| `com.geuneda.consent.att` | 0.1.0 | 2021.3 | consent 의 iOS ATT 공급자(completion 콜백, 앱 활성 대기, 추적 설명 문구 후처리, 약한 링크) | `geuneda-consent` |
| `com.geuneda.banword` | 0.1.1 | 2021.3 | 금칙어 검사(금칙·허용 Aho-Corasick 오토마톤 하나, 허용어가 완전히 덮으면 뺌, 포함·위치·가리기, 대소문자만 무시하는 고정 유니코드 표, 단어장 파일 읽기, 의존성 없음, resource 가 있으면 지금 → 마지막 → 내장 순서 로더 asmdef 가 켜짐, `Server~` .NET 라이브러리가 같은 소스) | `geuneda-banword` |
| `com.geuneda.notice` | 0.1.0 | 2021.3 | 게임 공지 목록(모든 언어·플랫폼 공지 JSON 문서를 ETag 조건부 요청으로 받아 기간·플랫폼·언어·분류로 거르고 정렬, 읽음(최근 500개)·'오늘 안 보기' 기록, 안 읽은 수·진입 팝업, 문서 형식 Unity·.NET 공유, `Server~` 에 지금 보이는 공지만 내려주는 ASP.NET Core 배포 헬퍼) | `geuneda-notice` |
| `com.geuneda.coupon` | 0.1.1 | 2021.3 | 쿠폰 사용(코드 다듬어 보내기, 지급 결과 `CouponRedemption<TGrant>`, 이미 쓴 캠페인은 처음 결과와 함께 성공, 결과 코드 11000, `Server~` ASP.NET Core 라이브러리: 공용·개별 일회용 코드, 기간, 대상 조건, 계정별 실패 제한, 사용 기록·지급 한 트랜잭션, 실제 DB 저장소 안내 docs/db-store.md) | `geuneda-coupon` |
| `com.geuneda.webview` | 0.2.1 | 2021.3 | 앱 안 웹뷰와 페이지 명령 브리지(JS 파일 `geuneda.call` 이 요청 ID 로 짝지은 결과를 Promise 로, Unity 이벤트, 허용 출처만 열고 명령 받기·그 밖 이동 막기, 토큰 안 넘김, RectTransform 영역 추적, 뒤로가기, 열기 성공은 브리지 준비, 결과 코드 12000, notice·coupon 이 있으면 공지·쿠폰 명령 asmdef, `IWebViewService` 는 `IDisposable`(`MainInstaller.CleanDispose`), 페이지로 가는 스크립트는 ASCII) | `geuneda-webview` |
| `com.geuneda.webview.gree` | 0.2.0 | 2021.3 | webview 의 gree unity-webview 어댑터(준비 전 값을 준비 뒤 이동 제한 → 여백 → 로드 순서로, 여백은 화면 비율, gree 가 있을 때만 컴파일, gree 는 `dist/package-nofragment` 로 설치) | `geuneda-webview` |
| `com.geuneda.servertime` | 0.2.0 | 6000.3 | 서버 시간 동기화(NTP·HTTPS `Date`·직접 구현 원천을 순서대로, 왕복 지연 보정, 지수 백오프 재시도, 30분 재동기화, 포그라운드 복귀 재동기화). services 시간 서비스의 기준점을 맞춤 | `geuneda-servertime` |
| `com.geuneda.gamedata` | 2.0.0 | 6000.0 | Observable 데이터, `ComputedField`, `ConfigsProvider`, 결정론적 `floatP`, 보안 값(`SecureInt` 등), 직렬화 헬퍼 | `geuneda-gamedata` |
| `com.geuneda.services` | 5.2.0 | 6000.3 | `MainInstaller` 서비스 로케이터, 메시지 브로커, 틱, 코루틴, 풀, 데이터, RNG(PCG32), 시간(단조 시계 기준점, 서버 시각 기준), 커맨드, 버전, Addressables 에셋 로딩/임포트 | `geuneda-services` |
| `com.geuneda.uiservice` | 3.1.0 | 6000.0 | UI 프레젠터 생명주기, UI Set, 피처 조합, UI Toolkit, 뒤로가기, 우선순위 팝업 큐, 모달 dim, 입력 차단 | `geuneda-uiservice` |
| `com.geuneda.statechart` | 0.11.0 | 2022.3 | 계층적 상태 머신(Statechart) | `geuneda-statechart` |
| `com.geuneda.inputextensions` | 1.0.4 | 2019.4 | Input System 포인터 드래그, 스와이프/탭, 게임패드 | `geuneda-inputextensions` |
| `com.geuneda.nativeui` | 0.3.0 | 2021.3 | iOS/Android 네이티브 알림 팝업, 토스트 | `geuneda-nativeui` |
| `com.geuneda.notificationservice` | 0.3.0 | 2021.3 | 모바일 로컬 알림 예약/취소/해제, 앱 안 설정과 OS 권한 게이트 | `geuneda-notificationservice` |
| `com.geuneda.googlesheetimporter` | 0.10.0 | 6000.0 | Google 스프레드시트 -> ScriptableObject 설정 데이터 임포트(에디터 도구) | `geuneda-googlesheetimporter` |
| `com.geuneda.gamesystems` | 0.3.1 | 6000.3 | 공용 게임 시스템, 기능별 asmdef(현재 레드닷) | `geuneda-gamesystems` |

레포 URL 규칙: `com.geuneda.<x>` -> `https://github.com/geuneda/geuneda-<x>.git`.

없어지거나 합쳐진 것:
- `com.geuneda.assetsimporter` 는 services v2.0.0 에 흡수됐다(`AssetResolverService`, `Geuneda.Services.AssetsImporter`, AddressableIds 생성기). 별도 패키지로 추가하지 않는다.
- 예전 DataExtensions / ConfigsProvider 패키지는 gamedata 로 합쳐졌다. 런타임 네임스페이스 `Geuneda.DataExtensions`, 어셈블리 `Geuneda.GameData`.

## 의존성

```
core
  ├── http
  │     ├── account
  │     │     ├── account.apple
  │     │     └── account.google (http 에도 의존)
  │     ├── appsetting
  │     ├── resource
  │     ├── notice (Server~ 는 .NET 배포 헬퍼)
  │     ├── coupon (Server~ 는 .NET 쿠폰 서버 라이브러리)
  │     └── servertime (services 에도 의존)
  ├── realtime
  └── analytics (http·account 는 선택: 있으면 해당 asmdef 가 켜짐)
        └── analytics.firebase, analytics.airbridge, analytics.appsflyer, analytics.facebook (벤더 SDK 필요)
  └── iap (analytics·http 는 선택: 있으면 매출 기록·HTTP 지급자 asmdef 가 켜짐. Server~ 는 .NET 결제 서버)
        └── iap.unity (Unity IAP 5.4.4)
  └── ads (analytics 는 선택: 있으면 노출 수익 기록 asmdef 가 켜짐)
        └── ads.max (AppLovin MAX 가 있을 때만 컴파일, versionDefines)
  └── consent
        └── consent.ump (UMP SDK 는 EDM4U), consent.att (iOS ATT)
  └── webview (notice·coupon 은 선택: 있으면 공지·쿠폰 명령 asmdef 가 켜짐)
        └── webview.gree (gree unity-webview 가 있을 때만 컴파일, versionDefines)
  ├── gamedata
  │     ├── services (core 에도 직접 의존)
  │     │     └── gamesystems (core 에도 직접 의존)
  │     └── googlesheetimporter
  └── uiservice, statechart, nativeui, notificationservice

독립(다른 Geuneda 패키지에 의존하지 않음): inputextensions, banword(resource 는 선택: 있으면 로더 asmdef `Geuneda.BanWord.Resource` 가 켜짐)
```

core 는 다른 패키지가 함께 쓰는 바닥 패키지다(결정 D1: gamedata 아래). 지금은 services(빌드 환경 `AppEnv`, `Pcg32`, 단조 시계, 로거), http 와 realtime(결과 규약 `Result`), account 와 제공자 패키지(보안 저장소), appsetting 과 resource(결과 규약, 로거), servertime(결과 규약, 로거, 단조 시계), analytics(로거, 설치 ID, 빌드 환경, 단조 시계), iap 과 ads(결과 규약, 로거, 단조 시계, 메인 스레드 디스패처), consent 와 그 어댑터(결과 규약, 로거, 메인 스레드 디스패처), banword 의 선택 로더(결과 규약, 로거), notice·coupon(결과 규약, 로거), webview(결과 규약, 로거, 메인 스레드 디스패처), gamedata·statechart·uiservice·notificationservice·gamesystems(로거), nativeui(로거, 메인 스레드 디스패처)가 참조한다. 에디터 전용 코드와 googlesheetimporter 는 `Debug.Log*` 를 그대로 쓴다. core 는 어떤 Geuneda 패키지도 참조하지 않는다.

- core API 를 바꾸면 services, http, realtime, account, appsetting, resource, servertime, analytics, iap, ads, consent, banword(`Geuneda.BanWord.Resource`), notice, coupon, webview, gamesystems, gamedata, statechart, uiservice, nativeui, notificationservice 를 확인한다. resource 의 `IResourceCache`·`ResourceEntry` 를 바꾸면 banword 로더를 확인한다. analytics 의 표준 이벤트(`AnalyticsPurchase`, `AnalyticsAdImpression`)를 바꾸면 iap(`Geuneda.Iap.Analytics`)와 ads(`Geuneda.Ads.Analytics`)를 확인한다. iap 의 `IIapStore` 계약을 바꾸면 iap.unity 를, ads 의 `IAdMediation` 계약을 바꾸면 ads.max 를, webview 의 어댑터 계약(`IWebViewFactory`·`IWebViewNative`·`IWebViewNativeListener`)을 바꾸면 webview.gree 를, notice 의 `INoticeService`·coupon 의 `ICouponService` 를 바꾸면 webview 의 공지·쿠폰 명령을, consent 의 `IAdConsentProvider`·`ITrackingAuthorization` 계약이나 `ConsentResultCodes` 를 바꾸면 consent.ump·consent.att 를 함께 바꾼다. http API 를 바꾸면 account, account.google, appsetting, resource, notice, coupon, servertime, analytics(`Geuneda.Analytics.Collector`)를 확인한다. account 의 `IAppSession` 을 바꾸면 analytics(`Geuneda.Analytics.Account`)를 확인한다. appsetting 의 리소스 이름 규칙(`AppSettingResource`)을 바꾸면 resource 의 `ResourceEntry` 도 함께 바꾼다(두 패키지는 서로 의존하지 않음). account API(`IAuthProvider`, `PlatformCredential`, `AccountResultCodes`)를 바꾸면 account.apple, account.google 을 확인한다. gamedata API 를 바꾸면 services, googlesheetimporter, gamesystems 를 확인한다. services API 를 바꾸면 gamesystems, servertime(시간 서비스 `ITimeManipulator`)을 확인한다.
- uiservice 는 gamedata/services 에 의존하지 않는다.
- 패키지 간 순환 의존은 금지한다.
- 외부 의존성과 버전은 `references/api.md` 의 패키지별 카드를 본다.

## 설치 (소비 프로젝트)

`Packages/manifest.json` 에 태그 없는 git URL 을 넣는다. 특정 버전으로 고정하려면 `#<태그>` 를 붙이되, git 태그가 `package.json` 버전과 맞지 않는 경우가 있으니 레포에 실제로 있는 태그인지 먼저 확인한다.

```json
{
  "dependencies": {
    "com.cysharp.unitask": "https://github.com/Cysharp/UniTask.git?path=src/UniTask/Assets/Plugins/UniTask",
    "com.geuneda.core": "https://github.com/geuneda/geuneda-core.git",
    "com.geuneda.gamedata": "https://github.com/geuneda/geuneda-gamedata.git",
    "com.geuneda.services": "https://github.com/geuneda/geuneda-services.git"
  }
}
```

UPM 은 git 전용 의존성을 자동으로 받지 못하므로 직접 함께 넣는다.

| 설치하는 패키지 | 같이 넣을 것 |
|----------------|-------------|
| gamedata, uiservice, statechart | core, UniTask |
| services | UniTask, gamedata, core |
| googlesheetimporter | gamedata, core, UniTask |
| gamesystems | services, gamedata, core, UniTask |
| nativeui, notificationservice | core |
| http | core, UniTask |
| realtime | core, UniTask(MessagePack 을 쓰면 UnityNuGet 의 `org.nuget.messagepack`, `org.nuget.microsoft.net.stringtools`) |
| account | core, http, UniTask |
| account.apple, account.google | account, core, http, UniTask |
| appsetting | core, http, UniTask |
| resource | core, http, UniTask |
| servertime | services, gamedata, core, http, UniTask |
| analytics | core, UniTask(자사 수집은 http, 세션 연동은 account 와 그 의존성) |
| analytics.firebase·airbridge·appsflyer·facebook | analytics, core, UniTask, 그 벤더 SDK |
| iap | core, UniTask(매출 기록은 analytics, HTTP 지급자는 http) |
| iap.unity | iap, core, UniTask(Unity IAP 는 레지스트리에서 자동 설치) |
| ads | core, UniTask(노출 수익 기록은 analytics) |
| ads.max | ads, core, UniTask, AppLovin MAX(게임이 AppLovin 레지스트리로 설치) |
| consent | core, UniTask |
| consent.ump | consent, core, UniTask, EDM4U(UMP SDK) |
| consent.att | consent, core, UniTask |
| banword | 없음(로더를 쓰려면 resource, core, http, UniTask) |
| notice | core, http, UniTask |
| coupon | core, http, UniTask |
| webview | core, UniTask(공지·쿠폰 명령은 notice·coupon 과 그 의존성) |
| webview.gree | webview, core, UniTask, gree unity-webview(커밋 고정), uGUI |

## 호스트 레포 구조

```
geuneda-frameworks/
  Assets/                 # 호스트 에셋 (Addressables 설정, TextMesh Pro 리소스, 테스트용 에셋)
  Packages/
    manifest.json         # 호스트 의존성 (Geuneda 패키지는 git URL 로 선언)
    com.geuneda.*/        # 패키지 35개, 각각 서브모듈
  ProjectSettings/        # ProjectVersion.txt: 6000.3.2f1
  UserSettings/
  claude-skills/
    install.sh            # ~/.claude/skills/ 로 스킬 복사
    uninstall.sh          # ~/.claude/skills/<스킬> 삭제
    geuneda-frameworks/   # 이 스킬
    geuneda-<패키지>/     # 패키지별 스킬 24개(애플·구글 제공자는 geuneda-account, 분석 어댑터는 geuneda-analytics, Unity IAP 어댑터는 geuneda-iap, MAX 어댑터는 geuneda-ads, UMP·ATT 어댑터는 geuneda-consent, gree 웹뷰 어댑터는 geuneda-webview 가 함께 다룸)
  .gitmodules
  AGENTS.md               # 에이전트용 레포 가이드
  CLAUDE.md               # 프레임워크를 쓰는 프로젝트의 공용 규칙, 네임스페이스 -> 스킬 표
  CONTRIBUTING.md         # 서브모듈 워크플로우, 코딩 표준, 테스트
  README.md               # 패키지 목록, 설치, 스킬 설치
```

`Packages/` 아래 같은 이름의 폴더(서브모듈)는 Unity 가 임베디드 패키지로 우선 사용하므로, 호스트에서는 `manifest.json` 의 git URL 이 아니라 서브모듈 작업본이 컴파일된다.

## 서브모듈 워크플로우

```bash
# 처음 받기
git clone --recurse-submodules https://github.com/geuneda/geuneda-frameworks.git
# 또는 이미 클론했으면
git submodule update --init --recursive
```

서브모듈은 호스트가 기록한 커밋에 detached HEAD 로 체크아웃된다. 고치기 전에 기본 브랜치로 전환한다. 기본 브랜치는 core, http, realtime, account, account.apple, account.google, appsetting, resource, servertime, analytics, analytics.firebase, analytics.airbridge, analytics.appsflyer, analytics.facebook, iap, iap.unity, ads, ads.max, consent, consent.ump, consent.att, banword, notice, coupon, webview, webview.gree, gamesystems 가 `main`, 나머지 8개는 `master` 다. 호스트 ProjectSettings 의 `GEUNEDA_SKIP_VENDOR_ADAPTERS` define 은 벤더 SDK 가 필요한 analytics 어댑터를 호스트에서 컴파일하지 않게 한다(지우지 않음).

```bash
cd Packages/com.geuneda.services
git checkout master
git pull
# 변경 -> 커밋 -> 패키지 레포에 push
cd ../..
git add Packages/com.geuneda.services     # 호스트에는 포인터 갱신만 커밋
git commit -m "chore: services 포인터 갱신"
```

모든 서브모듈을 원격 기본 브랜치 최신으로 옮기려면 `git submodule update --remote` 후 포인터 변경을 커밋한다.

## 개발 규칙

- C# 9.0, 명시적 네임스페이스(global usings 금지)
- Runtime 어셈블리에서 `UnityEditor` 참조 금지. 에디터 코드는 `Editor/` 와 Editor 전용 asmdef 에 둔다
- 새 의존성은 `package.json` `dependencies` 와 asmdef `references` 양쪽에 반영한다
- `Packages/` 안에 새 파일을 만들면 `.meta` 도 필요하다
- 서드파티 API 는 `Library/PackageCache/` 의 로컬 소스를 우선 참조한다(Unity 가 프로젝트를 연 뒤 생김)
- 패키지에 `AGENTS.md` 가 있으면 그 패키지 작업 규칙의 원천이다: services(테스트는 `Tests/AGENTS.md`), uiservice, gamesystems, core, http, realtime, account, account.apple, account.google, appsetting, resource, servertime, analytics, analytics.firebase, analytics.airbridge, analytics.appsflyer, analytics.facebook, iap, iap.unity, ads, ads.max, consent, consent.ump, consent.att, banword, notice, coupon, webview, webview.gree

## 테스트

Unity Test Framework 로 작성하고 Unity 에디터의 **Window > General > Test Runner** 에서 EditMode/PlayMode 로 실행한다. 테스트가 있는 패키지는 core, http, realtime, account, account.apple, account.google, appsetting, resource, servertime, analytics, gamedata, services, uiservice, statechart, googlesheetimporter, gamesystems, notificationservice(PlayMode), 벤더 어댑터 4개(analytics.firebase·airbridge·appsflyer·facebook, 호스트에서는 컴파일되지 않아 SDK 를 넣은 별도 프로젝트에서 실행), iap, iap.unity(PlayMode 전 과정 테스트는 define `IAP_FAKE_STORE_DEFAULT` 필요), ads, ads.max(MAX 가 있을 때만 컴파일, 호스트에는 MAX 가 없어 SDK 를 넣은 별도 프로젝트에서 실행), consent, consent.ump, consent.att(네이티브는 EDM4U 를 넣은 별도 프로젝트의 에뮬레이터·시뮬레이터 빌드로 확인), banword(같은 테스트 파일을 `Server~` 의 .NET 테스트도 돌림), notice(문서 테스트는 `Server~` 의 .NET 테스트도 돌림, 서버 테스트는 xUnit), coupon(서버 테스트는 `Server~` 의 xUnit), webview(JS 는 Node 테스트), webview.gree(gree 를 넣은 별도 프로젝트에서 PlayMode 상호 운용 테스트, macOS 에디터 그래픽 장치) 이고, inputextensions, nativeui 에는 없다. 테스트 asmdef 이름은 `references/api.md` 의 패키지별 카드에 있다.

## 새 패키지 추가 절차

1. `geuneda-<패키지>` 레포(패키지 이름의 점은 `-`)를 만들고 표준 UPM 구조(`package.json`, `Runtime/`, `Editor/`, `Tests/`, `README.md`, `CHANGELOG.md`, `LICENSE.md`)로 작성
2. `git submodule add https://github.com/geuneda/geuneda-<패키지>.git Packages/com.geuneda.<패키지>`
3. `Packages/manifest.json` 에 git URL 의존성 추가
4. 루트 `README.md` 의 패키지 목록, 의존성, 스킬 표에 추가
5. `claude-skills/geuneda-<패키지>/` 에 `SKILL.md`, `references/api.md` 를 만들고 `install.sh`, `uninstall.sh` 의 `SKILLS` 배열에 등록. 기능 패키지의 플랫폼 연동만 떼어 낸 패키지(D3, 예: account.apple·account.google)는 기능 패키지 스킬에 넣는다
6. `CLAUDE.md` 의 네임스페이스 -> 스킬 표에 행 추가
7. 이 스킬(`SKILL.md`, `references/api.md`)의 패키지 목록과 의존성 갱신

## 패키지 선택

| 필요한 기능 | 패키지 |
|-------------|--------|
| Observable 상태, 설정 데이터 저장소, 결정론적 수학 | gamedata |
| 서비스 로케이터, 이벤트, 틱/코루틴, 오브젝트 풀, 저장, RNG, 시간, 커맨드 | services |
| Addressables 에셋/씬 로딩, 에셋 설정 임포트, Addressable ID 생성 | services |
| UI 생명주기(MVP), UI Set, UI Toolkit, 뒤로가기, 팝업 순차 노출(우선순위 큐), 모달 dim, 입력 차단 | uiservice |
| 계층적 상태 머신 | statechart |
| 드래그, 스와이프, 탭, 게임패드 입력 | inputextensions |
| 네이티브 알림 팝업, 토스트 | nativeui |
| 모바일 로컬 알림 | notificationservice |
| Google 스프레드시트 데이터 임포트 | googlesheetimporter |
| 레드닷(경로 트리 알림 배지) 등 공용 게임 시스템 | gamesystems |
| 모듈별 로깅(레벨 플래그, 출력 대상 교체) | core |
| 실패를 코드로 돌려주는 결과 타입, 공용 결과 코드 | core |
| 빌드 환경(DEV/QA/PROD) 분기, 운영 빌드에서 코드 빼기 | core |
| SDK 콜백을 메인 스레드로 넘기기 | core |
| 설정 ScriptableObject 읽기(.user 덮어쓰기, 환경별 값) | core |
| 설치 ID, 재설치해도 유지되는 기기 ID(iOS 키체인) | core |
| 토큰·비밀 값 보관(iOS 키체인, Android 키스토어) | core |
| 세이브 파일·로그 캐시 암호화와 변조 검출, 기기에만 두는 암호 키 | core |
| REST API 호출(미들웨어, 타임아웃·재시도, JSON) | http |
| 실시간 서버 연결(WebSocket RPC, 서버 푸시, 자동 재연결), 서버·클라이언트 공유 RPC 계약과 ASP.NET Core 서버 | realtime |
| 로그인(게스트·플랫폼), 토큰 재발급·보관, 계정 연동, 앱 세션 ID, 인증 서버 | account |
| 애플·구글 로그인 | account.apple, account.google(+ account) |
| 원격 앱 설정(점검·강제 업데이트·서버 주소·기능 플래그), 서명된 설정 문서와 배포 | appsetting |
| 원격 데이터 파일(테이블 등) 내려받기·캐시, 크기·SHA-256 검증 | resource(매니페스트는 보통 appsetting 의 `resources`) |
| 서버 시각 동기화(NTP, HTTPS `Date` 헤더), 기기 시계 조작에 영향받지 않는 현재 시각, 일일 초기화 기준 시각 | servertime(+ services 의 `ITimeService`) |
| 분석 이벤트 로깅(Firebase·Airbridge·AppsFlyer·Facebook·자사 수집을 한 API 로), 구매·광고 수익 표준 이벤트, 실패 재전송, 이벤트 수집 서버 | analytics(+ 벤더 어댑터 패키지 analytics.firebase 등, 자사 수집은 http) |
| 인앱 결제(서버 지급 뒤 확정, 미확정 주문 복구, 지급 누락 방지, 매출 기록) | iap + iap.unity(Unity IAP), 매출 기록은 analytics |
| 보상형·전면 광고(결과 한 번, 닫힘 콜백 누락 시간 초과, 늦은 보상, 로드 재시도, 노출 수익 기록) | ads + ads.max(AppLovin MAX), 수익 기록은 analytics |
| 앱 시작 동의(자사 약관 항목별 버전, GDPR 광고 동의 UMP, iOS ATT), SDK 초기화 전 동의 값 | consent + consent.ump, consent.att |
| 닉네임·채팅 금칙어 검사(허용어, 가리기), 클라이언트와 서버가 같은 판정 | banword(원격 단어장은 resource) |
| 게임 공지 목록(기간·플랫폼·언어 필터, 읽음·레드닷, 진입 팝업과 오늘 안 보기), 공지 배포 서버 | notice |
| 쿠폰 코드 사용(공용·개별 일회용 코드, 대상 조건, 무작위 대입 방지, 서버 지급) | coupon |
| 앱 안 웹뷰로 공지·쿠폰·이벤트 웹 페이지 띄우기, 페이지 ↔ Unity 명령(Promise)·이벤트, 허용 출처 제한, 영역·뒤로가기 | webview + webview.gree(gree unity-webview), 공지·쿠폰 명령은 notice·coupon |

## 참조

- `references/api.md`: 패키지별 상세 카드(의존성, asmdef, 네임스페이스, 문서 위치, 테스트), 구성 예시
- 패키지 API 는 해당 패키지 스킬: `geuneda-gamedata`, `geuneda-services`, `geuneda-uiservice`, `geuneda-statechart`, `geuneda-inputextensions`, `geuneda-nativeui`, `geuneda-notificationservice`, `geuneda-googlesheetimporter`, `geuneda-gamesystems`, `geuneda-core`, `geuneda-http`, `geuneda-realtime`, `geuneda-account`, `geuneda-appsetting`, `geuneda-resource`, `geuneda-servertime`, `geuneda-analytics`, `geuneda-iap`, `geuneda-ads`, `geuneda-consent`, `geuneda-banword`, `geuneda-notice`, `geuneda-coupon`, `geuneda-webview`
