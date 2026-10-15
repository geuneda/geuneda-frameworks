# 기여 가이드

Geuneda 패키지 개선에 참여해 주셔서 감사합니다.

이 레포는 `Packages/` 아래에 Geuneda UPM 패키지 25개를 git 서브모듈로 포함하는 Unity 호스트 프로젝트입니다. 패키지 목록과 의존성은 [README.md](README.md) 를 보세요.

## 기여 위치

- **패키지 변경**: `Packages/com.geuneda.<패키지>/` 는 각각 독립 레포(`https://github.com/geuneda/geuneda-<패키지>.git`)입니다. 변경은 그 패키지 레포에 커밋하고 PR 을 보냅니다.
- **호스트 프로젝트 변경**: Unity 프로젝트 설정, `Assets/`, 루트 문서, `claude-skills/`, 서브모듈 포인터 갱신은 이 레포에 커밋합니다.

## 설정

### 클론

```bash
git clone --recurse-submodules https://github.com/geuneda/geuneda-frameworks.git
```

이미 클론했거나 `Packages/com.geuneda.*` 폴더가 비어 있으면:

```bash
git submodule update --init --recursive
```

### Unity 버전

호스트 프로젝트는 Unity 6000.3.2f1 입니다(`ProjectSettings/ProjectVersion.txt`). services, servertime, gamesystems 의 최소 버전이 6000.3 이므로 6000.3 이상 에디터로 엽니다.

## 서브모듈 워크플로우

`git submodule update` 직후 서브모듈은 호스트가 기록한 커밋에 detached HEAD 상태로 있습니다. 패키지를 고치기 전에 브랜치로 전환합니다. 기본 브랜치는 core, http, realtime, account, account.apple, account.google, appsetting, resource, servertime, analytics, analytics.firebase, analytics.airbridge, analytics.appsflyer, analytics.facebook, iap, iap.unity, gamesystems 가 `main` 이고 나머지 8개는 `master` 입니다.

```bash
cd Packages/com.geuneda.services
git checkout master
git pull
# 변경, 커밋, 패키지 레포에 push
```

패키지 레포에 push 한 뒤에는 호스트 레포에서 바뀐 서브모듈 포인터를 커밋합니다.

```bash
cd <호스트 레포 루트>
git add Packages/com.geuneda.services
git commit -m "chore: services 포인터 갱신"
```

모든 서브모듈을 각 원격 기본 브랜치의 최신 커밋으로 옮기려면 `git submodule update --remote` 를 쓰고, 마찬가지로 포인터 변경을 커밋합니다.

## 코딩 표준

- **C#**: C# 9.0 문법
- **네임스페이스**: 명시적 네임스페이스 사용 (global usings 사용 금지)
- **Runtime vs Editor**:
  - Runtime 코드에서 `UnityEditor` 를 참조하면 안 됩니다
  - Editor 도구는 `Editor/` 폴더와 Editor 전용 asmdef 에 둡니다
- **비동기**: 비동기 흐름이 필요한 패키지는 UniTask 를 씁니다
- **의존성**: 패키지 간 순환 의존은 금지합니다. 새 의존성은 `package.json` 의 `dependencies` 와 asmdef 의 `references` 양쪽에 반영합니다
- 프레임워크를 쓰는 게임 코드의 설계 규칙은 [CLAUDE.md](CLAUDE.md) 를 따릅니다

## 테스트

테스트는 Unity Test Framework 로 작성하고 **Window > General > Test Runner** 의 EditMode / PlayMode 탭에서 실행합니다.

