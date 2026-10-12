# Geuneda UI Service - 공개 API

소스: geuneda-frameworks 레포 `Packages/com.geuneda.uiservice/`. 패키지 사용자 문서는 같은 폴더의 `docs/api-reference.md`.

어셈블리와 네임스페이스:

| 어셈블리 | 네임스페이스 |
|----------|--------------|
| `Geuneda.UiService` (`Runtime/`) | `Geuneda.UiService`, `Geuneda.UiService.Views` |
| `Geuneda.UiService.Editor` (`Editor/`) | `GeunedaEditor.UiService` |

---

## Geuneda.UiService

### interface IUiService

| 멤버 | 비고 |
|------|------|
| `IReadOnlyList<UiInstanceId> VisiblePresenters { get; }` | |
| `IReadOnlyDictionary<int, UiSetConfig> UiSets { get; }` | |
| `List<UiInstance> GetLoadedPresenters()` | 매번 새 리스트 |
| `T GetUi<T>() where T : UiPresenter` | 없으면 `KeyNotFoundException` |
| `bool IsVisible<T>() where T : UiPresenter` | |
| `void AddUiConfig(UiConfig config)` | 중복 타입은 경고 후 무시 |
| `void AddUiSet(UiSetConfig uiSet)` | 중복 ID 는 경고 후 무시 |
| `void AddUi<T>(T ui, int layer, bool openAfter = false) where T : UiPresenter` | 인스턴스 주소 `string.Empty` |
| `bool RemoveUi<T>() where T : UiPresenter` | 언로드/닫기 없이 제거 |
| `bool RemoveUi<T>(T uiPresenter) where T : UiPresenter` | |
| `bool RemoveUi(Type type)` | |
| `List<UiPresenter> RemoveUiSet(int setId)` | 세트 없으면 `KeyNotFoundException` |
| `UniTask<T> LoadUiAsync<T>(bool openAfter = false, CancellationToken cancellationToken = default) where T : UiPresenter` | 인스턴스 주소 = `UiConfig.Address` |
| `UniTask<UiPresenter> LoadUiAsync(Type type, bool openAfter = false, CancellationToken cancellationToken = default)` | 설정 없으면 `KeyNotFoundException` |
| `IList<UniTask<UiPresenter>> LoadUiSetAsync(int setId)` | 미로드 항목만. 세트 없으면 빈 목록 |
| `void UnloadUi<T>() where T : UiPresenter` | 닫기 훅 없음 |
| `void UnloadUi<T>(T uiPresenter) where T : UiPresenter` | |
| `void UnloadUi(Type type)` | |
| `void UnloadUi(Type type, string instanceAddress)` | 미로드면 `KeyNotFoundException` |
| `void UnloadUiSet(int setId)` | 세트 없으면 `KeyNotFoundException` |
| `UniTask<T> OpenUiAsync<T>(CancellationToken cancellationToken = default) where T : UiPresenter` | 전환을 기다리지 않음 |
| `UniTask<UiPresenter> OpenUiAsync(Type type, CancellationToken cancellationToken = default)` | |
| `UniTask<T> OpenUiAsync<T, TData>(TData initialData, CancellationToken cancellationToken = default) where T : class, IUiPresenterData where TData : struct` | `UiPresenter<TData>` 가 아니면 에러 로그 후 열지 않음 |
| `UniTask<UiPresenter> OpenUiAsync<TData>(Type type, TData initialData, CancellationToken cancellationToken = default) where TData : struct` | 위와 같음 |
| `UniTask<UiPresenter[]> OpenUiSetAsync(int setId, CancellationToken cancellationToken = default)` | `UniTask.WhenAll`. 세트 없으면 `KeyNotFoundException` |
| `void CloseUi<T>(bool destroy = false) where T : UiPresenter` | 열려 있지 않으면 경고 |
| `void CloseUi<T>(T uiPresenter, bool destroy = false) where T : UiPresenter` | |
| `void CloseUi(Type type, bool destroy = false)` | |
| `void CloseUi(Type type, string instanceAddress, bool destroy = false)` | |
| `void CloseAllUi()` | |
| `void CloseAllUi(int layer)` | |
| `void CloseAllUiSet(int setId)` | 세트 없으면 `KeyNotFoundException` |

