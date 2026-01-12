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
1. **Window → Package Manager** 열기
2. **+** 버튼 → **Add package from git URL...**
3. 패키지 URL 입력

## 요구 사항

- Unity 6000.0 이상
- Addressables 2.7.6+
- UniTask

## 의존성 구조

```
dataextensions (기반)
    ↓
services (dataextensions 의존)
    ↓
uiservice (services, UniTask, Addressables 의존)
```

## 프로젝트 구조

```
geuneda-frameworks/
├── Assets/
│   └── Samples/          # 샘플 씬
├── Packages/
│   └── manifest.json     # 패키지 의존성
├── ProjectSettings/
└── README.md
```

## 라이센스

MIT License

원본: GameLovers Frameworks by Miguel Tomas
