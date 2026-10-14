---
name: geuneda-gamedata
description: com.geuneda.gamedata(네임스페이스 Geuneda.DataExtensions) 코드를 작성, 수정, 리뷰할 때 사용한다. ObservableField/List/Dictionary/HashSet, ComputedField, ObservableBatch 같은 반응형 데이터, ConfigsProvider/ConfigsSerializer/ConfigsScriptableObject 설정 저장소, floatP/MathfloatP 결정론적 수학, SecureInt/SecureLong/SecureFloat/SecureDouble/SecureFloatP 보안 값과 SecureValueMonitor 변조 감지, UnitySerializedDictionary/EnumSelector 직렬화, 설정 유효성 검사와 MigrationRunner 를 다룰 때 이 스킬을 쓴다. 예전 DataExtensions/ConfigsProvider 패키지 코드도 이 패키지로 옮겨졌다.
---

# Geuneda GameData

Unity 게임용 데이터 기반 패키지. 반응형 데이터 타입, 타입 안전 설정 저장소, 결정론적 수학, 직렬화 헬퍼를 제공한다. 예전 DataExtensions 와 ConfigsProvider 패키지가 여기로 합쳐졌다.

## 패키지 정보

- 패키지명: `com.geuneda.gamedata`
- 설치: `https://github.com/geuneda/geuneda-gamedata.git` (특정 버전 고정은 `#<태그>`)
- 런타임 네임스페이스: `Geuneda.DataExtensions` (어셈블리 `Geuneda.GameData`)
- 에디터 네임스페이스: `GeunedaEditor.GameData` (`MigrationRunner`, `IConfigMigration`, `ConfigMigrationAttribute`, `EditorConfigValidator`, `EnumSelectorPropertyDrawer<T>`), 에디터 창은 `Geuneda.DataExtensions.Editor` (어셈블리 `Geuneda.GameData.Editor`)
- Unity 6000.0 이상
- 의존성: `com.unity.nuget.newtonsoft-json` 3.2.1, `com.cysharp.unitask` 2.5.10, `com.unity.ugui` 2.0.0(TextMeshPro 포함, 샘플 UI 용). UniTask 는 Unity 레지스트리에 없으므로 manifest 에 git URL(`https://github.com/Cysharp/UniTask.git?path=src/UniTask/Assets/Plugins/UniTask`)로 먼저 넣어야 한다.

## 핵심 API

전체 시그니처는 [references/api.md](references/api.md) 에 있다.

### Observable

```csharp
using Geuneda.DataExtensions;

var score = new ObservableField<int>(0);
score.Observe((prev, curr) => Debug.Log($"{prev} -> {curr}"));
score.InvokeObserve((prev, curr) => Debug.Log(curr)); // 현재 값으로 즉시 한 번 호출한 뒤 구독
score.Value = 100;
score.StopObservingAll(this); // 콜백 Target 이 this 인 것만 해제. 인자 없으면 전부 해제

var list = new ObservableList<string>(new List<string>());
list.Observe((index, prev, curr, type) => { });
list.Add("Sword");       // Added
list[0] = "Axe";         // Updated
list.RemoveAt(0);        // Removed

var dict = new ObservableDictionary<string, int>(new Dictionary<string, int>());
dict.Observe("hp", (key, prev, curr, type) => { });   // 키 구독 (기본 설정에서 동작)
dict.ObservableUpdateFlag = ObservableUpdateFlag.Both; // 키 없는 구독도 받으려면 필요
dict.Observe((key, prev, curr, type) => { });
dict.Add("hp", 100);

var set = new ObservableHashSet<string>();
set.Observe((item, type) => { });
set.Add("tag");          // 새로 추가된 경우에만 통지, bool 반환
```

리졸버 타입은 다른 저장소를 감싼다.

```csharp
var resolved = new ObservableResolverField<int>(() => save.Gold, v => save.Gold = v);
var ids = new ObservableResolverList<int, string>(rawIds, s => int.Parse(s), i => i.ToString());
```

### ComputedField

```csharp
var baseAtk = new ObservableField<int>(50);
var weapon = new ObservableField<int>(20);

var total = new ComputedField<int>(() => baseAtk.Value + weapon.Value);
total.Observe((prev, curr) => Debug.Log($"ATK {prev} -> {curr}"));
baseAtk.Value = 60; // "ATK 70 -> 80"
total.Dispose();

var doubled = baseAtk.Select(x => x * 2);
var sum = baseAtk.CombineWith(weapon, (a, b) => a + b);   // 2~4개
var sum2 = ObservableField.Combine(baseAtk, weapon, (a, b) => a + b);
```