| 패키지 | 테스트 asmdef |
|--------|---------------|
| core | `Tests/EditMode` (`Geuneda.Core.Tests.EditMode`), `Tests/PlayMode` (`Geuneda.Core.Tests.PlayMode`) |
| http | `Tests/EditMode` (`Geuneda.Http.Tests.EditMode`), `Tests/PlayMode` (`Geuneda.Http.Tests.PlayMode`, 로컬 HttpListener) |
| realtime | `Tests/EditMode` (`Geuneda.Realtime.Tests.EditMode`, 가짜 전송과 로컬 TcpListener WebSocket 서버, 생성된 클라이언트, `[Explicit]` 샘플 서버 상호 운용), `Tests/MessagePack` (`Geuneda.Realtime.MessagePack.Tests.EditMode`, MessagePack 이 있을 때만). 서버·생성기는 `dotnet test "Packages/com.geuneda.realtime/Server~/Geuneda.Realtime.Server.slnx"`(.NET 10 SDK) |
| account | `Tests/EditMode` (`Geuneda.Account.Tests.EditMode`, 가짜 인증 서버 전송, `[Explicit]` 샘플 서버 상호 운용). 서버는 `dotnet test "Packages/com.geuneda.account/Server~/Geuneda.Account.Server.slnx"`(.NET 10 SDK) |
| account.apple | `Tests/EditMode` (`Geuneda.Account.Apple.Tests.EditMode`, 상태 변환·에디터 동작). 실기 확인은 iOS 빌드 |
| account.google | `Tests/EditMode` (`Geuneda.Account.Google.Tests.EditMode`, PKCE·토큰 교환 가짜 전송·설정 검사). 실기 확인은 Android·iOS 빌드 |
| appsetting | `Tests/EditMode` (`Geuneda.AppSetting.Tests.EditMode`, 봉투·서명, 본문 규칙(리소스 매니페스트 이름·크기·해시·주소 포함), 접속 판정, 가짜 문서 서버로 갱신, .NET CLI 가 RSA-3072 로 서명한 픽스처, `[Explicit]` 샘플 서버 상호 운용). 서명 라이브러리·CLI·배포 헬퍼는 `dotnet test "Packages/com.geuneda.appsetting/Server~/Geuneda.AppSetting.Server.slnx"`(.NET 10 SDK) |
| resource | `Tests/EditMode` (`Geuneda.Resource.Tests.EditMode`, 가짜 파일 서버와 같은 스레드 작업자로 캐시 판정·검증 후 저장·옛 버전 삭제·동시 다운로드 제한·취소, 항목 규칙, 로컬 HttpListener 와 실제 UnityWebRequest·스레드 풀로 받기) |
| servertime | `Tests/EditMode` (`Geuneda.ServerTime.Tests.EditMode`, NTP 패킷 생성·검증·왕복 보정, 127.0.0.1 가짜 UDP 서버로 실제 소켓, 가짜 `IHttpClient` 와 로컬 HttpListener·실제 UnityWebRequest 로 `HEAD` 의 `Date`, 가짜 원천·시계·지연으로 원천 순서·백오프·재동기화·포그라운드 복귀). 실기 확인은 Android·iOS 빌드 |
| analytics | `Tests/EditMode` (`Geuneda.Analytics.Tests.EditMode`, 가짜 단조 시계·수동 지연·기록 sink 로 맥락·팬아웃·준비 대기·재시도 저장·백오프·일시정지 저장·복귀·상한·손상 파일), `Tests/EditMode/Collector` (`Geuneda.Analytics.Collector.Tests.EditMode`, http 가 있을 때, 가짜 전송, `[Explicit]` 샘플 서버 상호 운용), `Tests/EditMode/Account` (`Geuneda.Analytics.Account.Tests.EditMode`, account 가 있을 때), `Tests/PlayMode` (`Geuneda.Analytics.Tests.PlayMode`, 숨은 수명 컴포넌트). 서버는 `dotnet test "Packages/com.geuneda.analytics/Server~/Geuneda.Analytics.Server.slnx"`(.NET 10 SDK) |
| analytics.firebase·airbridge·appsflyer·facebook | `Tests/EditMode` (`Geuneda.Analytics.Firebase.Tests.EditMode` 등, SDK 호출을 기록하는 대역으로 변환 확인). 호스트에는 벤더 SDK 가 없어 `GEUNEDA_SKIP_VENDOR_ADAPTERS` define 으로 컴파일하지 않습니다. 벤더 SDK(Firebase, Airbridge, AppsFlyer 7.x, Facebook + uGUI)를 넣은 별도 프로젝트에서 테스트와 Android·iOS 플레이어 스크립트 컴파일로 확인합니다 |
| iap | `Tests/EditMode` (`Geuneda.Iap.Tests.EditMode`, 가짜 스토어·지급자·수동 지연으로 지급 순서·재시도·늦은 결제·중복 거래·복구·종료), `Tests/EditMode/Analytics` (`Geuneda.Iap.Analytics.Tests.EditMode`, analytics 가 있을 때) |
| iap.unity | `Tests/EditMode` (`Geuneda.Iap.Unity.Tests.EditMode`, 대응표), `Tests/PlayMode` (`Geuneda.Iap.Unity.Tests.PlayMode`, Unity IAP 가짜 스토어로 전 과정. scripting define `IAP_FAKE_STORE_DEFAULT` 가 없으면 건너뜀) |
| gamedata | `Tests/Editor` (`Geuneda.GameData.Editor.Tests`), `Tests/PlayMode` (`Geuneda.GameData.PlayMode.Tests`) |
| services | `Tests/EditMode` (`Geuneda.Services.Editor.Tests`), `Tests/PlayMode` (`Geuneda.Services.Tests.Playmode`) |
| uiservice | `Tests/EditMode` (`Geuneda.UiService.Tests`), `Tests/PlayMode` (`Geuneda.UiService.Tests.PlayMode`) |
| statechart | `Tests/Editor` (`Geuneda.Statechart.Editor.Tests`) |
| googlesheetimporter | `Tests/Editor` (`Geuneda.GoogleSheetImporter.Editor.Tests`) |
| gamesystems | `Tests/EditMode` (`Geuneda.GameSystems.Tests.EditMode`), `Tests/PlayMode` (`Geuneda.GameSystems.Tests.PlayMode`) |
| notificationservice | `Tests/PlayMode` (`Geuneda.NotificationService.Tests.PlayMode`) |

