---
name: geuneda-notice
description: com.geuneda.notice 패키지(네임스페이스 Geuneda.Notice, 서버 Geuneda.Notice.Server)로 게임 공지 코드를 작성하거나 수정할 때 사용하는 스킬. INoticeService·NoticeService·NoticeServiceOptions 로 공지 문서를 받거나(RefreshAsync, ETag 304), GetNotices 로 기간·플랫폼·언어·분류에 맞는 공지를 정렬해 보여 주거나, MarkRead·IsRead·GetUnreadCount 로 읽음과 레드닷을 다루거나, GetPopups·SnoozeForToday·IsSnoozed 로 게임 진입 공지 팝업과 '오늘 하루 안 보기'를 만들거나, Language·Changed 를 쓰거나, NoticeDocument·NoticeItem·NoticeContent 로 공지 JSON 문서(contents 언어별 내용, startsAt·endsAt, platforms, popup, action, priority, category)를 읽고 쓰거나, ASP.NET Core 서버에서 AddGeunedaNotice·AddFileSource·AddSource·MapGeunedaNotice·INoticeSource 로 지금 보이는 공지를 ETag 와 함께 내려줄 때 활성화한다.
---

# Geuneda Notice

게임 공지 목록. 모든 언어·플랫폼의 공지를 담은 JSON 문서 하나를 받아 지금 시각·플랫폼·언어로 거르고 정렬한다. 읽음과 '오늘 안 보기'를 기기에 기록해 안 읽은 수와 진입 팝업을 준다. 화면은 게임 몫이다. 문서 형식은 Unity 와 .NET 서버가 같은 소스(`Runtime/Document`)로 읽는다.

## 패키지 정보

- **버전**: 0.1.0
- **네임스페이스 / 어셈블리**: `Geuneda.Notice`(Unity), 서버 `Geuneda.Notice.Server`
- **설치**: `https://github.com/geuneda/geuneda-notice.git`(core, http, UniTask git URL 도 함께. Newtonsoft 는 레지스트리 의존성). Unity 2021.3+
- **서버**: `Server~/src/Geuneda.Notice.Server/Geuneda.Notice.Server.csproj`(net10.0, ASP.NET Core, Newtonsoft 13.0.3)를 ProjectReference 로 참조
- **기여 가이드**: 패키지 루트의 `AGENTS.md`
- **출처**: Lucky Defense Percent `WebView.Notice`(공지 ID 별 로컬 읽음, 기간·OS·언어 필터)와 SpellDefense 공지(진입 팝업, 오늘 안 보기)(로드맵 5-2 1단위)

## 핵심 API

전체 시그니처는 `references/api.md`.

- `new NoticeService(NoticeServiceOptions)` → `INoticeService`. 필수 `HttpClient`, `DocumentUri`, `Language`. 기본 `Platform` = `NoticePlatforms.Current`, `RequestTimeout` 10초, `DayTimeZone` 기기 시간대, `StateKey` `geuneda.notice.state`.
- `RefreshAsync(ct)` → `Result`. single-flight, `If-None-Match`, 실패하면 지금 문서 유지. `Document`(이 실행에서 받아들인 문서, 처음엔 null).
- `GetNotices(utcNow, category = null)`, `GetUnreadCount(utcNow, category = null)`, `GetPopups(utcNow)` → 정렬된 `Notice`(`Id`, `Category`, `Priority`, `StartsAt`, `EndsAt`, `Popup`, `Action`, `Title`, `Body`, `LinkUrl`, `LinkLabel`, `Item`, `Content`).
- `MarkRead(id)`, `IsRead(id)`, `SnoozeForToday(id, utcNow)`, `IsSnoozed(id, utcNow)`, `Language { get; set; }`, `event Action Changed`.
- 문서: `NoticeDocument.Parse(byte[]|string, strict = false)`, `ToUtf8Json()`, `ActiveAt(utcNow)`, `Items`, `DefaultLanguage`. `NoticeItem(id, contents, category, priority, startsAt, endsAt, platforms, popup, action)`, `IsActiveAt`, `IsFor`, `FindContent(language, fallback)`. `NoticeContent(title, body, linkUrl, linkLabel)`. 규칙 위반은 `NoticeDocumentException`.
- 결과 코드: `NoticeResultCodes.InvalidDocument` 10001(10000 블록).
- 서버: `services.AddGeunedaNotice(o => o.CacheControl = ...)` → `NoticeServerBuilder.AddFileSource(path)` / `AddSource<T>(lifetime)`, `app.MapGeunedaNotice("/notices")`, `INoticeSource.GetDocumentAsync(ct)`.

## 사용 패턴

