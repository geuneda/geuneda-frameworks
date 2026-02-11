---
name: geuneda-notificationservice
description: Unity 모바일 프로젝트에서 로컬/원격 알림을 예약, 취소, 관리하는 코드를 작성하거나 수정할 때 사용하는 스킬. Geuneda.NotificationService 네임스페이스의 API를 활용한 알림 시스템 구현을 지원합니다.
---

# Geuneda Notification Service

Unity의 Mobile Notifications 패키지를 기반으로 Android/iOS 모바일 알림을 통합 관리하는 크로스 플랫폼 래퍼 패키지입니다. 로컬 알림 예약, 원격 알림 수신, 알림 취소/닫기, 큐잉 시스템, 포그라운드/백그라운드 전환 시 자동 처리 기능을 제공합니다.

## 활성화 시점

- 모바일 앱에서 로컬 푸시 알림을 예약해야 할 때
- 알림 채널을 생성하고 관리해야 할 때
- 알림 예약/취소/닫기 로직을 구현할 때
- 포그라운드/백그라운드 전환 시 알림 동작을 제어해야 할 때
- 알림 전달 이벤트를 구독하고 처리해야 할 때

## 패키지 정보

- **네임스페이스**: `Geuneda.NotificationService`
- **설치**: `https://github.com/geuneda/geuneda-notificationservice.git`
- **의존성**: `com.unity.mobile.notifications` (1.3.0 이상)
- **최소 Unity**: 2019.4

## 핵심 API

### INotificationService (서비스 인터페이스)

알림 시스템의 주요 진입점입니다.

```csharp
public interface INotificationService
{
    event Action<PendingNotification> OnLocalNotificationDeliveredEvent;
    event Action<PendingNotification> OnLocalNotificationExpiredEvent;
    IReadOnlyList<PendingNotification> PendingNotifications { get; }
    IGameNotification CreateNotification();
    PendingNotification ScheduleNotification(IGameNotification gameNotification);
    void CancelNotification(int notificationId);
    void DismissNotification(int notificationId);
    void CancelAllScheduledNotifications();
    void DismissAllDisplayedNotifications();
}
```

### MobileNotificationService (구현 클래스)

`INotificationService`의 구체 구현. 생성 시 채널을 등록하고 내부적으로 `GameNotificationsMonoBehaviour`를 생성합니다.

```csharp
public MobileNotificationService(params GameNotificationChannel[] channels)
```

### IGameNotification (알림 데이터)

알림의 속성을 정의하는 인터페이스입니다.

- `int? Id` - 고유 식별자 (null이면 자동 생성)
- `string Title` - 알림 제목
- `string Body` - 알림 본문
- `string Subtitle` - 부제목
- `string Channel` - 채널 식별자
- `int? BadgeNumber` - 배지 번호
- `bool ShouldAutoCancel` - 탭 시 자동 닫힘 (Android 전용)
- `DateTime? DeliveryTime` - 전달 시간
- `bool Scheduled` - 예약 상태 (읽기 전용)
- `string SmallIcon` / `string LargeIcon` - 아이콘

### GameNotificationChannel (채널 설정)

Android 알림 채널을 정의하는 readonly struct입니다.

```csharp
public GameNotificationChannel(string id, string name, string description)
public GameNotificationChannel(string id, string name, string description,
    NotificationStyle style, bool showsBadge = true, bool showLights = false,
    bool vibrates = true, bool highPriority = false,
    PrivacyMode privacy = PrivacyMode.Public, long[] vibrationPattern = null)
```

### OperatingMode (동작 모드)

```csharp
[Flags]
public enum OperatingMode
{
    NoQueue = 0x00,                    // 즉시 예약
    Queue = 0x01,                      // 백그라운드 전환 시까지 큐잉
    ClearOnForegrounding = 0x02,       // 포그라운드 시 알림 지우기
    RescheduleAfterClearing = 0x04,    // 지운 후 재예약
    QueueAndClear = Queue | ClearOnForegrounding,
    QueueClearAndReschedule = Queue | ClearOnForegrounding | RescheduleAfterClearing,
}
```

## 사용 패턴

### 기본 알림 서비스 초기화

```csharp
using Geuneda.NotificationService;

// 채널 생성 (Android 필수)
var channel = new GameNotificationChannel(
    "default",
    "Default Channel",
    "Default notification channel"
);

// 서비스 생성 및 초기화
INotificationService notificationService = new MobileNotificationService(channel);

// 이벤트 구독
notificationService.OnLocalNotificationDeliveredEvent += notification =>
{
    Debug.Log($"알림 전달됨: {notification.Notification.Title}");
};
```

### 알림 예약

```csharp
// 알림 생성
var notification = notificationService.CreateNotification();
notification.Title = "게임 보상 준비 완료";
notification.Body = "보상을 수령하세요!";
notification.DeliveryTime = DateTime.Now.AddHours(4);

// 예약
var pending = notificationService.ScheduleNotification(notification);
pending.Reschedule = true; // 포그라운드 전환 후 재예약 허용
```

### 알림 취소 및 닫기

```csharp
// 특정 알림 취소
notificationService.CancelNotification(notificationId);

// 특정 표시 알림 닫기
notificationService.DismissNotification(notificationId);

// 모든 알림 취소/닫기
notificationService.CancelAllScheduledNotifications();
notificationService.DismissAllDisplayedNotifications();
```

### 커스텀 채널 설정

```csharp
var urgentChannel = new GameNotificationChannel(
    "urgent",
    "긴급 알림",
    "방해 금지를 우회하는 긴급 알림",
    GameNotificationChannel.NotificationStyle.Popup,
    showsBadge: true,
    showLights: true,
    vibrates: true,
    highPriority: true,
    privacy: GameNotificationChannel.PrivacyMode.Public
);
```

## 아키텍처

```
INotificationService (인터페이스)
  +-- MobileNotificationService (구현)
        +-- GameNotificationsMonoBehaviour (MonoBehaviour, 내부)
              +-- IGameNotificationsPlatform (내부 플랫폼 인터페이스)
                    +-- AndroidNotificationsPlatform (Android)
                    +-- iOSNotificationsPlatform (iOS)
                    +-- EditorGameNotification (에디터)
```

## 주의사항

- Android에서는 최소 하나의 `GameNotificationChannel` 등록이 필수
- iOS에서 `Channel`은 `CategoryIdentifier`에 매핑됨
- `Subtitle`은 Android에서 지원되지 않음 (무시됨)
- `ShouldAutoCancel`은 Android에서만 동작
- `SmallIcon`/`LargeIcon`은 iOS에서 지원되지 않음
- `MobileNotificationService` 생성 시 `DontDestroyOnLoad`가 자동 적용됨
- 에디터에서는 `EditorGameNotification`이 사용되며 실제 알림이 전송되지 않음
- 알림 상태는 `PlayerPrefs`에 JSON으로 저장됨

## 참조 문서

상세 API 문서는 `references/api.md` 참조.
