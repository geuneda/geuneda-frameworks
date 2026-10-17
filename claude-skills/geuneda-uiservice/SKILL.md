---
name: geuneda-uiservice
description: com.geuneda.uiservice 패키지(네임스페이스 Geuneda.UiService, Geuneda.UiService.Views)로 Unity UI 를 다루는 코드를 작성하거나 수정할 때 사용한다. UiPresenter/UiPresenter<T> 프레젠터 작성, IUiService 로 UI 로드/열기/닫기/언로드, UiConfigs 설정 에셋과 UI 세트 구성, 다중 인스턴스(UiInstanceId), PresenterFeatureBase/ITransitionFeature 피처, UI Toolkit 연동(UiToolkitPresenterFeature, UiToolkitPanelRendererFeature), IUiAssetLoader 로더, SafeAreaHelperView 등 헬퍼 뷰를 다루거나, 뒤로가기(HandlesBack, HandleBack, AddBackHandler, BackUnhandled, ReadsBackInput), 팝업 큐(UiPopupQueue, Hold), 모달 dim(IsModal, DimColor), 입력 차단(BlockInput), 표시 상태 이벤트(PresenterOpened/PresenterClosed)를 쓸 때 활성화한다.
---

# Geuneda UI Service

UI 프레젠터의 로드, 열기, 닫기, 언로드를 `UiService` 한 곳에서 관리하는 패키지. 레이어 정렬, UI 세트, 다중 인스턴스, 피처 조합, 교체 가능한 에셋 로더, 뒤로가기, 우선순위 팝업 큐, 모달 dim, 입력 차단을 제공한다.

## 패키지 정보

- 패키지: `com.geuneda.uiservice` 3.1.0 (`package.json` 기준). 3.1.0 은 uGUI 같은 레이어 정렬과 여러 큐의 로드 중 대기를 바꾼 동작 변경(API 동일)이고, 3.0.0 은 core 의존성을 추가한 호환성 파괴 버전이며 core 를 넣지 않을 프로젝트는 `#v2.0.0`, `IUiService` 멤버가 추가되기 전 프로젝트는 `#v1.3.2` 로 고정한다
- 설치: `https://github.com/geuneda/geuneda-uiservice.git` (core 와 UniTask 는 manifest 에 직접 추가해야 함)
- 의존성: `com.geuneda.core` 0.4.0(로거 `ModuleLogger`, 로그는 `[Geuneda.UiService]`·`[Geuneda.UiService.<기능>]` 로 시작), `com.unity.addressables` 2.6.0, `com.cysharp.unitask` 2.5.10, `com.unity.ugui` 2.0.0. 헬퍼 뷰는 uGUI/TextMeshPro 사용. 선택: `com.unity.inputsystem`(있으면 `ReadsBackInput` 이 Input System 사용)
- Unity 6000.0+ (`UiToolkitPanelRendererFeature` 는 6000.5+)
- 소스: geuneda-frameworks 레포의 `Packages/com.geuneda.uiservice/` (`Runtime/`, `Editor/`, `docs/`)
- 전체 공개 API: [references/api.md](references/api.md)

## 핵심 API

