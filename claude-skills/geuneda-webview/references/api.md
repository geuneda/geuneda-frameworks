# Geuneda WebView API 레퍼런스

네임스페이스 `Geuneda.WebView`(asmdef `Geuneda.WebView`, 참조 `Geuneda.Core`, `UniTask`, Newtonsoft). 선택 어셈블리 `Geuneda.WebView.Notice`(versionDefines `com.geuneda.notice` → `GEUNEDA_WEBVIEW_NOTICE`), `Geuneda.WebView.Coupon`(`com.geuneda.coupon` → `GEUNEDA_WEBVIEW_COUPON`). 어댑터 `Geuneda.WebView.Gree`(`net.gree.unity-webview` → `GEUNEDA_WEBVIEW_GREE`, 참조 `unity-webview`). webview 0.1.0, webview.gree 0.1.0.

## interface IWebViewService / sealed class WebViewService : IDisposable

| 멤버 | 설명 |
|------|------|
| `WebViewService(WebViewServiceOptions options)` | 메인 스레드. null 은 `ArgumentNullException`, 어댑터 없음·허용 출처 없음·출처 모양 틀림(경로·쿼리·사용자 정보·http(s) 아님·ASCII 아닌 호스트)·제한 시간 0 이하는 `ArgumentException` |
| `bool IsOpen` | 열고 있거나 열려 있음 |
| `string PageUrl` | 마지막으로 로드가 끝난 메인 프레임(그 전에는 연 주소), 닫혀 있으면 null |
| `event Action Closed` | 열려 있던 웹뷰가 닫힘(열기 실패에는 없음). 처리기 예외는 Error 로그 |
| `UniTask<Result> OpenAsync(string url, RectTransform frame = null, CancellationToken ct = default)` | 허용 출처 주소가 아니면 `ArgumentException`(호출 자리에서), 버린 뒤면 `ObjectDisposedException` |
| `void Close()` | 열기 중이면 열기를 `Cancelled` 로 끝냄 |
| `bool HandleBack()` | 기록 있으면 `GoBack`, 없으면(또는 열기 중) 닫기. 열려 있지 않으면 false |
| `IDisposable AddCommand(string name, WebViewCommandHandler handler)` | 이름 1~64자 ASCII 영숫자·`.`·`_`·`-`. 기본 명령·규칙 위반은 `ArgumentException`, 중복은 `InvalidOperationException`, 처리기 null 은 `ArgumentNullException`. 해제는 등록 객체 기준 |
| `void Emit(string name, object value = null)` | 이름 규칙 위반은 `ArgumentException`. 보이는 페이지가 없거나 허용 밖 페이지면 버림 |
| `void Dispose()` | 닫기(열려 있었으면 `Closed`) |

### sealed class WebViewServiceOptions

| 속성 | 기본 | 설명 |
|------|------|------|
| `IWebViewFactory Factory` | 필수 | `new GreeWebViewFactory()` |
| `IEnumerable<string> AllowedOrigins` | 필수 | `https://notice.example.com`, `http://127.0.0.1:5700`. 소문자·기본 포트 생략으로 정규화, 중복 제거 |
| `TimeSpan LoadTimeout` | 10초 | 페이지와 연결될 때까지 기다리는 시간 |

### delegate WebViewCommandHandler / sealed class WebViewCommand

- `UniTask<Result<object>> WebViewCommandHandler(WebViewCommand command, CancellationToken ct)`: 메인 스레드. 토큰은 닫힐 때 취소(결과 버림). 던진 취소·제한 시간 예외는 `Cancelled`·`Timeout`, 그 밖의 예외는 `Unknown` 응답 + Error 로그.
- `WebViewCommand`: `Name`, `JObject Args`(없으면 빈 객체), `PageUrl`, `bool TryGetString(string name, out string value)`.

### static class WebViewResultCodes

| 코드 | 값 | 뜻 |
|------|----|----|
| `LoadFailed` | 12001 | 연결 실패, 브리지 없는 HTTP 오류 페이지, Android System WebView 없음 |
| `UnknownCommand` | 12002 | 등록되지 않은 명령(페이지에) |
| `InvalidArguments` | 12003 | 명령 이름·인자 형식(페이지에) |
| `BridgeUnavailable` | 12004 | 앱 웹뷰 밖(JS 파일만) |

## 어댑터 계약

| 타입 | 멤버 |
|------|------|
| `IWebViewFactory` | `IWebViewNative Create(WebViewNativeSettings settings, IWebViewNativeListener listener)`: 보이지 않게 만들고 첫 로드 전에 이동 제한을 건다 |
| `IWebViewNative : IDisposable` | `bool CanGoBack`, `LoadUrl(url)`, `EvaluateJavaScript(script)`(메인 프레임에서 실행해야 함: 키 전달이 이것에 기댐), `SetMargins(WebViewMargins)`(Unity 화면 픽셀, 가장자리에서의 거리. 여백이나 화면 크기가 바뀌면 다시 옴), `SetVisible(bool)`, `GoBack()`. 준비 전 값은 준비 뒤 마지막 값으로 적용 |
| `IWebViewNativeListener` | `OnMessage(json)`(전달 인코딩을 푼 글), `OnPageStarted(url)`(이동 시작, 허용 밖 http·https 면 서비스가 닫음), `OnPageLoaded(url)`(메인 프레임), `OnLoadError(description)`, `OnHttpError(status)`(리소스 오류도 올 수 있음, 모르면 0) |
| `WebViewNativeSettings` | `AllowedOrigins`, `DenyUrlPattern`(Java·ICU·.NET 공통 정규식, 허용 출처 밖 http·https) |
| `WebViewMargins` | `Left`, `Top`, `Right`, `Bottom`, 값 동등 |

