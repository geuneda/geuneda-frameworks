# Geuneda Game Systems - API 레퍼런스

## 네임스페이스: Geuneda.GameSystems.RedDot

어셈블리: `Geuneda.GameSystems.RedDot` (참조: `Geuneda.Core`, `Geuneda.Services`). 소스: `Runtime/RedDot/`. 기준 버전 0.4.0. 로그는 core `ModuleLogger` 로 `[Geuneda.GameSystems.RedDot]`(서비스), `[Geuneda.GameSystems.RedDot.View]`(뷰)를 붙인다.

### interface IRedDotService

경로 트리 기반 레드닷 서비스 계약. 경로는 '/' 로 계층을 나눈다. 종류(kind)를 받지 않는 멤버는 모든 종류의 합을 다룬다. 리프마다 종류 하나, 부모는 종류마다 따로 합한다.

| 멤버 | 설명 |
|------|------|
| `IReadOnlyCollection<string> Paths { get; }` | 등록된 모든 노드 경로의 읽기 전용 스냅샷(`ReadOnlyCollection`). 읽은 뒤 변경은 반영 안 됨, 순회 중 등록·제거 가능. 트리가 그대로면 같은 인스턴스 |
| `int KindCount { get; }` | 배지 종류 수(1 이면 종류를 나누지 않음). 종류는 0 ~ KindCount-1 |
| `void RegisterNode(string path)` | 노드 등록. 없는 조상 자동 생성(종류 0), 새 노드도 종류 0. 이미 있으면 무시(종류도 그대로). 경로가 비었거나 '/'로 시작·끝나거나 빈 구간이 있으면 `ArgumentException` |
| `void RegisterNode(string path, int kind)` | 종류를 정해 등록. 조상은 종류 0. 이미 있으면 종류만 바꾸고 리프 값을 새 종류로 옮김(합은 그대로). 종류가 0 ~ KindCount-1 밖이면 `ArgumentOutOfRangeException`(노드를 만들지 않음) |
| `void UnregisterNode(string path)` | 노드와 하위 노드 제거. 값이 있던 경로 구독자에게 0 알림, 구독 유지. 없는 경로면 무시 |
| `void SetLeafValue(string path, int value)` | 리프 값 설정(값은 리프의 종류에 들어감). 음수는 0. 미등록 경로나 부모 노드면 Warning 로그 후 무시 |
| `void SetNodeMuted(string path, bool muted)` | 뮤트/해제. 뮤트는 모든 종류를 0으로 잡음. 미등록 경로면 경고 후 무시 |
| `int GetValue(string path)` | 현재 값(모든 종류의 합). 부모는 자식 합(int 범위 초과 시 `int.MaxValue`), 없는 경로는 0 |
| `int GetValue(string path, int kind)` | 한 종류의 값(종류별로 포화). `AllKinds`(-1)면 합. 범위 밖이면 `ArgumentOutOfRangeException` |
| `void Subscribe(string path, Action<int> callback)` | 경로 구독. null 콜백은 `ArgumentNullException`. 미등록 경로도 가능. 구독 시점 값은 전달하지 않음(그 값이 이 구독자의 기준값). 같은 콜백을 여러 번 구독하면 그만큼 호출 |
| `void Unsubscribe(string path, Action<int> callback)` | 합(`AllKinds`)으로 구독한 같은 콜백 중 마지막에 추가한 하나를 해제. null 콜백이나 구독 없는 경로면 무시 |
| `void Subscribe(string path, int kind, Action<int> callback)` | 한 종류 구독. 그 종류의 값이 바뀔 때만 호출(합이 그대로여도 종류가 바뀌면 호출, 다른 종류만 바뀌면 호출 안 함). 범위 밖 종류는 `ArgumentOutOfRangeException` |
| `void Unsubscribe(string path, int kind, Action<int> callback)` | 종류와 콜백이 모두 같은 구독 중 마지막 하나를 해제 |
| `void Clear()` | 모든 노드 제거, 값이 있던 경로 구독자에게 0 알림, 구독 유지 |
| `RedDotBatch BeginBatch()` | 일괄 변경 범위. 범위 안 변경은 즉시 반영, 알림은 열린 범위가 모두 끝날 때 경로마다 최종 값으로 한 번. 중첩 가능 |