```csharp
// 소유자: 생성, 초기화, 해제
IUiServiceInit service = new UiService();                    // 기본 AddressablesUiAssetLoader
IUiServiceInit service = new UiService(new ResourcesUiAssetLoader());
service.Init(uiConfigs);                                     // UiConfigs 파생 에셋
service.Dispose();

// 소비자: IUiService
UniTask<T> OpenUiAsync<T>(CancellationToken ct = default) where T : UiPresenter;
UniTask<T> OpenUiAsync<T, TData>(TData initialData, CancellationToken ct = default)
    where T : class, IUiPresenterData where TData : struct;
UniTask<T> LoadUiAsync<T>(bool openAfter = false, CancellationToken ct = default) where T : UiPresenter;
void CloseUi<T>(bool destroy = false) where T : UiPresenter;
void CloseUi(Type type, string instanceAddress, bool destroy = false);
void CloseAllUi();  void CloseAllUi(int layer);
void UnloadUi<T>() where T : UiPresenter;  void UnloadUi(Type type, string instanceAddress);
UniTask<UiPresenter[]> OpenUiSetAsync(int setId, CancellationToken ct = default);
IList<UniTask<UiPresenter>> LoadUiSetAsync(int setId);
void CloseAllUiSet(int setId);  void UnloadUiSet(int setId);
T GetUi<T>() where T : UiPresenter;           // 없으면 KeyNotFoundException
bool IsVisible<T>() where T : UiPresenter;
IReadOnlyList<UiInstanceId> VisiblePresenters { get; }
List<UiInstance> GetLoadedPresenters();
bool TryGetUi(UiInstanceId instanceId, out UiPresenter presenter);
event Action<UiInstanceId> PresenterOpened;   // 표시 목록에 들어간 직후 (Dispose 중엔 없음)
event Action<UiInstanceId> PresenterClosed;   // 표시 목록에서 빠진 직후 (Remove/Unload 포함)

// 뒤로가기, 입력 차단
bool HandleBack();                            // 차단 중 무시 → 핸들러 → 맨 위 HandlesBack 프레젠터 → BackUnhandled
IDisposable AddBackHandler(Func<bool> handler, int priority = 0);
event Action BackUnhandled;
UiInputBlock BlockInput(string reason);       // using 으로 풀기. IsInputBlocked, InputBlockReasons

// UiService 전용 (인스턴스 주소 지정)
T GetUi<T>(string instanceAddress);  bool IsVisible<T>(string instanceAddress);
UniTask<UiPresenter> OpenUiAsync(Type type, string instanceAddress, CancellationToken ct = default);
UniTask<UiPresenter> LoadUiAsync(Type type, string instanceAddress, bool openAfter = false, CancellationToken ct = default);
Color DimColor { get; set; }                  // 기본 (0,0,0,0.6)
bool ReadsBackInput { get; set; }             // Escape/Android 뒤로가기를 직접 읽음. 기본 false
```

```csharp
public abstract class UiPresenter : MonoBehaviour
{
    public bool IsOpen { get; }                     // gameObject.activeSelf
    public UniTask OpenTransitionTask { get; }
    public UniTask CloseTransitionTask { get; }
    protected IUiService _uiService;
    protected void Close(bool destroy);
    protected virtual void OnInitialized();
    protected virtual void OnOpened();
    protected virtual void OnClosed();
    protected virtual void OnOpenTransitionCompleted();
    protected virtual void OnCloseTransitionCompleted();
    protected virtual bool HandlesBack { get; }     // 기본 false
    protected virtual void OnBackPressed();         // 기본 Close(false)
    protected virtual bool IsModal { get; }         // 기본 false
    protected virtual void OnDimClicked();          // 기본 없음
}

public abstract class UiPresenter<T> : UiPresenter, IUiPresenterData where T : struct
{
    public T Data { get; set; }                     // set 할 때마다 OnSetData()
    protected virtual void OnSetData();
}
```

## 사용 패턴

### 초기화와 열기

```csharp
using Cysharp.Threading.Tasks;
using Geuneda.UiService;
using UnityEngine;

public class GameBootstrap : MonoBehaviour
{
    [SerializeField] private UiConfigs _uiConfigs;   // AddressablesUiConfigs 에셋
    private IUiServiceInit _uiService;

    private void Start()
    {
        _uiService = new UiService();
        _uiService.Init(_uiConfigs);
        OpenAsync().Forget();
    }

    private async UniTaskVoid OpenAsync()
    {
        var menu = await _uiService.OpenUiAsync<MainMenuPresenter>();
        await menu.OpenTransitionTask;               // 전환까지 기다릴 때
    }

    private void OnDestroy() => _uiService?.Dispose();
}
```

### 프레젠터

```csharp
using Geuneda.UiService;
using UnityEngine;
using UnityEngine.UI;

public class MainMenuPresenter : UiPresenter
{
    [SerializeField] private Button _playButton;

    protected override void OnInitialized()
    {
        _playButton.onClick.AddListener(() => Close(destroy: false));
    }
}

public struct PlayerInfoData
{
    public string Name;
    public int Level;
}

public class PlayerInfoPresenter : UiPresenter<PlayerInfoData>
{
    [SerializeField] private Text _nameText;

    protected override void OnSetData() => _nameText.text = $"{Data.Name} Lv.{Data.Level}";
}

// await _uiService.OpenUiAsync<PlayerInfoPresenter, PlayerInfoData>(new PlayerInfoData { Name = "Hero", Level = 10 });
```

