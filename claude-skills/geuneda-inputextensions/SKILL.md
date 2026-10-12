---
name: geuneda-inputextensions
description: com.geuneda.inputextensions 패키지(네임스페이스 Input, Input.Controls)를 쓰거나 고칠 때 사용한다. PointerInputManager 로 마우스/펜/터치 드래그를 받거나, GestureController 로 스와이프/탭을 감지하거나, GamepadInputManager 로 스틱/버튼 값을 폴링하는 코드를 작성할 때, 그리고 PointerControls/GamepadControls 바인딩이나 PointerInputComposite 를 다룰 때 활성화한다.
---

# Geuneda Input Extensions

Unity Input System 위에서 포인터 드래그, 스와이프/탭 제스처, 게임패드 입력을 이벤트와 프로퍼티로 제공하는 패키지.

## 패키지 정보

- 패키지: `com.geuneda.inputextensions` (버전은 `package.json` 기준)
- 설치: `https://github.com/geuneda/geuneda-inputextensions.git` (고정하려면 `#<태그>`)
- 네임스페이스: `Input`(컴포넌트, 데이터 타입), `Input.Controls`(자동 생성 래퍼)
- 어셈블리: `Geuneda.InputExtensions` (`Runtime/Geuneda.InputExtensions.asmdef`, autoReferenced)
- 의존성: `com.unity.inputsystem` 1.1.1 이상, `com.unity.ugui` 1.0.0 이상(`UnityEngine.UI`, `UnityEngine.EventSystems`), Unity 2019.4 이상(`package.json` 기준, v1.0.4)

## 구조

```
PointerControls  ->  PointerInputManager  ->  GestureController  ->  SwipeInput / TapInput
GamepadControls  ->  GamepadInputManager
```

- `PointerInputManager` 는 `PointerControls.pointer.point` 액션의 값을 `PointerInput` 으로 읽어 `Pressed`/`Dragged`/`Released` 를 발행한다.
- `GestureController` 는 `PointerInputManager` 이벤트를 구독해 입력 ID 별로 내부 `ActiveGesture` 를 추적하고 `Pressed`/`PotentiallySwiped`/`Swiped`/`Tapped` 를 발행한다.
- `GamepadInputManager` 는 `GamepadControls.gameplay` 액션 값을 프로퍼티에 저장한다. 이벤트는 없고 폴링해서 쓴다.

## 핵심 API

전체 목록은 [references/api.md](references/api.md) 참고.

| 타입 | 주요 멤버 |
|------|-----------|
| `PointerInputManager` | `event Action<PointerInput, double> Pressed / Dragged / Released` (두 번째 인자는 `InputAction.CallbackContext.time`) |
| `GestureController` | `event Action<SwipeInput> Pressed / PotentiallySwiped / Swiped`, `event Action<TapInput> Tapped` |
| `GamepadInputManager` | `Vector2 AnalogueValue`, `bool PrimaryButtonValue`, `bool SecondaryButtonValue` (모두 public get) |
| `PointerInput` | `Contact`, `InputId`, `Position`, `Tilt?`, `Pressure?`, `Radius?`, `Twist?` (public 필드) |
| `SwipeInput` | `InputId`, `StartPosition`, `PreviousPosition`, `EndPosition`, `SwipeDirection`, `SwipeVelocity`, `TravelDistance`, `SwipeDuration`, `SwipeSameness` (readonly) |
| `TapInput` | `PressPosition`, `ReleasePosition`, `TapDuration`, `TapDrift`, `TimeStamp` (readonly, InputId 없음) |

`SwipeInput`, `TapInput` 생성자는 internal 이라 외부에서 만들 수 없다.

## 사용 패턴

### 스와이프/탭 감지

씬 설정: `PointerInputManager` 를 추가하고 인스펙터에서 `Use Mouse`/`Use Pen`/`Use Touch` 를 켠다. `GestureController` 의 `Input Manager` 필드에 연결한다.

```csharp
using Input;
using UnityEngine;

public class GestureHandler : MonoBehaviour
{
    [SerializeField] private GestureController gestureController;

    private void OnEnable()
    {
        gestureController.Swiped += OnSwiped;
        gestureController.Tapped += OnTapped;
    }

    private void OnDisable()
    {
        gestureController.Swiped -= OnSwiped;
        gestureController.Tapped -= OnTapped;
    }

    private void OnSwiped(SwipeInput swipe)
    {
        // swipe.SwipeDirection 은 (EndPosition - StartPosition).normalized
    }

    private void OnTapped(TapInput tap)
    {
        // tap.ReleasePosition 은 화면 좌표
    }
}
```

### 포인터 드래그 직접 처리

