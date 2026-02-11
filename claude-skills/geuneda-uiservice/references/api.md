# Geuneda UI Service - API Reference

## 네임스페이스: Geuneda.UiService

---

## 인터페이스

### IUiService

UI 프레젠터와 상호작용하기 위한 핵심 서비스 인터페이스.

**프로퍼티**

| 이름 | 타입 | 설명 |
|------|------|------|
| `VisiblePresenters` | `IReadOnlyList<UiInstanceId>` | 현재 표시 중인 프레젠터 목록 |
| `UiSets` | `IReadOnlyDictionary<int, UiSetConfig>` | UI 세트 딕셔너리 |

**메서드**

| 시그니처 | 설명 |
|----------|------|
| `T GetUi<T>() where T : UiPresenter` | 로드된 UI 프레젠터를 가져온다 |
| `bool IsVisible<T>() where T : UiPresenter` | UI 표시 여부를 확인한다 |
| `List<UiInstance> GetLoadedPresenters()` | 로드된 모든 UI 프레젠터 목록 반환 |
| `void AddUiConfig(UiConfig config)` | UI 구성을 서비스에 추가 |
| `void AddUiSet(UiSetConfig uiSet)` | UI 세트 구성을 서비스에 추가 |
| `void AddUi<T>(T ui, int layer, bool openAfter = false)` | UI 프레젠터를 직접 추가 |
| `bool RemoveUi<T>() where T : UiPresenter` | UI를 서비스에서 제거 (언로드하지 않음) |
| `bool RemoveUi<T>(T uiPresenter) where T : UiPresenter` | 특정 인스턴스를 제거 |
| `bool RemoveUi(Type type)` | 타입으로 UI 제거 |
| `List<UiPresenter> RemoveUiSet(int setId)` | UI 세트의 모든 프레젠터 제거 |
| `UniTask<T> LoadUiAsync<T>(bool openAfter = false, CancellationToken ct = default)` | UI를 비동기 로드 |
| `UniTask<UiPresenter> LoadUiAsync(Type type, bool openAfter = false, CancellationToken ct = default)` | 타입으로 UI를 비동기 로드 |
| `IList<UniTask<UiPresenter>> LoadUiSetAsync(int setId)` | UI 세트를 비동기 로드 |
| `void UnloadUi<T>() where T : UiPresenter` | UI를 언로드 |
| `void UnloadUi<T>(T uiPresenter) where T : UiPresenter` | 특정 인스턴스를 언로드 |
| `void UnloadUi(Type type)` | 타입으로 UI 언로드 |
| `void UnloadUi(Type type, string instanceAddress)` | 타입과 인스턴스 주소로 UI 언로드 |
| `void UnloadUiSet(int setId)` | UI 세트를 언로드 |
| `UniTask<T> OpenUiAsync<T>(CancellationToken ct = default)` | UI를 열기 (필요시 로드 포함) |
| `UniTask<UiPresenter> OpenUiAsync(Type type, CancellationToken ct = default)` | 타입으로 UI 열기 |
| `UniTask<T> OpenUiAsync<T, TData>(TData initialData, CancellationToken ct = default)` | 데이터와 함께 UI 열기 |
| `UniTask<UiPresenter> OpenUiAsync<TData>(Type type, TData initialData, CancellationToken ct = default)` | 타입과 데이터로 UI 열기 |
| `UniTask<UiPresenter[]> OpenUiSetAsync(int setId, CancellationToken ct = default)` | UI 세트 열기 (병렬) |
| `void CloseUi<T>(bool destroy = false)` | UI 닫기 |
| `void CloseUi<T>(T uiPresenter, bool destroy = false)` | 특정 인스턴스 닫기 |
| `void CloseUi(Type type, bool destroy = false)` | 타입으로 UI 닫기 |
| `void CloseUi(Type type, string instanceAddress, bool destroy = false)` | 타입과 인스턴스 주소로 닫기 |
| `void CloseAllUi()` | 모든 표시 중인 UI 닫기 |
| `void CloseAllUi(int layer)` | 특정 레이어의 모든 UI 닫기 |
| `void CloseAllUiSet(int setId)` | UI 세트의 모든 UI 닫기 |

