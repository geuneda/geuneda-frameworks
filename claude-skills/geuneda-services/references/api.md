# Geuneda Services - 공개 API 레퍼런스

`com.geuneda.services` 5.2.0 소스 기준. 런타임 로그는 core `ModuleLogger` 로 `[Geuneda.Services.<기능>]` 을 붙인다(Data, Version, AssetResolver, Tick, Time, Installer). 런타임 어셈블리 `Geuneda.Services`, 에디터 어셈블리 `Geuneda.Services.Editor`.

---

## Geuneda.Services — 서비스 로케이터

### interface IInstaller

| 멤버 | 반환 | 설명 |
|------|------|------|
| `Bind<T>(T instance) where T : class` | `IInstaller` | 인터페이스 `T` 에 바인딩. `T` 가 인터페이스가 아니거나 이미 바인딩되어 있으면 `ArgumentException` |
| `Bind<T, T1, T2>(T instance) where T : class, T1, T2` | `IInstaller` | `T1`, `T2` 에 각각 바인딩 (`T` 는 구현 타입) |
| `Bind<T, T1, T2, T3>(T instance) where T : class, T1, T2, T3` | `IInstaller` | `T1`, `T2`, `T3` 에 각각 바인딩 |
| `TryResolve<T>(out T instance)` | `bool` | 바인딩이 있으면 `true` |
| `Resolve<T>()` | `T` | 없으면 `ArgumentException` |
| `Clean<T>() where T : class` | `bool` | 해당 바인딩 제거 |
| `Clean()` | `void` | 전체 제거 |

### class Installer : IInstaller

`Dictionary<Type, object>` 기반 구현. 생성자 `Installer()`.

| 멤버 | 설명 |
|------|------|
| `event Action<Type> BindingChanged` | 바인딩 추가·제거 뒤 인터페이스 타입과 함께 발생(v5.1.0). `Bind<T,T1,T2>` 는 인터페이스마다, `Clean()` 은 모두 지운 뒤 타입마다. 예외로 실패한 인터페이스 바인딩, 지운 것 없는 `Clean<T>` 은 발생 안 함(다중 `Bind` 의 앞서 성공한 인터페이스는 남고 알림도 감). 처리기 예외는 `ModuleLogger`(`Geuneda.Services.Installer`) Error 후 계속. 스냅샷 순회. += / -= 는 할당 없음(해제는 같은 델리게이트 중 마지막 하나, 합성 델리게이트는 한 처리기) |

### static class MainInstaller

내부에 `Installer` 하나를 가진 전역 로케이터.

| 멤버 | 반환 | 설명 |
|------|------|------|
| `Bind<T>(T instance) where T : class` | `void` | 단일 인터페이스만. 다중 인터페이스 오버로드 없음 |
| `TryResolve<T>(out T instance)` | `bool` | |
| `Resolve<T>()` | `T` | 없으면 `ArgumentException` |
| `Clean<T>() where T : class` | `bool` | |
| `CleanDispose<T>() where T : class, IDisposable` | `bool` | 바인딩된 인스턴스의 `Dispose()` 호출 후 제거 |
| `Clean()` | `void` | 전체 제거 (`Dispose` 호출 안 함) |
| `event Action<Type> BindingChanged` | | `Installer.BindingChanged` 를 그대로 노출(정적). 플레이 세션 시작 때 처리기도 알림 없이 비움 |

---

## Geuneda.Services — 메시지 브로커

### interface IMessage

마커 인터페이스.

### interface IMessageBrokerService

| 멤버 | 설명 |
|------|------|
| `void Publish<T>(T message) where T : IMessage` | 구독자에게 직접 전달. 구독자가 없으면 아무 일도 없음 |
| `void PublishSafe<T>(T message) where T : IMessage` | 구독자 스냅샷(`ArrayPool`)을 순회. 핸들러 안에서 구독/해제 가능 |
| `void Subscribe<T>(Action<T> action) where T : IMessage` | 키는 `action.Target`. 정적 메서드면 `ArgumentException`, `Publish` 중이면 `InvalidOperationException`. 같은 Target 이 재구독하면 덮어씀 |
| `void Unsubscribe<T>(object subscriber = null) where T : IMessage` | `subscriber` 가 null 이면 `T` 구독자 전체 제거. 아니면 `Publish` 중 호출 시 `InvalidOperationException` |
| `void UnsubscribeAll(object subscriber = null)` | null 이면 전체 제거. 아니면 해당 구독자의 모든 구독 제거(`Publish` 중이면 `InvalidOperationException`) |

### class MessageBrokerService : IMessageBrokerService

생성자 `MessageBrokerService()`.

---

## Geuneda.Services — 틱

### interface ITickService : IDisposable

