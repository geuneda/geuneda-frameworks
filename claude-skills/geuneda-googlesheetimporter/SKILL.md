---
name: geuneda-googlesheetimporter
description: com.geuneda.googlesheetimporter 패키지로 Google 스프레드시트를 CSV 로 내려받아 ScriptableObject 설정 데이터로 임포트할 때 사용한다. 시트 임포터(GoogleSheetConfigsImporter, GoogleSheetSingleConfigImporter, GoogleSheetSingleConfigSubListImporter, IGoogleSheetConfigsImporter)를 작성하거나 고칠 때, CsvParser 로 CSV 텍스트나 셀 값을 파싱할 때, 임포트 순서(GoogleSheetImportOrder)나 원본 CSV 역동기화(ICsvSyncTarget)를 설정할 때, 시트 임포트가 비거나 실패하는 원인을 찾을 때 쓴다.
---

# Geuneda GoogleSheetImporter

Google 시트 URL 을 CSV 내보내기 URL 로 바꿔 다운로드하고, `CsvParser` 로 파싱한 뒤 임포터가 ScriptableObject 에 저장하는 에디터 도구다. 전체 공개 API 는 [references/api.md](references/api.md) 에 있다.

## 패키지 정보

- 패키지: `com.geuneda.googlesheetimporter` (버전은 `package.json` 기준, 현재 0.9.0)
- 런타임: 네임스페이스 `Geuneda.GoogleSheetImporter`, 어셈블리 `Geuneda.GoogleSheetImporter` (`CsvParser`, `ParseIgnoreAttribute`)
- 에디터: 네임스페이스 `GeunedaEditor.GoogleSheetImporter`, 어셈블리 `Geuneda.GoogleSheetImporter.Editor` (임포터, 메뉴, 인스펙터)
- 의존성: `com.geuneda.gamedata` 1.0.0(`Geuneda.DataExtensions` 의 `IConfigsContainer<T>`, `ISingleConfigContainer<T>`, `UnitySerializedDictionary<,>`), `com.unity.nuget.newtonsoft-json` 2.0.0
- Unity 6000.0 이상
- 설치: `https://github.com/geuneda/geuneda-googlesheetimporter.git`. gamedata(`https://github.com/geuneda/geuneda-gamedata.git`)와 UniTask 는 레지스트리에 없으므로 manifest 에 함께 넣는다. 특정 태그 고정은 `#<태그>` 이며 레포에 있는 태그만 쓴다.

## 어떤 임포터를 쓰나

| 시트 모양 | 기반 타입 | 구현할 것 |
|-----------|-----------|-----------|
| 1행 = 항목 1개 | `GoogleSheetConfigsImporter<TConfig, TSO>` (`TSO : IConfigsContainer<TConfig>`) | `GoogleSheetUrl`. 필요하면 `Deserialize(Dictionary<string,string>)` 재정의 |
| Key/Value 행으로 설정 1개 | `GoogleSheetSingleConfigImporter<TConfig, TSO>` (`TSO : ISingleConfigContainer<TConfig>`) | `GoogleSheetUrl`, `Deserialize(List<Dictionary<string,string>>)` |
| Key/Value + 하위 리스트 | `GoogleSheetSingleConfigSubListImporter<TConfig, TSO>` | `GoogleSheetUrl`, `GetDeserializers()` |
| 직접 저장 로직 | `GoogleSheetScriptableObjectImportContainer<TSO>` | `GoogleSheetUrl`, `OnImport(TSO, data)` |
| ScriptableObject 없음(코드 생성 등) | `IGoogleSheetConfigsImporter` | `GoogleSheetUrl`, `Import(data)` |

- `TConfig : struct`, `TSO : ScriptableObject`.
- 선택: `ICsvSyncTarget.CsvSyncPath`, `[GoogleSheetImportOrder(n)]`, `OnImportComplete(TSO)` 재정의.

## 기본 패턴

```csharp
// 런타임 어셈블리 (EnemyConfigs 는 EnemyConfigs.cs 파일에)
using System;
using System.Collections.Generic;
using Geuneda.DataExtensions;
using UnityEngine;

[Serializable]
public struct EnemyConfig
{
    public string Name;
    public int Health;
    public float Speed;
}

public class EnemyConfigs : ScriptableObject, IConfigsContainer<EnemyConfig>
{
    [SerializeField] private List<EnemyConfig> _configs = new();

    public List<EnemyConfig> Configs
    {
        get => _configs;
        set => _configs = value;
    }
}
```

```csharp
// 에디터 어셈블리
using GeunedaEditor.GoogleSheetImporter;

public class EnemyConfigsImporter : GoogleSheetConfigsImporter<EnemyConfig, EnemyConfigs>, ICsvSyncTarget
{
    public override string GoogleSheetUrl =>
        "https://docs.google.com/spreadsheets/d/<SPREADSHEET_ID>/edit#gid=<GID>";

    // 선택: 다운로드한 원본 CSV 를 LF 로 정규화해 기록. 빈 값이면 건너뜀
    public string CsvSyncPath => "Assets/Data/Enemy.csv";
}
```

