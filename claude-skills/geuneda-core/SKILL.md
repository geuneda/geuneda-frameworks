---
name: geuneda-core
description: com.geuneda.core 패키지(네임스페이스 Geuneda.Core)로 코드를 작성하거나 수정할 때 사용하는 스킬. 모듈별 로거 ModuleLogger 로 로그를 남기거나, LogLevel 로 레벨을 켜고 끄거나, throw logger.Fatal(ex) 패턴을 쓰거나, Log.Sink 에 ILogSink 를 넣어 출력 대상을 바꾸거나, Geuneda 패키지에 Debug.Log 대신 로거를 들일 때, 실패를 Result/Result<T> 코드로 돌려주거나 ResultCodes·패키지별 결과 코드 범위를 정할 때, DEV/QA/PROD 빌드 환경(AppEnv, GEUNEDA_ENV_* define)으로 분기하거나 운영 빌드에서 코드를 뺄 때, SDK 콜백 등 다른 스레드의 작업을 MainThreadDispatcher 로 메인 스레드에 넘길 때, 설정 ScriptableObject 를 ConfigAssetLoader 로 읽거나 .user 개인 덮어쓰기·EnvValue 환경별 값을 쓸 때, AppIdentity 로 설치 ID·기기 ID 를 얻을 때, 토큰·비밀 값을 ISecureStore/PlatformSecureStore(iOS 키체인, Android 키스토어)에 보관할 때, Pcg32(PCG32) 결정론적 난수 생성기를 직접 쓰거나 서버에서 같은 난수 수열을 재현할 때, 그리고 기기 시계 변경에 영향받지 않고 기기가 잠든 동안에도 흐르는 경과 시간을 IMonotonicClock/MonotonicClock 단조 시계로 재거나 테스트용 가짜 시계를 만들 때 활성화한다.
---

# Geuneda Core

다른 Geuneda 패키지가 함께 쓰는 바닥 패키지다. 의존성이 없다. 현재 기능은 모듈별 로거, 결과 규약(`Result`), 빌드 환경(`AppEnv`), 메인 스레드 디스패처(`MainThreadDispatcher`), 설정 에셋(`ConfigAssetLoader`), 설치·기기 ID(`AppIdentity`), 보안 저장소(`ISecureStore`, `PlatformSecureStore`), 결정론적 난수(`Pcg32`), 단조 시계(`MonotonicClock`)다.

## 패키지 정보

- **네임스페이스 / 어셈블리**: `Geuneda.Core`
- **설치**: `https://github.com/geuneda/geuneda-core.git`
- **의존성**: 없음
- **최소 Unity 버전**: 2021.3
- **기여 가이드**: 패키지 루트의 `AGENTS.md`(static 허용 목록, 로거 불변식)

## 로거 핵심 API

전체 시그니처는 `references/api.md`.

- `ModuleLogger(string module)`: `Verbose`/`Debug`/`Info`/`Warning`/`Error(string)`/`Error(Exception, string)`/`Fatal<T>(T exception)`, `IsEnabled(LogLevel)`, `Enable`/`Disable`, `EnabledLevels`, `Module`.
- `LogLevel`(`[Flags] byte`): `Verbose`, `Debug`, `Info`, `Warning`, `Error`, `Fatal`, `All`, `None`. 기본 켜짐은 `ModuleLogger.DefaultLevels`(Info 이상).
- `Log.Sink`(`ILogSink`, 기본 `UnityConsoleSink`), `Log.ResetSink()`.
- `ILogSink.Write(in LogEntry)`, `LogEntry`(Level, Module, Message, Exception, Context, CallerMember, CallerFile, CallerLine).

## 결과 규약 핵심 API

