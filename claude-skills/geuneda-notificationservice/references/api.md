# Geuneda NotificationService API 레퍼런스

네임스페이스와 어셈블리: `Geuneda.NotificationService`. 모든 공개 타입은 `Runtime/` 아래에 있다. 사용 패턴과 함정은 [../SKILL.md](../SKILL.md) 참고.

---

## INotificationService (interface)

`Runtime/MobileNotificationService.cs`

| 멤버 | 설명 |
|------|------|
| `event Action<PendingNotification> OnLocalNotificationDeliveredEvent` | 앱이 포그라운드일 때 대기 목록에 있는 로컬 알림이 전달되면 발생 |
| `event Action<PendingNotification> OnLocalNotificationExpiredEvent` | 큐에 있던 알림이 표시 시점에 앱이 포그라운드여서 제거될 때 발생(`Queue` 모드) |
| `event Action<bool> OnEnabledChanged` | 앱 안 알림 설정(`IsEnabled`)이 바뀔 때 바뀐 값으로 발생. 켜졌을 때 다시 예약하는 데 쓴다 |
| `IReadOnlyList<PendingNotification> PendingNotifications { get; }` | 예약되었거나 큐에 있는 알림 |
| `bool IsEnabled { get; set; }` | 앱 안 알림 설정(기본값 `true`, `PlayerPrefs` 키 `geuneda.notificationservice.enabled`). `false` 로 바꾸면 예약 취소, 표시 알림 닫기, 저장 목록 삭제 후 이후 예약은 `null`. 같은 값이면 아무것도 안 함 |
| `NotificationPermission Permission { get; }` | 현재 OS 알림 권한. `RequestPermission` 요청에 아직 응답이 없으면 `Pending`. 에디터에서는 항상 `Granted`. 권한이 없어도 예약은 막지 않지만 iOS 는 그 예약을 OS 가 버린다 |
| `void RequestPermission(Action<NotificationPermission> onCompleted)` | OS 알림 권한 요청. 이미 결정되었으면 바로, 아니면 응답 후 콜백. 진행 중이면 그 결과를 함께 받음. 에디터에서는 바로 `Granted`. `onCompleted` 가 `null` 이면 `ArgumentNullException` |
| `IGameNotification CreateNotification()` | 현재 플랫폼용 알림 객체 생성 |
| `PendingNotification ScheduleNotification(IGameNotification gameNotification)` | 알림 예약. `Id` 가 없으면 자동 ID 부여. `IsEnabled` 가 꺼져 있으면 `null` |
| `void CancelNotification(int notificationId)` | 예약된 알림 취소 |
| `void DismissNotification(int notificationId)` | 표시된 알림 닫기 |
| `void CancelAllScheduledNotifications()` | 모든 예약 알림 취소 |
| `void DismissAllDisplayedNotifications()` | 모든 표시 알림 닫기 |

## MobileNotificationService : INotificationService (class)

```csharp
public MobileNotificationService(params GameNotificationChannel[] channels)   // Mode = NoQueue
public MobileNotificationService(OperatingMode mode, params GameNotificationChannel[] channels)
```

- `"NotificationService"` GameObject 에 `GameNotificationsMonoBehaviour` 를 붙이고 `Mode` 를 설정한 뒤 `Initialize(channels)` 를 호출하고 `DontDestroyOnLoad` 를 적용한다.
- 내부 MonoBehaviour 를 노출하지 않으므로 `Mode` 는 생성할 때만 정한다. `AutoBadging` 은 `public bool AutoBadging { get; set; }` 프로퍼티로 내부 값을 읽고 쓴다(기본값 `true`, v0.1.9).
- 이벤트: MonoBehaviour 의 `OnLocalNotificationDelivered` / `OnLocalNotificationExpired` 가 호출될 때 그 시점의 구독자에게 전달한다.
- `CreateNotification()`: 에디터(`UNITY_EDITOR`)에서는 `EditorGameNotification`, 그 외에는 `GameNotificationsMonoBehaviour.CreateNotification()` 결과(지원하지 않는 플랫폼이면 `null`).
- `ScheduleNotification(...)`: `null` 이면 `ArgumentNullException`. 에디터에서는 `IsEnabled` 가 꺼져 있으면 `null`, 아니면 `Id` 가 없을 때 자동 ID 를 부여하고 `new PendingNotification(gameNotification)` 만 반환한다(예약하지 않고 `PendingNotifications` 에도 추가하지 않음). 그 외에는 MonoBehaviour 에 위임.
- `IsEnabled` 는 MonoBehaviour 의 `NotificationsEnabled`/`SetNotificationsEnabled` 에, `Permission`/`RequestPermission` 은 에디터가 아니면 MonoBehaviour 에 위임한다. `OnEnabledChanged` 는 MonoBehaviour 의 `OnNotificationsEnabledChanged` 가 호출될 때 그 시점의 구독자에게 전달한다.
- `CancelNotification` / `DismissNotification` 은 같은 이름의 MonoBehaviour 메서드에, `CancelAllScheduledNotifications` 는 `CancelAllNotifications` 에, `DismissAllDisplayedNotifications` 는 `DismissAllNotifications` 에 위임한다.

