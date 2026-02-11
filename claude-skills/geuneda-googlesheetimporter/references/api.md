# Geuneda GoogleSheetImporter API Reference

## Runtime API

네임스페이스: `Geuneda.GoogleSheetImporter`

---

### CsvParser (정적 클래스)

CSV 텍스트를 파싱하는 헬퍼 클래스.

#### 상수 및 필드

| 이름 | 타입 | 값 | 설명 |
|------|------|-----|------|
| `IGNORE_COLUMN_CHAR` | `string` | `"$"` | 무시할 열의 접두사 |
| `IGNORE_FIELD_CHAR` | `string` | `"#"` | 무시할 필드/서브리스트 행의 Key 값 |
| `SUB_LIST_SUFFIX` | `string` | `"[]"` | 서브 리스트 필드 접미사 |
| `PairSplitChars` | `char[]` | `{ ':', '<', '>', '=', '\|' }` | 키-값 쌍 구분 문자 |
| `ArraySplitChars` | `char[]` | `{ ',', '(', ')', '[', ']', '{', '}' }` | 배열 구분 문자 |
| `NewLineChars` | `string[]` | `{ "\r\n", "\r", "\n" }` | 줄바꿈 문자 |

#### 메서드

##### ConvertCsv

```csharp
public static List<Dictionary<string, string>> ConvertCsv(string csv)
```

전체 CSV 텍스트를 파싱한다. 각 행은 리스트의 요소이며, 각 열은 딕셔너리의 요소이다. 딕셔너리 키는 CSV 헤더가 된다.

- **매개변수**: `csv` - CSV 형식의 텍스트 (행 구분자: `\r\n`)
- **반환**: `List<Dictionary<string, string>>` - 파싱된 데이터
- **참고**: `$`로 시작하는 열 헤더는 무시된다

##### DeserializeTo\<T\>

```csharp
public static T DeserializeTo<T>(Dictionary<string, string> data, params Func<string, Type, object>[] deserializers)
public static object DeserializeTo(Type type, Dictionary<string, string> data, params Func<string, Type, object>[] deserializers)
```

CSV 데이터 행(딕셔너리)을 지정된 타입의 객체로 역직렬화한다. 리플렉션으로 public 필드를 매핑한다.

- `[ParseIgnore]` 어트리뷰트가 있는 필드는 무시된다
- 딕셔너리에 없는 필드는 기본값으로 유지된다

##### DeserializeObject

```csharp
public static object DeserializeObject(string data, Type type, params Func<string, Type, object>[] deserializers)
```

단일 셀 값을 지정된 타입으로 역직렬화한다. 배열, 리스트, 딕셔너리, 단일 값을 자동으로 감지한다.

- 배열(`T[]`): `ArrayParse` 호출
- `IList`: `ArrayParse` 호출
- `UnitySerializedDictionary<,>` 파생: `DictionaryParse` 호출
- `IDictionary`: `DictionaryParse` 호출
- 그 외: `Parse` 호출

##### DeserializeSubList

```csharp
public static object DeserializeSubList(List<Dictionary<string, string>> data, int startIndex, Type type, string fieldName, params Func<string, Type, object>[] deserializers)
```

복합(비원시) 타입의 서브 리스트를 역직렬화한다. `startIndex` 행의 값이 서브 리스트 필드의 헤더가 되고, 이후 행들(`Key == "#"`)이 데이터가 된다.

##### Parse\<T\>

```csharp
public static T Parse<T>(string text, params Func<string, Type, object>[] deserializers)
public static object Parse(string text, Type type, params Func<string, Type, object>[] deserializers)
```

단일 텍스트를 지정된 타입으로 파싱한다.

파싱 순서:
1. `string` -> 그대로 반환
2. `enum` -> `Enum.Parse(type, text)`
3. `KeyValuePair` 형태의 구조체 -> `Activator.CreateInstance(type, key, value)`
4. 커스텀 `deserializers` 함수들 시도
5. `DateTime` -> `DateTime.Parse(text)`
6. `TimeSpan` -> `TimeSpan.Parse(text)`
7. `Nullable<T>` -> `TypeDescriptor.GetConverter(type).ConvertFrom(text)`
8. 값 타입 -> `Convert.ChangeType(text, type)`
9. 참조 타입 -> `JsonConvert.DeserializeObject($"\"{text}\"", type)`