| 멤버 | 설명 |
|------|------|
| `void SubscribeOnUpdate(Action<float> action, float deltaTime = 0f, bool timeOverflowToNextTick = false, bool realTime = false)` | Update 구독. 인자는 마지막 호출 이후 경과 시간. `realTime` 이면 `Time.realtimeSinceStartup`, 아니면 `Time.time` |
| `void SubscribeOnLateUpdate(Action<float> action, float deltaTime = 0f, bool timeOverflowToNextTick = false, bool realTime = false)` | LateUpdate 구독 |
| `void SubscribeOnFixedUpdate(Action<float> action)` | FixedUpdate 구독. 인자는 `Time.fixedTime` |
| `void Unsubscribe(Action<float> action)` | 세 리스트 모두에서 제거 |
| `void UnsubscribeOnUpdate(Action<float> action)` / `UnsubscribeOnFixedUpdate(...)` / `UnsubscribeOnLateUpdate(...)` | 해당 리스트에서 제거 |
| `void UnsubscribeAllOnUpdate()` / `UnsubscribeAllOnUpdate(object subscriber)` | Update 전체 / 구독자별 제거 |
| `void UnsubscribeAllOnFixedUpdate()` / `UnsubscribeAllOnFixedUpdate(object subscriber)` | |
| `void UnsubscribeAllOnLateUpdate()` / `UnsubscribeAllOnLateUpdate(object subscriber)` | |
| `void UnsubscribeAll()` / `UnsubscribeAll(object subscriber)` | 세 리스트 전체 / 구독자별 제거 |

### class TickService : ITickService

생성자 `TickService()` 가 `DontDestroyOnLoad` GameObject 와 `TickServiceMonoBehaviour` 를 만든다. `Dispose()` 는 GameObject 를 파괴하고 리스트를 비운다.

### class TickServiceMonoBehaviour : MonoBehaviour

public 필드 `Action OnUpdate`, `Action OnFixedUpdate`, `Action OnLateUpdate`. `TickService` 내부용 호스트.

---

## Geuneda.Services — 코루틴

### interface IAsyncCoroutine

| 멤버 | 설명 |
|------|------|
| `bool IsRunning { get; }` | |
| `bool IsCompleted { get; }` | |
| `Coroutine Coroutine { get; }` | 완료/중지 후 null |
| `float StartTime { get; }` | 생성 시점 `Time.time` |
| `void OnComplete(Action onComplete)` | 완료 콜백 설정 (교체) |
| `void StopCoroutine(bool triggerOnComplete = false)` | 중지 후 완료 상태로 전환. `true` 면 콜백 호출. 이미 완료면 무시 |

### interface IAsyncCoroutine\<T\> : IAsyncCoroutine

| 멤버 | 설명 |
|------|------|
| `T Data { get; set; }` | 완료 시 전달할 데이터 |
| `void OnComplete(Action<T> onComplete)` | 데이터 포함 완료 콜백 (교체) |

### interface ICoroutineService : IDisposable

| 멤버 | 반환 |
|------|------|
| `StartCoroutine(IEnumerator routine)` | `Coroutine` |
| `StartAsyncCoroutine(IEnumerator routine)` | `IAsyncCoroutine` |
| `StartAsyncCoroutine<T>(IEnumerator routine, T data)` | `IAsyncCoroutine<T>` |
| `StartDelayCall(Action call, float delay)` | `IAsyncCoroutine` |
| `StartDelayCall<T>(Action<T> call, T data, float delay)` | `IAsyncCoroutine<T>` |
| `StopCoroutine(Coroutine coroutine)` | `void` |
| `StopAllCoroutines()` | `void` (`IAsyncCoroutine` 핸들은 완료 처리되지 않음) |

### class CoroutineService : ICoroutineService

생성자 `CoroutineService()` 가 `DontDestroyOnLoad` GameObject 와 `CoroutineServiceMonoBehaviour` 를 만든다. `Dispose()` 는 모든 코루틴을 멈추고 GameObject 를 파괴한다.

### class CoroutineServiceMonoBehaviour : MonoBehaviour

`Coroutine ExternalStartCoroutine(IEnumerator routine)`, `void ExternalStopCoroutine(Coroutine coroutine)`. 내부용 호스트.

---

## Geuneda.Services.Pooling — 풀

### 엔티티 훅 인터페이스

| 인터페이스 | 멤버 | 호출 시점 |
|------------|------|-----------|
| `IPoolEntitySpawn` | `void OnSpawn()` | 모든 스폰 |
| `IPoolEntitySpawn<T>` | `void OnSpawn(T data)` | `Spawn(data)` (`OnSpawn()` 다음) |
| `IPoolEntityDespawn` | `void OnDespawn()` | 디스폰 |
| `IPoolEntityObject<T> where T : class` | `void Init(IObjectPool<T> pool)`, `bool Despawn()` | `Init` 은 인스턴스 생성 시 |

### interface IObjectPool : IDisposable

| 멤버 | 설명 |
|------|------|
| `void DespawnAll()` | 스폰된 엔티티 전부 디스폰 |
| `void Dispose(bool disposeSampleEntity)` | 해제. 구현별 동작은 아래 참고 |

