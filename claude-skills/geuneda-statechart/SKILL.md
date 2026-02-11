---
name: geuneda-statechart
description: Unity 프로젝트에서 계층적 상태 머신(Statechart/HFSM)을 구성하고 사용하는 코드를 작성하거나 수정할 때 사용하는 스킬. Geuneda.StatechartMachine 네임스페이스의 상태, 전이, 이벤트, 중첩 상태 등의 API를 활용한 상태 머신 구현을 지원합니다.
---

# Geuneda Statechart

Unity 프로젝트에서 Statechart(계층적 상태 머신, HFSM)를 구현할 수 있게 해주는 패키지입니다. 상태를 계층 구조로 구성할 수 있으며, 각 상태가 하위 상태(substate)를 정의할 수 있습니다. UML 시맨틱스를 따르며, 비동기 대기(UniTask), 병렬 영역(Split), 조건 분기(Choice) 등 고급 상태 머신 패턴을 지원합니다.

## 활성화 시점

- 게임 AI, UI 흐름, 게임플레이 로직에 상태 머신을 적용할 때
- 계층적/중첩 상태 머신(HFSM)을 구현해야 할 때
- 상태 전이, 이벤트 기반 전이, 조건 분기를 설정할 때
- 비동기 작업 완료를 기다리는 상태를 구현할 때
- 병렬로 실행되는 상태 영역이 필요할 때
- 기존 Statechart 코드를 수정하거나 확장할 때

## 패키지 정보

- **네임스페이스**: `Geuneda.StatechartMachine`
- **설치**: `https://github.com/geuneda/geuneda-statechart.git`
- **의존성**: `com.cysharp.unitask` (2.5.10 이상)
- **최소 Unity**: 2022.3

## 핵심 개념

### 상태 유형

| 상태 | 팩토리 메서드 | 설명 |
|------|------------|------|
| Initial | `factory.Initial(name)` | 영역 시작점. 자동 전이만 가능 |
| Final | `factory.Final(name)` | 영역 완료 표시 |
| State | `factory.State(name)` | 이벤트를 기다리는 단순 상태 |
| Transition | `factory.Transition(name)` | 비차단 통과 상태 |
| Nest | `factory.Nest(name)` | 새로운 중첩 영역 생성 |
| Split | `factory.Split(name)` | 두 개의 병렬 영역 생성 |
| Choice | `factory.Choice(name)` | 조건 기반 분기 |
| Wait | `factory.Wait(name)` | 활동 완료 대기 (동기) |
| TaskWait | `factory.TaskWait(name)` | Task/UniTask 완료 대기 (비동기) |
| Leave | `factory.Leave(name)` | 중첩 영역에서 상위로 탈출 |

### 전이 체이닝

전이는 플루언트 API로 구성합니다:

```csharp
state.Event(someEvent)
    .OnTransition(() => DoSomething())  // 전이 시 실행할 액션
    .Target(targetState);               // 대상 상태
```

## 핵심 API

### IStatechart

```csharp
public interface IStatechart : IStateMachineDebug
{
    void Trigger(IStatechartEvent trigger);  // 이벤트 트리거
    void Run();                               // 실행 시작/재개
    void Pause();                             // 일시 정지
    void Reset();                             // 초기 상태로 리셋
}
```

### Statechart (구현)

```csharp
public Statechart(Action<IStateFactory> setup)
```

### IStateFactory

```csharp
public interface IStateFactory
{
    IInitialState Initial(string name);
    IFinalState Final(string name);
    ISimpleState State(string name);
    ITransitionState Transition(string name);
    INestState Nest(string name);
    IChoiceState Choice(string name);
    IWaitState Wait(string name);
    ITaskWaitState TaskWait(string name);
    ISplitState Split(string name);
    ILeaveState Leave(string name);
}
```

### StatechartEvent

```csharp
public class StatechartEvent : IStatechartEvent
{
    public StatechartEvent(string name)
    public uint Id { get; }
    public string Name { get; }
}
```

## 사용 패턴

### 기본 상태 머신

```csharp
using Geuneda.StatechartMachine;

var onAttack = new StatechartEvent("OnAttack");
var onIdle = new StatechartEvent("OnIdle");

var statechart = new Statechart(factory =>
{
    var initial = factory.Initial("Initial");
    var idle = factory.State("Idle");
    var attack = factory.State("Attack");
    var final = factory.Final("Final");

    // Initial -> Idle
    initial.Transition().Target(idle);

    // Idle 상태
    idle.OnEnter(() => Debug.Log("Idle 진입"));
    idle.Event(onAttack).Target(attack);
    idle.OnExit(() => Debug.Log("Idle 퇴장"));

    // Attack 상태
    attack.OnEnter(() => PlayAttackAnimation());
    attack.Event(onIdle).Target(idle);
    attack.OnExit(() => StopAttackAnimation());
});

statechart.Run();            // 실행 시작
statechart.Trigger(onAttack); // 이벤트로 상태 전이
```

### 중첩 상태 (Nest)

