# Geuneda Input Extensions - API Reference

소스 기준: `Packages/com.geuneda.inputextensions/Runtime/`. 어셈블리 `Geuneda.InputExtensions`.

## 네임스페이스: Input

### struct PointerInput

포인터 입력 한 번의 값. 모든 멤버는 public 필드다.

| 필드 | 타입 | 설명 |
|------|------|------|
| `Contact` | `bool` | 접촉(누름) 여부 |
| `InputId` | `int` | 입력 ID |
| `Position` | `Vector2` | 화면 위치 |
| `Tilt` | `Vector2?` | 펜 기울기. zero 이면 null |
| `Pressure` | `float?` | 압력. 0 이하이면 null |
| `Radius` | `Vector2?` | 터치 반경. 크기가 0 이면 null |
| `Twist` | `float?` | 비틀림. 0 이하이면 null |

---

### class PointerInputComposite : InputBindingComposite\<PointerInput\>

여러 컨트롤을 하나의 `PointerInput` 값으로 합치는 컴포지트 바인딩.

자동 등록: 에디터에서는 `[UnityEditor.InitializeOnLoad]` 정적 생성자, 런타임에서는 `[RuntimeInitializeOnLoadMethod]` 가 private `Register()` 를 호출해 `InputSystem.RegisterBindingComposite<PointerInputComposite>()` 를 실행한다.

| 파트 필드 (public int) | 레이아웃 |
|------------------------|----------|
| `contact` | Button |
| `position` | Vector2 |
| `tilt` | Vector2 |
| `radius` | Vector2 |
| `pressure` | Axis |
| `twist` | Axis |
| `inputId` | Integer |

메서드:
- `public override PointerInput ReadValue(ref InputBindingCompositeContext context)`

---

### class PointerInputManager : MonoBehaviour

마우스, 펜, 터치 입력을 `PointerInput` 이벤트로 바꾸는 컴포넌트.

이벤트:

| 이벤트 | 타입 | 발생 조건 |
|--------|------|-----------|
| `Pressed` | `Action<PointerInput, double>` | `Contact == true` 이고 누름 상태가 아닐 때 |
| `Dragged` | `Action<PointerInput, double>` | `Contact == true` 이고 이미 누름 상태일 때 |
| `Released` | `Action<PointerInput, double>` | `Contact == false` 이고 누름 상태일 때 |

두 번째 인자는 `InputAction.CallbackContext.time`. 누름 상태는 모든 포인터가 공유하는 `bool` 하나(`m_Dragging`)다.

인스펙터 설정(private `[SerializeField]`, 기본 false):

| 필드 | 바인딩 그룹 |
|------|-------------|
| `m_UseMouse` | `Mouse` |
| `m_UsePen` | `Pen` |
| `m_UseTouch` | `Touch` |

셋 다 true 면 `bindingMask = null`, 아니면 `InputBinding.MaskByGroups(...)` 로 켜진 그룹만 남긴다. `Awake` 와 `OnValidate` 에서 동기화한다.

상속용 멤버:
- `protected virtual void Awake()` - `PointerControls` 생성, `pointer.point` 의 `performed`/`canceled` 구독, 바인딩 마스크 동기화
- `protected virtual void OnEnable()` / `protected virtual void OnDisable()` - 컨트롤 Enable/Disable
- `protected void OnAction(InputAction.CallbackContext context)` - 값 해석 및 이벤트 발행

InputId 규칙: 마우스 `PointerInputModule.kMouseLeftId`, 펜 `int.MinValue`, 터치는 바인딩된 `touchId` 값.

---

### class GestureController : MonoBehaviour

`PointerInputManager` 이벤트로 스와이프와 탭을 감지한다.

이벤트:

| 이벤트 | 타입 | 발생 조건 |
|--------|------|-----------|
| `Pressed` | `Action<SwipeInput>` | 새 제스처 시작 시 |
| `PotentiallySwiped` | `Action<SwipeInput>` | 드래그 중 유효한 스와이프 조건을 만족할 때마다 |
| `Swiped` | `Action<SwipeInput>` | 해제 시 유효한 스와이프일 때 |
| `Tapped` | `Action<TapInput>` | 해제 시 유효한 탭일 때 |

