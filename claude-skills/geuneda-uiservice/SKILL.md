---
name: geuneda-uiservice
description: Unity UI 관리 서비스 패키지(geuneda-uiservice)의 코드를 작성하거나 수정할 때 사용하는 스킬. MVP 패턴 기반 UI 프레젠터 생성, UI 생명주기 관리(로드/열기/닫기/언로드), 피처 조합 시스템, UI Toolkit 통합, Addressables 에셋 로딩, UI 세트 관리 코드를 구현할 때 활성화한다.
---

# Geuneda UI Service

Unity 게임의 UI를 중앙 집중식으로 관리하는 서비스 패키지. MVP(Model-View-Presenter) 패턴 기반으로 UI 생명주기(로드, 열기, 닫기, 언로드)를 관리하며, 피처 조합 시스템을 통해 상속 없이 동작을 확장할 수 있다. Addressables, Resources, PrefabRegistry 등 다양한 에셋 로딩 전략을 지원한다.

## 활성화 시점

- UiPresenter를 상속하는 새로운 UI 프레젠터 클래스를 작성할 때
- IUiService를 통해 UI를 열기/닫기/로드/언로드하는 코드를 작성할 때
- PresenterFeatureBase를 상속하는 커스텀 피처를 구현할 때
- UiToolkitPresenterFeature를 사용한 UI Toolkit 통합 코드를 작성할 때
- UiConfigs ScriptableObject를 설정하거나 UI 세트를 구성할 때
- UiPresenter<T>를 사용한 데이터 기반 UI를 구현할 때
- 다중 인스턴스 UI(UiInstanceId)를 관리하는 코드를 작성할 때
- IUiAssetLoader를 구현하는 커스텀 에셋 로더를 만들 때

## 패키지 정보

- **네임스페이스**: `Geuneda.UiService`, `Geuneda.UiService.Views`
- **패키지명**: `com.geuneda.uiservice`
- **버전**: 1.2.0
- **설치**: `https://github.com/geuneda/geuneda-uiservice.git`
- **의존성**: Unity Addressables 2.6.0+, UniTask 2.5.10+
- **Unity**: 6000.0+
- **소스 경로**: `/Users/teamsparta/Documents/GitHub/geuneda-uiservice/`

## 아키텍처 개요

```
IUiService (인터페이스)
    |
    v
UiService (구현) -- IUiAssetLoader (에셋 로딩 추상화)
    |                   |-- AddressablesUiAssetLoader
    |                   |-- PrefabRegistryUiAssetLoader
    |                   |-- ResourcesUiAssetLoader
    |
    v
UiPresenter (기본 클래스) -- PresenterFeatureBase (피처 시스템)
    |                           |-- TimeDelayFeature
    |                           |-- AnimationDelayFeature
    |                           |-- UiToolkitPresenterFeature
    |                           |-- ITransitionFeature (전환 인터페이스)
    |
    v
UiPresenter<T> (데이터 바인딩)
```

## 핵심 API

### IUiService / IUiServiceInit
UI 서비스의 공개 인터페이스. 모든 UI 작업의 진입점.

```csharp
// 초기화
void Init(UiConfigs configs);

// 열기/닫기
UniTask<T> OpenUiAsync<T>(CancellationToken ct = default) where T : UiPresenter;
UniTask<T> OpenUiAsync<T, TData>(TData initialData, CancellationToken ct = default)
    where T : class, IUiPresenterData where TData : struct;
void CloseUi<T>(bool destroy = false) where T : UiPresenter;
void CloseAllUi();
void CloseAllUi(int layer);

// 로드/언로드
UniTask<T> LoadUiAsync<T>(bool openAfter = false, CancellationToken ct = default) where T : UiPresenter;
void UnloadUi<T>() where T : UiPresenter;

// UI 세트
UniTask<UiPresenter[]> OpenUiSetAsync(int setId, CancellationToken ct = default);
void CloseAllUiSet(int setId);
void UnloadUiSet(int setId);

// 조회
T GetUi<T>() where T : UiPresenter;
bool IsVisible<T>() where T : UiPresenter;
IReadOnlyList<UiInstanceId> VisiblePresenters { get; }
```

### UiPresenter
모든 UI 뷰의 기본 클래스. MonoBehaviour를 상속한다.

