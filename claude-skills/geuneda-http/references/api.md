# Geuneda Http API 레퍼런스

네임스페이스와 어셈블리: `Geuneda.Http`. 사용 패턴과 함정은 [../SKILL.md](../SKILL.md) 참고.

---

## interface IHttpClient / sealed class HttpClient

| 멤버 | 설명 |
|------|------|
| `UniTask<Result<HttpResponse>> SendAsync(HttpRequest request, CancellationToken ct = default)` | 상대 주소를 `BaseAddress` 와 합친 뒤 미들웨어 체인으로 보냄. 응답이 오면(4xx, 5xx 포함) 성공 |
| `UniTask<Result<T>> SendJsonAsync<T>(HttpRequest request, CancellationToken ct = default)` | 2xx 가 아니면 `HttpError`(메시지에 상태 코드), 본문을 JSON 으로 못 읽으면 `InvalidResponse`, 전송 실패는 그 코드 그대로 |
| `GetAsync(string uri, ct)` / `GetJsonAsync<T>(string uri, ct)` | GET |
| `PostJsonAsync(string uri, object body, ct)` / `PostJsonAsync<T>(string uri, object body, ct)` | 본문을 JSON(`application/json`)으로 보냄 |
| `Uri BaseAddress { get; }` (HttpClient) | 상대 주소의 기준. 없으면 null |

예외: `request` null → `ArgumentNullException`, 기본 주소 없는 상대 주소 → `ArgumentException`. 미들웨어가 던진 `OperationCanceledException` 은 호출자 토큰이 취소됐으면 `Cancelled` 결과, 아니면 그대로 전파.

## sealed class HttpClientBuilder

`WithBaseAddress(string)`(절대 주소가 아니면 `ArgumentException`), `AddMiddleware(IHttpMiddleware, int order = 0)`, `WithTransport(IHttpTransport)`(기본 `UnityWebRequestTransport`), `WithJsonSettings(JsonSerializerSettings)`, `HttpClient Build()`. 미들웨어는 order 오름차순, 같으면 추가 순서로 바깥부터 감싼다.

## sealed class HttpRequest (바꾸지 않음)

| 멤버 | 설명 |
|------|------|
| `HttpRequest(HttpMethod, Uri)` / `HttpRequest(HttpMethod, string)` | 문자열이 비었거나 주소가 아니면 `ArgumentException`, 정의되지 않은 메서드면 `ArgumentOutOfRangeException` |
| `static Get/Post/Put/Patch/Delete(string uri)` | |
| `Method`, `Uri`, `Headers`(대소문자 무시), `Body`(없으면 null), `ContentType`, `TimeSpan? Timeout` | |
| `WithHeader(name, value)` | 같은 이름은 바꿈. 이름이 비면 `ArgumentException`, 값 null 이면 `ArgumentNullException` |
| `WithBody(byte[] body, string contentType)` / `WithJsonBody(object body, JsonSerializerSettings settings = null)` | JSON 은 UTF-8, `application/json` |
| `WithTimeout(TimeSpan)` | 0 이하면 `ArgumentOutOfRangeException` |
| `WithUri(Uri)` | |

## sealed class HttpResponse

`Uri`, `int StatusCode`, `byte[] Body`(없으면 빈 배열), `IReadOnlyDictionary<string,string> Headers`(대소문자 무시, 읽기 전용), `bool IsSuccessStatusCode`(200~299), `string ReadText()`(UTF-8), `Result<T> ReadJson<T>(JsonSerializerSettings settings = null)`(빈 본문·공백뿐·JSON 오류 → `InvalidResponse`, JSON `null` → 참조·nullable 형식은 성공 null, nullable 이 아닌 값 형식은 `InvalidResponse`, 상태 코드는 보지 않음).

## enum HttpMethod

`Get`, `Head`, `Post`, `Put`, `Patch`, `Delete`. 멱등: Get, Head, Put, Delete.

## 미들웨어

- `delegate UniTask<Result<HttpResponse>> HttpHandler(HttpRequest request, CancellationToken ct)`
- `interface IHttpMiddleware { UniTask<Result<HttpResponse>> SendAsync(HttpRequest request, HttpHandler next, CancellationToken ct); }`
- `TimeoutMiddleware(TimeSpan timeout)`: `request.Timeout` 이 없을 때만 붙임. 0 이하면 `ArgumentOutOfRangeException`.
- `RetryMiddleware(int maxRetries = 3, TimeSpan? baseDelay = 0.5초, TimeSpan? maxDelay = 8초)`: 멱등 메서드가 `NetworkError`, `Timeout`, 408/429/500/502/503/504 이면 다시 보냄. n 번째 재시도 대기 = `min(maxDelay, baseDelay × 2^n)` × [0.5, 1.0). 대기 중 취소 → `Cancelled`. 실시간(timeScale 무시) 대기. 음수·baseDelay > maxDelay 면 `ArgumentOutOfRangeException`.
- `DefaultHeadersMiddleware(IReadOnlyDictionary<string,string> headers)`: 없는 헤더만 붙임.

## 전송

- `interface IHttpTransport { UniTask<Result<HttpResponse>> SendAsync(HttpRequest request, CancellationToken ct); }` — 받는 `Uri` 는 절대 주소.
- `UnityWebRequestTransport`: 메인 스레드로 옮겨 `UnityWebRequest` 로 보냄(옮기는 동안 취소되면 보내지 않고 `Cancelled`). 본문이 있으면 Content-Type 은 `request.ContentType`, 헤더 사전의 Content-Type 은 건너뜀. `result` 가 Success/ProtocolError → 응답, ConnectionError → `NetworkError`, DataProcessingError → `InvalidResponse`. `Timeout` 은 연결된 CTS 의 `CancelAfter`, 초과 시 `Abort` 후 `Timeout`, 호출자 취소는 `Abort` 후 `Cancelled`.

## static class HttpResultCodes

`RangeStart = 1000`(코드 아님), `HttpError = 1001`, `InvalidResponse = 1002`. 연결 실패·타임아웃·취소는 core `ResultCodes` 를 쓴다.
