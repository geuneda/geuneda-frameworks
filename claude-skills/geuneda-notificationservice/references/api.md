# Geuneda NotificationService API Reference

## 네임스페이스: Geuneda.NotificationService

---

## Public 인터페이스

### INotificationService

알림 서비스의 주요 인터페이스.

**이벤트:**
- `event Action<PendingNotification> OnLocalNotificationDeliveredEvent` - 포그라운드에서 로컬 알림 전달 시
- `event Action<PendingNotification> OnLocalNotificationExpiredEvent` - 큐에 있는 알림이 만료되어 취소될 때

**프로퍼티:**
- `IReadOnlyList<PendingNotification> PendingNotifications { get; }` - 예약/큐 알림 목록

**메서드:**
- `IGameNotification CreateNotification()` - 플랫폼에 적합한 알림 객체 생성
- `PendingNotification ScheduleNotification(IGameNotification gameNotification)` - 알림 예약
- `void CancelNotification(int notificationId)` - 예약된 알림 취소
- `void DismissNotification(int notificationId)` - 표시된 알림 닫기
- `void CancelAllScheduledNotifications()` - 모든 예약 알림 취소
- `void DismissAllDisplayedNotifications()` - 모든 표시 알림 닫기

---

### IGameNotification

알림 데이터를 나타내는 인터페이스.

**프로퍼티:**
| 이름 | 타입 | 설명 |
|------|------|------|
| `Id` | `int?` | 고유 식별자. null이면 예약 시 자동 생성 |
| `Title` | `string` | 알림 제목 |
| `Body` | `string` | 알림 본문 텍스트 |
| `Subtitle` | `string` | 부제목 (iOS 전용) |
| `Channel` | `string` | 채널 식별자 (Android: 채널 ID, iOS: CategoryIdentifier) |
| `BadgeNumber` | `int?` | 배지 번호. null이면 미표시 |
| `ShouldAutoCancel` | `bool` | 탭 시 자동 닫힘 (Android 전용) |
| `DeliveryTime` | `DateTime?` | 로컬 시간 기준 전달 시간 |
| `Scheduled` | `bool` | OS에 예약 완료 여부 (읽기 전용) |
| `SmallIcon` | `string` | 소형 아이콘 (Android 전용) |
| `LargeIcon` | `string` | 대형 아이콘 (Android 전용) |

---

## Public 클래스

### MobileNotificationService : INotificationService

`INotificationService`의 구체 구현. 내부에서 `GameNotificationsMonoBehaviour`를 생성하고 관리합니다.

**생성자:**
```csharp
public MobileNotificationService(params GameNotificationChannel[] channels)
```
- `channels` - 등록할 알림 채널 목록 (Android 필수)
- 내부적으로 `DontDestroyOnLoad` GameObject 생성

**메서드:**
- `IGameNotification CreateNotification()` - 에디터에서는 `EditorGameNotification`, 런타임에서는 플랫폼별 알림 반환
- `PendingNotification ScheduleNotification(IGameNotification gameNotification)` - 에디터에서는 ID 자동 생성 후 `PendingNotification` 반환
- `void CancelNotification(int notificationId)` - 내부 MonoBehaviour에 위임
- `void DismissNotification(int notificationId)` - 내부 MonoBehaviour에 위임
- `void CancelAllScheduledNotifications()` - 내부 MonoBehaviour에 위임
- `void DismissAllDisplayedNotifications()` - 내부 MonoBehaviour에 위임

---

### PendingNotification

예약된 알림의 래퍼 클래스.

**필드:**
- `bool Reschedule` - 포그라운드 전환 시 재예약 여부 (`RescheduleAfterClearing` 모드에서만 유효)

**프로퍼티:**
- `IGameNotification Notification { get; }` (readonly) - 원본 알림 데이터

**생성자:**
```csharp
public PendingNotification(IGameNotification notification)
```
- `notification`이 null이면 `ArgumentNullException` 발생

---

### GameNotificationsMonoBehaviour : MonoBehaviour

알림 관리 핵심 MonoBehaviour. 직접 사용하지 않으며 `MobileNotificationService`가 내부적으로 관리합니다.

**Public 필드:**
- `OperatingMode Mode` - 동작 모드 (기본값: `NoQueue`)
- `bool AutoBadging` - 배지 자동 증가 (기본값: `true`)
- `Action<PendingNotification> OnLocalNotificationDelivered` - 포그라운드 알림 전달 이벤트
- `Action<PendingNotification> OnLocalNotificationExpired` - 큐 알림 만료 이벤트

**프로퍼티:**
- `List<PendingNotification> PendingNotifications { get; }` - 대기 알림 목록
- `bool Initialized { get; }` - 초기화 상태

**메서드:**
- `void Initialize(params GameNotificationChannel[] channels)` - 초기화 (중복 호출 시 `InvalidOperationException`)
- `IGameNotification CreateNotification()` - 플랫폼별 알림 생성 (미초기화 시 `InvalidOperationException`)
- `PendingNotification ScheduleNotification(IGameNotification notification)` - 알림 예약
- `void CancelNotification(int notificationId)` - 알림 취소
- `void CancelAllNotifications()` - 모든 알림 취소
- `void DismissNotification(int notificationId)` - 표시 알림 닫기
- `void DismissAllNotifications()` - 모든 표시 알림 닫기

