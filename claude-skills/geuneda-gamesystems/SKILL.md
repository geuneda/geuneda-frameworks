---
name: geuneda-gamesystems
description: com.geuneda.gamesystems 패키지(네임스페이스 Geuneda.GameSystems.*)로 코드를 작성하거나 수정할 때 사용하는 스킬. 버튼/탭/리스트 셀에 레드닷(알림 배지)을 붙이거나, IRedDotService/RedDotService 로 경로 노드를 등록하고 값을 설정하거나, RedDotView 컴포넌트나 RedDotBinding 으로 화면을 구독시키거나, 잠긴 콘텐츠의 배지를 뮤트하거나, 이 패키지에 새 게임 시스템 기능(asmdef)을 추가할 때 활성화한다.
---

# Geuneda Game Systems

여러 게임 프로젝트에서 매번 다시 만들던 게임 시스템을 모은 UPM 패키지다. 기능마다 asmdef가 나뉘어 있어 프로젝트는 필요한 기능만 참조한다. 현재 기능은 레드닷 하나다.

## 패키지 정보

- **네임스페이스 / 어셈블리**: `Geuneda.GameSystems.RedDot` (기능마다 `Geuneda.GameSystems.<기능>`)
- **설치**: `https://github.com/geuneda/geuneda-gamesystems.git` (버전 고정이 필요하면 `#<태그>`, 실제 있는 태그만)
- **의존성**: `com.geuneda.services` 2.1.0. git 의존성은 자동 해결되지 않으므로 manifest 에 UniTask, core, gamedata, services 를 함께 넣는다(services 3.0.0 부터 core 필요)
- **최소 Unity 버전**: 6000.3
- **기여 가이드**: 패키지 루트의 `AGENTS.md`(구조 규칙, 설계 불변식, 테스트 실행)

## 레드닷 핵심 API

전체 시그니처는 `references/api.md`.

- `IRedDotService` / `RedDotService`: `RegisterNode`, `UnregisterNode`, `SetLeafValue`, `SetNodeMuted`, `GetValue`, `Subscribe`/`Unsubscribe`, `Paths`, `Clear`. `MainInstaller.Bind<IRedDotService>(...)` 로 바인딩해서 쓴다.
- `RedDotView` (sealed MonoBehaviour): 인스펙터 `_nodePath`, `_indicator`. `event Action<int> ValueChanged`, `int Value`, `string NodePath`, `SetNodePath(string)`.
- `RedDotBinding` (POCO): `new RedDotBinding(Action<int>)`, `Bind(string path)`(MainInstaller 에서 서비스 조회), `Bind(IRedDotService, string)`(직접 주입), `Unbind()`, `Path`, `IsBound`.

## 사용 패턴

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

### 서비스 바인딩과 노드 등록 (게임 초기화)
```csharp
using Geuneda.GameSystems.RedDot;
using Geuneda.Services;

var redDot = new RedDotService();
MainInstaller.Bind<IRedDotService>(redDot);

redDot.RegisterNode(RedDotPaths.Lobby_Shop_Free);   // 조상 노드 자동 생성
redDot.RegisterNode(RedDotPaths.Lobby_Quest);
redDot.RegisterNode(RedDotPaths.Lobby_Season_Reward);
```

### 값 설정은 서비스 계층에서 (Presenter/View 에서 하지 않는다)
```csharp
_redDot.SetLeafValue(RedDotPaths.Lobby_Shop_Free, hasFreeItem ? 1 : 0);
_redDot.SetNodeMuted(RedDotPaths.Lobby_Season, !isSeasonOpen);   // 잠긴 콘텐츠는 0으로 덮지 말고 뮤트
```

### 표시: RedDotView 를 붙이고, 추가 표시는 이벤트로 조합
```csharp
using Geuneda.GameSystems.RedDot;
using TMPro;
using UnityEngine;

public sealed class RedDotCountLabel : MonoBehaviour
{
    [SerializeField] private RedDotView _redDot;
    [SerializeField] private TMP_Text _label;

    private void OnEnable()
    {
        _redDot.ValueChanged += Show;
        Show(_redDot.Value);   // 늦게 구독했으므로 현재 값을 직접 읽는다
    }

    private void OnDisable() => _redDot.ValueChanged -= Show;

    private void Show(int value) => _label.text = value > 99 ? "99+" : value.ToString();
}
```