주소 없는 Get/IsVisible/Close/Unload/Remove 는 로드된 인스턴스가 여러 개면 경고 후 첫 번째를 사용한다.

### interface IUiServiceInit : IUiService, IDisposable

| 멤버 | 비고 |
|------|------|
| `void Init(UiConfigs configs)` | `null` 이면 `ArgumentNullException`, 빈 주소/미해결 타입이면 `ArgumentException`, 레이어 0 미만·1000 초과는 경고. `"Ui"` 루트(`DontDestroyOnLoad`, `UiServiceMonoComponent`) 생성 |
| `void Dispose()` | 전부 닫고 언로드, 컬렉션 정리, 루트 파괴. 정적 이벤트 리스너는 유지 |

### class UiService : IUiServiceInit

| 멤버 | 비고 |
|------|------|
| `UiService()` | `AddressablesUiAssetLoader` |
| `UiService(IUiAssetLoader assetLoader)` | |
| `static readonly UnityEvent<DeviceOrientation, DeviceOrientation> OnOrientationChanged` | (이전, 현재) |
| `static readonly UnityEvent<Vector2, Vector2> OnResolutionChanged` | (이전, 현재) |
| `T GetUi<T>(string instanceAddress) where T : UiPresenter` | 전용 |
| `bool IsVisible<T>(string instanceAddress) where T : UiPresenter` | 전용 |
| `void AddUi<T>(T ui, int layer, string instanceAddress, bool openAfter = false) where T : UiPresenter` | 전용 |
| `bool RemoveUi(Type type, string instanceAddress)` | 전용 |
| `UniTask<UiPresenter> LoadUiAsync(Type type, string instanceAddress, bool openAfter = false, CancellationToken cancellationToken = default)` | 전용 |
| `UniTask<UiPresenter> OpenUiAsync(Type type, string instanceAddress, CancellationToken cancellationToken = default)` | 전용 |
| `UniTask<UiPresenter> OpenUiAsync<TData>(Type type, string instanceAddress, TData initialData, CancellationToken cancellationToken = default) where TData : struct` | 전용 |

`internal static UiService CurrentService` 는 에디터용 내부 멤버다.

### readonly struct UiInstance

`UiInstance(Type type, string address, UiPresenter presenter)`, 필드 `Type Type`, `string Address`, `UiPresenter Presenter`.

### readonly struct UiInstanceId : IEquatable<UiInstanceId>

| 멤버 | 비고 |
|------|------|
| `UiInstanceId(Type presenterType, string instanceAddress = null)` | 타입 `null` 이면 `ArgumentNullException`. 주소 `null`/빈 값은 `string.Empty` |
| `Type PresenterType`, `string InstanceAddress` | 필드 |
| `bool IsDefault` | 주소가 비었는지 |
| `static UiInstanceId Default(Type presenterType)` | |
| `static UiInstanceId Named(Type presenterType, string instanceAddress)` | |
| `Equals`, `GetHashCode`, `==`, `!=`, `ToString()` | `ToString` 은 `Type` 또는 `Type:Address` |

### abstract class UiPresenter : MonoBehaviour

| 멤버 | 비고 |
|------|------|
| `bool IsOpen { get; }` | `gameObject.activeSelf` |
| `UniTask OpenTransitionTask { get; }` | |
| `UniTask CloseTransitionTask { get; }` | |
| `protected IUiService _uiService` | |
| `protected void Close(bool destroy)` | 자신의 인스턴스 주소로 닫기 |
| `protected virtual void OnInitialized()` | |
| `protected virtual void OnOpened()` | |
| `protected virtual void OnClosed()` | |
| `protected virtual void OnOpenTransitionCompleted()` | 전환 피처 없어도 호출 |
| `protected virtual void OnCloseTransitionCompleted()` | 전환 피처 없어도 호출 |