##### ArrayParse\<T\>

```csharp
public static List<T> ArrayParse<T>(string text, params Func<string, Type, object>[] deserializers)
public static object ArrayParse(string data, Type type, params Func<string, Type, object>[] deserializers)
```

텍스트를 지정된 타입의 리스트로 파싱한다. `ArraySplitChars`로 분리한다.

- 예: `"1,2,3"` -> `[1, 2, 3]`
- 예: `"[1,2]{3,4}(5)"` -> `[1, 2, 3, 4, 5]`

##### DictionaryParse\<TKey, TValue\>

```csharp
public static Dictionary<TKey, TValue> DictionaryParse<TKey, TValue>(string text, params Func<string, Type, object>[] deserializers)
```

텍스트를 딕셔너리로 파싱한다.

- 쌍 형식: `"key1:value1,key2:value2"` (PairSplitChars 사용)
- 연속 형식: `"key1,value1,key2,value2"` (짝수 개 필요)
- 빈 데이터 -> `null` 반환
- 홀수 개의 값 -> `IndexOutOfRangeException` 발생

---

### ParseIgnoreAttribute (어트리뷰트)

`CsvParser.DeserializeTo`에서 특정 필드의 파싱을 무시하게 하는 어트리뷰트.

- 대상: `AttributeTargets.Field`
- 사용: `[ParseIgnore] public string FieldName;`

---

## Editor API

네임스페이스: `GeunedaEditor.GoogleSheetImporter`

---

### IScriptableObjectImporter (인터페이스)

단일 ScriptableObject를 임포트하기 위한 인터페이스.

#### 프로퍼티

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `ScriptableObjectType` | `Type` | 저장될 ScriptableObject의 타입 |

---

### IGoogleSheetConfigsImporter (인터페이스)

Google 시트 임포터의 기본 인터페이스.

#### 프로퍼티

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `GoogleSheetUrl` | `string` | 전체 Google 시트 URL |

#### 메서드

| 메서드 | 반환 타입 | 설명 |
|--------|-----------|------|
| `Import(List<Dictionary<string, string>> data)` | `void` | CsvParser.ConvertCsv에서 처리된 데이터를 임포트 |

---

### GoogleSheetScriptableObjectImportContainer\<TScriptableObject\> (추상 클래스)

임포트 결과를 ScriptableObject에 저장하는 기본 컨테이너.

- 구현: `IScriptableObjectImporter`, `IGoogleSheetConfigsImporter`
- 제약 조건: `TScriptableObject : ScriptableObject`
- `Import()`: ScriptableObject를 찾거나 생성하고, `OnImport()` 호출 후 `EditorUtility.SetDirty()` 및 `OnImportComplete()` 호출

#### 추상/가상 메서드

| 메서드 | 설명 |
|--------|------|
| `GoogleSheetUrl` (abstract) | Google 시트 URL |
| `OnImport(TScriptableObject, List<Dictionary<string, string>>)` (abstract, protected) | 실제 임포트 로직 |
| `OnImportComplete(TScriptableObject)` (virtual, protected) | 임포트 완료 후 콜백 |

---

### GoogleSheetConfigsImporter\<TConfig, TScriptableObject\> (추상 클래스)

행 단위로 데이터를 임포트한다. 각 행이 1개의 `TConfig` 항목을 나타낸다.

- 상속: `GoogleSheetScriptableObjectImportContainer<TScriptableObject>`
- 제약 조건: `TConfig : struct`, `TScriptableObject : ScriptableObject, IConfigsContainer<TConfig>`
- `OnImport()`: 각 행을 `Deserialize()`로 변환하여 `scriptableObject.Configs`에 저장

#### 가상 메서드

| 메서드 | 반환 타입 | 설명 |
|--------|-----------|------|
| `Deserialize(Dictionary<string, string> data)` (virtual, protected) | `TConfig` | 기본: `CsvParser.DeserializeTo<TConfig>(data)` |

---

### GoogleSheetSingleConfigImporter\<TConfig, TScriptableObject\> (추상 클래스)

