# Geuneda Services - API Reference

## 네임스페이스: Geuneda.Services

---

## DI 컨테이너

### interface IInstaller

바인딩 인스톨러의 컨테이너. 인터페이스만 바인딩 가능.

| 메서드 | 반환 | 설명 |
|--------|------|------|
| `Bind<T>(T instance)` | `IInstaller` | 인터페이스 T를 instance에 바인딩. 체인 호출 가능 |
| `Bind<T, T1, T2>(T instance)` | `IInstaller` | 2개 인터페이스에 동시 바인딩 |
| `Bind<T, T1, T2, T3>(T instance)` | `IInstaller` | 3개 인터페이스에 동시 바인딩 |
| `TryResolve<T>(out T instance)` | `bool` | 안전한 해석. 바인딩 존재 시 true |
| `Resolve<T>()` | `T` | 인스턴스 해석. 미바인딩 시 ArgumentException |
| `Clean<T>()` | `bool` | 특정 타입 바인딩 제거. 성공 시 true |
| `Clean()` | `void` | 모든 바인딩 제거 |

### class Installer : IInstaller

`IInstaller`의 구현체. 내부적으로 `Dictionary<Type, object>` 사용.

### static class MainInstaller

게임 전체 범위의 정적 서비스 로케이터.

| 메서드 | 설명 |
|--------|------|
| `Bind<T>(T instance)` | 인터페이스 바인딩 |
| `TryResolve<T>(out T instance)` | 안전한 해석 |
| `Resolve<T>()` | 인스턴스 해석 |
| `Clean<T>()` | 특정 타입 제거 |
| `CleanDispose<T>()` | Dispose 후 제거 (T : IDisposable 필요) |
| `Clean()` | 모든 바인딩 제거 |

---

## 메시지 브로커

### interface IMessage

메시지 브로커에서 발행되는 모든 메시지의 마커 인터페이스.

### interface IMessageBrokerService

| 메서드 | 설명 |
|--------|------|
| `Publish<T>(T message)` | 메시지 발행. 구독자 없으면 무시. Publish 중 Subscribe/Unsubscribe 시 예외 |
| `PublishSafe<T>(T message)` | 안전한 발행. 구독자 복사 후 반복하므로 체인 구독 안전. 다만 추가 메모리 할당 |
| `Subscribe<T>(Action<T> action)` | 구독. 정적 메서드 불가. Publish 중 호출 불가 |
| `Unsubscribe<T>(object subscriber)` | 구독 해제. subscriber가 null이면 해당 타입 전체 해제. Publish 중 호출 불가 |
| `UnsubscribeAll(object subscriber)` | 모든 메시지 구독 해제. subscriber가 null이면 전체 해제 |

### class MessageBrokerService : IMessageBrokerService

내부 구조: `IDictionary<Type, IDictionary<object, Delegate>>`
- 키: 메시지 타입
- 값: subscriber 객체 -> Action 매핑
- `_isPublishing` 튜플로 발행 중 상태 추적

---

## 틱 서비스

### interface ITickService : IDisposable

| 메서드 | 설명 |
|--------|------|
| `SubscribeOnUpdate(Action<float>, float deltaTime, bool timeOverflowToNextTick, bool realTime)` | Update 구독. deltaTime=0이면 매 프레임. realTime이면 Time.realtimeSinceStartup 사용 |
| `SubscribeOnLateUpdate(Action<float>, float deltaTime, bool timeOverflowToNextTick, bool realTime)` | LateUpdate 구독 |
| `SubscribeOnFixedUpdate(Action<float>)` | FixedUpdate 구독 |
| `Unsubscribe(Action<float>)` | 모든 업데이트에서 해제 |
| `UnsubscribeOnUpdate(Action<float>)` | Update에서만 해제 |
| `UnsubscribeOnFixedUpdate(Action<float>)` | FixedUpdate에서만 해제 |
| `UnsubscribeOnLateUpdate(Action<float>)` | LateUpdate에서만 해제 |
| `UnsubscribeAllOnUpdate()` / `(object subscriber)` | Update 일괄 해제 |
| `UnsubscribeAllOnFixedUpdate()` / `(object subscriber)` | FixedUpdate 일괄 해제 |
| `UnsubscribeAllOnLateUpdate()` / `(object subscriber)` | LateUpdate 일괄 해제 |
| `UnsubscribeAll()` / `(object subscriber)` | 전체 일괄 해제 |