**제약 조건**
- `OpenUiAsync<T, TData>`: T는 `class, IUiPresenterData`, TData는 `struct`
- `OpenUiAsync<TData>(Type, TData, ...)`: TData는 `struct`

### IUiServiceInit

IUiService를 확장하며 IDisposable을 구현. 초기화 메서드를 제공.

| 시그니처 | 설명 |
|----------|------|
| `void Init(UiConfigs configs)` | UI 구성으로 서비스를 초기화 |

### IUiPresenterData

UiPresenter<T>를 데이터 기반 프레젠터로 태그하는 마커 인터페이스.

### IUiAssetLoader

에셋 로딩 전략 인터페이스.

| 시그니처 | 설명 |
|----------|------|
| `UniTask<GameObject> InstantiatePrefab(UiConfig config, Transform parent, CancellationToken ct = default)` | 프리팹을 비동기 인스턴스화 |
| `void UnloadAsset(GameObject asset)` | 에셋을 메모리에서 언로드 |

### ITransitionFeature

열기/닫기 전환 딜레이를 제공하는 피처 인터페이스.

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `OpenTransitionTask` | `UniTask` | 열기 전환 완료 태스크 |
| `CloseTransitionTask` | `UniTask` | 닫기 전환 완료 태스크 |

---

## 클래스

### UiService : IUiServiceInit

UI 서비스의 핵심 구현.

**정적 멤버**

| 이름 | 타입 | 설명 |
|------|------|------|
| `OnOrientationChanged` | `UnityEvent<DeviceOrientation, DeviceOrientation>` | 기기 방향 변경 이벤트 |
| `OnResolutionChanged` | `UnityEvent<Vector2, Vector2>` | 해상도 변경 이벤트 |
| `CurrentService` | `UiService` (internal) | 현재 활성 서비스 인스턴스 |

**생성자**

| 시그니처 | 설명 |
|----------|------|
| `UiService()` | 기본 생성자. AddressablesUiAssetLoader 사용 |
| `UiService(IUiAssetLoader assetLoader)` | 커스텀 에셋 로더를 주입하는 생성자 |

**추가 public 메서드 (인터페이스 외)**

| 시그니처 | 설명 |
|----------|------|
| `T GetUi<T>(string instanceAddress)` | 인스턴스 주소로 UI 가져오기 |
| `bool IsVisible<T>(string instanceAddress)` | 인스턴스 주소로 표시 여부 확인 |
| `void AddUi<T>(T ui, int layer, string instanceAddress, bool openAfter = false)` | 인스턴스 주소와 함께 UI 추가 |
| `bool RemoveUi(Type type, string instanceAddress)` | 타입과 인스턴스 주소로 제거 |
| `UniTask<UiPresenter> LoadUiAsync(Type type, string instanceAddress, bool openAfter = false, CancellationToken ct = default)` | 인스턴스 주소와 함께 로드 |
| `UniTask<UiPresenter> OpenUiAsync(Type type, string instanceAddress, CancellationToken ct = default)` | 인스턴스 주소와 함께 열기 |
| `UniTask<UiPresenter> OpenUiAsync<TData>(Type type, string instanceAddress, TData initialData, CancellationToken ct = default)` | 인스턴스 주소와 데이터로 열기 |
| `void CloseUi(Type type, string instanceAddress, bool destroy = false)` | 인스턴스 주소로 닫기 |
| `void UnloadUi(Type type, string instanceAddress)` | 인스턴스 주소로 언로드 |
| `void Dispose()` | 서비스 리소스 정리 |

---

### UiPresenter : MonoBehaviour (abstract)

모든 UI 뷰의 기본 클래스.

**프로퍼티**

| 이름 | 타입 | 접근자 | 설명 |
|------|------|--------|------|
| `IsOpen` | `bool` | public get | gameObject.activeSelf 기반 열림 상태 |
| `OpenTransitionTask` | `UniTask` | public get | 열기 전환 완료 태스크 |
| `CloseTransitionTask` | `UniTask` | public get | 닫기 전환 완료 태스크 |
| `InstanceAddress` | `string` | internal get | 인스턴스 고유 주소 |

**protected 메서드 (재정의 가능)**

