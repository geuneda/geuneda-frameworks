---
name: geuneda-notificationservice
description: Geuneda.NotificationService 네임스페이스(com.geuneda.notificationservice)로 Android/iOS 로컬 알림을 예약, 취소, 닫거나 Android 알림 채널과 OperatingMode(큐잉, 포그라운드 시 정리/재예약)를 다루는 코드를 작성하거나 수정할 때 사용한다. INotificationService, MobileNotificationService, IGameNotification, GameNotificationChannel, GameNotificationsMonoBehaviour 를 쓰는 코드라면 먼저 이 스킬을 확인한다.
---

# Geuneda Notification Service

Unity Mobile Notifications(`com.unity.mobile.notifications`)를 감싸 Android/iOS 로컬 알림을 하나의 API 로 다루는 패키지. 원격(푸시) 알림 수신과 알림 권한 요청은 포함하지 않는다.

- 네임스페이스/어셈블리: `Geuneda.NotificationService`
- 설치: `https://github.com/geuneda/geuneda-notificationservice.git` (고정하려면 `#<태그>`)
- 의존성: `com.unity.mobile.notifications` 1.3.0 (`package.json` 선언), Unity 2019.4 이상
- 전체 공개 API: [references/api.md](references/api.md)

## 핵심 API

```csharp
public interface INotificationService
{
    event Action<PendingNotification> OnLocalNotificationDeliveredEvent; // 포그라운드에서 대기 목록의 알림이 전달될 때
    event Action<PendingNotification> OnLocalNotificationExpiredEvent;   // Queue 모드에서 큐 알림이 시간을 지나 제거될 때
    IReadOnlyList<PendingNotification> PendingNotifications { get; }
    IGameNotification CreateNotification();
    PendingNotification ScheduleNotification(IGameNotification gameNotification);
    void CancelNotification(int notificationId);
    void DismissNotification(int notificationId);
    void CancelAllScheduledNotifications();
    void DismissAllDisplayedNotifications();
}

public class MobileNotificationService : INotificationService
{
    public MobileNotificationService(params GameNotificationChannel[] channels);                     // Mode = NoQueue
    public MobileNotificationService(OperatingMode mode, params GameNotificationChannel[] channels);
}
```

- `IGameNotification`: `int? Id`, `string Title`, `Body`, `Subtitle`, `Channel`, `int? BadgeNumber`, `bool ShouldAutoCancel`, `DateTime? DeliveryTime`, `string SmallIcon`, `LargeIcon`, 읽기 전용 `bool Scheduled`
- `PendingNotification`: `public readonly IGameNotification Notification`, `public bool Reschedule` (둘 다 필드)
- `GameNotificationChannel` (`readonly struct`): `(id, name, description)` 또는 `(id, name, description, NotificationStyle style, bool showsBadge = true, bool showLights = false, bool vibrates = true, bool highPriority = false, PrivacyMode privacy = PrivacyMode.Public, long[] vibrationPattern = null)`
- `OperatingMode` (`[Flags]`): `NoQueue`, `Queue`, `ClearOnForegrounding`, `RescheduleAfterClearing`, `QueueAndClear`, `QueueClearAndReschedule`
- `GameNotificationsMonoBehaviour`: 실제 관리자. `Mode`, `AutoBadging`, `OnLocalNotificationDelivered`, `OnLocalNotificationExpired` 필드와 `Initialize(params GameNotificationChannel[])` 를 가진다

## 사용 패턴

### 기본: 서비스로 예약/취소

```csharp
using System;
using Geuneda.NotificationService;

INotificationService notifications = new MobileNotificationService(
    new GameNotificationChannel("default", "기본 알림", "게임 일반 알림")); // 첫 채널이 Android 기본 채널

const int DailyRewardId = 1001;

var notification = notifications.CreateNotification();
if (notification != null) // Android/iOS 외 플랫폼이면 null
{
    notification.Id = DailyRewardId;          // 취소하려면 ID 를 직접 지정
    notification.Title = "보상 준비 완료";
    notification.Body = "접속해서 보상을 받으세요.";
    notification.DeliveryTime = DateTime.Now.AddHours(4);
    notifications.ScheduleNotification(notification);
}

notifications.CancelNotification(DailyRewardId);        // 예약 취소
notifications.DismissAllDisplayedNotifications();       // 표시된 알림 모두 닫기
```

Geuneda.Services 를 함께 쓰는 프로젝트라면 생성한 인스턴스를 `MainInstaller.Bind<INotificationService>(notifications);` 로 등록하고 `MainInstaller.Resolve<INotificationService>()` 로 가져온다. `MobileNotificationService` 는 생성할 때마다 `DontDestroyOnLoad` GameObject 를 새로 만들므로 한 번만 생성한다.

### OperatingMode 와 이벤트

```csharp
INotificationService notifications = new MobileNotificationService(
    OperatingMode.QueueClearAndReschedule,                                   // 모드는 생성할 때만 정할 수 있다
    new GameNotificationChannel("default", "기본 알림", "게임 일반 알림"));
notifications.OnLocalNotificationDeliveredEvent += pending => Debug.Log(pending.Notification.Title);
notifications.OnLocalNotificationExpiredEvent += pending => Debug.Log($"만료: {pending.Notification.Id}");

var pending = notifications.ScheduleNotification(notification); // notification 은 CreateNotification() 으로 만든 알림
pending.Reschedule = true;              // RescheduleAfterClearing 모드에서 포그라운드 복귀 후 재예약
```

