# Geuneda AppSetting API 레퍼런스

네임스페이스 `Geuneda.AppSetting`, 서버 `Geuneda.AppSetting.Server`. 결과는 core `Result`/`Result<T>`. 버전 0.2.0(리소스 매니페스트 추가).

## 서비스 (`Runtime/`)

### interface IAppSettingService / sealed class AppSettingService : IAppSettingService

| 멤버 | 설명 |
|------|------|
| `AppSettingService(AppSettingServiceOptions)` | 메인 스레드(`Application.version` 을 읽음). 필수 설정 누락, 문서 주소 형식 오류, 공개 키 없음·null·키 ID 겹침, 제한 시간 0 이하, 빈 버전·플랫폼은 `ArgumentException`(옵션 null 은 `ArgumentNullException`) |
| `AppSetting Current` | 이 실행에서 마지막으로 받아들인 설정. 처음 성공 전에는 null. 디스크에 두지 않음 |
| `event Action<AppSetting> Changed` | `Current` 가 새 설정으로 바뀔 때(처음 포함). 같은 판·같은 본문이면 오지 않음. 처리기 예외는 로그만. 문서 변경 알림이지 접속 판정 변경 알림이 아님(판정은 점검 시간 경계에서도 바뀜) |
| `UniTask<Result<AppSetting>> RefreshAsync(ct)` | 문서를 받아 검증하고 `Current` 를 바꿈. ETag 가 있으면 `If-None-Match`, 304 면 그대로. 낮은 판은 무시하고 지금 설정으로 성공. 동시 호출은 요청 하나를 함께 기다림(single-flight). `ct` 는 그 호출의 기다림만 멈춤(`Cancelled`), 이미 취소된 토큰이면 요청을 보내지 않음. 실패해도 `Current` 유지 |

### sealed class AppSettingServiceOptions

`IHttpClient HttpClient`(필수, 재시도 미들웨어 가능, 인증 미들웨어는 넣지 않음), `string DocumentUri`(필수, 절대 주소 또는 기본 주소 기준 상대 주소), `IList<AppSettingPublicKey> PublicKeys`(하나 이상, 키 ID 서로 다름), `string AppVersion`(null 이면 `Application.version`), `string Platform`(null 이면 `AppSettingPlatforms.Current`), `TimeSpan RequestTimeout`(기본 10초).

### sealed class AppSetting

| 멤버 | 설명 |
|------|------|
| `AppSettingDocument Document`, `long Revision` | 문서 전체와 판 |
| `string AppVersion`, `string Platform` | 노드·상태를 고를 때 쓴 값 |
| `string MatchedVersion` | 고른 노드 키(앱 버전 문자열이 정확히 같은 키, 없으면 `*`). 둘 다 없으면 null |
| `AppVersionSetting Version` | 고른 노드. 없으면 null |
| `AppPlatformStatus Status` | 이 플랫폼 상태. 노드·플랫폼이 없으면 `Closed` |
| `bool IsReview`, `MaintenanceNotice Maintenance` | 고른 노드의 값(공지는 null 일 수 있음) |
| `IReadOnlyList<string> NewerVersions`, `bool HasNewerVersion` | 이 앱보다 높은 공개 버전 키(숫자 버전 1~4 부분, `review` 아님, 이 플랫폼 `open`), 낮은 순. `*`·접미사 키 제외, 앱 버전을 숫자로 못 읽으면 비어 있음 |
| `AppAccess GetAccess(DateTime utcNow)` | 노드 없음 → `UpdateRequired`, `internal` → `Internal`, `open` → 점검 시간 안이면 `Maintenance` 아니면 `Open`, `closed` → 새 공개 버전 있으면 `UpdateRequired` 아니면 `Maintenance`. UTC 가 아니면 `ArgumentException` |
| `bool TryGetEndpoint(string name, out string address)` | 고른 노드의 서버 주소. 이름은 대소문자를 가림 |
| `Result<T> GetFeatures<T>(JsonSerializerSettings settings = null)` | 기능 플래그 JSON 을 게임 형식으로(호출마다 새로). 노드·플래그가 없으면 `{}`. 형식이 안 맞으면 `InvalidDocument` |
| `IReadOnlyDictionary<string, AppSettingResource> Resources` | 고른 노드의 리소스 매니페스트(카테고리 대소문자 구분 → 항목). 노드가 없으면 비어 있음. com.geuneda.resource 의 `ResourceEntry` 로 옮겨 받음 |

`AppAccess`: `Open`, `Internal`, `Maintenance`, `UpdateRequired`.

## 문서 모델 (`Runtime/Document/`, 서버와 공유)

