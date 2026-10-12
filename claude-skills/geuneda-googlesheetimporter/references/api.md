# Geuneda GoogleSheetImporter API

`com.geuneda.googlesheetimporter` 의 공개 API 전체. 사용 패턴과 함정은 [../SKILL.md](../SKILL.md) 참고.

## 런타임 (`Geuneda.GoogleSheetImporter`, 어셈블리 `Geuneda.GoogleSheetImporter`)

### `public static class CsvParser`

#### 상수와 필드

| 이름 | 선언 | 값 | 쓰임 |
|------|------|-----|------|
| `IGNORE_COLUMN_CHAR` | `public const string` | `"$"` | 이 문자로 시작하는 헤더 열은 `ConvertCsv` 가 무시 |
| `IGNORE_FIELD_CHAR` | `public const string` | `"#"` | 이 문자로 시작하는 줄은 `ConvertCsv` 가 건너뜀. 서브 리스트 데이터 행의 `Key` 값 |
| `SUB_LIST_SUFFIX` | `public const string` | `"[]"` | 서브 리스트 필드 표시 접미사 |
| `PairSplitChars` | `public static readonly char[]` | `':' '<' '>' '=' '\|'` | 키-값 쌍 구분 |
| `ArraySplitChars` | `public static readonly char[]` | `',' '(' ')' '[' ']' '{' '}'` | 배열 요소 구분 |
| `NewLineChars` | `public static readonly string[]` | `"\r\n" "\r" "\n"` | 선언만 있고 패키지 내부에서는 쓰지 않음 |

#### `ConvertCsv`

```csharp
public static List<Dictionary<string, string>> ConvertCsv(string csv)
```

- `"\r\n"` 으로만 줄을 나눈다. 첫 줄이 헤더이며 딕셔너리 키가 된다.
- `#` 으로 시작하는 줄은 건너뛴다.
- `$` 로 시작하는 헤더 열은 결과에 넣지 않는다.
- 값은 `Trim()` 되고, 값이 모자란 열은 `""` 로 채운다.
- 헤더만 있거나 `\n` 만 쓰는 텍스트는 빈 리스트를 반환한다.

#### `DeserializeTo`

```csharp
public static T DeserializeTo<T>(Dictionary<string, string> data, params Func<string, Type, object>[] deserializers)
public static object DeserializeTo(Type type, Dictionary<string, string> data, params Func<string, Type, object>[] deserializers)
```

`Activator.CreateInstance(type)` 로 인스턴스를 만들고 `type.GetFields()`(public 필드)를 돈다. `data` 에 필드 이름 키가 없거나 `[ParseIgnore]` 가 붙은 필드는 건너뛰고, 나머지는 `DeserializeObject(data[field.Name], field.FieldType, deserializers)` 로 채운다.

#### `DeserializeObject`

```csharp
public static object DeserializeObject(string data, Type type, params Func<string, Type, object>[] deserializers)
```

| 조건 | 처리 |
|------|------|
| `type.IsArray` | `ArrayParse(data, elementType)` (반환은 `List<T>`) |
| `IList` 할당 가능 | `ArrayParse(data, GenericTypeArguments[0])` |
| 직접 기반 타입이 `UnitySerializedDictionary<,>` | 해당 파생 타입 인스턴스로 딕셔너리 파싱 |
| `IDictionary` 할당 가능 | `Dictionary<K, V>` 로 딕셔너리 파싱 |
| 그 외 | `Parse(data, type)` |

배열 필드는 `List<T>` 가 반환되므로 `T[]` 필드에 `field.SetValue` 하면 실패한다. 리스트 필드는 `List<T>` 로 선언한다.

#### `DeserializeSubList`

```csharp
public static object DeserializeSubList(List<Dictionary<string, string>> data, int startIndex, Type type, string fieldName, params Func<string, Type, object>[] deserializers)
```

- `type.GetGenericArguments()[0]` 을 원소 타입으로 하는 `List<T>` 를 만들어 반환한다.
- `data[startIndex]` 행에서 값이 `[]` 로 끝나지 않는 열마다 "열 이름 -> 하위 필드 이름" 매핑을 만든다.
- `startIndex + 1` 부터 `Key` 열 값이 `"#"` 인 행을 읽어 `DeserializeTo(원소 타입, ...)` 로 변환한다. 다른 값이 나오면 멈춘다.
- `fieldName` 은 현재 사용되지 않는다.

#### `Parse`

```csharp
public static T Parse<T>(string text, params Func<string, Type, object>[] deserializers)
public static object Parse(string text, Type type, params Func<string, Type, object>[] deserializers)
```

`text` 를 `Trim()` 한 뒤 다음 순서로 시도한다.

