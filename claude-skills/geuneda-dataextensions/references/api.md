# Geuneda Data Extensions - API Reference

네임스페이스: `Geuneda.DataExtensions`

## Observable 데이터 타입

### IObservableFieldReader<T>
읽기 전용 Observable 필드 인터페이스.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| Value | `T Value { get; }` | 현재 값 |
| BeginBatch | `ObservableBatch BeginBatch()` | 일괄 업데이트 시작 |
| Observe | `void Observe(Action<T, T> action)` | 변경 콜백 등록 (prev, curr) |
| InvokeObserve | `void InvokeObserve()` | 현재 값으로 모든 옵저버 강제 호출 |
| StopObserving | `void StopObserving(Action<T, T> action)` | 특정 콜백 해제 |
| StopObservingAll | `void StopObservingAll()` | 모든 콜백 해제 |
| InvokeUpdate | `void InvokeUpdate(T previousValue)` | 업데이트 강제 발생 |

### IObservableField<T> : IObservableFieldReader<T>
읽기/쓰기 Observable 필드 인터페이스.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| Value | `new T Value { get; set; }` | 값 읽기/쓰기 |
| Rebind | `void Rebind(T value)` | 옵저버 통지 없이 값 교체 |

### ObservableField<T>
`IObservableField<T>`, `IBatchable`, `IComputedDependency` 구현.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| ObservableField | `ObservableField(T initialValue)` | 생성자 |
| ObservableField | `ObservableField(T initialValue, string debugName)` | 디버그 이름 지정 생성자 |
| Value | `T Value { get; set; }` | 값. 변경 시 옵저버 통지 |
| implicit operator T | `static implicit operator T(ObservableField<T> field)` | 암시적 T 변환 |
| BeginBatch | `ObservableBatch BeginBatch()` | 일괄 업데이트 |
| SuppressNotifications | `ObservableField<T> SuppressNotifications()` | 통지 억제 |
| ResumeNotifications | `ObservableField<T> ResumeNotifications()` | 통지 재개 |
| Subscribe | `IComputedDependency Subscribe(IComputedFieldInternal computed)` | ComputedField 의존성 등록 |
| Unsubscribe | `IComputedDependency Unsubscribe(IComputedFieldInternal computed)` | ComputedField 의존성 해제 |
| Rebind | `void Rebind(T value)` | 통지 없이 값 교체 |
| Observe | `void Observe(Action<T, T> action)` | 변경 콜백 등록 |
| InvokeObserve | `void InvokeObserve()` | 옵저버 강제 호출 |
| StopObserving | `void StopObserving(Action<T, T> action)` | 특정 콜백 해제 |
| StopObservingAll | `void StopObservingAll()` | 모든 콜백 및 의존성 해제 |
| InvokeUpdate | `void InvokeUpdate(T previousValue)` | 업데이트 강제 발생 |

---

### IObservableListReader<T>
읽기 전용 Observable 리스트 인터페이스.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| this[int] | `T this[int index] { get; }` | 인덱서 읽기 |
| Count | `int Count { get; }` | 요소 수 |
| ReadOnlyList | `IReadOnlyList<T> ReadOnlyList { get; }` | 읽기 전용 리스트 |
| Observe | `void Observe(Action<int, T, T, ObservableUpdateType>)` | 변경 콜백 |
| StopObserving | `void StopObserving(Action<int, T, T, ObservableUpdateType>)` | 콜백 해제 |
| StopObservingAll | `void StopObservingAll()` | 모든 콜백 해제 |
| InvokeObserve | `void InvokeObserve()` | 옵저버 강제 호출 |
| Contains | `bool Contains(T item)` | 포함 여부 |
| IndexOf | `int IndexOf(T item)` | 인덱스 반환 |
| BeginBatch | `ObservableBatch BeginBatch()` | 일괄 업데이트 |

### IObservableList<T> : IObservableListReader<T>
읽기/쓰기 Observable 리스트 인터페이스.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| this[int] | `new T this[int index] { get; set; }` | 인덱서 읽기/쓰기 |
| Add | `void Add(T value)` | 요소 추가 |
| Remove | `void Remove(T value)` | 요소 삭제 |
| RemoveAt | `void RemoveAt(int index)` | 인덱스로 삭제 |
| Clear | `void Clear()` | 전체 삭제 |
| InvokeUpdate | `void InvokeUpdate(int index, T previousValue)` | 업데이트 강제 |

