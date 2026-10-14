---
name: geuneda-appsetting
description: com.geuneda.appsetting 패키지(네임스페이스 Geuneda.AppSetting, 서버 Geuneda.AppSetting.Server)로 원격 앱 설정 코드를 작성하거나 수정할 때 사용하는 스킬. IAppSettingService·AppSettingService·AppSettingServiceOptions 로 서명된 설정 문서를 받아 부팅 관문(점검·강제 업데이트)을 판정하거나, AppSetting.GetAccess·AppAccess·AppPlatformStatus·AppSettingPlatforms·MaintenanceNotice 로 접속 판정·점검 공지·서버 주소(TryGetEndpoint)·기능 플래그(GetFeatures)를 읽거나, AppSettingPublicKey 로 공개 키를 넣거나, AppSettingResultCodes(4000 블록)·AppSettingDocumentException 을 처리하거나, 설정 문서 본문(revision, versions, '*' 노드, platforms, review, endpoints, maintenance, features)을 쓰거나, 서버 쪽 AppSettingSigningKey·AppSettingSigner·AppSettingPublicKeys·AddGeunedaAppSetting·MapGeunedaAppSetting 과 서명 CLI geuneda-appsetting(keygen, public-key, sign, verify)으로 문서를 서명·배포할 때 활성화한다.
---

# Geuneda AppSetting

원격 앱 설정이다. 서명된 설정 문서를 받아 검증하고, 이 앱 버전·플랫폼의 상태, 점검 공지, 서버 주소, 기능 플래그로 접속 판정(열림·내부·점검·업데이트 필요)을 돌려준다. 문서를 서명하는 CLI 와 ASP.NET Core 배포 헬퍼(`Server~/`)를 함께 둔다. 결과는 core 결과 규약(`Result`)을 따른다.

## 패키지 정보

- **네임스페이스 / 어셈블리**: `Geuneda.AppSetting`
- **설치**: `https://github.com/geuneda/geuneda-appsetting.git` (core, http, UniTask git URL 도 함께)
- **의존성**: `com.geuneda.core` 0.2.0(Result, ModuleLogger), `com.geuneda.http` 0.1.0, `com.cysharp.unitask` 2.5.10, `com.unity.nuget.newtonsoft-json` 3.2.1
- **최소 Unity 버전**: 2021.3
- **서버**: `Server~/` 의 .NET 10 솔루션 `Geuneda.AppSetting.Server.slnx`(서명·배포 라이브러리, CLI, 샘플 서버, xUnit). 문서 해석 코드 `Runtime/Document/` 를 링크해 클라이언트와 같은 코드로 컴파일
- **기여 가이드**: 패키지 루트의 `AGENTS.md`
- **출처**: Lucky Defense Perbase AppSetting(로드맵 3-5). 앱 버전별 상태 맵, 닫힘이면 새 공개 버전 유무로 업데이트·점검을 가르는 판정, 조건부 요청, 서명 검증, 메모리에만 두기를 따랐다

## 핵심 API

전체 시그니처는 `references/api.md`.

- `new AppSettingService(new AppSettingServiceOptions { HttpClient, DocumentUri, PublicKeys, AppVersion?, Platform?, RequestTimeout })` → `IAppSettingService`. `MainInstaller.Bind<IAppSettingService>`.
- `RefreshAsync(ct)` → `Result<AppSetting>`. `Current`(이 실행에서 마지막으로 받아들인 설정, 처음엔 null), 이벤트 `Changed(AppSetting)`.
- `AppSetting`: `GetAccess(utcNow)` → `AppAccess`(`Open`, `Internal`, `Maintenance`, `UpdateRequired`), `Status`(`AppPlatformStatus`), `MatchedVersion`(앱 버전 또는 `*`, 없으면 null), `Version`(`AppVersionSetting`), `Maintenance`(`MaintenanceNotice`), `NewerVersions`/`HasNewerVersion`, `IsReview`, `Revision`, `TryGetEndpoint(name, out address)`, `GetFeatures<T>()` → `Result<T>`.
- `MaintenanceNotice`: `StartAt`, `EndAt`(UTC), `DefaultLanguage`, `Messages`, `IsActiveAt(utcNow)`, `GetMessage(language)`(정확한 코드 → 기본 하위 태그 → 기본 언어).
- `AppSettingPublicKey(keyId, modulus, exponent)`: base64url modulus·exponent, 2048 비트 이상. CLI 가 생성자 호출 줄을 출력한다.
- `AppSettingPlatforms`: `Android`, `Ios`, `Standalone`(에디터·데스크톱), `WebGl`, `Current`(빌드 대상 define 기준).
- `AppSettingResultCodes`: `InvalidDocument` 4001, `InvalidSignature` 4002, `UnsupportedFormat` 4003.
- 서버: `AppSettingSigningKey.Generate(keyId)`/`FromPem`, `AppSettingSigner.Sign(payload, keys)`/`Verify(document, keys, strict)`/`PeekRevision`, `AppSettingPublicKeys.FromJson`/`ToJson`/`ToCSharp`, `AddGeunedaAppSetting(o => { o.DocumentPath; o.PublicKeys })`, `MapGeunedaAppSetting("/appsetting")`.