internal: `string InstanceAddress { get; }`, `Init(IUiService, string)`, `InternalOpen()`, `InternalClose(bool)`.

### abstract class UiPresenter\<T> : UiPresenter, IUiPresenterData where T : struct

`T Data { get; set; }` (set 시 `OnSetData()`), `protected virtual void OnSetData()`.

### interface IUiPresenterData

멤버 없는 마커 인터페이스.

### struct UiConfig

필드 `string Address`, `int Layer`, `Type UiType`, `bool LoadSynchronously`.

### abstract class UiConfigs : ScriptableObject

| 멤버 | 비고 |
|------|------|
| `List<UiConfig> Configs { get; set; }` | 변환 리스트. `LoadSynchronously` 는 저장되지 않아 항상 `false` |
| `List<UiSetConfig> Sets { get; }` | 타입을 찾지 못한 항목 제외 |
| `void SetSetsSize(int size)` | 세트 수 조정, 설정에 없는 타입 항목 제거. 새 세트의 `SetId` 는 인덱스 |
| `struct UiConfigSerializable` | 필드 `string Address`, `int Layer`, `string UiType`. `UiConfig` 와 양방향 암시적 변환 |

### 설정 에셋 파생 타입

| 타입 | `CreateAssetMenu` | 추가 멤버 |
|------|-------------------|-----------|
| `AddressablesUiConfigs : UiConfigs` | `ScriptableObjects/Configs/UiConfigs/Addressables` | |
| `ResourcesUiConfigs : UiConfigs` | `ScriptableObjects/Configs/UiConfigs/Resources` | |
| `PrefabRegistryUiConfigs : UiConfigs` | `ScriptableObjects/Configs/UiConfigs/PrefabRegistry` | `IReadOnlyList<PrefabEntry> PrefabEntries`, `struct PrefabEntry { string Address; GameObject Prefab; }` |

### struct UiSetConfig

필드 `int SetId`, `UiInstanceId[] UiInstanceIds`.

### struct UiSetEntry

필드 `string UiTypeName`(AssemblyQualifiedName), `string InstanceAddress`. 메서드 `UiInstanceId ToUiInstanceId()`(타입 못 찾으면 경고 후 `default`), `static UiSetEntry FromUiInstanceId(UiInstanceId instanceId)`.

### struct UiSetConfigSerializable

필드 `int SetId`, `List<UiSetEntry> UiEntries`. 메서드 `static UiSetConfig ToUiSetConfig(UiSetConfigSerializable)`, `static UiSetConfigSerializable FromUiSetConfig(UiSetConfig)`.

### class LoadSynchronouslyAttribute : Attribute

에디터 동기화 시 `UiConfig.LoadSynchronously` 를 채우지만 에셋에 저장되지 않아 런타임 효과 없음.

### class UiServiceMonoComponent : MonoBehaviour

`Init()` 이 `"Ui"` 루트에 붙인다. `Update` 에서 `Screen.width/height`, `Input.deviceOrientation`(`Unknown`, `FaceUp`, `FaceDown` 제외) 변화를 감지해 `UiService` 정적 이벤트를 발생시킨다. 공개 멤버 없음.

### interface IUiAssetLoader

| 멤버 |
|------|
| `UniTask<GameObject> InstantiatePrefab(UiConfig config, Transform parent, CancellationToken cancellationToken = default)` |
| `void UnloadAsset(GameObject asset)` |

