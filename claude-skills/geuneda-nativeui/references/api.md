# Geuneda Native UI - API Reference

소스: `Runtime/NativeUiService.cs`, `Runtime/Plugins/iOS/NativeUi.m`
네임스페이스: `Geuneda.NativeUi` / 어셈블리: `Geuneda.NativeUi`

## 공개 API

### enum AlertButtonStyle

```csharp
public enum AlertButtonStyle
{
    Default,   // 0
    Positive,  // 1
    Negative   // 2
}
```

| 값 | iOS (`UIAlertActionStyle`, 정수 값 그대로 캐스팅) | Android (`ConvertToAndroidStyle`) |
|----|------------------------------------------------|-----------------------------------|
| `Default` | `UIAlertActionStyleDefault` (0) | `BUTTON_NEUTRAL` (-3) |
| `Positive` | `UIAlertActionStyleCancel` (1) | `BUTTON_POSITIVE` (-1) |
| `Negative` | `UIAlertActionStyleDestructive` (2) | `BUTTON_NEGATIVE` (-2) |

---

### struct AlertButton

```csharp
public struct AlertButton
{
    public string Text;
    public AlertButtonStyle Style;
    public Action Callback;
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `Text` | `string` | 버튼 텍스트. iOS 에서는 콜백 매칭 키로도 쓰인다 |
| `Style` | `AlertButtonStyle` | 버튼 스타일 |
| `Callback` | `System.Action` | 버튼 클릭 시 호출. null 허용(`?.Invoke()`) |

---

### static class NativeUiService

#### ShowAlertPopUp

```csharp
public static void ShowAlertPopUp(bool isAlertSheet, string title, string message, params AlertButton[] buttons)
```

| 파라미터 | 설명 |
|----------|------|
| `isAlertSheet` | `true` 면 iOS 에서 `UIAlertControllerStyleActionSheet`, `false` 면 `UIAlertControllerStyleAlert`. Android 는 사용하지 않음 |
| `title` | 알림 제목 |
| `message` | 알림 본문 |
| `buttons` | 추가할 버튼. 배열 순서대로 추가되지만 실제 배치는 OS 가 결정 |

| 플랫폼 (컴파일 분기) | 동작 |
|----------------------|------|
| `UNITY_EDITOR` | `Debug.Log` 로 title, message 만 출력. 콜백 호출 없음 |
| `UNITY_IOS` | `buttons` 가 null 이거나 비어 있으면 `ArgumentException`. `_currentButtons` 에 저장 후 네이티브 `AlertMessage` 호출. 알림 생성과 표시는 메인 큐에서 `UnityGetGLViewController()` 로 present |
| `UNITY_ANDROID` | `AlertDialog.Builder(currentActivity).create()` 로 만든 `AlertDialog` 에 `setTitle`, `setMessage`, 버튼마다 `setButton(style, text, listener)` 후 `show` |
| 그 외 | `SystemException` |

예외:
- `SystemException`: iOS/Android/에디터 외 플랫폼
- `ArgumentException`: iOS, Android 에서 `buttons` 가 null 이거나 비어 있을 때(에디터는 로그만)

#### ShowToastMessage

```csharp
public static void ShowToastMessage(string message, bool isLongDuration)
```

| 파라미터 | 설명 |
|----------|------|
| `message` | 표시할 메시지 |
| `isLongDuration` | `true`: iOS 3.5초 / Android `Toast.LENGTH_LONG`. `false`: iOS 2초 / Android `Toast.LENGTH_SHORT` |

| 플랫폼 (컴파일 분기) | 동작 |
|----------------------|------|
| `UNITY_EDITOR` | `Debug.Log` 로 message 출력 |
| `UNITY_IOS` | 네이티브 `ToastMessage` 호출. 메인 큐에서 제목 없는 `UIAlertController`(Alert 스타일, 버튼 없음)를 띄우고 `dispatch_after` 로 지정 시간 후 닫음 |
| `UNITY_ANDROID` | `Toast.makeText(currentActivity, message, duration)` 후 `show` |
| 그 외 | `SystemException` |

---

## 내부 구현 (공개 API 아님)

패키지 자체를 수정할 때만 참고한다.

### iOS (`#if UNITY_IOS`)

| 멤버 | 선언 |
|------|------|
| 콜백 델리게이트 | `internal delegate void AlertButtonDelegate(string buttonText)` |
| 네이티브 알림 | `[DllImport("__Internal")] private static extern void AlertMessage(bool isSheet, string title, string message, string[] buttonsText, int[] buttonsStyle, int buttonsLength, AlertButtonDelegate alertButtonCallback)` |
| 네이티브 토스트 | `[DllImport("__Internal")] private static extern void ToastMessage(string message, bool isLongDuration)` |
| 버튼 콜백 | `[AOT.MonoPInvokeCallback(typeof(AlertButtonDelegate))] private static void AlertButtonCallback(string buttonText)` |
| 현재 버튼 | `private static AlertButton[] _currentButtons` |

- `AlertButtonCallback` 은 `_currentButtons` 에서 `Text` 가 같은 첫 버튼의 `Callback?.Invoke()` 를 호출한다.
- `NativeUi.m` 은 문자열을 `[NSString stringWithUTF8String:]` 로 변환하며 NULL 은 빈 문자열(`@""`)로 바꾼다. 인자는 호출 중에 복사하고 `UIAlertController` 생성과 표시는 `dispatch_async(dispatch_get_main_queue(), ...)` 안에서 한다.
- 액션 시트의 `popoverPresentationController` 가 있으면(iPad) `sourceView` 를 루트 뷰로, `sourceRect` 를 루트 뷰 중앙으로, `permittedArrowDirections` 를 0 으로 설정한다.
- `NativeUi.m.meta` 는 iOS 에서만 활성화되어 있다. C# 은 `UNITY_IOS` 분기뿐이라 tvOS 는 지원하지 않는다.

### Android (`#elif UNITY_ANDROID`)

| 멤버 | 선언 |
|------|------|
| 클릭 리스너 | `private class AndroidButtonCallback : AndroidJavaProxy` (`android.content.DialogInterface$OnClickListener`) |
| 스타일 변환 | `private static int ConvertToAndroidStyle(AlertButtonStyle style)` |

- `AndroidButtonCallback.onClick(AndroidJavaObject dialog, int which)` 는 `dialog.Call("dismiss")` 후 `_callback?.Invoke()` 를 호출한다.
- `ConvertToAndroidStyle` 은 정의되지 않은 값에 `ArgumentOutOfRangeException` 을 던진다.
- `AlertDialog.setButton` 은 버튼 종류(`which`)당 하나만 유지하므로 버튼은 스타일당 하나, 최대 3개다.
