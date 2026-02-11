# Geuneda Input Extensions - API Reference

## 네임스페이스: Input

### struct PointerInput

드래그 입력 정보를 담는 구조체.

| 필드 | 타입 | 설명 |
|------|------|------|
| `Contact` | `bool` | 접촉 여부 |
| `InputId` | `int` | 입력 유형의 ID |
| `Position` | `Vector2` | 입력 위치 |
| `Tilt` | `Vector2?` | 펜 기울기 (nullable) |
| `Pressure` | `float?` | 입력 압력 (nullable) |
| `Radius` | `Vector2?` | 터치 반경 (nullable) |
| `Twist` | `float?` | 비틀림 (nullable) |

---

### class PointerInputComposite : InputBindingComposite\<PointerInput\>

Input System의 커스텀 컴포지트 바인딩. 여러 입력 소스(contact, position, tilt, radius, pressure, twist, inputId)를 하나의 `PointerInput` 값으로 합성한다.

**자동 등록**: 에디터에서는 `[InitializeOnLoad]`, 런타임에서는 `[RuntimeInitializeOnLoadMethod]`로 자동 등록된다.

| 컴포지트 필드 | InputControl Layout | 설명 |
|---------------|---------------------|------|
| `contact` | Button | 접촉 여부 |
| `position` | Vector2 | 위치 |
| `tilt` | Vector2 | 기울기 |
| `radius` | Vector2 | 반경 |
| `pressure` | Axis | 압력 |
| `twist` | Axis | 비틀림 |
| `inputId` | Integer | 입력 ID |

**메서드**:
- `PointerInput ReadValue(ref InputBindingCompositeContext context)` - 컴포지트 값 읽기

---

### class PointerInputManager : MonoBehaviour

펜, 마우스, 터치 입력을 해석하는 입력 관리자. 드래그 관련 컨트롤에 특화되어 있다.

**이벤트**:

| 이벤트 | 시그니처 | 설명 |
|--------|----------|------|
| `Pressed` | `Action<PointerInput, double>` | 사용자가 화면을 눌렀을 때 발생 |
| `Dragged` | `Action<PointerInput, double>` | 사용자가 화면을 드래그할 때 발생 |
| `Released` | `Action<PointerInput, double>` | 누르기를 해제했을 때 발생 |

**SerializeField**:

| 필드 | 타입 | 설명 |
|------|------|------|
| `m_UseMouse` | `bool` | 마우스 입력 사용 여부 |
| `m_UsePen` | `bool` | 펜 입력 사용 여부 |
| `m_UseTouch` | `bool` | 터치 입력 사용 여부 |

**생명주기**:
- `Awake()` - PointerControls 생성, point 액션 구독, 바인딩 마스크 동기화
- `OnEnable()` - 컨트롤 활성화
- `OnDisable()` - 컨트롤 비활성화
- `OnValidate()` - 바인딩 마스크 재동기화

**입력 ID 규칙**:
- 마우스 입력: `PointerInputModule.kMouseLeftId`
- 펜 입력: `int.MinValue`
- 터치 입력: 각 터치의 touchId 사용

---

### struct SwipeInput

스와이프 입력 정보를 담는 구조체.

| 필드 | 타입 | 설명 |
|------|------|------|
| `InputId` | `int (readonly)` | 스와이프를 수행한 입력 ID |
| `StartPosition` | `Vector2 (readonly)` | 스와이프 시작 위치 |
| `PreviousPosition` | `Vector2 (readonly)` | 이전 위치 |
| `EndPosition` | `Vector2 (readonly)` | 종료 위치 |
| `SwipeDirection` | `Vector2 (readonly)` | 평균 정규화 방향. `(EndPosition - StartPosition).normalized` |
| `SwipeVelocity` | `float (readonly)` | 평균 속도 (화면 단위/초) |
| `TravelDistance` | `float (readonly)` | 총 이동 거리 (화면 단위). 직선 거리 이상 |
| `SwipeDuration` | `double (readonly)` | 스와이프 지속 시간 (초) |
| `SwipeSameness` | `float (readonly)` | 방향 일관성 정규화 값. 1에 가까울수록 직선 |

**생성자** (internal): `SwipeInput(ActiveGesture gesture)`

---

### struct TapInput

탭 입력 정보를 담는 구조체.

| 필드 | 타입 | 설명 |
|------|------|------|
| `PressPosition` | `Vector2 (readonly)` | 탭 시작 위치 |
| `ReleasePosition` | `Vector2 (readonly)` | 탭 해제 위치 |
| `TapDuration` | `double (readonly)` | 탭 유지 시간 (초) |
| `TapDrift` | `float (readonly)` | 탭 총 이탈 거리 (화면 단위) |
| `TimeStamp` | `double (readonly)` | 탭 타임스탬프 |

**생성자** (internal): `TapInput(ActiveGesture gesture)`

---

### class ActiveGesture (internal sealed)

진행 중인 잠재적 제스처를 추적하는 내부 클래스.

| 멤버 | 타입 | 설명 |
|------|------|------|
| `InputId` | `int` | 제스처 입력 ID |
| `StartTime` | `double (readonly)` | 시작 시간 |
| `EndTime` | `double` | 종료 시간 |
| `StartPosition` | `Vector2 (readonly)` | 시작 위치 |
| `PreviousPosition` | `Vector2` | 이전 위치 |
| `EndPosition` | `Vector2` | 종료 위치 |
| `Samples` | `int` | 샘플 수 |
| `SwipeDirectionSameness` | `float` | 방향 일관성 (1 = 완전 직선) |
| `TravelDistance` | `float` | 총 이동 거리 |