시트 헤더는 `Name,Health,Speed` 처럼 public 필드 이름과 정확히 같아야 한다(대소문자 구분).

코드 생성 임포터는 다른 임포터보다 먼저 돌도록 순서를 준다.

```csharp
using System.Collections.Generic;
using GeunedaEditor.GoogleSheetImporter;
using UnityEditor;

[GoogleSheetImportOrder(0)]
public class GameIdsImporter : IGoogleSheetConfigsImporter
{
    public string GoogleSheetUrl =>
        "https://docs.google.com/spreadsheets/d/<SPREADSHEET_ID>/edit#gid=<GID>";

    public void Import(List<Dictionary<string, string>> data)
    {
        // data 로 스크립트 텍스트를 만들어 File.WriteAllText 로 저장
        AssetDatabase.Refresh();
    }
}
```

## 실행 방법

- `Tools > GoogleSheet Importer > Import Google Sheet Data`: 전체 임포트
- `Tools > GoogleSheet Importer > Select GoogleSheetImporter.asset`: 설정 에셋 선택(없으면 `Assets/GoogleSheetImporter.asset` 생성). 생성 메뉴는 `Create > ScriptableObjects > Editor > GoogleSheetImporter`
- 설정 에셋 인스펙터: **Import All Sheets**, 임포터별 **Import** / **Select Object**, `ReplaceSpreadsheetId` 입력란

## CSV 와 파싱 규칙

- 행 구분자는 `\r\n` 만 인식한다. `\n` 텍스트는 빈 결과.
- 첫 행이 헤더. `$` 로 시작하는 헤더 열은 무시. `#` 으로 시작하는 줄은 건너뜀.
- 배열/리스트: `, ( ) [ ] { }` 로 분리. 딕셔너리: `k:v,k:v`(쌍 구분자 `: < > = |`) 또는 `k,v,k,v`, 빈 셀은 `null`.
- `Parse` 순서: string -> enum -> Key/Value(또는 Value1/Value2) 필드 2개짜리 제네릭 구조체 -> 커스텀 역직렬화기 -> `DateTime` -> `TimeSpan` -> `Nullable<T>` -> 값 타입(`Convert.ChangeType`) -> 참조 타입(`JsonConvert.DeserializeObject("\"text\"", type)`).
- 커스텀 역직렬화기 `Func<string, Type, object>` 는 처리하지 않을 타입에 `null` 을 반환한다.

## 함정

- URL 은 `.../d/<ID>/edit#gid=<GID>` 형식이어야 한다. 코드는 `edit#` 를 `export?format=csv&` 로 문자열 치환하므로 `edit?gid=...#gid=...` 형태면 CSV 가 아닌 응답을 받는다. `/d/` 나 `/edit` 가 없으면 즉시 실패.
- 시트는 링크 공개여야 한다. 401/403 도 재시도 대상이라 비공개 시트는 최대 6회 재시도 후 실패한다.
- 리스트 필드는 `List<T>` 로 선언한다. `DeserializeObject` 가 `T[]` 에도 `List<T>` 를 반환해서 `T[]` 필드는 `field.SetValue` 에서 예외가 난다.
- 값 타입 필드에 빈 셀이 오면 예외가 난다. 선택 값은 `int?` 같은 `Nullable<T>` 로 둔다.
- `System.Collections.Generic.KeyValuePair<,>` 는 public 필드가 없어 Key/Value 규칙에 걸리지 않는다. `StructPair<,>`(gamedata) 같은 public 필드 구조체를 쓰거나 역직렬화기를 넘긴다.
- 서브 리스트(`GoogleSheetSingleConfigSubListImporter`)의 데이터 행은 `Key == "#"` 인데, `ConvertCsv` 가 `#` 으로 시작하는 줄을 버린다. `Key` 열을 첫 열로 두면 서브 리스트가 비므로 앞에 `$` 주석 열을 둔다. 대상 필드는 `List<T>` 여야 한다.
- 저장 대상은 `FindAssets("t:<타입 이름>")` 의 첫 결과다. 같은 타입 에셋을 여러 개 두지 않는다. 없으면 `Assets/<타입 이름>.asset` 이 생긴다.
- `ReplaceSpreadsheetId` 는 인스펙터 버튼에만 적용되고 메뉴 실행에는 적용되지 않는다.
- 임포터는 모든 어셈블리에서 리플렉션으로 수집되며 `Activator.CreateInstance` 로 만든다. 추상이 아니고 public 매개변수 없는 생성자가 필요하다.
- `ICsvSyncTarget` 기록은 `File.WriteAllText` 라 폴더를 만들지 않는다. 실패해도 경고만 남는다.
- 패키지의 `Importers Example` 샘플은 그대로 컴파일되지 않는다(`Configs` 타입 없음, `GameIdsImporter` 가 제거된 `IGoogleSheetImporter` 사용). 예제는 위 패턴을 기준으로 한다.