인스펙터 설정(private `[SerializeField]`):

| 필드 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `inputManager` | `PointerInputManager` | - | 필수. `Awake` 에서 이벤트를 구독한다 |
| `maxTapDuration` | `float` | 0.2 | 탭 최대 지속 시간(초) |
| `maxTapDrift` | `float` | 5.0 | 탭 최대 이동 거리(화면 단위) |
| `maxSwipeDuration` | `float` | 0.5 | 스와이프 최대 지속 시간(초) |
| `minSwipeDistance` | `float` | 10.0 | 스와이프 최소 이동 거리(화면 단위) |
| `swipeDirectionSamenessThreshold` | `float` | 0.6 | 스와이프 방향 일관성 임계값 |
| `label` | `UnityEngine.UI.Text` | null | 디버그 정보 출력용. 연결 시 `Camera.main` 사용 |

판정 코드(private):
- 스와이프: `TravelDistance >= minSwipeDistance && (EndTime - StartTime) <= maxSwipeDuration && SwipeDirectionSameness >= swipeDirectionSamenessThreshold`
- 탭: `TravelDistance <= maxTapDrift && (EndTime - StartTime) <= maxTapDuration`

동작 흐름:
1. `Pressed` 수신: 입력 ID 로 새 `ActiveGesture` 를 등록하고(`Debug.Assert` 로 중복 검사) `Pressed` 발행
2. `Dragged` 수신: 해당 ID 의 제스처가 없으면 무시. 있으면 `SubmitPoint` 후 유효한 스와이프면 `PotentiallySwiped` 발행
3. `Released` 수신: 해당 ID 의 제스처가 없으면 무시. 있으면 제거하고 `SubmitPoint` 후 `Swiped`, `Tapped` 를 각각 조건에 따라 발행(둘 다 발행될 수 있음)

상속용 멤버: `protected virtual void Awake()`

---

### struct SwipeInput

모든 필드는 `public readonly`.

| 필드 | 타입 | 설명 |
|------|------|------|
| `InputId` | `int` | 입력 ID |
| `StartPosition` | `Vector2` | 시작 위치 |
| `PreviousPosition` | `Vector2` | 마지막 샘플 직전 위치. 첫 이동 전에는 `Vector2.zero` |
| `EndPosition` | `Vector2` | 현재(종료) 위치 |
| `SwipeDirection` | `Vector2` | `(EndPosition - StartPosition).normalized` |
| `SwipeVelocity` | `float` | `TravelDistance / SwipeDuration`. 지속 시간이 0 이면 0 |
| `TravelDistance` | `float` | 누적 이동 거리(화면 단위) |
| `SwipeDuration` | `double` | `EndTime - StartTime`(초) |
| `SwipeSameness` | `float` | 방향 일관성. 직선에 가까울수록 1 |

생성자: `internal SwipeInput(ActiveGesture gesture)`

---

### struct TapInput

모든 필드는 `public readonly`.

| 필드 | 타입 | 설명 |
|------|------|------|
| `PressPosition` | `Vector2` | 시작 위치 |
| `ReleasePosition` | `Vector2` | 해제 위치 |
| `TapDuration` | `double` | `EndTime - StartTime`(초) |
| `TapDrift` | `float` | 누적 이동 거리(화면 단위) |
| `TimeStamp` | `double` | 해제 시각(`EndTime`) |

생성자: `internal TapInput(ActiveGesture gesture)`

---

### class GamepadInputManager : MonoBehaviour

`GamepadControls` 값을 프로퍼티로 노출한다.

| 프로퍼티 | 타입 | 갱신 방식 |
|----------|------|-----------|
| `AnalogueValue` | `Vector2 { get; private set; }` | `movement` performed 값, canceled 시 `Vector2.zero` |
| `PrimaryButtonValue` | `bool { get; private set; }` | `button1Action` 값 > 0.5, canceled 시 false |
| `SecondaryButtonValue` | `bool { get; private set; }` | `button2Action` 값 > 0.5, canceled 시 false |

상속용 멤버: `protected virtual void Awake()`, `protected virtual void OnEnable()`, `protected virtual void OnDisable()`

