---
name: geuneda-dataextensions
description: Unity 게임용 핵심 데이터 유틸리티 및 설정 관리 패키지. Observable 반응형 데이터 타입, 타입 안전 설정 저장소(ConfigsProvider), 결정론적 부동소수점(floatP), JSON 직렬화, Unity 직렬화 헬퍼 관련 코드를 작성하거나 수정할 때 사용한다.
---

# Geuneda Data Extensions

Unity 게임을 위한 핵심 데이터 유틸리티 및 설정 관리 패키지. Observable 반응형 데이터 타입, 의존성 추적 기반 ComputedField, 타입 안전 설정 저장소, 결정론적 수학, JSON 직렬화/역직렬화, Unity 인스펙터 직렬화 헬퍼를 제공한다.

## 활성화 시점

- ObservableField, ObservableList, ObservableDictionary, ObservableHashSet 등 반응형 데이터 타입을 사용하거나 구현할 때
- ComputedField로 파생 상태를 자동 계산하는 코드를 작성할 때
- ConfigsProvider를 통해 설정 데이터를 추가/조회하는 코드를 작성할 때
- ConfigsSerializer로 설정을 JSON 직렬화/역직렬화할 때
- floatP/MathfloatP로 결정론적 부동소수점 연산을 수행할 때
- UnitySerializedDictionary, EnumSelector 등 Unity 직렬화 타입을 사용할 때
- ConfigsScriptableObject 기반 ScriptableObject 컨테이너를 생성할 때
- ObservableResolverField/List/Dictionary를 사용할 때

## 패키지 정보

- **네임스페이스**: `Geuneda.DataExtensions`
- **패키지명**: `com.geuneda.gamedata`
- **설치**: `https://github.com/geuneda/geuneda-dataextensions.git`
- **Unity**: 6000.0+ (Unity 6)
- **의존성**: Newtonsoft.Json (3.2.1), UniTask (2.5.10), TextMeshPro (3.0.6)
- **어셈블리**: `Geuneda.GameData` (Runtime), `Geuneda.GameData.Editor` (Editor)

## 핵심 API

### Observable 데이터 타입

#### ObservableField<T>
변경 콜백이 있는 단일 값 반응형 래퍼. `IObservableField<T>` (읽기/쓰기), `IObservableFieldReader<T>` (읽기 전용) 인터페이스 구현.

```csharp
var score = new ObservableField<int>(0);
// 또는 이름 지정 (디버그용)
var score = new ObservableField<int>(0, "PlayerScore");

// 옵저빙
score.Observe((prev, curr) => Debug.Log($"{prev} -> {curr}"));

// 값 변경
score.Value = 100;

// 옵저빙 중지
score.StopObserving(callback);
score.StopObservingAll();

// 일괄 업데이트
using (score.BeginBatch()) {
    score.Value = 10;
    score.Value = 20;
}
// 배치 완료 후 최종 값으로 한 번만 통지

// ComputedField 의존성 구독
score.Subscribe(computedDep);
score.Unsubscribe(computedDep);
```

#### ObservableList<T>
추가/삭제/업데이트 콜백이 있는 리스트 래퍼. `IObservableList<T>` (읽기/쓰기), `IObservableListReader<T>` (읽기 전용).

```csharp
var list = new ObservableList<string>(new List<string>());
list.Observe((index, prev, curr, updateType) => { /* ... */ });

list.Add("item");           // ObservableUpdateType.Added
list[0] = "updated";        // ObservableUpdateType.Updated
list.Remove("updated");     // ObservableUpdateType.Removed
list.RemoveAt(0);
list.Clear();

// 읽기 전용 접근
IReadOnlyList<string> readOnly = list.ReadOnlyList;
int count = list.Count;
bool has = list.Contains("item");
int idx = list.IndexOf("item");
```

#### ObservableDictionary<TKey, TValue>
키 기반 콜백이 있는 딕셔너리 래퍼.