```csharp
public abstract class UiPresenter : MonoBehaviour
{
    public bool IsOpen { get; }
    public UniTask OpenTransitionTask { get; }
    public UniTask CloseTransitionTask { get; }
    protected void Close(bool destroy);
    protected virtual void OnInitialized() {}
    protected virtual void OnOpened() {}
    protected virtual void OnClosed() {}
    protected virtual void OnOpenTransitionCompleted() {}
    protected virtual void OnCloseTransitionCompleted() {}
}
```

### UiPresenter<T>
데이터 바인딩을 지원하는 제네릭 프레젠터. T는 struct 타입이어야 한다.

```csharp
public abstract class UiPresenter<T> : UiPresenter, IUiPresenterData where T : struct
{
    public T Data { get; set; }
    protected virtual void OnSetData() {}
}
```

### PresenterFeatureBase
프레젠터에 부착하여 동작을 확장하는 피처의 기본 클래스.

```csharp
public abstract class PresenterFeatureBase : MonoBehaviour
{
    protected UiPresenter Presenter { get; }
    public virtual void OnPresenterInitialized(UiPresenter presenter) {}
    public virtual void OnPresenterOpening() {}
    public virtual void OnPresenterOpened() {}
    public virtual void OnPresenterClosing() {}
    public virtual void OnPresenterClosed() {}
}
```

### IUiAssetLoader
에셋 로딩 전략 인터페이스.

```csharp
public interface IUiAssetLoader
{
    UniTask<GameObject> InstantiatePrefab(UiConfig config, Transform parent, CancellationToken ct = default);
    void UnloadAsset(GameObject asset);
}
```

## 사용 패턴

### 기본 UI 서비스 초기화 (Addressables)

```csharp
using Geuneda.UiService;

public class GameInitializer : MonoBehaviour
{
    [SerializeField] private UiConfigs _uiConfigs;
    private IUiServiceInit _uiService;

    void Start()
    {
        _uiService = new UiService();
        _uiService.Init(_uiConfigs);
    }

    void OnDestroy()
    {
        _uiService?.Dispose();
    }
}
```

### PrefabRegistry 로더 사용

```csharp
var configs = ScriptableObject.CreateInstance<PrefabRegistryUiConfigs>();
var loader = new PrefabRegistryUiAssetLoader(configs);
var uiService = new UiService(loader);
uiService.Init(configs);
```

### Resources 로더 사용

```csharp
var loader = new ResourcesUiAssetLoader();
var uiService = new UiService(loader);
uiService.Init(configs);
```

### 기본 프레젠터 구현

```csharp
public class MainMenuPresenter : UiPresenter
{
    [SerializeField] private Button _playButton;

    protected override void OnInitialized()
    {
        _playButton.onClick.AddListener(OnPlayClicked);
    }

    protected override void OnOpened()
    {
        // UI가 열릴 때 실행
    }

    protected override void OnClosed()
    {
        // UI가 닫힐 때 실행
    }

    private void OnPlayClicked()
    {
        Close(destroy: false);
    }
}
```

### 데이터 기반 프레젠터

```csharp
public struct PlayerInfoData
{
    public string Name;
    public int Level;
}

public class PlayerInfoPresenter : UiPresenter<PlayerInfoData>
{
    [SerializeField] private TMP_Text _nameText;
    [SerializeField] private TMP_Text _levelText;

    protected override void OnSetData()
    {
        _nameText.text = Data.Name;
        _levelText.text = $"Lv. {Data.Level}";
    }
}

// 사용
var data = new PlayerInfoData { Name = "Hero", Level = 10 };
await _uiService.OpenUiAsync<PlayerInfoPresenter, PlayerInfoData>(data);
```

### 커스텀 피처 만들기

```csharp
public class FadeFeature : PresenterFeatureBase, ITransitionFeature
{
    [SerializeField] private CanvasGroup _canvasGroup;
    [SerializeField] private float _duration = 0.3f;
    private UniTaskCompletionSource _openCompletion;
    private UniTaskCompletionSource _closeCompletion;

    public UniTask OpenTransitionTask => _openCompletion?.Task ?? UniTask.CompletedTask;
    public UniTask CloseTransitionTask => _closeCompletion?.Task ?? UniTask.CompletedTask;

    public override void OnPresenterOpened()
    {
        _openCompletion = new UniTaskCompletionSource();
        FadeInAsync().Forget();
    }

    public override void OnPresenterClosing()
    {
        _closeCompletion = new UniTaskCompletionSource();
        FadeOutAsync().Forget();
    }

    private async UniTask FadeInAsync()
    {
        _canvasGroup.alpha = 0f;
        var elapsed = 0f;
        while (elapsed < _duration)
        {
            elapsed += Time.deltaTime;
            _canvasGroup.alpha = elapsed / _duration;
            await UniTask.Yield();
        }
        _canvasGroup.alpha = 1f;
        _openCompletion?.TrySetResult();
    }

    private async UniTask FadeOutAsync()
    {
        var elapsed = 0f;
        while (elapsed < _duration)
        {
            elapsed += Time.deltaTime;
            _canvasGroup.alpha = 1f - (elapsed / _duration);
            await UniTask.Yield();
        }
        _canvasGroup.alpha = 0f;
        _closeCompletion?.TrySetResult();
    }
}
```

