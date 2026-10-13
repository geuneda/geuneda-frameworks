---
name: geuneda-nativeui
description: com.geuneda.nativeui 패키지(Geuneda.NativeUi)로 iOS/Android 네이티브 알림 다이얼로그, 액션 시트, 토스트 메시지를 띄우는 코드를 작성하거나 수정할 때 사용한다. NativeUiService, AlertButton, AlertButtonStyle 을 다루거나 네이티브 확인 팝업, 토스트 구현을 요청받았을 때 활성화한다.
---

# Geuneda Native UI

iOS/Android 네이티브 알림 다이얼로그(Alert/ActionSheet)와 토스트 메시지를 정적 메서드 두 개로 호출하는 패키지다. 의존성이 없고 MonoBehaviour 없이 어디서든 호출할 수 있다.

## 패키지 정보

- **패키지**: `com.geuneda.nativeui` (버전은 `package.json` 기준)
- **네임스페이스 / 어셈블리**: `Geuneda.NativeUi` / `Geuneda.NativeUi` (Auto Referenced)
- **설치**: `https://github.com/geuneda/geuneda-nativeui.git` (`#<태그>` 로 고정 가능)
- **의존성**: 없음
- **최소 Unity 버전**: 2020.3
- **소스**: `Runtime/NativeUiService.cs`, `Runtime/Plugins/iOS/NativeUi.m`

## 핵심 API

```csharp
public enum AlertButtonStyle { Default, Positive, Negative }

public struct AlertButton
{
    public string Text;
    public AlertButtonStyle Style;
    public Action Callback;
}

public static class NativeUiService
{
    public static void ShowAlertPopUp(bool isAlertSheet, string title, string message, params AlertButton[] buttons);
    public static void ShowToastMessage(string message, bool isLongDuration);
}
```

- `ShowAlertPopUp`: `isAlertSheet` 는 iOS 에서만 의미가 있다(ActionSheet). Android 는 무시한다.
- `ShowToastMessage`: `isLongDuration` 이 `true` 면 약 3.5초, `false` 면 약 2초.
- 에디터에서는 둘 다 `Debug.Log` 만 출력하고 콜백은 호출하지 않는다. iOS/Android 외 플랫폼 빌드에서는 `SystemException` 을 던진다.

스타일 매핑, 플랫폼별 동작, 내부 구현은 `references/api.md` 참조.

## 사용 패턴

### 확인 다이얼로그

```csharp
using Geuneda.NativeUi;
using UnityEngine;

public class DeleteConfirm : MonoBehaviour
{
    public void Ask()
    {
#if UNITY_IOS || UNITY_ANDROID
        NativeUiService.ShowAlertPopUp(false, "알림", "정말 삭제하시겠습니까?",
            new AlertButton { Text = "취소", Style = AlertButtonStyle.Default, Callback = () => { } },
            new AlertButton { Text = "삭제", Style = AlertButtonStyle.Negative, Callback = Delete });
#endif
    }

    private void Delete()
    {
        Debug.Log("삭제");
    }
}
```

### iOS 액션 시트

```csharp
NativeUiService.ShowAlertPopUp(true, "옵션 선택", "원하는 작업을 선택하세요.",
    new AlertButton { Text = "사진 촬영", Style = AlertButtonStyle.Default, Callback = TakePhoto },
    new AlertButton { Text = "취소", Style = AlertButtonStyle.Positive, Callback = () => { } });
```

iOS 에서 `Positive` 는 `UIAlertActionStyleCancel` 로 변환되므로 액션 시트의 취소 버튼으로 쓸 수 있다. 같은 코드가 Android 에서는 일반 다이얼로그(`BUTTON_NEUTRAL`, `BUTTON_POSITIVE`)로 표시된다.

### 토스트

```csharp
NativeUiService.ShowToastMessage("저장되었습니다.", false);           // 약 2초
NativeUiService.ShowToastMessage("네트워크 오류가 발생했습니다.", true); // 약 3.5초
```

## 함정

- **스타일 의미가 플랫폼마다 다르다**: `Default`/`Positive`/`Negative` 는 iOS 에서 `Default`/`Cancel`/`Destructive`, Android 에서 `BUTTON_NEUTRAL`/`BUTTON_POSITIVE`/`BUTTON_NEGATIVE` 가 된다.
- **iOS `Positive` 는 하나만**: UIKit 은 `Cancel` 스타일 액션을 하나만 허용한다.
- **Android 는 스타일당 버튼 하나, 최대 3개**: 같은 `Style` 을 다시 쓰면 앞 버튼이 대체된다.
- **iOS 콜백은 버튼 텍스트로 매칭**: 텍스트가 같은 버튼이 있으면 첫 번째 것만 호출된다. `_currentButtons` 정적 필드 하나로 관리하므로 알림이 열린 상태에서 새 알림을 띄우면 이전 알림의 버튼 정보가 덮어써진다. `Text` 가 null 이면 네이티브와 같이 빈 문자열로 보고 매칭한다.
- **버튼 인자**: `buttons` 가 `null` 이거나 비어 있으면 iOS, Android 모두 `ArgumentException`(v0.2.7). 에디터는 로그만 남긴다.
- **`Callback` 은 null 허용**: iOS, Android 모두 null 이면 알림만 닫고 아무것도 호출하지 않는다.
- **스레드**: 버튼 콜백은 Unity 메인 스레드에서 실행되므로 Unity API 를 써도 된다. Android 는 다이얼로그·토스트를 Android UI 스레드에서 만들고(`runOnUiThread`), 클릭은 `ShowAlertPopUp` 을 부른 스레드의 `SynchronizationContext` 로 넘겨 그 컨텍스트가 큐를 처리할 때 실행한다. 그래서 Android 에서는 메서드가 표시 완료를 기다리지 않고 표시 오류는 로그로만 남는다. `ShowAlertPopUp` 은 Unity 메인 스레드에서 부른다(Unreleased).
- **에디터에서 콜백 테스트 불가**: 에디터 분기는 `Debug.Log` 만 하고 반환한다.
- **비대상 플랫폼 예외**: Standalone/WebGL 등에서는 `SystemException`. 공용 코드에서는 `#if UNITY_IOS || UNITY_ANDROID` 로 감싼다.
- **버튼 배치 순서**: 배열 순서대로 추가하지만 실제 배치는 OS 규칙을 따른다.

## 참조 문서

- `references/api.md`: 공개 API 전체, 플랫폼별 동작, 내부 구현