```csharp
var dict = new ObservableDictionary<string, int>(new Dictionary<string, int>());

// 전체 키 옵저빙
dict.Observe((key, prev, curr, updateType) => { /* ... */ });

// 특정 키만 옵저빙
dict.Observe("health", (key, prev, curr, updateType) => { /* ... */ });

dict.Add("health", 100);
dict["health"] = 120;
dict.Remove("health");
dict.Clear();

bool has = dict.ContainsKey("health");
dict.TryGetValue("health", out var val);
```

#### ObservableHashSet<T>
HashSet 래퍼.

```csharp
var set = new ObservableHashSet<string>();
set.Observe((item, updateType) => { /* ... */ });
set.Add("tag");
set.Remove("tag");
set.Contains("tag");
set.Clear();
```

#### ObservableBatch
여러 Observable의 일괄 업데이트 관리. `IDisposable`.

```csharp
using (var batch = health.BeginBatch()) {
    health.Value = 80;
    mana.Value = 40;
}
// 또는 수동 추가
var batch = new ObservableBatch();
batch.Add(health);
batch.Add(mana);
// Dispose 시 모든 옵저버 한 번에 호출
```

#### ObservableResolverField<T>
리졸버 함수로 값을 동적으로 해결하는 ObservableField 확장.

```csharp
var resolved = new ObservableResolverField<int>(() => source.Value * 2, (val) => source.Value = val / 2);
int v = resolved.Value;      // getter 호출
resolved.Value = 10;          // setter 호출
resolved.Rebind(newGetter, newSetter);
```

#### ObservableUpdateType (enum)
```
Added, Updated, Removed
```

### ComputedField<T>
의존성을 자동 추적하고 의존하는 Observable이 변경되면 자동으로 재계산하는 파생 값.

```csharp
var baseHp = new ObservableField<int>(100);
var bonus = new ObservableField<int>(25);
var total = new ComputedField<int>(() => baseHp.Value + bonus.Value);

total.Observe((prev, curr) => Debug.Log($"HP: {prev} -> {curr}"));
baseHp.Value = 120;  // 자동 재계산 및 통지

// 정리
total.Dispose();  // 모든 의존성 구독 해제
```

**ComputedTracker**: ComputedField의 의존성 자동 추적을 담당하는 정적 클래스.
- `BeginTracking(IComputedFieldInternal)`: 추적 시작
- `EndTracking()`: 추적 종료
- `OnRead(IComputedDependency)`: 읽기 감지하여 의존성 등록

### ObservableExtensions (확장 메서드)
```csharp
// Select: 값 변환
var doubled = score.Select(x => x * 2);

// CombineWith: 여러 Observable 결합
var combined = a.CombineWith(b, (va, vb) => va + vb);
var combined3 = a.CombineWith(b, c, (va, vb, vc) => va + vb + vc);
var combined4 = a.CombineWith(b, c, d, (va, vb, vc, vd) => va + vb + vc + vd);
```

### ConfigsProvider
O(1) 조회와 버저닝을 지원하는 타입 안전 설정 저장소. `IConfigsProvider`, `IConfigsAdder` 구현.

```csharp
var provider = new ConfigsProvider();

// 컬렉션 추가 (ID 리졸버 필요)
provider.AddConfigs(item => item.Id, itemConfigs);

// 싱글톤 설정 추가
provider.AddSingletonConfig(new GameSettings { Difficulty = 2 });

// 모든 설정 일괄 추가
provider.AddAllConfigs(otherProvider);

// 조회
var item = provider.GetConfig<ItemConfig>(42);            // ID로
var settings = provider.GetConfig<GameSettings>();         // 싱글톤
bool found = provider.TryGetConfig<ItemConfig>(42, out var config);

// 컬렉션 접근
var list = provider.GetConfigsList<ItemConfig>();                  // List<T> (할당)
var dict = provider.GetConfigsDictionary<ItemConfig>();            // IReadOnlyDictionary
foreach (var e in provider.EnumerateConfigs<EnemyConfig>()) { }   // 제로 할당 열거
foreach (var (id, e) in provider.EnumerateConfigsWithIds<EnemyConfig>()) { }

// 버저닝
provider.SetVersion(new ConfigsProvider(), "v2.1");
int version = provider.Version;

// 다른 Provider 내용으로 업데이트
provider.UpdateTo(newProvider);
```