| 타입 | 멤버 |
|------|------|
| `AppSettingDocument` | `const string DefaultVersionKey = "*"`, `long Revision`, `IReadOnlyDictionary<string, AppVersionSetting> Versions`(키 대소문자 구분) |
| `AppVersionSetting` | `Platforms`(이름 대소문자 무시 → `AppPlatformStatus`), `IsReview`, `Endpoints`(이름 → 주소), `Resources`(카테고리 → `AppSettingResource`, 없으면 비어 있음), `Maintenance`(null 가능), `FeaturesJson`(서명한 본문에 쓴 그대로의 JSON 객체 텍스트, 없으면 `{}`), `GetStatus(platform)`(없으면 `Closed`) |
| `MaintenanceNotice` | `StartAt`, `EndAt`(UTC, 끝 미포함), `DefaultLanguage`, `Messages`(언어 대소문자 무시), `IsActiveAt(utcNow)`(UTC 아니면 `ArgumentException`), `GetMessage(language)`(정확한 코드 → 기본 하위 태그 `ko-KR`→`ko` → 기본 언어, null·빈 값은 기본 언어) |
| `AppSettingResource` | `Version`, `Size`(바이트), `Sha256`(소문자 16진수 64자), `Url`(http·https 절대 주소). 문서 서명이 크기·해시를 보장 |
| `AppPlatformStatus` | `Closed` 0(없는 플랫폼, 모르는 상태 문자열 포함), `Open` 1, `Internal` 2. 문서에는 `open`·`internal`·`closed`(대소문자 무시) |
| `AppSettingPlatforms` | `Android` "android", `Ios` "ios", `WebGl` "webgl", `Standalone` "standalone"(에디터·데스크톱), `Current`(UNITY_ANDROID·UNITY_IOS·UNITY_WEBGL define, 그 밖 Standalone) |
| `AppSettingPublicKey(keyId, modulus, exponent)` | base64url(또는 base64) big-endian. `KeyId`, `KeySizeBits`, `Modulus`, `Exponent`, `MinimumKeySizeBits` 2048. 키 ID 빈 값, base64 아님, 2048 비트 미만, 짝수 modulus, 1 이하·짝수 exponent 는 `ArgumentException` |
| `AppSettingDocumentException` | `Code`(`AppSettingResultCodes`). 공유 코드가 던지고 클라이언트 서비스만 `Result` 로 바꿈 |

## 코드 (`AppSettingResultCodes`, 4000 블록)

| 코드 | 이름 | 뜻 |
|------|------|----|
| 4001 | `InvalidDocument` | 문서·본문이 규칙에 맞지 않음(JSON 오류, 필수 값, 날짜 등), 기능 플래그가 게임 형식과 다름 |
| 4002 | `InvalidSignature` | 믿는 키로 만든 맞는 서명이 없음 |
| 4003 | `UnsupportedFormat` | 봉투 `format` 이 `geuneda.appsetting.v1` 이 아님 |

연결 실패·제한 시간·취소는 core `ResultCodes.NetworkError`·`Timeout`·`Cancelled`, 2xx·304 가 아닌 응답(조건부 요청이 아닌데 온 304 포함)은 http `HttpResultCodes.HttpError`.

## 문서 형식

봉투: `{"format": "geuneda.appsetting.v1", "payload": "<본문 UTF-8 바이트 base64>", "signatures": [{"keyId", "signature"}]}`. 서명은 RSA PKCS#1 v1.5 SHA-256 이고 입력은 `"geuneda.appsetting.v1"`(ASCII) + `0x00` + 본문 바이트. 믿는 키 ID 의 서명 하나가 맞으면 통과(키 교체 때 두 키로 서명).

본문 규칙:

| 값 | 규칙 |
|----|------|
| `revision` | 1 이상 정수(필수). 배포마다 올림 |
| `versions` | 비어 있지 않은 객체(필수). 키는 앱 버전 문자열 또는 `*` |
| `platforms` | 이름 → `open`·`internal`·`closed`. 엄격 모드에서 필수, 관대 모드는 없으면 모두 닫힘 |
| `review` | bool, 기본 false |
| `endpoints` | 이름 → 비어 있지 않은 주소. 엄격 모드는 호스트 있는 절대 주소만 |
| `maintenance` | `startAt`·`endAt`(Z 나 오프셋 있는 ISO 8601, `endAt` > `startAt`), `defaultLanguage`(필수), `messages`(기본 언어 문구 필수) |
| `features` | JSON 객체 |
| `resources` | 카테고리 → `version`·`size`·`sha256`·`url`. 카테고리·버전은 `[a-z0-9._-]` 1~64자(소문자만, 끝의 점·Windows 장치 이름(`con` 등) 제외, `.`·`..` 제외, 캐시 파일 이름이 됨), `size` 0 이상 정수, `sha256` 16진수 64자(소문자로 맞춤), `url` 호스트 있는 http·https 절대 주소. 두 모드 모두 이 규칙을 적용(모르는 속성만 엄격 모드에서 거절) |

공통: 중복 속성, JSON 뒤 다른 내용, 잘못된 UTF-8 거절(앞 BOM 허용). JSON `null` 은 없는 값. 날짜 문자열을 자동 변환하지 않음. 관대(클라이언트)는 모르는 속성 무시·모르는 상태는 닫힘, 엄격(CLI·`Sign`)은 모르는 속성·상태, 호스트 없는 주소, 앞뒤 공백 버전 키 거절.

