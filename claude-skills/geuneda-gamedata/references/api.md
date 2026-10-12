# Geuneda GameData - API Reference

`com.geuneda.gamedata` 의 공개 API. 런타임 타입은 모두 네임스페이스 `Geuneda.DataExtensions` (어셈블리 `Geuneda.GameData`)에 있다. 에디터 API 는 마지막 절을 본다.

`IComputedDependency`, `IComputedFieldInternal`, `ComputedTracker`, `SerializedConfigs` 는 internal 이라 사용자 코드에서 쓸 수 없다.

## Observable

### IObservableFieldReader<out T>

| 멤버 | 설명 |
|------|------|
| `T Value { get; }` | 현재 값 |
| `IDisposable BeginBatch()` | 자기 자신만 담은 `ObservableBatch` 반환 |
| `void Observe(Action<T, T> onUpdate)` | 변경 콜백 등록 (이전 값, 현재 값) |
| `void InvokeObserve(Action<T, T> onUpdate)` | `onUpdate(Value, Value)` 를 한 번 호출한 뒤 등록 |
| `void StopObserving(Action<T, T> onUpdate)` | 콜백 해제 |
| `void StopObservingAll(object subscriber = null)` | `subscriber` 가 콜백 `Target` 인 것만 해제, null 이면 전부 해제 |
| `void InvokeUpdate()` | 현재 값으로 모든 옵저버 호출 |

### IObservableField<T> : IObservableFieldReader<T>

| 멤버 | 설명 |
|------|------|
| `new T Value { get; set; }` | 값 읽기/쓰기 |
| `void Rebind(T initialValue)` | 옵저버를 유지하고 통지 없이 값 교체 |

### ObservableField<T> : IObservableField<T>, IBatchable

| 멤버 | 설명 |
|------|------|
| `ObservableField()` / `ObservableField(T initialValue)` | 생성자 |
| `virtual T Value { get; set; }` | setter 는 값이 같아도 항상 통지 |
| `static implicit operator T(ObservableField<T>)` | 값으로 암시적 변환 |
| `protected virtual T GetCurrentValue()` | 파생 클래스용 |
| `protected void InvokeUpdate(T previousValue)` | 파생 클래스용 |

나머지 멤버는 인터페이스와 같다. `IBatchable` 은 명시적 구현이다.

### ObservableField (정적 팩토리)

| 멤버 | 설명 |
|------|------|
| `static ComputedField<T> Computed<T>(Func<T> computation)` | `new ComputedField<T>(computation)` |
| `static ComputedField<TResult> Combine<T1, T2, TResult>(IObservableFieldReader<T1>, IObservableFieldReader<T2>, Func<T1, T2, TResult>)` | 2개 결합 (3개, 4개 오버로드 있음) |

### ComputedField<T> : IObservableFieldReader<T>, IDisposable, IBatchable

| 멤버 | 설명 |
|------|------|
| `ComputedField(Func<T> computation)` | 계산 함수 안에서 읽은 Observable 을 의존성으로 자동 등록 |
| `T Value { get; }` | dirty 이면 다시 계산 후 반환 (lazy) |
| `void Observe(Action<T, T>)` | 등록 전에 필요하면 계산해 의존성을 잡는다 |
| `void InvokeUpdate()` | 강제로 다시 계산하고 통지 |
| `void Dispose()` | 의존성 구독, 옵저버 모두 해제 |

`BeginBatch`, `InvokeObserve`, `StopObserving`, `StopObservingAll` 은 인터페이스와 같다.

### ObservableExtensions

| 메서드 | 설명 |
|--------|------|
| `ComputedField<TResult> Select<T, TResult>(this IObservableFieldReader<T>, Func<T, TResult>)` | 값 변환 |
| `ComputedField<TResult> CombineWith<T1, T2, TResult>(this IObservableFieldReader<T1>, IObservableFieldReader<T2>, Func<T1, T2, TResult>)` | 2개 결합 |
| `CombineWith<T1, T2, T3, TResult>(...)`, `CombineWith<T1, T2, T3, T4, TResult>(...)` | 3개, 4개 결합 |

---

### IObservableListReader : IEnumerable

| 멤버 | 설명 |
|------|------|
| `int Count { get; }` | 요소 수 |

### IObservableListReader<T> : IObservableListReader, IEnumerable<T>

| 멤버 | 설명 |
|------|------|
| `T this[int index] { get; }` | 인덱서 |
| `IDisposable BeginBatch()` | 배치 시작 |
| `IReadOnlyList<T> ReadOnlyList { get; }` | 호출마다 새 `List<T>` 복사본 |
| `bool Contains(T value)` / `int IndexOf(T value)` | 조회 |
| `void Observe(Action<int, T, T, ObservableUpdateType> onUpdate)` | (인덱스, 이전 값, 현재 값, 종류) |
| `void InvokeObserve(int index, Action<int, T, T, ObservableUpdateType> onUpdate)` | 등록 후 `InvokeUpdate(index)` (모든 옵저버에 통지) |
| `void StopObserving(Action<int, T, T, ObservableUpdateType> onUpdate)` | 콜백 해제 |
| `void StopObservingAll(object subscriber = null)` | 구독자별 또는 전체 해제 |