**생성자**: `ActiveGesture(int inputId, Vector2 startPosition, double startTime)`

**메서드**:
- `void SubmitPoint(Vector2 position, double time)` - 새 위치 포인트 제출. 거리가 0인 경우 무시. 내부적으로 정규화된 이동 벡터를 누적하여 SwipeDirectionSameness를 계산한다.

---

### class GestureController : MonoBehaviour

PointerInputManager로부터 포인터 입력을 받아 방향성 스와이프와 탭을 감지하는 컨트롤러.

**이벤트**:

| 이벤트 | 시그니처 | 설명 |
|--------|----------|------|
| `Pressed` | `Action<SwipeInput>` | 사용자가 화면을 눌렀을 때 |
| `PotentiallySwiped` | `Action<SwipeInput>` | 스와이프 진행 중 (프레임당 여러 번 가능) |
| `Swiped` | `Action<SwipeInput>` | 유효한 스와이프 완료 시 |
| `Tapped` | `Action<TapInput>` | 유효한 탭 감지 시 |

**SerializeField**:

| 필드 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `inputManager` | `PointerInputManager` | - | 포인터 입력 매니저 참조 |
| `maxTapDuration` | `float` | 0.2 | 탭 최대 지속 시간 (초) |
| `maxTapDrift` | `float` | 5.0 | 탭 최대 이탈 거리 (화면 단위) |
| `maxSwipeDuration` | `float` | 0.5 | 스와이프 최대 지속 시간 (초) |
| `minSwipeDistance` | `float` | 10.0 | 스와이프 최소 이동 거리 (화면 단위) |
| `swipeDirectionSamenessThreshold` | `float` | 0.6 | 스와이프 방향 일관성 임계값 |
| `label` | `Text` | null | 디버그 정보 표시용 UI Text |

**스와이프 유효성 조건**: TravelDistance >= minSwipeDistance AND 지속시간 <= maxSwipeDuration AND SwipeDirectionSameness >= threshold

**탭 유효성 조건**: TravelDistance <= maxTapDrift AND 지속시간 <= maxTapDuration

**동작 흐름**:
1. OnPressed: 새 ActiveGesture 생성, Pressed 이벤트 발행
2. OnDragged: ActiveGesture에 포인트 제출, 유효한 스와이프면 PotentiallySwiped 발행
3. OnReleased: ActiveGesture 제거, 유효한 스와이프면 Swiped 발행, 유효한 탭이면 Tapped 발행

---

### class GamepadInputManager : MonoBehaviour

게임패드 및 키보드 입력 관리자.

**프로퍼티**:

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `AnalogueValue` | `Vector2 { get; }` | 아날로그 스틱 / WASD 현재 값 |
| `PrimaryButtonValue` | `bool { get; }` | 기본 버튼 상태 (Gamepad South / Space / Z) |
| `SecondaryButtonValue` | `bool { get; }` | 보조 버튼 상태 (Gamepad East / X) |

**바인딩 맵**:

| 액션 | 게임패드 | 키보드 |
|------|----------|--------|
| movement | Left Stick | W/A/S/D (Dpad 컴포지트) |
| button1Action | Button South | Space, Z |
| button2Action | Button East | X |

---

## 네임스페이스: Input.Controls

### class PointerControls : IInputActionCollection, IDisposable

.inputactions 파일에서 자동 생성된 포인터 입력 액션 컬렉션.

**주요 멤버**:
- `InputActionAsset asset { get; }` - 내부 InputActionAsset
- `InputBinding? bindingMask { get; set; }` - 바인딩 마스크
- `ReadOnlyArray<InputDevice>? devices { get; set; }` - 장치 필터
- `PointerActions pointer` - 포인터 액션 맵 접근자
- `void Enable()` / `void Disable()` - 활성화/비활성화
- `void Dispose()` - 에셋 해제

**PointerActions struct**:
- `InputAction point` - 포인터 입력 액션 (PassThrough 모드)

**컨트롤 스킴**: Mouse, Pen, Touch

**지원 터치**: touch0 ~ touch4 (5개 멀티터치)

**interface IPointerActions**:
- `void OnPoint(InputAction.CallbackContext context)`

---

### class GamepadControls : IInputActionCollection, IDisposable

.inputactions 파일에서 자동 생성된 게임패드 입력 액션 컬렉션.

**주요 멤버**:
- `InputActionAsset asset { get; }` - 내부 InputActionAsset
- `GameplayActions gameplay` - 게임플레이 액션 맵 접근자
- `void Enable()` / `void Disable()` - 활성화/비활성화
- `void Dispose()` - 에셋 해제

**GameplayActions struct**:
- `InputAction movement` - 이동 액션 (Value, Vector2)
- `InputAction button1Action` - 버튼1 액션 (Button)
- `InputAction button2Action` - 버튼2 액션 (Button)

**interface IGameplayActions**:
- `void OnMovement(InputAction.CallbackContext context)`
- `void OnButton1Action(InputAction.CallbackContext context)`
- `void OnButton2Action(InputAction.CallbackContext context)`