### ObservableList<T>
`IObservableList<T>`, `IBatchable`, `IComputedDependency` 구현.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| ObservableList | `ObservableList(IList<T> list)` | 생성자 (기존 리스트 래핑) |
| ObservableList | `ObservableList(IList<T> list, string debugName)` | 디버그 이름 지정 생성자 |
| this[int] | `T this[int index] { get; set; }` | 인덱서 |
| Count | `int Count { get; }` | 요소 수 |
| List | `IList<T> List { get; }` | 내부 리스트 직접 접근 (주의) |
| ReadOnlyList | `IReadOnlyList<T> ReadOnlyList { get; }` | 읽기 전용 |
| Subscribe | `IComputedDependency Subscribe(IComputedFieldInternal)` | ComputedField 의존성 등록 |
| Unsubscribe | `IComputedDependency Unsubscribe(IComputedFieldInternal)` | 의존성 해제 |
| BeginBatch | `ObservableBatch BeginBatch()` | 일괄 업데이트 |
| SuppressNotifications | `ObservableList<T> SuppressNotifications()` | 통지 억제 |
| ResumeNotifications | `ObservableList<T> ResumeNotifications()` | 통지 재개 |
| Rebind | `void Rebind(IList<T> list)` | 통지 없이 내부 리스트 교체 |
| Add | `void Add(T value)` | 요소 추가 |
| Remove | `void Remove(T value)` | 요소 삭제 |
| RemoveAt | `void RemoveAt(int index)` | 인덱스로 삭제 |
| Clear | `void Clear()` | 전체 삭제 |
| Contains | `bool Contains(T item)` | 포함 여부 |
| IndexOf | `int IndexOf(T item)` | 인덱스 반환 |
| Observe | `void Observe(Action<int, T, T, ObservableUpdateType>)` | 변경 콜백 |
| InvokeObserve | `void InvokeObserve()` | 옵저버 강제 호출 |
| StopObserving | `void StopObserving(Action<int, T, T, ObservableUpdateType>)` | 콜백 해제 |
| StopObservingAll | `void StopObservingAll()` | 모든 콜백 및 의존성 해제 |
| InvokeUpdate | `void InvokeUpdate(int index, T previousValue)` | 업데이트 강제 |
| GetEnumerator | `IEnumerator<T> GetEnumerator()` | 열거자 |

---

### IObservableDictionary<TKey, TValue>
읽기/쓰기 Observable 딕셔너리 인터페이스.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| this[TKey] | `TValue this[TKey key] { get; set; }` | 인덱서 |
| Add | `void Add(TKey key, TValue value)` | 추가 |
| Remove | `void Remove(TKey key)` | 삭제 |
| Clear | `void Clear()` | 전체 삭제 |

### IObservableDictionaryReader<TKey, TValue>
읽기 전용 Observable 딕셔너리 인터페이스.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| Count | `int Count { get; }` | 요소 수 |
| ReadOnlyDictionary | `IReadOnlyDictionary<TKey, TValue> ReadOnlyDictionary { get; }` | 읽기 전용 |
| ContainsKey | `bool ContainsKey(TKey key)` | 키 존재 여부 |
| TryGetValue | `bool TryGetValue(TKey key, out TValue value)` | 값 조회 시도 |
| Observe | `void Observe(Action<TKey, TValue, TValue, ObservableUpdateType>)` | 전체 키 옵저빙 |
| Observe | `void Observe(TKey key, Action<TKey, TValue, TValue, ObservableUpdateType>)` | 특정 키 옵저빙 |
| StopObserving | `void StopObserving(Action<TKey, TValue, TValue, ObservableUpdateType>)` | 콜백 해제 |
| StopObserving | `void StopObserving(TKey key, ...)` | 특정 키 콜백 해제 |
| StopObservingAll | `void StopObservingAll()` | 모든 콜백 해제 |
| BeginBatch | `ObservableBatch BeginBatch()` | 일괄 업데이트 |