### class TickService : ITickService

- 생성자에서 DontDestroyOnLoad `TickServiceMonoBehaviour` GameObject 생성
- 내부적으로 `List<TickData>` 3개 (Update/Fixed/Late)
- 역순 순회로 반복 중 안전한 변경 지원
- `timeOverflowToNextTick`: 타이밍 오버플로를 다음 틱에 반영

### class TickServiceMonoBehaviour : MonoBehaviour

틱 서비스의 MonoBehaviour 호스트. `OnUpdate`, `OnFixedUpdate`, `OnLateUpdate` Action 필드.

---

## 코루틴 서비스

### interface IAsyncCoroutine

| 멤버 | 타입 | 설명 |
|------|------|------|
| `IsRunning` | `bool` | 실행 중 여부 |
| `IsCompleted` | `bool` | 완료 여부 |
| `Coroutine` | `Coroutine` | 현재 코루틴 |
| `StartTime` | `float` | 시작 시간 |
| `OnComplete(Action)` | `void` | 완료 콜백 설정 |
| `StopCoroutine(bool triggerOnComplete)` | `void` | 코루틴 중지 |

### interface IAsyncCoroutine\<T\> : IAsyncCoroutine

| 멤버 | 타입 | 설명 |
|------|------|------|
| `Data` | `T` | 코루틴 완료 시 반환 데이터 |
| `OnComplete(Action<T>)` | `void` | 데이터 포함 완료 콜백 |

### interface ICoroutineService : IDisposable

| 메서드 | 반환 | 설명 |
|--------|------|------|
| `StartCoroutine(IEnumerator)` | `Coroutine` | 기본 코루틴 시작 |
| `StartAsyncCoroutine(IEnumerator)` | `IAsyncCoroutine` | 비동기 코루틴 (완료 콜백 지원) |
| `StartAsyncCoroutine<T>(IEnumerator, T data)` | `IAsyncCoroutine<T>` | 데이터 포함 비동기 코루틴 |
| `StartDelayCall(Action, float delay)` | `IAsyncCoroutine` | 지연 호출 |
| `StartDelayCall<T>(Action<T>, T data, float delay)` | `IAsyncCoroutine<T>` | 데이터 포함 지연 호출 |
| `StopCoroutine(Coroutine)` | `void` | 코루틴 중지 |
| `StopAllCoroutines()` | `void` | 전체 중지 |

### class CoroutineService : ICoroutineService

- 생성자에서 DontDestroyOnLoad `CoroutineServiceMonoBehaviour` GameObject 생성
- Dispose()로 정리 (GameObject 파괴, 모든 코루틴 중지)

---

## 풀링 시스템

### 풀 엔티티 인터페이스

| 인터페이스 | 메서드 | 설명 |
|-----------|--------|------|
| `IPoolEntitySpawn` | `OnSpawn()` | 스폰 시 알림 |
| `IPoolEntitySpawn<T>` | `OnSpawn(T data)` | 데이터와 함께 스폰 시 알림 |
| `IPoolEntityDespawn` | `OnDespawn()` | 디스폰 시 알림 |
| `IPoolEntityObject<T>` | `Init(IObjectPool<T>)`, `Despawn()` | 자체 디스폰 기능 |

### interface IObjectPool : IDisposable

| 메서드 | 설명 |
|--------|------|
| `DespawnAll()` | 모든 엔티티 디스폰 |
| `Dispose(bool disposeSampleEntity)` | 해제 (샘플 엔티티 포함 여부) |

### interface IObjectPool\<T\> : IObjectPool

| 멤버 | 설명 |
|------|------|
| `T SampleEntity` | 풀 원본 엔티티 |
| `IReadOnlyList<T> SpawnedReadOnly` | 스폰된 엔티티 읽기 전용 리스트 |
| `IsSpawned(Func<T, bool>)` | 조건 검사 |
| `Reset(uint initSize, T sampleEntity)` | 풀 리셋 |
| `Spawn()` | 스폰 |
| `Spawn<TData>(TData data)` | 데이터와 함께 스폰 |
| `Despawn(T entity)` | 디스폰 |
| `Despawn(bool onlyFirst, Func<T, bool>)` | 조건부 디스폰 |
| `Clear()` | 내용 비우기 (리스트 반환) |