## 서버 (`Server~/src/Geuneda.AppSetting.Server/`)

| API | 설명 |
|-----|------|
| `AppSettingSigningKey.Generate(keyId, keySizeBits = 3072)` | 새 RSA 키. 2048 미만·빈 키 ID 는 `ArgumentException`. `IDisposable` |
| `AppSettingSigningKey.FromPem(keyId, pem)` | PKCS#8 `PRIVATE KEY` 또는 PKCS#1 `RSA PRIVATE KEY`. 공개 키만 든 PEM, 작은 키, 깨진 값은 `ArgumentException` |
| `KeyId`, `PublicKey`, `ExportPrivateKeyPem()` | 공개 키(`AppSettingPublicKey`), PKCS#8 PEM 내보내기 |
| `AppSettingSigner.Sign(byte[] payload, IEnumerable<AppSettingSigningKey>)` | 본문을 엄격하게 검사한 뒤 키마다 서명한 봉투(UTF-8 JSON). 본문 바이트는 그대로. 규칙 위반은 `AppSettingDocumentException`, 키 없음·null·ID 겹침은 `ArgumentException` |
| `AppSettingSigner.Verify(byte[] document, IEnumerable<AppSettingPublicKey>, bool strict = false)` | 서명과 본문 검증 → `AppSettingDocument` |
| `AppSettingSigner.PeekRevision(byte[] document)` | 서명 확인 없이 판만, 형식이 깨졌으면 null |
| `AppSettingResources.Describe(category, version, url, filePath)` | 파일의 크기·SHA-256 으로 `{"카테고리": {"version", "size", "sha256", "url"}}` JSON. 이름·주소는 본문 엄격 규칙으로 확인(위반은 `AppSettingDocumentException`, 파일 오류는 `IOException`) |
| `AppSettingPublicKeys.ToJson(keys)` / `FromJson(json)` / `ToCSharp(key)` | 공개 키 파일 `[{"keyId", "modulus", "exponent"}]`(형식 오류 `FormatException`, 키 오류·ID 겹침 `ArgumentException`), Unity 줄 `options.PublicKeys.Add(new AppSettingPublicKey(...));` |
| `IServiceCollection.AddGeunedaAppSetting(Action<AppSettingServerOptions>)` | 옵션 `DocumentPath`(필수, 상대 경로는 콘텐츠 루트 기준), `PublicKeys`(하나 이상, ID 서로 다름), `CacheControl`(기본 `no-cache`). `TimeProvider` 도 등록 |
| `IEndpointRouteBuilder.MapGeunedaAppSetting(pattern = "/appsetting")` → `IEndpointConventionBuilder` | 시작할 때 설정 검사와 문서 읽기·검증(실패면 `InvalidOperationException`). GET 에 ETag(문서 바이트 SHA-256)·Cache-Control, `If-None-Match`(약한 비교, 목록, `*`) 맞으면 304. 1초에 한 번까지 파일을 내용으로 비교해 다시 읽고, 검증 실패·낮은 판·파일 삭제면 지금 문서 유지(오류 로그 한 번) |

## CLI `geuneda-appsetting`

`dotnet run --project "Server~/src/Geuneda.AppSetting.Tool" -- <명령>`. 종료 코드 0 성공, 1 실패(문서·키·파일 오류), 2 사용법 오류.

| 명령 | 설명 |
|------|------|
| `keygen --key-id <id> --out <pem>` | RSA-3072 키를 권한 600 으로 씀(있으면 덮어쓰지 않고 실패). 공개 키 JSON 과 Unity 줄 출력 |
| `public-key --key <pem> --key-id <id>` | 공개 키 출력 다시 보기 |
| `sign --payload <json> --key <pem> --key-id <id> [--key ... --key-id ...] --out <json>` | 엄격 검사 → 서명 → 같은 폴더 임시 파일에 쓰고 이름 바꾸기. `--out` 의 판보다 낮으면 거절, 같으면 경고 |
| `resource --category <name> --version <v> --url <url> --file <file>` | 올릴 파일의 `resources` 항목 JSON(크기·SHA-256) 출력. 이름이 규칙에 맞지 않으면(경로 조작 등) 실패 |
| `verify --document <json> --public-keys <json> [--strict]` | 클라이언트와 같은 규칙(또는 엄격)으로 검증하고 버전별 요약(리소스 `카테고리@버전` 포함) 출력 |

샘플 서버: `dotnet run --project "Server~/samples/Geuneda.AppSetting.SampleServer" --no-launch-profile -- --urls http://127.0.0.1:5399`(시작할 때마다 새 키로 `appsetting.payload.json` 서명, 샘플 전용 `GET /sample/public-keys`·`POST /sample/publish`). Unity 상호 운용 테스트는 `GEUNEDA_APPSETTING_INTEROP_URL=http://127.0.0.1:5399`.