### ConfigsSerializer
JSON 직렬화/역직렬화 (Newtonsoft.Json 기반). `IConfigsSerializer` 구현.

```csharp
var serializer = new ConfigsSerializer();  // TrustedOnly 기본
var serializer = new ConfigsSerializer(SerializationSecurityMode.Secure);

// 허용 타입 등록
serializer.RegisterAllowedTypes(typeof(ItemConfig), typeof(EnemyConfig));
serializer.RegisterAllowedTypesFromProvider(provider);

// 직렬화
string json = serializer.Serialize(provider);

// 역직렬화
T config = serializer.Deserialize<T>(json);
provider = serializer.Deserialize(json, provider);  // Provider에 직접 로드
```

**SerializationSecurityMode**: `TrustedOnly` (TypeNameHandling.Auto + Binder), `Secure` (TypeNameHandling.None)

### ConfigTypesBinder
화이트리스트 기반 타입 바인더. 허용되지 않은 타입의 역직렬화를 차단.

```csharp
var binder = new ConfigTypesBinder(typeof(ItemConfig), typeof(EnemyConfig));
var binder = ConfigTypesBinder.FromProvider(provider);
binder.AddAllowedType(typeof(NewConfig));
```

### ConfigsScriptableObject<TKey, TValue>
인스펙터에서 설정을 편집할 수 있는 ScriptableObject 컨테이너.

```csharp
[CreateAssetMenu(menuName = "Config/Items")]
public class ItemConfigAsset : ConfigsScriptableObject<int, ItemConfig>
{
}

// 접근
var asset = Resources.Load<ItemConfigAsset>("ItemConfigs");
IReadOnlyList<ItemConfig> configs = asset.Configs;
IReadOnlyDictionary<int, ItemConfig> dict = asset.ConfigsDictionary;
```

### floatP (결정론적 부동소수점)
크로스 플랫폼 재현 가능한 부동소수점 struct. `IEquatable`, `IComparable` 구현.

```csharp
floatP a = 3.14f;              // float에서 암시적 변환
floatP b = 2;                  // int에서 암시적 변환
floatP sum = a + b;            // 산술 연산 (+, -, *, /, %)
float result = (float)sum;     // float로 암시적 변환
int intVal = (int)sum;         // int로 암시적 변환

// 비교 연산: ==, !=, <, >, <=, >=
// 정적 프로퍼티: Zero, One, MinusOne, NaN, PositiveInfinity, NegativeInfinity, MaxValue, MinValue, Epsilon
// 메서드: IsNaN, IsInfinity, IsFinite, IsPositive, IsNegative, IsZero, Sign, CompareTo
// 내부: FromRaw, FromParts, FromIeeeRaw, ToIeeeRaw
```

### MathfloatP
floatP 전용 수학 함수 (정적 클래스).

```csharp
MathfloatP.Abs(x)              MathfloatP.Max(a, b)
MathfloatP.Min(a, b)           MathfloatP.Clamp(x, min, max)
MathfloatP.Clamp01(x)          MathfloatP.Lerp(a, b, t)
MathfloatP.LerpUnclamped(a,b,t) MathfloatP.SmoothStep(a, b, t)
MathfloatP.InverseLerp(a,b,v)  MathfloatP.MoveTowards(curr, target, delta)
MathfloatP.Sign(x)             MathfloatP.Repeat(t, length)
MathfloatP.PingPong(t, length) MathfloatP.DeltaAngle(a, b)
MathfloatP.LerpAngle(a, b, t)  MathfloatP.MoveTowardsAngle(curr, target, delta)
MathfloatP.Approximately(a, b) MathfloatP.Round(x)
MathfloatP.Floor(x)            MathfloatP.Ceil(x)
MathfloatP.Truncate(x)         MathfloatP.Sqrt(x)
MathfloatP.Exp(x)              MathfloatP.Pow(base, exp)
MathfloatP.Pow2(x)             MathfloatP.Log(x)
MathfloatP.Log(x, base)        MathfloatP.Log2(x)
MathfloatP.Log10(x)            MathfloatP.Sin(x)
MathfloatP.Cos(x)              MathfloatP.Tan(x)
MathfloatP.Asin(x)             MathfloatP.Acos(x)
MathfloatP.Atan(x)             MathfloatP.Atan2(y, x)
MathfloatP.Hypothenuse(a, b)   MathfloatP.Mod(a, b)
MathfloatP.ScaleB(x, n)
// 상수: RawPi, RawPiOver2, RawPiOver4, Raw2Pi, Raw3PiOver4
```