### ObservableDictionary<TKey, TValue>
`IObservableDictionary<TKey, TValue>`, `IObservableDictionaryReader<TKey, TValue>`, `IBatchable`, `IComputedDependency` 구현.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| ObservableDictionary | `ObservableDictionary(IDictionary<TKey, TValue> dict)` | 생성자 |
| ObservableDictionary | `ObservableDictionary(IDictionary<TKey, TValue> dict, string debugName)` | 디버그 이름 지정 생성자 |
| Count | `int Count { get; }` | 요소 수 |
| ObservableUpdateFlag | `ObservableUpdateFlag ObservableUpdateFlag { get; }` | 업데이트 플래그 |
| ReadOnlyDictionary | `IReadOnlyDictionary<TKey, TValue> ReadOnlyDictionary { get; }` | 읽기 전용 |
| Dictionary | `IDictionary<TKey, TValue> Dictionary { get; }` | 내부 딕셔너리 직접 접근 |
| Rebind | `void Rebind(IDictionary<TKey, TValue> dict)` | 통지 없이 교체 |
| this[TKey] | `TValue this[TKey key] { get; set; }` | 인덱서 |
| ContainsKey | `bool ContainsKey(TKey key)` | 키 존재 여부 |
| TryGetValue | `bool TryGetValue(TKey key, out TValue value)` | 값 조회 시도 |
| Add | `void Add(TKey key, TValue value)` | 추가 |
| Remove | `void Remove(TKey key)` | 삭제 |
| Clear | `void Clear()` | 전체 삭제 |
| Observe (전체) | `void Observe(Action<TKey, TValue, TValue, ObservableUpdateType>)` | 전체 키 옵저빙 |
| Observe (키) | `void Observe(TKey key, Action<TKey, TValue, TValue, ObservableUpdateType>)` | 특정 키 옵저빙 |
| InvokeObserve | `void InvokeObserve()` | 옵저버 강제 호출 |
| StopObserving | `void StopObserving(Action<TKey, TValue, TValue, ObservableUpdateType>)` | 콜백 해제 |
| StopObserving (키) | `void StopObserving(TKey key, Action<...>)` | 특정 키 콜백 해제 |
| StopObservingAll | `void StopObservingAll()` | 모든 콜백 및 의존성 해제 |
| Subscribe | `IComputedDependency Subscribe(IComputedFieldInternal)` | ComputedField 의존성 등록 |
| Unsubscribe | `IComputedDependency Unsubscribe(IComputedFieldInternal)` | 의존성 해제 |
| BeginBatch | `ObservableBatch BeginBatch()` | 일괄 업데이트 |
| SuppressNotifications | `ObservableDictionary<TKey, TValue> SuppressNotifications()` | 통지 억제 |
| ResumeNotifications | `ObservableDictionary<TKey, TValue> ResumeNotifications()` | 통지 재개 |
| InvokeUpdate | `void InvokeUpdate(TKey key, TValue previousValue)` | 업데이트 강제 |

---

### IObservableHashSet<T>
읽기/쓰기 Observable HashSet 인터페이스.

### IObservableHashSetReader<T>
읽기 전용 Observable HashSet 인터페이스.

### ObservableHashSet<T>
`IObservableHashSet<T>`, `IObservableHashSetReader<T>`, `IBatchable`, `IComputedDependency` 구현.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| ObservableHashSet | `ObservableHashSet()` | 기본 생성자 |
| ObservableHashSet | `ObservableHashSet(HashSet<T> set)` | 기존 HashSet 래핑 |
| ObservableHashSet | `ObservableHashSet(HashSet<T> set, string debugName)` | 디버그 이름 지정 |
| Count | `int Count { get; }` | 요소 수 |
| Subscribe | `IComputedDependency Subscribe(IComputedFieldInternal)` | 의존성 등록 |
| Unsubscribe | `IComputedDependency Unsubscribe(IComputedFieldInternal)` | 의존성 해제 |
| BeginBatch | `ObservableBatch BeginBatch()` | 일괄 업데이트 |
| SuppressNotifications | `ObservableHashSet<T> SuppressNotifications()` | 통지 억제 |
| ResumeNotifications | `ObservableHashSet<T> ResumeNotifications()` | 통지 재개 |
| Contains | `bool Contains(T item)` | 포함 여부 |
| Observe | `void Observe(Action<T, ObservableUpdateType>)` | 변경 콜백 |
| StopObserving | `void StopObserving(Action<T, ObservableUpdateType>)` | 콜백 해제 |
| StopObservingAll | `void StopObservingAll()` | 모든 콜백 해제 |
| Add | `void Add(T item)` | 추가 |
| Remove | `void Remove(T item)` | 삭제 |
| Clear | `void Clear()` | 전체 삭제 |
| GetEnumerator | `HashSet<T>.Enumerator GetEnumerator()` | 열거자 |

---

### IBatchable
일괄 업데이트를 지원하는 인터페이스.

### ObservableBatch : IDisposable
여러 Observable의 일괄 업데이트 관리.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| Add | `void Add(IBatchable observable)` | Observable 추가 |
| Dispose | `void Dispose()` | 배치 종료, 모든 옵저버 통지 |

---

### ObservableUpdateType (enum)
```csharp
public enum ObservableUpdateType { Added, Updated, Removed }
```

### ObservableUpdateFlag (enum)
Observable 업데이트 플래그.

---

### ObservableDebugRegistry
에디터 디버그 창에서 Observable 인스턴스를 추적하는 레지스트리.

---