### class ObjectPoolBase\<T\> : IObjectPool\<T\> (abstract)

풀의 기본 구현. Stack 기반. 풀이 비면 Instantiator로 새 인스턴스 생성.

### class ObjectPool\<T\> : ObjectPoolBase\<T\>

순수 C# 객체용 풀.
- `ObjectPool(uint initSize, T sampleEntity, Func<T, T> instantiator)`
- `ObjectPool(uint initSize, Func<T> instantiator)`

### class GameObjectPool : ObjectPoolBase\<GameObject\>

GameObject용 풀. 스폰 시 SetActive(true), 디스폰 시 SetActive(false).
- `bool DespawnToSampleParent` - 디스폰 시 샘플 부모로 이동 (기본 true)
- `GameObjectPool(uint initSize, GameObject sampleEntity)`
- 정적 `Instantiator(GameObject)` - Object.Instantiate + SetActive(false)

### class GameObjectPool\<T\> : ObjectPoolBase\<T\> where T : Behaviour

Behaviour 컴포넌트 기반 풀. GetComponent로 IPoolEntity 인터페이스 접근.
- `bool DespawnToSampleParent` - 디스폰 시 샘플 부모로 이동 (기본 true)
- `GameObjectPool(uint initSize, T sampleEntity)`

### interface IPoolService : IDisposable

| 메서드 | 설명 |
|--------|------|
| `GetPool<T>()` | 풀 조회 (미존재 시 ArgumentException) |
| `TryGetPool<T>(out IObjectPool<T>)` | 안전한 풀 조회 |
| `AddPool<T>(IObjectPool<T>)` | 풀 추가 (중복 시 ArgumentException) |
| `RemovePool<T>()` | 풀 제거 |
| `Spawn<T>()` | 스폰 |
| `Spawn<T, TData>(TData)` | 데이터와 함께 스폰 |
| `Despawn<T>(T)` | 디스폰 |
| `DespawnAll<T>()` | 전체 디스폰 |
| `Clear()` | 모든 풀 반환 |
| `Dispose<T>(bool disposeSampleEntity)` | 특정 풀 해제 |

---

## 데이터 서비스

### interface IDataProvider

| 메서드 | 설명 |
|--------|------|
| `T GetData<T>()` | 데이터 조회 (참조 타입만) |
| `bool HasData<T>()` | 데이터 존재 확인 |

### interface IDataService : IDataProvider

| 메서드 | 설명 |
|--------|------|
| `SaveData<T>()` | 특정 타입 저장 (PlayerPrefs + JSON) |
| `SaveAllData()` | 전체 저장 |
| `T LoadData<T>()` | 로드 (없으면 Activator.CreateInstance로 생성) |
| `AddOrReplaceData<T>(T data)` | 메모리에 추가/교체 |

### class DataService : IDataService

- 내부: `IDictionary<Type, object>`
- 저장: `PlayerPrefs.SetString(typeof(T).Name, JsonConvert.SerializeObject(data))`
- 로드: `JsonConvert.DeserializeObject<T>(json)`
- `OnDataSaved(string key, object data, Type type)` - 가상 메서드 (확장용)

---

## 시간 서비스

### interface ITimeService

| 멤버 | 타입 | 설명 |
|------|------|------|
| `DateTimeUtcNow` | `DateTime` | 게임 기준 UTC 시간 |
| `UnityTimeNow` | `float` | realtimeSinceStartup + extraTime |
| `UnityScaleTimeNow` | `float` | Time.time + extraTime |
| `UnixTimeNow` | `long` | 밀리초 단위 Unix 시간 |
| `UnixTimeFromDateTimeUtc(DateTime)` | `long` | DateTime -> Unix |
| `UnixTimeFromUnityTime(float)` | `long` | Unity -> Unix |
| `DateTimeUtcFromUnixTime(long)` | `DateTime` | Unix -> DateTime |
| `DateTimeUtcFromUnityTime(float)` | `DateTime` | Unity -> DateTime |
| `UnityTimeFromDateTimeUtc(DateTime)` | `float` | DateTime -> Unity |
| `UnityTimeFromUnixTime(long)` | `float` | Unix -> Unity |

