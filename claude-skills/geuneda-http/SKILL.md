---
name: geuneda-http
description: com.geuneda.http 패키지(네임스페이스 Geuneda.Http)로 코드를 작성하거나 수정할 때 사용하는 스킬. HttpClientBuilder 로 IHttpClient 를 만들거나, GetJsonAsync/PostJsonAsync/SendAsync 로 REST API 를 부르거나, Result<HttpResponse> 의 NetworkError/Timeout/Cancelled 와 4xx·5xx 상태 코드를 처리하거나, IHttpMiddleware 로 공통 헤더·토큰·재시도를 만들거나, TimeoutMiddleware/RetryMiddleware/DefaultHeadersMiddleware 를 붙이거나, 테스트용 IHttpTransport 를 바꿀 때 활성화한다.
---

# Geuneda Http

UnityWebRequest 기반 HTTP 클라이언트다. 공통 처리는 미들웨어 체인에 두고, 결과는 core 결과 규약(`Result`)을 따른다.

## 패키지 정보

- **네임스페이스 / 어셈블리**: `Geuneda.Http`
- **설치**: `https://github.com/geuneda/geuneda-http.git` (core, UniTask git URL 도 함께)
- **의존성**: `com.geuneda.core` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1, `com.unity.modules.unitywebrequest` 1.0.0
- **최소 Unity 버전**: 2021.3
- **기여 가이드**: 패키지 루트의 `AGENTS.md`

## 핵심 API

전체 시그니처는 `references/api.md`.

- `new HttpClientBuilder().WithBaseAddress(url).AddMiddleware(mw, order).WithTransport(t).WithJsonSettings(s).Build()` → `HttpClient : IHttpClient`.
- `IHttpClient`: `SendAsync(HttpRequest)`, `SendJsonAsync<T>(HttpRequest)`, `GetAsync(uri)`, `GetJsonAsync<T>(uri)`, `PostJsonAsync(uri, body)`, `PostJsonAsync<T>(uri, body)`. 모두 `CancellationToken` 을 받고 `UniTask<Result<...>>` 를 돌려준다.
- `HttpRequest.Get/Post/Put/Patch/Delete(uri)`, `WithHeader`, `WithBody`, `WithJsonBody`, `WithTimeout`, `WithUri` — 바꾸지 않는 객체, 복사본을 돌려준다.
- `HttpResponse`: `StatusCode`, `Body`, `Headers`(대소문자 무시), `IsSuccessStatusCode`, `ReadText()`, `ReadJson<T>()`.
- `IHttpMiddleware.SendAsync(request, next, ct)`, `HttpHandler next`.
- `HttpResultCodes`: `HttpError` 1001(JSON 편의 메서드에서 2xx 아님), `InvalidResponse` 1002(본문 비었거나 JSON 오류, 내려받기 처리 오류).

## 사용 패턴

```csharp
var client = new HttpClientBuilder()
    .WithBaseAddress("https://api.example.com/v1/")
    .AddMiddleware(new TimeoutMiddleware(TimeSpan.FromSeconds(10)))
    .AddMiddleware(new RetryMiddleware())
    .Build();
MainInstaller.Bind<IHttpClient>(client);

var result = await http.GetJsonAsync<Profile>("profiles/me", token);
if (!result.TryGetValue(out var profile))
{
    if (result.Code == ResultCodes.NetworkError || result.Code == ResultCodes.Timeout) ShowRetryPopup();
    return;
}

// 오류 본문이 필요하면 SendAsync 로 응답을 직접 본다
var raw = await http.SendAsync(HttpRequest.Post("purchases").WithJsonBody(receipt), token);
if (raw.TryGetValue(out var response) && response.StatusCode == 409)
{
    var error = response.ReadJson<ServerError>();
}

// 토큰 헤더 미들웨어
public sealed class AuthHeaderMiddleware : IHttpMiddleware
{
    public UniTask<Result<HttpResponse>> SendAsync(HttpRequest request, HttpHandler next, CancellationToken ct)
        => next(request.WithHeader("Authorization", "Bearer " + _tokens.AccessToken), ct);
}
```

## 함정

- 4xx, 5xx 는 **성공한** `Result` 의 응답이다(`IsSuccessStatusCode` 로 구분). 실패 `Result` 는 응답이 없을 때(연결 실패 `NetworkError`, 타임아웃 `Timeout`, 취소 `Cancelled`)뿐이다. JSON 편의 메서드만 2xx 가 아니면 `HttpError` 로 실패한다.
- 취소는 예외가 아니라 `ResultCodes.Cancelled` 다. 미들웨어가 취소를 예외로 던져도 호출자 토큰이 취소됐으면 클라이언트가 코드로 바꾼다.
- 잘못된 주소, 기본 주소 없는 상대 주소, 제한된 헤더는 예외다(오용).
- 기본 주소를 경로와 이으려면 끝을 `/` 로 둔다(`https://host/v1/` + `users` → `/v1/users`).
- 타임아웃과 재시도는 기본으로 꺼져 있다. `TimeoutMiddleware`, `RetryMiddleware` 를 추가해야 동작한다. 재시도는 GET, HEAD, PUT, DELETE 만, 연결 실패·타임아웃·408/429/500/502/503/504 에만 한다. `Retry-After` 는 보지 않는다.
- `HttpRequest` 를 바꾸지 말고 `With*` 복사본을 `next` 에 넘긴다. 다시 보내려면 `next` 를 다시 부른다.
- 미들웨어 order 는 작을수록 바깥(먼저), 같으면 추가 순서다.
- 어느 스레드에서 불러도 된다. 전송이 메인 스레드로 옮겨 보낸다.
- Player Settings 의 HTTP 허용이 꺼져 있으면 플레이어에서 `http://` 가 막힐 수 있다. 운영은 `https://`.
- 본문이 있으면 Content-Type 은 `WithBody`/`WithJsonBody` 값이 이긴다. 헤더 사전의 Content-Type 은 무시된다.
- 공백뿐인 본문은 `InvalidResponse`. JSON 리터럴 `null` 은 참조 형식·nullable 값 형식이면 성공에 값 null, `int` 같은 nullable 이 아닌 값 형식이면 `InvalidResponse` 다.
- 헤더 사전은 읽기 전용이다. 정의되지 않은 `HttpMethod` 값은 생성자에서 `ArgumentOutOfRangeException`.
- 테스트에서는 `WithTransport` 로 가짜 `IHttpTransport` 를 넣는다.