## 사용 패턴

```csharp
var options = new AppSettingServiceOptions
{
    // GET 이라 재시도해도 된다. 인증 토큰 미들웨어는 넣지 않는다(로그인 전에 받는 문서)
    HttpClient = new HttpClientBuilder().AddMiddleware(new RetryMiddleware()).Build(),
    DocumentUri = new EnvValue<string>(devUrl, qaUrl, prodUrl).Value
};
options.PublicKeys.Add(new AppSettingPublicKey("2026-10", "<modulus>", "AQAB"));   // CLI 출력 줄
var appSetting = new AppSettingService(options);
MainInstaller.Bind<IAppSettingService>(appSetting);

// 부팅 관문
var result = await appSetting.RefreshAsync(ct);
if (!result.IsSuccess) { ShowRetry(result.Code); return; }   // NetworkError·Timeout·HttpError 는 재시도, 4001·4002 는 운영 사고

var setting = result.Value;
switch (setting.GetAccess(DateTime.UtcNow))   // 서버 시각이 있으면 그것을 넘긴다
{
    case AppAccess.UpdateRequired: OpenStore(); return;
    case AppAccess.Maintenance: ShowMaintenance(setting.Maintenance?.GetMessage("ko")); return;   // 공지가 없을 수 있다
}

if (setting.HasNewerVersion && setting.GetFeatures<MyFeatures>().TryGetValue(out var features) && features.SoftUpdate)
{
    // 선택 업데이트 안내
}
setting.TryGetEndpoint("game", out var gameUrl);
// 이어서 로그인(com.geuneda.account)
```

판정 규칙:

| 노드 | 이 플랫폼 상태 | `GetAccess` |
|------|---------------|-------------|
| 없음(`*` 도 없음) | - | `UpdateRequired` |
| 있음 | `internal` | `Internal`(점검 공지와 관계없이 로그인으로, 테스터 여부는 게임 서버) |
| 있음 | `open` | 점검 시간(`startAt` 이상 `endAt` 미만) 안이면 `Maintenance`, 아니면 `Open` |
| 있음 | `closed`(또는 모르는 상태 문자열) | 더 높은 공개 버전이 있으면 `UpdateRequired`, 없으면 `Maintenance` |

더 높은 공개 버전: 숫자 버전(1~4 부분)으로 읽히고 이 앱보다 높으며, `review` 가 아니고 이 플랫폼이 `open` 인 키. `*`·접미사 키(`1.2.0-beta`)는 빼고, 이 앱 버전을 숫자로 못 읽으면 비어 있다.

설정 본문(서명 전 JSON):

```json
{
  "revision": 12,
  "versions": {
    "1.2.0": {
      "platforms": { "android": "open", "ios": "open" },
      "review": false,
      "endpoints": { "game": "https://game.example.com/", "realtime": "wss://rt.example.com/rpc" },
      "maintenance": { "startAt": "2026-10-20T02:00:00Z", "endAt": "2026-10-20T04:00:00Z",
                       "defaultLanguage": "en", "messages": { "en": "Maintenance", "ko": "정기 점검" } },
      "features": { "softUpdate": true }
    },
    "*": { "platforms": { "android": "closed", "ios": "closed" } }
  }
}
```

서명과 배포:

```sh
# CLI: dotnet run --project "Server~/src/Geuneda.AppSetting.Tool" -- <명령>
geuneda-appsetting keygen --key-id 2026-10 --out appsetting-2026-10.pem          # RSA-3072, 권한 600, 덮어쓰지 않음
geuneda-appsetting sign --payload payload.json --key appsetting-2026-10.pem --key-id 2026-10 --out appsetting.json
geuneda-appsetting verify --document appsetting.json --public-keys public-keys.json [--strict]
```

```csharp
builder.Services.AddGeunedaAppSetting(o =>
{
    o.DocumentPath = "appsetting.json";
    foreach (var key in AppSettingPublicKeys.FromJson(File.ReadAllText("public-keys.json"))) o.PublicKeys.Add(key);
});
app.MapGeunedaAppSetting("/appsetting");   // ETag, If-None-Match 면 304, 1초마다 내용 비교로 다시 읽기
```

정적 호스팅(CDN·스토리지)에 서명한 파일을 그대로 올려도 된다(캐시는 `no-cache` 나 짧은 `max-age`).

## 함정

