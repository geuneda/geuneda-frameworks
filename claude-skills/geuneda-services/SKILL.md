---
name: geuneda-services
description: Unity 게임 아키텍처를 위한 핵심 서비스 패키지. DI 컨테이너(MainInstaller), 메시지 브로커(Pub/Sub), 틱 서비스(업데이트 관리), 코루틴 서비스, 오브젝트 풀링, 데이터 영속성, 시간 관리, 결정론적 RNG, 커맨드 패턴, 버전 관리 관련 코드를 작성하거나 수정할 때 사용한다.
---

# Geuneda Services

Unity 게임 아키텍처를 위한 핵심 서비스 패키지이다. DI 컨테이너, 메시지 브로커, 틱/코루틴 서비스, 오브젝트 풀링, 데이터 영속성, 시간 관리, 결정론적 RNG, 커맨드 패턴 등 게임 개발에 필요한 핵심 서비스를 제공한다.

## 활성화 시점

- DI 컨테이너를 통해 서비스를 등록/해석할 때 (MainInstaller, Installer)
- 타입 안전한 Pub/Sub 메시지 통신을 구현할 때 (MessageBrokerService)
- MonoBehaviour 없이 업데이트 사이클을 관리할 때 (TickService)
- MonoBehaviour 없이 코루틴을 실행할 때 (CoroutineService)
- 오브젝트 풀링 시스템을 구현할 때 (PoolService, ObjectPool)
- PlayerPrefs 기반 데이터 저장/로드를 구현할 때 (DataService)
- 시간 관리 및 변환을 구현할 때 (TimeService)
- 결정론적 난수 생성이 필요할 때 (RngService)
- 커맨드 패턴을 구현할 때 (CommandService)
- 빌드 버전/Git 메타데이터에 접근할 때 (VersionServices)

## 패키지 정보

- **네임스페이스**: `Geuneda.Services`
- **설치**: `https://github.com/geuneda/geuneda-services.git`
- **의존성**: `com.geuneda.gamedata` >= 1.0.0
- **최소 Unity 버전**: 6000.0

## 아키텍처 개요

```
MainInstaller (정적 서비스 로케이터)
    |
    +-- IMessageBrokerService (Pub/Sub 통신)
    +-- ITickService (업데이트 관리)
    +-- ICoroutineService (코루틴 호스트)
    +-- IPoolService (오브젝트 풀링)
    +-- IDataService (데이터 영속성)
    +-- ITimeService (시간 관리)
    +-- IRngService (결정론적 RNG)
    +-- ICommandService<T> (커맨드 패턴)
```

## 핵심 API 요약

### MainInstaller (정적 DI 컨테이너)
- `Bind<T>(T instance)` - 인터페이스 바인딩 (인터페이스만 가능)
- `Resolve<T>()` - 서비스 해석
- `TryResolve<T>(out T instance)` - 안전한 해석
- `Clean<T>()` / `CleanDispose<T>()` / `Clean()` - 바인딩 제거

### IMessageBrokerService (Pub/Sub)
- `Publish<T>(T message)` - 메시지 발행
- `PublishSafe<T>(T message)` - 안전한 발행 (체인 구독 허용)
- `Subscribe<T>(Action<T> action)` - 구독 (정적 메서드 불가)
- `Unsubscribe<T>(object subscriber)` - 구독 해제
- `UnsubscribeAll(object subscriber)` - 전체 구독 해제

### ITickService (업데이트 관리, IDisposable)
- `SubscribeOnUpdate(Action<float>, float deltaTime, bool timeOverflow, bool realTime)` - Update 구독
- `SubscribeOnLateUpdate(...)` - LateUpdate 구독
- `SubscribeOnFixedUpdate(Action<float>)` - FixedUpdate 구독
- `Unsubscribe(Action<float>)` - 전체 구독 해제
- `UnsubscribeAll()` / `UnsubscribeAll(object subscriber)` - 일괄 해제

### ICoroutineService (코루틴, IDisposable)
- `StartCoroutine(IEnumerator)` - 코루틴 시작
- `StartAsyncCoroutine(IEnumerator)` - IAsyncCoroutine 반환 (완료 콜백)
- `StartDelayCall(Action, float delay)` - 지연 호출
- `StopCoroutine(Coroutine)` / `StopAllCoroutines()` - 중지

### IPoolService (풀링, IDisposable)
- `AddPool<T>(IObjectPool<T>)` - 풀 추가
- `Spawn<T>()` / `Spawn<T, TData>(TData)` - 스폰
- `Despawn<T>(T entity)` / `DespawnAll<T>()` - 디스폰
- 풀 타입: `ObjectPool<T>`, `GameObjectPool`, `GameObjectPool<T>`