### interface IObjectPool\<T\> : IObjectPool where T : class

| 멤버 | 설명 |
|------|------|
| `T SampleEntity { get; }` | 새 인스턴스를 만드는 원본 |
| `IReadOnlyList<T> SpawnedReadOnly { get; }` | 스폰된 엔티티 |
| `bool IsSpawned(Func<T, bool> conditionCheck)` | 조건에 맞는 스폰 엔티티가 있으면 `true` |
| `void Reset(uint initSize, T sampleEntity)` | `Dispose()` 후 새 샘플로 `initSize` 개 생성 |
| `T Spawn()` | 스폰. 비어 있으면 새로 생성 |
| `T Spawn<TData>(TData data)` | 데이터와 함께 스폰 |
| `bool Despawn(T entity)` | 디스폰. 스폰 목록에 없으면 `false` |
| `bool Despawn(bool onlyFirst, Func<T, bool> entityGetter)` | 조건부 디스폰 |
| `List<T> Clear()` | 스폰/대기 엔티티를 모두 떼어 반환 (파괴하지 않음) |

### abstract class ObjectPoolBase\<T\> : IObjectPool\<T\> where T : class

- 생성자 `protected ObjectPoolBase(uint initSize, T sampleEntity, Func<T, T> instantiator)`
- `protected readonly IList<T> SpawnedEntities`
- `protected virtual T SpawnEntity()`, `protected virtual void PostDespawnEntity(T entity)`, `protected T CallInstantiator()`
- `SpawnEntity()` 는 스택에서 null 이거나 파괴된(`Equals(null)`) 항목을 건너뛰고, 스택이 비면 인스턴시에이터를 한 번 부릅니다. 그 결과도 null 이거나 파괴된 객체면 `InvalidOperationException` 을 던집니다. `CallInstantiator()` 는 무효한 인스턴스에 `IPoolEntityObject<T>.Init` 을 부르지 않습니다(v3.0.0)
- `protected virtual void CallOnSpawned(T entity)`, `protected virtual void CallOnSpawned<TData>(T entity, TData data)`, `protected virtual void CallOnDespawned(T entity)` — 기본 구현은 `entity as I...` 캐스팅
- `public virtual void Dispose()` — `Clear()` 호출
- `public virtual void Dispose(bool disposeSampleEntity)` — `true` 면 샘플 참조를 null 로 만든 뒤 `Dispose()`

### class ObjectPool\<T\> : ObjectPoolBase\<T\> where T : class

- `ObjectPool(uint initSize, T sampleEntity, Func<T, T> instantiator)`
- `ObjectPool(uint initSize, Func<T> instantiator)` — 샘플도 `instantiator()` 로 생성

### class GameObjectPool : ObjectPoolBase\<GameObject\>

- `GameObjectPool(uint initSize, GameObject sampleEntity)`, `GameObjectPool(uint initSize, GameObject sampleEntity, Func<GameObject, GameObject> instantiator)`
- `bool DespawnToSampleParent { get; set; }` (기본 `true`)
- `static GameObject Instantiator(GameObject entityRef)` — 샘플 부모 아래 `Object.Instantiate` 후 `SetActive(false)`
- 스폰 시 `SetActive(true)`, 디스폰 시 `SetActive(false)`. 훅은 `GetComponent<I...>()` 로 호출
- `Dispose()` — 풀의 GameObject 를 `Object.Destroy`(이미 파괴된 항목은 건너뜀). 샘플은 유지
- `Dispose(bool)` — 인자가 `true` 이면 샘플을 `Object.Destroy` 한 뒤 기본 처리(`false` 면 샘플 유지)

### class GameObjectPool\<T\> : ObjectPoolBase\<T\> where T : Behaviour

- `GameObjectPool(uint initSize, T sampleEntity)`, `GameObjectPool(uint initSize, T sampleEntity, Func<T, T> instantiator)`
- `bool DespawnToSampleParent { get; set; }` (기본 `true`)
- `static T Instantiator(T entityRef)`
- `GameObjectPool` 과 같은 활성화/훅/해제 규칙(대상은 `entity.gameObject`)

### interface IPoolService : IDisposable

| 멤버 | 설명 |
|------|------|
| `IObjectPool<T> GetPool<T>() where T : class` | 없으면 `ArgumentException` |
| `bool TryGetPool<T>(out IObjectPool<T> pool) where T : class` | |
| `void AddPool<T>(IObjectPool<T> pool) where T : class` | 중복이면 `ArgumentException` |
| `void RemovePool<T>() where T : class` | 서비스에서만 제거 |
| `T Spawn<T>() where T : class` | |
| `T Spawn<T, TData>(TData data) where T : class, IPoolEntitySpawn<TData>` | |
| `bool Despawn<T>(T entity) where T : class` | |
| `void DespawnAll<T>() where T : class` | |
| `IDictionary<Type, IObjectPool> Clear()` | 모든 풀을 떼어 반환 (해제하지 않음) |
| `void Dispose<T>(bool disposeSampleEntity) where T : class` | 해당 풀 `Dispose(bool)` 후 제거 |