- **디스크에 저장하지 않는다(설계)**. 부팅 관문을 지난 실행의 사본으로 지나지 않게 하려는 것이다. 갱신이 실패해도 `Current` 는 이 실행에서 받은 값 그대로이고, 그 값으로 계속할지는 게임이 정한다. 저장본 폴백을 넣지 않는다.
- 노드는 앱 버전 **문자열이 정확히 같은** 키만 고른다(`1.0` 과 `1.0.0` 은 다름). 키는 `Application.version` 과 같게 쓰고, 개발 환경 문서는 `*` 노드로 둘 수 있다.
- `GetAccess`·`IsActiveAt` 은 UTC(`DateTimeKind.Utc`)만 받는다. 아니면 `ArgumentException`.
- 판정은 클라이언트 안내용이다. 점검·지원 버전은 게임 서버도 로그인에서 막는다(시계를 바꾸거나 클라이언트를 고친 사용자).
- 기능 플래그 형식은 게임이 정하고 `GetFeatures<T>` 는 호출마다 새로 읽는다. IL2CPP 코드 제거에 대비해 형식에 `[Preserve]` 를 붙인다. 형식이 안 맞으면 `InvalidDocument`.
- 이 실행에서 받아들인 판보다 낮은 판(오래된 CDN 사본)은 무시하고 지금 설정으로 성공한다. 배포할 때마다 `revision` 을 올린다(CLI 는 `--out` 의 판보다 낮으면 거절, 같으면 경고).
- 동시에 `RefreshAsync` 를 부르면 요청 하나를 함께 기다린다. 호출자 토큰은 그 호출의 기다림만 멈추고 요청은 제한 시간(기본 10초)까지 계속된다.
- 서명은 RSA PKCS#1 v1.5 SHA-256 이다. Unity(Mono)는 ECDSA·RSA-PSS·Ed25519·SPKI 공개 키 가져오기를 지원하지 않고, `RSA.Create(2048)` 은 1024 비트 키를 만든다(테스트 키는 `new RSACryptoServiceProvider(bits)`). 공개 키는 modulus·exponent 로 넣는다.
- 서명을 건너뛰는 옵션은 없다. 개발 환경도 개발용 키로 서명한다. 개인 키는 저장소에 넣지 말고 비밀 관리 도구·CI 비밀 값에 둔다. 배포 서버에는 공개 키만 둔다.
- 키 교체: 새 키를 앱 `PublicKeys` 에 더해 배포하고 그동안 문서를 두 키로 서명한다(`--key`·`--key-id` 두 쌍). 새 키를 넣은 버전만 남으면 옛 키를 뺀다.
- 클라이언트는 관대하다(모르는 속성 무시, 모르는 상태 문자열은 닫힘). 서명 CLI·`AppSettingSigner.Sign` 은 엄격하다(모르는 속성·상태, 호스트 없는 서버 주소, 앞뒤 공백 버전 키 거절). 서명 형식(`geuneda.appsetting.v1`, 서명 입력)을 바꾸려면 새 형식 이름과 새 문서 주소를 쓴다.
- 문서 오류는 공유 코드가 `AppSettingDocumentException`(코드 포함)으로 던지고, 클라이언트 서비스만 이를 `Result` 로 바꾼다. 서버·CLI 는 그대로 던진다.
- 본문은 표준 JSON 만 받는다(주석, 작은따옴표, 따옴표 없는 이름, 뒤 쉼표, `NaN`·`Infinity`, `1e400` 처럼 double 범위 밖 숫자 거절). `features` 는 서명한 원문 그대로 게임 형식으로 읽으므로 작은·큰 double 과 정밀한 decimal 이 그대로 남는다. 기능 플래그를 JToken 에서 다시 직렬화하지 않는다.
- 같은 `--out` 에 동시에 서명하면 `.<파일>.lock`(flock)으로 차례를 기다리고 잠금 안에서 기존 판을 다시 읽어 비교한다. 잠금 파일은 남고 배포하지 않는다. 여러 기기의 CI 는 발행을 한 줄로 세운다.
- 공개 키 파일은 `AppSettingPublicKeys.FromJson` 으로 읽는다(날짜 모양 키 ID 를 바꾸지 않음). 직접 `JArray.Parse` 하면 Newtonsoft 날짜 변환으로 키 ID 가 바뀐다.
- 메인 스레드에서 쓴다. `Changed` 도 메인 스레드에서 오고 처리기 예외는 로그만 남긴다.
- `Changed` 는 문서 변경 알림이지 접속 판정 변경 알림이 아니다. 같은 문서여도 `GetAccess(utcNow)` 는 예약 점검의 시작·끝에서 바뀐다. 판정을 `Changed` 처리기에만 두지 말고, 성공한 `RefreshAsync` 마다(304 포함) 그리고 오래 머무는 화면에서는 `Maintenance.StartAt`·`EndAt` 에 맞춰 다시 판정한다.
