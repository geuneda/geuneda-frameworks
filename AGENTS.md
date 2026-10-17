# geuneda-frameworks (Unity 호스트 레포) - AI 에이전트 가이드

## 1. 레포 개요

Geuneda UPM 패키지 33개를 개발, 테스트, 검증하는 Unity 6000.3 호스트 프로젝트다. 패키지는 `Packages/com.geuneda.*` 아래에 git 서브모듈로 들어 있고(`.gitmodules`), 각각 독립 레포다. `claude-skills/` 에는 패키지별 Claude Code 스킬 23개와 프레임워크 전체 스킬이 있다(애플·구글 제공자 패키지는 `geuneda-account`, 분석 벤더 어댑터 패키지는 `geuneda-analytics`, Unity IAP 어댑터 패키지는 `geuneda-iap`, MAX 어댑터 패키지는 `geuneda-ads`, UMP·ATT 어댑터 패키지는 `geuneda-consent` 스킬이 함께 다룬다).

- 패키지 목록, 버전, 의존성, 설치, 레포 구조: [README.md](README.md)
- 설정, 서브모듈 워크플로우, 코딩 표준, 테스트, 문서화 요구 사항: [CONTRIBUTING.md](CONTRIBUTING.md)
- 프레임워크를 쓰는 게임 코드의 설계 규칙과 네임스페이스 -> 스킬 매핑: [CLAUDE.md](CLAUDE.md)

## 2. 정보의 원천

문서와 코드가 다르면 코드가 맞다. 다음 순서로 확인한다.

1. 패키지 소스(`Runtime/`, `Editor/`)
2. `package.json`(버전, 최소 Unity, 의존성), asmdef(어셈블리 이름, 참조)
3. 패키지에 `AGENTS.md` 가 있으면 그 파일이 해당 패키지 작업 규칙의 원천이다
   - `Packages/com.geuneda.services/AGENTS.md` (테스트 규칙: `Packages/com.geuneda.services/Tests/AGENTS.md`)
   - `Packages/com.geuneda.uiservice/AGENTS.md`
   - `Packages/com.geuneda.gamesystems/AGENTS.md`
   - `Packages/com.geuneda.core/AGENTS.md` (static 허용 목록 D2)
   - `Packages/com.geuneda.http/AGENTS.md`
   - `Packages/com.geuneda.realtime/AGENTS.md`
   - `Packages/com.geuneda.account/AGENTS.md`
   - `Packages/com.geuneda.account.apple/AGENTS.md`
   - `Packages/com.geuneda.account.google/AGENTS.md`
   - `Packages/com.geuneda.appsetting/AGENTS.md`
   - `Packages/com.geuneda.resource/AGENTS.md`
   - `Packages/com.geuneda.servertime/AGENTS.md`
   - `Packages/com.geuneda.analytics/AGENTS.md`
   - `Packages/com.geuneda.analytics.firebase/AGENTS.md`, `.airbridge`, `.appsflyer`, `.facebook` 의 `AGENTS.md`
   - `Packages/com.geuneda.iap/AGENTS.md`, `Packages/com.geuneda.iap.unity/AGENTS.md`
   - `Packages/com.geuneda.ads/AGENTS.md`, `Packages/com.geuneda.ads.max/AGENTS.md`
   - `Packages/com.geuneda.consent/AGENTS.md`, `Packages/com.geuneda.consent.ump/AGENTS.md`, `Packages/com.geuneda.consent.att/AGENTS.md`
   - `Packages/com.geuneda.banword/AGENTS.md`
   - `Packages/com.geuneda.notice/AGENTS.md`
   - `Packages/com.geuneda.coupon/AGENTS.md`
4. 패키지 `README.md`, `docs/`, `CHANGELOG.md`

서드파티 API(Unity 패키지, UniTask, Addressables)를 조사할 때는 Unity 가 프로젝트를 연 뒤 생기는 `Library/PackageCache/` 의 로컬 소스를 우선 참조한다(`Library/` 는 git 에 없다).

## 3. 작업 규칙

- 코딩 표준은 [CONTRIBUTING.md](CONTRIBUTING.md#코딩-표준) 를 따른다. 특히 Runtime 코드에서 `UnityEditor` 참조 금지, 명시적 네임스페이스, C# 9.0.
- 패키지 코드를 고칠 때는 해당 서브모듈 레포에서 커밋하고, 호스트 레포에는 서브모듈 포인터 갱신만 커밋한다([서브모듈 워크플로우](CONTRIBUTING.md#서브모듈-워크플로우)).
- `Packages/` 안에 파일을 새로 만들면 Unity `.meta` 파일도 필요하다.
- 호스트 `ProjectSettings` 의 Scripting Define Symbols(Android, iPhone, Standalone, Server, WebGL)에 `GEUNEDA_SKIP_VENDOR_ADAPTERS` 가 있다. 다른 빌드 타깃으로 바꿀 때는 그 타깃에도 넣는다. 벤더 SDK 가 필요한 어댑터 패키지(analytics.firebase 등)를 호스트에서 컴파일하지 않기 위한 것이므로 지우지 않는다. 어댑터는 SDK 를 넣은 별도 프로젝트에서 테스트한다.
- Geuneda API 를 쓰는 코드를 작성하기 전에 [CLAUDE.md](CLAUDE.md#프레임워크-스킬-필수-규칙) 의 표에 따라 해당 스킬을 invoke 한다.
- 공개 API, 버전, 의존성을 바꾸면 [문서화 요구 사항](CONTRIBUTING.md#문서화-요구-사항) 에 적힌 문서와 스킬을 같은 변경에서 갱신한다.

## 4. 문서 역할

| 문서 | 다루는 것 |
|------|-----------|
| `README.md` | 이 호스트 레포, 패키지 목록, 설치, 스킬 설치 |
| `CONTRIBUTING.md` | 개발 환경, 서브모듈, 코딩 표준, 테스트, PR |
| `CLAUDE.md` | 프레임워크를 쓰는 모든 프로젝트의 공용 규칙 |
| `AGENTS.md` | 에이전트가 이 레포를 작업할 때의 규칙 (이 문서) |
| `Packages/<패키지>/README.md` | 패키지 설치, 사용법, API, 샘플 |
| `claude-skills/geuneda-*/` | Claude Code 스킬. `~/.claude/skills/` 로 복사되어 쓰이므로 레포 파일로의 상대 링크를 두지 않는다 |
