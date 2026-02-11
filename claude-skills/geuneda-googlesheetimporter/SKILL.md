---
name: geuneda-googlesheetimporter
description: Google 스프레드시트 데이터를 Unity ScriptableObject로 임포트하는 패키지. Unity 프로젝트에서 Google 시트 데이터를 파싱하거나, CSV 데이터를 역직렬화하거나, 시트 임포터를 작성/수정할 때 사용한다.
---

# Geuneda GoogleSheetImporter

Google 스프레드시트의 데이터를 Unity ScriptableObject 설정 데이터로 가져오는 에디터 도구 패키지이다. CSV 형식으로 시트를 다운로드하여 파싱하고, 리플렉션 기반으로 다양한 데이터 타입을 역직렬화하여 ScriptableObject에 저장한다.

## 활성화 시점

- Google 스프레드시트에서 게임 데이터를 임포트하는 코드를 작성할 때
- CSV 텍스트를 파싱하거나 역직렬화할 때
- 커스텀 시트 임포터를 작성할 때
- CsvParser를 사용하여 데이터를 변환할 때
- ParseIgnoreAttribute를 사용하여 필드를 파싱에서 제외할 때

## 패키지 정보

- **런타임 네임스페이스**: `Geuneda.GoogleSheetImporter`
- **에디터 네임스페이스**: `GeunedaEditor.GoogleSheetImporter`
- **설치**: `https://github.com/geuneda/geuneda-googlesheetimporter.git`
- **Unity 버전**: 6000.0 이상
- **의존성**:
  - `com.unity.nuget.newtonsoft-json` (2.0.0)
  - `com.geuneda.gamedata` (1.0.0)

## 핵심 API

### CsvParser (정적 클래스, 런타임)

CSV 텍스트를 파싱하고 다양한 타입으로 역직렬화하는 핵심 유틸리티.

```csharp
// CSV 전체 파싱 - 헤더를 키로 사용하는 딕셔너리 리스트 반환
static List<Dictionary<string, string>> ConvertCsv(string csv);

// 딕셔너리를 지정된 타입의 객체로 역직렬화
static T DeserializeTo<T>(Dictionary<string, string> data, params Func<string, Type, object>[] deserializers);
static object DeserializeTo(Type type, Dictionary<string, string> data, params Func<string, Type, object>[] deserializers);

// 단일 셀 값을 객체로 역직렬화 (배열, 리스트, 딕셔너리 자동 감지)
static object DeserializeObject(string data, Type type, params Func<string, Type, object>[] deserializers);

// 서브 리스트 역직렬화 (복합 타입의 중첩 리스트)
static object DeserializeSubList(List<Dictionary<string, string>> data, int startIndex, Type type, string fieldName, params Func<string, Type, object>[] deserializers);

// 단일 값 파싱
static T Parse<T>(string text, params Func<string, Type, object>[] deserializers);
static object Parse(string text, Type type, params Func<string, Type, object>[] deserializers);

// 배열/리스트 파싱
static List<T> ArrayParse<T>(string text, params Func<string, Type, object>[] deserializers);

// 딕셔너리 파싱
static Dictionary<TKey, TValue> DictionaryParse<TKey, TValue>(string text, params Func<string, Type, object>[] deserializers);
```

### ParseIgnoreAttribute (어트리뷰트, 런타임)

CsvParser에서 특정 필드의 파싱을 무시하게 하는 어트리뷰트.

```csharp
[ParseIgnore]
public string IgnoredField;
```

### IGoogleSheetConfigsImporter (인터페이스, 에디터)

Google 시트 임포터의 기본 인터페이스.

```csharp
string GoogleSheetUrl { get; }
void Import(List<Dictionary<string, string>> data);
```

### GoogleSheetScriptableObjectImportContainer\<TScriptableObject\> (추상 클래스, 에디터)

ScriptableObject에 임포트 결과를 저장하는 기본 컨테이너.

### GoogleSheetConfigsImporter\<TConfig, TScriptableObject\> (추상 클래스, 에디터)

행 단위로 데이터를 임포트 (1행 = 1개 TConfig 항목).

### GoogleSheetSingleConfigImporter\<TConfig, TScriptableObject\> (추상 클래스, 에디터)

시트 전체를 하나의 TConfig 객체로 임포트 (Key/Value 쌍).

### GoogleSheetSingleConfigSubListImporter\<TConfig, TScriptableObject\> (추상 클래스, 에디터)

단일 설정 내 서브 리스트 임포트를 지원하는 확장.

### GoogleSheetImportOrderAttribute (어트리뷰트, 에디터)

임포트 순서를 제어하는 어트리뷰트. 값이 작을수록 먼저 임포트된다.

```csharp
[GoogleSheetImportOrder(0)]
public class MyImporter : IGoogleSheetConfigsImporter { ... }
```

## 사용 패턴

### 행 단위 데이터 임포트 (가장 일반적)

