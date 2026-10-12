---
name: geuneda-frameworks
description: Geuneda Unity 패키지 프레임워크 전체의 구조, 의존성, 개발/테스트 방법을 이해할 때 사용하는 스킬. 어떤 com.geuneda.* 패키지를 써야 할지 고르거나, 패키지 간 의존 관계를 파악하거나, geuneda-frameworks 호스트 레포에서 서브모듈 작업, 새 패키지 추가, Unity 버전 변경처럼 여러 패키지에 영향을 주는 작업을 할 때 활성화한다. 개별 패키지 API 사용법은 해당 패키지 스킬을 쓴다.
---

# Geuneda Frameworks

Geuneda UPM 패키지 9개와 그것을 개발, 테스트, 검증하는 Unity 호스트 레포(`https://github.com/geuneda/geuneda-frameworks.git`). 각 패키지는 독립 git 레포이고 호스트 레포의 `Packages/com.geuneda.<패키지>/` 에 서브모듈로 들어 있다. 원본은 GameLovers Frameworks by Miguel Tomas, 라이선스는 MIT.

## 활성화 시점

- 어떤 패키지를 써야 할지 결정할 때
- 패키지 간 의존성이나 설치 시 함께 넣어야 할 패키지를 파악할 때
- 호스트 레포에서 서브모듈을 갱신하거나 패키지를 수정할 때
- 새 패키지를 프레임워크에 추가할 때
- Unity 버전 변경처럼 여러 패키지에 영향을 주는 변경을 할 때

## 패키지 (9개)

버전과 최소 Unity 는 2026-10-12 시점 `package.json` 값이다. 작업 전에 `package.json` 으로 다시 확인한다.

| 패키지 | 버전 | 최소 Unity | 용도 | 스킬 |
|--------|------|-----------|------|------|
| `com.geuneda.gamedata` | 1.0.4 | 6000.0 | Observable 데이터, `ComputedField`, `ConfigsProvider`, 결정론적 `floatP`, 직렬화 헬퍼 | `geuneda-gamedata` |
| `com.geuneda.services` | 2.1.4 | 6000.3 | `MainInstaller` 서비스 로케이터, 메시지 브로커, 틱, 코루틴, 풀, 데이터, RNG, 시간, 커맨드, 버전, Addressables 에셋 로딩/임포트 | `geuneda-services` |
| `com.geuneda.uiservice` | 1.3.2 | 6000.0 | UI 프레젠터 생명주기, UI Set, 피처 조합, UI Toolkit | `geuneda-uiservice` |
| `com.geuneda.statechart` | 0.9.6 | 2022.3 | 계층적 상태 머신(Statechart) | `geuneda-statechart` |
| `com.geuneda.inputextensions` | 1.0.3 | 2019.3 | Input System 포인터 드래그, 스와이프/탭, 게임패드 | `geuneda-inputextensions` |
| `com.geuneda.nativeui` | 0.2.7 | 2020.3 | iOS/Android 네이티브 알림 팝업, 토스트 | `geuneda-nativeui` |
| `com.geuneda.notificationservice` | 0.1.9 | 2019.4 | 모바일 로컬 알림 예약/취소/해제 | `geuneda-notificationservice` |
| `com.geuneda.googlesheetimporter` | 0.9.1 | 6000.0 | Google 스프레드시트 -> ScriptableObject 설정 데이터 임포트(에디터 도구) | `geuneda-googlesheetimporter` |
| `com.geuneda.gamesystems` | 0.2.1 | 6000.3 | 공용 게임 시스템, 기능별 asmdef(현재 레드닷) | `geuneda-gamesystems` |

레포 URL 규칙: `com.geuneda.<x>` -> `https://github.com/geuneda/geuneda-<x>.git`.

없어지거나 합쳐진 것:
- `com.geuneda.assetsimporter` 는 services v2.0.0 에 흡수됐다(`AssetResolverService`, `Geuneda.Services.AssetsImporter`, AddressableIds 생성기). 별도 패키지로 추가하지 않는다.
- 예전 DataExtensions / ConfigsProvider 패키지는 gamedata 로 합쳐졌다. 런타임 네임스페이스 `Geuneda.DataExtensions`, 어셈블리 `Geuneda.GameData`.

## 의존성

```
gamedata
  ├── services
  │     └── gamesystems
  └── googlesheetimporter

독립(다른 Geuneda 패키지에 의존하지 않음): uiservice, statechart, inputextensions, nativeui, notificationservice
```

- gamedata API 를 바꾸면 services, googlesheetimporter, gamesystems 를 확인한다. services API 를 바꾸면 gamesystems 를 확인한다.
- uiservice 는 gamedata/services 에 의존하지 않는다.
- 패키지 간 순환 의존은 금지한다.
- 외부 의존성과 버전은 `references/api.md` 의 패키지별 카드를 본다.

## 설치 (소비 프로젝트)