### class PoolService : IPoolService (네임스페이스 `Geuneda.Services`)

생성자 `PoolService()`. `Dispose()` 는 모든 풀의 `Dispose()` 를 호출하고 비운다.

---

## Geuneda.Services — 데이터

### interface IDataProvider

| 멤버 | 설명 |
|------|------|
| `T GetData<T>() where T : class` | 메모리에 없으면 `KeyNotFoundException` |
| `bool HasData<T>() where T : class` | |

### interface IDataService : IDataProvider

| 멤버 | 설명 |
|------|------|
| `void SaveData<T>() where T : class` | 저장소 키(`GetStorageKey(typeof(T))`)에 `{"version":n,"data":{...}}` 를 `IDataStorage.Write` 로 저장(기본 저장소는 `PlayerPrefs` + `PlayerPrefs.Save()`) |
| `void SaveAllData()` | 메모리의 모든 타입 저장 |
| `T LoadData<T>() where T : class` | 저장값이 없으면 `Activator.CreateInstance<T>()`. 저장된 버전이 낮으면 등록된 마이그레이션 적용. 읽지 못하면 예외 대신 `{키}.corrupt` 백업·에러 로그·`OnDataLoadFailed` 후 새 인스턴스. 결과를 메모리에 등록 |
| `void AddOrReplaceData<T>(T data) where T : class` | 메모리만 변경 |

### class DataService : IDataService

생성자 `DataService()`(= `PlayerPrefsDataStorage`, 접두사 없음), `DataService(IDataStorage storage, string keyPrefix = null)`(`storage` null 이면 `ArgumentNullException`). 인스턴스 `string GetStorageKey(Type)`(접두사가 있으면 `{접두사}.{FullName}`, 없으면 `GetSaveKey` 와 같음. 훅에 전달되는 키). 확장 지점 `protected virtual void OnDataSaved(string key, object data, Type type)`, `protected virtual void OnDataLoadFailed(string key, string rawData, Exception exception)`, `protected virtual void SaveCorruptBackup(string key, string rawData)`(기본 같은 저장소의 `{키}.corrupt`). 백업·훅의 예외는 로그만 남기고 새 인스턴스로 계속한다. 더 새 버전 세이브를 읽은 타입은 `AddOrReplaceData` 전까지 `SaveData`/`SaveAllData` 에서 건너뛴다(경고). `void AddMigration<T>(int fromVersion, Func<JToken, JToken> migration)`(한 단계씩, 잘못된 인자면 `ArgumentNullException`/`ArgumentOutOfRangeException`/`ArgumentException`). 정적 `string GetSaveKey(Type)`(FullName), `int GetDataVersion(Type)`, `const string CorruptKeySuffix = ".corrupt"`. 직렬화는 Newtonsoft.Json.

### interface IDataStorage

`bool HasKey(string key)`, `string Read(string key)`(없으면 `null`), `void Write(string key, string value)`(돌아오기 전에 영구 저장), `void Delete(string key)`(없으면 무시). 직접 구현해 다른 곳에 저장할 수 있다.

### class PlayerPrefsDataStorage : IDataStorage

`PlayerPrefs`. `Write`/`Delete` 마다 `PlayerPrefs.Save()`. `DataService()` 의 기본.

### class FileDataStorage : IDataStorage

생성자 `FileDataStorage()`(`Application.persistentDataPath`), `FileDataStorage(string directory)`(없으면 만듦, 비어 있으면 `ArgumentException`). 키마다 UTF-8 `{키}.json`. `Write` 는 `{키}.json.tmp` 에 쓰고 디스크에 내린 뒤 교체. 키가 파일 이름으로 쓸 수 없으면 모든 메서드가 `ArgumentException`.

### class BrowserLocalDataStorage : IDataStorage

WebGL 플레이어의 `localStorage`(페이지 출처 단위, 동기). 생성자가 WebGL 플레이어 밖(에디터 포함)에서 `PlatformNotSupportedException`, 브라우저가 막았으면 `InvalidOperationException`. `Write` 거부(용량 초과 등)는 `IOException`. jslib 는 `Runtime/Plugins/WebGL/`.

### sealed class DataVersionAttribute : Attribute

`[DataVersion(int version)]`, 클래스에만. 데이터 타입의 세이브 스키마 버전(음수면 `ArgumentOutOfRangeException`). 없으면 0.

---

## Geuneda.Services — 시간

현재 UTC 는 기준점(UTC 시각과 그때의 core `IMonotonicClock` 값)에 단조 시계 경과와 `AddTime` 오프셋을 더한 값이다(v5.0.0). 서비스를 만든 뒤 기기 시계를 바꿔도 현재 시각은 바뀌지 않는다.

### interface ITimeService

