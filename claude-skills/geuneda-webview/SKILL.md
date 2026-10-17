---
name: geuneda-webview
description: com.geuneda.webview 패키지(네임스페이스 Geuneda.WebView, 선택 어셈블리 Geuneda.WebView.Notice·Geuneda.WebView.Coupon)와 어댑터 com.geuneda.webview.gree(Geuneda.WebView.Gree)로 앱 안 웹뷰 코드를 작성하거나 수정할 때 사용하는 스킬. IWebViewService·WebViewService·WebViewServiceOptions(Factory, AllowedOrigins, LoadTimeout)로 공지·쿠폰·이벤트 웹 페이지를 RectTransform 영역에 열거나(OpenAsync, Close, Closed, HandleBack 뒤로가기), AddCommand·WebViewCommandHandler·WebViewCommand 로 페이지가 부를 명령을 더하거나, Emit 으로 페이지에 이벤트를 보내거나, WebViewResultCodes(12000 블록: LoadFailed, UnknownCommand, InvalidArguments, BridgeUnavailable)를 다루거나, NoticeWebViewCommands(notice.list, notice.read, notice.refresh, notice.changed)·CouponWebViewCommands(coupon.redeem)를 붙이거나, 페이지 쪽 Web~/geuneda-webview.js(geuneda.call Promise, geuneda.on, geuneda.close, geuneda.openUrl)와 샘플 notice.html·coupon.html 을 쓰거나 고치거나, GreeWebViewFactory(gree unity-webview, net.gree.unity-webview)를 설치·설정하거나, IWebViewFactory·IWebViewNative·IWebViewNativeListener 로 다른 웹뷰 플러그인 어댑터를 만들 때 활성화한다.
---

# Geuneda WebView

앱 안 웹뷰와 페이지 ↔ Unity 명령 브리지. 페이지는 함께 주는 JS 파일의 `geuneda.call(명령, 인자)` 로 Unity 명령을 부르고 요청 ID 로 짝지은 결과를 Promise 로 받는다. Unity 는 이벤트를 보낸다. 네이티브 웹뷰는 어댑터(`com.geuneda.webview.gree`)가 넣는다.

## 패키지 정보

- **버전**: webview 0.1.0, webview.gree 0.1.0
- **네임스페이스 / 어셈블리**: `Geuneda.WebView`, 선택 `Geuneda.WebView.Notice`(com.geuneda.notice 가 있을 때), `Geuneda.WebView.Coupon`(com.geuneda.coupon 이 있을 때), 어댑터 `Geuneda.WebView.Gree`(gree 가 있을 때)
- **설치**: `https://github.com/geuneda/geuneda-webview.git`, `https://github.com/geuneda/geuneda-webview-gree.git`(core, UniTask git URL 도 함께). gree 는 `"net.gree.unity-webview": "https://github.com/gree/unity-webview.git?path=/dist/package#20f14061ca4b45e8490c1e89e00684a5d3ed6be0"` 처럼 커밋을 고정해 게임이 넣고 uGUI(`com.unity.ugui`)가 필요. Unity 2021.3+
- **페이지 파일**: 패키지의 `Web~/geuneda-webview.js`(Unity 가 가져오지 않는 폴더), 샘플 `Web~/notice.html`, `Web~/coupon.html`. 페이지 서버가 함께 내려준다
- **기여 가이드**: 각 패키지 루트의 `AGENTS.md`
- **출처**: Lucky Defense PercentWebview(gree 감쌈)·WebView.Notice·Coupon.WebViewPlugin 의 보완(로드맵 5-2 3단위)

## 핵심 API

전체 시그니처는 `references/api.md`.

- `new WebViewService(WebViewServiceOptions)` → `IWebViewService`. 필수 `Factory`(`new GreeWebViewFactory()`), `AllowedOrigins`(`https://host[:port]`, 경로 없이). `LoadTimeout` 10초.
- `OpenAsync(url, frame = null, ct)` → `Result`: 허용 출처 주소만(아니면 `ArgumentException`). 페이지 JS 와 연결되면(준비 알림 → 메인 프레임에 키 → 키로 응답) 보이게 하고 성공. 실패 `LoadFailed`(연결 실패, 브리지 없는 HTTP 오류 페이지), `Timeout`, `Cancelled`(취소·열기 중 닫기), `InProgress`(이미 열림).
- `Close()`, `event Closed`, `HandleBack()`(페이지 기록 → 닫기, 열려 있지 않으면 false), `IsOpen`, `PageUrl`.
- `AddCommand(name, (command, token) => UniTask<Result<object>>)` → `IDisposable`(해제). `command.Args`(JObject), `command.TryGetString(name, out value)`, `command.PageUrl`. 기본 명령 `close`, `openUrl` 은 등록 불가.
- `Emit(name, value = null)`: 페이지 이벤트(`geuneda.on`). 열린 페이지가 없으면 버림.
- `NoticeWebViewCommands.Add(webView, notices, utcNow)`, `CouponWebViewCommands.Add<TGrant>(webView, coupons, redeemed)` → `IDisposable`.
- JS: `geuneda.call(command, args)` → `Promise<{ok, code, message, value}>`(reject 없음), `geuneda.on/off(name, handler)`, `geuneda.close()`, `geuneda.openUrl(url)`, `geuneda.isAvailable()`, `geuneda.codes`.

## 사용 패턴