### ObservableResolverField<T>
리졸버 함수 기반 동적 값 해결 Observable 필드.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| ObservableResolverField | `ObservableResolverField(Func<T> getter, Action<T> setter)` | 생성자 |
| Value | `T Value { get; set; }` | getter/setter를 통한 값 접근 |
| implicit operator T | `static implicit operator T(ObservableResolverField<T>)` | 암시적 변환 |
| Rebind | `void Rebind(Func<T> getter, Action<T> setter)` | 리졸버 교체 |

### IObservableResolverField<T>
ObservableResolverField의 인터페이스.

### ObservableResolverList<T>
리졸버 함수 기반 동적 리스트.

### IObservableResolverList<T>
ObservableResolverList의 읽기/쓰기 인터페이스.

### IObservableResolverListReader<T>
ObservableResolverList의 읽기 전용 인터페이스.

### ObservableResolverDictionary<TKey, TValue>
리졸버 함수 기반 동적 딕셔너리.

### IObservableResolverDictionary<TKey, TValue>
ObservableResolverDictionary의 읽기/쓰기 인터페이스.

### IObservableResolverDictionaryReader<TKey, TValue>
ObservableResolverDictionary의 읽기 전용 인터페이스.

---

## ComputedField

### IComputedDependency
ComputedField가 의존할 수 있는 타입을 나타내는 인터페이스.

### IComputedFieldInternal
ComputedField 내부 인터페이스.

### ComputedField<T> : IObservableFieldReader<T>, IDisposable
의존성 자동 추적 기반 파생 값.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| ComputedField | `ComputedField(Func<T> computation)` | 생성자 (계산 함수 전달) |
| Value | `T Value { get; }` | 현재 계산된 값 (lazy, dirty일 때 재계산) |
| BeginBatch | `ObservableBatch BeginBatch()` | 일괄 업데이트 |
| SuppressNotifications | `ComputedField<T> SuppressNotifications()` | 통지 억제 |
| ResumeNotifications | `ComputedField<T> ResumeNotifications()` | 통지 재개 |
| Observe | `void Observe(Action<T, T> action)` | 변경 콜백 등록 |
| InvokeObserve | `void InvokeObserve()` | 옵저버 강제 호출 |
| StopObserving | `void StopObserving(Action<T, T> action)` | 콜백 해제 |
| StopObservingAll | `void StopObservingAll()` | 모든 콜백 해제 |
| Subscribe | `IComputedDependency Subscribe(IComputedFieldInternal)` | 의존성 등록 |
| Unsubscribe | `IComputedDependency Unsubscribe(IComputedFieldInternal)` | 의존성 해제 |
| Dispose | `void Dispose()` | 모든 의존성 구독 해제 및 정리 |

### ComputedTracker
ComputedField의 의존성 자동 추적을 담당하는 정적 클래스.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| BeginTracking | `static void BeginTracking(IComputedFieldInternal)` | 추적 시작 |
| EndTracking | `static void EndTracking()` | 추적 종료 |
| OnRead | `static void OnRead(IComputedDependency)` | 읽기 감지 (의존성 등록) |

---

## ObservableExtensions (확장 메서드)

| 메서드 | 시그니처 | 설명 |
|--------|----------|------|
| Select | `ComputedField<TResult> Select<T, TResult>(this IObservableFieldReader<T>, Func<T, TResult>)` | 값 변환 |
| CombineWith (2) | `ComputedField<TResult> CombineWith<T1, T2, TResult>(this IObservableFieldReader<T1>, IObservableFieldReader<T2>, Func<T1, T2, TResult>)` | 2개 결합 |
| CombineWith (3) | `ComputedField<TResult> CombineWith<T1, T2, T3, TResult>(...)` | 3개 결합 |
| CombineWith (4) | `ComputedField<TResult> CombineWith<T1, T2, T3, T4, TResult>(...)` | 4개 결합 |

---

## Config Services

### IConfigsProvider
설정 조회 인터페이스.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| Version | `int Version { get; }` | 설정 버전 |
| TryGetConfig | `bool TryGetConfig<T>(int id, out T config)` | ID로 설정 조회 시도 |
| TryGetConfig | `bool TryGetConfig<T>(out T config)` | 싱글톤 설정 조회 시도 |
| GetConfig | `T GetConfig<T>(int id)` | ID로 설정 조회 (없으면 예외) |
| GetConfig | `T GetConfig<T>()` | 싱글톤 설정 조회 |
| GetConfigsList | `List<T> GetConfigsList<T>()` | 리스트로 반환 (할당 발생) |
| GetConfigsDictionary | `IReadOnlyDictionary<int, T> GetConfigsDictionary<T>()` | 딕셔너리로 반환 |
| EnumerateConfigs | `IEnumerable<T> EnumerateConfigs<T>()` | 제로 할당 열거 |
| EnumerateConfigsWithIds | `IEnumerable<KeyValuePair<int, T>> EnumerateConfigsWithIds<T>()` | ID 포함 열거 |
| GetAllConfigs | `IReadOnlyDictionary<Type, IEnumerable> GetAllConfigs()` | 모든 설정 반환 |