### 로더별 구성

| 로더 | 설정 에셋 (`Create > ScriptableObjects > Configs > UiConfigs > ...`) | `Address` |
|------|------|------|
| `AddressablesUiAssetLoader` (기본) | `AddressablesUiConfigs` | Addressable 주소 |
| `ResourcesUiAssetLoader` | `ResourcesUiConfigs` | Resources 상대 경로(확장자 없음) |
| `PrefabRegistryUiAssetLoader(prefabRegistryConfigs)` | `PrefabRegistryUiConfigs` | 프리팹 이름 |

설정 에셋 종류가 로더를 고르지 않는다. 생성자에 맞는 로더를 직접 넘긴다. 설정 목록은 인스펙터를 열 때 소스(Addressable 그룹, Resources 폴더, 프리팹 레지스트리)에서 자동 동기화된다.

### 다중 인스턴스

```csharp
var uiService = new UiService();              // 주소 오버로드는 대부분 UiService 전용
uiService.Init(_uiConfigs);
await uiService.OpenUiAsync(typeof(TooltipPresenter), "item");
await uiService.OpenUiAsync(typeof(TooltipPresenter), "skill");
var item = uiService.GetUi<TooltipPresenter>("item");
uiService.CloseUi(typeof(TooltipPresenter), "item");
```

### 커스텀 전환 피처

```csharp
using Cysharp.Threading.Tasks;
using Geuneda.UiService;

// 프레젠터와 같은 GameObject 에 붙인다. 태스크는 OnPresenterOpened/OnPresenterClosing 안에서 만들어야 프레젠터가 기다린다.
public class FadeFeature : PresenterFeatureBase, ITransitionFeature
{
    private UniTaskCompletionSource _open, _close;
    public UniTask OpenTransitionTask => _open?.Task ?? UniTask.CompletedTask;
    public UniTask CloseTransitionTask => _close?.Task ?? UniTask.CompletedTask;

    public override void OnPresenterOpened()  { _open = new UniTaskCompletionSource();  /* 시작 후 끝나면 _open.TrySetResult() */ }
    public override void OnPresenterClosing() { _close = new UniTaskCompletionSource(); /* 시작 후 끝나면 _close.TrySetResult() */ }
}
```

### UI Toolkit

```csharp
using Geuneda.UiService;
using UnityEngine;
using UnityEngine.UIElements;

[RequireComponent(typeof(UiToolkitPresenterFeature))]
public class SettingsPresenter : UiPresenter
{
    [SerializeField] private UiToolkitPresenterFeature _toolkit;
    private Button _close;

    protected override void OnInitialized() => _toolkit.AddVisualTreeAttachedListener(root =>
    {
        if (_close != null) _close.clicked -= OnClose;           // 재생성된 요소 대비, 여러 번 호출돼도 안전하게
        _close = root.Q<Button>("close-button");
        if (_close != null) _close.clicked += OnClose;
    });

    private void OnClose() => Close(destroy: false);
}
```

`OnInitialized()` 에서 `rootVisualElement` 를 직접 쿼리하지 않는다. 콜백은 열 때마다, 한 번 열 때 여러 번 호출될 수 있다. Unity 6000.5+ 에서 `PanelRenderer` 를 쓰면 `UiToolkitPanelRendererFeature` 로 바꾼다(API 동일, `Document` 대신 `Panel`).

### 뒤로가기, 모달, 팝업 큐

```csharp
public class RewardPopup : UiPresenter
{
    protected override bool HandlesBack => true;    // 뒤로가기로 닫힘
    protected override bool IsModal => true;        // 맨 위 모달일 때 공용 dim
    protected override void OnDimClicked() => Close(false);
}

var uiService = new UiService { ReadsBackInput = true };
uiService.Init(uiConfigs);
uiService.BackUnhandled += () => uiService.OpenUiAsync<QuitConfirmPopup>().Forget();

var queue = new UiPopupQueue(uiService);           // 장면마다 만들고 떠날 때 Dispose (서비스보다 먼저)
queue.Enqueue("daily-reward", 100, ct => uiService.OpenUiAsync(typeof(DailyRewardPopup), ct));
queue.Enqueue("notice:42", 50, async ct => HasUnread(42) ? await uiService.OpenUiAsync<NoticePopup>(ct) : null);
using (queue.Hold("tutorial")) { await RunTutorialAsync(); }

using (uiService.BlockInput("purchase")) { await BuyAsync(); }
```