### UnitySerializedDictionary<TKey, TValue>
Unity 인스펙터에서 표시되는 Dictionary. `Dictionary<TKey, TValue>` 상속, `ISerializationCallbackReceiver` 구현.

```csharp
[Serializable]
public class StringIntDictionary : UnitySerializedDictionary<string, int> { }

[SerializeField] private StringIntDictionary _data;
```

### EnumSelector<T>
enum 이름 기반으로 저장되어 enum 값 변경에 안전한 드롭다운.

```csharp
[SerializeField] private EnumSelector<ItemType> _itemType;

ItemType type = _itemType.GetSelection();
_itemType.SetSelection(ItemType.Weapon);
bool valid = _itemType.HasValidSelection();
T val = (T)_itemType;  // 암시적 변환
```

### IConfigBackendService
원격 설정 동기화를 위한 인터페이스.

```csharp
public interface IConfigBackendService
{
    UniTask<int> GetRemoteVersion();
    UniTask<IConfigsProvider> FetchRemoteConfiguration();
}
```

### Validation Attributes
설정 값 검증용 어트리뷰트.
- `[Required]`: 필수 필드
- `[Range(min, max)]`: 범위 제한
- `[MinLength(n)]`: 최소 길이
- `[ReadOnly]`: 인스펙터에서 읽기 전용
- `ValidationAttribute`: 커스텀 검증의 기본 클래스

## 사용 패턴

### 반응형 UI 바인딩
```csharp
public class PlayerHUD : MonoBehaviour
{
    [SerializeField] private TMP_Text _healthText;
    private ObservableField<int> _health;

    void Start()
    {
        _health = new ObservableField<int>(100, "Health");
        _health.Observe((prev, curr) => _healthText.text = $"HP: {curr}");
    }
}
```

### 설정 로드 및 사용
```csharp
public class GameBootstrap
{
    public void LoadConfigs(ItemConfig[] items, GameSettings settings)
    {
        var provider = new ConfigsProvider();
        provider.AddConfigs(item => item.Id, items);
        provider.AddSingletonConfig(settings);

        var serializer = new ConfigsSerializer();
        serializer.RegisterAllowedTypesFromProvider(provider);
        string json = serializer.Serialize(provider);
    }
}
```

### 파생 상태 자동 계산
```csharp
var baseAtk = new ObservableField<int>(50);
var weapon = new ObservableField<int>(20);
var buff = new ObservableField<float>(1.2f);

var totalAtk = new ComputedField<int>(() =>
    (int)((baseAtk.Value + weapon.Value) * buff.Value));

totalAtk.Observe((prev, curr) =>
    Debug.Log($"공격력: {prev} -> {curr}"));
```

## 주의사항

- `GetConfigsList<T>()`는 매번 새 List를 할당한다. 핫 패스에서는 `EnumerateConfigs<T>()`를 사용할 것.
- `ObservableField.Value` setter에서 이전 값과 같으면 통지가 발생하지 않을 수 있다 (배치 모드 예외).
- `ComputedField`는 사용 후 반드시 `Dispose()`를 호출하여 의존성 구독을 해제할 것.
- `floatP`는 소프트웨어 에뮬레이션이므로 일반 float보다 느리다. 결정론이 필요한 로직에만 사용.
- `ConfigsSerializer`의 `TrustedOnly` 모드는 신뢰할 수 있는 데이터 소스에만 사용. 외부 입력에는 `Secure` 모드.
- `UnitySerializedDictionary`는 직렬화를 위해 구체 타입 클래스를 선언해야 한다.
- Observable의 `StopObservingAll()`은 모든 옵저버와 의존성 구독을 제거하므로 주의.

## 참조 문서

상세 API 문서는 `references/api.md` 참조.