### IObservableList<T> : IObservableListReader<T>

| 멤버 | 설명 |
|------|------|
| `new T this[int index] { get; set; }` | setter 는 `Updated` 통지 |
| `void Add(T data)` | `Added` 통지 |
| `bool Remove(T data)` | 있으면 `RemoveAt` 과 같이 `Removed` 통지 |
| `void RemoveAt(int index)` | `Removed` 통지 |
| `void Clear()` | 요소마다 `Removed` 통지 후 비움 |
| `void InvokeUpdate(int index)` | 해당 인덱스의 `Updated` 를 모든 옵저버에 통지 |

### ObservableList<T> : IObservableList<T>, IBatchable

| 멤버 | 설명 |
|------|------|
| `ObservableList(IList<T> list)` | `List<T>` 면 그 인스턴스를 그대로 감싸고, 아니면 복사 |
| `protected ObservableList()` | 파생 클래스용 |
| `protected virtual List<T> List { get; set; }` | 내부 리스트 |
| `void Rebind(IList<T> list)` | 옵저버를 유지하고 통지 없이 내부 리스트 교체 |
| `List<T>.Enumerator GetEnumerator()` | 구조체 열거자 |
| `virtual void Add(T)`, `virtual void RemoveAt(int)`, `virtual void Clear()` | 재정의 가능 |
| `protected void InvokeUpdate(int index, T previousValue)` | 파생 클래스용 |

---

### IObservableDictionary : IEnumerable

| 멤버 | 설명 |
|------|------|
| `int Count { get; }` | 요소 수 |
| `ObservableUpdateFlag ObservableUpdateFlag { get; set; }` | 통지 대상 구성. `ObservableDictionary` 생성자 기본값 `KeyUpdateOnly` |
| `IDisposable BeginBatch()` | 배치 시작 |

### IObservableDictionaryReader<TKey, TValue> : IObservableDictionary, IEnumerable<KeyValuePair<TKey, TValue>>

| 멤버 | 설명 |
|------|------|
| `TValue this[TKey key] { get; }` | 인덱서 |
| `ReadOnlyDictionary<TKey, TValue> ReadOnlyDictionary { get; }` | 호출마다 새 래퍼 |
| `bool TryGetValue(TKey key, out TValue value)` / `bool ContainsKey(TKey key)` | 조회 |
| `void Observe(Action<TKey, TValue, TValue, ObservableUpdateType> onUpdate)` | 전체 구독. 플래그가 `KeyUpdateOnly` 면 호출되지 않음 |
| `void Observe(TKey key, Action<TKey, TValue, TValue, ObservableUpdateType> onUpdate)` | 키 구독. 플래그가 `UpdateOnly` 면 호출되지 않음 |
| `void InvokeObserve(TKey key, Action<...> onUpdate)` | 키 구독 후 `InvokeUpdate(key)` |
| `void StopObserving(Action<...> onUpdate)` | 전체/키 구독에서 해당 콜백 해제 |
| `void StopObserving(TKey key)` | 그 키의 구독 전부 해제 |
| `void StopObservingAll(object subscriber = null)` | 구독자별 또는 전체 해제 |

### IObservableDictionary<TKey, TValue> : IObservableDictionaryReader<TKey, TValue>

| 멤버 | 설명 |
|------|------|
| `new TValue this[TKey key] { get; set; }` | setter 는 기존 키만 가능(없으면 `KeyNotFoundException`), `Updated` 통지 |
| `void Add(TKey key, TValue value)` | `Added` 통지 |
| `bool Remove(TKey key)` | 없으면 false, 있으면 `Removed` 통지 |
| `void Clear()` | 요소마다 `Removed` 통지 후 비움 |
| `void InvokeUpdate(TKey key)` | 해당 키 `Updated` 통지 |

### ObservableDictionary<TKey, TValue> : IObservableDictionary<TKey, TValue>, IBatchable

| 멤버 | 설명 |
|------|------|
| `ObservableDictionary(IDictionary<TKey, TValue> dictionary)` | 전달한 딕셔너리를 그대로 감싼다 |
| `protected virtual IDictionary<TKey, TValue> Dictionary { get; set; }` | 내부 딕셔너리 |
| `void Rebind(IDictionary<TKey, TValue> dictionary)` | 통지 없이 내부 딕셔너리 교체 |
| `virtual void Add(...)`, `virtual bool Remove(...)`, `virtual void Clear()` | 재정의 가능 |
| `protected void InvokeUpdate(TKey key, TValue previousValue)` | 파생 클래스용 |

---

### IObservableHashSetReader<T> : IEnumerable<T>