- 화면 맨 위 = 레이어가 높을수록, 같으면 나중에 연 프레젠터. 뒤로가기 대상과 dim 위치가 이 규칙을 쓴다. 열고 닫을 때마다 서비스가 UIDocument `sortingOrder` 를 `레이어 + 순번/1024`, uGUI 루트 `Canvas.sortingOrder` 를 `레이어 + 순번`(0 부터) 으로 매겨 화면도 이 순서다(닫기 전환 중인 것 포함). uGUI 값은 UiConfigs 의 다음 레이어 값보다 작게만 쓰므로 레이어를 띄워 둔다(예: 0, 10, 20). 간격이 모자라면 먼저 연 캔버스끼리 같은 값을 쓰고 레이어마다 한 번 경고(-32768~32766 밖 레이어는 경계 값부터, 경고). 자식 Canvas 와 PanelRenderer 는 다시 매기지 않는다. 루트 sortingOrder 로 레이어를 판단하지 않는다.
- 큐는 팝업이 닫히고 닫기 전환까지 끝나야 다음을 띄운다(닫기 중 재열기는 계속 추적). `Hold` 가 남았거나 큐 밖에서 연 `HandlesBack` 프레젠터가 떠 있으면 기다린다. 같은 key 는 넣지 않는다(false). 팩토리가 null 이면 건너뛴다. 같은 UiService 의 큐끼리는 팩토리를 하나씩 돌린다: 먼저 시작한 큐가 이기고, 팩토리가 끝나면(실패·취소·null 포함) 그때 진행할 수 있는 대기 큐가 기다린 순서대로 그 큐의 다음 항목보다 먼저 진행, 팝업이 뜬 뒤에는 HandlesBack 대기 규칙(닫히면 큐를 만든 순서로 다시 확인). 큐 사이는 우선순위가 아니라 시작 순서이므로 우선순위로 정할 팝업은 한 큐에. IUiService 직접 구현 서비스의 큐끼리는 조정 없음.
- `PresenterOpened/Closed` 는 `OnOpened/OnClosed` 보다 먼저 온다. 구독자와 열기·닫기 훅(OnOpened/OnClosed, 피처 시작·종료 콜백) 안에서 연 UI 의 알림과 훅은 지금 것이 끝난 뒤 실행된다(IsVisible 은 즉시). 전환 완료 훅(OnOpenTransitionCompleted/OnCloseTransitionCompleted)은 이 순서 밖이라 그 안에서 연 UI 의 훅은 곧바로 실행된다. 훅 예외는 전환 태스크를 같은 예외로 실패시키고 한 번 기록된다. `BlockInput` 은 포인터와 함께 EventSystem 선택·내비게이션, UIDocument 패널 키 입력도 막는다(막힌 동안 새 EventSystem·패널 포함, 선택은 복구 안 함). `RemoveUi`/`UnloadUi` 는 진행 중인 전환 태스크를 완료한다.
- dim 은 루트 `Canvas`(첫 자식 `UiDim`) 또는 `UIDocument`(같은 PanelSettings, 모달 문서보다 1/2048 낮은 `UiDimDocument`)에만 깔린다.
- 자세한 규칙: 패키지 `docs/navigation.md`.

## 생명주기 순서

- 추가: (인스턴스화 → `SetActive(false)`) → 레이어 반영 → 피처 `OnPresenterInitialized` → `OnInitialized`
- 열기: 피처 `OnPresenterOpening` → `SetActive(true)` → `OnOpened` → 피처 `OnPresenterOpened` → 전환 대기 → `OnOpenTransitionCompleted`
- 닫기: 피처 `OnPresenterClosing` → `OnClosed` → 피처 `OnPresenterClosed` → 전환 대기 → `SetActive(false)` → `OnCloseTransitionCompleted` → `destroy` 면 `UnloadUi`
- 전환 중 반대 동작이 끼어들면 늦게 끝난 쪽은 결과를 내지 않는다(닫기 중 재열기: 숨김·언로드·`OnCloseTransitionCompleted` 생략, 열기 중 닫기: `OnOpenTransitionCompleted` 생략).
- 2.0.0 부터 `OpenUi` 는 표시 목록에 먼저 넣고 연다. `OnOpened` 안에서 연 UI 는 그 뒤 순서가 된다.