### ObservableBatch

```csharp
using (var batch = new ObservableBatch())
{
    batch.Add(health);   // IBatchable: Observable 타입과 ComputedField 모두 해당
    batch.Add(mana);
    health.Value = 80;
    mana.Value = 40;
} // 여기서 한 번에 통지

using (health.BeginBatch()) { health.Value = 10; health.Value = 20; } // 자기 자신만 배치. (배치 전 값, 20) 으로 한 번 통지
```

### ConfigsProvider / ConfigsSerializer

```csharp
var provider = new ConfigsProvider();
provider.AddConfigs(item => item.Id, itemList);          // IList<T> 필요
provider.AddSingletonConfig(new GameSettings());

ItemConfig item = provider.GetConfig<ItemConfig>(42);
GameSettings settings = provider.GetConfig<GameSettings>();
bool found = provider.TryGetConfig<ItemConfig>(42, out var cfg);
IReadOnlyDictionary<int, ItemConfig> all = provider.GetConfigsDictionary<ItemConfig>();
ulong version = provider.Version;

var serializer = new ConfigsSerializer();                 // TrustedOnly
string json = serializer.Serialize(provider, "2");        // version 은 문자열, ulong 으로 파싱
var loaded = serializer.Deserialize<ConfigsProvider>(json);  // loaded.Version == 2
```

### ConfigsScriptableObject

```csharp
[CreateAssetMenu(menuName = "Configs/Items")]
public class ItemConfigsAsset : ConfigsScriptableObject<int, ItemConfig> { }

List<Pair<int, ItemConfig>> entries = asset.Configs;
IReadOnlyDictionary<int, ItemConfig> byId = asset.ConfigsDictionary;
provider.AddConfigs(c => c.Id, asset.Configs.ConvertAll(p => p.Value));
```

### Unity 직렬화

```csharp
[Serializable] public class StringIntDictionary : UnitySerializedDictionary<string, int> { }

[Serializable]
public sealed class ItemTypeSelector : EnumSelector<ItemType>
{
    public ItemTypeSelector() : base(ItemType.Weapon) { }
    public ItemTypeSelector(ItemType value) : base(value) { }
}

// Editor 어셈블리
[CustomPropertyDrawer(typeof(ItemTypeSelector))]
public sealed class ItemTypeSelectorDrawer : GeunedaEditor.GameData.EnumSelectorPropertyDrawer<ItemType> { }

ItemType type = selector.GetSelection();  // 또는 암시적 변환 ItemType t = selector;
```

### floatP

```csharp
floatP a = 3.14f;                 // float -> floatP 암시적
floatP b = 2;                     // int -> floatP 암시적
floatP c = MathfloatP.Sqrt(a * b);
float f = c;                      // floatP -> float 암시적
int i = c;                        // floatP -> int 암시적 (소수부 버림)
```

### 보안 값 (v1.2.0)

```csharp
public class Wallet { public SecureInt Gold; }   // JSON 은 {"Gold":100} (int 필드와 같은 형식)

wallet.Gold = 100;                // int 에서 암시적 변환, 쓸 때마다 새 nonce 로 재인코딩
wallet.Gold += 50;                // 산술·비교·++ 는 int 처럼
int gold = wallet.Gold;           // 읽을 때 변조 검사

SecureFloatP hp = (floatP)10;
hp -= (floatP)2.5f;               // floatP 와 섞은 연산은 그대로
floatP half = hp.Value * 2;       // SecureFloatP 끼리·정수 리터럴과는 Value 로 꺼내서

SecureValueMonitor.TamperDetected += OnTamper;  // static 이벤트(D2 예외)
void OnTamper(Type valueType)
{
    SecureValueMonitor.TamperDetected -= OnTamper;  // 감지된 읽기마다 발생하므로 첫 감지만 처리
    // 로그 전송, 감지 시점을 숨기려면 무작위 지연 뒤 대응
}
```

### 유효성 검사 / 마이그레이션 (에디터)