- `Result`: `Ok()`, `Fail(int code, string message = null)`, `FromException(Exception)`, `IsSuccess`, `Code`, `Message`.
- `Result<T>`: 위와 같고 `Ok(T value)`, `Value`(실패면 `InvalidOperationException`), `TryGetValue(out T)`. `Result` 로 암시적 변환.
- `ResultCodes`: `Success` 0, `Unknown` 1, `Cancelled` 2, `Timeout` 3, `NetworkError` 4, `InProgress` 5, `FromException(Exception)`.
- 규칙: 실행 중 일어날 수 있는 실패(네트워크, 타임아웃, 취소, 서버 거절, 중복 실행)는 결과 코드, 오용(잘못된 인자·상태)은 즉시 예외.
- 코드 범위: 0 성공, 1~999 core 공용, 패키지별 1000 단위 블록(core `README.md` 표에 등록: 1000 http, 2000 realtime, 3000 account, 4000 appsetting, 5000 resource, 6000 servertime, 7000 iap, 8000 ads, 9000 consent, 10000 notice, 다음 빈 블록 11000), 100000~100999 실시간 RPC 서버 프레임워크(realtime `RpcStatusCodes`), 게임 101000 이상.

## 빌드 환경 핵심 API

- `AppEnv.Current`(`AppEnvironment.Dev` 1 / `QA` 2 / `Prod` 3), `AppEnv.IsDev`/`IsQA`/`IsProd`, `AppEnv.Name`(`dev`/`qa`/`prod`).
- 값은 컴파일 define 으로 정한다: `GEUNEDA_ENV_PROD`, `GEUNEDA_ENV_QA`, `GEUNEDA_ENV_DEV` 중 하나(Scripting Define Symbols 또는 Build Profile). 없으면 에디터·개발 빌드는 Dev, 릴리스 빌드는 Prod. 둘 이상이면 컴파일 오류.
- 운영 빌드에서 빠져야 하는 코드는 `#if !GEUNEDA_ENV_PROD && (UNITY_EDITOR || DEVELOPMENT_BUILD || GEUNEDA_ENV_DEV || GEUNEDA_ENV_QA)` 로 감싼다. `AppEnv.IsProd` 로 분기한 코드는 빌드에 남는다.

## 메인 스레드 디스패처 핵심 API

- `MainThreadDispatcher.Post(Action)`: 어느 스레드에서든 넣고, 메인 스레드의 다음 처리(PlayerLoop Update 의 `ScriptRunBehaviourUpdate` 바로 앞)에서 넣은 순서대로 실행. 프레임당 개수 제한 없음.
- `MainThreadDispatcher.IsMainThread`: 플레이 세션 시작 때 기록한 메인 스레드와 비교. 한 번도 플레이하지 않은 편집 모드에서는 false.

## 설정 에셋 핵심 API

- `new ConfigAssetLoader(Func<string, Object> fallbackLoad = null)`, `Load<T>()`(없거나 타입이 다르면 `InvalidOperationException`), `TryLoad<T>(out T)`, `static GetPath(Type)`, `const UserSuffix = ".user"`.
- `[ConfigAssetPath("폴더/이름")]`: Resources 기준 경로. 없으면 타입 이름.
- 읽는 순서: 에디터만 `경로.user`(`Editor/Resources` 에 둠) → `Resources/경로` → 대체 로더.
- `EnvValue<T>`: `[Serializable] struct`, `new EnvValue<T>(dev, qa, prod)`, `Value`(AppEnv.Current), `Get(AppEnvironment)`.

## 설치·기기 ID 핵심 API

- `IAppIdentity`(`InstallId`, `DeviceId`), 구현 `new AppIdentity()`(메인 스레드). `InstallId` 는 PlayerPrefs GUID(앱 데이터가 지워지면 새로, Android 자동 백업·iOS 백업 복원이면 이전 값), `DeviceId` 는 iOS 키체인 GUID(재설치해도 유지), Android 는 `SystemInfo.deviceUniqueIdentifier`. 부트스트랩에서 `MainInstaller.Bind<IAppIdentity>(new AppIdentity())`(MainInstaller 는 인터페이스만 받음).

## 보안 저장소 핵심 API