| 멤버 | 설명 |
|------|------|
| `int Count { get; }` | 요소 수 |
| `IDisposable BeginBatch()` | 배치 시작 |
| `bool Contains(T item)` | 포함 여부 |
| `void Observe(Action<T, ObservableUpdateType> onUpdate)` | (항목, 종류) |
| `void StopObserving(Action<T, ObservableUpdateType> onUpdate)` | 콜백 해제 |
| `void StopObservingAll(object subscriber = null)` | 구독자별 또는 전체 해제 |

### IObservableHashSet<T> : IObservableHashSetReader<T>

| 멤버 | 설명 |
|------|------|
| `bool Add(T item)` | 새로 추가되면 `Added` 통지 후 true |
| `bool Remove(T item)` | 제거되면 `Removed` 통지 후 true |
| `void Clear()` | 항목마다 `Removed` 통지 후 비움 |

### ObservableHashSet<T> : IObservableHashSet<T>, IBatchable

| 멤버 | 설명 |
|------|------|
| `ObservableHashSet()` | 빈 셋 |
| `ObservableHashSet(IEnumerable<T> collection)` | 복사해서 생성 |
| `ObservableHashSet(IEqualityComparer<T> comparer)` | 비교자 지정 |

---

### ObservableUpdateType / ObservableUpdateFlag

```csharp
public enum ObservableUpdateType { Added, Updated, Removed }

public enum ObservableUpdateFlag
{
    UpdateOnly,     // 키 없이 Observe 한 구독자만
    KeyUpdateOnly,  // 키를 지정해 Observe 한 구독자만 (ObservableDictionary 기본값)
    Both            // 둘 다 (비용 큼)
}
```

### IBatchable

| 멤버 | 설명 |
|------|------|
| `void SuppressNotifications()` | 통지 보류 시작 |
| `void ResumeNotifications()` | 보류 종료 후 통지 |

Observable 타입과 `ComputedField` 는 이 인터페이스를 명시적으로 구현한다. 재개 시 `ObservableField` 는 (배치 전 값, 현재 값)으로 한 번, List/Dictionary 는 모든 요소에 대해 이전 값 `default` 의 `Updated`, HashSet 은 모든 항목에 `Added` 를 통지한다.

### ObservableBatch : IDisposable

| 멤버 | 설명 |
|------|------|
| `void Add(IBatchable observable)` | 추가 즉시 통지 보류. Dispose 이후 호출하면 `ObjectDisposedException` |
| `void Dispose()` | 추가된 순서대로 `ResumeNotifications` 호출 |

---

### IObservableResolverField<T> : IObservableField<T>

| 멤버 | 설명 |
|------|------|
| `void Rebind(Func<T> fieldResolver, Action<T> fieldSetter)` | 옵저버를 유지하고 getter/setter 교체 |

### ObservableResolverField<T> : ObservableField<T>, IObservableResolverField<T>

| 멤버 | 설명 |
|------|------|
| `ObservableResolverField(Func<T> fieldResolver, Action<T> fieldSetter)` | 생성자 |
| `override T Value { get; set; }` | getter 는 `fieldResolver()`, setter 는 `fieldSetter(value)` 후 통지 |
| `static implicit operator T(ObservableResolverField<T>)` | 암시적 변환 |

### IObservableResolverListReader<T, out TOrigin> : IObservableListReader<T>

| 멤버 | 설명 |
|------|------|
| `IReadOnlyList<TOrigin> OriginList { get; }` | 원본 리스트 복사본 |

### IObservableResolverList<T, TOrigin> : IObservableResolverListReader<T, TOrigin>, IObservableList<T>

| 멤버 | 설명 |
|------|------|
| `void UpdateOrigin(TOrigin value, int index)` | 원본 갱신 후 변환 값을 인덱서로 설정 (통지) |
| `void AddOrigin(TOrigin value)` | 원본에 추가 후 변환 값을 내부 리스트에 추가 (통지) |
| `bool RemoveOrigin(TOrigin value)` | 원본에서 `value` 의 위치를 찾아 원본과 내부 리스트의 같은 위치를 제거 (통지). 원본에 없으면 아무것도 바꾸지 않고 `false` |
| `void ClearOrigin()` | 원본과 내부 리스트 비움 |
| `void Rebind(IList<TOrigin> originList, Func<TOrigin, T> fromOrignResolver, Func<T, TOrigin> toOrignResolver)` | 원본과 변환 함수 교체, 내부 리스트 재구성 |

### ObservableResolverList<T, TOrigin> : ObservableList<T>, IObservableResolverList<T, TOrigin>

| 멤버 | 설명 |
|------|------|
| `ObservableResolverList(IList<TOrigin> originList, Func<TOrigin, T> fromOrignResolver, Func<T, TOrigin> toOrignResolver)` | 원본을 변환해 내부 리스트 생성 |

`Add`, `RemoveAt`, `Clear`, 인덱서 setter 는 원본 리스트에도 반영한다(인덱서는 1.0.4 부터. `ObservableList` 인덱서가 virtual 로 바뀜).

### IObservableResolverDictionaryReader<TKey, TValue, TKeyOrigin, TValueOrigin> : IObservableDictionaryReader<TKey, TValue>

