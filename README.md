# Geuneda Frameworks (Unity)

Unity 6 프로젝트로, Geuneda Unity Package Manager (UPM) 패키지들을 **개발, 테스트, 검증**하는 데 사용됩니다.

## 이 프로젝트의 구성

- **Unity 호스트 프로젝트**: 패키지 개발 시 샘플과 테스트를 실행하는 데 유용합니다
- **내장 패키지**: 각각 UPM 패키지로, 독립적인 `package.json`, `README.md` 등을 가지고 있습니다

## 포함된 패키지

| 패키지 | 설명 | 레포지토리 |
|--------|------|-----------|
| `com.geuneda.dataextensions` | 데이터 타입 확장 유틸리티 | [geuneda-dataextensions](https://github.com/geuneda/geuneda-dataextensions) |
| `com.geuneda.services` | 게임 서비스 (DI, 메시지 브로커, 풀링 등) | [geuneda-services](https://github.com/geuneda/geuneda-services) |
| `com.geuneda.uiservice` | UI 관리 서비스 | [geuneda-uiservice](https://github.com/geuneda/geuneda-uiservice) |
| `com.geuneda.statechart` | 상태머신 (HFSM) | [geuneda-statechart](https://github.com/geuneda/geuneda-statechart) |
| `com.geuneda.configsprovider` | 설정 제공자 | [geuneda-configsprovider](https://github.com/geuneda/geuneda-configsprovider) |
| `com.geuneda.inputextensions` | 입력 확장 | [geuneda-inputextensions](https://github.com/geuneda/geuneda-inputextensions) |
| `com.geuneda.nativeui` | 네이티브 UI 헬퍼 | [geuneda-nativeui](https://github.com/geuneda/geuneda-nativeui) |
| `com.geuneda.notificationservice` | 알림 서비스 | [geuneda-notificationservice](https://github.com/geuneda/geuneda-notificationservice) |
| `com.geuneda.googlesheetimporter` | 구글 시트 임포터 | [geuneda-googlesheetimporter](https://github.com/geuneda/geuneda-googlesheetimporter) |
| `com.geuneda.assetsimporter` | 에셋 임포터 | [geuneda-assetsimporter](https://github.com/geuneda/geuneda-assetsimporter) |

## 설치 방법

### 전체 프로젝트 클론

```bash
git clone https://github.com/geuneda/geuneda-frameworks.git
```

### 개별 패키지 사용

`Packages/manifest.json`에 필요한 패키지만 추가:

```json
{
  "dependencies": {
    "com.geuneda.services": "https://github.com/geuneda/geuneda-services.git#v1.0.0",
    "com.geuneda.uiservice": "https://github.com/geuneda/geuneda-uiservice.git#v1.0.0"
  }
}
```

또는 Unity Package Manager에서:
1. **Window -> Package Manager** 열기
2. **+** 버튼 -> **Add package from git URL...**
3. 패키지 URL 입력

## 요구 사항

- Unity 6000.0 이상
- Addressables 2.7.6+
- UniTask

## 의존성 구조

```
dataextensions (기반)
    |
services (dataextensions 의존)
    |
uiservice (services, UniTask, Addressables 의존)
```

## 프로젝트 구조

```
geuneda-frameworks/
├── Assets/
│   └── Samples/              # 샘플 씬
├── Packages/
│   └── manifest.json         # 패키지 의존성
├── ProjectSettings/
├── claude-skills/            # Claude Code AI 스킬
│   ├── install.sh            # 스킬 설치 스크립트
│   ├── uninstall.sh          # 스킬 제거 스크립트
│   └── geuneda-*/            # 패키지별 스킬 폴더
└── README.md
```

## Claude Code Skills

각 Geuneda 패키지에 대한 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 스킬이 포함되어 있습니다. 스킬을 설치하면 Claude Code가 각 패키지의 API, 사용 패턴, 주의사항을 자동으로 인식하여 코드 작성을 지원합니다.

### 포함된 스킬

| 스킬 | 대상 패키지 | 설명 |
|------|-----------|------|
| `geuneda-assetsimporter` | com.geuneda.assetsimporter | Addressables 에셋 로딩/관리 API 지원 |
| `geuneda-dataextensions` | com.geuneda.dataextensions | Observable, ConfigsProvider, floatP 등 데이터 유틸 |
| `geuneda-frameworks` | (전체) | 프레임워크 구조, 의존성, 패키지 간 관계 파악 |
| `geuneda-googlesheetimporter` | com.geuneda.googlesheetimporter | Google Sheets -> ScriptableObject 임포트 |
| `geuneda-inputextensions` | com.geuneda.inputextensions | Input System 드래그/스와이프/탭 확장 |
| `geuneda-nativeui` | com.geuneda.nativeui | iOS/Android 네이티브 알림/토스트 |
| `geuneda-notificationservice` | com.geuneda.notificationservice | 모바일 로컬/원격 알림 관리 |
| `geuneda-services` | com.geuneda.services | DI 컨테이너, 메시지 브로커, 풀링, 틱 서비스 |
| `geuneda-statechart` | com.geuneda.statechart | 계층적 상태 머신 (HFSM) 구성 |
| `geuneda-uiservice` | com.geuneda.uiservice | MVP 패턴 UI 서비스, 피처 조합, UI Toolkit |

### 스킬 설치

전체 설치:

```bash
cd claude-skills
./install.sh
```

개별 스킬 설치:

```bash
cd claude-skills
./install.sh geuneda-services
```

### 스킬 제거

전체 제거:

```bash
cd claude-skills
./uninstall.sh
```

개별 스킬 제거:

```bash
cd claude-skills
./uninstall.sh geuneda-services
```

### 스킬 구조

각 스킬은 다음 구조로 구성되어 있습니다:

```
geuneda-{패키지명}/
├── SKILL.md              # 스킬 메타데이터, API 요약, 사용 패턴
└── references/
    └── api.md            # 상세 API 레퍼런스
```

- **SKILL.md**: Claude Code가 스킬 활성화 시 로드하는 핵심 문서. 패키지의 API, 사용 패턴, 주의사항을 포함합니다.
- **references/api.md**: 소스코드에서 추출한 상세 API 레퍼런스. Claude Code가 필요에 따라 참조합니다.

## 라이센스

MIT License

원본: GameLovers Frameworks by Miguel Tomas
