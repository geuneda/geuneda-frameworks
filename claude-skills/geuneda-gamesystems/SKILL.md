---
name: geuneda-gamesystems
description: 여러 게임에서 반복 구현하던 게임 시스템을 모은 패키지(com.geuneda.gamesystems)의 코드를 작성하거나 수정할 때 사용하는 스킬. 레드닷(알림 배지) 트리, IRedDotService, RedDotBinding, RedDotView 를 쓰거나, 이 패키지에 새 기능을 추가할 때 활성화한다.
---

# Geuneda Game Systems

여러 게임 프로젝트에서 매번 다시 만들던 게임 시스템을 모은 UPM 패키지이다. 기능마다 asmdef가 나뉘어 있어 프로젝트는 필요한 기능만 참조한다. 현재 기능은 레드닷 하나다.

## 활성화 시점

- 버튼/탭/리스트 셀에 레드닷(알림 배지)을 붙일 때
- `IRedDotService`로 노드를 등록하거나 값을 설정할 때
- `RedDotView` 컴포넌트를 프리팹에 붙이거나 `RedDotBinding`으로 자체 뷰를 구독시킬 때
- 콘텐츠 잠금 구간의 배지를 막을 때(뮤트)
- 이 패키지에 새 게임 시스템 기능을 추가할 때

## 패키지 정보

- **네임스페이스**: `Geuneda.GameSystems.RedDot` (기능마다 `Geuneda.GameSystems.<기능>`)
- **어셈블리**: `Geuneda.GameSystems.RedDot`
- **설치**: `https://github.com/geuneda/geuneda-gamesystems.git` (버전 고정 `#v0.2.0`)
- **의존성**: `com.geuneda.services` (UniTask, gamedata 도 manifest 에 함께 있어야 한다)
- **최소 Unity 버전**: 6000.3
- **패키지 기여 가이드**: 패키지 루트의 `AGENTS.md`가 정보의 원천이다(설계 불변식, 구조 규칙).

## 레드닷 핵심 API

### IRedDotService (MainInstaller 에 바인딩해서 쓴다)
- `RegisterNode(string path)` - 노드 등록. 없는 조상은 자동 생성. 잘못된 경로("/A", "A/", "A//B", 빈 문자열)는 `ArgumentException`
- `UnregisterNode(string path)` - 노드와 하위 제거. 값이 있던 경로 구독자에게 0을 알림, 구독은 유지
- `SetLeafValue(string path, int value)` - 리프 값 설정(0 꺼짐, 1 이상 켜짐, 음수는 0). 부모 노드에는 설정 불가(경고)
- `SetNodeMuted(string path, bool muted)` - 뮤트. 하위 값은 보존되고 상위로만 0 전파
- `GetValue(string path)` - 현재 값. 부모는 자식 합, 없는 경로는 0, 합이 int 범위를 넘으면 `int.MaxValue`
- `Subscribe(string path, Action<int>)` / `Unsubscribe(...)` - 경로 구독. 등록 전에도 구독 가능
- `Paths` - 등록된 모든 경로(디버그 도구용)
- `Clear()` - 모든 노드 제거, 구독은 유지

### RedDotView (sealed MonoBehaviour)
- 인스펙터: `_nodePath`(경로), `_indicator`(값이 1 이상일 때 켤 자식 오브젝트)
- 배치: 뷰는 계속 활성인 오브젝트(버튼 등)에 두고 `_indicator`는 별도 자식으로 지정한다. 자신이나 조상을 지정하면 무시하고 오류를 남긴다
- `ValueChanged` 핸들러 예외는 핸들러 단위로 격리되고, 앞선 핸들러가 경로를 바꾸거나 뷰를 끄면 남은 핸들러에 옛 값을 보내지 않는다(합성 델리게이트도 호출 단위로 적용)
- `event Action<int> ValueChanged`, `int Value`, `string NodePath`
- `SetNodePath(string)` - 런타임 경로 변경(리스트 셀 등)

### RedDotBinding (POCO)
- `new RedDotBinding(Action<int> onValueChanged)`
- `Bind(string path)` - MainInstaller 에서 서비스를 찾아 구독하고 현재 값을 즉시 전달
- `Bind(IRedDotService service, string path)` - 서비스를 직접 넘김(테스트/DI)
- `Unbind()`, `Path`, `IsBound`