| 멤버 | 설명 |
|------|------|
| `ReadOnlyDictionary<TKeyOrigin, TValueOrigin> OriginDictionary { get; }` | 원본 딕셔너리 래퍼 |
| `TValueOrigin GetOriginValue(TKey key)` | 원본 값 조회 |
| `bool TryGetOriginValue(TKey key, out TValueOrigin value)` | 원본 값 조회 시도 |

### IObservableResolverDictionary<TKey, TValue, TKeyOrigin, TValueOrigin>

`IObservableResolverDictionaryReader<...>`, `IObservableDictionary<TKey, TValue>` 상속.

| 멤버 | 설명 |
|------|------|
| `void UpdateOrigin(TKeyOrigin key, TValueOrigin value)` | 원본 갱신 후 변환 값을 인덱서로 설정 (통지) |
| `void AddOrigin(TKeyOrigin key, TValueOrigin value)` | 원본에 추가 후 변환 값 `Add` (통지) |
| `bool RemoveOrigin(TKeyOrigin key)` | 원본에서 제거 후 변환 키 `Remove` |
| `void ClearOrigin()` | 원본과 내부 딕셔너리 비움 |
| `void Rebind(IDictionary<TKeyOrigin, TValueOrigin> dictionary, Func<KeyValuePair<TKeyOrigin, TValueOrigin>, KeyValuePair<TKey, TValue>> fromOrignResolver, Func<TKey, TValue, KeyValuePair<TKeyOrigin, TValueOrigin>> toOrignResolver)` | 원본과 변환 함수 교체 |

### ObservableResolverDictionary<TKey, TValue, TKeyOrigin, TValueOrigin> : ObservableDictionary<TKey, TValue>, IObservableResolverDictionary<...>

| 멤버 | 설명 |
|------|------|
| `ObservableResolverDictionary(IDictionary<TKeyOrigin, TValueOrigin> dictionary, Func<KeyValuePair<TKeyOrigin, TValueOrigin>, KeyValuePair<TKey, TValue>> fromOrignResolver, Func<TKey, TValue, KeyValuePair<TKeyOrigin, TValueOrigin>> toOrignResolver)` | 생성자 |

`Add`, `Remove`, `Clear`, 인덱서 setter 는 원본 딕셔너리에도 반영한다(인덱서는 1.0.4 부터. 없는 키는 원본을 바꾸지 않고 `KeyNotFoundException`).

### ObservableDebugRegistry (static)

Observable Debugger 창용 레지스트리. 멤버는 모두 `#if UNITY_EDITOR` 안에 있다. Observable 생성자가 자동 등록한다.

| 멤버 | 설명 |
|------|------|
| `static IEnumerable<EntrySnapshot> EnumerateSnapshots()` | 살아 있는 인스턴스 스냅샷 |
| `static EntrySnapshot? FindByInstance(object instance)` | 특정 인스턴스 스냅샷 |
| `struct EntrySnapshot` | `Id`, `Name`, `Kind`, `CreatedAt`, `FilePath`, `LineNumber`, `FileName`, `SourceLocation`, `Value`, `Subscribers`, `RuntimeType`, `InstanceRef` |

---

## 설정 (Config Services)

### IConfigsProvider

| 멤버 | 설명 |
|------|------|
| `ulong Version { get; }` | 설정 버전 |
| `bool TryGetConfig<T>(int id, out T config)` | ID 조회 시도. 타입이 등록되지 않았으면 `ConfigsProvider` 는 `KeyNotFoundException` |
| `bool TryGetConfig<T>(out T config)` | 싱글톤(키 0) 조회 시도. 타입이 없으면 false |
| `T GetConfig<T>()` | 싱글톤 조회. 없으면 `InvalidOperationException` |
| `T GetConfig<T>(int id)` | ID 조회. 없으면 `KeyNotFoundException` |
| `List<T> GetConfigsList<T>()` | 호출마다 새 `List<T>` |
| `IReadOnlyDictionary<int, T> GetConfigsDictionary<T>()` | 내부 딕셔너리 |
| `IEnumerable<T> EnumerateConfigs<T>()` | 복사 없이 값 열거 (foreach 시 열거자 박싱 1회) |
| `IEnumerable<KeyValuePair<int, T>> EnumerateConfigsWithIds<T>()` | ID 와 함께 열거 |
| `IReadOnlyDictionary<Type, IEnumerable> GetAllConfigs()` | 타입별 전체 설정 |

### IConfigsAdder : IConfigsProvider

| 멤버 | 설명 |
|------|------|
| `void AddSingletonConfig<T>(T config)` | 키 0 으로 저장. 같은 타입 재등록 시 `ArgumentException` |
| `void AddConfigs<T>(Func<T, int> referenceIdResolver, IList<T> configList)` | ID 리졸버로 등록. null 인자는 `ArgumentNullException`, 중복 ID/타입은 `ArgumentException` |
| `void AddAllConfigs(IReadOnlyDictionary<Type, IEnumerable> configs)` | 타입별로 덮어쓰기 |
| `void UpdateTo(ulong version, IReadOnlyDictionary<Type, IEnumerable> toUpdate)` | `AddAllConfigs` 후 버전 설정 |