---

## Public 구조체

### GameNotificationChannel (readonly struct)

Android 알림 채널의 크로스 플랫폼 래퍼.

**필드:**
| 이름 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `Id` | `string` | - | 채널 고유 식별자 |
| `Name` | `string` | - | 사용자에게 표시되는 이름 |
| `Description` | `string` | - | 사용자에게 표시되는 설명 |
| `ShowsBadge` | `bool` | `true` | 배지 표시 여부 |
| `ShowLights` | `bool` | `false` | LED 깜빡임 여부 |
| `Vibrates` | `bool` | `true` | 진동 여부 |
| `HighPriority` | `bool` | `false` | 방해 금지 우회 여부 |
| `Style` | `NotificationStyle` | `Popup` | 알림 스타일 |
| `Privacy` | `PrivacyMode` | `Public` | 잠금 화면 표시 모드 |
| `VibrationPattern` | `int[]` | `null` | 사용자 정의 진동 패턴 |

**생성자:**
```csharp
// 기본 설정
public GameNotificationChannel(string id, string name, string description)

// 전체 설정
public GameNotificationChannel(string id, string name, string description,
    NotificationStyle style, bool showsBadge = true, bool showLights = false,
    bool vibrates = true, bool highPriority = false,
    PrivacyMode privacy = PrivacyMode.Public, long[] vibrationPattern = null)
```

**중첩 열거형:**

`NotificationStyle`:
| 값 | 설명 |
|----|------|
| `None = 0` | 상태 표시줄에 미표시 |
| `NoSound = 2` | 소리 없음 |
| `Default = 3` | 소리 재생 |
| `Popup = 4` | 헤드업 팝업 포함 |

`PrivacyMode`:
| 값 | 설명 |
|----|------|
| `Secret = -1` | 보안 잠금 화면에서 미표시 |
| `Private = 0` | 아이콘만 표시, 내용 숨김 |
| `Public = 1` | 모든 잠금 화면에 표시 |

---

## Public 열거형

### OperatingMode (Flags)

알림 관리자의 동작 모드.

| 값 | 설명 |
|----|------|
| `NoQueue = 0x00` | 큐잉 없이 즉시 OS에 예약 |
| `Queue = 0x01` | 백그라운드 전환 시까지 큐에 보관, 배지 번호 자동 증가 |
| `ClearOnForegrounding = 0x02` | 포그라운드 전환 시 모든 대기 알림 지우기 |
| `RescheduleAfterClearing = 0x04` | 지운 후 `Reschedule=true`인 미래 알림 재예약 |
| `QueueAndClear = 0x03` | Queue + ClearOnForegrounding |
| `QueueClearAndReschedule = 0x07` | Queue + ClearOnForegrounding + RescheduleAfterClearing |

---

## 플랫폼별 구현 (Public)

### AndroidGameNotification : IGameNotification

Android 전용 알림 구현.

**추가 프로퍼티:**
- `AndroidNotification InternalNotification { get; }` - 내부 Android 알림 객체
- `string DeliveredChannel { get; set; }` - 알림 채널

**참고:**
- `Subtitle` 미지원 (항상 null 반환)
- `Id`가 없으면 예약 시 자동 생성
- `DeliveryTime`은 `AndroidNotification.FireTime`에 매핑

### iOSGameNotification : IGameNotification

iOS 전용 알림 구현.

**추가 프로퍼티:**
- `iOSNotification InternalNotification { get; }` - 내부 iOS 알림 객체
- `string CategoryIdentifier { get; set; }` - 카테고리 식별자

**참고:**
- `Id`는 내부적으로 문자열로 저장, int 파싱
- `Channel`은 `CategoryIdentifier`에 매핑
- `DeliveryTime`은 `iOSNotificationCalendarTrigger`를 사용
- `SmallIcon`/`LargeIcon` 미지원 (항상 null 반환)
- 기본적으로 `ShowInForeground = true`

---

## Internal 타입 (참고용)

### IGameNotificationsPlatform (internal interface)

플랫폼별 알림 처리 인터페이스.

- `event Action<IGameNotification> NotificationReceived`
- `IGameNotification CreateNotification()`
- `void ScheduleNotification(IGameNotification gameNotification)`
- `void CancelNotification(int notificationId)`
- `void DismissNotification(int notificationId)`
- `void CancelAllScheduledNotifications()`
- `void DismissAllDisplayedNotifications()`
- `void OnForeground()`
- `void OnBackground()`

### SerializableNotification (internal struct)

디스크 직렬화용 알림 구조체. `PlayerPrefs`에 JSON으로 저장됩니다.

필드: `Id`, `Title`, `Body`, `Subtitle`, `Channel`, `BadgeNumber`, `DeliveryTime`

### EditorGameNotification (internal class)

에디터 전용 `IGameNotification` 구현. 모든 프로퍼티를 단순 자동 프로퍼티로 구현하며 `Scheduled`는 항상 `false`.