| 구현 | 공개 멤버 | 동작 |
|------|-----------|------|
| `AddressablesUiAssetLoader` | 인터페이스 멤버 | `Addressables.InstantiateAsync`, `LoadSynchronously` 면 `WaitForCompletion()`, 실패 시 `OperationException` throw. 해제는 `Addressables.ReleaseInstance` |
| `ResourcesUiAssetLoader` | 인터페이스 멤버 | `Resources.Load<GameObject>` 캐시 후 `Instantiate`, 없으면 `KeyNotFoundException`. 해제는 `DestroyImmediate`. 토큰 미사용 |
| `PrefabRegistryUiAssetLoader` | `PrefabRegistryUiAssetLoader()`, `PrefabRegistryUiAssetLoader(PrefabRegistryUiConfigs configs)`, `void RegisterPrefab(string address, GameObject prefab)` | 미등록 주소면 `KeyNotFoundException`. 해제는 `DestroyImmediate`. 토큰 미사용 |

### abstract class PresenterFeatureBase : MonoBehaviour

| 멤버 | 호출 시점 |
|------|-----------|
| `protected UiPresenter Presenter { get; }` | |
| `virtual void OnPresenterInitialized(UiPresenter presenter)` | `OnInitialized()` 직전. 재정의 시 `base` 호출 |
| `virtual void OnPresenterOpening()` | `SetActive(true)` 전 |
| `virtual void OnPresenterOpened()` | `OnOpened()` 후 |
| `virtual void OnPresenterClosing()` | `OnClosed()` 전 |
| `virtual void OnPresenterClosed()` | `OnClosed()` 후, 전환 대기 전 |

피처는 프레젠터와 같은 GameObject 에서 `GetComponents` 로 수집된다.

### interface ITransitionFeature

`UniTask OpenTransitionTask { get; }`, `UniTask CloseTransitionTask { get; }`. 프레젠터는 `OnPresenterOpened` 직후, `OnPresenterClosed` 직후에 읽는다.

### class TimeDelayFeature : PresenterFeatureBase, ITransitionFeature

직렬화 필드 `_openDelayInSeconds`(0.5), `_closeDelayInSeconds`(0.3). 공개 `float OpenDelayInSeconds`, `float CloseDelayInSeconds`, `OpenTransitionTask`, `CloseTransitionTask`. protected virtual `OnOpenStarted()`, `OnOpenedCompleted()`, `OnCloseStarted()`, `OnClosedCompleted()`.

### class AnimationDelayFeature : PresenterFeatureBase, ITransitionFeature

`[RequireComponent(typeof(Animation))]`. 직렬화 필드 `_animation`, `_introAnimationClip`, `_outroAnimationClip`. 공개 `Animation AnimationComponent`, `AnimationClip IntroAnimationClip`, `AnimationClip OutroAnimationClip`, `float OpenDelayInSeconds`, `float CloseDelayInSeconds`(클립 길이, 없으면 0), `OpenTransitionTask`, `CloseTransitionTask`. protected virtual `OnOpenStarted()`/`OnCloseStarted()`(기본 구현이 클립 재생), `OnOpenedCompleted()`, `OnClosedCompleted()`.

### class UiToolkitPresenterFeature : PresenterFeatureBase

`[RequireComponent(typeof(UIDocument))]`. `UIDocument Document`, `VisualElement Root`(= `Document.rootVisualElement`), `void AddVisualTreeAttachedListener(UnityAction<VisualElement> callback)`(준비돼 있으면 즉시 호출), `void RemoveVisualTreeAttachedListener(UnityAction<VisualElement> callback)`. 리스너는 초기화, 열기, `AttachToPanelEvent` 때 호출된다.

### class UiToolkitPanelRendererFeature : PresenterFeatureBase

`#if UNITY_6000_5_OR_NEWER`, `[RequireComponent(typeof(PanelRenderer))]`. `PanelRenderer Panel`, `VisualElement Root`(최근 리로드 콜백의 루트, 없으면 `null`), `AddVisualTreeAttachedListener`, `RemoveVisualTreeAttachedListener`. `RegisterUIReloadCallback` 으로 루트를 받는다.