## 메시지 규약(JS 파일과 짝)

- 페이지 → Unity: `{"type":"ready","doc"}`, `{"type":"bound","doc","key"}`, `{"type":"call","doc","key","id":"1"|1,"command":"notice.list","args":{...}}`(doc 은 1~64자 영숫자·`.`·`_`·`-`, id 는 1~64자 문자열 또는 정수). `bound`·`call` 은 키가 맞을 때만 받음(아니면 Warning).
- Unity → 페이지(메인 프레임에서만 실행, `(function(o){if(o==="허용 출처"||...){...}})(window.location.origin)` 로 감싸 실행 순간 출처가 허용 출처일 때만): `window.geuneda&&window.geuneda.__receive({"type":"bind","doc","key"})`(준비 알림에 답함), `{"type":"result","doc","id","ok","code","message"?,"value"?}`, `{"type":"event","name","value"?}`. U+2028·U+2029 는 이스케이프. JS 는 자기 doc 의 bind·result 만 받고, 키를 받기 전 명령은 대기열에 둔다.
- 전달: iOS·macOS 는 `window.webkit.messageHandlers.unityControl.postMessage(encodeURIComponent(json))`(gree 가 `UnEscapeURL`), Android 는 `window.Unity.call(json)`.

## 공지 명령 `NoticeWebViewCommands`(Geuneda.WebView.Notice)

`static IDisposable Add(IWebViewService webView, INoticeService notices, Func<DateTime> utcNow = null)` — 상수 `List`, `Read`, `Refresh`, `ChangedEvent`.

| 명령 | 인자 | 값 / 실패 |
|------|------|------|
| `notice.list` | `{category?: string}` | `{language, unreadCount, notices: [{id, category, priority, startsAt?, endsAt?, popup, action?, title, body?, linkUrl?, linkLabel?, read}]}` / category 가 문자열이 아니면 12003 |
| `notice.read` | `{id: string}` | 없음 / id 없음·규칙 위반은 12003 |
| `notice.refresh` | | 없음 / 공지 패키지 코드(`InvalidDocument` 10001, `HttpError`, core 공용) |
| 이벤트 `notice.changed` | | `INoticeService.Changed` 마다 |

## 쿠폰 명령 `CouponWebViewCommands`(Geuneda.WebView.Coupon)

`static IDisposable Add<TGrant>(IWebViewService webView, ICouponService coupons, Action<CouponRedemption<TGrant>> redeemed = null)` — 상수 `Redeem`.

| 명령 | 인자 | 값 / 실패 |
|------|------|------|
| `coupon.redeem` | `{code: string}` | `{campaignId, alreadyRedeemed, redeemedAt?, grant?}` / `CouponResultCodes`, core 공용, code 없음은 12003 |

요청에 닫기 토큰을 넘기지 않는다(닫혀도 끝까지, `redeemed` 콜백은 닫힌 뒤에도 옴). 콜백 예외는 Error 로그.

## gree 어댑터 `GreeWebViewFactory`(Geuneda.WebView.Gree)

- 열 때마다 `GeunedaWebView-<GUID>` 게임 오브젝트(`DontDestroyOnLoad`) + `WebViewObject`. `Init(cb, err, httpErr, ld, started, androidForceDarkMode: 1)`.
- 준비(`IsInitialized`) 전 값은 `Update` 에서 `SetURLPattern("", deny, "")` → `SetMargins(..., relative: true)` → `SetVisibility` → `LoadURL` 순서로 적용. 이동 제한을 걸 수 없으면 로드하지 않고 `OnLoadError`(열기 `LoadFailed`). 데스크톱(macOS·Windows)은 화면 크기만 바뀌면 여백을 한 번 바꿔 넘겨 gree 가 뷰 크기를 다시 계산하게 함.
- `WebViewObject.IsWebViewAvailable()` 가 false 면 첫 `Update` 에서 `OnLoadError` 한 번.
- 네임스페이스 `Gree.UnityWebView`, 어셈블리 `unity-webview`. 확인한 커밋 `20f14061ca4b45e8490c1e89e00684a5d3ed6be0`.

## 테스트

- EditMode `Geuneda.WebView.Tests.EditMode`(`FakeWebViewFactory`), `Geuneda.WebView.Notice.Tests.EditMode`, `Geuneda.WebView.Coupon.Tests.EditMode`.
- JS: `node --test "Web~/tests/*.test.mjs"`(Node 21+).
- PlayMode `Geuneda.WebView.Gree.Tests.PlayMode` 의 `GreeWebViewInteropTest`(명시 실행, macOS 에디터 그래픽 장치, `Web~` 정적 서버, `GEUNEDA_WEBVIEW_INTEROP_URL`).