알림 규칙:
- 변경 메서드는 트리를 모두 갱신한 뒤 마지막에 구독자를 호출한다.
- 구독자마다 마지막 전달 값을 기억하고, 호출 직전 현재 값과 다를 때만 호출한다.
- 콜백 안의 변경은 즉시 반영되고 같은 알림 흐름 안에서 이어서 전달된다.
- 해제된 구독자는 진행 중인 알림에서도 호출되지 않는다.
- 콜백 예외는 Error 줄과 예외를 남긴 뒤 나머지 구독자를 계속 알린다.
- 일괄 범위가 열려 있으면 알리지 않는다. 알림 도중 콜백이 범위를 열면 남은 알림(같은 경로의 남은 구독자 포함)은 그 범위가 끝날 때 보낸다.
- 한 번의 처리에서 같은 경로를 100번(`MaxNotificationsPerPath`, internal) 넘게 알리면 Error 로그 한 번 후 그 처리에서 그 경로를 건너뛴다. 횟수는 경로로 세므로 콜백이 해제 후 재구독해도 유지된다.

---

### readonly struct RedDotBatch : IDisposable

`BeginBatch()` 가 돌려주는 범위. 할당 없음.

| 멤버 | 설명 |
|------|------|
| `RedDotBatch(Action<int> end, int id)` | `IRedDotService` 를 직접 구현할 때 쓰는 생성자. Dispose 가 `end(id)` 를 부른다. `end` 는 서비스가 한 번 만들어 둔 델리게이트를 넘기고, 이미 끝난 ID 를 무시해야 한다(복사본 중복 Dispose) |
| `void Dispose()` | 범위를 끝낸다. 열린 범위가 더 없으면 미뤄 둔 알림을 보낸다. 이미 끝난 범위(복사본 포함)면 무시, 순서와 관계없이 끝내도 됨. `default` 값은 아무것도 안 함 |

---

### sealed class RedDotService : IRedDotService

| 멤버 | 설명 |
|------|------|
| `public const char Separator = '/'` | 경로 구분자 |
| `public const int AllKinds = -1` | 종류 인자로 넘기면 모든 종류의 합 |
| `public const int MaxKindCount = 32` | 최대 종류 수 |
| `public RedDotService()` | 종류 하나인 빈 트리(기존 동작) |
| `public RedDotService(int kindCount)` | 종류 수를 정한 빈 트리. 1 ~ 32 밖이면 `ArgumentOutOfRangeException` |

구현 메모: 값 변화량을 부모 체인으로 즉시 전파해 `GetValue`는 O(1). 자식 합은 내부적으로 long. 종류가 둘 이상이면 노드마다 종류별 합(long 배열)을 따로 둔다.

---

### sealed class RedDotBinding

경로 하나의 구독을 담당하는 POCO. 화면 컴포넌트가 필드로 들고 생명주기에 맞춰 호출한다.

| 멤버 | 설명 |
|------|------|
| `RedDotBinding(Action<int> onValueChanged)` | 모든 종류의 합을 받는 바인딩. null 이면 `ArgumentNullException` |
| `RedDotBinding(Action<int> onValueChanged, int kind)` | 한 종류를 받는 바인딩. -1 미만이면 `ArgumentOutOfRangeException`, 서비스의 `KindCount` 이상이면 구독할 때 `ArgumentOutOfRangeException` |
| `int Kind { get; }` | 받는 종류(`AllKinds` 면 합) |
| `string Path { get; }` | 마지막으로 Bind 한 경로(Unbind 후에도 유지) |
| `bool IsBound { get; }` | 서비스에 구독 중 여부. MainInstaller 에 서비스가 없어 기다리는 중이면 false |
| `void Bind(string path)` | 기존 구독 해제 후 `MainInstaller` 의 `IRedDotService` 로 구독하고 현재 값(없으면 0)을 즉시 전달. `Unbind` 까지 `MainInstaller.BindingChanged` 를 따라가 늦은 바인딩·교체 때 새 서비스를 구독하고 값을, 정리 때 0을 전달(마지막 전달 값과 같으면 생략). 경로만 바꿀 때는 처리기를 다시 등록하지 않음. 빈 경로면 따라가기를 멈추고 0 전달 |
| `void Bind(IRedDotService service, string path)` | 기존 구독과 MainInstaller 따라가기를 해제한 뒤 구독하고 현재 값을 즉시 전달. 서비스 null 또는 빈 경로면 구독 없이 0 전달 |
| `void Unbind()` | 구독 해제와 MainInstaller 따라가기 중지. 구독 중이 아니면 무시 |

바인딩마다 고유한 델리게이트로 구독하므로, 같은 콜백을 쓰는 다른 바인딩의 구독에 영향을 주지 않는다.

---

### sealed class RedDotView : MonoBehaviour

프리팹에 붙여 쓰는 표시 컴포넌트.