`Packages/manifest.json` 에 태그 없는 git URL 을 넣는다. 특정 버전으로 고정하려면 `#<태그>` 를 붙이되, git 태그가 `package.json` 버전과 맞지 않는 경우가 있으니 레포에 실제로 있는 태그인지 먼저 확인한다.

```json
{
  "dependencies": {
    "com.cysharp.unitask": "https://github.com/Cysharp/UniTask.git?path=src/UniTask/Assets/Plugins/UniTask",
    "com.geuneda.gamedata": "https://github.com/geuneda/geuneda-gamedata.git",
    "com.geuneda.services": "https://github.com/geuneda/geuneda-services.git"
  }
}
```

UPM 은 git 전용 의존성을 자동으로 받지 못하므로 직접 함께 넣는다.

| 설치하는 패키지 | 같이 넣을 것 |
|----------------|-------------|
| gamedata, uiservice, statechart | UniTask |
| services | UniTask, gamedata |
| googlesheetimporter | gamedata, UniTask |
| gamesystems | services, gamedata, UniTask |

## 호스트 레포 구조

```
geuneda-frameworks/
  Assets/                 # 호스트 에셋 (Addressables 설정, TextMesh Pro 리소스, 테스트용 에셋)
  Packages/
    manifest.json         # 호스트 의존성 (Geuneda 패키지는 git URL 로 선언)
    com.geuneda.*/        # 패키지 9개, 각각 서브모듈
  ProjectSettings/        # ProjectVersion.txt: 6000.3.2f1
  UserSettings/
  claude-skills/
    install.sh            # ~/.claude/skills/ 로 스킬 복사
    uninstall.sh          # ~/.claude/skills/<스킬> 삭제
    geuneda-frameworks/   # 이 스킬
    geuneda-<패키지>/     # 패키지별 스킬 9개
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

서브모듈은 호스트가 기록한 커밋에 detached HEAD 로 체크아웃된다. 고치기 전에 기본 브랜치로 전환한다. 기본 브랜치는 gamesystems 만 `main`, 나머지 8개는 `master` 다.

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
- 패키지에 `AGENTS.md` 가 있으면 그 패키지 작업 규칙의 원천이다: services(테스트는 `Tests/AGENTS.md`), uiservice, gamesystems

## 테스트

Unity Test Framework 로 작성하고 Unity 에디터의 **Window > General > Test Runner** 에서 EditMode/PlayMode 로 실행한다. 테스트가 있는 패키지는 gamedata, services, uiservice, statechart, googlesheetimporter, gamesystems 이고, inputextensions, nativeui, notificationservice 에는 없다. 테스트 asmdef 이름은 `references/api.md` 의 패키지별 카드에 있다.

## 새 패키지 추가 절차

1. `geuneda-<패키지>` 레포를 만들고 표준 UPM 구조(`package.json`, `Runtime/`, `Editor/`, `Tests/`, `README.md`, `CHANGELOG.md`, `LICENSE.md`)로 작성
2. `git submodule add https://github.com/geuneda/geuneda-<패키지>.git Packages/com.geuneda.<패키지>`
3. `Packages/manifest.json` 에 git URL 의존성 추가
4. 루트 `README.md` 의 패키지 목록, 의존성, 스킬 표에 추가
5. `claude-skills/geuneda-<패키지>/` 에 `SKILL.md`, `references/api.md` 를 만들고 `install.sh`, `uninstall.sh` 의 `SKILLS` 배열에 등록
6. `CLAUDE.md` 의 네임스페이스 -> 스킬 표에 행 추가
7. 이 스킬(`SKILL.md`, `references/api.md`)의 패키지 목록과 의존성 갱신

## 패키지 선택

| 필요한 기능 | 패키지 |
|-------------|--------|
| Observable 상태, 설정 데이터 저장소, 결정론적 수학 | gamedata |
| 서비스 로케이터, 이벤트, 틱/코루틴, 오브젝트 풀, 저장, RNG, 시간, 커맨드 | services |
| Addressables 에셋/씬 로딩, 에셋 설정 임포트, Addressable ID 생성 | services |
| UI 생명주기(MVP), UI Set, UI Toolkit | uiservice |
| 계층적 상태 머신 | statechart |
| 드래그, 스와이프, 탭, 게임패드 입력 | inputextensions |
| 네이티브 알림 팝업, 토스트 | nativeui |
| 모바일 로컬 알림 | notificationservice |
| Google 스프레드시트 데이터 임포트 | googlesheetimporter |
| 레드닷(경로 트리 알림 배지) 등 공용 게임 시스템 | gamesystems |

## 참조

- `references/api.md`: 패키지별 상세 카드(의존성, asmdef, 네임스페이스, 문서 위치, 테스트), 구성 예시
- 패키지 API 는 해당 패키지 스킬: `geuneda-gamedata`, `geuneda-services`, `geuneda-uiservice`, `geuneda-statechart`, `geuneda-inputextensions`, `geuneda-nativeui`, `geuneda-notificationservice`, `geuneda-googlesheetimporter`, `geuneda-gamesystems`