### interface ITimeManipulator : ITimeService

| 메서드 | 설명 |
|--------|------|
| `AddTime(float timeInSeconds)` | 시간 추가/감소 |
| `SetInitialTime(DateTime initialTime)` | 초기 시간 설정 (서버 동기화용) |

### class TimeService : ITimeManipulator

시간 기준점: `_initialTime`(DateTime.Now) + `_initialUnityTime`(realtimeSinceStartup) + `_extraTime`

---

## RNG 서비스

### interface IRngData

| 멤버 | 타입 | 설명 |
|------|------|------|
| `Seed` | `int` | RNG 시드 |
| `Count` | `int` | 생성된 난수 개수 |
| `State` | `IReadOnlyList<int>` | RNG 상태 (56개 int 배열) |

### class RngData : IRngData

직렬화 가능한 RNG 데이터. `int Seed`, `int Count`, `int[] State` 필드.

### interface IRngService

| 멤버 | 타입 | 설명 |
|------|------|------|
| `Data` | `IRngData` | RNG 데이터 |
| `Counter` | `int` | 카운트 |
| `Peek` / `Peekfloat` | `int` / `floatP` | 상태 변경 없이 조회 |
| `Next` / `Nextfloat` | `int` / `floatP` | 다음 난수 (상태 변경) |
| `PeekRange(int, int, bool)` | `int` | 범위 지정 Peek |
| `PeekRange(floatP, floatP, bool)` | `floatP` | 범위 지정 Peek |
| `Range(int min, int max, bool maxInclusive=false)` | `int` | 범위 난수 |
| `Range(floatP min, floatP max, bool maxInclusive=true)` | `floatP` | 범위 난수 |
| `Restore(int count)` | `void` | 상태 복원 |

### class RngService : IRngService

D.E. Knuth의 감법 난수 생성기 기반. 상태 길이 56.

**정적 메서드**:
- `CreateRngData(int seed)` - RngData 생성
- `GenerateRngState(int seed)` - 초기 상태 생성
- `CopyRngState(int[] state)` - 상태 복사
- `Restore(int count, int seed)` - 정적 복원
- `Range(int, int, int[], bool)` / `Range(floatP, floatP, int[], bool)` - 정적 범위 난수

---

## 커맨드 서비스

### interface IGameCommandBase

커맨드 마커 인터페이스.

### interface IGameServerCommand\<in TGameLogic\> : IGameCommandBase

서버 전용 커맨드.
- `ExecuteLogic(TGameLogic gameLogic)` - 로직 실행

### interface IGameCommand\<in TGameLogic\> : IGameCommandBase

게임 커맨드.
- `Execute(TGameLogic gameLogic, IMessageBrokerService messageBroker)` - 로직 실행 + 메시지 발행

### interface ICommandService\<out TGameLogic\>

- `ExecuteCommand<TCommand>(TCommand command)` - 커맨드 실행

### class CommandService\<TGameLogic\> : ICommandService\<TGameLogic\>

- 생성자: `CommandService(TGameLogic gameLogic, IMessageBrokerService messageBroker)`
- protected 멤버: `GameLogic`, `MessageBroker`

---

## 버전 서비스

### static class VersionServices

| 멤버 | 타입 | 설명 |
|------|------|------|
| `VersionDataFilename` | `const string` | "version-data" |
| `VersionExternal` | `string` | Application.version (M.m.p) |
| `VersionInternal` | `string` | M.m.p-b.branch.commit[.buildType] |
| `Branch` | `string` | Git 브랜치 |
| `Commit` | `string` | Git 커밋 해시 |
| `BuildNumber` | `string` | 빌드 번호 |

**메서드**:
- `LoadVersionDataAsync()` - Resources에서 비동기 로드 (앱 시작 시 1회)
- `IsOutdatedVersion(string version)` - M.m.p 버전 비교
- `FormatInternalVersion(VersionData data)` - 내부 버전 문자열 포맷

### struct VersionData (Serializable)

- `string CommitHash`, `string BranchName`, `string BuildType`, `string BuildNumber`
