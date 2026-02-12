# Frameworks (Unity 호스트 저장소) - AI 에이전트 가이드

## 1. 저장소 개요
이 저장소는 여러 Geuneda UPM 패키지를 개발, 테스트, 검증하기 위한 **Unity 6 호스트 프로젝트**입니다.

대부분의 패키지는 `Packages/` 하위에 위치하며 **git 서브모듈**로 포함되어 있습니다 (`.gitmodules` 참조).

## 2. 주요 규칙 / 표준
- **Unity**: 6000.0+
- **C#**: C# 9.0 구문; **명시적 네임스페이스** 사용 (global usings 사용 금지)
- **어셈블리 경계**:
  - Runtime 코드에서 `UnityEditor`를 참조하면 안 됩니다
  - Editor 도구는 `Editor/` 및 Editor 어셈블리에 위치해야 합니다
- **외부 API**: 서드파티 소스(Unity 패키지, UniTask, Addressables)를 조사할 때는 가능한 경우 `Library/PackageCache/` 하위의 로컬 UPM 캐시를 우선 참조하세요.

## 3. 저장소 구조
- `Assets/`: 개발/테스트에 사용되는 Unity 프로젝트 에셋.
- `Packages/`: 임베디드 UPM 패키지 (대부분 서브모듈).
- `ProjectSettings/`, `UserSettings/`: Unity 설정.

## 4. 서브모듈 워크플로우 (중요)
`Packages/` 하위의 패키지 폴더가 비어 있다면 서브모듈을 초기화하세요:

```bash
git submodule update --init --recursive
```

패키지를 편집할 때는 독립 저장소처럼 취급하세요:
- `Packages/<package-name>/` 내에서 변경
- 동작이나 API가 변경된 경우 해당 패키지의 `README.md` / `CHANGELOG.md` 업데이트
- 패키지 저장소에 업스트림으로 기여하는 것을 권장합니다

## 5. 패키지별 가이드 (정보의 원천)
일부 패키지에는 자체 `AGENTS.md`가 포함되어 있습니다. 해당 파일이 존재하는 경우, **그 파일이 해당 패키지의 정보의 원천**입니다.

예시:
- `Packages/com.geuneda.uiservice/AGENTS.md`

## 6. 문서화 정책
- 루트 `README.md`는 **이 호스트 저장소**를 문서화하며, 패키지 문서로 링크합니다.
- 패키지 수준의 `README.md`는 **패키지** 자체를 문서화합니다 (설치, 사용법, API, 샘플).