1. `string` -> 그대로
2. enum -> `Enum.Parse(type, text)`
3. 제네릭 값 타입이고 public 필드가 정확히 2개이며 이름이 (`Key` 또는 `Value1`), (`Value` 또는 `Value2`) -> `PairSplitChars` 로 나눠 각각 `Parse` 한 뒤 `Activator.CreateInstance(type, key, value)`
4. `deserializers` 를 순서대로 호출해 처음으로 `null` 이 아닌 결과
5. `DateTime` -> `DateTime.Parse(text)`
6. `TimeSpan` -> `TimeSpan.Parse(text)`
7. `Nullable<T>` -> `TypeDescriptor.GetConverter(type).ConvertFrom(text)` (빈 텍스트는 `null`)
8. 값 타입 -> `Convert.ChangeType(text, type)` (현재 컬처)
9. 참조 타입 -> `JsonConvert.DeserializeObject($"\"{text}\"", type)`

변환할 수 없으면 `FormatException` 등 하위 API 의 예외가 그대로 전파된다.

#### `ArrayParse`

```csharp
public static List<T> ArrayParse<T>(string text, params Func<string, Type, object>[] deserializers)
public static object ArrayParse(string data, Type type, params Func<string, Type, object>[] deserializers)
```

`ArraySplitChars` 로 나누고(빈 항목 제거) 각 항목을 `Parse` 해 `List<type>` 을 만든다. 예: `"1,[2],{3,4},(5),6"` -> `[1, 2, 3, 4, 5, 6]`. 구분자가 없으면 원소 1개, 빈 텍스트면 빈 리스트.

#### `DictionaryParse`

```csharp
public static Dictionary<TKey, TValue> DictionaryParse<TKey, TValue>(string text, params Func<string, Type, object>[] deserializers)
```

- `ArrayParse<string>` 으로 나눈 항목이 0개면 `null`.
- 첫 항목에 `PairSplitChars` 문자가 있으면 모든 항목을 쌍으로 파싱: `"1:2,(3>4)"` -> `{1:2, 3:4}`.
- 아니면 연속 형식: `"1,2,3,4"` -> `{1:2, 3:4}`. 항목 수가 홀수면 `IndexOutOfRangeException`.
- 중복 키는 `Dictionary.Add` 예외.

### `public class ParseIgnoreAttribute : Attribute`

`[AttributeUsage(AttributeTargets.Field)]`. `DeserializeTo` 가 이 어트리뷰트가 붙은 필드를 건너뛴다.

## 에디터 (`GeunedaEditor.GoogleSheetImporter`, 어셈블리 `Geuneda.GoogleSheetImporter.Editor`)

### `public interface IGoogleSheetConfigsImporter`

```csharp
string GoogleSheetUrl { get; }
void Import(List<Dictionary<string, string>> data);
```

`data` 는 `CsvParser.ConvertCsv` 결과다. 이 인터페이스를 구현한 비추상 타입은 모두 자동 수집된다(public 매개변수 없는 생성자 필요).

### `public interface IScriptableObjectImporter`

```csharp
Type ScriptableObjectType { get; }
```

인스펙터의 **Select Object** 버튼이 이 타입으로 에셋을 찾는다.

### `public interface ICsvSyncTarget`

```csharp
string CsvSyncPath { get; }
```

`IGoogleSheetConfigsImporter` 와 함께 구현하면, `Import` 가 끝난 직후 다운로드한 원본 CSV 를 LF 와 끝 개행 1개로 정규화해 `CsvSyncPath`(프로젝트 상대 경로)에 `File.WriteAllText` 로 쓰고 `AssetDatabase.ImportAsset` 한다. `null`/공백이면 건너뛴다. 실패는 경고 로그만 남긴다.

### `public abstract class GoogleSheetScriptableObjectImportContainer<TScriptableObject>`

`: IScriptableObjectImporter, IGoogleSheetConfigsImporter where TScriptableObject : ScriptableObject`

| 멤버 | 설명 |
|------|------|
| `public abstract string GoogleSheetUrl { get; }` | 시트 URL |
| `public Type ScriptableObjectType` | `typeof(TScriptableObject)` |
| `public void Import(List<Dictionary<string, string>> data)` | `FindAssets("t:<타입 이름>")` 첫 결과를 로드하거나 `Assets/<타입 이름>.asset` 을 생성 -> `OnImport` -> `EditorUtility.SetDirty` -> `OnImportComplete` |
| `protected abstract void OnImport(TScriptableObject scriptableObject, List<Dictionary<string, string>> data)` | 저장 로직 |
| `protected virtual void OnImportComplete(TScriptableObject scriptableObject)` | 후처리. 기본은 빈 구현 |

### `public abstract class GoogleSheetConfigsImporter<TConfig, TScriptableObject>`

`: GoogleSheetScriptableObjectImportContainer<TScriptableObject> where TConfig : struct where TScriptableObject : ScriptableObject, IConfigsContainer<TConfig>`

| 멤버 | 설명 |
|------|------|
| `protected override void OnImport(...)` | 행마다 `Deserialize(row)` 를 호출해 새 리스트를 만들고 `scriptableObject.Configs` 에 대입 |
| `protected virtual TConfig Deserialize(Dictionary<string, string> data)` | 기본: `CsvParser.DeserializeTo<TConfig>(data)` |

### `public abstract class GoogleSheetSingleConfigImporter<TConfig, TScriptableObject>`