```csharp
using System.Collections.Generic;
using Input;
using UnityEngine;

public class DragHandler : MonoBehaviour
{
    [SerializeField] private PointerInputManager inputManager;

    // 이벤트는 포인터(input.InputId)마다 따로 온다. 멀티터치를 위해 InputId 별로 상태를 둔다
    private readonly HashSet<int> pressedPointers = new HashSet<int>();

    private void OnEnable()
    {
        inputManager.Pressed += OnPressed;
        inputManager.Dragged += OnDragged;
        inputManager.Released += OnReleased;
    }

    private void OnDisable()
    {
        inputManager.Pressed -= OnPressed;
        inputManager.Dragged -= OnDragged;
        inputManager.Released -= OnReleased;

        // 관리자가 꺼지거나 장치가 분리되면 해제 이벤트 없이 끝나므로 자신의 상태도 비운다
        pressedPointers.Clear();
    }

    private void OnPressed(PointerInput input, double time)
    {
        // 해제를 받지 못하고 남은 같은 InputId 가 있어도 새 시작으로 처리한다
        pressedPointers.Add(input.InputId);
    }

    private void OnDragged(PointerInput input, double time)
    {
        if (!pressedPointers.Contains(input.InputId))
        {
            return;
        }

        // input.Position 으로 드래그 위치 처리
    }

    private void OnReleased(PointerInput input, double time)
    {
        // 정상 해제: 여기서 탭/드래그 완료 같은 판정을 한다
        pressedPointers.Remove(input.InputId);
    }
}
```

### 게임패드 폴링

```csharp
using Input;
using UnityEngine;

public class PlayerMover : MonoBehaviour
{
    [SerializeField] private GamepadInputManager gamepadInput;
    [SerializeField] private float speed = 5f;

    private void Update()
    {
        Vector2 move = gamepadInput.AnalogueValue;
        transform.Translate(new Vector3(move.x, 0f, move.y) * speed * Time.deltaTime);

        if (gamepadInput.PrimaryButtonValue)
        {
            // Button South / Space / Z
        }
    }
}
```

## 함정

- 전역 네임스페이스 `Input` 이 `UnityEngine.Input` 을 가린다. 어셈블리가 autoReferenced 이므로 프로젝트 코드에서 레거시 API 는 `UnityEngine.Input.GetKey(...)` 처럼 완전한 이름으로 써야 한다. 이 패키지 네임스페이스는 `Geuneda.InputExtensions` 가 아니다(그건 어셈블리 이름).
- `PointerInputManager` 의 `m_UseMouse`/`m_UsePen`/`m_UseTouch` 는 기본 false. 셋 다 true 면 `bindingMask = null`, 아니면 켜진 그룹으로 `InputBinding.MaskByGroups` 를 건다. 사용할 장치는 명시적으로 켠다.
- `PointerInputManager` 는 누름 상태를 `InputId` 별로 관리한다(v1.0.2). 포인터마다 `Pressed` -> `Dragged` -> `Released` 순서로 오고, 누르지 않은 포인터의 이동(마우스 호버)은 무시한다. 활성화할 때 이미 눌린 포인터도 `Pressed` 로 온다(액션 initialStateCheck). 비활성화, 액션 리셋, 장치 분리 때는 이벤트 없이 그 포인터들의 눌림 상태만 비운다(입력 콜백 안에서 비활성화해도 `Released` 가 나가지 않는다). 그 뒤 같은 포인터의 접촉은 다시 `Pressed` 로 오므로, 직접 상태를 추적한다면 같은 `InputId` 의 `Pressed` 를 새 시작으로 처리하고 자신의 `OnDisable` 에서도 상태를 비운다.
- `InputId`: 마우스는 `PointerInputModule.kMouseLeftId`, 펜은 `int.MinValue`, 터치는 `touchId`.
- `PointerInput` 의 nullable 필드는 값이 0(또는 zero 벡터)이면 null 이다. `Pressure.HasValue` 등으로 확인한다.
- `GestureController.Awake` 에서 `inputManager` 이벤트를 구독하므로 인스펙터 연결이 없으면 `NullReferenceException`.
- `GestureController` 는 새 `Pressed` 때 관리자에서 더 이상 눌려 있지 않은 포인터(관리자 비활성화, 장치 분리로 해제를 받지 못한 것)의 남은 제스처를 지운다(v1.0.3). 지금 눌려 있는 다른 포인터의 제스처는 유지되므로 멀티터치는 끊기지 않는다. 같은 ID 가 다시 눌리면 그 제스처는 새로 시작한다.
- `IsValidSwipe`/`IsValidTap` 은 지속 시간(`EndTime - StartTime`)이 각각 `maxSwipeDuration`, `maxTapDuration` 이하여야 참이다. `PotentiallySwiped` 도 같은 조건이라 `maxSwipeDuration` 을 넘겨 드래그하면 더 이상 발행되지 않는다. `minSwipeDistance <= maxTapDrift` 면 한 동작이 `Swiped` 와 `Tapped` 를 모두 발행할 수 있다.
- `GestureController.Pressed` 의 `SwipeInput` 은 막 시작한 제스처라 `SwipeDuration`, `SwipeVelocity`, `TravelDistance` 가 0 이다.
- 디버그 `label`(`UnityEngine.UI.Text`)을 연결하면 `Camera.main` 을 참조한다.
- `PointerControls`, `GamepadControls` 는 `.inputactions` 에서 생성된 코드다(`wrapperCodeNamespace: Input.Controls`). 직접 수정하지 말고 `.inputactions` 를 고친 뒤 재생성한다. `point` 액션 타입은 `PassThrough` 다(v1.0.2). 충돌 해결 없이 모든 포인터 변화가 들어온다.
- Player Settings 의 `Active Input Handling` 이 Input System 을 포함해야 한다.