| 멤버 | 설명 |
|------|------|
| `[SerializeField] private string _nodePath` | 인스펙터에서 지정하는 구독 경로 |
| `[SerializeField] private int _kind` | 볼 종류. 기본 -1(모든 종류의 합). -1 미만이면 Awake 에서 오류 후 -1 로 봄. 서비스의 종류 수 이상이면 OnEnable 구독에서 예외 |
| `[SerializeField] private GameObject _indicator` | 값이 1 이상이면 켤 자식 오브젝트. 비우면 토글 없이 이벤트만 발생. 자신/조상 지정은 무시(Awake 오류, OnValidate 경고) |
| `event Action<int> ValueChanged` | 표시 값이 바뀔 때. 일반 이벤트 +=/-= 규칙. 호출 단위로 예외 격리, 앞선 핸들러가 경로를 바꾸거나 뷰를 끄면 남은 핸들러 호출 중단 |
| `int Value { get; }` | 마지막 표시 값(늦게 구독한 쪽이 초기 상태를 읽을 때) |
| `string NodePath { get; }` | 현재 경로 |
| `int Kind { get; }` | 보는 종류 |
| `void SetNodePath(string nodePath)` | 같은 경로면 무시. 활성 상태면 즉시 재구독, 비활성이면 표시를 끄고 다음 활성화 때 구독. null/빈 문자열이면 끔 |

생명주기: Awake 에서 `RedDotBinding` 생성, OnEnable 에서 `Bind(_nodePath)`, OnDisable 에서 `Unbind()`.

---

### sealed class RedDotPriorityGroup : MonoBehaviour

종류별 `RedDotView` 를 우선순위 순서로 묶어, 값이 1 이상인 첫 항목의 표시 오브젝트 하나만 켠다(원본 TipDot 의 배지 상호 배제).

| 멤버 | 설명 |
|------|------|
| `[SerializeField] private Entry[] _entries` | 항목 `{ RedDotView View; GameObject Indicator; }`. 앞이 우선순위가 높다. 묶은 뷰의 `_indicator` 는 비운다(OnValidate 경고). 자신/조상을 `Indicator` 로 지정하면 무시(Awake 오류, OnValidate 경고) |
| `int ActiveIndex { get; }` | 지금 켠 항목 순번, 없으면 -1 |

켜져 있는 동안 뷰의 `ValueChanged` 를 구독하고 OnEnable 에서 한 번 갱신한다. 선택되지 않은 표시 오브젝트는 모두 끈다(프리팹에 켜져 있던 것 포함). 뷰는 그룹과 함께 켜고 끈다(꺼진 뷰도 마지막 값으로 판단).

---

### internal 타입

| 타입 | 역할 |
|------|------|
| `RedDotNode` | 트리 노드. 전체 값·종류별 값과 변화량 전파, 값이 바뀐 구독을 알림 대기열에 넣음 |
| `RedDotSubscription` | 경로 하나의 구독자 목록과 대기열 여부 |
| `RedDotListener` | 구독자 하나. 콜백, 받는 종류, 마지막 전달 값, 활성 여부 |

---

## 네임스페이스: Geuneda.GameSystems.FeatureUnlock

어셈블리: `Geuneda.GameSystems.FeatureUnlock` (참조: `Geuneda.Core`, `Geuneda.Services`). 소스: `Runtime/FeatureUnlock/`. 기준 버전 0.4.0. 로그는 `[Geuneda.GameSystems.FeatureUnlock]`(서비스), `[Geuneda.GameSystems.FeatureUnlock.View]`(뷰).

### interface IFeatureUnlockService

| 멤버 | 설명 |
|------|------|
| `event Action<string, bool> StateChanged` | (기능 ID, 열렸는지). 기능별 마지막으로 알린 상태와 다를 때만, 처음 기준은 열림. 상태를 모두 바꾼 뒤 대기열로 알림, 처리기 안의 변경은 이어서 알림(뒤 처리기가 마지막으로 받는 값은 현재 상태). 처리기 예외는 Error 로그 후 계속. 한 처리에서 기능 하나를 100번(`MaxNotificationsPerFeature`, internal) 넘게 알리면 Error 후 그 처리에서 건너뜀 |
| `bool IgnoreConditions { get; set; }` | 켜면 등록한 기능을 판정과 관계없이 연다(원격 차단은 적용). 바뀐 기능을 알림 |
| `void Register(string featureId, Func<bool> isMet)` | 등록하고 바로 판정. 빈 ID·중복은 `ArgumentException`, null 함수는 `ArgumentNullException`. 판정 결과가 잠김이면 (id, false) 알림 |
| `void Unregister(string featureId)` | 등록 해제(열림이 됨, 차단 제외). 없으면 무시 |
| `bool IsRegistered(string featureId)` | 등록 여부(빈 ID 는 false) |
| `bool IsUnlocked(string featureId)` | 차단이면 false, 미등록이면 true, 아니면 `IgnoreConditions` 또는 마지막 판정 결과. 판정 함수를 부르지 않음. 빈 ID 는 `ArgumentException` |
| `void Refresh()` | 등록한 모든 기능을 다시 판정(사본 배열 순회, 판정 중 지워진 기능은 건너뜀)하고 바뀐 기능을 알림 |
| `void Refresh(string featureId)` | 기능 하나를 다시 판정. 미등록이면 무시 |
| `void SetDisabled(string featureId, bool disabled)` | 원격 차단/해제(미등록 기능도). 빈 ID 는 `ArgumentException`. 같은 값이면 무시 |
| `bool IsDisabled(string featureId)` | 차단 여부 |
| `void Clear()` | 등록 전부 해제(바뀐 기능 알림). 원격 차단은 유지 |

