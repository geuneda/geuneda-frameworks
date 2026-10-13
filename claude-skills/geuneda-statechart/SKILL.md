---
name: geuneda-statechart
description: com.geuneda.statechart 패키지(네임스페이스 Geuneda.StatechartMachine)로 계층적 상태 머신(Statechart/HFSM)을 만들거나 고칠 때 사용한다. 게임 AI, UI 흐름, 게임 루프 같은 로직을 Statechart, IStateFactory, StatechartEvent로 구성하거나, Nest/Split/Choice/Wait/TaskWait/Leave 상태와 전이를 설정하거나, 기존 Statechart 코드의 전이 오류나 검증 예외를 디버깅할 때 이 스킬을 쓴다.
---

# Geuneda Statechart

코드로 정의하는 계층적 상태 머신. 상태 구성은 `Statechart` 생성자의 setup 콜백에서만 할 수 있고, 런타임에는 `Run`/`Pause`/`Reset`/`Trigger` 로만 조작한다.

- 패키지: `com.geuneda.statechart` (`https://github.com/geuneda/geuneda-statechart.git`)
- 네임스페이스: `using Geuneda.StatechartMachine;` (`Geuneda.Statechart` 가 아니다. 어셈블리 이름만 `Geuneda.Statechart`)
- 의존성: `com.cysharp.unitask` 2.5.10, Unity 2022.3 이상
- 전체 공개 API: [references/api.md](references/api.md)

## 핵심 API

```csharp
// 생성 + 제어
IStatechart chart = new Statechart(factory => { /* 상태와 전이 정의 */ });
chart.Run();        // 시작 또는 재개
chart.Trigger(evt); // 이벤트 처리 (일시정지 중이면 버려짐)
chart.Pause();
chart.Reset();      // 현재 위치를 Initial 로 되돌림. OnExit 호출 없음, Run/Pause 상태 유지
chart.LogsEnabled = true;

// 이벤트: 인스턴스마다 고유 Id, 동등성은 Id 로 비교. 같은 인스턴스를 재사용해야 한다
IStatechartEvent evt = new StatechartEvent("Attack");
```

| 팩토리 | 반환 | 가능한 구성 |
|---|---|---|
| `Initial(name)` | `IInitialState` | `Transition()`, `OnExit` |
| `Final(name)` | `IFinalState` | `OnEnter` |
| `State(name)` | `ISimpleState` | `OnEnter`, `OnExit`, `Event(e)` |
| `Transition(name)` | `ITransitionState` | `OnEnter`, `OnExit`, `Transition()` |
| `Choice(name)` | `IChoiceState` | `OnEnter`, `OnExit`, `Transition()` -> `ITransitionCondition` |
| `Nest(name)` | `INestState` | `OnEnter`, `OnExit`, `Event(e)`, `Nest(...)` |
| `Split(name)` | `ISplitState` | `OnEnter`, `OnExit`, `Event(e)`, `Split(...)` |
| `Wait(name)` | `IWaitState` | `OnEnter`, `OnExit`, `Event(e)`, `WaitingFor(Action<IWaitActivity>)` |
| `TaskWait(name)` | `ITaskWaitState` | `OnEnter`, `OnExit`, `WaitingFor(Func<Task>)`, `WaitingFor(Func<UniTask>)`, `WaitingFor(Func<CancellationToken, Task>)`, `WaitingFor(Func<CancellationToken, UniTask>)`, `Failed()` |
| `Leave(name)` | `ILeaveState` | `OnEnter`, `Transition()` |

`Transition()`, `Event()`, `WaitingFor()`, `Nest()`, `Split()` 는 모두 `ITransition` 을 돌려준다. `ITransition.OnTransition(Action)` 은 체이닝 가능하고 `Target(IState)` 는 `void` 라 체인의 마지막에 둔다. `ITransitionCondition.Condition(Func<bool>)` 은 `ITransition` 을 돌려주므로 조건은 한 번만 체이닝된다.

## 사용 패턴

### 기본 흐름

```csharp
var onAttack = new StatechartEvent("OnAttack");
var onIdle = new StatechartEvent("OnIdle");

var chart = new Statechart(factory =>
{
    var initial = factory.Initial("Initial");
    var idle = factory.State("Idle");
    var attack = factory.State("Attack");

    initial.Transition().Target(idle);

    idle.OnEnter(() => Debug.Log("Idle 진입"));
    idle.Event(onAttack).Target(attack);

    attack.Event(onIdle).OnTransition(() => Debug.Log("공격 종료")).Target(idle);
});

chart.Run();
chart.Trigger(onAttack);
```