```csharp
public class EnemyConfig
{
    [Required] public string Name;
    [Geuneda.DataExtensions.Range(1, 1000)] public int Health;
    [MinLength(1)] public List<string> Tags;
}

ValidationResult result = EditorConfigValidator.ValidateAll(provider); // result.IsValid, result.Errors

[ConfigMigration(typeof(EnemyConfig))]
public class EnemyConfigMigration_v1_v2 : IConfigMigration
{
    public ulong FromVersion => 1;
    public ulong ToVersion => 2;
    public void Migrate(JObject configJson) { configJson["Armor"] = 10; }
}
```

## 함정

- `ObservableField.Value` setter 는 같은 값이어도 항상 통지한다. 중복 통지를 막으려면 호출 쪽에서 비교한다.
- 모든 Observable 과 `ComputedField` 는 변경 연산이 시작될 때 구독자 목록을 고정하고 구독 순서대로 부른다(Remove/Clear 도 같음). 콜백 안에서 구독을 해제해도 다른 구독자를 건너뛰거나 두 번 부르지 않고, 아직 안 불린 구독자를 해제하면 그 등록은 이번 통지에서 빠진다(중복 구독은 해제한 건만, `StopObserving(key)`/`StopObservingAll()` 포함). 통지 도중 새로 구독한 콜백은 다음 연산부터 받는다. 의존 갱신(`ComputedField` 무효화)만은 알리는 시점의 의존 관계 전체에 보낸다. 배치가 끝나면 컬렉션은 항목 통지 뒤 의존 갱신을 한 번 보내고(남은 항목이 없어도), 재개 콜백이나 `Clear` 의 `Removed` 콜백이 새 배치를 열면 남은 재개 통지와 의존 갱신은 그 배치가 끝날 때 보낸다(v1.1.0).
- 구독자가 예외를 던져도 나머지 구독자와 의존 갱신(`ComputedField`)은 끝까지 진행한 뒤 예외를 다시 던진다. 하나면 원래 예외 그대로, 여럿이면 `AggregateException` 이고 데이터 변경은 되돌리지 않는다. `ObservableBatch.Dispose` 도 모든 Observable 을 재개한 뒤 던진다(v1.1.0. 1.0.4 까지는 첫 예외에서 통지가 멈췄고 배치 뒤쪽 Observable 은 배치 상태에 남았다).
- `ObservableDictionary` 의 `ObservableUpdateFlag` 기본값은 `KeyUpdateOnly` 다. 키 없는 `Observe(action)` 구독은 `UpdateOnly` 나 `Both` 로 바꾸기 전에는 호출되지 않는다.
- `ObservableDictionary` 인덱서 setter 는 이전 값을 먼저 읽으므로 없는 키에 쓰면 `KeyNotFoundException` 이다. 새 키는 `Add` 로 넣는다.
- `ObservableList` 생성자에 `List<T>` 를 넘기면 복사하지 않고 그 인스턴스를 그대로 감싼다. 원본 리스트를 직접 고치면 통지가 나가지 않는다. `ReadOnlyList` 는 호출마다 새 `List<T>` 를 할당한다.
- `ObservableList.InvokeObserve(index, action)` 과 `ObservableDictionary.InvokeObserve(key, action)` 은 구독 후 `InvokeUpdate` 를 호출하므로 새 콜백뿐 아니라 해당 인덱스/키를 받는 기존 구독자에게도 `Updated` 가 전달된다. `ObservableField.InvokeObserve` 는 새 콜백만 호출한다.
- 컬렉션(List/Dictionary/HashSet)을 배치에 넣으면 배치 종료 시 변경분이 아니라 전체 요소에 대해 통지한다. List/Dictionary 는 이전 값 `default` 의 `Updated`, HashSet 은 `Added` 다.
- `ComputedField` 는 다 쓰면 `Dispose()` 해야 원본 Observable 의 의존성 구독이 풀린다. `Select`/`CombineWith` 결과도 `ComputedField` 다.
- `StopObservingAll()` 은 `Observe` 콜백만 지운다. `ComputedField` 가 걸어 둔 의존성 구독은 남는다.
- `ConfigsProvider.TryGetConfig<T>(int id, out T)` 와 `GetConfig<T>(int id)`, `GetConfigsDictionary<T>()` 는 등록되지 않은 타입에 대해 `KeyNotFoundException` 을 던진다. `TryGetConfig<T>(out T)` (싱글톤)만 타입이 없을 때 false 를 반환한다.
- 같은 타입으로 `AddConfigs`/`AddSingletonConfig` 를 두 번 호출하면 `ArgumentException` 이다. 교체는 `AddAllConfigs` 또는 `UpdateTo` 를 쓴다. 버전은 `UpdateTo(version, configs)` 로만 바꿀 수 있다(`SetVersion` 은 internal).
- `GetConfigsList<T>()` 는 호출마다 새 `List<T>` 를 할당한다. `EnumerateConfigs<T>()` 는 복사는 없지만 `IEnumerable<T>` 반환이라 foreach 마다 열거자 박싱 1회가 생긴다. 매 프레임 루프라면 초기화 때 `GetConfigsList<T>()` 로 한 번 캐싱하고 인덱스로 순회한다.
- `ConfigsSerializer.Serialize` 는 `[Serializable]` 이 없는 설정 타입에서 예외를 던진다. 서버로 보내지 않을 타입은 `[IgnoreServerSerialization]` 을 붙인다.
- `TrustedOnly` 는 `Serialize` 한 타입만 자동으로 허용 목록에 넣는다. 새 `ConfigsSerializer` 로 역직렬화할 때는 먼저 `RegisterAllowedTypes(IEnumerable<Type>)` 나 `RegisterAllowedTypesFromProvider` 를 호출한다. `Secure` 모드는 타입 메타데이터가 없어 역직렬화할 수 없다(신뢰할 수 없는 대상에 보내는 직렬화 전용).
- `ConfigsScriptableObject.ConfigsDictionary` 는 `OnAfterDeserialize` 에서만 다시 만들어진다. 런타임에 `Configs` 를 바꿔도 반영되지 않는다. 중복 키는 에러 로그 후 건너뛴다.
- `EnumSelector<T>` 의 저장 필드는 `HideInInspector` 다. 하위 클래스와 `EnumSelectorPropertyDrawer<T>` 하위 드로어가 없으면 인스펙터에 보이지 않는다. 생성자가 private/protected 이므로 `new EnumSelector<T>()` 도 불가능하다.
- `UnitySerializedDictionary` 는 abstract 다. `[Serializable]` 구체 클래스를 선언한다.
- `floatP` 는 `float`/`int` 로 암시적 변환되므로 `Mathf.Sqrt(x)` 같은 float API 에 그대로 넘겨도 컴파일된다. 그 순간 결정론이 깨진다. 결정론이 필요한 계산은 `MathfloatP` 만 쓴다. `MathfloatP.Pow2(x)` 는 x 의 제곱이다.
- 보안 값(`SecureInt` 등)은 가벼운 난독화이고 검사값은 MAC 이 아니다. 알고리즘을 아는 공격자는 화면에 보이는 값 하나와 그 16바이트 메모리로 검사값을 맞춘 위조와 세션 키 복원이 가능하니 재화 지급 같은 판정은 서버가 검증한다. 모든 필드를 0 으로 지우는 변조는 `default`(0)와 같아 감지하지 못하고, 32비트 nonce 는 프로세스 전체 쓰기 2^32-1 회마다 순환한다.
- 보안 값은 Unity 직렬화(`[SerializeField]`, 인스펙터, `JsonUtility`)를 지원하지 않는다. 세이브는 Newtonsoft JSON 으로 한다(평문 숫자). `SecureFloatP` 의 JSON 은 float 숫자라 NaN payload 는 남지 않고 Unity(Mono)에서 -0 은 0 이 된다.
- 한 보안 값 필드를 여러 스레드가 동시에 쓰고 읽으면 16바이트 복사가 원자적이지 않아 정상 값이 변조로 감지될 수 있다. 공유하면 잠금으로 보호한다.
- `SecureValueMonitor.TamperDetected` 는 값을 읽은 스레드에서 불린다. 다른 스레드에서 읽는 값이면 Unity API 호출 전에 `MainThreadDispatcher.Post`(core)로 넘긴다.
- `Geuneda.DataExtensions.RangeAttribute` 는 `UnityEngine.RangeAttribute` 와 이름이 같다. 두 `using` 이 함께 있으면 전체 이름이나 별칭으로 구분한다.
- `ObservableDebugRegistry`, `ConfigsProviderDebugRegistry` 의 멤버는 `#if UNITY_EDITOR` 안에만 있다. 런타임 코드에서 호출하지 않는다.