| 시그니처 | 설명 |
|----------|------|
| `void Close(bool destroy)` | 서비스를 통해 자신을 닫기 |
| `virtual void OnInitialized()` | 초기화 시 호출 (1회) |
| `virtual void OnOpened()` | 열릴 때 호출 |
| `virtual void OnClosed()` | 닫힐 때 호출 |
| `virtual void OnOpenTransitionCompleted()` | 열기 전환 완료 후 호출 |
| `virtual void OnCloseTransitionCompleted()` | 닫기 전환 완료 후 호출 |

**internal 메서드**

| 시그니처 | 설명 |
|----------|------|
| `void Init(IUiService uiService, string instanceAddress)` | 서비스와 주소로 초기화 |
| `void InternalOpen()` | 열기 프로세스 시작 |
| `void InternalClose(bool destroy)` | 닫기 프로세스 시작 |

---

### UiPresenter<T> : UiPresenter, IUiPresenterData (abstract)

데이터 바인딩을 지원하는 제네릭 프레젠터. T는 struct 제약.

**프로퍼티**

| 이름 | 타입 | 접근자 | 설명 |
|------|------|--------|------|
| `Data` | `T` | public get/set | UI 데이터. set 시 OnSetData() 호출 |

**재정의 가능 메서드**

| 시그니처 | 설명 |
|----------|------|
| `virtual void OnSetData()` | Data가 설정될 때 호출 |

---

### PresenterFeatureBase : MonoBehaviour (abstract)

프레젠터 피처의 기본 클래스.

**프로퍼티**

| 이름 | 타입 | 접근자 | 설명 |
|------|------|--------|------|
| `Presenter` | `UiPresenter` | protected get | 소유 프레젠터 |

**재정의 가능 메서드**

| 시그니처 | 설명 |
|----------|------|
| `virtual void OnPresenterInitialized(UiPresenter presenter)` | 프레젠터 초기화 시 |
| `virtual void OnPresenterOpening()` | 열기 시작 시 |
| `virtual void OnPresenterOpened()` | 열린 후 |
| `virtual void OnPresenterClosing()` | 닫기 시작 시 |
| `virtual void OnPresenterClosed()` | 닫힌 후 |

---

### TimeDelayFeature : PresenterFeatureBase, ITransitionFeature

시간 기반 열기/닫기 지연 피처.

**SerializeField**

| 이름 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `_openDelayInSeconds` | `float` | 0.5f | 열기 지연 (초) |
| `_closeDelayInSeconds` | `float` | 0.3f | 닫기 지연 (초) |

**프로퍼티**

| 이름 | 타입 | 설명 |
|------|------|------|
| `OpenDelayInSeconds` | `float` | 열기 지연 시간 |
| `CloseDelayInSeconds` | `float` | 닫기 지연 시간 |
| `OpenTransitionTask` | `UniTask` | 열기 전환 태스크 |
| `CloseTransitionTask` | `UniTask` | 닫기 전환 태스크 |

**재정의 가능 메서드**

| 시그니처 | 설명 |
|----------|------|
| `virtual void OnOpenStarted()` | 열기 딜레이 시작 시 |
| `virtual void OnOpenedCompleted()` | 열기 딜레이 완료 시 |
| `virtual void OnCloseStarted()` | 닫기 딜레이 시작 시 |
| `virtual void OnClosedCompleted()` | 닫기 딜레이 완료 시 |

---

### AnimationDelayFeature : PresenterFeatureBase, ITransitionFeature

애니메이션 기반 열기/닫기 지연 피처. `[RequireComponent(typeof(Animation))]`

**SerializeField**

| 이름 | 타입 | 설명 |
|------|------|------|
| `_animation` | `Animation` | Animation 컴포넌트 |
| `_introAnimationClip` | `AnimationClip` | 인트로 애니메이션 |
| `_outroAnimationClip` | `AnimationClip` | 아웃트로 애니메이션 |

**프로퍼티**

