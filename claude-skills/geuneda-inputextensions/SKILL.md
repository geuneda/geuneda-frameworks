---
name: geuneda-inputextensions
description: Unity Input System 확장 패키지(geuneda-inputextensions)의 코드를 작성하거나 수정할 때 사용하는 스킬. 포인터 드래그, 스와이프, 탭 제스처, 게임패드 입력 처리 코드를 구현할 때 활성화한다.
---

# Geuneda Input Extensions

Unity의 새로운 Input System 패키지를 확장하여 터치, 드래그, 스와이프, 탭 제스처 및 게임패드 입력을 간편하게 처리할 수 있게 해주는 라이브러리이다. 포인터 입력(마우스, 펜, 터치스크린)을 통합 관리하고, 제스처 인식(스와이프/탭)을 자동화한다.

## 활성화 시점

- Unity Input System 기반의 터치/드래그 입력 처리 코드를 작성할 때
- 스와이프, 탭 등 제스처 인식 기능을 구현할 때
- 게임패드(아날로그 스틱, 버튼) 입력 관리 코드를 작성할 때
- 멀티터치 포인터 입력을 처리해야 할 때
- PointerInputManager, GestureController, GamepadInputManager를 사용하거나 확장할 때

## 패키지 정보

- **네임스페이스**: `Input` (핵심), `Input.Controls` (자동 생성 컨트롤)
- **설치**: `https://github.com/geuneda/geuneda-inputextensions.git`
- **의존성**: `com.unity.inputsystem` >= 1.0.0-preview.4
- **최소 Unity 버전**: 2019.3

## 아키텍처 개요

```
PointerControls / GamepadControls (자동 생성 InputActionCollection)
       |                    |
PointerInputManager    GamepadInputManager (MonoBehaviour, 입력 해석)
       |
GestureController (MonoBehaviour, 제스처 인식)
       |
SwipeInput / TapInput (결과 데이터 구조체)
```

- `PointerInputManager`는 `PointerControls`로부터 원시 포인터 입력을 수신하여 Pressed/Dragged/Released 이벤트를 발행한다.
- `GestureController`는 `PointerInputManager`의 이벤트를 구독하여 `ActiveGesture`를 추적하고, 유효한 스와이프/탭을 감지하면 이벤트를 발행한다.
- `GamepadInputManager`는 `GamepadControls`로부터 아날로그 스틱과 버튼 입력을 수신하여 프로퍼티로 노출한다.

## 핵심 API

### PointerInput (struct)
포인터 입력 데이터를 담는 구조체.
- `bool Contact` - 접촉 여부
- `int InputId` - 입력 소스 ID
- `Vector2 Position` - 위치
- `Vector2? Tilt` - 펜 기울기 (nullable)
- `float? Pressure` - 압력 (nullable)
- `Vector2? Radius` - 터치 반경 (nullable)
- `float? Twist` - 비틀림 (nullable)

### PointerInputManager : MonoBehaviour
포인터(마우스/펜/터치) 입력을 해석하는 입력 관리자.
- `event Action<PointerInput, double> Pressed` - 누르기 시작
- `event Action<PointerInput, double> Dragged` - 드래그 중
- `event Action<PointerInput, double> Released` - 누르기 해제
- `[SerializeField] bool m_UseMouse / m_UsePen / m_UseTouch` - 입력 장치 필터

### GestureController : MonoBehaviour
제스처(스와이프/탭) 인식 컨트롤러.
- `event Action<SwipeInput> Pressed` - 누르기 시작
- `event Action<SwipeInput> PotentiallySwiped` - 스와이프 진행 중
- `event Action<SwipeInput> Swiped` - 스와이프 완료
- `event Action<TapInput> Tapped` - 탭 감지
- 설정: `maxTapDuration`, `maxTapDrift`, `maxSwipeDuration`, `minSwipeDistance`, `swipeDirectionSamenessThreshold`

### SwipeInput (struct)
스와이프 결과 데이터.
- `int InputId`, `Vector2 StartPosition`, `Vector2 PreviousPosition`, `Vector2 EndPosition`
- `Vector2 SwipeDirection`, `float SwipeVelocity`, `float TravelDistance`
- `double SwipeDuration`, `float SwipeSameness`

### TapInput (struct)
탭 결과 데이터.
- `Vector2 PressPosition`, `Vector2 ReleasePosition`
- `double TapDuration`, `float TapDrift`, `double TimeStamp`

### GamepadInputManager : MonoBehaviour
게임패드/키보드 입력 관리자.
- `Vector2 AnalogueValue { get; }` - 아날로그 스틱 값
- `bool PrimaryButtonValue { get; }` - 기본 버튼 상태
- `bool SecondaryButtonValue { get; }` - 보조 버튼 상태

## 사용 패턴

### 기본 포인터 드래그 처리
```csharp
using Input;
using UnityEngine;

public class DragHandler : MonoBehaviour
{
    [SerializeField] private PointerInputManager inputManager;

    private void Awake()
    {
        inputManager.Pressed += OnPressed;
        inputManager.Dragged += OnDragged;
        inputManager.Released += OnReleased;
    }

    private void OnPressed(PointerInput input, double time)
    {
        // 드래그 시작 처리
    }

    private void OnDragged(PointerInput input, double time)
    {
        // input.Position으로 드래그 위치 처리
    }

    private void OnReleased(PointerInput input, double time)
    {
        // 드래그 종료 처리
    }
}
```

### 스와이프/탭 제스처 감지
```csharp
using Input;
using UnityEngine;

public class GestureHandler : MonoBehaviour
{
    [SerializeField] private GestureController gestureController;

    private void Awake()
    {
        gestureController.Swiped += OnSwiped;
        gestureController.Tapped += OnTapped;
    }

    private void OnSwiped(SwipeInput swipe)
    {
        // swipe.SwipeDirection으로 방향 판단
        // swipe.SwipeVelocity로 속도 활용
    }

    private void OnTapped(TapInput tap)
    {
        // tap.PressPosition으로 탭 위치 활용
    }
}
```

### 게임패드 입력 폴링
```csharp
using Input;
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    [SerializeField] private GamepadInputManager gamepadInput;

    private void Update()
    {
        Vector2 movement = gamepadInput.AnalogueValue;
        // movement로 이동 처리

        if (gamepadInput.PrimaryButtonValue)
        {
            // 기본 버튼 액션
        }
    }
}
```

## 주의사항

- `com.unity.inputsystem` 패키지가 반드시 설치되어야 한다.
- 프로젝트 설정에서 Input System을 활성 Input Handling으로 설정해야 한다 (Player Settings > Active Input Handling).
- `PointerControls`와 `GamepadControls`는 .inputactions 파일에서 자동 생성된 코드이므로 직접 수정하지 않는다.
- `PointerInputComposite`는 에디터와 런타임에서 자동 등록된다 (`[InitializeOnLoad]`, `[RuntimeInitializeOnLoadMethod]`).
- 멀티터치는 touch0~touch4까지 5개 터치 포인트를 지원한다.
- 네임스페이스가 `Input`으로 되어 있어 `UnityEngine.Input`과 충돌할 수 있으므로 명시적 using이 필요할 수 있다.
- GestureController는 PointerInputManager에 대한 참조를 SerializeField로 가지므로 인스펙터에서 연결해야 한다.
- 게임패드 바인딩: 왼쪽 스틱 + WASD(이동), South/Space/Z(버튼1), East/X(버튼2).

## 참조 문서

상세 API 문서는 `references/api.md` 참조.
