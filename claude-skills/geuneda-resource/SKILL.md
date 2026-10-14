---
name: geuneda-resource
description: com.geuneda.resource 패키지(네임스페이스 Geuneda.Resource)로 원격 리소스(테이블 등 데이터 파일)를 내려받고 캐시하는 코드를 작성하거나 수정할 때 사용하는 스킬. IResourceCache·ResourceCache·ResourceCacheOptions 로 캐시를 만들거나, ResourceEntry(카테고리, 버전, 크기, SHA-256, URL)로 리소스 매니페스트를 옮기거나, CheckAsync(받을 항목과 총 용량)·DownloadAsync(진행률 ResourceDownloadProgress, 동시 다운로드 제한)·LoadBytesAsync·GetFilePathAsync 로 테이블 다운로드와 원격 데이터 캐시를 다루거나, ResourceCheck·ResourceResultCodes(5000 블록: NotCached, IntegrityFailed, StorageFailed)를 처리하거나, com.geuneda.appsetting 의 resources 노드(AppSetting.Resources)를 리소스 캐시에 연결할 때 활성화한다.
---

# Geuneda Resource

원격 리소스(테이블 같은 데이터 파일) 캐시다. 매니페스트 항목(카테고리, 버전, 크기, SHA-256, URL)을 받아 캐시 파일이 맞는지 크기와 해시로 보고, 맞지 않는 것만 받아 검증한 뒤 원자적으로 저장한다. 결과는 core 결과 규약(`Result`)을 따른다.

## 패키지 정보

- **버전**: 0.1.0
- **네임스페이스 / 어셈블리**: `Geuneda.Resource`
- **설치**: `https://github.com/geuneda/geuneda-resource.git` (core, http, UniTask git URL 도 함께)
- **의존성**: `com.geuneda.core` 0.2.0(Result, ModuleLogger), `com.geuneda.http` 0.1.0, `com.cysharp.unitask` 2.5.10. appsetting 에 의존하지 않는다(매니페스트는 게임이 옮겨 줌)
- **최소 Unity 버전**: 2021.3
- **기여 가이드**: 패키지 루트의 `AGENTS.md`
- **출처**: Lucky Defense Perbase Resource(로드맵 3-6). 크기+해시 판정(버전 비교 없음), 파일 이름에 버전, 받기 전 용량 확인, 진행률은 따랐고, 검증 후 원자적 저장·옛 버전은 저장 뒤 삭제·동시 다운로드 제한·재시도(RetryMiddleware)·스레드 풀 입출력으로 보완했다

## 핵심 API

전체 시그니처는 `references/api.md`.

- `new ResourceCache(new ResourceCacheOptions { HttpClient, RootPath?, MaxConcurrentDownloads = 2, RequestTimeout = 60초 })` → `IResourceCache`. `MainInstaller.Bind<IResourceCache>`.
- `CheckAsync(entries, ct)` → `Result<ResourceCheck>`(`Missing`, `TotalBytes`, `IsUpToDate`).
- `DownloadAsync(entries, progress?, ct)` → `Result`. 맞지 않는 항목만 받는다. 진행률 `ResourceDownloadProgress`(`CompletedFiles`, `TotalFiles`, `CompletedBytes`, `TotalBytes`).
- `LoadBytesAsync(entry, ct)` → `Result<byte[]>`(읽은 바이트를 크기·해시로 확인), `GetFilePathAsync(entry, ct)` → `Result<string>`.
- `ResourceEntry(category, version, size, sha256, url)`: 이름 `[a-z0-9._-]` 1~64자(소문자만, 끝의 점·Windows 장치 이름(`con`, `nul`, `com1` 등, 뒤에 점이 붙어도)·`.`·`..` 제외), 크기 0 이상, SHA-256 16진수 64자(소문자로 맞춤), http·https 절대 주소. 아니면 `ArgumentException`.
- `ResourceResultCodes`: `NotCached` 5001, `IntegrityFailed` 5002, `StorageFailed` 5003.

## 사용 패턴

```csharp
var resources = new ResourceCache(new ResourceCacheOptions
{
    // 일시 실패(연결, 제한 시간, 5xx) 재시도는 RetryMiddleware 에 맡긴다(GET 이라 재시도해도 됨)
    HttpClient = new HttpClientBuilder().AddMiddleware(new RetryMiddleware()).Build()
});
MainInstaller.Bind<IResourceCache>(resources);

// 매니페스트: appsetting 의 서명된 resources 노드가 크기·해시를 보장한다. 두 패키지는 서로 의존하지 않아 게임이 옮긴다
var entries = setting.Resources
    .Select(pair => new ResourceEntry(pair.Key, pair.Value.Version, pair.Value.Size, pair.Value.Sha256, pair.Value.Url))
    .ToList();

var check = await resources.CheckAsync(entries, ct);
if (!check.IsSuccess) { ShowRetry(check.Code); return; }

if (!check.Value.IsUpToDate)
{
    if (!await ConfirmDownload(check.Value.TotalBytes)) return;   // 셀룰러 용량 확인

    var downloaded = await resources.DownloadAsync(check.Value.Missing,
        progress => ShowProgress(progress.CompletedBytes, progress.TotalBytes), ct);
    if (!downloaded.IsSuccess) { ShowRetry(downloaded.Code); return; }
}

var tables = entries.First(entry => entry.Category == "tables");
var loaded = await resources.LoadBytesAsync(tables, ct);
if (!loaded.TryGetValue(out var data)) { ShowRetry(loaded.Code); return; }
// gamedata 설정 형식이면 허용할 설정 타입을 먼저 등록한다(TrustedOnly 바인더)
var serializer = new ConfigsSerializer();
serializer.RegisterAllowedTypes(new[] { typeof(UnitConfig), typeof(StageConfig) });
var configs = serializer.Deserialize<ConfigsProvider>(Encoding.UTF8.GetString(data));
```