```csharp
using Geuneda.Core;
using Geuneda.Http;
using Geuneda.Notice;
using Geuneda.Services;

var notices = new NoticeService(new NoticeServiceOptions
{
    HttpClient = new HttpClientBuilder().AddMiddleware(new RetryMiddleware()).Build(),   // 인증 미들웨어 불필요
    DocumentUri = new EnvValue<string>(devUrl, qaUrl, prodUrl).Value,
    Language = settings.LanguageCode
});
MainInstaller.Bind<INoticeService>(notices);

var time = MainInstaller.Resolve<ITimeService>();
await notices.RefreshAsync(token);                                // 로비 진입 때. 실패해도 지난 문서 그대로

notices.Changed += () => redDot.SetLeafValue(RedDotPaths.Notice, notices.GetUnreadCount(time.DateTimeUtcNow));

foreach (var notice in notices.GetNotices(time.DateTimeUtcNow))  // 공지 탭
    cell.Show(notice.Title, notice.Body, unread: !notices.IsRead(notice.Id));
notices.MarkRead(id);                                             // 상세를 열 때

foreach (var popup in notices.GetPopups(time.DateTimeUtcNow))     // 진입 팝업(읽음은 안 봄)
    await ShowPopupAsync(popup, onTodayClose: () => notices.SnoozeForToday(popup.Id, time.DateTimeUtcNow));
```

서버:

```csharp
builder.Services.AddGeunedaNotice().AddFileSource("notices.json");   // 또는 .AddSource<DbNoticeSource>(ServiceLifetime.Scoped)
app.MapGeunedaNotice("/notices");
```

## 문서

```json
{ "defaultLanguage": "en", "notices": [ { "id": "update-2-1", "category": "notice", "priority": 10, "popup": true, "action": "shop:gem_100",
  "startsAt": "2026-10-17T00:00:00Z", "endsAt": "2026-10-31T00:00:00Z", "platforms": ["android", "ios"],
  "contents": { "ko": { "title": "...", "body": "...", "linkUrl": "https://...", "linkLabel": "..." }, "en": { "title": "..." } } } ] }
```

- `id` 1~128자 영문·숫자·`.`·`_`·`-`(읽음 기록의 키, 바꾸지 않음), `category` 기본 `notice`, `platforms` 없으면 모두(빈 배열 거절), `contents` 언어 태그 → 내용(하나 이상, `title` 필수), `linkUrl` 은 http·https 절대 주소만, 시각은 Z·오프셋 필수.
- 클라이언트는 모르는 속성을 무시, 서버 파일 원천·`strict` 는 거절. 값 오류는 문서 전체 거절.

## 규칙

- **보이는 공지**: `startsAt <= now < endsAt`, 플랫폼 일치, 언어 → 태그를 줄인 언어 → `defaultLanguage` 내용이 있어야 함. 정렬은 `priority` 큰 것 → `startsAt` 늦은 것(없으면 가장 이른 것) → 문서 순서.
- **시각은 호출자가 UTC 로 넘긴다**(UTC 아니면 `ArgumentException`). 서버 시각은 services `ITimeService.DateTimeUtcNow`.
- **`Changed` 는 기간 경계에 오지 않는다.** 공지 화면·레드닷은 화면에 들어올 때도 다시 센다.
- **기록**: PlayerPrefs 키 하나(기기 단위), 쓸 때마다 Save. 받은 문서에 없다는 이유로 지우지 않는다(오래된 CDN 사본 대비). 읽음은 최근 500개, 지난 '오늘 안 보기'는 다음 기록 때 지운다. 서비스마다 `StateKey` 를 따로 둔다.
- **'오늘 안 보기'** 는 `DayTimeZone` 의 다음 날 시작까지(두 번 있는 자정은 지금 이후 먼저 오는 것, 없는 자정은 시계가 넘어간 순간).
- **서버는 지금 보이는 공지만 내려준다**(미래·끝난 공지 제외, ETag = 바이트 SHA-256, `Cache-Control` 기본 `no-cache`, `If-None-Match` 304). 원천은 문서가 같으면 같은 인스턴스를 돌려준다(직렬화 재사용).
- 메인 스레드에서 쓴다.

## 함정

- `id` 를 바꾸면 모두에게 다시 안 읽음이 된다. 내용만 고친다.
- `linkUrl` 에 게임 스킴(`game://`)은 거절된다. 게임 안 이동은 `action` 에 넣고 게임이 해석한다.
- 정적 호스팅(CDN)에 문서를 그대로 올리면 기간 밖 공지도 내려간다(클라이언트가 거르지만 미래 공지가 노출됨). 서버 헬퍼를 쓰거나 올리기 전에 `ActiveAt` 으로 거른다.
- 운영 파일은 엄격하게 읽는다. `startAt` 같은 오타는 서버 시작·교체 때 거절된다(교체 실패는 오류 로그 한 번 뒤 이전 문서 유지).
- 긴 `Cache-Control: max-age` 는 공지 시작·끝을 늦춘다.
- 오프라인으로 시작하면 공지가 없다(디스크에 문서를 두지 않음).