### ConfigsProvider : IConfigsAdder

| 멤버 | 설명 |
|------|------|
| `ConfigsProvider()` | 에디터에서는 `ConfigsProviderDebugRegistry` 에 자동 등록 |
| `virtual IReadOnlyDictionary<int, T> GetConfigsDictionary<T>()` | 재정의 가능 |

나머지는 인터페이스와 같다. 버전 설정 메서드 `SetVersion(ulong)` 은 internal 이므로 `UpdateTo` 를 쓴다.

### IConfigsSerializer

| 멤버 | 설명 |
|------|------|
| `string Serialize(IConfigsProvider cfg, string version)` | 직렬화 |
| `T Deserialize<T>(string serialized) where T : IConfigsAdder` | 새 `T` 인스턴스를 만들어 역직렬화 |

### ConfigsSerializer : IConfigsSerializer

| 멤버 | 설명 |
|------|------|
| `const int DefaultMaxDepth = 128` | 기본 JSON 최대 깊이 |
| `ConfigsSerializer(SerializationSecurityMode mode = SerializationSecurityMode.TrustedOnly, int maxDepth = DefaultMaxDepth)` | 생성자 |
| `SerializationSecurityMode SecurityMode { get; }` | 보안 모드 |
| `string Serialize(IConfigsProvider cfg, string version)` | `[IgnoreServerSerialization]` 타입은 건너뛰고, `[Serializable]` 이 아닌 타입은 예외. `TrustedOnly` 면 직렬화한 타입을 허용 목록에 추가 |
| `void RegisterAllowedTypes(IEnumerable<Type> types)` | 허용 타입 등록 (`TrustedOnly` 에서만 동작) |
| `void RegisterAllowedTypesFromProvider(IConfigsProvider provider)` | 프로바이더의 타입을 허용 목록에 등록 (`TrustedOnly` 에서만 동작) |
| `T Deserialize<T>(string serialized) where T : IConfigsAdder` | `Activator.CreateInstance` 로 만든 인스턴스에 로드 |
| `void Deserialize(string serialized, IConfigsAdder cfg)` | `cfg.UpdateTo(version, configs)` 호출. 버전 문자열이 숫자가 아니면 0 |

사용하는 JSON 컨버터: `StringEnumConverter`, `ColorJsonConverter`, `Vector2JsonConverter`, `Vector3JsonConverter`, `Vector4JsonConverter`, `QuaternionJsonConverter`.

### SerializationSecurityMode

```csharp
public enum SerializationSecurityMode
{
    TrustedOnly, // 기본. TypeNameHandling.Auto + ConfigTypesBinder 화이트리스트
    Secure       // TypeNameHandling.None. 역직렬화 왕복 불가, 직렬화 전용
}
```

### IgnoreServerSerialization : Attribute

클래스/구조체에 붙이면 `ConfigsSerializer.Serialize` 가 그 타입을 건너뛴다.

### ConfigTypesBinder : ISerializationBinder

| 멤버 | 설명 |
|------|------|
| `ConfigTypesBinder(IEnumerable<Type> allowedConfigTypes)` | 기본 내장 타입(기본형, `List<>`, `Dictionary<,>`, `HashSet<>` 등) + 지정 타입 허용. null 가능 |
| `static ConfigTypesBinder FromProvider(IConfigsProvider provider)` | 프로바이더 타입과 `Dictionary<int, T>` 허용 |
| `void AddAllowedType(Type type)` | 허용 타입 추가 (제네릭 인자도 함께 추가) |
| `Type BindToType(string assemblyName, string typeName)` | 허용되지 않은 타입이면 `JsonSerializationException` |
| `void BindToName(Type serializedType, out string assemblyName, out string typeName)` | 표준 이름 사용 |

### IConfigBackendService

| 멤버 | 설명 |
|------|------|
| `UniTask<ulong> GetRemoteVersion()` | 원격 설정 버전 |
| `UniTask<IConfigsProvider> FetchRemoteConfiguration(ulong version)` | 해당 버전 설정 가져오기 |

구현체는 패키지에 없다.

### 설정 컨테이너 인터페이스

| 타입 | 멤버 |
|------|------|
| `IConfig` | `int ConfigId { get; }` |
| `IConfigsContainer<T>` | `List<T> Configs { get; set; }` |
| `ISingleConfigContainer<T>` | `T Config { get; set; }` |
| `IPairConfigsContainer<TKey, TValue> : IConfigsContainer<Pair<TKey, TValue>>` | - |
| `IStructPairConfigsContainer<TKey, TValue> : IConfigsContainer<StructPair<TKey, TValue>>` | `TKey`, `TValue` 모두 `struct` 제약 |

### ConfigsScriptableObject<TId, TAsset> (abstract)

`ScriptableObject`, `IPairConfigsContainer<TId, TAsset>`, `ISerializationCallbackReceiver` 구현.