### Choice

```csharp
var check = factory.Choice("HealthCheck");
check.Transition().Condition(() => health > 50).Target(attack); // 조건 전이 1개 이상
check.Transition().Target(flee);                                // 기본 전이 정확히 1개
```

조건 전이는 등록 순서대로 검사하고, 모두 실패하면 기본 전이를 탄다.

### Nest / Split / Leave

```csharp
var combat = factory.Nest("Combat");
combat.Nest(inner =>
{
    var init = inner.Initial("Init");
    var fight = inner.State("Fight");
    var done = inner.Final("Done");
    var bail = inner.Leave("Bail");

    init.Transition().Target(fight);
    fight.Event(onWin).Target(done);
    fight.Event(onError).Target(bail);
    bail.Transition().Target(errorState); // 바로 위 영역(combat 과 같은 영역)의 상태
}).Target(victory);                       // 하위 영역이 Final 에 도달했을 때
combat.Event(onFlee).Target(escape);      // 바깥 이벤트로 강제 종료

var parallel = factory.Split("Parallel");
parallel.Split(
    anim => { var i = anim.Initial("AnimInit"); var f = anim.Final("AnimDone"); i.Transition().Target(f); },
    sound => { var i = sound.Initial("SoundInit"); var f = sound.Final("SoundDone"); i.Transition().Target(f); }
).Target(next);                           // 모든 영역이 Final 에 도달했을 때

// 떠날 때 내부 현재 상태의 OnExit / 내부 Final 의 OnEnter 실행 여부 제어 (람다만 넘기면 둘 다 true)
Action<IStateFactory> menuSetup = inner => { /* 하위 영역 정의 */ };
var menu = factory.Nest("Menu");
menu.Nest(new NestedStateData(menuSetup, executeExit: false, executeFinal: false)).Target(next);
```

### Wait / TaskWait

```csharp
var wait = factory.Wait("Loading");
wait.WaitingFor(activity =>
{
    var child = activity.Split();          // 자식 활동: 부모와 자식이 모두 완료되어야 끝남
    LoadConfigs(() => child.Complete());   // 로드 완료 콜백에서 호출(동기 호출도 가능)
    LoadAssets(() => activity.Complete());
}).Target(next);
wait.Event(onCancel).Target(cancelled);    // Target 이 있는 이벤트 전이는 대기 활동을 강제 완료

var task = factory.TaskWait("Download");
task.WaitingFor(DownloadAsync).Target(next); // async Task/UniTask 메서드, CancellationToken 을 받아도 됨
task.Failed().Target(retry);                 // 선택: 태스크가 예외로 끝났을 때의 전이
```

## 함정

- `using Geuneda.Statechart;` 는 존재하지 않는 네임스페이스다. 항상 `Geuneda.StatechartMachine`.
- 검증(`Validate`)은 `UNITY_EDITOR || DEBUG` 에서만 생성자 안에서 실행된다. 릴리스 빌드에서는 잘못된 구성이 예외 없이 이상 동작할 수 있으니 에디터에서 생성자를 한 번은 실행해 본다.
  - 대상 없는 자동 전이(Transition/Wait/TaskWait/Leave), 자기 자신으로의 전이, Choice 의 조건 전이나 기본 전이 누락은 `InvalidOperationException`.
  - Initial 상태의 전이 누락은 `MissingMemberException`. Initial 상태 자체가 없으면 빌드와 무관하게 `MissingMemberException`.
  - Nest 는 하위 영역 정확히 1개, Split 은 2개 이상이어야 하고, 하위 영역마다 Initial 이 있어야 한다(`InvalidOperationException`). Leave 의 대상은 바로 위 영역(RegionLayer - 1)의 상태여야 한다.