### IDataService (데이터 영속성)
- `AddOrReplaceData<T>(T data)` - 메모리에 추가/교체
- `SaveData<T>()` / `SaveAllData()` - PlayerPrefs + JSON 저장
- `LoadData<T>()` - 로드 (없으면 새 인스턴스 생성)
- `GetData<T>()` / `HasData<T>()` - 조회

### ITimeService / ITimeManipulator (시간)
- `DateTimeUtcNow` / `UnityTimeNow` / `UnixTimeNow` - 현재 시간
- 시간 변환: DateTime <-> Unix <-> UnityTime
- `AddTime(float)` / `SetInitialTime(DateTime)` - 시간 조작

### IRngService (결정론적 RNG)
- `Next` / `Nextfloat` - 다음 난수
- `Peek` / `Peekfloat` - 상태 변경 없이 조회
- `Range(int min, int max)` / `Range(floatP min, floatP max)` - 범위 지정
- `Restore(int count)` - 상태 복원
- `CreateRngData(int seed)` - 정적 팩토리

### ICommandService<TGameLogic> (커맨드 패턴)
- `ExecuteCommand<TCommand>(TCommand command)` - 커맨드 실행
- 커맨드는 `IGameCommand<TGameLogic>` 구현

## 사용 패턴

### 서비스 초기화 및 등록
```csharp
using Geuneda.Services;

// 서비스 생성 및 등록
MainInstaller.Bind<IMessageBrokerService>(new MessageBrokerService());
MainInstaller.Bind<ITickService>(new TickService());
MainInstaller.Bind<ICoroutineService>(new CoroutineService());
MainInstaller.Bind<IPoolService>(new PoolService());
MainInstaller.Bind<IDataService>(new DataService());
MainInstaller.Bind<ITimeService, ITimeManipulator>(new TimeService());

// 서비스 사용
var broker = MainInstaller.Resolve<IMessageBrokerService>();
```

### 메시지 기반 통신
```csharp
public struct PlayerDiedMessage : IMessage
{
    public int PlayerId;
}

// 구독
broker.Subscribe<PlayerDiedMessage>(msg => HandlePlayerDeath(msg.PlayerId));

// 발행
broker.Publish(new PlayerDiedMessage { PlayerId = 1 });

// 구독 해제
broker.Unsubscribe<PlayerDiedMessage>(this);
```

### 틱 서비스로 업데이트 관리
```csharp
var tickService = MainInstaller.Resolve<ITickService>();

// 매 프레임
tickService.SubscribeOnUpdate(deltaTime => MovePlayer(deltaTime));

// 0.5초마다
tickService.SubscribeOnUpdate(dt => CheckEnemy(dt), deltaTime: 0.5f);

// FixedUpdate
tickService.SubscribeOnFixedUpdate(dt => PhysicsStep(dt));
```

### 오브젝트 풀링
```csharp
var poolService = MainInstaller.Resolve<IPoolService>();

// GameObject 풀 생성
var bulletPool = new GameObjectPool<Bullet>(initSize: 50, bulletPrefab);
poolService.AddPool(bulletPool);

// 스폰/디스폰
var bullet = poolService.Spawn<Bullet>();
poolService.Despawn(bullet);
```

### 커맨드 패턴
```csharp
public struct AttackCommand : IGameCommand<GameLogic>
{
    public int TargetId;

    public void Execute(GameLogic logic, IMessageBrokerService broker)
    {
        logic.DealDamage(TargetId);
        broker.Publish(new DamageDealtMessage { TargetId = TargetId });
    }
}

var commandService = new CommandService<GameLogic>(gameLogic, broker);
commandService.ExecuteCommand(new AttackCommand { TargetId = 42 });
```

## 주의사항

- `MainInstaller`는 인터페이스만 바인딩 가능하다. 구체 클래스를 직접 바인딩하면 `ArgumentException`이 발생한다.
- `MessageBrokerService`는 정적 메서드 구독을 지원하지 않는다. `action.Target`이 null이면 예외가 발생한다.
- `Publish` 중 `Subscribe`/`Unsubscribe`를 호출하면 `InvalidOperationException`이 발생한다. 이 경우 `PublishSafe`를 사용한다.
- `TickService`와 `CoroutineService`는 DontDestroyOnLoad GameObject를 생성한다. 반드시 `Dispose()`로 정리해야 한다.
- `DataService`는 `PlayerPrefs` + `Newtonsoft.Json`을 사용한다. 참조 타입만 저장 가능하다.
- `RngService`는 `Geuneda.GameData`의 `floatP`(결정론적 부동소수점)를 사용한다.
- `VersionServices.LoadVersionDataAsync()`는 앱 시작 시 한 번 호출해야 한다. Resources 폴더에 `version-data` TextAsset이 필요하다.
- 풀 서비스의 `GameObjectPool`은 스폰 시 `SetActive(true)`, 디스폰 시 `SetActive(false)`를 자동 호출한다.

## 참조 문서

상세 API 문서는 `references/api.md` 참조.