| 멤버 | 설명 |
|------|------|
| `List<Pair<TId, TAsset>> Configs { get; set; }` | 인스펙터에서 편집하는 목록 |
| `IReadOnlyDictionary<TId, TAsset> ConfigsDictionary { get; }` | `OnAfterDeserialize` 에서 생성. 중복 키는 에러 로그 후 건너뜀 |
| `void OnBeforeSerialize()` | 동작 없음 |
| `virtual void OnAfterDeserialize()` | `ConfigsDictionary` 재구성 |

### ConfigsProviderDebugRegistry (static)

Config Browser 용 레지스트리. 멤버는 모두 `#if UNITY_EDITOR` 안에 있다.

| 멤버 | 설명 |
|------|------|
| `static IEnumerable<ProviderSnapshot> EnumerateSnapshots()` | 살아 있는 프로바이더 스냅샷 |
| `struct ProviderSnapshot` | `Id`, `Name`, `CreatedAt`, `FilePath`, `LineNumber`, `FileName`, `SourceLocation`, `ConfigTypeCount`, `ProviderRef` |

---

## Math

### floatP : IEquatable<floatP>, IComparable<floatP>, IComparable, IFormattable

IEEE binary32 와 같은 비트 표현을 쓰고 연산을 소프트웨어로 구현한 결정론적 부동소수점.

| 멤버 | 설명 |
|------|------|
| `static floatP FromRaw(uint raw)` | 원시 비트로 생성 |
| `uint RawValue { get; }` | 원시 비트 |
| `static floatP FromParts(bool sign, uint exponent, uint mantissa)` | 부호/지수/가수로 생성 |
| `static floatP FromIeeeRaw(uint ieeeRaw)` / `uint ToIeeeRaw()` | IEEE 원시값 변환 |
| `Zero`, `One`, `MinusOne`, `MaxValue`, `MinValue`, `Epsilon`, `NaN`, `PositiveInfinity`, `NegativeInfinity` | 정적 프로퍼티 |
| 단항 `-`, 이항 `+ - * / %` | 산술 (`%` 는 `MathfloatP.Mod`) |
| `== != < > <= >=` | 비교 (NaN 이 끼면 순서 비교는 false) |
| `implicit float -> floatP`, `implicit floatP -> float` | 비트 재해석 |
| `implicit int -> floatP`, `implicit floatP -> int` | int 변환 (소수부 버림) |
| `IsNaN()`, `IsInfinity()`, `IsPositiveInfinity()`, `IsNegativeInfinity()`, `IsFinite()`, `IsZero()`, `IsPositive()`, `IsNegative()` | 인스턴스 검사 |
| `static IsNaN(floatP)`, `static IsInfinity(floatP)`, `static IsNegativeInfinity(floatP)`, `static IsFinite(floatP)` | 정적 검사 |
| `int Sign()` / `static int Sign(floatP)` | 부호 (-1, 0, 1) |
| `CompareTo(floatP)`, `CompareTo(object)`, `Equals(floatP)`, `Equals(object)`, `GetHashCode()` | 비교/동등 |
| `ToString()`, `ToString(string)`, `ToString(IFormatProvider)`, `ToString(string, IFormatProvider)`, `ToStringInv()` | 문자열 (float 로 변환해 포맷) |

### MathfloatP (static)

| 분류 | 메서드 |
|------|--------|
| 기본 | `Abs(x)`, `Max(a, b)`, `Min(a, b)`, `Clamp(value, min, max)`, `Clamp01(value)`, `int Sign(x)` |
| 보간 | `Lerp(a, b, t)` (t 를 0~1 로 제한), `LerpUnclamped(a, b, t)`, `SmoothStep(from, to, t)`, `InverseLerp(a, b, value)`, `MoveTowards(current, target, maxDelta)` |
| 각도 (도 단위) | `DeltaAngle(current, target)`, `LerpAngle(a, b, t)`, `MoveTowardsAngle(current, target, maxDelta)` |
| 반복/비교 | `Repeat(t, length)`, `PingPong(t, length)`, `bool Approximately(a, b)` |
| 나머지 | `Mod(x, y)`, `IEEERemainder(x, y)`, `int DivRem(floatP x, floatP y, out floatP remainder, out int quotient)` |
| 반올림 | `Round(x)`, `Floor(x)`, `Ceil(x)`, `Truncate(x)` |
| 거듭제곱/로그 | `Sqrt(x)`, `Exp(x)`, `Pow(x, y)`, `Pow2(x)` (x 의 제곱), `Log(x)`, `Log(x, e)` (밑 e), `Log2(x)`, `Log10(x)` |
| 삼각 (라디안) | `Sin(x)`, `Cos(x)`, `Tan(x)`, `Asin(x)`, `Acos(x)`, `Atan(x)`, `Atan2(y, x)` |
| 기타 | `Hypothenuse(x, y)`, `ScaleB(x, int n)`, `long RawDistance(f1, f2)` |