### UI Toolkit 통합

```csharp
public class SettingsPresenter : UiPresenter
{
    [SerializeField] private UiToolkitPresenterFeature _toolkitFeature;

    protected override void OnInitialized()
    {
        _toolkitFeature.AddVisualTreeAttachedListener(OnVisualTreeReady);
    }

    private void OnVisualTreeReady(VisualElement root)
    {
        var closeButton = root.Q<Button>("close-button");
        closeButton.clicked += () => Close(destroy: false);
    }
}
```

### UI 세트 (그룹 관리)

```csharp
// UiConfigs에서 SetId 0에 HUD UI들을 구성한 후:
var hudPresenters = await _uiService.OpenUiSetAsync(setId: 0);
// 전체 HUD 닫기
_uiService.CloseAllUiSet(setId: 0);
// 전체 HUD 언로드
_uiService.UnloadUiSet(setId: 0);
```

### 다중 인스턴스

```csharp
// UiConfigs에서 같은 프레젠터 타입을 다른 주소로 등록
// 각 인스턴스는 고유한 인스턴스 주소를 가짐
var popup1 = await _uiService.OpenUiAsync(typeof(NotificationPresenter), "notification-1");
var popup2 = await _uiService.OpenUiAsync(typeof(NotificationPresenter), "notification-2");
// 특정 인스턴스 닫기
_uiService.CloseUi(typeof(NotificationPresenter), "notification-1");
```

## 생명주기 순서

### 열기 흐름
1. `LoadUiAsync` / `OpenUiAsync` -> 에셋 로드
2. `UiPresenter.Init()` -> `OnInitialized()` (최초 1회)
3. `InternalOpen()` -> `OnPresenterOpening()` (피처)
4. `gameObject.SetActive(true)`
5. `OnOpened()` -> `OnPresenterOpened()` (피처)
6. 전환 대기 (ITransitionFeature)
7. `OnOpenTransitionCompleted()`

### 닫기 흐름
1. `CloseUi` -> `InternalClose()`
2. `OnPresenterClosing()` (피처) -> `OnClosed()` -> `OnPresenterClosed()` (피처)
3. 전환 대기 (ITransitionFeature)
4. `gameObject.SetActive(false)`
5. `OnCloseTransitionCompleted()`
6. destroy=true이면 `UnloadUi()` 호출

## UiConfigs ScriptableObject 생성

세 가지 유형의 UiConfigs를 생성할 수 있다:

- **AddressablesUiConfigs**: `Create > ScriptableObjects > Configs > UiConfigs > Addressables`
- **ResourcesUiConfigs**: `Create > ScriptableObjects > Configs > UiConfigs > Resources`
- **PrefabRegistryUiConfigs**: `Create > ScriptableObjects > Configs > UiConfigs > PrefabRegistry`

## 주의사항

- UiPresenter는 MonoBehaviour이므로 `new`로 생성하지 않는다. 프리팹에 부착한다.
- UiService 생성자에 IUiAssetLoader를 주입하지 않으면 기본값으로 AddressablesUiAssetLoader가 사용된다.
- UiPresenter<T>의 T는 반드시 struct 타입이어야 한다.
- ITransitionFeature를 구현하는 피처는 열기/닫기 전환을 완료해야 프레젠터 생명주기가 진행된다.
- UiService.Dispose()를 호출하여 리소스를 정리해야 한다.
- 동일 타입의 다중 인스턴스를 사용할 때는 인스턴스 주소를 명시적으로 지정해야 한다.
- 레이어 번호는 Canvas sortingOrder 또는 UIDocument sortingOrder에 매핑된다.
- 핫 패스에서 프레임당 할당 제로를 보장한다 (읽기 전용 래퍼 사용).
- WebGL에서는 UniTask가 필수 (Task.Delay 사용 불가).

## 참조 문서

상세 API 문서는 `references/api.md` 참조.