---

### 내부 타입: class ActiveGesture (internal sealed)

`GestureController` 가 입력 ID 별로 쓰는 진행 중 제스처. 외부 어셈블리에서 접근할 수 없다.

- 필드: `InputId`, `StartTime`(readonly), `EndTime`, `StartPosition`(readonly), `PreviousPosition`, `EndPosition`, `Samples`, `SwipeDirectionSameness`, `TravelDistance`
- 생성자: `ActiveGesture(int inputId, Vector2 startPosition, double startTime)`
- `void SubmitPoint(Vector2 position, double time)`: `EndTime` 을 갱신하고, 이동 거리가 0 이면 그대로 반환한다. 아니면 위치, 샘플 수, 누적 거리, 방향 일관성을 갱신한다.

---

## 네임스페이스: Input.Controls

`.inputactions` 에서 자동 생성된 래퍼(`wrapperCodeNamespace: Input.Controls`). 직접 수정하지 않는다.

### class PointerControls : IInputActionCollection, IDisposable

- `PointerControls()`
- `InputActionAsset asset { get; }`
- `InputBinding? bindingMask { get; set; }`
- `ReadOnlyArray<InputDevice>? devices { get; set; }`
- `ReadOnlyArray<InputControlScheme> controlSchemes { get; }`
- `bool Contains(InputAction action)`, `IEnumerator<InputAction> GetEnumerator()`
- `void Enable()`, `void Disable()`, `void Dispose()`
- `PointerActions pointer { get; }`
- `InputControlScheme MouseScheme / PenScheme / TouchScheme { get; }`

`struct PointerActions`:
- `InputAction point` - 타입 `Value`
- `InputActionMap Get()`, `void Enable()`, `void Disable()`, `bool enabled`
- `void SetCallbacks(IPointerActions instance)`
- `implicit operator InputActionMap(PointerActions set)`

`interface IPointerActions`: `void OnPoint(InputAction.CallbackContext context)`

바인딩(`point` 액션, 모두 `PointerInputComposite`):

| 컴포지트 | 파트 바인딩 | 그룹 |
|----------|-------------|------|
| `MouseAndPen` | `contact`: `<Mouse>/leftButton`, `<Pen>/tip` / `position`: `<Mouse>/position`, `<Pen>/position` / `tilt`, `pressure`, `twist`: `<Pen>/...` | Mouse, Pen |
| `Touch0` ~ `Touch4` | `contact`: `touchN/press` / `position`: `touchN/position` / `radius`, `pressure`: `touchN/...` / `inputId`: `touchN/touchId` | Touch |

컨트롤 스킴: `Mouse`(`<Mouse>`), `Pen`(`<Pen>`), `Touch`(`<Touchscreen>`)

---

### class GamepadControls : IInputActionCollection, IDisposable

- `GamepadControls()`
- `InputActionAsset asset { get; }`
- `InputBinding? bindingMask { get; set; }`
- `ReadOnlyArray<InputDevice>? devices { get; set; }`
- `ReadOnlyArray<InputControlScheme> controlSchemes { get; }` (정의된 스킴 없음)
- `bool Contains(InputAction action)`, `IEnumerator<InputAction> GetEnumerator()`
- `void Enable()`, `void Disable()`, `void Dispose()`
- `GameplayActions gameplay { get; }`

`struct GameplayActions`:
- `InputAction movement` (Value, Vector2), `InputAction button1Action` (Button), `InputAction button2Action` (Button)
- `InputActionMap Get()`, `void Enable()`, `void Disable()`, `bool enabled`
- `void SetCallbacks(IGameplayActions instance)`
- `implicit operator InputActionMap(GameplayActions set)`

`interface IGameplayActions`: `OnMovement`, `OnButton1Action`, `OnButton2Action` (모두 `void (InputAction.CallbackContext context)`)

바인딩:

| 액션 | 게임패드 | 키보드 |
|------|----------|--------|
| `movement` | `<Gamepad>/leftStick` | W/A/S/D (`Dpad` 컴포지트) |
| `button1Action` | `<Gamepad>/buttonSouth` | Space, Z |
| `button2Action` | `<Gamepad>/buttonEast` | X |
