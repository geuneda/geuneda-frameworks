# Geuneda Frameworks (Unity)

Geuneda Unity Package Manager(UPM) 패키지 9개를 개발, 테스트, 검증하는 Unity 호스트 프로젝트입니다. 각 패키지는 별도 git 레포지토리이고, 이 레포에는 `Packages/com.geuneda.*` 아래 git 서브모듈로 들어 있습니다. 패키지마다 Claude Code 스킬이 `claude-skills/` 에 함께 있습니다.

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

버전과 최소 Unity 버전은 각 패키지의 `package.json` 값입니다(2026-10-12 기준). 바뀌었을 수 있으니 정확한 값은 `package.json` 을 확인하세요.

| 패키지 | 버전 | 최소 Unity | 하는 일 | 문서 |
|--------|------|-----------|---------|------|
| `com.geuneda.gamedata` | 1.0.3 | 6000.0 | Observable 데이터(필드/리스트/딕셔너리 등), `ComputedField`, `ConfigsProvider` 설정 저장소, 결정론적 부동소수점 `floatP`, 직렬화 헬퍼 | [README](Packages/com.geuneda.gamedata/README.md) |
| `com.geuneda.services` | 2.1.4 | 6000.3 | 서비스 로케이터(`MainInstaller`), 메시지 브로커, 틱, 코루틴, 오브젝트 풀, 데이터 저장, RNG, 시간, 커맨드, 버전 정보, Addressables 에셋 로딩/임포트 | [README](Packages/com.geuneda.services/README.md), [docs](Packages/com.geuneda.services/docs/README.md) |
| `com.geuneda.uiservice` | 1.3.1 | 6000.0 | UI 열기/닫기/로드/언로드, UI Set, 프레젠터 피처 조합, UI Toolkit 지원, 다중 인스턴스 | [README](Packages/com.geuneda.uiservice/README.md), [docs](Packages/com.geuneda.uiservice/docs/README.md) |
| `com.geuneda.statechart` | 0.9.4 | 2022.3 | 계층적 상태 머신(Statechart) | [README](Packages/com.geuneda.statechart/README.md) |
| `com.geuneda.inputextensions` | 1.0.1 | 2019.3 | Input System 기반 포인터 드래그, 스와이프/탭 제스처, 게임패드 입력 | [README](Packages/com.geuneda.inputextensions/README.md) |
| `com.geuneda.nativeui` | 0.2.6 | 2020.3 | iOS/Android 네이티브 알림 팝업과 토스트 메시지 | [README](Packages/com.geuneda.nativeui/README.md) |
| `com.geuneda.notificationservice` | 0.1.8 | 2019.4 | Unity Mobile Notifications 기반 모바일 로컬 알림 예약/취소/해제 | [README](Packages/com.geuneda.notificationservice/README.md) |
| `com.geuneda.googlesheetimporter` | 0.9.1 | 6000.0 | Google 스프레드시트 데이터를 ScriptableObject 설정 데이터로 가져오는 에디터 도구 | [README](Packages/com.geuneda.googlesheetimporter/README.md) |
| `com.geuneda.gamesystems` | 0.2.1 | 6000.3 | 여러 게임에서 반복되는 게임 시스템 모음. 기능마다 asmdef 가 나뉨(현재 레드닷) | [README](Packages/com.geuneda.gamesystems/README.md) |

레포지토리 URL 은 모두 `https://github.com/geuneda/<레포>.git` 형식이고, 레포 이름은 패키지 이름의 `com.geuneda.` 를 `geuneda-` 로 바꾼 것입니다(예: `com.geuneda.services` -> `geuneda-services`).

### 없어지거나 합쳐진 패키지

- `com.geuneda.assetsimporter`: services v2.0.0 에 흡수되었습니다(`AssetResolverService`, `Geuneda.Services.AssetsImporter` 네임스페이스, AddressableIds 생성기). 별도 패키지로 추가하지 않습니다. 마이그레이션은 [services MIGRATION.md](Packages/com.geuneda.services/MIGRATION.md) 를 참고하세요.
- 예전 DataExtensions / ConfigsProvider 패키지: gamedata 로 합쳐졌습니다. 런타임 네임스페이스는 `Geuneda.DataExtensions`, 어셈블리 이름은 `Geuneda.GameData` 입니다.

## 의존성

Geuneda 패키지끼리의 의존 관계입니다(`package.json` 과 asmdef 기준).

```
gamedata
  ├── services
  │     └── gamesystems
  └── googlesheetimporter

uiservice, statechart, inputextensions, nativeui, notificationservice: 다른 Geuneda 패키지에 의존하지 않음
```

외부 의존성(`package.json` 에 선언된 최소 버전):

