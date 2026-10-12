---
name: geuneda-uiservice
description: com.geuneda.uiservice 패키지(네임스페이스 Geuneda.UiService, Geuneda.UiService.Views)로 Unity UI 를 다루는 코드를 작성하거나 수정할 때 사용한다. UiPresenter/UiPresenter<T> 프레젠터 작성, IUiService 로 UI 로드/열기/닫기/언로드, UiConfigs 설정 에셋과 UI 세트 구성, 다중 인스턴스(UiInstanceId), PresenterFeatureBase/ITransitionFeature 피처, UI Toolkit 연동(UiToolkitPresenterFeature, UiToolkitPanelRendererFeature), IUiAssetLoader 로더, SafeAreaHelperView 등 헬퍼 뷰를 다룰 때 활성화한다.
---

# Geuneda UI Service

UI 프레젠터의 로드, 열기, 닫기, 언로드를 `UiService` 한 곳에서 관리하는 패키지. 레이어 정렬, UI 세트, 다중 인스턴스, 피처 조합, 교체 가능한 에셋 로더를 제공한다.

## 패키지 정보

- 패키지: `com.geuneda.uiservice` 1.3.1 (`package.json` 기준)
- 설치: `https://github.com/geuneda/geuneda-uiservice.git` (UniTask 는 manifest 에 직접 추가해야 함)
- 의존성: `com.unity.addressables` 2.6.0, `com.cysharp.unitask` 2.5.10, `com.unity.ugui` 2.0.0. 헬퍼 뷰는 uGUI/TextMeshPro 사용
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

// UiService 전용 (인스턴스 주소 지정)
T GetUi<T>(string instanceAddress);  bool IsVisible<T>(string instanceAddress);
UniTask<UiPresenter> OpenUiAsync(Type type, string instanceAddress, CancellationToken ct = default);
UniTask<UiPresenter> LoadUiAsync(Type type, string instanceAddress, bool openAfter = false, CancellationToken ct = default);
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

## 생명주기 순서

- 추가: (인스턴스화 → `SetActive(false)`) → 레이어 반영 → 피처 `OnPresenterInitialized` → `OnInitialized`
- 열기: 피처 `OnPresenterOpening` → `SetActive(true)` → `OnOpened` → 피처 `OnPresenterOpened` → 전환 대기 → `OnOpenTransitionCompleted`
- 닫기: 피처 `OnPresenterClosing` → `OnClosed` → 피처 `OnPresenterClosed` → 전환 대기 → `SetActive(false)` → `OnCloseTransitionCompleted` → `destroy` 면 `UnloadUi`

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
- 레이어 정렬은 `Canvas`, `UIDocument` 만 지원하고 `PanelRenderer` 는 지원하지 않는다.
- `UiPresenter` 인스펙터의 플레이 모드 버튼은 서비스를 거치지 않아 `VisiblePresenters` 와 어긋난다. 디버깅은 `Tools > UI Service > Presenter Manager` 사용.
- 프레임워크 공통 규칙상 `async void` 대신 `async UniTaskVoid` 또는 `async UniTask` 를 쓴다.