| 멤버 | 타입 | 설명 |
|------|------|------|
| `DateTimeUtcNow` | `DateTime` | 기준점 UTC + 단조 시계 경과 + 오프셋 (`Kind` 는 `Utc`). 어느 스레드에서 읽어도 됨 |
| `IsServerTime` | `bool` | `SetServerTime` 을 부른 뒤로 true. 그 전에는 생성할 때의 기기 시계 기준. 어느 스레드에서 읽어도 됨 |
| `UnityTimeNow` | `float` | `Time.realtimeSinceStartup` + 오프셋 |
| `UnityScaleTimeNow` | `float` | `Time.time` + 오프셋 |
| `UnixTimeNow` | `long` | 밀리초 Unix 시간 (오프셋 포함). 어느 스레드에서 읽어도 됨 |
| `TimeAdjusted` | `event Action<TimeSpan>` | `SetServerTime`·`AddTime` 으로 현재 시각이 바뀐 양(새 값 - 이전 값, 음수 가능). 처리기 예외는 로그만 남기고 다음 처리기로 넘어감 |
| `UnixTimeFromDateTimeUtc(DateTime time)` | `long` | |
| `UnixTimeFromUnityTime(float time)` | `long` | |
| `DateTimeUtcFromUnixTime(long time)` | `DateTime` | |
| `DateTimeUtcFromUnityTime(float time)` | `DateTime` | |
| `UnityTimeFromDateTimeUtc(DateTime time)` | `float` | |
| `UnityTimeFromUnixTime(long time)` | `float` | |

`DateTime` 을 받는 메서드는 `Kind` 가 `Unspecified` 면 `ArgumentException`, `Local` 은 UTC 로 바꾼다. 변환 메서드에는 `AddTime` 오프셋이 반영되지 않는다. Unity 시간 변환은 기준점의 `Time.realtimeSinceStartup` 을 기준으로 한다.

### interface ITimeManipulator : ITimeService

메인 스레드에서 부른다.

| 멤버 | 설명 |
|------|------|
| `void AddTime(float timeInSeconds)` | 오프셋 누적 (음수면 되돌림). `SetServerTime` 뒤에도 유지. `TimeAdjusted` 발생 |
| `void SetServerTime(DateTime serverUtcNow)` | 지금 이 순간의 서버 시각을 기준점으로 삼음(`IsServerTime` true). `Kind` 가 `Unspecified` 면 `ArgumentException`. `TimeAdjusted` 발생. v4.x 의 `SetInitialTime` |

### class TimeService : ITimeManipulator

- 생성자 `TimeService()`(core `MonotonicClock`), `TimeService(IMonotonicClock clock)`(null 이면 `ArgumentNullException`. 테스트용 가짜 시계, 또는 servertime 과 같은 시계)
- 기준점은 처음에 생성 시점 `DateTime.UtcNow`. 기기 시계는 생성할 때 한 번만 읽는다.
- 왕복 지연 보정, 주기 재동기화, 포그라운드 복귀 재동기화는 `com.geuneda.servertime` 의 `ServerTimeSync` 가 `SetServerTime` 을 불러 한다.

---

## Geuneda.Services — RNG

### interface IRngData

| 멤버 | 타입 | 설명 |
|------|------|------|
| `Seed` | `ulong` | |
| `Stream` | `ulong` | 스트림 번호. 시드가 같아도 스트림이 다르면 다른 수열(SplitMix64 로 섞음, 스트림 공간 2^63) |
| `Count` | `ulong` | 쓴 32비트 출력 수(범위 함수가 드물게 하나 더 씀) |

### class RngData : IRngData

public 필드 `ulong Seed`, `ulong Stream`, `ulong Count`. `RngService` 가 `Count` 를 직접 수정한다. 필드를 바깥에서 바꾸면 서비스는 다음 호출부터 그 상태를 쓴다.

### interface IRngService

| 멤버 | 타입 | 설명 |
|------|------|------|
| `Data` | `IRngData` | |
| `NextUInt()` | `uint` | 다음 32비트 값 |
| `NextFloat()` | `floatP` | [0, 1), 상위 24비트 × 2^-24 |
| `Range(int min, int max, bool maxInclusive = false)` | `int` | Lemire, 편향 없음. 포함이면 max 도 나옴 |
| `Range(floatP min, floatP max, bool maxInclusive = true)` | `floatP` | `min * (1 - t) + max * t` 를 [min, max] 로 자름. 미포함이면 max 가 나올 때 max 바로 아래 값. 출력 정확히 1개 |
| `PeekRange(int min, int max, bool maxInclusive = false)` | `int` | 상태 변경 없음. 이어서 부른 `Range` 와 같은 값 |
| `PeekRange(floatP min, floatP max, bool maxInclusive = true)` | `floatP` | 상태 변경 없음 |
| `Restore(ulong count)` | `void` | `Data.Count = count`. 다음 호출에서 O(log n) 으로 옮김 |