---

## IGameNotification (interface)

`Runtime/IGameNotification.cs`

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `Id` | `int?` (get/set) | 고유 식별자 |
| `Title` | `string` (get/set) | 제목 |
| `Body` | `string` (get/set) | 본문 |
| `Subtitle` | `string` (get/set) | 부제목. Android 에서는 무시 |
| `Channel` | `string` (get/set) | Android: 채널 ID, iOS: `CategoryIdentifier` |
| `BadgeNumber` | `int?` (get/set) | 배지 번호. `null` 이면 표시하지 않음 |
| `ShouldAutoCancel` | `bool` (get/set) | 탭하면 자동으로 닫힘. Android 에서만 동작 |
| `DeliveryTime` | `DateTime?` (get/set) | 로컬 시간 기준 전달 시간 |
| `Scheduled` | `bool` (get) | OS 에 예약되었는지 여부 |
| `SmallIcon` | `string` (get/set) | 소형 아이콘. iOS 에서는 무시 |
| `LargeIcon` | `string` (get/set) | 대형 아이콘. iOS 에서는 무시 |

## PendingNotification (class)

`Runtime/PendingNotification.cs`

| 멤버 | 설명 |
|------|------|
| `public bool Reschedule` (필드) | 포그라운드 복귀 후 재예약 여부. `Mode` 에 `ClearOnForegrounding` 과 `RescheduleAfterClearing` 이 모두 있을 때만 유효. 시간 기반이 아닌 전달에는 동작하지 않음 |
| `public readonly IGameNotification Notification` (필드) | 예약된 알림 |
| `PendingNotification(IGameNotification notification)` | `notification` 이 `null` 이면 `ArgumentNullException` |

---

## GameNotificationsMonoBehaviour : MonoBehaviour (sealed class)

`Runtime/GameNotificationsMonoBehaviour.cs`

| 멤버 | 설명 |
|------|------|
| `public OperatingMode Mode` | 동작 모드. 기본값 `NoQueue` |
| `public bool AutoBadging` | `Queue` 모드에서 배지 번호가 하나도 설정되지 않았으면 전달 시간순으로 1부터 자동 부여. 기본값 `true` |
| `public Action<PendingNotification> OnLocalNotificationDelivered` | 앱이 포그라운드일 때 대기 목록에 있는 알림이 전달되면 호출 |
| `public Action<PendingNotification> OnLocalNotificationExpired` | `Queue` 모드에서 전달 시간이 지난 큐 알림을 제거할 때 호출 |
| `List<PendingNotification> PendingNotifications { get; }` | 예약/큐 알림 목록 |
| `bool Initialized { get; }` | 초기화 여부 |
| `void Initialize(params GameNotificationChannel[] channels)` | 플랫폼 구현 생성, Android 채널 등록(첫 채널이 기본 채널). 두 번 호출하면 `InvalidOperationException` |
| `IGameNotification CreateNotification()` | 플랫폼용 알림 생성. 플랫폼이 없으면 `null` |
| `PendingNotification ScheduleNotification(IGameNotification notification)` | `notification` 이 `null` 이거나 앱 안 알림 설정이 꺼져 있으면 `null` 반환. `Id` 가 없으면 자동 ID(1,000,000 부터, `PlayerPrefs` 키 `geuneda.notificationservice.lastId` 로 실행 간 이어짐, 대기 목록의 ID 는 건너뜀) 부여. `Queue` 모드이고 `DeliveryTime` 이 있으면 백그라운드 전환 때까지 큐에 보관, 아니면 즉시 예약. 결과를 `PendingNotifications` 에 추가 |
| `public Action<bool> OnNotificationsEnabledChanged` | 앱 안 알림 설정이 바뀔 때 호출 |
| `bool NotificationsEnabled { get; }` / `void SetNotificationsEnabled(bool enabled)` | 앱 안 알림 설정 읽기/바꾸기. 끄면 예약 취소, 표시 알림 닫기, 목록과 저장값 삭제 |
| `NotificationPermission Permission { get; }` | 진행 중인 권한 요청이 있으면 `Pending`, 아니면 플랫폼의 OS 알림 권한. 플랫폼이 없으면 `Granted` |
| `internal void InitializeWithPlatform(IGameNotificationsPlatform platform)` | 플랫폼 구현을 받아 초기화(`Initialize` 가 플랫폼을 만든 뒤 호출). 테스트에서 가짜 플랫폼을 넣는 데 쓴다 |
| `void RequestPermission(Action<NotificationPermission> onCompleted)` | OS 권한 요청. 요청 상태는 `Update` 에서 매 프레임 확인하고 끝나면 기다리던 콜백 모두에 알림(콜백 예외는 로그). 플랫폼이 없으면 바로 `Granted` |
| `void CancelNotification(int notificationId)` | 예약 취소 후 목록에서 제거 |
| `void CancelAllNotifications()` | 모든 예약 취소 후 목록 비움 |
| `void DismissNotification(int notificationId)` | 표시된 알림 닫기 |
| `void DismissAllNotifications()` | 모든 표시 알림 닫기 |

