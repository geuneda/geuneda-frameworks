# Geuneda Notice API 레퍼런스

네임스페이스 `Geuneda.Notice`(Unity asmdef `Geuneda.Notice`, 참조 `Geuneda.Core`, `Geuneda.Http`, `UniTask`), 서버 `Geuneda.Notice.Server`(`Server~/src/Geuneda.Notice.Server`, net10.0). notice 0.1.0.

## 서비스

### interface INoticeService / sealed class NoticeService : INoticeService

| 멤버 | 설명 |
|------|------|
| `NoticeService(NoticeServiceOptions options)` | 메인 스레드(PlayerPrefs 기록을 읽음). null 이면 `ArgumentNullException`, 필수 값 없음·제한 시간 0 이하·잘못된 언어 태그·플랫폼 이름은 `ArgumentException`. 기록을 읽지 못하면 경고 뒤 빈 기록 |
| `NoticeDocument Document` | 이 실행에서 마지막으로 받아들인 문서. 처음 성공 전 null |
| `string Language { get; set; }` | 비교용 모양(소문자, `-`). 바뀌면 `Changed`. 잘못된 태그는 `ArgumentException` |
| `event Action Changed` | 문서 교체(같은 바이트 제외), 언어 변경, 읽음·'오늘 안 보기' 기록 때. 처리기 예외는 Error 로그 후 다음 처리기 |
| `UniTask<Result> RefreshAsync(CancellationToken ct = default)` | single-flight, `If-None-Match`, 304·같은 바이트면 그대로. 토큰은 이 호출의 기다림만 멈춤 |
| `IReadOnlyList<Notice> GetNotices(DateTime utcNow, string category = null)` | 보이는 공지(정렬). 문서가 없으면 빈 목록 |
| `int GetUnreadCount(DateTime utcNow, string category = null)` | 보이는 공지 중 안 읽은 수 |
| `IReadOnlyList<Notice> GetPopups(DateTime utcNow)` | 보이는 공지 중 `Popup` 이고 '오늘 안 보기'가 아닌 것(읽음은 안 봄) |
| `bool IsRead(string id)` | null 은 false |
| `void MarkRead(string id)` | 처음이면 기록·`Changed`. 문서에 없는 ID 도 기록. 최근 500개 유지. 잘못된 ID 는 `ArgumentException` |
| `bool IsSnoozed(string id, DateTime utcNow)` | |
| `void SnoozeForToday(string id, DateTime utcNow)` | `DayTimeZone` 의 다음 날 시작까지. 같은 날 다시 부르면 아무 일 없음. 지난 기록을 함께 지움 |

시각 인자가 UTC 가 아니면 `ArgumentException`. 메인 스레드 전용.

### sealed class NoticeServiceOptions

| 속성 | 기본 | 설명 |
|------|------|------|
| `IHttpClient HttpClient` | 필수 | GET 이라 `RetryMiddleware` 가능, 인증 미들웨어 불필요 |
| `string DocumentUri` | 필수 | 절대 주소 또는 기본 주소 기준 상대 주소 |
| `string Language` | 필수 | `ko`, `zh-Hant` 등 |
| `string Platform` | `NoticePlatforms.Current` | 1~32자 영문 소문자·숫자·`_`·`-` |
| `TimeSpan RequestTimeout` | 10초 | 넘으면 `ResultCodes.Timeout` |
| `TimeZoneInfo DayTimeZone` | `TimeZoneInfo.Local` | '오늘'을 나눌 시간대 |
| `string StateKey` | `geuneda.notice.state` | 기록 PlayerPrefs 키. 서비스마다 따로 |

### sealed class Notice

`Item`(`NoticeItem`), `Content`(`NoticeContent`), `Id`, `Category`, `Priority`, `StartsAt`, `EndsAt`, `Popup`, `Action`, `Title`, `Body`, `LinkUrl`, `LinkLabel`.

### static class NoticeResultCodes

| 상수 | 값 | 뜻 |
|------|----|----|
| `InvalidDocument` | 10001 | 받은 문서가 규칙에 맞지 않음(지금 문서 유지, 경고 로그) |

그 밖의 실패: `ResultCodes.NetworkError`·`Timeout`·`Cancelled`, `HttpResultCodes.HttpError`(2xx·304 아님, 조건부 요청이 아닌데 304).

### static partial class NoticePlatforms

`Android` = `android`, `Ios` = `ios`, `Standalone` = `standalone`, `WebGl` = `webgl`, `Current`(빌드 대상, 에디터는 활성 빌드 대상).