```csharp
var webView = new WebViewService(new WebViewServiceOptions
{
    Factory = new GreeWebViewFactory(),
    AllowedOrigins = new[] { "https://notice.example.com" }
});
MainInstaller.Bind<IWebViewService>(webView);
NoticeWebViewCommands.Add(webView, notices, () => timeService.DateTimeUtcNow);
CouponWebViewCommands.Add<MyGrant>(webView, coupons, redemption => SyncWalletFromServerAsync().Forget());

var opened = await webView.OpenAsync($"https://notice.example.com/{language}/notice.html", noticeFrame, token);
if (!opened.IsSuccess) ShowToast("공지를 열 수 없습니다");

// 게임의 뒤로가기 처리기
if (webView.HandleBack()) return;
```

```html
<script src="geuneda-webview.js"></script>   <!-- 페이지 스크립트보다 먼저, async·defer 없이 -->
<script>
  geuneda.call('notice.list', { category: 'event' }).then(function (r) { if (r.ok) render(r.value.notices); else showError(r.code); });
  geuneda.on('notice.changed', reload);
  closeButton.onclick = geuneda.close;
</script>
```

## 규칙

- **열기 성공 = 연결**(`ready` → Unity 가 `bind` 로 키를 `EvaluateJS` → 페이지가 키로 `bound`). 로드 끝만으로 성공시키지 않는다(404 도 로드는 끝남). gree Android 는 리소스 HTTP 오류도 알리므로 HTTP 오류만으로 실패시키지 않고, 준비 알림 없이 로드가 끝났고 400 이상이 있었을 때만 `LoadFailed`.
- **키·문서 ID**: 키는 열기마다 무작위이고 `EvaluateJS`(메인 프레임만)로만 넘기므로 다른 출처 iframe 은 명령을 보낼 수 없다(gree 는 보낸 프레임을 알려 주지 않음). 결과는 명령을 보낸 문서(JS 가 만든 무작위 ID)에만 간다.
- **실행 순간의 출처 검사**: Unity 가 보내는 스크립트는 실행 순간의 `window.location.origin` 이 허용 출처일 때만 페이지에 넘긴다. 이동 제한을 비껴간 허용 밖 이동이 시작되면(Android POST) 웹뷰를 닫는다.
- **허용 출처 세 겹**: 연 주소 검사, 네이티브 이동 제한(`DenyUrlPattern`), 지금 페이지 주소(메인 프레임 로드 끝)로 명령·결과·이벤트 거르기. 다른 출처 링크는 JS 파일이 외부 브라우저로 연다.
- **토큰을 페이지에 넘기지 않는다.** 쿠폰 사용은 Unity 의 `ICouponService` 가 인증해 보낸다.
- **명령 결과**: 성공 `{ok:true, code:0, value}`(camelCase, null 속성 뺌), 실패는 처리기의 code·message 그대로, 모르는 명령 12002, 인자 형식 12003, 처리기가 던진 취소·제한 시간은 `Cancelled`·`Timeout`, 그 밖의 처리기 예외는 `Unknown`(1)+Error 로그, 앱 밖 12004(JS).
- **닫히면** 처리기 토큰이 취소되고 결과는 버린다. 닫혀도 끝까지 해야 하는 일(지급 요청)은 토큰을 넘기지 않는다(`coupon.redeem` 이 그렇게 함).
- **영역**은 매 프레임(`LastPostLateUpdate`) 따라가고, 영역이 파괴되면 닫는다. 없으면 `Screen.safeArea`.
- 메인 스레드 전용(다른 스레드에서 온 열기 취소만 메인 스레드로 옮김). 웹뷰는 하나만.

## 함정

- JS 파일은 `<script src>` 로 페이지 스크립트보다 먼저, `async`·`defer` 없이 넣는다. 늦게 실행되면 준비 알림이 로드 끝보다 늦어 HTTP 오류 판정이 틀리거나 제한 시간까지 기다린다.
- 웹뷰는 네이티브 뷰라 게임 UI 위에 그려진다. 닫기 버튼은 페이지(`geuneda.close()`)나 영역 밖에 둔다.
- iOS 는 iframe 이동에도 이동 제한이 걸려 다른 출처 iframe 이 열리지 않는다. 같은 출처 iframe 은 부모의 `window.geuneda`(키)에 닿으므로 페이지 코드와 같은 권한이다.
- 이동 제한을 걸 수 없는 플랫폼(WebGL, Linux 에디터)에서 gree 어댑터는 열기를 `LoadFailed` 로 끝낸다.
- IL2CPP: 처리기가 돌려주는 값은 `JObject` 로 만들거나 `[Preserve]` 를 붙인다(Newtonsoft 리플렉션 직렬화).
- gree 는 iOS·macOS 에서 받은 글을 URL 디코딩한다(`+` → 공백). JS 파일이 그 경로에서 인코딩해 보내므로 직접 `window.Unity.call` 을 부르지 않는다.
- gree 는 uGUI 가 필요하고, 태그가 없어 커밋으로 고정한다. 호스트 레포에는 gree 가 없어 어댑터가 컴파일되지 않는다.
- 상호 운용 테스트(`GreeWebViewInteropTest`)는 macOS 에디터의 그래픽 장치가 필요하다(`-nographics` 불가).
- 처리기 인자(`command.Args`)는 페이지가 보낸 값이다. 형식을 확인하고 쓴다.