- `Initialize` 외의 메서드는 초기화 전에 호출하면 `InvalidOperationException`.
- 플랫폼 구현은 `UNITY_ANDROID` 면 Android, `UNITY_IOS` 면 iOS 이며, 둘 다 아니면 없다(에디터에서도 빌드 타깃 기준).
- 포그라운드 전환(`OnApplicationPause(false)`, `Initialize` 시 포함): 목록을 비운다. 앱 안 알림 설정이 꺼져 있으면 OS 예약을 모두 취소하고 끝낸다. 켜져 있으면 `PlayerPrefs` 키 `notifications` 에서 저장된 알림을 읽는다. `ClearOnForegrounding` 이면 예약을 모두 취소하고, `RescheduleAfterClearing` 이면 미래 알림을 `Reschedule = true` 로 다시 예약한다. 그렇지 않으면 미래 알림을 다시 예약하지 않고 `Scheduled` 상태로 목록에 복원한다(OS 예약이 남아 있으므로).
- 포커스가 아니라 일시 정지 기준이라 결제창·광고로 포커스만 잃은 경우는 전환으로 보지 않는다. 상태가 바뀌지 않은 호출(시작 직후 `OnApplicationPause(false)` 등)은 무시한다(Unreleased).
- 백그라운드 전환(`OnApplicationPause(true)`): `Queue` 모드면 아직 예약되지 않은 알림 중 전달 시간이 2초 이내이거나 지난 것을 버리고(필요하면 배지 자동 부여) 나머지를 예약한다. 이어서 저장 대상(`ClearOnForegrounding` 이 없으면 예약된 모든 알림, `RescheduleAfterClearing` 까지 있으면 `Reschedule` 이고 예약되었으며 시간이 있는 알림)을 `PlayerPrefs` 키 `notifications` 에 쓴다.

## OperatingMode (`[Flags]` enum)

`Runtime/GameNotificationsMonoBehaviour.cs`

| 값 | 설명 |
|----|------|
| `NoQueue = 0x00` | 모든 알림을 즉시 OS 에 예약 |
| `Queue = 0x01` | 백그라운드 전환 때까지 큐에 보관, 배지 자동 부여 |
| `ClearOnForegrounding = 0x02` | 포그라운드 전환 시 예약된 알림 모두 취소 |
| `RescheduleAfterClearing = 0x04` | 취소 후 `Reschedule` 로 표시된 미래 알림 재예약. `ClearOnForegrounding` 과 함께일 때만 유효 |
| `QueueAndClear` | `Queue` + `ClearOnForegrounding` |
| `QueueClearAndReschedule` | `Queue` + `ClearOnForegrounding` + `RescheduleAfterClearing` |

---

## GameNotificationChannel (readonly struct)

`Runtime/GameNotificationChannel.cs`. Android 알림 채널에 대응하며 iOS 에서는 아무 동작도 하지 않는다.

```csharp
// Style = Popup, ShowsBadge = true, ShowLights = false, Vibrates = true,
// HighPriority = false, Privacy = Public, VibrationPattern = null
public GameNotificationChannel(string id, string name, string description)

public GameNotificationChannel(string id, string name, string description,
    NotificationStyle style, bool showsBadge = true, bool showLights = false,
    bool vibrates = true, bool highPriority = false,
    PrivacyMode privacy = PrivacyMode.Public, long[] vibrationPattern = null)
```

| 필드 (`public readonly`) | 타입 | 설명 |
|--------------------------|------|------|
| `Id` | `string` | 채널 식별자 |
| `Name` | `string` | 사용자에게 표시되는 이름 |
| `Description` | `string` | 사용자에게 표시되는 설명 |
| `ShowsBadge` | `bool` | 배지 표시 |
| `ShowLights` | `bool` | 기기 조명 깜빡임 |
| `Vibrates` | `bool` | 진동 |
| `HighPriority` | `bool` | 방해 금지 우회 |
| `Style` | `NotificationStyle` | 표시 스타일(Android 중요도) |
| `Privacy` | `PrivacyMode` | 잠금 화면 표시 방식 |
| `VibrationPattern` | `int[]` | 진동 패턴. 생성자의 `long[]` 을 `int` 로 변환해 저장, `null` 이면 기본값 |