판정 함수 예외는 Error 로그 후 잠김. 판정 함수 안에서 상태를 바꾸면 그 알림은 판정이 끝난 뒤 보낸다.

### sealed class FeatureUnlockService : IFeatureUnlockService

| 멤버 | 설명 |
|------|------|
| `public FeatureUnlockService()` | 빈 서비스 |

### sealed class FeatureUnlockBinding

| 멤버 | 설명 |
|------|------|
| `FeatureUnlockBinding(Action<bool> onStateChanged)` | null 이면 `ArgumentNullException` |
| `string FeatureId { get; }` | 마지막으로 Bind 한 ID |
| `bool IsBound { get; }` | 서비스에 구독 중 여부 |
| `void Bind(string featureId)` | `MainInstaller` 의 서비스로 구독하고 현재 상태(서비스 없으면 false) 즉시 전달. `Unbind` 까지 `MainInstaller.BindingChanged` 를 따라감(교체 때 상태가 같으면 다시 보내지 않음, 정리 때 false). 빈 ID 는 따라가기 중지 후 true |
| `void Bind(IFeatureUnlockService service, string featureId)` | 직접 주입, MainInstaller 를 따라가지 않음. 서비스 null 이면 false, 빈 ID 면 true |
| `void Unbind()` | 구독·따라가기 해제 |

다른 기능의 알림은 거르고, 알림을 받으면 지금 구독한 서비스의 상태를 다시 읽어 마지막 전달 값과 다를 때만 전달한다.

### sealed class FeatureLockView : MonoBehaviour

| 멤버 | 설명 |
|------|------|
| `[SerializeField] private string _featureId` | 기능 ID. 비우면 늘 열림 |
| `[SerializeField] private GameObject _lockedObject` / `_unlockedObject` | 잠김/열림 때 켤 자식. 자신/조상 지정은 무시(Awake 오류, OnValidate 경고) |
| `event Action<bool> StateChanged` | 표시 상태가 바뀔 때(활성화 때 현재 상태로 한 번). 처리기별 예외 격리, 앞선 처리기가 기능을 바꾸거나 뷰를 끄면 남은 처리기 호출 중단 |
| `bool IsUnlocked { get; }` | 마지막 표시 상태 |
| `string FeatureId { get; }` | 현재 기능 ID |
| `void SetFeatureId(string featureId)` | 같으면 무시. 활성이면 즉시 재구독, 비활성이면 잠김 표시 후 다음 활성화 때 구독 |

---

## 네임스페이스: Geuneda.GameSystems.RedDot.Editor

어셈블리: `Geuneda.GameSystems.RedDot.Editor` (Editor 플랫폼만, 참조: `Geuneda.GameSystems.RedDot`, `Geuneda.Services`). 소스: `Editor/RedDot/`. 런타임 internal 은 `InternalsVisibleTo` 로 읽는다.

| 타입 | 역할 |
|------|------|
| `RedDotDebuggerWindow` (internal) | 메뉴 `Tools > Geuneda > RedDot Debugger`. 플레이 중에만 0.25초마다 `MainInstaller` 의 `RedDotService` 를 스냅샷으로 복사해 IMGUI 로 그림. 서비스가 없거나 직접 구현한 `IRedDotService` 면 안내만 표시 |
| `RedDotDebugSnapshot` (internal) | `Capture(RedDotService)`: 이름 순 트리(`Entry`: Name, Path, Value, UnmutedValue, Muted, Kind, UnmutedKindValues, ListenerCount, Children), 노드 없이 구독만 있는 경로, 노드 수, 열린 일괄 범위 수. `FormatLabel(Entry)` 예: `"Season = 0 [뮤트, 원래 3] 구독 2"`. 종류가 둘 이상이면 리프에 `{종류 1}`, 부모에 0이 아닌 종류별 값 `{0:1 2:2}` |
