---
name: geuneda-nativeui
description: Unity에서 iOS/Android 네이티브 UI(알림 다이얼로그, 토스트 메시지)를 표시하는 패키지(geuneda-nativeui)의 코드를 작성하거나 수정할 때 사용하는 스킬. 네이티브 팝업, 토스트 메시지 구현 시 활성화한다.
---

# Geuneda Native UI

iOS 및 Android의 네이티브 UI 기능을 Unity에서 사용할 수 있게 해주는 라이브러리이다. 네이티브 알림 다이얼로그(Alert/AlertSheet)와 토스트 메시지를 지원하며, 각 플랫폼의 네이티브 API를 직접 호출한다.

## 활성화 시점

- 네이티브 알림/확인 다이얼로그를 표시해야 할 때
- 토스트 메시지를 표시해야 할 때
- iOS AlertSheet 형태의 팝업을 표시해야 할 때
- 플랫폼별 네이티브 UI 기능을 Unity에서 호출해야 할 때
- `NativeUiService`를 사용하거나 확장할 때

## 패키지 정보

- **네임스페이스**: `Geuneda.NativeUi`
- **설치**: `https://github.com/geuneda/geuneda-nativeui.git`
- **의존성**: 없음
- **최소 Unity 버전**: 2020.3

## 핵심 API

### enum AlertButtonStyle
알림 버튼의 스타일.
- `Default` - 기본 스타일 (Android: BUTTON_NEUTRAL = -3)
- `Positive` - 긍정 스타일 (Android: BUTTON_POSITIVE = -1)
- `Negative` - 부정 스타일 (Android: BUTTON_NEGATIVE = -2)

### struct AlertButton
알림 다이얼로그의 버튼 정의.
- `string Text` - 버튼 텍스트
- `AlertButtonStyle Style` - 버튼 스타일
- `Action Callback` - 클릭 콜백

### static class NativeUiService
네이티브 UI 화면을 호출하는 정적 서비스 클래스.

#### ShowAlertPopUp
```csharp
public static void ShowAlertPopUp(
    bool isAlertSheet,
    string title,
    string message,
    params AlertButton[] buttons
)
```
네이티브 OS 알림 팝업을 표시한다.
- `isAlertSheet`: iOS에서 알림 시트 형태로 표시할지 여부 (Android에서는 무시됨)
- `title`: 알림 제목
- `message`: 알림 메시지
- `buttons`: 버튼 배열 (왼쪽에서 오른쪽 순서)
- **예외**: iOS/Android 외 플랫폼에서 `SystemException` 발생
- **에디터**: Debug.Log로 호출 내용만 출력

#### ShowToastMessage
```csharp
public static void ShowToastMessage(string message, bool isLongDuration)
```
네이티브 OS 토스트 메시지를 표시한다.
- `message`: 표시할 메시지
- `isLongDuration`: true면 3.5초(LENGTH_LONG), false면 2초(LENGTH_SHORT)
- **예외**: iOS/Android 외 플랫폼에서 `SystemException` 발생
- **에디터**: Debug.Log로 호출 내용만 출력

## 사용 패턴

### 확인/취소 알림 다이얼로그
```csharp
using Geuneda.NativeUi;

NativeUiService.ShowAlertPopUp(
    false,
    "알림",
    "정말 삭제하시겠습니까?",
    new AlertButton
    {
        Text = "취소",
        Style = AlertButtonStyle.Negative,
        Callback = () => { /* 취소 처리 */ }
    },
    new AlertButton
    {
        Text = "삭제",
        Style = AlertButtonStyle.Positive,
        Callback = () => { /* 삭제 처리 */ }
    }
);
```

### iOS 알림 시트 형태
```csharp
using Geuneda.NativeUi;

NativeUiService.ShowAlertPopUp(
    true,  // iOS에서 AlertSheet 형태로 표시
    "옵션 선택",
    "원하는 작업을 선택하세요.",
    new AlertButton { Text = "사진 촬영", Style = AlertButtonStyle.Default, Callback = TakePhoto },
    new AlertButton { Text = "갤러리", Style = AlertButtonStyle.Default, Callback = OpenGallery },
    new AlertButton { Text = "취소", Style = AlertButtonStyle.Negative, Callback = null }
);
```

### 토스트 메시지
```csharp
using Geuneda.NativeUi;

// 짧은 토스트 (2초)
NativeUiService.ShowToastMessage("저장되었습니다.", false);

// 긴 토스트 (3.5초)
NativeUiService.ShowToastMessage("네트워크 오류가 발생했습니다. 다시 시도해주세요.", true);
```

## 플랫폼별 구현 상세

### iOS
- 네이티브 플러그인(`__Internal`)을 통해 Objective-C/Swift 코드 호출
- `AlertMessage()`: 네이티브 알림/시트 표시, 버튼 텍스트와 스타일 배열 전달
- `ToastMessage()`: 네이티브 토스트 표시
- 알림 버튼 콜백은 `MonoPInvokeCallback`으로 전달 (버튼 텍스트로 매칭)
- iOS에서는 한 번에 하나의 알림만 활성화 가능 (`_currentButtons` 정적 필드)

### Android
- `AndroidJavaClass`/`AndroidJavaObject`를 통해 Java API 직접 호출
- 알림: `android.app.AlertDialog.Builder` 사용
- 토스트: `android.widget.Toast.makeText()` 사용
- 버튼 콜백: `AndroidJavaProxy`로 `DialogInterface.OnClickListener` 구현

### 에디터
- 모든 호출은 `Debug.Log`로 대체됨. 실제 네이티브 UI는 표시되지 않는다.

## 주의사항

- iOS/Android 빌드에서만 실제 네이티브 UI가 표시된다. 에디터에서는 Debug.Log만 출력된다.
- iOS에서 알림 버튼 콜백은 버튼 텍스트로 매칭하므로, 동일한 텍스트의 버튼이 있으면 첫 번째 버튼의 콜백만 호출된다.
- iOS에서는 한 번에 하나의 알림만 관리한다 (`_currentButtons` 정적 필드 덮어쓰기).
- Android에서 AlertDialog의 버튼은 최대 3개까지 지원된다 (POSITIVE, NEGATIVE, NEUTRAL).
- `buttons` 파라미터에 null을 전달하면 iOS에서 `ArgumentException`이 발생한다.
- 정적 클래스이므로 MonoBehaviour 생명주기와 무관하게 어디서든 호출 가능하다.

## 참조 문서

상세 API 문서는 `references/api.md` 참조.