| 이름 | 타입 | 설명 |
|------|------|------|
| `AnimationComponent` | `Animation` | Animation 컴포넌트 |
| `IntroAnimationClip` | `AnimationClip` | 인트로 클립 |
| `OutroAnimationClip` | `AnimationClip` | 아웃트로 클립 |
| `OpenDelayInSeconds` | `float` | 인트로 클립 길이 |
| `CloseDelayInSeconds` | `float` | 아웃트로 클립 길이 |
| `OpenTransitionTask` | `UniTask` | 열기 전환 태스크 |
| `CloseTransitionTask` | `UniTask` | 닫기 전환 태스크 |

**재정의 가능 메서드**

| 시그니처 | 설명 |
|----------|------|
| `virtual void OnOpenStarted()` | 인트로 애니메이션 재생 (기본 구현 있음) |
| `virtual void OnOpenedCompleted()` | 인트로 완료 시 |
| `virtual void OnCloseStarted()` | 아웃트로 애니메이션 재생 (기본 구현 있음) |
| `virtual void OnClosedCompleted()` | 아웃트로 완료 시 |

---

### UiToolkitPresenterFeature : PresenterFeatureBase

UI Toolkit 통합 피처. `[RequireComponent(typeof(UIDocument))]`

**프로퍼티**

| 이름 | 타입 | 설명 |
|------|------|------|
| `Document` | `UIDocument` | UIDocument 컴포넌트 |
| `Root` | `VisualElement` | 루트 VisualElement |

**메서드**

| 시그니처 | 설명 |
|----------|------|
| `void AddVisualTreeAttachedListener(UnityAction<VisualElement> callback)` | 비주얼 트리 준비 콜백 등록 |
| `void RemoveVisualTreeAttachedListener(UnityAction<VisualElement> callback)` | 콜백 제거 |

---

### AddressablesUiAssetLoader : IUiAssetLoader

Addressables 기반 에셋 로더. 기본 로더.

### PrefabRegistryUiAssetLoader : IUiAssetLoader

프리팹 직접 참조 기반 로더. 테스트나 직접 참조에 유용.

**생성자**

| 시그니처 | 설명 |
|----------|------|
| `PrefabRegistryUiAssetLoader()` | 기본 생성자 |
| `PrefabRegistryUiAssetLoader(PrefabRegistryUiConfigs configs)` | configs에서 프리팹 등록 |

**메서드**

| 시그니처 | 설명 |
|----------|------|
| `void RegisterPrefab(string address, GameObject prefab)` | 주소에 프리팹 등록 |

### ResourcesUiAssetLoader : IUiAssetLoader

Resources 폴더 기반 에셋 로더. 프리팹을 캐싱한다.

---

## 구조체

### UiConfig

UI 프레젠터의 구성 데이터.

| 필드 | 타입 | 설명 |
|------|------|------|
| `Address` | `string` | 에셋 주소 (Addressables 키 또는 Resources 경로) |
| `Layer` | `int` | 레이어 번호 (Canvas sortingOrder에 매핑) |
| `UiType` | `Type` | UiPresenter의 타입 |
| `LoadSynchronously` | `bool` | 동기 로드 여부 |

### UiInstance

로드된 UI 프레젠터 인스턴스 정보.

| 필드 | 타입 | 설명 |
|------|------|------|
| `Type` | `Type` | 프레젠터 타입 |
| `Address` | `string` | 인스턴스 주소 |
| `Presenter` | `UiPresenter` | 프레젠터 참조 |

### UiInstanceId : IEquatable<UiInstanceId>

UI 프레젠터 인스턴스의 고유 식별자.

| 필드 | 타입 | 설명 |
|------|------|------|
| `PresenterType` | `Type` | 프레젠터 타입 |
| `InstanceAddress` | `string` | 인스턴스 주소 (빈 문자열 = 기본 인스턴스) |

| 프로퍼티/메서드 | 설명 |
|-----------------|------|
| `bool IsDefault` | 기본/싱글턴 인스턴스인지 확인 |
| `static UiInstanceId Default(Type)` | 기본 인스턴스 ID 생성 |
| `static UiInstanceId Named(Type, string)` | 명명된 인스턴스 ID 생성 |

### UiSetConfig

UI 세트 구성. 함께 관리할 UI 그룹.

| 필드 | 타입 | 설명 |
|------|------|------|
| `SetId` | `int` | 세트 ID |
| `UiInstanceIds` | `UiInstanceId[]` | 세트에 포함된 UI 인스턴스 목록 |