- `ISecureStore`: `SecureReadResult TryRead(key, out value)`(Found/NotFound/Failed), `bool TryWrite(key, value)`(추가 또는 덮어쓰기), `bool TryDelete(key)`(없어도 true). 구현 `new PlatformSecureStore()`, 부트스트랩에서 `MainInstaller.Bind<ISecureStore>(...)`. 메인 스레드.
- 플랫폼: iOS 키체인(재설치해도 남음), Android API 23 이상 키스토어 AES-256-GCM + SharedPreferences(재설치하면 사라짐, 복호화 못 하는 값은 지우고 NotFound), 에디터·그 밖·Android API 22 이하는 PlayerPrefs 평문(`geuneda.secure.` 접두사).

## 결정론적 난수 핵심 API

- `Pcg32`(가변 struct, PCG32 XSH-RR): `new Pcg32(ulong seed, ulong stream)`, `uint NextUInt()`, `uint NextUInt(uint bound)`([0, bound)), `int NextInt(min, max)`([min, max)), `int NextIntInclusive(min, max)`([min, max]), `void Advance(ulong delta)`(O(log n), 2^64 를 법으로 해 뒤로도 감), `ulong Position`(쓴 32비트 출력 수).
- 게임 로직은 보통 services 의 `IRngService`(이 생성기를 씀)를 쓴다. `Pcg32` 는 상태를 직접 다루거나 서버(.NET)가 `Runtime/Random/Pcg32.cs` 를 링크해 같은 수열을 재현할 때 쓴다.

## 단조 시계 핵심 API

- `IMonotonicClock`: `TimeSpan Elapsed`(기준점 이후 흐른 시간, 어느 스레드에서 읽어도 됨). 기기 시계(`DateTime.UtcNow`)를 바꿔도 영향받지 않고 줄어들지 않는다.
- `new MonotonicClock()`: 플랫폼 기본 구현. Android `clock_gettime(CLOCK_BOOTTIME)`, macOS 에디터·플레이어 `clock_gettime(CLOCK_MONOTONIC)`(libc), iOS 플러그인 `GeunedaMonotonicClock.mm` 의 `clock_gettime_nsec_np(CLOCK_MONOTONIC)` 로 기기가 잠든 동안에도 흐른다. 그 밖(Windows, Linux, WebGL)과 네이티브 호출 실패는 `Stopwatch`. `bool IncludesSleep` 은 네이티브 시계를 쓰는지(`Stopwatch` 면 false).
- services 의 `TimeService` 가 이 시계로 현재 시각을 진행하고, servertime 의 `ServerTimeSync` 가 같은 시계로 왕복 지연을 보정한다.

## 사용 패턴

```csharp
using System;
using Geuneda.Core;

public sealed class PoolService
{
    private static readonly ModuleLogger Logger = new ModuleLogger("Geuneda.Services.Pool");

    public void Spawn(string key)
    {
        Logger.Debug($"Spawn {key}");     // 기본 꺼짐, 릴리스 빌드에서는 호출 자체가 사라짐

        if (string.IsNullOrEmpty(key))
        {
            throw Logger.Fatal(new ArgumentException("Key is empty", nameof(key)));
        }
    }
}

// 출력 대상 교체(파일, 원격 수집 등). AfterAssembliesLoaded 이후에 한다
Log.Sink = new MyRemoteSink();
```

```csharp
public async UniTask<Result<Profile>> LoadAsync(string userId, CancellationToken token)
{
    if (string.IsNullOrEmpty(userId))
    {
        throw new ArgumentException("User id is empty", nameof(userId));   // 오용: 즉시 예외
    }

    // 정상 실패에 해당하는 예외만 타입별로 잡는다. 오용·버그 예외(ObjectDisposedException 등)는 전파한다
    try
    {
        return Result<Profile>.Ok(await FetchAsync(userId, token));
    }
    catch (OperationCanceledException)
    {
        return Result<Profile>.Fail(ResultCodes.Cancelled);                // 정상 취소: 오류 로그 없음
    }
    catch (TimeoutException exception)
    {
        Logger.Warning($"Profile request timed out: {exception.Message}");
        return Result<Profile>.FromException(exception);                   // Timeout
    }
    catch (HttpRequestException exception)
    {
        Logger.Warning($"Profile request failed: {exception.Message}");
        return Result<Profile>.Fail(ResultCodes.NetworkError, exception.Message);
    }
}
```

