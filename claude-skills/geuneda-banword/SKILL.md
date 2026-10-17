---
name: geuneda-banword
description: com.geuneda.banword 패키지(네임스페이스 Geuneda.BanWord)로 금칙어 검사 코드를 작성하거나 수정할 때 사용하는 스킬. IBanWordFilter·BanWordFilter 로 닉네임·길드 이름·채팅에 금칙어가 있는지 보거나(Contains), 위치를 찾거나(Find, BanWordMatch), 가리거나(Mask), 허용어로 오탐(예: 핵 → 핵심)을 빼거나, BanWordList.TryParse 로 [denied]/[allowed] 단어장 파일을 읽거나, BanWordResourceLoader(선택 어셈블리 Geuneda.BanWord.Resource)·BanWordLoad·BanWordSource 로 com.geuneda.resource 캐시와 appsetting resources 노드의 원격 단어장을 지금 항목 → 마지막으로 읽은 항목 → 내장 스냅샷 순서로 읽거나, 게임 설정의 추가 금칙어를 합치거나, 큰 단어장을 스레드 풀에서 만들거나, .NET 게임 서버에서 Server~ 의 Geuneda.BanWord 라이브러리로 같은 판정을 하거나, 대소문자 접기 표(CaseFolding, Tools~/generate_case_folding.py)를 다시 만들 때 활성화한다.
---

# Geuneda BanWord

금칙어 검사. 금칙어·허용어로 Aho-Corasick 오토마톤 하나를 만들고, 허용어가 완전히 덮지 않는 금칙어를 찾는다. 대소문자만 무시한다. 의존성이 없고 UnityEngine 을 쓰지 않아 .NET 서버가 같은 소스로 같은 판정을 한다.

## 패키지 정보

- **버전**: 0.1.1
- **네임스페이스 / 어셈블리**: `Geuneda.BanWord`(Unity, 서버 모두)
- **설치**: `https://github.com/geuneda/geuneda-banword.git`. 검사만 쓰면 다른 패키지가 필요 없다(Unity 2021.3+). 로더 어셈블리 `Geuneda.BanWord.Resource` 는 `com.geuneda.resource` 가 있을 때만 컴파일된다(resource 와 core, http, UniTask 를 함께 넣음)
- **서버**: `Server~/src/Geuneda.BanWord/Geuneda.BanWord.csproj`(net10.0, Runtime 소스 링크)를 ProjectReference 로 참조
- **기여 가이드**: 패키지 루트의 `AGENTS.md`
- **출처**: Lucky Defense Percent `BanWord`(Aho-Corasick 금칙·허용 트라이, 허용어가 완전히 덮으면 뺌)를 따르고, 자체 다운로더(24시간 TTL, 해시 조건부 GET, 실패하면 부팅 실패) 대신 resource 캐시 + 내장 스냅샷, 런타임 대소문자 비교 대신 고정 표, 트라이 2개 대신 오토마톤 1개로 바꿨다(로드맵 5-1)

## 핵심 API

전체 시그니처는 `references/api.md`.

- `new BanWordFilter(IEnumerable<string> denied, IEnumerable<string> allowed)` → `IBanWordFilter`. 앞뒤 공백 제거, 빈 단어 무시, null 목록·단어는 `ArgumentNullException`. 만든 뒤 불변(여러 스레드에서 함께 씀).
- `Contains(text)` → bool. `Find(text)` → `IReadOnlyList<BanWordMatch>`(겹친 것 모두, 시작 위치 순·긴 것 먼저). `Mask(text, mask = '*')` → string(합친 범위를 가림, 없으면 원문 객체 그대로). null 글은 `ArgumentNullException`.
- `BanWordMatch`: `Index`, `Length`(UTF-16 단위), `Word`(등록한 철자).
- `BanWordList.TryParse(string text, out BanWordList list, out string error)` → bool. `Denied`, `Allowed`(파일 순서). 실패 이유에 줄 번호.
- `new BanWordResourceLoader(IResourceCache cache, string bundledText, string prefsKey = "geuneda.banword.last")`, `LoadAsync(ResourceEntry current, ct)` → `Result<BanWordLoad>`(`List`, `Source`, `Entry`). 실패는 `Cancelled` 뿐. 받기는 하지 않음. 메인 스레드.

## 사용 패턴

```csharp
using System.Linq;
using Cysharp.Threading.Tasks;
using Geuneda.BanWord;
using Geuneda.Services;

// 받기(CheckAsync·DownloadAsync)는 게임이 다른 리소스와 함께 먼저 한다. 실패했어도 로더를 부른다
var loader = new BanWordResourceLoader(resources, bundledText);   // bundledText: 앱에 넣은 단어장
var loaded = await loader.LoadAsync(entries.FirstOrDefault(e => e.Category == "banwords"), token);
if (!loaded.TryGetValue(out var load)) return;                     // 실패는 취소뿐: 바인딩하지 않음

var (canceled, filter) = await UniTask.RunOnThreadPool(() => new BanWordFilter(
    load.List.Denied.Concat(config.ExtraDenied), load.List.Allowed.Concat(config.ExtraAllowed)),
    cancellationToken: token).SuppressCancellationThrow();
if (canceled) return;
MainInstaller.Bind<IBanWordFilter>(filter);                         // load.Source: Current / LastGood / Bundled

if (filter.Contains(nickname)) { ShowNicknameError(); return; }   // 서버도 같은 검사로 최종 판정
var shown = filter.Mask(chatText);                                  // "아 시발 진짜" -> "아 ** 진짜"
```

