---
name: geuneda-core
description: com.geuneda.core 패키지(네임스페이스 Geuneda.Core)로 코드를 작성하거나 수정할 때 사용하는 스킬. 모듈별 로거 ModuleLogger 로 로그를 남기거나, LogLevel 로 레벨을 켜고 끄거나, throw logger.Fatal(ex) 패턴을 쓰거나, Log.Sink 에 ILogSink 를 넣어 출력 대상을 바꾸거나, Geuneda 패키지에 Debug.Log 대신 로거를 들일 때 활성화한다.
---

# Geuneda Core

다른 Geuneda 패키지가 함께 쓰는 바닥 패키지다. 의존성이 없다. 현재 기능은 모듈별 로거다.

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

## 함정

- `Verbose`/`Debug` 는 `[Conditional]` 이라 에디터, `DEVELOPMENT_BUILD`, `GEUNEDA_LOG_DEBUG` 심볼이 없으면 호출과 인자 계산이 통째로 제거된다. 부수 효과가 있는 식을 인자로 넣지 않는다.
- 클래스 이름은 `ModuleLogger` 다. `UnityEngine.Logger` 와 겹치지 않게 지은 이름이다.
- `throw logger.Fatal(ex)` 는 로그를 남기고 같은 예외를 돌려준다. 아무도 잡지 않으면 Unity 가 한 번 더 콘솔에 쓴다.
- 출력 대상이 예외를 던져도 호출자에게 전파되지 않고 `Debug.LogException` 으로 남는다. 출력 대상은 여러 스레드에서 불릴 수 있다.
- `Log` 는 플레이 세션 시작(`SubsystemRegistration`)에 출력 대상과 살아 있는 모든 로거의 레벨을 기본값으로 되돌린다. `SubsystemRegistration` 에서 출력 대상이나 레벨을 바꾸면 지워질 수 있다.
- 레벨 읽기·변경(`EnabledLevels`, `Enable`, `Disable`)은 스레드 안전하다.
- static 가변 상태는 로거와 메인 스레드 디스패처만 허용한다(D2). 다른 서비스는 인터페이스 + `MainInstaller` 바인딩으로 만든다.