inputextensions, nativeui 에는 테스트가 없습니다. 패키지 테스트가 Test Runner 에 보이지 않으면 `Packages/manifest.json` 의 `testables` 에 패키지 이름을 추가합니다.

### 테스트 의존성

gamedata, services, statechart, uiservice 테스트와 realtime 의 MessagePack 테스트는 아래 라이브러리가 있어야 컴파일됩니다. 호스트 `Packages/manifest.json` 에 들어 있습니다.

| 라이브러리 | 패키지 | 쓰는 곳 |
|------------|--------|---------|
| Unity Performance Testing | `com.unity.test-framework.performance` | `[Performance]` 테스트 (gamedata, services, uiservice) |
| NSubstitute | `org.nuget.nsubstitute` (UnityNuGet 레지스트리 `https://unitynuget-registry.openupm.com`, scope `org.nuget`) | 목 객체 (gamedata, services, statechart) |
| MessagePack | `org.nuget.messagepack` 3.1.12 + `org.nuget.microsoft.net.stringtools` 1.0.0 (같은 레지스트리. UnityNuGet 패키지가 StringTools 의존성을 빠뜨려 함께 넣음) | realtime 의 선택 어셈블리 `Geuneda.Realtime.MessagePack` 과 그 테스트 |

- 패키지 `package.json` 에는 테스트 전용 의존성을 넣을 수 없습니다. 그래서 소비 프로젝트에서 `testables` 로 이 패키지들의 테스트를 돌리려면 위 의존성과 scoped registry 를 그 프로젝트 manifest 에도 넣어야 합니다.
- 명령줄에서는 Unity CLI 로 돌릴 수 있습니다: `unity test . --mode EditMode` (PlayMode 는 `--mode PlayMode`).
- `ProjectSettings/ProjectVersion.txt` 와 다른 패치 버전의 에디터로 열면 Unity 가 manifest 의 Unity 패키지 버전을 올리고 순서를 바꿀 수 있습니다. 커밋하기 전에 `Packages/manifest.json` 변경이 의도한 것인지 확인합니다.

## 문서화 요구 사항

동작이나 공개 API 를 바꾸면 같은 변경에서 다음을 갱신합니다.

- 패키지 `README.md` (와 `docs/` 가 있으면 해당 문서)
- 패키지 `CHANGELOG.md` (사용자에게 보이는 변경)
- 패키지 `AGENTS.md` (아키텍처나 워크플로우가 바뀐 경우, 있는 패키지만)
- `claude-skills/geuneda-<패키지>/` 스킬 (`SKILL.md`, `references/api.md`)
- 패키지 버전, 의존성, 최소 Unity 버전이 바뀌면 루트 `README.md` 의 패키지 목록과 의존성 표

루트 `README.md` 는 호스트 레포와 패키지 목록을 다루고, 패키지 사용법은 패키지 문서로 링크합니다.

### 새 패키지 추가

1. `geuneda-<패키지>` 레포(패키지 이름의 점은 `-`, 예: `com.geuneda.account.apple` -> `geuneda-account-apple`)를 만들고 표준 UPM 구조(`package.json`, `Runtime/`, `Editor/`, `Tests/`, `README.md`, `CHANGELOG.md`, `LICENSE.md`)로 작성합니다
2. `git submodule add https://github.com/geuneda/geuneda-<패키지>.git Packages/com.geuneda.<패키지>`
3. `Packages/manifest.json` 에 git URL 의존성을 추가합니다
4. 루트 `README.md` 의 패키지 목록, 의존성, 스킬 표에 추가합니다
5. `claude-skills/geuneda-<패키지>/` 에 `SKILL.md` 와 `references/api.md` 를 만들고 `install.sh`, `uninstall.sh` 의 `SKILLS` 목록에 등록합니다. 기능 패키지의 플랫폼 연동만 따로 떼어 낸 패키지(D3, 예: account.apple·account.google)는 별도 스킬을 만들지 않고 기능 패키지 스킬에 넣습니다
6. `CLAUDE.md` 의 네임스페이스 -> 스킬 표에 행을 추가합니다
7. `claude-skills/geuneda-frameworks/` 스킬의 패키지 목록과 의존성을 갱신합니다

## 풀 리퀘스트

- PR 은 가능한 한 작고 한 가지 목적에 집중합니다.
- 다음 내용을 포함해 주세요.
  - 동기 / 배경
  - 변경 내용
  - 검증 방법 (절차, 테스트, UI/에디터 관련이면 스크린샷)

## 라이선스

- 이 레포는 루트 `LICENSE` 를 따릅니다.
- `Packages/` 아래 패키지는 자체 라이선스 파일을 가질 수 있으며, 그 패키지에는 해당 라이선스가 적용됩니다.
