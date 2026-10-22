---
name: geuneda-gamesystems
description: com.geuneda.gamesystems 패키지(네임스페이스 Geuneda.GameSystems.*)로 코드를 작성하거나 수정할 때 사용하는 스킬. 버튼/탭/리스트 셀에 레드닷(알림 배지)을 붙이거나, 빨간 점·새 항목·강화 가능처럼 종류가 다른 배지를 나누거나(RedDotService(kindCount), RedDotPriorityGroup 으로 하나만 표시), IRedDotService/RedDotService 로 경로 노드를 등록하고 값을 설정하거나, BeginBatch 로 여러 리프를 한 번에 바꾸거나, RedDotView 컴포넌트나 RedDotBinding 으로 화면을 구독시키거나, 잠긴 콘텐츠의 배지를 뮤트하거나, 레벨·아이템 같은 조건으로 기능을 잠그고 열거나(IFeatureUnlockService/FeatureUnlockService, Register·Refresh·IsUnlocked, 원격 차단 SetDisabled, FeatureLockView/FeatureUnlockBinding), RedDot Debugger 창으로 배지가 안 뜨는 원인을 찾거나, 이 패키지에 새 게임 시스템 기능(asmdef)을 추가할 때 활성화한다.
---

# Geuneda Game Systems

여러 게임 프로젝트에서 매번 다시 만들던 게임 시스템을 모은 UPM 패키지다. 기능마다 asmdef가 나뉘어 있어 프로젝트는 필요한 기능만 참조한다. 현재 기능은 레드닷과 기능 개방이다.

## 패키지 정보

- **네임스페이스 / 어셈블리**: `Geuneda.GameSystems.RedDot`, `Geuneda.GameSystems.FeatureUnlock` (기능마다 `Geuneda.GameSystems.<기능>`), 레드닷 에디터 디버그 창은 `Geuneda.GameSystems.RedDot.Editor`
- **설치**: `https://github.com/geuneda/geuneda-gamesystems.git` (버전 고정이 필요하면 `#<태그>`, 실제 있는 태그만)
- **현재 버전**: 0.4.0
- **의존성**: `com.geuneda.services` 5.1.0 이상(`MainInstaller.BindingChanged`). git 의존성은 자동 해결되지 않으므로 manifest 에 UniTask, core, gamedata, services 를 함께 넣는다(services 3.0.0 부터 core 필요)
- **최소 Unity 버전**: 6000.3
- **기여 가이드**: 패키지 루트의 `AGENTS.md`(구조 규칙, 설계 불변식, 테스트 실행)

## 레드닷 핵심 API

전체 시그니처는 `references/api.md`.

- `IRedDotService` / `RedDotService`: `RegisterNode`, `UnregisterNode`, `SetLeafValue`, `SetNodeMuted`, `GetValue`, `Subscribe`/`Unsubscribe`, `Paths`(읽기 전용 스냅샷), `Clear`, `BeginBatch()`(일괄 변경 범위 `RedDotBatch`). `MainInstaller.Bind<IRedDotService>(...)` 로 바인딩해서 쓴다.
- 배지 종류(0.4.0): `new RedDotService(kindCount)`(1~32), `KindCount`, `RegisterNode(path, kind)`, `GetValue(path, kind)`, `Subscribe/Unsubscribe(path, kind, callback)`, `RedDotService.AllKinds`(-1, 합). 종류 없는 멤버는 모든 종류의 합이다.
- `RedDotView` (sealed MonoBehaviour): 인스펙터 `_nodePath`, `_kind`(기본 -1 = 합), `_indicator`. `event Action<int> ValueChanged`, `int Value`, `int Kind`, `string NodePath`, `SetNodePath(string)`.
- `RedDotPriorityGroup` (sealed MonoBehaviour): 인스펙터 `_entries`(뷰 + 표시 오브젝트, 앞이 우선). 값이 1 이상인 첫 항목의 표시만 켠다. `int ActiveIndex`.
- `RedDotBinding` (POCO): `new RedDotBinding(Action<int>)`, `new RedDotBinding(Action<int>, int kind)`, `Bind(string path)`(MainInstaller 에서 서비스 조회, `Unbind` 까지 늦은 바인딩·교체·정리를 따라감), `Bind(IRedDotService, string)`(직접 주입, MainInstaller 를 따라가지 않음), `Unbind()`, `Path`, `IsBound`(서비스를 기다리는 중이면 false).
- 에디터: `Tools > Geuneda > RedDot Debugger`(플레이 중 트리, 값, 뮤트, 구독자 수, 노드 없는 구독 경로, 열린 일괄 범위 수).

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