## 문서 (`Runtime/Document`, 서버와 공유)

### sealed class NoticeDocument

| 멤버 | 설명 |
|------|------|
| `NoticeDocument(IEnumerable<NoticeItem> items, string defaultLanguage = null)` | 복사. null 목록·null 항목·겹친 ID·잘못된 언어 태그는 `NoticeDocumentException` |
| `IReadOnlyList<NoticeItem> Items` | 문서 순서 |
| `string DefaultLanguage` | 비교용 모양. 없으면 null |
| `static NoticeDocument Parse(byte[] utf8, bool strict = false)`, `Parse(string json, bool strict = false)` | 엄격한 UTF-8(BOM 허용), 같은 이름 속성·뒤 내용·시간대 없는 시각 거절, JSON null 은 없는 값. `strict` 는 모르는 속성도 거절 |
| `NoticeDocument ActiveAt(DateTime utcNow)` | 보이는 기간의 공지만 남긴 새 문서. UTC 가 아니면 `ArgumentException` |
| `byte[] ToUtf8Json()` | 결정적 UTF-8 JSON(BOM 없음, 언어 이름 순, 기본값 속성 생략) |

### sealed class NoticeItem

| 멤버 | 설명 |
|------|------|
| `NoticeItem(string id, IReadOnlyDictionary<string, NoticeContent> contents, string category = null, int priority = 0, DateTime? startsAt = null, DateTime? endsAt = null, IEnumerable<string> platforms = null, bool popup = false, string action = null)` | 규칙 위반은 `NoticeDocumentException`(시각은 UTC Kind, 끝 > 시작) |
| `const string DefaultCategory = "notice"` | |
| `Id`, `Category`, `Priority`, `StartsAt`, `EndsAt`, `Platforms`(비면 모두), `Popup`, `Action`, `Contents`(비교용 언어 → 내용) | |
| `bool IsActiveAt(DateTime utcNow)` | 시작 포함·끝 제외. UTC 아니면 `ArgumentException` |
| `bool IsFor(string platform)` | |
| `NoticeContent FindContent(string language, string fallbackLanguage = null)` | 태그 → 줄인 태그 → 대체 언어. 없으면 null. 잘못된 태그는 `ArgumentException` |

### sealed class NoticeContent

`NoticeContent(string title, string body = null, string linkUrl = null, string linkLabel = null)`: 빈 제목, http·https 절대 주소가 아닌 링크는 `NoticeDocumentException`. `Title`, `Body`, `LinkUrl`, `LinkLabel`.

### sealed class NoticeDocumentException : Exception

## 서버 (`Geuneda.Notice.Server`)

| 멤버 | 설명 |
|------|------|
| `IServiceCollection.AddGeunedaNotice(Action<NoticeServerOptions> configure = null)` → `NoticeServerBuilder` | `TimeProvider.System`(없을 때), 배포기 등록 |
| `NoticeServerBuilder.AddFileSource(string path)` | 파일 원천(싱글턴, 콘텐츠 루트 기준). 엄격하게 읽고 1초마다 내용 비교로 다시 읽음, 잘못된 파일은 오류 로그 후 이전 문서 |
| `NoticeServerBuilder.AddSource<T>(ServiceLifetime lifetime = Singleton)` | 게임 원천(앞의 파일 원천 등록을 지움) |
| `IEndpointRouteBuilder.MapGeunedaNotice(string pattern = "/notices")` → `RouteHandlerBuilder` | GET. 지금 보이는 공지만, ETag(SHA-256)·Cache-Control, `If-None-Match` 약한 비교 304. 등록 없음은 `InvalidOperationException`, 파일 원천은 여기서 읽어 잘못되면 예외 |
| `interface INoticeSource { Task<NoticeDocument> GetDocumentAsync(CancellationToken) }` | 요청마다 불림. 같은 문서면 같은 인스턴스. null 은 500 |
| `NoticeServerOptions.CacheControl` | 기본 `no-cache` |

## 테스트

- Unity EditMode `Geuneda.Notice.Tests.EditMode`(`SampleServerInteropTest` 는 명시 실행, `GEUNEDA_NOTICE_INTEROP_URL`).
- .NET `dotnet test "Server~/Geuneda.Notice.Server.slnx"`: `Geuneda.Notice.Document.Tests`(Unity 문서 테스트 링크, NUnit 3), `Geuneda.Notice.Server.Tests`(xUnit, Kestrel).
- 샘플 서버: `dotnet run --project "Server~/samples/Geuneda.Notice.SampleServer" --no-launch-profile -- --urls http://127.0.0.1:5599`.