| 패키지 | 외부 의존성 |
|--------|-------------|
| gamedata | `com.unity.nuget.newtonsoft-json` 3.2.1, `com.cysharp.unitask` 2.5.10, `com.unity.ugui` 2.0.0 |
| services | `com.geuneda.gamedata` 1.0.0, `com.unity.addressables` 1.21.20, `com.cysharp.unitask` 2.5.10 |
| uiservice | `com.unity.addressables` 2.6.0, `com.cysharp.unitask` 2.5.10, `com.unity.ugui` 2.0.0 |
| statechart | `com.cysharp.unitask` 2.5.10 |
| inputextensions | `com.unity.inputsystem` 1.0.0-preview.4, `com.unity.ugui` 1.0.0 |
| nativeui | 없음 |
| notificationservice | `com.unity.mobile.notifications` 1.3.0 |
| googlesheetimporter | `com.unity.nuget.newtonsoft-json` 2.0.0, `com.geuneda.gamedata` 1.0.0 |
| gamesystems | `com.geuneda.services` 2.1.0 |

호스트 프로젝트는 Unity 6000.3.2f1 에서 Addressables 2.7.6, Input System 1.17.0, Mobile Notifications 2.4.2, Test Framework 1.6.0, uGUI 2.0.0 으로 검증합니다(`Packages/manifest.json`, `ProjectSettings/ProjectVersion.txt`). 패키지별 최소 Unity 버전은 서로 다르지만 이 호스트에서 함께 검증하는 버전은 6000.3 입니다.

## 설치

### 내 Unity 프로젝트에 패키지 추가

`Packages/manifest.json` 의 `dependencies` 에 git URL 을 넣거나, Unity 에서 **Window > Package Manager > + > Add package from git URL...** 로 같은 URL 을 입력합니다.

```json
{
  "dependencies": {
    "com.cysharp.unitask": "https://github.com/Cysharp/UniTask.git?path=src/UniTask/Assets/Plugins/UniTask",
    "com.geuneda.gamedata": "https://github.com/geuneda/geuneda-gamedata.git",
    "com.geuneda.services": "https://github.com/geuneda/geuneda-services.git"
  }
}
```

UPM 은 git URL 로만 받을 수 있는 의존성을 자동으로 설치하지 못합니다. 다음 의존성은 직접 함께 추가해야 합니다.

| 설치하는 패키지 | 같이 추가할 패키지 |
|----------------|-------------------|
| gamedata, uiservice, statechart | UniTask |
| services | UniTask, gamedata |
| googlesheetimporter | gamedata, UniTask(gamedata 의존성) |
| gamesystems | services, gamedata, UniTask |

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
│   └── com.geuneda.*/      # 패키지 9개, 각각 git 서브모듈 (.gitmodules)
├── ProjectSettings/        # Unity 설정 (ProjectVersion.txt: 6000.3.2f1)
├── UserSettings/
├── claude-skills/
│   ├── install.sh          # 스킬 설치
│   ├── uninstall.sh        # 스킬 제거
│   ├── geuneda-frameworks/ # 프레임워크 전체 스킬
│   └── geuneda-<패키지>/    # 패키지별 스킬 9개
├── .gitmodules
├── AGENTS.md               # AI 에이전트용 레포 가이드
├── CLAUDE.md               # 프레임워크를 쓰는 프로젝트의 공용 규칙
├── CONTRIBUTING.md         # 개발/기여 가이드
├── CODE_OF_CONDUCT.md
├── LICENSE
└── README.md
```

`Packages/manifest.json` 은 Geuneda 패키지를 git URL 로 선언하지만, `Packages/` 아래에 같은 이름의 폴더(서브모듈)가 있으면 Unity 는 그 폴더를 임베디드 패키지로 우선 사용합니다. 그래서 호스트에서는 서브모듈 작업본이 컴파일됩니다.

## Claude Code 스킬

`claude-skills/` 에는 패키지별 스킬 9개와 프레임워크 전체 스킬 `geuneda-frameworks` 가 있습니다. 스킬을 설치하면 Claude Code 가 패키지 API, 사용 패턴, 주의사항을 참고해 코드를 작성합니다.

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

어떤 코드에서 어떤 스킬을 써야 하는지는 [CLAUDE.md](CLAUDE.md) 의 네임스페이스 매핑 표를 따릅니다.

### 설치와 제거

스크립트는 자기 위치를 기준으로 동작하므로 어느 디렉터리에서 실행해도 됩니다.

```bash
claude-skills/install.sh                     # 스킬 10개 모두 설치
claude-skills/install.sh geuneda-services    # 하나만 설치
claude-skills/uninstall.sh                   # 스킬 10개 모두 제거
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

원본: GameLovers Frameworks by Miguel Tomas