### 배지 종류: 한 버튼에 모양이 다른 배지가 겹칠 때
```csharp
public static class BadgeKinds { public const int Red = 0, New = 1, Upgrade = 2, Count = 3; }

var redDot = new RedDotService(BadgeKinds.Count);
redDot.RegisterNode("Equip/Slot1/Upgrade", BadgeKinds.Upgrade);   // 리프마다 종류 하나
redDot.RegisterNode("Equip/Slot1/New", BadgeKinds.New);
redDot.SetLeafValue("Equip/Slot1/New", 1);
redDot.GetValue("Equip", BadgeKinds.New);   // 1, 종류 없는 GetValue 는 합
```
화면은 종류별 `RedDotView`(`_kind`, `_indicator` 비움)를 같은 버튼에 두고 `RedDotPriorityGroup` 의 `_entries` 에 우선순위 순서로 [뷰, 표시 오브젝트]를 넣는다. 종류 번호의 뜻과 우선순위는 게임이 정한다.

### 씬 단위 노드는 한 루트 아래에
맵 안에서만 쓰는 노드는 `Map/...` 아래에 두고 씬을 떠날 때 `UnregisterNode("Map")` 으로 한 번에 지운다. 구독은 유지돼 다시 등록하면 이어서 알림을 받는다.

### 여러 리프를 한 번에 바꿀 때는 BeginBatch
```csharp
// 범위 밖에서 리프 50개를 켜면 부모 구독자가 50번 불린다. 범위 안에서는 끝날 때 최종 값으로 한 번.
using (_redDot.BeginBatch())
{
    foreach (var quest in quests)
    {
        string path = RedDotPaths.QuestLeaf(quest.Id);
        _redDot.RegisterNode(path);
        _redDot.SetLeafValue(path, quest.IsClaimable ? 1 : 0);
    }
}
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

## 기능 개방 (`Geuneda.GameSystems.FeatureUnlock`)

조건(레벨, 아이템, 진행도)을 채워야 열리는 기능의 잠금. 조건 내용은 게임의 판정 함수, 패키지는 판정 결과를 들고 바뀔 때만 알린다. 전체 시그니처는 `references/api.md`.

```csharp
using Geuneda.GameSystems.FeatureUnlock;

var features = new FeatureUnlockService();
MainInstaller.Bind<IFeatureUnlockService>(features);

features.Register(FeatureIds.Shop, () => player.Level >= 5);   // 등록할 때 한 번 판정
features.Refresh();                                            // 조건에 쓰는 값이 바뀌면 다시 판정
bool open = features.IsUnlocked(FeatureIds.Shop);              // 판정 함수를 부르지 않고 마지막 결과
features.SetDisabled(FeatureIds.Gacha(6001), true);            // 원격 차단(미등록 기능도)
features.StateChanged += (id, unlocked) => redDot.SetNodeMuted(PathOf(id), !unlocked);   // 레드닷 뮤트는 게임 코드에서 잇는다
```

- 열림 = 차단 아님 && (미등록 || `IgnoreConditions` || 마지막 판정). 미등록 기능은 열림이므로 ID 오타는 늘 열림으로 보인다. 상수로 둔다.
- `StateChanged` 는 마지막으로 알린 상태와 다를 때만, 처음 기준은 열림. 로그인 때 이미 열려 있던 기능은 알리지 않으므로 "새로 열림" 연출은 세이브의 본 목록과 `IsUnlocked` 로 따로 확인한다.
- 판정 함수는 `Register`/`Refresh` 때만 부른다. 레벨업·아이템 획득 처리기에서 `Refresh()` 를 부르지 않으면 상태가 그대로다.
- 같은 ID `Register` 두 번은 `ArgumentException`(바꾸려면 `Unregister` 후 등록), 빈 ID 는 `ArgumentException`. 판정 함수 예외는 오류 로그 후 잠김.
- `IgnoreConditions`(치트)는 `#if !GEUNEDA_ENV_PROD && (UNITY_EDITOR || DEVELOPMENT_BUILD || GEUNEDA_ENV_DEV || GEUNEDA_ENV_QA)` 안에서만 켠다. 원격 차단은 무시하지 않는다.
- `Clear()` 는 등록만 지우고 원격 차단은 유지한다.
- 화면: `FeatureLockView`(`_featureId`, `_lockedObject`, `_unlockedObject`, `StateChanged`, `IsUnlocked`, `SetFeatureId`) 또는 `FeatureUnlockBinding(Action<bool>)`. 둘 다 `MainInstaller` 를 따라가고 서비스가 없으면 잠김, 빈 ID 는 열림.

## 알림 동작 규칙