### 자체 뷰가 있으면 RedDotBinding
```csharp
using Geuneda.GameSystems.RedDot;
using UnityEngine;

public sealed class ShopTabBadge : MonoBehaviour
{
    [SerializeField] private GameObject _dot;

    private RedDotBinding _binding;

    private void Awake() => _binding = new RedDotBinding(OnRedDotChanged);   // 필드 초기화식에서는 인스턴스 메서드를 못 넘긴다
    private void OnEnable() => _binding.Bind(RedDotPaths.Lobby_Shop);
    private void OnDisable() => _binding.Unbind();

    private void OnRedDotChanged(int value) => _dot.SetActive(value > 0);
}
```

## 알림 동작 규칙

- 값을 바꾸는 메서드는 트리 전체를 먼저 갱신하고 끝에서 구독자를 호출한다. 콜백 안에서는 항상 일관된 트리를 본다.
- 콜백 안에서 값을 바꿔도 된다. 즉시 반영되고 알림은 이어서 전달된다. 각 구독자가 마지막으로 받는 값은 항상 현재 값이다(중간 값은 생략될 수 있다).
- 구독자에게는 그 구독자가 마지막으로 받은 값과 달라졌을 때만 알린다. 구독 시점 값은 전달하지 않으므로 직접 `GetValue`로 읽는다(`RedDotBinding`은 Bind 직후 현재 값을 전달한다).
- 해제한 구독자는 진행 중인 알림에서도 다시 호출되지 않는다. 콜백 예외는 로그만 남기고 나머지 구독자 알림은 계속한다.
- 등록 전 경로도 구독할 수 있다. `UnregisterNode`/`Clear`는 값이 있던 경로 구독자에게 0을 알리고 구독은 유지한다.

## 함정

- 부모 노드 값은 자식 합이다. 부모에 `SetLeafValue` 하면 경고 로그만 남고 무시된다. 리프에 자식이 생기면 기존 리프 값은 버려진다.
- 미등록 경로에 `SetLeafValue`/`SetNodeMuted` 하면 경고 후 무시된다. 먼저 `RegisterNode` 한다.
- `RegisterNode`에 잘못된 경로(빈 문자열, "/A", "A/", "A//B")를 넘기면 `ArgumentException`. 구분자는 `RedDotService.Separator`('/')다.
- `RedDotView`/`RedDotBinding.Bind(path)`는 `MainInstaller`에 서비스가 바인딩된 뒤에 활성화/호출돼야 한다. 서비스가 없으면 0으로 표시하고 구독하지 않으며, 나중에 바인딩해도 자동으로 다시 구독하지 않는다.
- `RedDotView`는 계속 활성인 오브젝트(버튼 등)에 두고 `_indicator`는 별도 자식으로 지정한다. 자신이나 조상을 지정하면 무시되고 오류가 남는다.
- 같은 콜백을 `Subscribe`로 여러 번 등록하면 그만큼 호출되고, `Unsubscribe`는 마지막에 추가한 하나만 해제한다.
- 상속용 기반 MonoBehaviour 는 없다(프레임워크 규칙: 2단계 이상 MonoBehaviour 상속 금지). 커스텀 표시는 `ValueChanged` 구독이나 `RedDotBinding` 조합으로 만든다.
- 이 패키지는 기존 운영 프로젝트로 이관하지 않고 신규 프로젝트에서 쓴다.

## 새 기능을 추가할 때

- `Runtime/<기능>/` 폴더와 `Geuneda.GameSystems.<기능>.asmdef` 하나. 기능 asmdef끼리 서로 참조 금지, 의존은 `Geuneda.GameData`, `Geuneda.Services`까지.
- 게임 규칙, 경로, 수치는 넣지 않고 델리게이트, 이벤트, 인터페이스로 연다.
- 공개 MonoBehaviour 는 `sealed`, 로직은 POCO. 테스트는 `Tests/EditMode/<기능>/`, `Tests/PlayMode/<기능>/`.
- 패키지 `README.md` 기능 표, `CHANGELOG.md`, `package.json` 버전과 이 스킬 문서를 함께 갱신한다.
