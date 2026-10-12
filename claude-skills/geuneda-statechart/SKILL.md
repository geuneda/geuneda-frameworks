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
| `TaskWait(name)` | `ITaskWaitState` | `OnEnter`, `OnExit`, `WaitingFor(Func<Task>)`, `WaitingFor(Func<UniTask>)` |
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
    LoadConfigs(() => child.Complete());   // 완료는 비동기 콜백에서 호출
    LoadAssets(() => activity.Complete());
}).Target(next);
wait.Event(onCancel).Target(cancelled);    // Target 이 있는 이벤트 전이는 대기 활동을 강제 완료

var task = factory.TaskWait("Download");
task.WaitingFor(DownloadAsync).Target(next); // async Task 또는 async UniTask 메서드
```

## 함정

- `using Geuneda.Statechart;` 는 존재하지 않는 네임스페이스다. 항상 `Geuneda.StatechartMachine`.
- 검증(`Validate`)은 `UNITY_EDITOR || DEBUG` 에서만 생성자 안에서 실행된다. 릴리스 빌드에서는 잘못된 구성이 예외 없이 이상 동작할 수 있으니 에디터에서 생성자를 한 번은 실행해 본다.
  - 대상 없는 자동 전이(Transition/Wait/TaskWait/Leave), 자기 자신으로의 전이, Choice 의 조건 전이나 기본 전이 누락은 `InvalidOperationException`.
  - Initial 상태의 전이 누락은 `MissingMemberException`. Initial 상태 자체가 없으면 빌드와 무관하게 `MissingMemberException`.
  - Nest 는 하위 영역 정확히 1개, Split 은 2개 이상이어야 한다. Leave 의 대상은 바로 위 영역(RegionLayer - 1)의 상태여야 한다.
- 같은 영역에서 `Initial`/`Final` 을 두 번 만들거나, 같은 상태에 `Transition()`/`Nest()`/`Split()` 을 두 번 호출하면 즉시 `InvalidOperationException`. 같은 상태에 같은 이벤트를 두 번 등록하면 `Dictionary` 의 `ArgumentException`.
- 중첩 영역의 Initial 누락은 검증되지 않고 실행 시점에 실패한다. 중첩 영역마다 Initial 을 만든다.
- `TaskWait` 에는 `Event()` 가 없다. 이 상태가 현재 상태일 때 `Trigger` 한 이벤트는 부모 Nest/Split 의 이벤트가 아니면 처리되지 않고 사라진다. 취소가 필요하면 `Wait` 를 쓴다.
- Nest/Split 을 이벤트나 Leave 로 떠날 때 내부 `Wait` 는 강제 완료되고, 내부 `TaskWait` 가 실행 중이면 태스크가 끝날 때까지 전이가 지연된다(이벤트는 첫 번째 하나만 큐잉).
- Nest/Split 자신에 등록한 `Event` 가 내부 상태보다 먼저 검사된다.
- `WaitingFor` 콜백 안에서 동기적으로 `activity.Complete()` 를 호출하거나 즉시 완료되는 Task 를 넘기면, 완료 콜백이 진행 중인 `Trigger` 안으로 재진입한다. 패키지 테스트는 모두 yield 이후에 완료한다. 완료는 비동기로 일어나게 한다.
- `Reset()` 은 현재 상태의 `OnExit` 를 부르지 않고, 실행 중인 대기 활동도 정리하지 않는다. 필요한 정리는 직접 한다.
- `OnEnter`/`OnExit`/`OnTransition`/대기 액션의 예외는 잡혀서 로그로만 남고 흐름은 계속된다. 예외로 흐름을 멈출 수 없다.
- `Statechart.CurrentState` 는 `UNITY_EDITOR` 전용이며 최상위 영역의 상태 이름만 보여 준다. 런타임 로직에 쓰지 않는다.