반환 타입은 따로 적은 것 외에 모두 `floatP` 다. π 상수(`RawPi` 등)는 private 이다.

---

## Serialization

### UnitySerializedDictionary<TKey, TValue> (abstract)

`Dictionary<TKey, TValue>`, `ISerializationCallbackReceiver` (명시적 구현). 키/값을 두 리스트로 직렬화한다. Unity 가 제네릭 타입을 직접 직렬화하지 못하므로 `[Serializable]` 구체 클래스를 선언해 쓴다.

### Pair<TKey, TValue> (class), StructPair<TKey, TValue> (struct)

`[Serializable]`. 공개 필드 `Key`, `Value` 와 생성자 `(TKey key, TValue value)`. `StructPair` 는 `TKey`, `TValue` 모두 `struct` 제약.

### SerializableType<T> (struct)

`System.Type` 을 인스펙터에 저장하는 래퍼. `IEquatable<SerializableType<T>>`, `IEquatable<Type>`, `ISerializationCallbackReceiver`.

| 멤버 | 설명 |
|------|------|
| `SerializableType(Type type)` | 생성자 |
| `Type Value { get; set; }` | `T` 에 할당 가능하지 않은 타입을 넣으면 `typeof(T)` 로 저장 |
| `string AssemblyName { get; }`, `string ClassName { get; }` | 저장된 이름 |
| `implicit operator Type(SerializableType<T>)`, `implicit operator SerializableType<T>(Type)` | 암시적 변환 |

### 벡터 직렬화 구조체

| 타입 | 변환 |
|------|------|
| `Vector2Serializable` | `Vector2` 와 양방향 암시적 변환 |
| `Vector3Serializable` | `Vector3` 와 양방향 |
| `Vector4Serializable` | `Vector4`, `Quaternion` 과 양방향 |
| `Vector2IntSerializable` | `Vector2Int` 와 양방향 |
| `Vector3IntSerializable` | `Vector3Int` 와 양방향 |
| `Vector4Int` | 정수 4성분 (`x`, `y`, `z`, `w`), 변환 연산자 없음 |

### JSON 컨버터 (Newtonsoft.Json)

`ColorJsonConverter` (`JsonConverter<Color>`), `Vector2JsonConverter`, `Vector3JsonConverter`, `Vector4JsonConverter`, `QuaternionJsonConverter`.

---

## Utilities

### IEnumSelector

| 멤버 | 설명 |
|------|------|
| `int GetSelectedIndex()` | `EnumValues` 내 인덱스, 잘못된 이름이면 에러 로그 후 -1 |
| `bool HasValidSelection()` | 인덱스가 -1 이 아닌지 |
| `string GetSelectionString()` | 저장된 enum 이름 |

### EnumSelector<T> : IEnumSelector where T : Enum

`[Serializable]`. 저장 필드 `_selection` 은 `HideInInspector`.

| 멤버 | 설명 |
|------|------|
| `protected EnumSelector(T data)` | 하위 클래스용 생성자 (매개변수 없는 생성자는 private) |
| `static readonly string[] EnumNames` | enum 이름 |
| `static readonly T[] EnumValues` | enum 값 |
| `static readonly Dictionary<string, T> EnumDictionary` | 이름 → 값 (대소문자 무시) |
| `T GetSelection()` | 선택 값. 잘못된 이름이면 `EnumValues[0]` |
| `void SetSelection(T data)` | 선택 설정 |
| `static implicit operator T(EnumSelector<T>)` | 암시적 변환 |

---

## Extensions

### ObjectExtensions (static)

| 멤버 | 설명 |
|------|------|
| `enum ObjectDisposeResult { None, Pooled, Destroyed }` | 중첩 enum |
| `ObjectDisposeResult Dispose(this GameObject gameObject, bool forceDestroy)` | 플레이 중 `Destroy`, 아니면 `DestroyImmediate` |
| `ObjectDisposeResult Dispose(this Object o, bool forceDestroy)` | `IDisposable` 이면 `Dispose` 후 파괴 |
| `T GetOrAddComponent<T>(this GameObject) where T : Component` | 가져오거나 추가 |
| `Component GetOrAddComponent(this GameObject, SerializableType<Component> type)` | 타입 지정 버전 |
| `bool HasComponent<T>(this GameObject)`, `bool HasComponent(this GameObject, Type)` | 컴포넌트 보유 여부 |
| `bool IsPersistent(this GameObject)` | DontDestroyOnLoad 씬 여부 |
| `T GetValid<T>(this T o)`, `bool IsValid(this object o)`, `bool TryGetValid<T>(this T o, out T valid)` | 파괴된 Unity 오브젝트를 null 로 취급 |
| `string GetDisplayString(this Type type)` | 제네릭 인자와 네임스페이스를 포함한 표시 이름 |

`forceDestroy` 인자는 현재 구현에서 사용되지 않는다.

### ReflectionExtensions (static)