---

## Geuneda.UiService.Views

| 타입 | 요구 컴포넌트 | 공개/직렬화 멤버 |
|------|---------------|------------------|
| `SafeAreaHelperView : MonoBehaviour` | `RectTransform` | 직렬화 `_checkAreaBounds`, `_rectTransform`, `_ignoreHeight`, `_ignoreWidth`, `_onUpdate`, `_refResolution`. 에디터 전용 `SafeAreaHelperViewEditor`(같은 파일, `Update Anchored Data`/`Update Anchored View` 버튼) |
| `NonDrawingView : Graphic` | `CanvasRenderer` | `SetMaterialDirty()`, `SetVerticesDirty()` 재정의(아무것도 안 함) |
| `AdjustScreenSizeFitterView : UIBehaviour, ILayoutSelfController` | `RectTransform`, `LayoutElement` | `[ExecuteAlways]`, 메뉴 `Layout/Adjust Size Fitter`. 직렬화 `_padding`, `_canvasTransform`, `_rectTransform`. `SetLayoutHorizontal()`, `SetLayoutVertical()`(효과 없음) |
| `InteractableTextView : MonoBehaviour, IPointerClickHandler` | `TMP_Text` | `UnityEvent<TMP_LinkInfo> OnLinkedInfoClicked`, `InteractableTextType InteractableType`(`IntersectingLink`, `NearestLink`), `TMP_Text Text`, `OnPointerClick(PointerEventData)`. 카메라 `null` 로 판정 |

---

## GeunedaEditor.UiService (에디터)

| 타입 | 설명 |
|------|------|
| `abstract UiConfigsEditorBase<TSet> : Editor where TSet : Enum` | 설정 인스펙터 공통. 레이어 시각화, 설정 목록, enum 기반 세트 편집 |
| `abstract AddressablesUiConfigsEditor<TSet> : UiConfigsEditorBase<TSet>` | 읽기 전용이 아닌 Addressable 그룹과 동기화 |
| `abstract ResourcesUiConfigsEditor<TSet> : UiConfigsEditorBase<TSet>` | 경로에 `/Resources/` 가 있는 프리팹과 동기화 |
| `abstract PrefabRegistryUiConfigsEditor<TSet> : UiConfigsEditorBase<TSet>` | 프리팹 레지스트리 편집, 주소 = 프리팹 이름 |
| `enum DefaultUiSetId` | `InitialLoading`=0, `MainMenu`=1, `Gameplay`=2, `Settings`=3, `Overlays`=4, `Popups`=5 |
| `DefaultAddressablesUiConfigsEditor`, `DefaultResourcesUiConfigsEditor`, `DefaultPrefabRegistryUiConfigsEditor` | 각 설정 에셋의 기본 `[CustomEditor]` (`DefaultUiSetId` 사용) |
| `static UiConfigsMenuItems` | `Tools/UI Service/Select UiConfigs`, `Tools/UI Service/Layer Visualizer`(`public static void ShowLayerVisualizer()`) |
| `UiPresenterManagerWindow : EditorWindow` | `Tools/UI Service/Presenter Manager`(`public static void ShowWindow()`). 플레이 모드 전용 |
| `UiPresenterEditor : Editor` | `UiPresenter` 및 파생 인스펙터. 플레이 모드 열기/닫기 버튼(서비스 우회) |
| `NonDrawingViewEditor : GraphicEditor` | `NonDrawingView` 인스펙터 |

세트 enum 을 바꾸려면 Editor 폴더에 `[CustomEditor(typeof(AddressablesUiConfigs))] public class X : AddressablesUiConfigsEditor<MySetId> { }` 를 만든다. enum 값은 0부터 연속. 패키지 기본 에디터도 같은 타입을 대상으로 하므로 적용 여부를 확인한다.
