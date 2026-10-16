# Geuneda Frameworks (Unity)

Geuneda Unity Package Manager(UPM) 패키지 27개를 개발, 테스트, 검증하는 Unity 호스트 프로젝트입니다. 각 패키지는 별도 git 레포지토리이고, 이 레포에는 `Packages/com.geuneda.*` 아래 git 서브모듈로 들어 있습니다. 패키지별 Claude Code 스킬이 `claude-skills/` 에 함께 있습니다(애플·구글 제공자 패키지는 account 스킬, 분석 벤더 어댑터는 analytics 스킬, Unity IAP 어댑터는 iap 스킬, MAX 어댑터는 ads 스킬이 함께 다룹니다).

## 어디부터 읽으면 되나

| 하려는 일 | 읽을 문서 |
|-----------|-----------|
| 어떤 패키지가 있고 무엇에 쓰는지 알기 | 이 문서의 [패키지 목록](#패키지-목록) |
| 내 Unity 프로젝트에 패키지 설치 | 이 문서의 [설치](#설치), 그다음 해당 패키지의 `README.md` |
| 패키지 API 사용법 | 각 패키지의 `README.md`(services, uiservice 는 `docs/` 도 있음) |
| Claude Code 가 패키지 API 를 알게 하기 | 이 문서의 [Claude Code 스킬](#claude-code-스킬) |
| 프레임워크를 쓰는 프로젝트의 공통 코딩 규칙 | [CLAUDE.md](CLAUDE.md) |
| 이 레포에서 패키지 개발/기여 | [CONTRIBUTING.md](CONTRIBUTING.md) |
| AI 에이전트로 이 레포 작업 | [AGENTS.md](AGENTS.md) |

## 패키지 목록

버전과 최소 Unity 버전은 각 패키지의 `package.json` 값입니다(2026-10-14 기준). 바뀌었을 수 있으니 정확한 값은 `package.json` 을 확인하세요.

| 패키지 | 버전 | 최소 Unity | 하는 일 | 문서 |
|--------|------|-----------|---------|------|
| `com.geuneda.core` | 0.4.0 | 2021.3 | 다른 패키지가 함께 쓰는 바닥 패키지(의존성 없음). 모듈별 로거, 결과 규약(`Result`), 빌드 환경(`AppEnv`), 메인 스레드 디스패처, 설정 에셋 로더, 설치·기기 ID, 보안 저장소, 결정론적 난수(`Pcg32`), 기기 시계 변경에 영향받지 않고 잠든 동안에도 흐르는 단조 시계(`MonotonicClock`) | [README](Packages/com.geuneda.core/README.md) |
| `com.geuneda.http` | 0.1.0 | 2021.3 | UnityWebRequest HTTP 클라이언트. 미들웨어 체인, `Result<HttpResponse>`(연결 실패·타임아웃·취소는 코드), JSON 편의 메서드, 선택형 타임아웃·재시도 | [README](Packages/com.geuneda.http/README.md) |
| `com.geuneda.realtime` | 0.2.0 | 2021.3 | WebSocket 실시간 RPC 클라이언트. single-flight 연결, 연결마다 재로그인, 지수 백오프 재연결, 요청 ID 매칭, 서버 푸시, 핑퐁, 교체 가능한 직렬화(JSON 기본, MessagePack 선택). `[RpcService]` 계약에서 클라이언트 프록시·서버 라우트를 만드는 소스 생성기와 ASP.NET Core 서버(`Server~/`) | [README](Packages/com.geuneda.realtime/README.md) |
| `com.geuneda.account` | 0.2.0 | 2021.3 | 계정 인증과 앱 세션. 게스트 로그인과 제공자 등록, refresh 토큰은 보안 저장소·access 토큰은 메모리(재발급 single-flight), 게임 서버 요청용 토큰 미들웨어, 연동·충돌·옮겨오기·해제·계정 삭제, 다음 세션 ID 예약과 대칭 세션 이벤트. ASP.NET Core 인증 서버(`Server~/`: JWT, refresh 회전·재사용 감지, 애플·구글 id 토큰 검증) | [README](Packages/com.geuneda.account/README.md) |
| `com.geuneda.account.apple` | 0.1.0 | 2021.3 | account 의 Sign in with Apple 제공자(iOS 13+, ASAuthorizationController 네이티브 플러그인, Sign in with Apple capability 빌드 후처리). 설치한 게임에만 네이티브 코드가 들어감 | [README](Packages/com.geuneda.account.apple/README.md) |
| `com.geuneda.account.google` | 0.1.0 | 2021.3 | account 의 Google 로그인 제공자. Android 는 Credential Manager(Gradle 의존성을 담은 Android 라이브러리 플러그인), iOS 는 SDK 없이 ASWebAuthenticationSession + OAuth PKCE | [README](Packages/com.geuneda.account.google/README.md) |
| `com.geuneda.appsetting` | 0.2.0 | 2021.3 | 원격 앱 설정. 서명된 설정 문서(RSA-3072 PKCS#1 SHA-256)를 받아 검증하고, 앱 버전별 노드(`*` 기본 노드)의 플랫폼별 상태·점검 공지·서버 주소·기능 플래그로 접속 판정(열림·내부·점검·업데이트 필요), 리소스 매니페스트(카테고리별 버전·크기·SHA-256·URL). ETag 조건부 요청, 갱신 single-flight, 낮은 판 무시. 서명 CLI 와 ASP.NET Core 배포 헬퍼(`Server~/`) | [README](Packages/com.geuneda.appsetting/README.md) |
| `com.geuneda.resource` | 0.1.0 | 2021.3 | 원격 리소스(테이블 등 데이터 파일) 캐시. 매니페스트 항목의 크기·SHA-256 으로 캐시 파일을 판정하고 맞지 않는 것만 받아 검증 후 원자적 저장(임시 파일 → 이름 바꾸기), 새 버전 저장 뒤 옛 버전 삭제, 동시 다운로드 수 제한, 받기 전 총 용량 확인, 진행률. 파일 입출력·해시는 스레드 풀 | [README](Packages/com.geuneda.resource/README.md) |
| `com.geuneda.servertime` | 0.1.0 | 6000.3 | 서버 시간 동기화. 시간 원천(NTP 기본 `time.google.com`, HTTPS `Date` 헤더, 직접 구현)을 순서대로 시도해 왕복 지연을 보정한 서버 시각을 services 시간 서비스의 기준점으로 넣음. 실패하면 지수 백오프로 재시도, 성공하면 30분마다, 앱이 포그라운드로 돌아오면 바로 다시 맞춤. 현재 시각은 core 단조 시계로 진행해 기기 시계를 바꿔도 영향받지 않음 | [README](Packages/com.geuneda.servertime/README.md) |
| `com.geuneda.analytics` | 0.2.0 | 2021.3 | 분석 이벤트 로깅. 기록 시점의 공통 맥락(시각, 순번, 세션, 사용자, 앱)을 담은 이벤트를 비트로 고른 sink(콘솔, 자사 수집, 벤더 어댑터 패키지)마다 따로 큐에 넣어 보내고, 실패한 sink 의 배치만 디스크에 저장해 그 sink 로만 다시 보냄(백오프, 포그라운드 복귀, 네트워크 복구, 다음 실행). http 가 있으면 자사 수집 배치 sink, account 가 있으면 세션 ID·세션 이벤트. ASP.NET Core 수집 서버(`Server~/`: 이벤트별 검증, ID 중복 제거). 구매·광고 노출 수익 표준 이벤트 | [README](Packages/com.geuneda.analytics/README.md) |
| `com.geuneda.analytics.firebase` | 0.1.0 | 2021.3 | analytics 의 Firebase Analytics sink. 이름 규칙(40자, 예약 접두사·이름), 파라미터 25개·값 100자, 표준 이벤트 → `purchase`(상품 목록)·`ad_impression`, `MarkReady` 로 준비. Firebase Unity SDK 가 있는 게임만 설치 | [README](Packages/com.geuneda.analytics.firebase/README.md) |
| `com.geuneda.analytics.airbridge` | 0.1.0 | 2021.3 | analytics 의 Airbridge sink. 카테고리·시맨틱/커스텀 속성, 표준 이벤트 → 주문 완료·광고 노출(AppLovin 파트너 상세). Airbridge Unity SDK 가 있는 게임만 설치 | [README](Packages/com.geuneda.analytics.airbridge/README.md) |
| `com.geuneda.analytics.appsflyer` | 0.1.0 | 2023.1 | analytics 의 AppsFlyer sink(플러그인 7.x). 값은 문자열, 표준 이벤트 → `af_purchase`·`logAdRevenue`(미디에이션 선택), `MarkReady` 로 준비. AppsFlyer 플러그인이 있는 게임만 설치 | [README](Packages/com.geuneda.analytics.appsflyer/README.md) |
| `com.geuneda.analytics.facebook` | 0.1.0 | 2021.3 | analytics 의 Facebook(Meta) App Events sink. 이름 규칙, 표준 이벤트 → `FB.LogPurchase`·`AdImpression`, `FB.IsInitialized` 로 준비. Facebook SDK 가 있는 게임만 설치 | [README](Packages/com.geuneda.analytics.facebook/README.md) |
| `com.geuneda.iap` | 0.3.0 | 2021.3 | 인앱 결제. 게임의 지급자(서버 지급)가 지급을 확인한 뒤에만 스토어 거래를 닫아 결제 후 지급 누락을 막음(지급 재시도 백오프, 초기화·복귀·복구 때 스토어 재조회, 늦게 온 결제 지급, 중복 거래·같은 상품 미확정 주문 먼저 지급, 확정만 재시도). 결과 코드 7000 블록, 지급 실패 이벤트, analytics 가 있으면 확정한 구매만 매출 기록, http 가 있으면 결제 서버 지급자. `Server~` 에 ASP.NET Core 결제 서버(Google Play·App Store 영수증 검증, 영수증 유일성 원장, 지급 엔드포인트, 서버 알림의 환불 회수·구독 상태) | [README](Packages/com.geuneda.iap/README.md) |
| `com.geuneda.iap.unity` | 0.1.0 | 2022.3 | iap 의 Unity IAP 5.4.4(`StoreController`) 어댑터. 자동 재전달·조회 재시도 끄기, 실패 이유 멤버별 대응, App Store 거래 서명(JWS) 전달 | [README](Packages/com.geuneda.iap.unity/README.md) |
| `com.geuneda.ads` | 0.1.0 | 2021.3 | 보상형·전면 광고. 표시 요청마다 결과 하나(보상 받음은 성공, 보상 없이 닫음·표시 실패·시간 초과·준비 안 됨은 결과 코드 8000 블록), 닫힘 콜백이 없으면 앱이 앞에 있는 시간으로 시간 초과 판정(표시 콜백 없음, 광고가 앱을 멈추는 미디에이션의 복귀 뒤, 절대 5분), 시간 초과 뒤 늦은 보상 이벤트, 앞 광고의 늦은 콜백을 광고 식별 값으로 거름, 로드 실패 2초→30초 백오프. analytics 가 있으면 노출 수익 기록 | [README](Packages/com.geuneda.ads/README.md) |
| `com.geuneda.ads.max` | 0.1.0 | 2021.3 | ads 의 AppLovin MAX(8.6.3 이상) 어댑터. 단위 거르기, 만료 광고 재로드를 새 로드로, 광고 식별 값, 모르는 수익(-1)은 null. MAX 가 있을 때만 컴파일(`versionDefines`) | [README](Packages/com.geuneda.ads.max/README.md) |
| `com.geuneda.gamedata` | 1.2.0 | 6000.0 | Observable 데이터(필드/리스트/딕셔너리 등), `ComputedField`, `ConfigsProvider` 설정 저장소, 결정론적 부동소수점 `floatP`, 메모리 변조 감지 보안 값(`SecureInt` 등), 직렬화 헬퍼 | [README](Packages/com.geuneda.gamedata/README.md) |
| `com.geuneda.services` | 5.1.0 | 6000.3 | 서비스 로케이터(`MainInstaller`), 메시지 브로커, 틱, 코루틴, 오브젝트 풀, 데이터 저장, RNG(PCG32), 시간(단조 시계 기준점, 서버 시각 기준), 커맨드, 버전 정보, Addressables 에셋 로딩/임포트 | [README](Packages/com.geuneda.services/README.md), [docs](Packages/com.geuneda.services/docs/README.md) |
| `com.geuneda.uiservice` | 2.0.0 | 6000.0 | UI 열기/닫기/로드/언로드, UI Set, 프레젠터 피처 조합, UI Toolkit 지원, 다중 인스턴스, 뒤로가기, 팝업 큐, 모달 dim, 입력 차단 | [README](Packages/com.geuneda.uiservice/README.md), [docs](Packages/com.geuneda.uiservice/docs/README.md) |
| `com.geuneda.statechart` | 0.10.0 | 2022.3 | 계층적 상태 머신(Statechart) | [README](Packages/com.geuneda.statechart/README.md) |
| `com.geuneda.inputextensions` | 1.0.4 | 2019.4 | Input System 기반 포인터 드래그, 스와이프/탭 제스처, 게임패드 입력 | [README](Packages/com.geuneda.inputextensions/README.md) |
| `com.geuneda.nativeui` | 0.2.8 | 2020.3 | iOS/Android 네이티브 알림 팝업과 토스트 메시지 | [README](Packages/com.geuneda.nativeui/README.md) |
| `com.geuneda.notificationservice` | 0.2.0 | 2021.3 | Unity Mobile Notifications 기반 모바일 로컬 알림 예약/취소/해제 | [README](Packages/com.geuneda.notificationservice/README.md) |
| `com.geuneda.googlesheetimporter` | 0.10.0 | 6000.0 | Google 스프레드시트 데이터를 ScriptableObject 설정 데이터로 가져오는 에디터 도구 | [README](Packages/com.geuneda.googlesheetimporter/README.md) |
| `com.geuneda.gamesystems` | 0.3.0 | 6000.3 | 여러 게임에서 반복되는 게임 시스템 모음. 기능마다 asmdef 가 나뉨(현재 레드닷: 일괄 변경, 늦은 바인딩 추적, 디버그 창) | [README](Packages/com.geuneda.gamesystems/README.md) |

레포지토리 URL 은 모두 `https://github.com/geuneda/<레포>.git` 형식이고, 레포 이름은 패키지 이름의 `com.geuneda.` 를 `geuneda-` 로 바꾸고 나머지 점을 `-` 로 바꾼 것입니다(예: `com.geuneda.services` -> `geuneda-services`, `com.geuneda.account.apple` -> `geuneda-account-apple`).

### 없어지거나 합쳐진 패키지

- `com.geuneda.assetsimporter`: services v2.0.0 에 흡수되었습니다(`AssetResolverService`, `Geuneda.Services.AssetsImporter` 네임스페이스, AddressableIds 생성기). 별도 패키지로 추가하지 않습니다. 마이그레이션은 [services MIGRATION.md](Packages/com.geuneda.services/MIGRATION.md) 를 참고하세요.
- 예전 DataExtensions / ConfigsProvider 패키지: gamedata 로 합쳐졌습니다. 런타임 네임스페이스는 `Geuneda.DataExtensions`, 어셈블리 이름은 `Geuneda.GameData` 입니다.

## 의존성

Geuneda 패키지끼리의 의존 관계입니다(`package.json` 과 asmdef 기준).

```
core
  ├── services (gamedata 에도 의존)
  ├── http
  │     ├── account
  │     │     ├── account.apple
  │     │     └── account.google (http 에도 의존)
  │     ├── appsetting
  │     ├── resource
  │     └── servertime (services 에도 의존)
  ├── realtime
  └── analytics (http·account 는 선택: 있으면 해당 asmdef 가 켜짐)
        └── analytics.firebase, analytics.airbridge, analytics.appsflyer, analytics.facebook (벤더 SDK 필요)
  └── iap (analytics 는 선택: 있으면 매출 기록 asmdef 가 켜짐)
        └── iap.unity (Unity IAP 5.4.4)
  └── ads (analytics 는 선택: 있으면 노출 수익 기록 asmdef 가 켜짐)
        └── ads.max (AppLovin MAX 가 있을 때만 컴파일)
gamedata
  ├── services
  │     └── gamesystems
  └── googlesheetimporter

uiservice, statechart, inputextensions, nativeui, notificationservice: 다른 Geuneda 패키지에 의존하지 않음
```

`core` 는 다른 패키지가 함께 쓰는 바닥 패키지이고 어떤 Geuneda 패키지에도 의존하지 않습니다. 지금은 services(빌드 환경 `AppEnv`, RNG 생성기 `Pcg32`, 단조 시계 `MonotonicClock`), http 와 realtime(결과 규약 `Result`), account 와 그 제공자 패키지(보안 저장소, 결과 규약), appsetting 과 resource(결과 규약, 로거), servertime(결과 규약, 로거, 단조 시계), analytics(로거, 설치 ID, 빌드 환경, 단조 시계), iap 과 ads(결과 규약, 로거, 단조 시계, 메인 스레드 디스패처)가 참조하며, 기존 패키지의 로그를 옮길 때 다른 패키지에도 의존성을 추가합니다.

외부 의존성(`package.json` 에 선언된 최소 버전):

| 패키지 | 외부 의존성 |
|--------|-------------|
| gamedata | `com.unity.nuget.newtonsoft-json` 3.2.1, `com.cysharp.unitask` 2.5.10, `com.unity.ugui` 2.0.0 |
| services | `com.geuneda.core` 0.4.0, `com.geuneda.gamedata` 1.0.0, `com.unity.addressables` 1.21.20, `com.cysharp.unitask` 2.5.10 |
| uiservice | `com.unity.addressables` 2.6.0, `com.cysharp.unitask` 2.5.10, `com.unity.ugui` 2.0.0 (선택: `com.unity.inputsystem`) |
| statechart | `com.cysharp.unitask` 2.5.10 |
| inputextensions | `com.unity.inputsystem` 1.1.1, `com.unity.ugui` 1.0.0 |
| core | 없음 |
| http | `com.geuneda.core` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1, `com.unity.modules.unitywebrequest` 1.0.0 |
| realtime | `com.geuneda.core` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1. 선택: `org.nuget.messagepack` 3.x(+ `org.nuget.microsoft.net.stringtools`) |
| account | `com.geuneda.core` 0.2.0, `com.geuneda.http` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1 |
| account.apple | `com.geuneda.account` 0.1.0, `com.geuneda.core` 0.2.0, `com.cysharp.unitask` 2.5.10 |
| account.google | `com.geuneda.account` 0.1.0, `com.geuneda.core` 0.2.0, `com.geuneda.http` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1. Android Gradle: `androidx.credentials` 1.3.0, `googleid` 1.1.1, `androidx.core` 1.8.0, `androidx.loader` 1.0.0 |
| appsetting | `com.geuneda.core` 0.2.0, `com.geuneda.http` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1 |
| resource | `com.geuneda.core` 0.2.0, `com.geuneda.http` 0.1.0, `com.cysharp.unitask` 2.5.10 |
| servertime | `com.geuneda.core` 0.4.0, `com.geuneda.services` 5.0.0, `com.geuneda.http` 0.1.0, `com.cysharp.unitask` 2.5.10 |
| analytics | `com.geuneda.core` 0.4.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1. 선택: `com.geuneda.http` 0.1.0 이상(자사 수집), `com.geuneda.account` 0.1.0 이상(세션 연동) |
| analytics.firebase·airbridge·appsflyer·facebook | `com.geuneda.analytics` 0.2.0, `com.geuneda.core` 0.4.0, `com.cysharp.unitask` 2.5.10. 벤더 SDK 는 게임이 먼저 설치(Firebase Unity SDK, Airbridge Unity SDK 4.x, AppsFlyer Unity 플러그인 7.x, Facebook SDK for Unity) |
| iap | `com.geuneda.core` 0.4.0, `com.cysharp.unitask` 2.5.10. 선택: `com.geuneda.analytics` 0.2.0 이상(매출 기록), `com.geuneda.http` 0.1.0 이상(결제 서버 지급자). 결제 서버는 .NET 10 |
| iap.unity | `com.geuneda.iap` 0.1.0, `com.geuneda.core` 0.4.0, `com.cysharp.unitask` 2.5.10, `com.unity.purchasing` 5.4.4 |
| ads | `com.geuneda.core` 0.4.0, `com.cysharp.unitask` 2.5.10. 선택: `com.geuneda.analytics` 0.2.0 이상(노출 수익 기록) |
| ads.max | `com.geuneda.ads` 0.1.0. AppLovin MAX(`com.applovin.mediation.ads` 8.6.3 이상)는 게임이 AppLovin 레지스트리로 설치(의존성 아님) |
| nativeui | 없음 |
| notificationservice | `com.unity.mobile.notifications` 2.4.2 |
| googlesheetimporter | `com.unity.nuget.newtonsoft-json` 2.0.0, `com.geuneda.gamedata` 1.0.0 |
| gamesystems | `com.geuneda.services` 5.1.0 |

호스트 프로젝트는 Unity 6000.3.2f1 에서 Addressables 2.7.6, Input System 1.17.0, Mobile Notifications 2.4.2, Test Framework 1.6.0, uGUI 2.0.0 으로 검증합니다(`Packages/manifest.json`, `ProjectSettings/ProjectVersion.txt`). 패키지별 최소 Unity 버전은 서로 다르지만 이 호스트에서 함께 검증하는 버전은 6000.3 입니다.

## 설치

### 내 Unity 프로젝트에 패키지 추가

`Packages/manifest.json` 의 `dependencies` 에 git URL 을 넣거나, Unity 에서 **Window > Package Manager > + > Add package from git URL...** 로 같은 URL 을 입력합니다.

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

UPM 은 git URL 로만 받을 수 있는 의존성을 자동으로 설치하지 못합니다. 다음 의존성은 직접 함께 추가해야 합니다.

| 설치하는 패키지 | 같이 추가할 패키지 |
|----------------|-------------------|
| gamedata, uiservice, statechart | UniTask |
| services | UniTask, gamedata, core |
| googlesheetimporter | gamedata, UniTask(gamedata 의존성) |
| gamesystems | services, gamedata, core, UniTask |
| http | core, UniTask |
| realtime | core, UniTask(MessagePack 을 쓰면 UnityNuGet 레지스트리와 `org.nuget.messagepack`, `org.nuget.microsoft.net.stringtools`) |
| account | core, http, UniTask |
| account.apple, account.google | account, core, http, UniTask |
| appsetting | core, http, UniTask |
| resource | core, http, UniTask |
| servertime | services, gamedata, core, http, UniTask |
| analytics | core, UniTask(자사 수집을 쓰면 http, 세션 연동을 쓰면 account 와 그 의존성) |
| analytics.firebase·airbridge·appsflyer·facebook | analytics, core, UniTask, 그 벤더 SDK |
| iap | core, UniTask(매출 기록을 쓰면 analytics) |
| iap.unity | iap, core, UniTask(Unity IAP 는 레지스트리에서 자동 설치) |
| ads | core, UniTask(노출 수익 기록을 쓰면 analytics) |
| ads.max | ads, core, UniTask, AppLovin MAX |

Unity 레지스트리에 있는 의존성(Addressables, Newtonsoft Json, Input System, Mobile Notifications 등)은 자동으로 설치됩니다.

특정 버전으로 고정하려면 URL 끝에 `#<태그>` 를 붙입니다. 레포의 git 태그가 `package.json` 버전과 맞지 않는 경우가 있으니, 고정하기 전에 해당 레포에 그 태그가 실제로 있는지 확인하세요.

### 이 호스트 프로젝트 전체 받기

```bash
git clone --recurse-submodules https://github.com/geuneda/geuneda-frameworks.git
```

이미 클론했다면 `git submodule update --init --recursive` 로 서브모듈을 받습니다. 개발 워크플로우는 [CONTRIBUTING.md](CONTRIBUTING.md) 를 보세요.

## 프로젝트 구조

```
geuneda-frameworks/
├── Assets/                 # 호스트 프로젝트 에셋 (Addressables 설정, TextMesh Pro 리소스, 테스트용 에셋)
├── Packages/
│   ├── manifest.json       # 호스트 프로젝트 의존성
│   └── com.geuneda.*/      # 패키지 25개, 각각 git 서브모듈 (.gitmodules)
├── ProjectSettings/        # Unity 설정 (ProjectVersion.txt: 6000.3.2f1)
├── UserSettings/
├── claude-skills/
│   ├── install.sh          # 스킬 설치
│   ├── uninstall.sh        # 스킬 제거
│   ├── geuneda-frameworks/ # 프레임워크 전체 스킬
│   └── geuneda-<패키지>/    # 패키지별 스킬 18개
├── .gitmodules
├── AGENTS.md               # AI 에이전트용 레포 가이드
├── CLAUDE.md               # 프레임워크를 쓰는 프로젝트의 공용 규칙
├── CONTRIBUTING.md         # 개발/기여 가이드
├── CODE_OF_CONDUCT.md
├── LICENSE
└── README.md
```

벤더 어댑터 패키지(analytics.firebase 등)는 호스트에 벤더 SDK 가 없어 컴파일되지 않도록 `ProjectSettings` 의 Scripting Define Symbols(Android, iPhone, Standalone, Server, WebGL)에 `GEUNEDA_SKIP_VENDOR_ADAPTERS` 를 둡니다. 다른 빌드 타깃으로 바꾸려면 그 타깃에도 같은 define 을 넣습니다. 어댑터 검증은 SDK 를 넣은 별도 프로젝트에서 합니다([CONTRIBUTING.md](CONTRIBUTING.md#테스트)).

`Packages/manifest.json` 은 Geuneda 패키지를 git URL 로 선언하지만, `Packages/` 아래에 같은 이름의 폴더(서브모듈)가 있으면 Unity 는 그 폴더를 임베디드 패키지로 우선 사용합니다. 그래서 호스트에서는 서브모듈 작업본이 컴파일됩니다.

## Claude Code 스킬

`claude-skills/` 에는 패키지별 스킬 19개와 프레임워크 전체 스킬 `geuneda-frameworks` 가 있습니다. 애플·구글 제공자 패키지는 `geuneda-account`, 분석 벤더 어댑터는 `geuneda-analytics`, Unity IAP 어댑터는 `geuneda-iap`, MAX 어댑터는 `geuneda-ads` 스킬이 함께 다룹니다. 스킬을 설치하면 Claude Code 가 패키지 API, 사용 패턴, 주의사항을 참고해 코드를 작성합니다.

| 스킬 | 대상 |
|------|------|
| `geuneda-frameworks` | 프레임워크 전체 구조, 패키지 간 의존성, 개발/테스트 방법 |
| `geuneda-gamedata` | com.geuneda.gamedata |
| `geuneda-services` | com.geuneda.services |
| `geuneda-uiservice` | com.geuneda.uiservice |
| `geuneda-statechart` | com.geuneda.statechart |
| `geuneda-inputextensions` | com.geuneda.inputextensions |
| `geuneda-nativeui` | com.geuneda.nativeui |
| `geuneda-notificationservice` | com.geuneda.notificationservice |
| `geuneda-googlesheetimporter` | com.geuneda.googlesheetimporter |
| `geuneda-gamesystems` | com.geuneda.gamesystems |
| `geuneda-core` | com.geuneda.core |
| `geuneda-http` | com.geuneda.http |
| `geuneda-realtime` | com.geuneda.realtime |
| `geuneda-account` | com.geuneda.account, com.geuneda.account.apple, com.geuneda.account.google |
| `geuneda-appsetting` | com.geuneda.appsetting |
| `geuneda-resource` | com.geuneda.resource |
| `geuneda-servertime` | com.geuneda.servertime |
| `geuneda-analytics` | com.geuneda.analytics, com.geuneda.analytics.firebase·airbridge·appsflyer·facebook |
| `geuneda-iap` | com.geuneda.iap, com.geuneda.iap.unity |
| `geuneda-ads` | com.geuneda.ads, com.geuneda.ads.max |

어떤 코드에서 어떤 스킬을 써야 하는지는 [CLAUDE.md](CLAUDE.md) 의 네임스페이스 매핑 표를 따릅니다.

### 설치와 제거

스크립트는 자기 위치를 기준으로 동작하므로 어느 디렉터리에서 실행해도 됩니다.

```bash
claude-skills/install.sh                     # 스킬 19개 모두 설치
claude-skills/install.sh geuneda-services    # 하나만 설치
claude-skills/uninstall.sh                   # 스킬 19개 모두 제거
claude-skills/uninstall.sh geuneda-services  # 하나만 제거
```

- 설치 위치는 사용자 전역 `~/.claude/skills/<스킬>/` 입니다. 스킬 폴더 내용을 그대로 복사해 덮어씁니다. 원본에서 지운 파일은 설치 위치에 남으므로 깨끗하게 바꾸려면 제거한 뒤 다시 설치하세요.
- 제거는 `~/.claude/skills/<스킬>/` 폴더를 지웁니다. 설치되어 있지 않으면 건너뜁니다.
- 설치나 제거 후에는 Claude Code 를 다시 시작해야 반영됩니다.

### 스킬 폴더 구성

```
geuneda-<패키지>/
├── SKILL.md          # 스킬 메타데이터(frontmatter), API 요약, 사용 패턴, 주의사항
├── references/
│   └── api.md        # 소스 기준 상세 API 레퍼런스
└── evals/            # (일부 스킬만) 스킬 평가용 프롬프트와 채점 기준
```

## 라이선스

MIT License. 루트 [LICENSE](LICENSE) 를 따르며, `Packages/` 아래 각 패키지는 자체 라이선스 파일을 가질 수 있습니다.