`object CreateInstance(this Type)`, `bool CanCreateInstance(this Type)`, `bool TryCreateInstance<T>(this Type, out T)`, `FieldInfo? FindFieldByName(this Type, in string)`, `MethodInfo? FindMethodByName(this Type, in string)`, `MethodInfo? FindMethodBySignature(this Type, in string, params Type[])`, `MethodInfo? FindSetterByName(this Type, in string)`.

### SortedListExtensions (static)

이미 정렬된 리스트에 정렬을 유지하며 삽입한다. `InsertIntoSortedList<T>(this IList<T>, T) where T : IComparable<T>`, `InsertIntoSortedList<T>(this IList<T>, T, Comparison<T>)`, `InsertIntoSortedList<T>(this IList<T>, T, IComparer<T>)`, `InsertIntoSortedList(this IList, IComparable)`, `InsertIntoSortedList(this IList, IComparable, Comparison<IComparable>)`.

### UnityObjectsExtensions (static)

`Vector3[] GetLocalCornersArray(this RectTransform)`, `Vector3[] GetWorldCornersArray(this RectTransform)`, `bool RaycastPoint(this GraphicRaycaster, Vector2 screenPoint, out List<RaycastResult> results)`.

---

## Validation Attributes

| 타입 | 설명 |
|------|------|
| `abstract class ValidationAttribute : Attribute` | 필드/프로퍼티 대상. `abstract bool IsValid(object value, out string message)` |
| `RequiredAttribute` | null 또는 빈 문자열이면 실패 |
| `RangeAttribute(double min, double max)` | 숫자로 변환해 범위 검사. null 은 통과. `UnityEngine.RangeAttribute` 와 이름 충돌 주의 |
| `MinLengthAttribute(int minLength)` | 문자열/컬렉션 길이 검사. null 은 `minLength > 0` 이면 실패 |
| `ReadOnlyAttribute : PropertyAttribute` | 인스펙터 읽기 전용 표시 (`ValidationAttribute` 아님) |

---

## Editor API

어셈블리 `Geuneda.GameData.Editor`. 에디터 전용이다.

### 네임스페이스 GeunedaEditor.GameData

| 타입 | 주요 멤버 |
|------|-----------|
| `interface IConfigMigration` | `ulong FromVersion { get; }`, `ulong ToVersion { get; }`, `void Migrate(JObject configJson)` |
| `ConfigMigrationAttribute(Type configType)` | 클래스 대상, `AllowMultiple = true`. `Type ConfigType { get; }`. 버전 인자는 없다 |
| `static class MigrationRunner` | `Initialize(bool force = false)`, `IReadOnlyCollection<Type> GetConfigTypesWithMigrations()`, `IReadOnlyList<MigrationInfo> GetAvailableMigrations<T>()`, `GetAvailableMigrations(Type)`, `ulong GetLatestVersion(Type)`, `int Migrate(Type configType, JObject configJson, ulong currentVersion, ulong targetVersion)`, `MigrationResult MigrateScriptableObject<T>(T scriptableObject, Type configType, ulong fromVersion, ulong toVersion = 0) where T : ScriptableObject` |
| `readonly struct MigrationInfo` | `ConfigType`, `FromVersion`, `ToVersion`, `MigrationType` |
| `readonly struct MigrationResult` | `Success`, `Message`, `MigrationsApplied`, `static Ok(int)`, `static NoMigrations()`, `static Error(string)` |
| `static class EditorConfigValidator` | `ValidationResult ValidateAll(IConfigsProvider provider)`, `ValidationResult Validate<T>(IConfigsProvider provider)` |
| `class ValidationResult` | `bool IsValid`, `List<ValidationError> Errors`, `List<ValidConfig> ValidConfigs` |
| `class ValidationError` | `ConfigType`, `int? ConfigId`, `FieldName`, `Message` |
| `class ValidConfig` | `ConfigType`, `int? ConfigId` |
| `abstract class EnumSelectorPropertyDrawer<T> : PropertyDrawer where T : Enum` | `EnumSelector<T>` 하위 클래스용 드로어 기반. UI Toolkit/IMGUI 모두 지원, 이름 알파벳순 드롭다운 |
| `class ReadOnlyPropertyDrawer` | `[ReadOnly]` 드로어 |

`MigrationRunner.Migrate` 는 `FromVersion >= currentVersion` 이고 `ToVersion <= targetVersion` 인 마이그레이션을 `FromVersion` 순으로 모두 적용한다.

### 네임스페이스 Geuneda.DataExtensions.Editor

| 타입 | 설명 |
|------|------|
| `ConfigBrowserWindow` | `Tools > Game Data > Config Browser`. `static ShowWindow()` |
| `ObservableDebugWindow` | `Tools > Game Data > Observable Debugger`. `static ShowWindow()` |
| `ConfigsScriptableObjectInspector` | `ConfigsScriptableObject<,>` 파생 에셋 인스펙터 (중복 키/유효성 상태, Validate All) |
| `JsonViewerElement`, `ValidationErrorElement`, `MigrationPanelElement`, `DependencyGraphElement` | 창에서 쓰는 UI Toolkit 요소 |
