# Geuneda Frameworks - 공용 규칙

geuneda-frameworks를 사용하는 모든 Unity 프로젝트에 적용되는 공통 규칙.
프로젝트별 CLAUDE.md에서 이 문서를 참조한다.

## 금지 패턴

- 싱글톤 금지 (MainInstaller 서비스 로케이터 사용)
- static mutable state 금지 (서비스를 통해 접근)
- 2단계 이상 MonoBehaviour 상속 금지
- MonoBehaviour에 비즈니스 로직 직접 구현 금지
- God class 금지 (단일 책임 원칙)
- Resources 폴더 사용 최소화 (Addressables 사용)
- Find/FindObjectOfType 사용 금지 -> 서비스 로케이터 사용
- `async void` 금지 -> `async UniTaskVoid` (UniTask only)

## CBD 설계 원칙

- MonoBehaviour는 단일 책임 (Unity 연결 역할만)
- 비즈니스 로직은 POCO 클래스로 분리
- 상속 대신 컴포넌트 조합
- 인터페이스 기반 추상화, 구체 타입 직접 참조 최소화

### 권장 구조

- Model: POCO + ObservableField 상태 관리
- View: MonoBehaviour, Unity 표시만
- Presenter: 로직 담당 클래스, View와 분리
- Config: ScriptableObject 또는 ConfigsProvider
- Service: MainInstaller 바인딩, 인터페이스 접근

## 핵심 API 패턴

### 서비스 접근

```csharp
var service = ServiceAccessor.Get<IMyService>();
if (ServiceAccessor.TryGet<IMyService>(out var svc)) { ... }
```

### 이벤트 (MessageBroker)

```csharp
MessageBroker.Subscribe<MyMessage>(OnMyMessage);    // 구독
MessageBroker.PublishSafe(new MyMessage { ... });    // 발행
MessageBroker.Unsubscribe<MyMessage>(this);          // 해제 (필수)
```

### 오브젝트 풀링

```csharp
var pool = poolService.GetPool<T>(prefab);
var obj = pool.Spawn();
pool.Despawn(obj);
```

### DI 등록

```csharp
MainInstaller.Bind<IMyService>(instance);
```

## 프레임워크 스킬 필수 규칙

Geuneda API 코드 작성/수정 전 반드시 해당 스킬을 invoke하여 API 사양 확인.

| using 네임스페이스 | 필수 스킬 |
|-------------------|----------|
| `Geuneda.DataExtensions` | `/geuneda-gamedata` |
| `Geuneda.Services` | `/geuneda-services` |
| `Geuneda.Services.AssetsImporter` | `/geuneda-services` |
| `Geuneda.UiService` | `/geuneda-uiservice` |
| `Geuneda.StatechartMachine` | `/geuneda-statechart` |
| `Geuneda.GoogleSheetImporter` | `/geuneda-googlesheetimporter` |
| `Geuneda.InputExtensions` | `/geuneda-inputextensions` |
| `Geuneda.NativeUi` | `/geuneda-nativeui` |
| `Geuneda.NotificationService` | `/geuneda-notificationservice` |

| 작업 유형 | 필수 스킬 |
|----------|----------|
| 프레임워크 구조/의존성 변경 | `/geuneda-frameworks` |

- 하나의 파일이 여러 네임스페이스 사용 시 관련 스킬 모두 invoke
- 에이전트 위임 시 스킬 invoke를 명시

## 패키지 의존성 체인

```
gamedata -> services -> uiservice
```

하위 패키지 API 변경 시 상위 패키지에 영향을 줄 수 있다.
