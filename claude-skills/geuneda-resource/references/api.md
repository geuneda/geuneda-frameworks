# Geuneda Resource API 레퍼런스

네임스페이스 `Geuneda.Resource`. 결과는 core `Result`/`Result<T>`. 버전 0.1.0.

## 캐시 (`Runtime/`)

### interface IResourceCache / sealed class ResourceCache : IResourceCache

| 멤버 | 설명 |
|------|------|
| `ResourceCache(ResourceCacheOptions)` | 메인 스레드(`Application.persistentDataPath` 를 읽음). 옵션 null 은 `ArgumentNullException`, `HttpClient` 없음·`MaxConcurrentDownloads` 1 미만·`RequestTimeout` 0 이하·빈 `RootPath` 는 `ArgumentException` |
| `string RootPath` | 캐시 폴더(절대 경로) |
| `UniTask<Result<ResourceCheck>> CheckAsync(IEnumerable<ResourceEntry> entries, CancellationToken ct = default)` | 캐시에 맞는 파일이 없는 항목과 총 크기. 파일을 읽어 해시를 계산(이 실행에서 확인한 같은 파일은 존재만 봄). 파일은 지우지 않음. 취소면 `Cancelled`(빈 목록·마지막 항목 확인 중 포함) |
| `UniTask<Result> DownloadAsync(IEnumerable<ResourceEntry> entries, Action<ResourceDownloadProgress> progress = null, CancellationToken ct = default)` | 맞지 않는 항목만 받아 저장. 동시 `MaxConcurrentDownloads` 개. 하나가 실패해도 나머지 계속, 끝나면 첫 실패 코드와 실패 목록(취소만 있었으면 `Cancelled`). 진행 중이면 `InProgress`. 진행률은 처음 0 으로 한 번, 파일을 저장할 때마다 메인 스레드에서(예외는 로그만) |
| `UniTask<Result<byte[]>> LoadBytesAsync(ResourceEntry entry, CancellationToken ct = default)` | 캐시 파일을 읽어 크기·해시 확인 후 바이트. 없거나 맞지 않으면 `NotCached`(파일은 그대로 두고 다음 저장이 교체), 입출력 오류는 `StorageFailed`, 이미 취소된 토큰은 파일 작업 없이 `Cancelled` |
| `UniTask<Result<string>> GetFilePathAsync(ResourceEntry entry, CancellationToken ct = default)` | 맞는지 확인한 뒤 경로. 아니면 `NotCached`. 다음 다운로드가 새 버전을 저장하면 지워질 수 있음 |

공개 메서드는 async 가 아니어서 인자 오류(null 목록·항목, 같은 카테고리의 다른 버전)는 호출 즉시 예외다. 같은 항목 중복은 하나로 합친다.

### sealed class ResourceCacheOptions

`IHttpClient HttpClient`(필수, `RetryMiddleware` 권장, 응답 본문을 메모리에 받음), `string RootPath`(null 이면 `Application.persistentDataPath/geuneda-resources`), `int MaxConcurrentDownloads`(기본 2), `TimeSpan RequestTimeout`(파일 요청 하나, 기본 60초).

## 항목과 결과

| 타입 | 멤버 |
|------|------|
| `ResourceEntry(string category, string version, long size, string sha256, string url)` | `Category`, `Version`(`[a-z0-9._-]` 1~64자, 소문자만, 끝의 점·Windows 장치 이름(`con` 등, 뒤에 점이 붙어도) 금지, `.`·`..` 제외), `Size`(0 이상, 음수는 `ArgumentOutOfRangeException`), `Sha256`(16진수 64자 → 소문자), `Url`(`Uri`, 호스트 있는 http·https 절대 주소). 위반은 `ArgumentException`. `ToString()` 은 `카테고리@버전` |
| `ResourceCheck` | `IReadOnlyList<ResourceEntry> Missing`(넘긴 순서), `long TotalBytes`, `bool IsUpToDate` |
| `ResourceDownloadProgress`(struct) | `CompletedFiles`, `TotalFiles`, `CompletedBytes`, `TotalBytes` |

## 코드 (`ResourceResultCodes`, 5000 블록)

| 코드 | 이름 | 뜻 |
|------|------|----|
| 5001 | `NotCached` | 캐시에 맞는 파일이 없음(없거나 크기·해시가 다름. 맞지 않는 파일은 다음 저장이 교체) |
| 5002 | `IntegrityFailed` | 받은 파일의 크기나 SHA-256 이 항목과 다름. 저장하지 않음 |
| 5003 | `StorageFailed` | 캐시 폴더에 쓰거나 읽지 못함(공간 부족, 권한) |

연결 실패·제한 시간·취소·진행 중은 core `ResultCodes.NetworkError`·`Timeout`·`Cancelled`·`InProgress`, 2xx 가 아닌 응답은 http `HttpResultCodes.HttpError`.

## 저장 형식

- 경로: `<RootPath>/<카테고리>/<버전>.<SHA-256 앞 16자>.bin`. 같은 버전이라도 내용이 다르면 다른 파일이다. 카테고리마다 한 파일만 남는다.
- 조회(`CheckAsync`·`LoadBytesAsync`·`GetFilePathAsync`)는 파일을 지우지 않는다. 지우는 것은 저장뿐이다.
- 저장 순서: 크기·해시 확인 → 같은 폴더 `.<버전>.<guid>.tmp` 에 쓰고 `Flush(true)` → 같은 이름(같은 버전·해시 앞부분) 파일이 있으면 다시 확인해 정상이면 그대로 쓰고(판정 때 읽지 못했을 수 있음, 확인이 입출력 오류면 그 파일을 두고 `StorageFailed`) 맞지 않으면 지움 → 이름 바꾸기 → 같은 카테고리의 다른 `*.bin`·`.*.tmp` 삭제(실패하면 경고 로그, 다음 저장 때 다시).
- 암호화 없음(무결성만), 파싱 결과 2차 캐시 없음.

## appsetting 과 연결

```csharp
var entries = setting.Resources   // com.geuneda.appsetting 0.2.0, AppSetting.Resources(카테고리 → AppSettingResource)
    .Select(pair => new ResourceEntry(pair.Key, pair.Value.Version, pair.Value.Size, pair.Value.Sha256, pair.Value.Url))
    .ToList();
```

리소스 항목 JSON 은 서명 CLI `geuneda-appsetting resource --category <c> --version <v> --url <u> --file <f>` 로 만든다.

## 테스트

EditMode `Geuneda.Resource.Tests.EditMode`: `FakeFileServer`(주소별 파일·상태·실패·게이트, 동시 요청 수)와 `InlineResourceWorker`(같은 스레드)로 캐시 동작, `ResourceEntryTest`(이름·크기·해시·주소 규칙), `UnityWebRequestDownloadTest`(로컬 `HttpListener` 와 실제 UnityWebRequest·스레드 풀).