## 함정

- `UiPresenter`, 피처, `Canvas`/`UIDocument` 는 프리팹 **루트**에 둔다. 자식의 피처는 수집되지 않고 자식 Canvas 는 레이어 정렬 대상이 아니다.
- `OpenUiAsync`/`CloseUi` 는 전환을 기다리지 않는다. 필요하면 `OpenTransitionTask`/`CloseTransitionTask` 를 `await`.
- `IsVisible<T>()` 는 서비스 표시 목록 기준, `IsOpen` 은 `activeSelf` 기준. 닫기 전환 중에는 서로 다르다.
- 설정은 타입당 하나. 주소 없는 `LoadUiAsync`/`OpenUiAsync` 의 인스턴스 주소는 `UiConfig.Address` 이고, 주소 없는 `AddUi` 는 빈 문자열이다. 둘을 섞으면 같은 타입이 두 번 로드될 수 있다. 설정으로 로드한 인스턴스는 `UiInstanceId.IsDefault == false`.
- 같은 타입이 여러 개 로드된 상태에서 주소 없는 `GetUi`/`CloseUi`/`UnloadUi` 를 호출하면 경고 후 첫 번째 인스턴스가 대상이 된다.
- `UnloadUi` 는 닫기 훅을 실행하지 않는다. 훅이 필요하면 `CloseUi(..., destroy: true)`.
- 데이터 오버로드에 `UiPresenter<TData>` 가 아닌 타입을 넘기면 에러 로그 후 열지 않는다.
- `GetUi<T>()` 는 null 을 반환하지 않고 `KeyNotFoundException` 을 던진다.
- `[LoadSynchronously]` 는 설정 인스펙터 동기화 때 `UiConfigs` 에셋의 `LoadSynchronously` 로 저장되고, 런타임은 어트리뷰트를 직접 읽지 않는다. 어트리뷰트를 바꾼 뒤에는 인스펙터를 열어 다시 동기화한다. 1.3.1 이전에 저장된 에셋은 `false` 로 읽힌다. 동기 로드는 `AddressablesUiAssetLoader` 에서만 의미가 있다.
- `AddressablesUiAssetLoader` 를 쓸 때 `Instantiate` 후 `AddUi` 로 넣은 프레젠터는 `ReleaseInstance` 가 처리하지 못하므로 `UnloadUi` 에서 로더가 `Object.Destroy` 로 파괴한다. GameObject 를 남기려면 `RemoveUi` 를 쓴다.
- `CancellationToken` 은 Addressables 로더의 비동기 대기에만 쓰인다.
- UniTask 는 한 번만 `await` 할 수 있다. 여러 결과는 `var (a, b) = await UniTask.WhenAll(t1, t2);`.
- 정적 이벤트 `UiService.OnResolutionChanged`/`OnOrientationChanged` 는 `Dispose()` 가 지우지 않으므로 직접 해제한다.
- 레이어 정렬은 프리팹 루트의 `Canvas`, `UIDocument`, `PanelRenderer`(Unity 6.5+, `int sortingOrder`) 에 적용된다. `Canvas`·`UIDocument` 는 열고 닫을 때 레이어 안 순위를 더해 다시 매긴다(3.1.0 부터 uGUI 도).
- `UiPresenter` 인스펙터의 플레이 모드 버튼은 서비스를 거치지 않아 `VisiblePresenters` 와 어긋난다. 디버깅은 `Tools > UI Service > Presenter Manager` 사용.
- 프레임워크 공통 규칙상 `async void` 대신 `async UniTaskVoid` 또는 `async UniTask` 를 쓴다.
- `HandlesBack`/`IsModal` 등은 `protected virtual` 이다. 재정의는 `protected override`.
- `BlockInput`/`Hold` 토큰은 `using` 으로 푼다. 같은 토큰을 두 번 풀면 경고만 남고, 남은 사유는 `InputBlockReasons`/`HoldReasons` 로 본다.
- 런타임에 UIDocument 를 만들 때는 끈 GameObject 에 붙이고 `panelSettings` 를 넣은 뒤 켠다. 켠 채로 붙이고 설정하면 플레이어 빌드에서 `rootVisualElement` 가 null 이다.
