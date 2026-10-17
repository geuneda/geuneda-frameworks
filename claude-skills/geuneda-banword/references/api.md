# Geuneda BanWord API 레퍼런스

네임스페이스 `Geuneda.BanWord`. banword 0.1.0. Unity asmdef `Geuneda.BanWord`(`noEngineReferences`), 서버 프로젝트 `Server~/src/Geuneda.BanWord`(net10.0, 같은 소스).

## 검사

### interface IBanWordFilter / sealed class BanWordFilter : IBanWordFilter

| 멤버 | 설명 |
|------|------|
| `BanWordFilter(IEnumerable<string> denied, IEnumerable<string> allowed)` | 목록이나 단어가 null 이면 `ArgumentNullException`. 단어는 앞뒤 공백 제거, 공백만 있으면 뺌. 대소문자만 다른 단어는 하나로(처음 등록한 금칙어 철자로 알림). 금칙·허용에 모두 있는 단어는 걸리지 않음 |
| `bool Contains(string text)` | 허용어가 덮지 않는 금칙어가 있으면 true. 최종 `BanWordMatch` 목록은 만들지 않지만 내부 금칙·허용 일치 목록은 모음 |
| `IReadOnlyList<BanWordMatch> Find(string text)` | 덮이지 않은 금칙어 모두(겹친 것 포함). 시작 위치 순, 같으면 긴 것 먼저. 없으면 빈 배열 |
| `string Mask(string text, char mask = '*')` | 찾은 범위를 합쳐 `mask` 로 바꿈. 없으면 같은 객체를 돌려줌 |

- `text` 가 null 이면 세 메서드 모두 `ArgumentNullException`. 빈 글은 걸리지 않음.
- 만든 뒤 불변. 여러 스레드에서 함께 써도 됨. 검사마다 지역 목록을 할당.

### readonly struct BanWordMatch

| 멤버 | 뜻 |
|------|----|
| `BanWordMatch(int index, int length, string word)` | |
| `int Index` | 원문 시작 위치(UTF-16) |
| `int Length` | 원문 길이(등록한 금칙어 길이와 같음) |
| `string Word` | 등록한 금칙어(앞뒤 공백 제외) |
| `ToString()` | `"{Word}@{Index}+{Length}"` |

## 단어장 파일

### sealed class BanWordList

| 멤버 | 설명 |
|------|------|
| `static bool TryParse(string text, out BanWordList list, out string error)` | 성공하면 `list`, `error` null. 실패하면 `list` null, `error` 에 줄 번호가 든 이유. `text` 가 null 이면 `ArgumentNullException` |
| `IReadOnlyList<string> Denied` | 파일 순서, 앞뒤 공백 제외 |
| `IReadOnlyList<string> Allowed` | 파일 순서, 앞뒤 공백 제외 |

형식: 줄 단위 UTF-8. `[denied]`/`[allowed]` 구역 줄 아래 한 줄에 단어 하나. 빈 줄·맨 앞 BOM 무시, `\n`·`\r\n`, 구역 반복 가능, 주석 없음. 실패: 구역 줄 없음, 첫 구역 앞 단어, `[영문 소문자]` 모양의 모르는 구역.

## 원격 단어장 로더 (어셈블리 `Geuneda.BanWord.Resource`, com.geuneda.resource 0.1.0 이상이 있을 때만)

### sealed class BanWordResourceLoader