### GameNotificationsMonoBehaviour 직접 사용

`AutoBadging` 은 `MobileNotificationService.AutoBadging` 프로퍼티로 바꾼다(v0.1.9). 에디터에서도 플랫폼 구현을 쓰려면 MonoBehaviour 를 직접 만든다.

```csharp
using System;
using Geuneda.NotificationService;
using UnityEngine;

var manager = new GameObject("Notifications").AddComponent<GameNotificationsMonoBehaviour>();
manager.Mode = OperatingMode.QueueClearAndReschedule;   // Initialize 전에 설정
manager.OnLocalNotificationDelivered = pending => Debug.Log(pending.Notification.Title);
manager.OnLocalNotificationExpired = pending => Debug.Log($"만료: {pending.Notification.Id}");
manager.Initialize(new GameNotificationChannel("default", "기본 알림", "게임 일반 알림"));
UnityEngine.Object.DontDestroyOnLoad(manager.gameObject);

var n = manager.CreateNotification();   // 에디터에서도 플랫폼 구현을 쓴다. 빌드 타깃이 Android/iOS 가 아니면 null
if (n != null)
{
    n.Title = "에너지 충전 완료";
    n.Body = "다시 플레이하세요.";
    n.DeliveryTime = DateTime.Now.AddMinutes(30);
    var pending = manager.ScheduleNotification(n);
    pending.Reschedule = true;          // RescheduleAfterClearing 모드에서 포그라운드 복귀 후 재예약
}
```

이 경우 `INotificationService` 가 아니므로 메서드 이름이 다르다: `CancelAllNotifications()`, `DismissAllNotifications()`. `Initialize` 전에 다른 메서드를 부르거나 `Initialize` 를 두 번 부르면 `InvalidOperationException`.

### 커스텀 채널

```csharp
var urgent = new GameNotificationChannel(
    "urgent", "긴급 알림", "방해 금지를 우회하는 알림",
    GameNotificationChannel.NotificationStyle.Popup,
    highPriority: true,
    privacy: GameNotificationChannel.PrivacyMode.Private);

// 채널은 서비스(또는 Initialize) 생성 시에만 등록된다
INotificationService notifications = new MobileNotificationService(
    new GameNotificationChannel("default", "기본 알림", "게임 일반 알림"), urgent);

var notification = notifications.CreateNotification();
notification.Channel = "urgent"; // Android: 채널 ID, iOS: CategoryIdentifier
```

## 함정

- `MobileNotificationService` 의 `Mode` 는 생성자에서만 정한다. 인자 없는 채널 생성자는 `NoQueue` 이고, 이 상태에서 `PendingNotification.Reschedule` 은 의미가 없다.
- 에디터에서 `MobileNotificationService.CreateNotification()` 은 internal `EditorGameNotification` 을 반환하고, `ScheduleNotification` 은 실제로 예약하지 않으며 `PendingNotifications` 에도 추가하지 않는다(ID 만 생성). 그래서 에디터에서는 전달/만료 이벤트도 발생하지 않는다.
- `MobileNotificationService.ScheduleNotification(null)` 은 `ArgumentNullException`. `GameNotificationsMonoBehaviour.ScheduleNotification(null)` 은 `null` 을 반환한다.
- Android 는 채널이 최소 하나 필요하다. 첫 번째 채널이 `Channel` 미지정 알림의 기본 채널이 된다. iOS 에서 채널 등록은 아무 동작도 하지 않는다.
- Android: `DeliveryTime = null` 은 `ArgumentNullException`, `Subtitle` 은 무시된다. ID 미지정 시 예약하면서 OS 발급 ID 가 채워진다.
- iOS: `Id = null` 은 `ArgumentNullException`, 내부 식별자가 숫자가 아니면 `Id` 는 경고 로그와 함께 `null`. `SmallIcon`/`LargeIcon` 은 무시, `ShouldAutoCancel` 은 효과 없음, 포그라운드 전환 시 앱 배지를 0 으로 초기화한다.
- `AndroidGameNotification`/`iOSGameNotification` 은 각각 `#if UNITY_ANDROID`/`#if UNITY_IOS` 안에서만 존재한다. 직접 참조하면 같은 지시문으로 감싼다.
- 알림 권한(iOS, Android 13 이상) 요청은 이 패키지가 하지 않는다. Unity Mobile Notifications API 로 직접 요청한다.
- 백그라운드 전환 시 `PlayerPrefs` 키 `notifications` 에 상태를 저장하고 포그라운드 복귀 시 읽는다. 같은 키를 쓰지 않는다. `SmallIcon`/`LargeIcon`/`ShouldAutoCancel` 도 저장된다. 예약을 지우지 않는 모드에서 복원한 알림은 다시 예약하지 않고 `Scheduled` 상태로 되살린다(다음 백그라운드 전환 때 다시 저장된다). 0.1.7 이하가 저장한 값은 빈 상태로 읽힌다.