resource 를 쓰지 않으면 `BanWordList.TryParse(text, out var list, out var error)` 로 읽어 `new BanWordFilter(list.Denied, list.Allowed)`.

서버(ASP.NET Core):

```csharp
if (!BanWordList.TryParse(await File.ReadAllTextAsync(path), out var list, out var error))
    throw new InvalidOperationException(error);
builder.Services.AddSingleton<IBanWordFilter>(new BanWordFilter(list.Denied, list.Allowed));
```

## 단어장 파일

UTF-8, 줄 단위. `[denied]` 아래 금칙어, `[allowed]` 아래 허용어, 한 줄에 단어 하나. 앞뒤 공백 제거, 빈 줄 무시, BOM 무시, 같은 구역 반복 가능, 주석 없음. `[영문 소문자]` 모양은 구역 줄이라 모르는 구역(`[deny]`)·첫 구역 앞 단어·구역 없는 파일은 실패. `[광고]`, `[AD]` 같은 다른 대괄호 줄은 단어.

## 규칙

- **부분 문자열 판정**: 단어 경계를 보지 않는다. 짧은 금칙어의 오탐(`핵` → `핵심`)은 허용어로 뺀다.
- **허용어는 하나가 금칙어를 완전히 덮어야** 뺀다(시작 ≤, 끝 ≥). 겹치기만 하거나 둘이 이어 덮으면 안 뺀다. 두 목록에 다 있는 단어는 걸리지 않는다.
- **대소문자만 무시**: 패키지에 넣은 유니코드 17.0 단순 대소문자 접기 표(C·S, BMP)로 한 글자씩 바꾼다. `ς`=`σ`, 켈빈 기호=`k`, `ẞ`=`ß`, `ß`≠`ss`, `ı`·`İ`≠`i`. 전각·공백·기호 끼우기·자모는 정규화하지 않는다(사용자 결정, `시 발`·`ＣＨＥＡＴ` 은 못 잡음). 기호가 든 금칙어는 기호까지 비교(`.com` 은 `become` 에 안 걸림).
- **로더 순서**: 지금 항목 → 마지막 항목(PlayerPrefs 에 기억한 항목을 캐시에서 다시 검증) → 내장. 해석까지 성공한 지금 항목만 기억한다. 취소면(읽는 동안 취소된 것 포함) 다음 출처로 넘어가지 않고 `Cancelled`. 기록 저장 실패(WebGL PlayerPrefs 한도)는 경고 뒤 읽은 단어장을 쓴다. 내장 단어장 형식 오류만 `InvalidOperationException`.
- **필터는 불변**: 목록을 바꾸려면 새로 만들어 바인딩을 바꾼다. "준비 전에는 모두 거부" 같은 상태는 없으니 필요하면 게임이 필터를 만들 때까지 입력을 막는다.
- **저장되는 값은 서버가 판정한다.** 클라이언트 검사는 입력 안내. 서버는 클라이언트와 같은 단어장 파일(같은 버전)을 읽는다.
- 검사마다 작은 목록을 할당하므로 매 프레임 부르지 않는다.

## 함정

- `char.ToUpperInvariant`·`StringComparer.OrdinalIgnoreCase`·`Normalize` 로 단어를 미리 바꾸지 않는다. Mono(IL2CPP 포함)와 .NET 10 의 표가 달라(ToUpperInvariant 가 바꾸는 BMP 글자: Unity 6000.3.11f1 Mono·IL2CPP 973자, .NET 10.0.5 1197자(시스템 ICU)·1193자(invariant 모드)) 클라이언트와 서버 판정이 갈리고, .NET 끼리도 ICU 버전·모드에 따라 달라진다. 패키지가 고정 표로 접는다.
- 큰 단어장(5만 단어)은 만드는 데 에디터 Mono 66ms, Android IL2CPP 에뮬레이터 38ms 가 걸린다. 부팅 중이면 `UniTask.RunOnThreadPool` 로 만든다(WebGL 은 스레드 풀 없음).
- 내장 스냅샷의 형식 오류는 빌드 전에 고칠 버그다(로더가 예외). 테스트로 `TryParse` 를 확인한다.
- resource 는 새 파일을 저장하면 같은 카테고리의 옛 파일을 지운다. 받기에 성공한 형식 오류 단어장을 올리면 마지막 항목도 못 읽고 내장으로 내려가므로, 올리기 전에 서버·CI 에서 `TryParse` 로 확인한다.
- 부트스트랩을 취소하면 `LoadAsync` 는 `Cancelled`, `RunOnThreadPool` 은 `SuppressCancellationThrow` 로 받아 바인딩하지 않는다.
- 대소문자 표는 Unicode 데이터 파생물이라 Unicode License v3(`THIRD-PARTY-NOTICES.md`)를 따른다.
- `Mask` 는 UTF-16 단위로 가려 이모지 같은 서로게이트 쌍은 `**` 가 된다. BMP 밖 글자는 대소문자를 구분한다.
- 대소문자 표를 새 유니코드로 다시 만들면 판정이 바뀐다. 클라이언트와 서버를 같은 패키지 버전으로 맞춘다(`python3 -I Tools~/generate_case_folding.py CaseFolding.txt`).