### UiSetEntry

세트 내 UI 인스턴스를 위한 직렬화 가능 항목.

| 필드 | 타입 | 설명 |
|------|------|------|
| `UiTypeName` | `string` | AssemblyQualifiedName |
| `InstanceAddress` | `string` | 인스턴스 주소 |

| 메서드 | 설명 |
|--------|------|
| `UiInstanceId ToUiInstanceId()` | UiInstanceId로 변환 |
| `static UiSetEntry FromUiInstanceId(UiInstanceId)` | UiInstanceId에서 생성 |

---

## ScriptableObject

### UiConfigs (abstract)

UI 구성 데이터를 저장하는 ScriptableObject의 기본 클래스.

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `Configs` | `List<UiConfig>` | UI 구성 목록 (get/set) |
| `Sets` | `List<UiSetConfig>` | UI 세트 목록 (get) |

| 메서드 | 설명 |
|--------|------|
| `void SetSetsSize(int size)` | 세트 목록 크기 조정 |

### AddressablesUiConfigs : UiConfigs

Addressables 기반 UiConfigs.
- CreateAssetMenu: `ScriptableObjects/Configs/UiConfigs/Addressables`

### ResourcesUiConfigs : UiConfigs

Resources 기반 UiConfigs.
- CreateAssetMenu: `ScriptableObjects/Configs/UiConfigs/Resources`

### PrefabRegistryUiConfigs : UiConfigs

PrefabRegistry 기반 UiConfigs. 직접 프리팹 참조.
- CreateAssetMenu: `ScriptableObjects/Configs/UiConfigs/PrefabRegistry`

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `PrefabEntries` | `IReadOnlyList<PrefabEntry>` | 프리팹 매핑 목록 |

**PrefabEntry 구조체**

| 필드 | 타입 | 설명 |
|------|------|------|
| `Address` | `string` | 주소 키 |
| `Prefab` | `GameObject` | 프리팹 참조 |

---

## 어트리뷰트

### LoadSynchronouslyAttribute : Attribute

프레젠터에 부착하면 동기적으로 로드된다.

---

## 네임스페이스: Geuneda.UiService.Views

### SafeAreaHelperView : MonoBehaviour

기기 안전 영역(노치, 다이나믹 아일랜드)을 고려하여 RectTransform 위치를 조정하는 헬퍼. `[RequireComponent(typeof(RectTransform))]`

**SerializeField**

| 이름 | 타입 | 설명 |
|------|------|------|
| `_checkAreaBounds` | `bool` | 영역 경계 체크 여부 |
| `_rectTransform` | `RectTransform` | 대상 RectTransform |
| `_ignoreHeight` | `bool` | 높이 조정 무시 |
| `_ignoreWidth` | `bool` | 너비 조정 무시 |
| `_onUpdate` | `bool` | 매 프레임 업데이트 여부 |
| `_refResolution` | `Vector2` | 참조 해상도 |

### NonDrawingView : Graphic

아무것도 그리지 않는 Graphic 서브클래스. 레이캐스트 타겟을 제공하지만 드로우콜을 발생시키지 않는다. `[RequireComponent(typeof(CanvasRenderer))]`

### InteractableTextView : MonoBehaviour, IPointerClickHandler

TMP_Text의 링크 클릭을 처리하는 뷰. `[RequireComponent(typeof(TMP_Text))]`

| 필드 | 타입 | 설명 |
|------|------|------|
| `OnLinkedInfoClicked` | `UnityEvent<TMP_LinkInfo>` | 링크 클릭 이벤트 |
| `InteractableType` | `InteractableTextType` | 감지 방식 (IntersectingLink / NearestLink) |
| `Text` | `TMP_Text` | TMP_Text 컴포넌트 (읽기 전용) |

### AdjustScreenSizeFitterView : UIBehaviour, ILayoutSelfController

화면 크기에 맞게 RectTransform 크기를 조정하는 레이아웃 컨트롤러. `[RequireComponent(typeof(RectTransform), typeof(LayoutElement))]`, `[ExecuteAlways]`

**SerializeField**