### IConfigsAdder
설정 추가 인터페이스.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| AddSingletonConfig | `void AddSingletonConfig<T>(T config)` | 싱글톤 설정 추가 |
| AddConfigs | `void AddConfigs<T>(Func<T, int> idResolver, IEnumerable<T> configs)` | ID 리졸버로 컬렉션 추가 |
| AddAllConfigs | `void AddAllConfigs(IConfigsProvider provider)` | 다른 Provider에서 일괄 추가 |
| UpdateTo | `void UpdateTo(IConfigsProvider provider)` | 다른 Provider 내용으로 교체 |

### ConfigsProvider : IConfigsProvider, IConfigsAdder

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| ConfigsProvider | `ConfigsProvider()` | 기본 생성자 |
| Version | `int Version { get; }` | 버전 |
| TryGetConfig | `bool TryGetConfig<T>(out T config)` | 싱글톤 조회 시도 |
| TryGetConfig | `bool TryGetConfig<T>(int id, out T config)` | ID 조회 시도 |
| GetConfig | `T GetConfig<T>(int id)` | ID로 조회 |
| GetConfig | `T GetConfig<T>()` | 싱글톤 조회 |
| GetConfigsList | `List<T> GetConfigsList<T>()` | 리스트 반환 |
| GetConfigsDictionary | `IReadOnlyDictionary<int, T> GetConfigsDictionary<T>()` | 딕셔너리 반환 |
| EnumerateConfigs | `IEnumerable<T> EnumerateConfigs<T>()` | 제로 할당 열거 |
| EnumerateConfigsWithIds | `IEnumerable<KeyValuePair<int, T>> EnumerateConfigsWithIds<T>()` | ID 포함 열거 |
| AddSingletonConfig | `void AddSingletonConfig<T>(T config)` | 싱글톤 추가 |
| AddConfigs | `void AddConfigs<T>(Func<T, int> idResolver, IEnumerable<T> configs)` | 컬렉션 추가 |
| GetAllConfigs | `IReadOnlyDictionary<Type, IEnumerable> GetAllConfigs()` | 모든 설정 |
| AddAllConfigs | `void AddAllConfigs(IConfigsProvider provider)` | 일괄 추가 |
| UpdateTo | `void UpdateTo(IConfigsProvider provider)` | 교체 |
| SetVersion | `void SetVersion(IConfigsProvider provider, string version)` | 버전 설정 |

---

### IConfigsSerializer
직렬화 인터페이스.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| Serialize | `string Serialize(IConfigsProvider provider)` | Provider를 JSON으로 |
| Deserialize | `T Deserialize<T>(string json)` | JSON에서 역직렬화 |

### ConfigsSerializer : IConfigsSerializer

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| DefaultMaxDepth | `const int DefaultMaxDepth = 32` | 기본 최대 깊이 |
| ConfigsSerializer | `ConfigsSerializer(SerializationSecurityMode mode = TrustedOnly)` | 생성자 |
| SecurityMode | `SerializationSecurityMode SecurityMode { get; }` | 현재 보안 모드 |
| Serialize | `string Serialize(IConfigsProvider provider)` | 직렬화 |
| RegisterAllowedTypes | `void RegisterAllowedTypes(params Type[] types)` | 허용 타입 등록 |
| RegisterAllowedTypesFromProvider | `void RegisterAllowedTypesFromProvider(IConfigsProvider provider)` | Provider에서 타입 자동 등록 |
| Deserialize | `T Deserialize<T>(string json)` | 역직렬화 |
| Deserialize | `void Deserialize(string json, IConfigsAdder adder)` | Provider에 직접 로드 |

### SerializationSecurityMode (enum)
```csharp
public enum SerializationSecurityMode
{
    TrustedOnly,  // TypeNameHandling.Auto + Binder (기본)
    Secure        // TypeNameHandling.None
}
```

### SerializedConfigs
직렬화된 설정 래퍼.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| Version | `int Version` | 버전 |
| Configs | `Dictionary<string, string> Configs` | 타입별 JSON 맵 |

### IgnoreServerSerialization
서버 직렬화에서 제외할 어트리뷰트.

---

