# Geuneda Native UI - API Reference

## 네임스페이스: Geuneda.NativeUi

### enum AlertButtonStyle

알림 다이얼로그 버튼의 스타일을 정의하는 열거형.

| 값 | 설명 | Android 매핑 |
|----|------|-------------|
| `Default` | 기본 스타일 | BUTTON_NEUTRAL (-3) |
| `Positive` | 긍정(확인) 스타일 | BUTTON_POSITIVE (-1) |
| `Negative` | 부정(취소/삭제) 스타일 | BUTTON_NEGATIVE (-2) |

---

### struct AlertButton

알림 다이얼로그에 표시할 버튼을 정의하는 구조체.

| 필드 | 타입 | 설명 |
|------|------|------|
| `Text` | `string` | 버튼에 표시할 텍스트 |
| `Style` | `AlertButtonStyle` | 버튼 스타일 |
| `Callback` | `Action` | 버튼 클릭 시 실행할 콜백. null 가능 |

---

### static class NativeUiService

네이티브 UI 화면을 호출하는 정적 서비스 클래스. iOS와 Android의 네이티브 다이얼로그 및 토스트 메시지를 Unity에서 사용할 수 있게 해준다.

---

#### public static void ShowAlertPopUp(bool isAlertSheet, string title, string message, params AlertButton[] buttons)

네이티브 OS 알림 팝업을 표시한다.

**파라미터**:

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `isAlertSheet` | `bool` | iOS에서 알림 시트(ActionSheet) 형태로 표시할지 여부. Android에서는 무시됨 |
| `title` | `string` | 알림 제목 |
| `message` | `string` | 알림 본문 메시지 |
| `buttons` | `params AlertButton[]` | 버튼 배열. 왼쪽에서 오른쪽 순서로 정렬 |

**예외**:
- `SystemException`: iOS/Android 외 플랫폼에서 호출 시
- `ArgumentException`: iOS에서 buttons가 null인 경우

**플랫폼별 동작**:

| 플랫폼 | 동작 |
|--------|------|
| Unity Editor | `Debug.Log`로 title, message 출력 |
| iOS | 네이티브 `AlertMessage()` 호출. `isAlertSheet`에 따라 Alert 또는 AlertSheet 표시 |
| Android | `AlertDialog.Builder`를 통해 네이티브 다이얼로그 표시 |
| 기타 | `SystemException` 발생 |

**iOS 구현 상세**:
- `[DllImport("__Internal")]`로 네이티브 플러그인 호출
- 시그니처: `AlertMessage(bool isSheet, string title, string message, string[] buttonsText, int[] buttonsStyle, int buttonsLength, AlertButtonDelegate alertButtonCallback)`
- 콜백은 `[MonoPInvokeCallback]`으로 마샬링
- 콜백 매칭: 버튼 텍스트 기준으로 `_currentButtons` 배열에서 검색
- `_currentButtons`는 정적 필드로, 새 알림 호출 시 덮어씌워짐

**Android 구현 상세**:
- `AndroidJavaClass("com.unity3d.player.UnityPlayer")`로 현재 Activity 획득
- `android.app.AlertDialog.Builder`로 다이얼로그 생성
- `alertDialog.Call("setButton", style, text, callback)`으로 버튼 추가
- 콜백: `AndroidJavaProxy("android.content.DialogInterface$OnClickListener")` 구현
- `onClick(AndroidJavaObject dialog, int which)` 메서드에서 `dialog.Call("dismiss")` 후 콜백 실행

---

#### public static void ShowToastMessage(string message, bool isLongDuration)

네이티브 OS 토스트 메시지를 표시한다.

**파라미터**:

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `message` | `string` | 표시할 메시지 텍스트 |
| `isLongDuration` | `bool` | true: 3.5초(LENGTH_LONG), false: 2초(LENGTH_SHORT) |

**예외**:
- `SystemException`: iOS/Android 외 플랫폼에서 호출 시

**플랫폼별 동작**:

| 플랫폼 | 동작 |
|--------|------|
| Unity Editor | `Debug.Log`로 message 출력 |
| iOS | 네이티브 `ToastMessage()` 호출 |
| Android | `Toast.makeText()` 호출 |
| 기타 | `SystemException` 발생 |

**iOS 구현 상세**:
- `[DllImport("__Internal")]`로 네이티브 플러그인 호출
- 시그니처: `ToastMessage(string message, bool isLongDuration)`

**Android 구현 상세**:
- `AndroidJavaClass("com.unity3d.player.UnityPlayer")`로 현재 Activity 획득
- `AndroidJavaClass("android.widget.Toast")`에서 `makeText()` 호출
- duration: `isLongDuration ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT`
- `toast.Call("show")` 후 `toast.Dispose()`

---

### internal 타입

#### delegate AlertButtonDelegate (iOS 전용)
- 시그니처: `void AlertButtonDelegate(string buttonText)`
- iOS 네이티브 코드에서 버튼 클릭 시 호출되는 콜백 델리게이트

#### class AndroidButtonCallback : AndroidJavaProxy (Android 전용)
- `DialogInterface.OnClickListener` 프록시 구현
- 생성자: `AndroidButtonCallback(Action callback)`
- `onClick(AndroidJavaObject dialog, int which)`: dialog dismiss 후 callback 실행

#### static int ConvertToAndroidStyle(AlertButtonStyle style) (Android 전용)
- `Default` -> -3 (BUTTON_NEUTRAL)
- `Positive` -> -1 (BUTTON_POSITIVE)
- `Negative` -> -2 (BUTTON_NEGATIVE)
- 잘못된 스타일: `ArgumentOutOfRangeException` 발생