`min > max`, `maxInclusive == false` 이고 `min == max`, floatP 경계가 NaN·무한대면 `ArgumentOutOfRangeException`(상태 그대로). 범위 함수는 성공하면 출력을 하나 이상 쓴다. `Range(0, floatP.MaxValue)` 처럼 int 와 floatP 를 섞으면 오버로드가 모호하다(`floatP`↔`int` 양방향 암시적 변환). 두 경계의 타입을 맞춘다.

### class RngService : IRngService

- 생성자 `RngService(RngData rngData)`(null 이면 `ArgumentNullException`)
- 정적: `RngData CreateRngData(ulong seed, ulong stream = 0)`
- 스레드 안전하지 않음. 상태를 직접 다루거나 서버에서 재현하려면 core 의 `Pcg32`(`new Pcg32(Seed, Stream)` + `Advance(Count)`, `Range(int)` ↔ `NextInt`/`NextIntInclusive`)

`floatP` 는 `Geuneda.DataExtensions`(com.geuneda.gamedata). floatP 곱셈은 IEEE 반올림이 아니라 잘라내기라 서버에서 float 결과를 재현하려면 floatP 를 함께 링크한다.

---

## Geuneda.Services.Commands — 커맨드

| 타입 | 멤버 |
|------|------|
| `interface IGameCommandBase` | 마커 |
| `interface IGameServerCommand<in TGameLogic> : IGameCommandBase where TGameLogic : class` | `void ExecuteLogic(TGameLogic gameLogic)` (`CommandService` 는 실행하지 않음) |
| `interface IGameCommand<in TGameLogic> : IGameCommandBase where TGameLogic : class` | `void Execute(TGameLogic gameLogic, IMessageBrokerService messageBroker)` |
| `interface ICommandService<out TGameLogic> where TGameLogic : class` | `void ExecuteCommand<TCommand>(TCommand command) where TCommand : IGameCommand<TGameLogic>` |

### class CommandService\<TGameLogic\> : ICommandService\<TGameLogic\> (네임스페이스 `Geuneda.Services`)

- 생성자 `CommandService(TGameLogic gameLogic, IMessageBrokerService messageBroker)`
- `protected TGameLogic GameLogic`, `protected IMessageBrokerService MessageBroker`
- `ExecuteCommand` 는 동기, `virtual` 아님

---

## Geuneda.Services — 버전

### static class VersionServices

| 멤버 | 설명 |
|------|------|
| `const string VersionDataFilename = "version-data"` | Resources 의 TextAsset 이름 |
| `string VersionExternal` | `Application.version` |
| `string VersionInternal` | `FormatInternalVersion(data)`. 로드 실패 시 `Application.version` |
| `string Branch` / `Commit` / `BuildNumber` | 로드 실패 시 `string.Empty` |
| `void LoadVersionData()` | 동기 로드 (호출 시마다 다시 읽음) |
| `Task LoadVersionDataAsync()` | 비동기 로드 |
| `bool IsOutdatedVersion(string version)` | `version` 이 `VersionExternal` 보다 높으면 `true`. 아래 오버로드의 규칙을 따름 |
| `bool IsOutdatedVersion(string currentVersion, string otherVersion)` | `otherVersion` 이 더 높으면 `true`. `Major[.Minor[.Patch]]`, 빠진 부분 0, 각 부분의 앞쪽 숫자만 비교(접미사 무시). Major 를 읽을 수 없거나 어느 부분이 `int` 범위를 넘으면 경고 후 `false` |
| `string FormatInternalVersion(VersionData data)` | `{Application.version}-{BuildNumber}.{BranchName}.{CommitHash}.{AppEnv.Name}`(`Geuneda.Core.AppEnv`) |

`SubsystemRegistration` 에서 자동 로드되고, 프로퍼티 접근 시 로드를 한 번도 시도하지 않았으면 지연 로드한다(실패해도 재시도하지 않음).

### struct VersionServices.VersionData ([Serializable])

필드 `string CommitHash`, `string BranchName`, `string BuildNumber`. 환경은 필드가 아니라 런타임 `AppEnv` 다.

---

## Geuneda.Services.AssetsImporter — 저수준 로더

### interface IAssetLoader

| 멤버 | 반환 |
|------|------|
| `LoadAssetAsync<T>(object key, Action<T> onCompleteCallback = null)` | `UniTask<T>` |
| `InstantiateAsync(object key, Transform parent, bool instantiateInWorldSpace, Action<GameObject> onCompleteCallback = null)` | `UniTask<GameObject>` |
| `InstantiateAsync(object key, Vector3 position, Quaternion rotation, Transform parent, Action<GameObject> onCompleteCallback = null)` | `UniTask<GameObject>` |
| `UnloadAsset<T>(T asset, Action onCompleteCallback = null)` | `void` (`Addressables.Release` 후 콜백) |

### interface ISceneLoader