결과:

| 상황 | 결과 코드 |
|------|-----------|
| 성공 | 0 |
| 연결 실패, 제한 시간, 취소 | `ResultCodes.NetworkError`, `Timeout`, `Cancelled` |
| 다른 `DownloadAsync` 진행 중 | `ResultCodes.InProgress` |
| 2xx 가 아닌 응답 | `HttpResultCodes.HttpError` |
| 캐시에 맞는 파일 없음(읽기·경로) | `NotCached` 5001 |
| 받은 파일의 크기·해시가 다름 | `IntegrityFailed` 5002 |
| 캐시 폴더에 쓰지 못함 | `StorageFailed` 5003 |
| null 항목, 같은 카테고리의 다른 버전, 잘못된 이름·해시·주소, 필수 설정 없음 | 예외 |

## 규칙

- **판정은 크기와 SHA-256**: 버전을 비교하지 않고 캐시 파일(`<루트>/<카테고리>/<버전>.<SHA-256 앞 16자>.bin`)이 항목의 크기·해시와 같은지 본다. 이 실행에서 해시까지 확인한 파일은 다시 확인할 때 해시를 건너뛴다(파일 존재는 봄). `LoadBytesAsync` 는 읽은 바이트를 매번 확인한다. 맞지 않는 파일은 조회가 지우지 않고 다음 저장이 교체한다.
- **검증 후 원자적 저장**: 받은 바이트의 크기·해시를 먼저 확인하고, 같은 폴더 임시 파일에 써서 디스크로 내보낸 뒤 이름을 바꾼다. 맞지 않으면 아무것도 쓰지 않는다(`IntegrityFailed`, 옛 버전 유지).
- **옛 파일은 저장 뒤 삭제**: 새 파일 저장 뒤 같은 카테고리의 다른 파일(다른 버전·내용, 맞지 않는 파일)과 남은 임시 파일을 지운다. 파일 이름에 해시가 들어가 같은 버전의 내용 교체도 새 파일이 놓인 뒤에야 이전 파일이 지워진다. 지우지 못한 파일(Windows 에서 열린 파일)은 다음 저장 때 다시 지운다.
- **조회는 파일을 바꾸지 않는다**: 맞지 않는 파일도 조회는 지우지 않는다(판정과 삭제 사이에 저장된 새 파일을 지우지 않게). 지우는 것은 저장뿐이다.
- **저장 때 같은 이름 파일을 다시 확인한다**: 판정 때 읽지 못해(잠김 등) 받게 된 파일이 실제로 정상이면 덮어쓰지 않고 그대로 쓴다. 다시 확인하다 입출력 오류가 나면 그 파일을 두고 `StorageFailed` 다.
- **동시 다운로드 제한**: `MaxConcurrentDownloads`(기본 2)개씩 받는다. 하나가 실패해도 나머지는 계속 받고, 끝난 뒤 첫 실패 코드와 실패 목록을 돌려준다(성공한 파일은 저장된 채). 취소하면 시작하지 않은 항목은 받지 않는다.
- **한 번에 하나**: `DownloadAsync` 가 진행 중이면 기다리지 않고 `InProgress` 다. 한 호출에 같은 카테고리의 다른 버전을 넣으면 예외, 같은 항목 중복은 하나로 합친다.
- **이름 규칙**: 카테고리·버전은 파일 경로가 되므로 `[a-z0-9._-]` 1~64자(소문자만, `.`·`..` 제외)로 제한해 경로를 벗어나지 못하고 대소문자를 가리지 않는 파일 시스템에서도 겹치지 않는다. 끝의 점과 Windows 장치 이름(`con` 등)도 막아 Windows 에서도 같은 파일 이름이 된다. appsetting 의 `AppSettingResource` 와 같은 규칙이라 함께 바꾼다.
- **스레드**: 메인 스레드에서 부른다. 파일 입출력과 해시는 스레드 풀에서 하고 결과·진행률 콜백(예외는 로그만)은 메인 스레드로 돌아온다.

## 함정

- 응답 본문을 메모리에 받으므로 데이터 파일용이다. 큰 에셋은 Addressables 원격 카탈로그를 쓴다.
- 항목의 크기·해시로 받은 파일을 검증하므로 항목은 믿을 수 있는 곳(서명된 appsetting 문서 등)에서 가져온다. 검증하지 않은 서버 응답으로 항목을 만들면 무결성 보장이 없다.
- 저장 파일은 암호화하지 않는다(설계). 앱에 넣은 키는 꺼낼 수 있어 암호화는 난독화 수준이고, 테이블은 어차피 메모리에서 읽는다. 파일 단위 서명도 두지 않는다(매니페스트 서명이 해시를 보장).
- 파싱 결과 2차 캐시(레퍼런스 ptb)는 두지 않는다(설계). 테이블은 gamedata `ConfigsSerializer` JSON 처럼 구조화된 형식으로 올리고, 파싱이 느리다고 측정되면 그때 추가한다.
- `GetFilePathAsync` 의 경로는 다음 다운로드가 새 버전을 저장하면 지워질 수 있다. 오래 열어 둘 파일이면 다운로드와 겹치지 않게 한다.
- 버전을 파일 이름에 넣어 CDN 에 올리면 캐시 무효화가 필요 없다. 같은 URL 에 내용을 바꿔 올리면 오래된 CDN 사본이 해시 불일치(`IntegrityFailed`)로 거절된다.
- 매니페스트에서 빠진 카테고리 폴더는 지우지 않는다.