| 멤버 | 설명 |
|------|------|
| `const string DefaultPrefsKey = "geuneda.banword.last"` | 마지막 항목을 두는 PlayerPrefs 키 |
| `BanWordResourceLoader(IResourceCache cache, string bundledText, string prefsKey = DefaultPrefsKey)` | `cache`·`bundledText` null 이면 `ArgumentNullException`, 빈 키는 `ArgumentException` |
| `UniTask<Result<BanWordLoad>> LoadAsync(ResourceEntry current, CancellationToken ct = default)` | `current`(null 가능) → 마지막 항목 → 내장 순서. 해석에 성공한 `current` 만 기억. 실패는 `ResultCodes.Cancelled` 뿐(다음 출처로 넘어가지 않음. 읽는 동안 토큰이 취소되면 캐시 결과와 상관없이 취소). 기록 저장 실패(`PlayerPrefsException`, WebGL 한도)는 Warning 뒤 읽은 단어장을 돌려줌. 그 밖의 읽기 실패(캐시 없음, 해시, UTF-8 아님, 형식)는 Warning 뒤 다음 출처. 내장 형식 오류는 `InvalidOperationException`. 받기는 하지 않음. 메인 스레드 |

### readonly struct BanWordLoad / enum BanWordSource

| 멤버 | 뜻 |
|------|----|
| `BanWordList List` | 읽은 단어장 |
| `BanWordSource Source` | `Current`, `LastGood`, `Bundled`(`None` 은 기본값, 돌려주지 않음) |
| `ResourceEntry Entry` | 읽은 항목. 내장이면 null |

## 판정 규칙

| 항목 | 규칙 |
|------|------|
| 찾기 | 부분 문자열(단어 경계 없음). Aho-Corasick 오토마톤 하나에 금칙·허용 표시 |
| 대소문자 | 유니코드 17.0 `CaseFolding.txt` 상태 C·S, BMP 원본·결과만(1205개). 한 글자 → 한 글자. 표는 패키지 안(`CaseFolding.Table.cs`, 생성 파일) |
| 그 밖의 정규화 | 없음(전각·반각, 공백·기호, 자모, 비슷한 글자) |
| 허용어 | 허용어 하나의 시작 ≤ 금칙어 시작 이고 끝 ≥ 금칙어 끝 이면 그 금칙어를 뺌 |
| 위치 | UTF-16 단위. 서로게이트 쌍은 두 글자 |

## 성능 (0.1.0, Apple Silicon Mac, 한글 2~6자 무작위 단어)

| | 1만 단어 만들기 | 5만 단어 만들기 | 200자 `Find` |
|---|---|---|---|
| .NET 10 | 13ms | 29ms | 약 10µs |
| Unity 에디터 Mono | 13ms | 66ms | 약 8µs |
| Android IL2CPP(arm64 에뮬레이터, 제거 High) | 11ms | 38ms | 약 3µs |

5만 단어 필터 메모리는 .NET 에서 약 2.7MB.

## 서버

```xml
<ProjectReference Include="<패키지 경로>/Server~/src/Geuneda.BanWord/Geuneda.BanWord.csproj" />
```

- 솔루션 `Server~/Geuneda.BanWord.Server.slnx`: `src/Geuneda.BanWord`(Runtime/*.cs 링크), `tests/Geuneda.BanWord.Tests`(Tests/EditMode/*.cs 링크, NUnit 3.14).
- `Server~/Directory.Build.props` 가 `LangVersion 9.0` 으로 공유 소스를 Unity 와 같은 C# 으로 묶음.

## 테스트

- Unity EditMode `Geuneda.BanWord.Tests.EditMode`, .NET `dotnet test Server~/Geuneda.BanWord.Server.slnx`(같은 파일). resource 가 있으면 EditMode `Geuneda.BanWord.Resource.Tests.EditMode`(로더, 실제 ResourceCache 재시작 시나리오).
- `MatchesBruteForce_OnRandomLists`(기준 구현 대조), `CaseFoldingTest`(BMP 전체 멱등, 표 정렬), 파일 형식 테스트.

## 대소문자 표 다시 만들기

```bash
curl -fsSL https://www.unicode.org/Public/<버전>/ucd/CaseFolding.txt -o CaseFolding.txt
python3 -I Tools~/generate_case_folding.py CaseFolding.txt   # Runtime/CaseFolding.Table.cs 를 덮어씀
```