```csharp
var statechart = new Statechart(factory =>
{
    var initial = factory.Initial("Initial");
    var combat = factory.Nest("Combat");
    var final = factory.Final("Final");

    initial.Transition().Target(combat);

    // Nest 상태: 내부에 별도 상태 머신 정의
    combat.OnEnter(() => Debug.Log("전투 시작"));
    combat.Nest(innerFactory =>
    {
        var innerInitial = innerFactory.Initial("CombatInit");
        var attacking = innerFactory.State("Attacking");
        var defending = innerFactory.State("Defending");
        var innerFinal = innerFactory.Final("CombatEnd");

        innerInitial.Transition().Target(attacking);
        attacking.Event(onDefend).Target(defending);
        defending.Event(onAttack).Target(innerFinal);
    }).OnTransition(() => Debug.Log("전투 완료")).Target(final);

    // 외부 이벤트로 Nest를 강제 종료
    combat.Event(onFlee).Target(final);
    combat.OnExit(() => Debug.Log("전투 종료"));
});
```

### NestedStateData로 세밀한 제어

```csharp
var nestedData = new NestedStateData(
    setup: innerFactory => { /* 상태 정의 */ },
    executeExit: true,   // 중첩 떠날 때 현재 활성 상태의 OnExit 실행
    executeFinal: true    // 중첩 떠날 때 FinalState의 OnEnter 실행
);

nestState.Nest(nestedData).Target(someState);
```

### 조건 분기 (Choice)

```csharp
var choice = factory.Choice("HealthCheck");

// 조건이 있는 전이 (여러 개 가능)
choice.Transition().Condition(() => health > 50).Target(attack);

// 조건 없는 전이 (기본 경로, 반드시 하나 필요)
choice.Transition().Target(flee);
```

### 비동기 대기 (Wait)

```csharp
var wait = factory.Wait("LoadingWait");
wait.OnEnter(() => StartLoading());
wait.WaitingFor(activity =>
{
    // 비동기 작업 시작, 완료 시 activity.Complete() 호출
    LoadAsync(() => activity.Complete());
}).Target(nextState);
// 이벤트로 대기를 중단할 수도 있음
wait.Event(cancelEvent).Target(cancelState);
```

### Task/UniTask 대기 (TaskWait)

```csharp
var taskWait = factory.TaskWait("AsyncLoad");
taskWait.OnEnter(() => Debug.Log("비동기 로딩 시작"));
taskWait.WaitingFor(async () =>
{
    await LoadDataAsync();
}).Target(nextState);
```

### 병렬 영역 (Split)

```csharp
var split = factory.Split("Parallel");

split.Split(
    animFactory =>
    {
        // 애니메이션 영역
        var init = animFactory.Initial("AnimInit");
        var playing = animFactory.State("Playing");
        var done = animFactory.Final("AnimDone");
        init.Transition().Target(playing);
        playing.Event(animComplete).Target(done);
    },
    audioFactory =>
    {
        // 오디오 영역
        var init = audioFactory.Initial("AudioInit");
        var playing = audioFactory.State("AudioPlaying");
        var done = audioFactory.Final("AudioDone");
        init.Transition().Target(playing);
        playing.Event(audioComplete).Target(done);
    }
).Target(nextState); // 두 영역 모두 Final에 도달하면 전이
```

### 전이 액션 (OnTransition)

```csharp
state.Event(someEvent)
    .OnTransition(() => PlaySound())
    .OnTransition(() => UpdateUI())  // 여러 개 체이닝 가능
    .Target(nextState);
```

### 이탈 상태 (Leave)

중첩 영역 내에서 상위 영역의 특정 상태로 직접 전이:

```csharp
nestState.Nest(innerFactory =>
{
    var init = innerFactory.Initial("Init");
    var leave = innerFactory.Leave("ErrorLeave");
    var state = innerFactory.State("Processing");
    var final = innerFactory.Final("Done");

    init.Transition().Target(state);
    state.Event(errorEvent).Target(leave);
    state.Event(successEvent).Target(final);

    // Leave는 상위 영역의 상태를 타겟으로 지정
    leave.Transition().Target(errorState); // errorState는 상위 영역의 상태
});
```

## 상태 머신 수명 주기

1. **생성**: `new Statechart(setup)` - 상태와 전이 정의 (이후 수정 불가)
2. **실행**: `statechart.Run()` - Initial 상태에서 시작, 자동 전이 실행
3. **이벤트**: `statechart.Trigger(event)` - 이벤트로 상태 전이 트리거
4. **일시정지**: `statechart.Pause()` - 이벤트 처리 중단
5. **재개**: `statechart.Run()` - 현재 위치에서 재개
6. **리셋**: `statechart.Reset()` - Initial 상태로 복귀 (Run() 필요)

## 주의사항

- 상태 구성은 `Statechart` 생성자에서만 가능하며 런타임 중 수정 불가
- 각 영역에 `Initial` 상태와 `Final` 상태는 각각 하나만 허용
- `Initial` 상태에는 반드시 하나의 전이(Transition)가 정의되어야 함
- 상태가 자기 자신으로 전이하면 `InvalidOperationException` 발생
- `ChoiceState`는 최소 하나의 조건 전이와 하나의 기본(조건 없는) 전이가 필요
- `TaskWaitState`는 이벤트를 처리할 수 없음 (동시성 방지)
- `WaitState`에서 이벤트로 전이하면 대기 활동이 강제 완료됨
- `LogsEnabled`를 `true`로 설정하면 디버그 로그 출력 가능
- UniTask 의존성 필수 (`com.cysharp.unitask`)

## 참조 문서

상세 API 문서는 `references/api.md` 참조.