### ConfigTypesBinder : ISerializationBinder
화이트리스트 기반 타입 바인더.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| ConfigTypesBinder | `ConfigTypesBinder(params Type[] allowedTypes)` | 생성자 |
| FromProvider | `static ConfigTypesBinder FromProvider(IConfigsProvider provider)` | Provider에서 생성 |
| AddAllowedType | `void AddAllowedType(Type type)` | 허용 타입 추가 |
| BindToType | `Type BindToType(string assemblyName, string typeName)` | 타입 바인딩 |
| BindToName | `void BindToName(Type serializedType, out string assemblyName, out string typeName)` | 이름 바인딩 |

---

### IConfigBackendService
원격 설정 동기화 인터페이스.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| GetRemoteVersion | `UniTask<int> GetRemoteVersion()` | 원격 버전 조회 |
| FetchRemoteConfiguration | `UniTask<IConfigsProvider> FetchRemoteConfiguration()` | 원격 설정 가져오기 |

---

### IConfig
설정 타입 마커 인터페이스.

### IConfigsContainer<T>
설정 컨테이너 인터페이스.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| Configs | `IReadOnlyList<T> Configs { get; }` | 설정 목록 |

### IPairConfigsContainer<TKey, TValue>
키-값 쌍 컨테이너. `IConfigsContainer<TValue>` 상속.

### ISingleConfigContainer<T>
싱글톤 컨테이너.

### IStructPairConfigsContainer<TKey, TValue>
구조체 쌍 컨테이너.

---

### ConfigsScriptableObject<TKey, TValue> : ScriptableObject, ISerializationCallbackReceiver
인스펙터에서 설정을 편집할 수 있는 ScriptableObject 컨테이너.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| Configs | `IReadOnlyList<TValue> Configs { get; }` | 설정 목록 |
| ConfigsDictionary | `IReadOnlyDictionary<TKey, TValue> ConfigsDictionary { get; }` | 딕셔너리 |
| OnBeforeSerialize | `void OnBeforeSerialize()` | 직렬화 전 처리 |
| OnAfterDeserialize | `void OnAfterDeserialize()` | 역직렬화 후 딕셔너리 빌드 |

### ConfigsProviderDebugRegistry
에디터에서 ConfigsProvider 인스턴스를 추적하는 레지스트리.

---

## Math

### floatP : IEquatable<floatP>, IComparable<floatP>, IComparable, IFormattable
결정론적 32비트 부동소수점 struct.

**상수 및 프로퍼티**

| 멤버 | 타입 | 설명 |
|------|------|------|
| Zero | `floatP` | 0 |
| One | `floatP` | 1 |
| MinusOne | `floatP` | -1 |
| MaxValue | `floatP` | 최대값 |
| MinValue | `floatP` | 최소값 |
| Epsilon | `floatP` | 엡실론 |
| NaN | `floatP` | NaN |
| PositiveInfinity | `floatP` | 양의 무한대 |
| NegativeInfinity | `floatP` | 음의 무한대 |
| MantissaBits | `int` | 23 (가수 비트) |
| ExponentBias | `int` | 150 (지수 바이어스) |
| SignMask | `uint` | 부호 마스크 |

**프로퍼티**

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| RawValue | `int RawValue { get; }` | 내부 원시값 |
| RawMantissa | `uint RawMantissa { get; }` | 원시 가수 |
| Mantissa | `int Mantissa { get; }` | 가수 |
| RawExponent | `int RawExponent { get; }` | 원시 지수 |
| Exponent | `int Exponent { get; }` | 지수 |

**생성자 및 팩토리**

| 메서드 | 시그니처 | 설명 |
|--------|----------|------|
| floatP | `floatP(int rawValue)` | 원시값으로 생성 |
| FromRaw | `static floatP FromRaw(int raw)` | 원시값에서 생성 |
| FromParts | `static floatP FromParts(int sign, int exponent, uint mantissa)` | 부분으로 생성 |
| FromIeeeRaw | `static floatP FromIeeeRaw(uint ieeeRaw)` | IEEE 원시값에서 변환 |

**연산자**

| 연산자 | 설명 |
|--------|------|
| `+`, `-`, `*`, `/`, `%` | 산술 연산 |
| `==`, `!=`, `<`, `>`, `<=`, `>=` | 비교 연산 |
| `implicit float -> floatP` | float에서 암시적 변환 |
| `implicit floatP -> float` | float로 암시적 변환 |
| `implicit int -> floatP` | int에서 암시적 변환 |
| `implicit floatP -> int` | int로 암시적 변환 |

**메서드**