| 이름 | 타입 | 설명 |
|------|------|------|
| `_padding` | `RectOffset` | 패딩 |
| `_canvasTransform` | `RectTransform` | Canvas RectTransform |
| `_rectTransform` | `RectTransform` | 대상 RectTransform |

---

## MonoBehaviour (내부)

### UiServiceMonoComponent : MonoBehaviour

UiService의 해상도/방향 변경 감지를 담당하는 내부 컴포넌트.
UiService.Init() 시 자동으로 생성되며, DontDestroyOnLoad로 유지된다.
Update에서 Screen.width/height와 Input.deviceOrientation 변경을 감지하여 UiService 정적 이벤트를 발생시킨다.

---

## 에디터 클래스 (Editor/)

| 클래스 | 설명 |
|--------|------|
| `UiConfigsEditorBase` | UiConfigs 인스펙터의 공통 기본 클래스 |
| `AddressablesUiConfigsEditor` | AddressablesUiConfigs 커스텀 인스펙터 |
| `ResourcesUiConfigsEditor` | ResourcesUiConfigs 커스텀 인스펙터 |
| `PrefabRegistryUiConfigsEditor` | PrefabRegistryUiConfigs 커스텀 인스펙터 |
| `DefaultUiConfigsEditor` | 기본 UiConfigs 인스펙터 |
| `UiPresenterEditor` | UiPresenter 커스텀 인스펙터 |
| `UiPresenterManagerWindow` | UI 프레젠터 관리/디버깅 에디터 윈도우 |
| `UiConfigsMenuItems` | ScriptableObject 생성 메뉴 아이템 |
| `NonDrawingViewEditor` | NonDrawingView 커스텀 인스펙터 |

---

## 파일 구조

```
Runtime/
  IUiService.cs               - IUiService, IUiServiceInit 인터페이스
  UiService.cs                - UiService 핵심 구현
  UiPresenter.cs              - UiPresenter, UiPresenter<T>, IUiPresenterData
  UiConfigs.cs                - UiConfigs, UiConfig, UiConfigSerializable
  AddressablesUiConfigs.cs    - Addressables 기반 UiConfigs
  ResourcesUiConfigs.cs       - Resources 기반 UiConfigs
  PrefabRegistryUiConfigs.cs  - PrefabRegistry 기반 UiConfigs
  UiSetConfig.cs              - UiSetConfig, UiSetEntry, UiSetConfigSerializable
  UiInstanceId.cs             - UiInstanceId 식별자
  UiServiceMonoComponent.cs   - 해상도/방향 감지 컴포넌트
  LoadSynchronouslyAttribute.cs - 동기 로드 어트리뷰트
  Loaders/
    IUiAssetLoader.cs               - 에셋 로더 인터페이스
    AddressablesUiAssetLoader.cs    - Addressables 로더
    PrefabRegistryUiAssetLoader.cs  - PrefabRegistry 로더
    ResourcesUiAssetLoader.cs       - Resources 로더
  Features/
    PresenterFeatureBase.cs         - 피처 기본 클래스
    ITransitionFeature.cs           - 전환 피처 인터페이스
    TimeDelayFeature.cs             - 시간 지연 피처
    AnimationDelayFeature.cs        - 애니메이션 지연 피처
    UiToolkitPresenterFeature.cs    - UI Toolkit 통합 피처
  Views/
    SafeAreaHelperView.cs           - 안전 영역 헬퍼
    NonDrawingView.cs               - 비렌더링 Graphic
    InteractableTextView.cs         - TMP 링크 처리
    AdjustScreenSizeFitterView.cs   - 화면 크기 맞춤
Editor/
  UiConfigsEditorBase.cs           - 인스펙터 기본 클래스
  AddressablesUiConfigsEditor.cs   - Addressables 인스펙터
  ResourcesUiConfigsEditor.cs      - Resources 인스펙터
  PrefabRegistryUiConfigsEditor.cs - PrefabRegistry 인스펙터
  DefaultUiConfigsEditor.cs        - 기본 인스펙터
  UiPresenterEditor.cs             - 프레젠터 인스펙터
  UiPresenterManagerWindow.cs      - 관리/디버깅 윈도우
  UiConfigsMenuItems.cs            - 메뉴 아이템
  NonDrawingViewEditor.cs          - NonDrawingView 인스펙터
```