## 함정

- `Verbose`/`Debug` 는 `[Conditional]` 이라 에디터, `DEVELOPMENT_BUILD`, `GEUNEDA_LOG_DEBUG` 심볼이 없으면 호출과 인자 계산이 통째로 제거된다. 부수 효과가 있는 식을 인자로 넣지 않는다.
- 클래스 이름은 `ModuleLogger` 다. `UnityEngine.Logger` 와 겹치지 않게 지은 이름이다.
- `throw logger.Fatal(ex)` 는 로그를 남기고 같은 예외를 돌려준다. 아무도 잡지 않으면 Unity 가 한 번 더 콘솔에 쓴다.
- 출력 대상이 예외를 던져도 호출자에게 전파되지 않고 `Debug.LogException` 으로 남는다. 출력 대상은 여러 스레드에서 불릴 수 있다.
- `Log` 는 플레이 세션 시작(`SubsystemRegistration`)에 출력 대상과 살아 있는 모든 로거의 레벨을 기본값으로 되돌린다. `SubsystemRegistration` 에서 출력 대상이나 레벨을 바꾸면 지워질 수 있다.
- 레벨 읽기·변경(`EnabledLevels`, `Enable`, `Disable`)은 스레드 안전하다.
- static 가변 상태는 로거, 메인 스레드 디스패처, gamedata 의 보안 값 변조 알림(`SecureValueMonitor`), services 의 `MainInstaller`(바인딩과 `BindingChanged` 처리기)만 허용한다(D2). 다른 서비스는 인터페이스 + `MainInstaller` 바인딩으로 만든다.
- `default(Result)` 와 `default(Result<T>)` 는 성공이 아니라 `Unknown` 실패다.
- `Fail` 에 0 이하 코드를 넣으면 `ArgumentOutOfRangeException` 이다. 실패를 다른 `T` 의 결과로 넘길 때는 `Result<U>.Fail(result.Code, result.Message)`.
- `Result` 를 돌려주는 API 는 취소도 예외 대신 `Cancelled` 코드로 돌려준다.
- `FromException` 은 코드로 바꾸기만 한다. `catch (Exception)` 으로 모든 예외를 넘기면 오용·버그가 `Unknown` 결과로 숨겨진다. 정상 실패 예외만 타입별로 잡는다.
- `ResultCodes.FromException` 은 네트워크 예외를 분류하지 않는다(`Unknown`). 통신 패키지가 자기 예외를 `NetworkError` 로 바꾼다.
- 정상 실패는 Error 로 남기지 않는다. 취소는 로그 없음 또는 Debug, 네트워크·타임아웃은 Warning.
- `Message` 는 로그용이다. 사용자 문구는 `Code` 로 찾는다.
- define 없는 릴리스 빌드는 Prod 다. QA 서버용 릴리스 빌드에 `GEUNEDA_ENV_QA` 를 빠뜨리면 운영 서버에 붙는다.
- `#if !GEUNEDA_ENV_PROD` 만 쓰면 define 없는 릴리스 빌드(Prod)에서 코드가 남고, `UNITY_EDITOR || DEVELOPMENT_BUILD` 만 쓰면 PROD 를 넣은 개발 빌드(Prod)에서 남는다. 두 조건을 합친 위 조건을 쓴다.
- Addressables 콘텐츠 빌드는 개발 빌드 옵션·추가 define 없이 플레이어 스크립트를 컴파일한다. 직렬화 필드를 환경 define 으로 바꾸지 않는다. define 없는 릴리스 컴파일을 `#error` 로 막으면 콘텐츠 빌드가 깨진다.
- 프로젝트 Scripting Define Symbols 의 환경 define 은 에디터에도 적용된다(에디터에서 운영 환경을 시험할 때만 `GEUNEDA_ENV_PROD` 를 넣는다). 빌드 스크립트의 `extraScriptingDefines` 는 그 플레이어 컴파일에만 적용된다.
- `MainThreadDispatcher.Post` 는 메인 스레드에서 불러도 바로 실행하지 않는다. 처리 중에 넣은 작업은 다음 프레임에 실행된다. 작업 예외는 Error 로그로 남고 나머지는 계속 실행된다.
- `MainThreadDispatcher` 는 플레이 중에 쓰도록 만든 것이다(편집 모드 실행은 보장하지 않음). 플레이 세션 시작(`SubsystemRegistration`)에 남은 작업을 버리므로 `AfterAssembliesLoaded` 이후에 `Post` 한다.
- `ConfigAssetLoader` 는 캐시가 없다. 부트스트랩에서 한 번 읽어 `MainInstaller` 에 바인딩한다. 정적 캐시를 만들지 않는다(D2).
- `.user` 에셋(대소문자 무시)이 Editor 폴더 밖이나 StreamingAssets 안에 있으면 플레이어 빌드가 `BuildFailedException` 으로 실패한다. 개인 덮어쓰기는 `Editor/Resources` 에 두고 gitignore(`*.user.asset`, `*.user.asset.meta`) 한다.
- `EnvValue<T>` 의 dev/qa/prod 값은 모두 빌드에 들어간다. 비밀 값은 넣지 않는다.
- `AppIdentity` 의 ID 는 만들 때 정해진다. iOS 에서 키체인을 못 읽으면 그 실행만 identifierForVendor 를 쓰고(덮어쓰지 않음) Warning 을 남긴다. 다른 회사 앱 데이터와 연결하는 추적에 쓰지 않는다.
- `ISecureStore.TryRead` 가 `Failed` 면 값이 있는지 모른다. 그 실행에서는 그 키에 쓰거나 지우지 않는다(기존 값 손실). 빈 키, null 값, NUL 문자를 담은 키·값은 예외다.
- iOS 키체인 값은 앱을 지워도 남는다. 재설치 때 지워야 하는 값은 사용하는 쪽이 처리한다. Android 값은 재설치·키 분실로 사라질 수 있으니 서버에서 다시 받을 수 있는 값만 둔다.
- Android 보안 저장소는 Java 플러그인을 JNI 이름으로 부른다. R8 keep 규칙은 core 에디터 훅이 넣으므로 따로 추가하지 않는다. Java 클래스 이름을 바꾸면 `AndroidProguardRules.Rule` 도 바꾼다.
- `AppEnv.IsProd` 등은 의도적으로 `const` 가 아니다(소비 코드의 CS0162 경고 방지). 빌드에서 확실히 빼야 하면 `#if` 를 쓴다.
- `Pcg32` 는 가변 struct 다. `readonly` 필드에 두거나 프로퍼티로 꺼내 부르면 복사본이 진행해 원래 생성기는 그대로다. 복사는 미리 보기로 쓴다. `default(Pcg32)` 는 `InvalidOperationException`.
- `Pcg32` 의 범위 함수는 거절 샘플링으로 출력을 하나 더 쓸 수 있어 `Position` 은 호출 수가 아니다. 저장·재현은 시드·스트림·`Position` 세 값으로 한다.
- `IMonotonicClock.Elapsed` 의 기준점은 정해져 있지 않다(보통 기기 부팅). 값 자체를 시각으로 쓰지 말고 두 값의 차이로 경과 시간을 잰다. 같은 기기에서는 인스턴스가 달라도 같은 시계라 값끼리 비교할 수 있다.
- `Stopwatch` 대체(`IncludesSleep` false)에서 잠든 동안 흐르는지는 플랫폼에 따른다. 네이티브 호출 실패는 생성할 때 한 번만 확인한다.
- 테스트에서는 `Elapsed` 를 직접 정하는 가짜 `IMonotonicClock` 을 만들어 넘긴다(`TimeService(IMonotonicClock)`, `ServerTimeSync(..., clock)`).