| 메서드 | 시그니처 | 설명 |
|--------|----------|------|
| IsNaN | `bool IsNaN()` / `static bool IsNaN(floatP)` | NaN 검사 |
| IsInfinity | `bool IsInfinity()` / `static bool IsInfinity(floatP)` | 무한대 검사 |
| IsNegativeInfinity | `bool IsNegativeInfinity()` / `static bool IsNegativeInfinity(floatP)` | 음의 무한대 |
| IsPositiveInfinity | `bool IsPositiveInfinity()` / `static` | 양의 무한대 |
| IsFinite | `bool IsFinite()` / `static bool IsFinite(floatP)` | 유한 검사 |
| IsZero | `bool IsZero()` | 0 검사 |
| IsPositive | `bool IsPositive()` | 양수 검사 |
| IsNegative | `bool IsNegative()` | 음수 검사 |
| Sign | `int Sign()` / `static int Sign(floatP)` | 부호 반환 |
| CompareTo | `int CompareTo(floatP)` / `int CompareTo(object)` | 비교 |
| Equals | `bool Equals(floatP)` / `bool Equals(object)` | 동등 비교 |
| GetHashCode | `int GetHashCode()` | 해시코드 |
| ToString | `string ToString()` / `string ToString(string, IFormatProvider)` | 문자열 변환 |
| ToIeeeRaw | `uint ToIeeeRaw()` | IEEE 원시값 반환 |

---

### MathfloatP (정적 클래스)
floatP 전용 수학 함수.

**상수**

| 멤버 | 설명 |
|------|------|
| RawPi | Pi 원시값 |
| RawPiOver2 | Pi/2 원시값 |
| RawPiOver4 | Pi/4 원시값 |
| Raw2Pi | 2*Pi 원시값 |
| Raw3PiOver4 | 3*Pi/4 원시값 |

**기본 수학**

| 메서드 | 시그니처 | 설명 |
|--------|----------|------|
| Abs | `static floatP Abs(floatP x)` | 절대값 |
| Max | `static floatP Max(floatP a, floatP b)` | 최대값 |
| Min | `static floatP Min(floatP a, floatP b)` | 최소값 |
| Clamp | `static floatP Clamp(floatP x, floatP min, floatP max)` | 범위 제한 |
| Clamp01 | `static floatP Clamp01(floatP x)` | 0-1 범위 제한 |
| Sign | `static int Sign(floatP x)` | 부호 (-1, 0, 1) |

**보간**

| 메서드 | 시그니처 | 설명 |
|--------|----------|------|
| Lerp | `static floatP Lerp(floatP a, floatP b, floatP t)` | 선형 보간 (clamped) |
| LerpUnclamped | `static floatP LerpUnclamped(floatP a, floatP b, floatP t)` | 선형 보간 (unclamped) |
| SmoothStep | `static floatP SmoothStep(floatP a, floatP b, floatP t)` | 부드러운 보간 |
| InverseLerp | `static floatP InverseLerp(floatP a, floatP b, floatP v)` | 역 선형 보간 |
| MoveTowards | `static floatP MoveTowards(floatP current, floatP target, floatP maxDelta)` | 이동 |

**각도**

| 메서드 | 시그니처 | 설명 |
|--------|----------|------|
| DeltaAngle | `static floatP DeltaAngle(floatP a, floatP b)` | 각도 차이 |
| LerpAngle | `static floatP LerpAngle(floatP a, floatP b, floatP t)` | 각도 보간 |
| MoveTowardsAngle | `static floatP MoveTowardsAngle(floatP current, floatP target, floatP maxDelta)` | 각도 이동 |

**반복**

| 메서드 | 시그니처 | 설명 |
|--------|----------|------|
| Repeat | `static floatP Repeat(floatP t, floatP length)` | 반복 |
| PingPong | `static floatP PingPong(floatP t, floatP length)` | 핑퐁 |
| Approximately | `static bool Approximately(floatP a, floatP b)` | 근사 비교 |

**반올림**

| 메서드 | 시그니처 | 설명 |
|--------|----------|------|
| Round | `static floatP Round(floatP x)` | 반올림 |
| Floor | `static floatP Floor(floatP x)` | 내림 |
| Ceil | `static floatP Ceil(floatP x)` | 올림 |
| Truncate | `static floatP Truncate(floatP x)` | 절사 |

**거듭제곱 및 로그**

| 메서드 | 시그니처 | 설명 |
|--------|----------|------|
| Sqrt | `static floatP Sqrt(floatP x)` | 제곱근 |
| Exp | `static floatP Exp(floatP x)` | 지수 함수 |
| Pow | `static floatP Pow(floatP base, floatP exp)` | 거듭제곱 |
| Pow2 | `static floatP Pow2(floatP x)` | 2의 거듭제곱 |
| Log | `static floatP Log(floatP x)` | 자연 로그 |
| Log | `static floatP Log(floatP x, floatP base)` | 지정 밑 로그 |
| Log2 | `static floatP Log2(floatP x)` | 밑 2 로그 |
| Log10 | `static floatP Log10(floatP x)` | 밑 10 로그 |

