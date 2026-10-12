# Geuneda Services - 공개 API 레퍼런스

`com.geuneda.services` 2.1.4 소스 기준. 런타임 어셈블리 `Geuneda.Services`, 에디터 어셈블리 `Geuneda.Services.Editor`.

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
| `void SaveData<T>() where T : class` | `PlayerPrefs` 키 `typeof(T).Name` 에 JSON 저장 후 `PlayerPrefs.Save()` |
| `void SaveAllData()` | 메모리의 모든 타입 저장 |
| `T LoadData<T>() where T : class` | 저장값이 없으면 `Activator.CreateInstance<T>()`. 결과를 메모리에 등록 |
| `void AddOrReplaceData<T>(T data) where T : class` | 메모리만 변경 |

### class DataService : IDataService

생성자 `DataService()`. `protected virtual void OnDataSaved(string key, object data, Type type)` 확장 지점. 직렬화는 Newtonsoft.Json(`JsonConvert`).

---

## Geuneda.Services — 시간

### interface ITimeService

| 멤버 | 타입 | 설명 |
|------|------|------|
| `DateTimeUtcNow` | `DateTime` | 기준 시각 + 경과 시간 + 오프셋 (UTC) |
| `UnityTimeNow` | `float` | `Time.realtimeSinceStartup` + 오프셋 |
| `UnityScaleTimeNow` | `float` | `Time.time` + 오프셋 |
| `UnixTimeNow` | `long` | 밀리초 Unix 시간 (오프셋 포함) |
| `UnixTimeFromDateTimeUtc(DateTime time)` | `long` | |
| `UnixTimeFromUnityTime(float time)` | `long` | |
| `DateTimeUtcFromUnixTime(long time)` | `DateTime` | |
| `DateTimeUtcFromUnityTime(float time)` | `DateTime` | |
| `UnityTimeFromDateTimeUtc(DateTime time)` | `float` | |
| `UnityTimeFromUnixTime(long time)` | `float` | |

변환 메서드에는 `AddTime` 오프셋이 반영되지 않는다.

### interface ITimeManipulator : ITimeService

| 멤버 | 설명 |
|------|------|
| `void AddTime(float timeInSeconds)` | 오프셋 누적 (음수면 되돌림) |
| `void SetInitialTime(DateTime initialTime)` | 기준 시각을 바꾸고 기준 Unity 시간을 현재로 재설정 |

### class TimeService : ITimeManipulator

생성자 `TimeService()`. 기준 시각은 생성 시점 `DateTime.Now`.

---

## Geuneda.Services — RNG

### interface IRngData

| 멤버 | 타입 |
|------|------|
| `Seed` | `int` |
| `Count` | `int` |
| `State` | `IReadOnlyList<int>` (길이 56) |

### class RngData : IRngData

public 필드 `int Seed`, `int Count`, `int[] State`. `RngService` 가 직접 수정한다.

### interface IRngService

| 멤버 | 타입 | 설명 |
|------|------|------|
| `Data` | `IRngData` | |
| `Counter` | `int` | `Data.Count` |
| `Peek` | `int` | 상태 변경 없음 |
| `Peekfloat` | `floatP` | 상태 변경 없음 |
| `Next` | `int` | 상태 진행, `Counter` +1 |
| `Nextfloat` | `floatP` | 상태 진행, `Counter` +1 |
| `PeekRange(int min, int max, bool maxInclusive = false)` | `int` | |
| `PeekRange(floatP min, floatP max, bool maxInclusive = true)` | `floatP` | |
| `Range(int min, int max, bool maxInclusive = false)` | `int` | |
| `Range(floatP min, floatP max, bool maxInclusive = true)` | `floatP` | |
| `Restore(int count)` | `void` | 시드에서 `count` 번 진행한 상태로 복원 |

`min > max`, 또는 `maxInclusive == false` 이고 `min == max` 면 `IndexOutOfRangeException`.

### class RngService : IRngService

- 생성자 `RngService(RngData rngData)`
- 정적: `RngData CreateRngData(int seed)`, `int[] GenerateRngState(int seed)`, `int[] CopyRngState(int[] state)`(길이 56 아니면 `IndexOutOfRangeException`), `int[] Restore(int count, int seed)`, `int Range(int min, int max, int[] rndState, bool maxInclusive)`, `floatP Range(floatP min, floatP max, int[] rndState, bool maxInclusive)`

`floatP` 는 `Geuneda.DataExtensions`(com.geuneda.gamedata).

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
| `bool IsOutdatedVersion(string version)` | `version` 이 `VersionExternal` 보다 높으면 `true`. 세 부분 아니면 예외 |
| `string FormatInternalVersion(VersionData data)` | `{Application.version}-{BuildNumber}.{BranchName}.{CommitHash}[.{BuildType}]` |

`SubsystemRegistration` 에서 자동 로드되고, 프로퍼티 접근 시 로드를 한 번도 시도하지 않았으면 지연 로드한다(실패해도 재시도하지 않음).

### struct VersionServices.VersionData ([Serializable])

필드 `string CommitHash`, `string BranchName`, `string BuildType`, `string BuildNumber`.

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
| `static class VersionEditorUtils` | `void SetAndSaveInternalVersion(bool isStoreBuild)`(`prod`/`dev`), `string LoadVersionDataSerializedSync()` |
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