```csharp
// 1. 데이터 구조체 정의
public struct EnemyConfig
{
    public string Name;
    public int Health;
    public float Speed;
    [ParseIgnore] public string EditorNote; // 파싱 무시
}

// 2. ScriptableObject 정의 (IConfigsContainer<T> 구현)
public class EnemyConfigs : ScriptableObject, IConfigsContainer<EnemyConfig>
{
    [SerializeField] private List<EnemyConfig> _configs;
    public List<EnemyConfig> Configs { get => _configs; set => _configs = value; }
}

// 3. 임포터 정의
public class EnemyConfigsImporter : GoogleSheetConfigsImporter<EnemyConfig, EnemyConfigs>
{
    public override string GoogleSheetUrl =>
        "https://docs.google.com/spreadsheets/d/SHEET_ID/edit#gid=TAB_ID";
}
```

### 단일 설정 임포트 (Key/Value 형식)

```csharp
public class GameConfigsImporter : GoogleSheetSingleConfigImporter<GameConfig, GameConfigs>
{
    public override string GoogleSheetUrl => "https://docs.google.com/.../edit#gid=...";

    protected override GameConfig Deserialize(List<Dictionary<string, string>> data)
    {
        var config = new GameConfig() as object;
        var type = typeof(GameConfig);

        foreach (var row in data)
        {
            var field = type.GetField(row["Key"]);
            field.SetValue(config, CsvParser.Parse(row["Value"], field.FieldType));
        }

        return (GameConfig)config;
    }
}
```

### 코드 생성 임포터 (enum/lookup 자동 생성)

```csharp
[GoogleSheetImportOrder(0)] // 다른 임포터보다 먼저 실행
public class GameIdsImporter : IGoogleSheetConfigsImporter
{
    public string GoogleSheetUrl => "https://docs.google.com/.../edit#gid=...";

    public void Import(List<Dictionary<string, string>> data)
    {
        // data를 기반으로 enum 코드 생성
        // File.WriteAllText()로 스크립트 저장
        AssetDatabase.Refresh();
    }
}
```

### CsvParser 직접 사용

```csharp
// CSV 텍스트를 딕셔너리 리스트로 변환
var data = CsvParser.ConvertCsv(csvText);

// 배열 파싱: "1,2,3" 또는 "[1,2,3]" 또는 "{1,2,3}"
var numbers = CsvParser.ArrayParse<int>("1,[2],{3}");

// 딕셔너리 파싱: "key1:value1,key2:value2"
var dict = CsvParser.DictionaryParse<string, int>("hp:100,mp:50");

// 커스텀 역직렬화기 전달
var result = CsvParser.DeserializeTo<MyType>(data[0],
    (text, type) => {
        if (type == typeof(MyCustomType))
            return ParseMyCustomType(text);
        return null;
    }
);
```

## CSV 형식 규칙

- 행 구분자: `\r\n` (CRLF) - Google 시트 CSV 내보내기 형식
- 첫 번째 행: 헤더 (필드 이름)
- `$`로 시작하는 열: 파싱에서 무시 (주석용)
- `#`으로 시작하는 Key: 서브 리스트의 데이터 행
- `[]` 접미사: 서브 리스트 필드 표시
- 배열 구분자: `,`, `()`, `[]`, `{}`
- 키-값 쌍 구분자: `:`, `<`, `>`, `=`, `|`

## 지원하는 데이터 타입

- 원시 타입: `int`, `float`, `double`, `string`, `bool` 등
- `enum` 타입
- `DateTime`, `TimeSpan`
- `Nullable<T>` (예: `int?`, `float?`)
- `List<T>`, 배열
- `Dictionary<TKey, TValue>`, `UnitySerializedDictionary<TKey, TValue>`
- `KeyValuePair<TKey, TValue>` 형태의 커스텀 구조체 (Key/Value 또는 Value1/Value2 필드)
- Newtonsoft.Json으로 역직렬화 가능한 참조 타입

## 주의사항

- CSV 행 구분자는 반드시 `\r\n` (CRLF)이어야 한다. `\n`만 사용하면 빈 결과가 반환된다
- Google 시트 URL은 `edit#gid=`를 포함해야 하며, 이 부분이 `export?format=csv&`로 변환된다
- `DeserializeTo`는 리플렉션 기반이므로 public 필드만 처리된다
- 커스텀 타입 파싱이 필요하면 `deserializers` 파라미터로 커스텀 역직렬화 함수를 전달해야 한다
- `GoogleSheetImportOrderAttribute`를 사용하여 임포트 순서를 제어할 수 있다 (기본: int.MaxValue)
- `com.geuneda.gamedata` 패키지의 `IConfigsContainer<T>`, `ISingleConfigContainer<T>`, `UnitySerializedDictionary<TKey, TValue>` 타입을 사용한다

## 참조 문서

상세 API 문서는 `references/api.md` 참조.