시트 전체를 하나의 `TConfig` 객체로 임포트한다. Key/Value 형태의 시트에 적합하다.

- 상속: `GoogleSheetScriptableObjectImportContainer<TScriptableObject>`
- 제약 조건: `TConfig : struct`, `TScriptableObject : ScriptableObject, ISingleConfigContainer<TConfig>`
- `OnImport()`: `Deserialize()`로 전체 데이터를 변환하여 `scriptableObject.Config`에 저장

#### 추상 메서드

| 메서드 | 반환 타입 | 설명 |
|--------|-----------|------|
| `Deserialize(List<Dictionary<string, string>> data)` (abstract, protected) | `TConfig` | 전체 시트 데이터를 단일 설정으로 변환 |

---

### GoogleSheetSingleConfigSubListImporter\<TConfig, TScriptableObject\> (추상 클래스)

단일 설정 내 서브 리스트 임포트를 지원하는 확장.

- 상속: `GoogleSheetSingleConfigImporter<TConfig, TScriptableObject>`
- `Deserialize()`: Key/Value 행을 순회하며 `[]` 접미사가 있는 필드는 `CsvParser.DeserializeSubList()`로 처리

#### 추상 메서드

| 메서드 | 반환 타입 | 설명 |
|--------|-----------|------|
| `GetDeserializers()` (abstract, protected) | `Func<string, Type, object>[]` | 커스텀 역직렬화 함수 배열 반환 |

---

### GoogleSheetImportOrderAttribute (어트리뷰트)

임포트 순서를 제어하는 어트리뷰트.

- 대상: `AttributeTargets.Class`
- 기본 순서: `int.MaxValue` (어트리뷰트 없으면 마지막에 실행)
- 값이 작을수록 먼저 임포트된다
- 같은 순서 값이면 클래스 이름의 알파벳 순서로 정렬

#### 프로퍼티

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `ImportOrder` | `int` | 임포트 순서 값 |

#### 생성자

```csharp
public GoogleSheetImportOrderAttribute(int importOrder)
```

---

### GoogleSheetImporter (ScriptableObject)

Google 시트 임포트 도구의 설정 ScriptableObject.

- CreateAssetMenu: `ScriptableObjects/Editor/GoogleSheetImporter`

#### 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `ReplaceSpreadsheetId` | `string` | (선택) 기본 시트 ID를 대체할 Spreadsheet ID. 테스트용 시트 복제 시 사용 |

#### 메뉴

- `Tools/GoogleSheet Importer/Select GoogleSheetImporter.asset`: 설정 에셋 선택

---

### GoogleSheetToolImporter (CustomEditor)

`GoogleSheetImporter`의 커스텀 인스펙터. 모든 `IGoogleSheetConfigsImporter` 구현체를 검색하고 관리한다.

#### 메뉴

- `Tools/GoogleSheet Importer/Import Google Sheet Data`: 모든 시트 데이터 임포트

#### 기능

- 모든 `IGoogleSheetConfigsImporter` 구현체를 자동 검색
- `GoogleSheetImportOrderAttribute` 순서대로 정렬
- 개별 또는 전체 시트 임포트 버튼 제공
- ScriptableObject 선택 버튼 제공
- `ReplaceSpreadsheetId`로 시트 ID 대체 가능

#### 임포트 프로세스

1. Google 시트 URL에서 `edit#`를 `export?format=csv&`로 변환
2. `UnityWebRequest.Get()`으로 CSV 데이터 다운로드
3. `CsvParser.ConvertCsv()`로 CSV 파싱
4. `IGoogleSheetConfigsImporter.Import()`로 데이터 임포트

---

## 시트 URL 형식

Google 시트 URL은 다음 형식이어야 한다:

```
https://docs.google.com/spreadsheets/d/{SPREADSHEET_ID}/edit#gid={SHEET_TAB_ID}
```

- `SPREADSHEET_ID`: 스프레드시트 고유 ID
- `SHEET_TAB_ID`: 특정 시트 탭의 ID
- 시트는 반드시 공개 접근 가능(링크가 있는 모든 사용자)이거나 인증이 되어 있어야 한다