- 값을 바꾸는 메서드는 트리 전체를 먼저 갱신하고 끝에서 구독자를 호출한다. 콜백 안에서는 항상 일관된 트리를 본다.
- 콜백 안에서 값을 바꿔도 된다. 즉시 반영되고 알림은 이어서 전달된다. 각 구독자가 마지막으로 받는 값은 항상 현재 값이다(중간 값은 생략될 수 있다).
- 구독자에게는 그 구독자가 마지막으로 받은 값과 달라졌을 때만 알린다. 구독 시점 값은 전달하지 않으므로 직접 `GetValue`로 읽는다(`RedDotBinding`은 Bind 직후 현재 값을 전달한다).
- 해제한 구독자는 진행 중인 알림에서도 다시 호출되지 않는다. 콜백 예외는 로그만 남기고 나머지 구독자 알림은 계속한다.
- 등록 전 경로도 구독할 수 있다. `UnregisterNode`/`Clear`는 값이 있던 경로 구독자에게 0을 알리고 구독은 유지한다.
- `BeginBatch()` 범위 안에서는 값만 바뀌고(`GetValue` 는 바뀐 값) 알림은 열린 범위가 모두 끝날 때 경로마다 최종 값으로 한 번 간다. 중첩·순서 무관 종료·두 번 Dispose 모두 안전하다. 콜백 안에서 연 범위도 남은 알림을 미룬다. 끝내지 않은 범위가 남으면 알림이 계속 멈추므로 반드시 `using` 으로 감싼다.
- 콜백끼리 값을 계속 바꿔 한 번의 처리에서 같은 경로를 100번 넘게 알리면 오류 로그 후 그 처리에서 그 경로를 건너뛴다(멈춤 방지).

## 함정

- 부모 노드 값은 자식 합이다. 부모에 `SetLeafValue` 하면 경고 로그만 남고 무시된다. 리프에 자식이 생기면 기존 리프 값은 버려진다.
- 미등록 경로에 `SetLeafValue`/`SetNodeMuted` 하면 경고 후 무시된다. 먼저 `RegisterNode` 한다.
- `RegisterNode`에 잘못된 경로(빈 문자열, "/A", "A/", "A//B")를 넘기면 `ArgumentException`. 구분자는 `RedDotService.Separator`('/')다.
- `RedDotView`/`RedDotBinding.Bind(path)`는 서비스보다 먼저 활성화돼도 된다(0을 표시하다가 바인딩되면 구독). 서비스를 교체·정리하면 따라가고, 값이 그대로면 같은 값을 다시 보내지 않는다. 부트스트랩이 `OnDestroy` 에서 `MainInstaller.Clean()` 을 부르면 켜진 뷰는 0을 받는다.
- 배지가 안 뜨면 `RedDot Debugger` 창의 "노드 없이 구독만 있는 경로"(경로 오타)와 열린 일괄 범위 수를 먼저 본다.
- `RedDotView`는 계속 활성인 오브젝트(버튼 등)에 두고 `_indicator`는 별도 자식으로 지정한다. 자신이나 조상을 지정하면 무시되고 오류가 남는다.
- 같은 콜백을 `Subscribe`로 여러 번 등록하면 그만큼 호출되고, `Unsubscribe`는 마지막에 추가한 하나만 해제한다.
- 종류 구독자는 그 종류만 본다. 빨간 점이 꺼지고 같은 수의 새 항목이 켜지면 합 구독자(`RedDotView` 기본값 포함)는 불리지 않는다. 종류마다 다른 표시가 필요하면 종류별 뷰를 쓴다.
- 이미 있는 노드에 `RegisterNode(path)`(종류 없음)를 다시 불러도 종류는 바뀌지 않는다. 종류를 바꾸려면 `RegisterNode(path, kind)`. 자동 생성된 조상은 종류 0이라, 자식이 모두 사라져 리프가 되면 종류 0 으로 값을 받는다.
- `RedDotPriorityGroup` 으로 묶은 뷰에 `_indicator` 를 지정하면 그룹과 뷰가 같은 오브젝트를 따로 켜고 끈다. 뷰의 `_indicator` 는 비운다.
- 상속용 기반 MonoBehaviour 는 없다(프레임워크 규칙: 2단계 이상 MonoBehaviour 상속 금지). 커스텀 표시는 `ValueChanged` 구독이나 `RedDotBinding` 조합으로 만든다.
- 이 패키지는 기존 운영 프로젝트로 이관하지 않고 신규 프로젝트에서 쓴다.

## 새 기능을 추가할 때

- `Runtime/<기능>/` 폴더와 `Geuneda.GameSystems.<기능>.asmdef` 하나. 기능 asmdef끼리 서로 참조 금지, 의존은 `Geuneda.Core`, `Geuneda.GameData`, `Geuneda.Services`까지.
- 에디터 도구는 `Editor/<기능>/Geuneda.GameSystems.<기능>.Editor.asmdef`(Editor 플랫폼만). 런타임 내부는 `InternalsVisibleTo` 로 열고 디버그용 공개 API 를 늘리지 않는다.
- 게임 규칙, 경로, 수치는 넣지 않고 델리게이트, 이벤트, 인터페이스로 연다.
- 공개 MonoBehaviour 는 `sealed`, 로직은 POCO. 테스트는 `Tests/EditMode/<기능>/`, `Tests/PlayMode/<기능>/`.
- 패키지 `README.md` 기능 표, `CHANGELOG.md`, `package.json` 버전과 이 스킬 문서를 함께 갱신한다.