**삼각함수**

| 메서드 | 시그니처 | 설명 |
|--------|----------|------|
| Sin | `static floatP Sin(floatP x)` | 사인 |
| Cos | `static floatP Cos(floatP x)` | 코사인 |
| Tan | `static floatP Tan(floatP x)` | 탄젠트 |
| Asin | `static floatP Asin(floatP x)` | 아크사인 |
| Acos | `static floatP Acos(floatP x)` | 아크코사인 |
| Atan | `static floatP Atan(floatP x)` | 아크탄젠트 |
| Atan2 | `static floatP Atan2(floatP y, floatP x)` | 아크탄젠트2 |

**기타**

| 메서드 | 시그니처 | 설명 |
|--------|----------|------|
| Hypothenuse | `static floatP Hypothenuse(floatP a, floatP b)` | 빗변 |
| Mod | `static floatP Mod(floatP a, floatP b)` | 모듈러 |
| IEEERemainder | `static floatP IEEERemainder(floatP a, floatP b)` | IEEE 나머지 |
| DivRem | `static int DivRem(floatP a, floatP b, out floatP rem)` | 나눗셈 + 나머지 |
| ScaleB | `static floatP ScaleB(floatP x, int n)` | 스케일 |

---

## Serialization

### UnitySerializedDictionary<TKey, TValue> : Dictionary<TKey, TValue>, ISerializationCallbackReceiver
Unity 인스펙터 직렬화 가능 딕셔너리.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| OnBeforeSerialize | `void OnBeforeSerialize()` | 직렬화 전: 딕셔너리 -> 리스트 |
| OnAfterDeserialize | `void OnAfterDeserialize()` | 역직렬화 후: 리스트 -> 딕셔너리 |

### Pair<TKey, TValue>
키-값 쌍 클래스.

### StructPair<TKey, TValue>
키-값 쌍 구조체.

### SerializableType
System.Type의 직렬화 가능 래퍼 구조체.

### Vector 직렬화 구조체
`Vector2Serializable`, `Vector3Serializable`, `Vector4Serializable`,
`Vector2IntSerializable`, `Vector3IntSerializable`, `Vector4Int`

### ColorJsonConverter, VectorJsonConverters
Newtonsoft.Json 컨버터 (Color, Vector2/3/4).

---

## Utilities

### EnumSelector<T> : IEnumSelector
enum 이름 기반 직렬화/드롭다운.

| 멤버 | 시그니처 | 설명 |
|------|----------|------|
| EnumSelector | `EnumSelector()` | 기본 생성자 |
| EnumSelector | `EnumSelector(T selection)` | 초기값 지정 |
| EnumSelector | `EnumSelector(string selection)` | 문자열로 지정 |
| EnumNames | `static string[] EnumNames` | enum 이름 배열 |
| EnumValues | `static T[] EnumValues` | enum 값 배열 |
| EnumDictionary | `static IReadOnlyDictionary<string, T> EnumDictionary` | 이름-값 딕셔너리 |
| GetSelectedIndex | `int GetSelectedIndex()` | 선택된 인덱스 |
| HasValidSelection | `bool HasValidSelection()` | 유효한 선택인지 |
| GetSelectionString | `string GetSelectionString()` | 선택된 이름 |
| GetSelection | `T GetSelection()` | 선택된 값 |
| SetSelection | `void SetSelection(T value)` | 값 설정 |
| implicit operator T | `static implicit operator T(EnumSelector<T>)` | 암시적 변환 |

### IEnumSelector
EnumSelector의 비제네릭 인터페이스.

---

## Extensions

### ObjectExtensions (정적 확장 클래스)
객체 유틸리티 확장 메서드.

### ObjectDisposeResult (enum)
Dispose 결과.

### ReflectionExtensions (정적 확장 클래스)
리플렉션 유틸리티 확장 메서드.

### SortedListExtensions (정적 확장 클래스)
SortedList 유틸리티 확장 메서드.

### UnityObjectsExtensions (정적 확장 클래스)
Unity Object 유틸리티 확장 메서드.

---

## Validation Attributes

### ValidationAttribute : Attribute
설정 검증 기본 어트리뷰트.

### RequiredAttribute : ValidationAttribute
필수 필드 어트리뷰트.

### RangeAttribute : ValidationAttribute
범위 제한 어트리뷰트.

### MinLengthAttribute : ValidationAttribute
최소 길이 어트리뷰트.

### ReadOnlyAttribute : PropertyAttribute
인스펙터 읽기 전용 어트리뷰트.