- 같은 영역에서 `Initial`/`Final` 을 두 번 만들거나, 같은 상태에 `Transition()`/`Nest()`/`Split()` 을 두 번 호출하면 즉시 `InvalidOperationException`. 같은 상태에 같은 이벤트를 두 번 등록하면 `Dictionary` 의 `ArgumentException`.
- `TaskWait` 에는 `Event()` 가 없다. 이 상태가 현재 상태일 때 `Trigger` 한 이벤트는 부모 Nest/Split 의 이벤트가 아니면 처리되지 않고 사라진다. 부모 이벤트로 태스크를 멈추려면 `CancellationToken` 을 받는 `WaitingFor` 를 쓰고 태스크가 토큰을 따르게 한다. 최상위 영역에서 이벤트로 취소해야 하면 `Wait` 를 쓴다.
- `TaskWait` 의 태스크가 예외로 끝나면 로그를 남기고 `Failed()` 전이, 없으면 `WaitingFor` 전이로 진행한다(v0.10.0, 이전에는 그 자리에 멈춰 부모 Nest/Split 도 퇴장하지 못했다). 실패를 성공과 구분해야 하면 `Failed()` 를 설정한다.
- Nest/Split 을 대상 있는 이벤트나 Leave 로 떠날 때 내부(중첩 영역 포함) `Wait` 는 강제 완료되고, 내부 `TaskWait` 가 실행 중이면 태스크가 끝날 때까지 전이가 지연된다. 부모가 퇴장을 미룬 이벤트를 기억했다가 태스크가 모두 끝나면 그 이벤트로 한 번 퇴장하고, 미루는 동안 들어온 다른 이벤트는 버린다(그 사이 `Pause` 했다가 `Run` 해도 이어진다). 토큰을 받는 `WaitingFor` 면 이때 토큰에 취소를 요청하며, 그 취소로 끝난 태스크는 실패로 보지 않는다. 대상 없는 Nest/Split 이벤트는 떠나지 않으므로 내부 대기를 건드리지 않는다(v0.10.0).
- 대상 없는 Nest/Split 완료 전이(`Nest(...).OnTransition(...)` 만)는 상태에 머무르며 진입마다 한 번만 실행된다(v0.10.0, 이전에는 `Run()` 이나 대기 완료로 진행 요청이 올 때마다 다시 실행됐다).
- Nest/Split 자신에 등록한 `Event` 가 내부 상태보다 먼저 검사된다.
- `WaitingFor` 콜백 안에서 동기적으로 `activity.Complete()` 를 호출하거나 이미 완료된 Task/UniTask 를 넘겨도 된다. 전이는 한 번만 일어난다(0.9.4 미만에서는 Wait 와 UniTask 의 경우 두 번 실행됐다). 이미 완료된 `UniTask` 와 동기 `Complete()` 는 진행 중인 처리 안에서 바로 전이하고, `Func<Task>` 는 `AsUniTask` 변환이 동기화 컨텍스트를 거치므로 그 뒤에 전이한다. 다른 상태 액션(`OnEnter`, `OnExit`, `OnTransition`) 안에서 `Trigger` 를 호출하거나 대기 활동을 완료해도 바로 처리되지 않고 큐에 들어가, 진행 중인 처리가 끝난 뒤(새 상태 진입 후) 순서대로 처리된다(run-to-completion, 0.9.5). 처리 도중 `Pause` 되거나 예외가 `Trigger`/`Run` 밖으로 전파되면 남은 요청은 버려진다(상태 액션의 예외는 로그로 남고 처리는 계속된다). 액션 안에서 `Reset` 하면 대기 요청을 버리고, 진행 중이던 전이 결과가 초기 상태를 덮어쓰지 않으며, 퇴장/전이 액션 안에서 리셋했다면 그 전이의 남은 단계(전이 액션, 목적 상태 진입)도 실행하지 않는다. 대기 액션·선택 조건·중첩/분할 영역 안(영역 종료 포함)에서 리셋해도 같은 규칙으로 멈추고, 리셋 전에 시작한 Wait 활동이나 TaskWait 태스크가 나중에 완료돼도 무시된다(0.9.6). 최상위 연쇄 전이 도중 `Pause` 하면 방금 진입한 상태에서 멈추고 `Run` 으로 이어서 진행한다(중첩/분할 영역 안의 연쇄 전이는 제외).
- `Reset()` 은 현재 상태의 `OnExit` 를 부르지 않고, 실행 중인 `Wait` 활동도 정리하지 않는다. 실행 중인 `TaskWait` 태스크에는 토큰 취소만 요청한다(토큰을 받는 `WaitingFor` 일 때 효과). 필요한 정리는 직접 한다.
- `OnEnter`/`OnExit`/`OnTransition`/대기 액션의 예외는 잡혀서 로그로만 남고 흐름은 계속된다. 예외로 흐름을 멈출 수 없다. 단 `Wait` 의 대기 액션이 예외를 던지면 활동이 완료되거나 이벤트가 올 때까지 기다린다.
- `Statechart.CurrentState` 는 `UNITY_EDITOR` 전용이며 최상위 영역의 상태 이름만 보여 준다. 런타임 로직에 쓰지 않는다.