`: GoogleSheetScriptableObjectImportContainer<TScriptableObject> where TConfig : struct where TScriptableObject : ScriptableObject, ISingleConfigContainer<TConfig>`

| 멤버 | 설명 |
|------|------|
| `protected override void OnImport(...)` | `scriptableObject.Config = Deserialize(data)` |
| `protected abstract TConfig Deserialize(List<Dictionary<string, string>> data)` | 시트 전체를 설정 1개로 변환 |

### `public abstract class GoogleSheetSingleConfigSubListImporter<TConfig, TScriptableObject>`

`: GoogleSheetSingleConfigImporter<TConfig, TScriptableObject>` (제약 동일)

| 멤버 | 설명 |
|------|------|
| `protected override TConfig Deserialize(List<Dictionary<string, string>> data)` | 각 행의 `Key` 를 필드 이름으로 본다. `[]` 로 끝나면 `CsvParser.DeserializeSubList`, 아니면 `CsvParser.DeserializeObject(row["Value"], ...)`. 없는 필드 이름(예: `#`)은 건너뜀 |
| `protected abstract Func<string, Type, object>[] GetDeserializers()` | 위 두 호출에 넘길 역직렬화기. 없으면 빈 배열 반환 |

시트에 `Key`, `Value` 열이 있어야 한다.

### `public class GoogleSheetImportOrderAttribute : Attribute`

`[AttributeUsage(AttributeTargets.Class)]`

| 멤버 | 설명 |
|------|------|
| `public GoogleSheetImportOrderAttribute(int importOrder)` | 생성자 |
| `public int ImportOrder { get; }` | 작을수록 먼저. 어트리뷰트가 없으면 `int.MaxValue` |

같은 순서 값은 타입 이름의 ordinal 비교로 정렬한다.

### `public class GoogleSheetImporter : ScriptableObject`

- `[CreateAssetMenu(fileName = "GoogleSheetImporter", menuName = "ScriptableObjects/Editor/GoogleSheetImporter")]`
- `public string ReplaceSpreadsheetId`: 비어 있지 않으면 인스펙터에서 실행한 임포트의 URL 에서 `/d/` 와 `/edit` 사이 ID 를 이 값으로 바꾼다.
- 메뉴 `Tools/GoogleSheet Importer/Select GoogleSheetImporter.asset`: 첫 에셋을 선택하고, 없으면 `Assets/GoogleSheetImporter.asset` 을 만든다.

### `public class GoogleSheetToolImporter : Editor`

`[CustomEditor(typeof(GoogleSheetImporter))]`. 공개 멤버는 `OnInspectorGUI()` 와 `[DidReloadScripts] public static void OnCompileScripts()`(임포터 목록 재수집)뿐이다.

- 메뉴 `Tools/GoogleSheet Importer/Import Google Sheet Data`: 전체 임포트. `ReplaceSpreadsheetId` 는 적용되지 않는다.
- 인스펙터: `ReplaceSpreadsheetId` 입력, **Import All Sheets**, 임포터별 **Import**, `IScriptableObjectImporter` 구현체에는 **Select Object**.

임포트 동작:

1. URL 에 `/d/` 와 `/edit` 가 없으면 실패. `edit#` 를 `export?format=csv&` 로 치환해 `UnityWebRequest.Get` 으로 요청한다.
2. 전체 임포트는 최대 6개를 동시에 다운로드한다. 다운로드 중 진행 바에서 취소할 수 있다.
3. HTTP 401/403/429/5xx 는 1초부터 2배씩(최대 60초) 기다리며 최대 6회 시도한다. 그 밖의 오류는 바로 실패.
4. 다운로드가 끝나면 `AssetDatabase.StartAssetEditing`/`StopAssetEditing` 안에서 임포트 순서대로 `ConvertCsv` -> `Import` -> CSV 역동기화를 수행한다. `ConvertCsv` 결과가 비면 "CSV 형식 아님" 경고와 함께 실패로 센다.
5. 끝나면 `SaveAssets`, `Refresh` 후 성공/실패 수를 로그로 남긴다.
6. 임포트 중 도메인 리로드가 일어나면 상태를 초기화하고 경고를 남긴다. 임포트 중 다른 임포트 요청은 무시된다.

## 사용하는 gamedata 타입 (`Geuneda.DataExtensions`, 어셈블리 `Geuneda.GameData`)

```csharp
public interface IConfigsContainer<T> { List<T> Configs { get; set; } }
public interface ISingleConfigContainer<T> { T Config { get; set; } }
public abstract class UnitySerializedDictionary<TKey, TValue> : Dictionary<TKey, TValue>, ISerializationCallbackReceiver
public struct StructPair<TKey, TValue> where TKey : struct where TValue : struct // Key, Value 필드 + (key, value) 생성자
```

## 시트 URL 형식

```
https://docs.google.com/spreadsheets/d/{SPREADSHEET_ID}/edit#gid={SHEET_TAB_ID}
```

시트는 "링크가 있는 모든 사용자" 보기 권한으로 공유해야 한다. 요청에 인증 정보를 붙이지 않는다.