## 사용 패턴

### 서비스 바인딩과 노드 등록 (게임 초기화)
```csharp
using Geuneda.GameSystems.RedDot;
using Geuneda.Services;

var redDot = new RedDotService();
MainInstaller.Bind<IRedDotService>(redDot);

redDot.RegisterNode(RedDotPaths.Lobby_Shop_Free);
redDot.RegisterNode(RedDotPaths.Lobby_Quest);
redDot.RegisterNode(RedDotPaths.Lobby_Season_Reward);
```

### 경로 상수는 게임 쪽에 둔다
```csharp
public static class RedDotPaths
{
    public const string Lobby = "Lobby";
    public const string Lobby_Shop = Lobby + "/Shop";
    public const string Lobby_Shop_Free = Lobby_Shop + "/Free";
    public const string Lobby_Quest = Lobby + "/Quest";
    public const string Lobby_Season = Lobby + "/Season";
    public const string Lobby_Season_Reward = Lobby_Season + "/Reward";

    public static string QuestLeaf(int questId) => Lobby_Quest + "/" + questId;
}
```

### 값 설정은 서비스 계층에서 (Presenter/View 에서 하지 않는다)
```csharp
_redDot.SetLeafValue(RedDotPaths.Lobby_Shop_Free, hasFreeItem ? 1 : 0);
_redDot.SetNodeMuted(RedDotPaths.Lobby_Season, !isSeasonOpen);   // 잠긴 콘텐츠는 0으로 덮지 말고 뮤트
```

### 표시: RedDotView 를 붙이고, 추가 표시는 이벤트로 조합
```csharp
public sealed class RedDotCountLabel : MonoBehaviour
{
    [SerializeField] private RedDotView _redDot;
    [SerializeField] private TMP_Text _label;

    private void OnEnable()
    {
        _redDot.ValueChanged += Show;
        Show(_redDot.Value);
    }

    private void OnDisable() => _redDot.ValueChanged -= Show;

    private void Show(int value) => _label.text = value > 99 ? "99+" : value.ToString();
}
```

### 자체 뷰가 있으면 RedDotBinding
```csharp
private RedDotBinding _binding;

private void Awake() => _binding = new RedDotBinding(OnRedDotChanged);   // 필드 초기화식에서는 메서드를 못 넘긴다
private void OnEnable() => _binding.Bind(RedDotPaths.Lobby_Shop);
private void OnDisable() => _binding.Unbind();
```

## 알림 동작 규칙

- 값을 바꾸는 메서드는 트리 전체를 먼저 갱신하고 끝에서 구독자를 호출한다. 콜백 안에서는 항상 일관된 트리를 본다.
- 콜백 안에서 값을 바꿔도 된다. 즉시 반영되고 알림은 이어서 전달된다. 각 구독자가 마지막으로 받는 값은 항상 현재 값이다(중간 값은 생략될 수 있다).
- 구독자에게는 그 구독자가 마지막으로 받은 값과 달라졌을 때만 알린다. 구독 시점 값은 전달하지 않으므로 직접 `GetValue`로 읽는다(`RedDotBinding`이 한다).
- 해제한 구독자는 진행 중인 알림에서도 다시 호출되지 않는다. 콜백 예외는 로그만 남기고 나머지 구독자 알림은 계속한다.

## 주의사항

- 이 패키지는 기존 운영 프로젝트로 이관하지 않고 신규 프로젝트에서 쓴다.
- 레드닷 경로 구분자는 `RedDotService.Separator`('/')이다.
- 부모 노드 값은 자식 합이다. 리프에 자식이 생기면 기존 리프 값은 버려진다.
- `RedDotView`/`RedDotBinding`은 서비스가 바인딩된 뒤에 활성화돼야 한다. 서비스가 없으면 0으로 표시하고 구독하지 않는다.
- 상속용 기반 MonoBehaviour 는 없다(프레임워크 규칙: 2단계 이상 MonoBehaviour 상속 금지). 커스텀 표시는 `ValueChanged` 구독이나 `RedDotBinding` 조합으로 만든다.
- 새 기능을 추가할 때: `Runtime/<기능>/` 폴더와 asmdef 하나, 기능끼리 서로 참조 금지, 게임 규칙/경로/수치는 넣지 않는다.

## 참조 문서

상세 API 는 `references/api.md` 참조.