중첩 열거형:

| `NotificationStyle` | 설명 |
|---------------------|------|
| `None = 0` | 상태 표시줄에 나타나지 않음 |
| `NoSound = 2` | 소리 없음 |
| `Default = 3` | 소리 재생 |
| `Popup = 4` | 헤드업 팝업 표시 |

| `PrivacyMode` | 설명 |
|---------------|------|
| `Secret = -1` | 보안 잠금 화면에 표시하지 않음 |
| `Private = 0` | 아이콘만 표시, 보안 잠금 화면에서 내용 숨김 |
| `Public` (= 1) | 모든 잠금 화면에 표시 |

---

## 플랫폼별 구현 (public, 조건부 컴파일)

### AndroidGameNotification : IGameNotification

`Runtime/Android/AndroidGameNotification.cs`, `#if UNITY_ANDROID` 에서만 존재. `using Unity.Notifications.Android` 타입을 노출한다.

- `AndroidGameNotification()` 생성자
- `AndroidNotification InternalNotification { get; }`
- `string DeliveredChannel { get; set; }` - `Channel` 과 같은 값
- `Title`/`Body`/`SmallIcon`/`LargeIcon`/`ShouldAutoCancel` 은 `InternalNotification` 의 `Title`/`Text`/`SmallIcon`/`LargeIcon`/`ShouldAutoCancel` 에 매핑
- `BadgeNumber` 는 `InternalNotification.Number` 에 매핑(`-1` 이 `null`)
- `DeliveryTime` 은 `InternalNotification.FireTime` 에 매핑. `null` 을 넣으면 `ArgumentNullException`
- `Subtitle` 은 항상 `null`, 설정은 무시
- 서비스가 예약 전에 자동 ID 를 부여하므로 `AndroidNotificationCenter.SendNotificationWithExplicitID` 로 예약된다. 플랫폼 구현을 직접 써서 `Id` 없이 예약할 때만 `SendNotification` 이 반환한 ID 로 채워짐

### iOSGameNotification : IGameNotification

`Runtime/iOS/iOSGameNotification.cs`, `#if UNITY_IOS` 에서만 존재. `using Unity.Notifications.iOS` 타입을 노출한다.

- `iOSGameNotification()` 생성자 - 내부 알림을 `ShowInForeground = true` 로 생성
- `iOSNotification InternalNotification { get; }`
- `string CategoryIdentifier { get; set; }` - `Channel` 과 같은 값
- `Id` 는 내부 `Identifier` 문자열에 저장. 새 알림은 식별자 없이 만들어 `Id` 가 `null` 이고(서비스가 예약할 때 자동 ID 부여, Unreleased), 정수로 파싱할 수 없으면 경고 로그와 함께 `null`, `null` 을 넣으면 `ArgumentNullException`
- `BadgeNumber` 는 `InternalNotification.Badge` 에 매핑(`-1` 이 `null`)
- `DeliveryTime` 은 `iOSNotificationCalendarTrigger` 로 저장(밀리초 무시). 다른 트리거면 `null` 반환, `null` 설정은 무시
- `SmallIcon`/`LargeIcon` 은 항상 `null`, 설정은 무시. `ShouldAutoCancel` 은 값만 보관

---

## internal 타입 (참고용, 직접 사용 불가)

- `IGameNotificationsPlatform` / `IGameNotificationsPlatform<TNotificationType>` - 플랫폼 추상화(`NotificationReceived` 이벤트, 생성/예약/취소/닫기, `OnForeground`, `OnBackground`)
- `AndroidNotificationsPlatform`, `iOSNotificationsPlatform` - 위 인터페이스의 구현. iOS 는 `OnForeground` 에서 `iOSNotificationCenter.ApplicationBadge = 0`
- `EditorGameNotification` - 에디터용 `IGameNotification`. 모든 값이 자동 프로퍼티이며 `Scheduled` 는 항상 `false`
- `SerializableNotification` / `SerializableNotificationConverter` - `PlayerPrefs` 저장용 구조체(`Id`, `Title`, `Body`, `Subtitle`, `Channel`, `BadgeNumber`, `DeliveryTime`, `SmallIcon`, `LargeIcon`, `ShouldAutoCancel`)와 변환 메서드. 백그라운드 전환 때 `SetString` 후 바로 `PlayerPrefs.Save()` 한다. `ToJson`/`FromJson` 은 `JsonUtility` 가 다룰 수 있는 `SerializableNotificationCollection`/`SerializableNotificationData`(nullable 값은 `Has*` 플래그, 시간은 `DateTime.ToBinary`)로 변환하며, 비었거나 읽을 수 없는 값은 빈 목록으로 읽는다