| 멤버 | 반환 |
|------|------|
| `LoadSceneAsync(string path, LoadSceneMode loadMode = LoadSceneMode.Single, bool activateOnLoad = true, Action<Scene> onCompleteCallback = null)` | `UniTask<Scene>` |
| `UnloadSceneAsync(Scene scene, Action onCompleteCallback = null)` | `UniTask` (`SceneManager.UnloadSceneAsync` 사용. Addressables 씬 핸들은 `sceneUnloaded` 에서 Addressables 가 해제) |

### class AddressablesAssetLoader : IAssetLoader, ISceneLoader

Addressables 래퍼. 작업이 실패하면 `OperationException` 을 던진다.

### 설정 타입

| 타입 | 설명 |
|------|------|
| `abstract class AssetConfigsScriptableObject : ScriptableObject` | `abstract Type AssetType { get; }`, `string AssetsFolderPath { get; set; }` |
| `abstract class AssetConfigsScriptableObjectBase<TId, TAsset> : AssetConfigsScriptableObject, IPairConfigsContainer<TId, TAsset>, ISerializationCallbackReceiver` | `List<Pair<TId, TAsset>> Configs { get; set; }`, `IReadOnlyDictionary<TId, TAsset> ConfigsDictionary { get; }`(역직렬화 시 생성) |
| `abstract class AssetConfigsScriptableObject<TId, TAsset> : AssetConfigsScriptableObjectBase<TId, AssetReference>` | `AssetType => typeof(TAsset)` |
| `class AddressableConfig` | 필드 `int Id`, `string Address`, `string Path`, `string AssetFileType`, `Type AssetType`, `ReadOnlyCollection<string> Labels`. 생성자 `(int id, string address, string path, Type assetType, string[] labels)`. `string GetSceneName()`(씬이 아니면 `InvalidOperationException`) |
| `class AddressableConfigComparer : IEqualityComparer<AddressableConfig>` | `Id` 비교 |
| `static class AssetLoaderUtils` | `Task<Task<T>>[] Interleaved<T>(IEnumerable<Task<T>> tasks)` — 완료 순서대로 꺼내기 |
| `class AssetReferenceScene : AssetReference` | 씬 에셋만 허용. 생성자 `(string guid)`. 에디터에서 `SceneAsset editorAsset` |

---

## Geuneda.Services — AssetResolverService

### interface IAssetResolverService : IAssetLoader, ISceneLoader

| 멤버 | 반환 |
|------|------|
| `RequestAsset<TId, TAsset>(TId id, bool loadAsynchronously = true, bool instantiate = true, Action<TId, TAsset, bool> onLoadCallback = null) where TAsset : Object` | `UniTask<TAsset>` |
| `RequestAsset<TId, TAsset, TData>(TId id, TData data, bool loadAsynchronously = true, bool instantiate = true, Action<TId, TAsset, TData, bool> onLoadCallback = null) where TAsset : Object` | `UniTask<TAsset>` |
| `LoadSceneAsync<TId>(TId id, LoadSceneMode loadMode = LoadSceneMode.Single, bool activateOnLoad = true, bool setActive = true, Action<TId, SceneInstance> onLoadCallback = null)` | `UniTask<SceneInstance>` |
| `LoadAllAssets<TId, TAsset>(bool loadAsynchronously = true, Action<TId, TAsset> onLoadCallback = null)` | `UniTask<List<Pair<TId, TAsset>>>` |
| `UnloadSceneAsync<TId>(TId id, Action<TId> onUnloadCallback = null)` | `UniTask` |
| `UnloadAssets<TId, TAsset>(bool clearReferences)` | `void` |
| `UnloadAssets<TId, TAsset>(bool clearReferences, AssetConfigsScriptableObject<TId, TAsset> assetConfigs)` | `void` |
| `UnloadAssets<TId, TAsset>(bool clearReferences, params TId[] ids)` | `void` |

미등록 id 로 `RequestAsset` / `LoadSceneAsync<TId>` / `LoadAllAssets` 를 호출하면 `MissingMemberException`. 씬은 에셋 타입 `UnityEngine.SceneManagement.Scene` 으로 등록된 것을 찾는다. `instantiate: true` 면 `GameObject` 는 `Object.Instantiate`, `Material` 은 `new Material(...)` 복사본을 돌려준다.

### interface IAssetAdderService : IAssetResolverService

| 멤버 | 설명 |
|------|------|
| `void AddConfigs<TId, TAsset>(AssetConfigsScriptableObject<TId, TAsset> configs)` | **기본 인터페이스 메서드**. `IAssetAdderService` 타입으로만 호출 가능 |
| `void AddAssets<TId>(Type assetType, List<Pair<TId, AssetReference>> assets)` | 같은 id 재등록 시 `ArgumentException` |
| `void AddAsset<TId>(Type assetType, TId id, AssetReference assetReference)` | |
| `void AddDebugConfigs(Sprite errorSprite = null, GameObject errorCube = null, Material errorMaterial = null, AudioClip errorClip = null)` | 로드 미완료 시 대체 에셋 |

### class AssetResolverService : AddressablesAssetLoader, IAssetAdderService

생성자 `AssetResolverService()`.

---

## 에디터 API (`Geuneda.Services.Editor` 어셈블리)

### Geuneda.Services.AssetsImporter.Editor

| 타입 | 멤버 |
|------|------|
| `interface IAssetConfigsImporter` | `Type ScriptableObjectType { get; }`, `void Import(string assetsFolderPath = null)` |
| `interface IAssetConfigsGeneratorImporter : IAssetConfigsImporter` | `string TIdName`, `string TScriptableObjectName`, `bool CacheScriptAsOld` |
| `abstract class AssetsConfigsImporterBase<TId, TAsset, TScriptableObject> : IAssetConfigsImporter where TScriptableObject : AssetConfigsScriptableObject<TId, TAsset>` | `virtual Type AssetType`, `protected abstract TId[] Ids`, `protected virtual string IdPattern(TId id)`, `protected virtual List<Pair<TId, AssetReference>> OnImportIds(...)`, `protected int IndexOfId(string id, IList<string> assetsPath)`, `protected virtual void OnImportComplete(TScriptableObject scriptableObject)` |
| `abstract class AssetsConfigsImporter<TId, TAsset, TScriptableObject> : AssetsConfigsImporterBase<...> where TId : Enum` | `Ids` 는 enum 전체 값. 경로에 `/{IdPattern(id)}.` 가 포함된 에셋을 매칭 |
| `abstract class AssetsConfigsGeneratorImporter<TAsset> : IAssetConfigsGeneratorImporter` | enum(`Game.Ids`), 설정 SO(`Game.Configs`), 임포터 스크립트를 `Assets/` 에 생성 |

비추상 `IAssetConfigsImporter` 구현은 리플렉션으로 자동 발견되어 `Tools > Geuneda > Assets Importer > Import Assets Data` 와 Services Explorer 의 Assets Importer 탭에 나타난다.

### Geuneda.Services.Versioning.Editor

| 타입 | 멤버 |
|------|------|
| `static class VersionEditorUtils` | `void SetAndSaveInternalVersion()`(활성 빌드 타깃의 빌드 번호), `void SetAndSaveInternalVersion(BuildTarget buildTarget)`, `string LoadVersionDataSerializedSync()`. 빌드 번호는 Android 면 `bundleVersionCode`, 그 밖에는 `iOS.buildNumber` |
| `internal sealed class VersionBuildProcessor` | `IPreprocessBuildWithReport`/`IPostprocessBuildWithReport`. 빌드 직전 빌드 대상 플랫폼의 빌드 번호를 쓰고, 성공 후처리 또는 빌드가 끝난 뒤 첫 에디터 업데이트(실패·취소)에서 활성 타깃 번호로 되돌림. 환경은 기록하지 않음(런타임 `AppEnv`) |
| `class GitEditorProcess : IDisposable` | 생성자 `(string workingDir, string pathToGitBinary = ...)`, `int ExitCode`, `bool IsValidRepo()`, `string GetBranch()`, `string GetCommitHash()`, `string GetDiffFromCommit(string commitHash)` |

### Geuneda.Services.Editor.Explorer

| 타입 | 멤버 |
|------|------|
| `class ServicesExplorerWindow : EditorWindow` | `static void Open()`, `static ServicesExplorerWindow OpenOnTab<T>() where T : ServiceTab`, `void SelectTab<T>() where T : ServiceTab` |
| `abstract class ServiceTab : VisualElement` (`.Tabs`) | 탭 기반 클래스. `abstract string DisplayName` |

### 메뉴

- `Tools/Geuneda/Services Explorer`
- `Tools/Geuneda/Versioning/Refresh Version Data`, `Tools/Geuneda/Versioning/Open in Explorer`
- `Tools/Geuneda/Assets Importer/Import Assets Data`, `Tools/Geuneda/Assets Importer/Open in Explorer`
- `Tools/Geuneda/Addressable Ids/Generate Addressable Ids`, `Tools/Geuneda/Addressable Ids/Open in Explorer`
- `Assets/Create/Geuneda Services/Message`, `.../Command`, `.../Service`, `.../Pool Entity`

### Addressable Ids 생성기 출력

설정 기본값 `ScriptFilename = "AddressableId"`, `Namespace = "Game.Ids"`, `AddressableLabel = "GenerateIds"`(비우면 전체). 생성 파일에는 주소 enum `{ScriptFilename}`, enum `AddressableLabel`(`Label_...`), `static class AddressablePathLookup`, `static class AddressableConfigLookup`(`IList<AddressableConfig> Configs`, `IList<string> Labels`, `GetConfig(this {ScriptFilename})`, `GetConfigs(this AddressableLabel)`, `GetConfigs(string label)`, `ToLabelString(this AddressableLabel)`)이 들어 있다.
