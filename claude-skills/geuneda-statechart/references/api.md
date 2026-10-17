# Geuneda Statechart API 레퍼런스

- 네임스페이스: `Geuneda.StatechartMachine`
- 어셈블리: `Geuneda.Statechart` (참조: UniTask)
- 소스: `Packages/com.geuneda.statechart/Runtime/`

아래는 모든 공개 타입이다. `Geuneda.StatechartMachine.Internal` 의 타입은 전부 `internal` 이라 사용자 코드에서 접근할 수 없다.

---

## Statechart

### IStateMachineDebug

| 멤버 | 설명 |
|---|---|
| `bool LogsEnabled { get; set; }` | 모든 상태와 전이의 디버그 로그를 콘솔에 출력 |

### IStatechart : IStateMachineDebug

| 멤버 | 설명 |
|---|---|
| `void Trigger(IStatechartEvent trigger)` | 이벤트를 run-to-completion 방식으로 처리. 상태 액션 안에서 호출하면 큐에 넣었다가 현재 처리가 끝난 뒤 순서대로 처리(0.9.5). 실행 중이 아니면(`Run` 전, `Pause` 후) 아무것도 하지 않고 이벤트는 버려짐 |
| `void Run()` | 실행 플래그를 켜고 현재 상태에서 진행을 시작/재개. 일시정지 동안 완료된 Wait/TaskWait 는 이때 전이됨 |
| `void Pause()` | 실행 플래그를 끔. 이후 `Trigger` 와 대기 완료 콜백에 의한 진행이 멈춤 |
| `void Reset()` | 현재 상태를 최상위 Initial 상태로 되돌림. 실행/정지 상태는 그대로이며 현재 상태의 `OnExit` 은 호출하지 않음. 실행 중인 `TaskWait` 태스크에는 토큰 취소를 요청함(v0.10.0) |

### Statechart : IStatechart

```csharp
public Statechart(Action<IStateFactory> setup)
```

- `setup` 안에서만 상태와 전이를 정의할 수 있다.
- 최상위 영역에 Initial 상태가 없으면 `MissingMemberException`.
- `UNITY_EDITOR || DEBUG` 에서는 생성 직후 모든 상태(중첩 포함)를 검증한다. 아래 [검증 규칙](#검증-규칙) 참고.

| 멤버 | 설명 |
|---|---|
| `bool LogsEnabled { get; set; }` | `IStateMachineDebug` 구현 |
| `string CurrentState { get; }` | 최상위 영역의 현재 상태 이름. `#if UNITY_EDITOR` 에서만 존재 |
| `Trigger`, `Run`, `Pause`, `Reset` | `IStatechart` 구현 |

---

## 이벤트

### IStatechartEvent : IEquatable\<IStatechartEvent\>

| 멤버 | 설명 |
|---|---|
| `uint Id { get; }` | 생성 시 자동 부여되는 고유 ID |
| `string Name { get; }` | 디버깅용 이름 |

### StatechartEvent : IStatechartEvent

```csharp
public StatechartEvent(string name)
```

- `Id` 는 정적 카운터로 증가한다. 이름이 같아도 인스턴스가 다르면 다른 이벤트다.
- `Equals(IStatechartEvent)`, `Equals(object)`, `GetHashCode()` 는 `Id` 기준. `ToString()` 은 `Name` 을 반환한다.

---

## IStateFactory

`Statechart` 생성자와 `Nest`/`Split` 의 각 영역마다 하나씩 전달된다.

| 메서드 | 반환 | 비고 |
|---|---|---|
| `Initial(string name)` | `IInitialState` | 영역마다 하나. 두 번 호출하면 `InvalidOperationException` |
| `Final(string name)` | `IFinalState` | 영역마다 최대 하나. 두 번 호출하면 `InvalidOperationException` |
| `State(string name)` | `ISimpleState` | |
| `Transition(string name)` | `ITransitionState` | |
| `Nest(string name)` | `INestState` | |
| `Choice(string name)` | `IChoiceState` | |
| `Wait(string name)` | `IWaitState` | |
| `TaskWait(string name)` | `ITaskWaitState` | |
| `Split(string name)` | `ISplitState` | |
| `Leave(string name)` | `ILeaveState` | |

---

## 상태 구성 요소 인터페이스

| 인터페이스 | 멤버 | 설명 |
|---|---|---|
| `IState` | `bool LogsEnabled { get; set; }` | 이 상태만의 디버그 로그 |
| `IStateEnter : IState` | `void OnEnter(Action action)` | 진입 액션 추가. 여러 번 호출하면 순서대로 실행. `null` 이면 `NullReferenceException` |
| `IStateExit : IState` | `void OnExit(Action action)` | 퇴장 액션 추가. `null` 이면 `NullReferenceException` |
| `IStateTransition : IState` | `ITransition Transition()` | 자동 전이 생성. 이미 있으면 `InvalidOperationException` |
| `IStateEvent : IState` | `ITransition Event(IStatechartEvent statechartEvent)` | 이벤트 전이 생성. `null` 이면 `NullReferenceException`, 같은 이벤트를 두 번 등록하면 `ArgumentException` |

## 전이

### ITransition

| 멤버 | 설명 |
|---|---|
| `ITransition OnTransition(Action action)` | 전이 시 실행할 액션 추가. 자신을 반환하므로 체이닝 가능. `null` 이면 `NullReferenceException` |
| `void Target(IState state)` | 대상 상태 지정. `null` 이면 `NullReferenceException` |

이벤트 전이(`Event`)에서 `Target` 을 지정하지 않으면 상태를 바꾸지 않고 `OnTransition` 액션만 실행한다.

### ITransitionCondition : ITransition

| 멤버 | 설명 |
|---|---|
| `ITransition Condition(Func<bool> condition)` | 전이 실행 조건 추가. `null` 이면 `NullReferenceException`. `IChoiceState.Transition()` 이 반환 |

---

## 상태 인터페이스

| 인터페이스 | 상속 | 고유 멤버 |
|---|---|---|
| `IInitialState` | `IStateExit`, `IStateTransition` | 없음 |
| `IFinalState` | `IStateEnter` | 없음 |
| `ISimpleState` | `IStateEnter`, `IStateExit`, `IStateEvent` | 없음 |
| `ITransitionState` | `IStateEnter`, `IStateExit`, `IStateTransition` | 없음 |
| `IChoiceState` | `IStateEnter`, `IStateExit` | `ITransitionCondition Transition()` |
| `INestState` | `IStateEnter`, `IStateExit`, `IStateEvent` | `ITransition Nest(Action<IStateFactory> data)`, `ITransition Nest(NestedStateData data)` |
| `ISplitState` | `IStateEnter`, `IStateExit`, `IStateEvent` | `ITransition Split(params Action<IStateFactory>[] data)`, `ITransition Split(params NestedStateData[] data)` |
| `IWaitState` | `IStateEnter`, `IStateExit`, `IStateEvent` | `ITransition WaitingFor(Action<IWaitActivity> waitAction)` |
| `ITaskWaitState` | `IStateEnter`, `IStateExit` | `ITransition WaitingFor(Func<Task> taskAwaitAction)`, `ITransition WaitingFor(Func<UniTask> taskAwaitAction)`, `ITransition WaitingFor(Func<CancellationToken, Task> taskAwaitAction)`, `ITransition WaitingFor(Func<CancellationToken, UniTask> taskAwaitAction)`, `ITransition Failed()` |
| `ILeaveState` | `IStateEnter`, `IStateTransition` | 없음 |

### 상태별 동작

- **Initial**: 영역에 진입하면 곧바로 `Transition()` 의 대상으로 이동한다. `OnEnter` 는 없다.
- **Final**: 영역의 완료 지점. 들어온 뒤에는 어떤 이벤트에도 반응하지 않는다.
- **Simple**: 등록된 이벤트가 들어올 때까지 멈춘다.
- **Transition**: 진입 후 멈추지 않고 `Transition()` 의 대상으로 이동한다.
- **Choice**: 조건 전이를 등록 순서대로 검사해 처음으로 참인 전이를 탄다. 모두 거짓이면 조건 없는 기본 전이를 탄다. 멈추지 않는다.
- **Nest / Split**
  - `Nest` 는 하위 영역 1개, `Split` 은 2개 이상의 병렬 영역을 만든다. 각 영역은 별도의 `IStateFactory` 로 정의하며 Initial 이 필요하다.
  - 모든 하위 영역이 Final 에 도달하면 `Nest()`/`Split()` 이 반환한 전이를 실행한다. 이 완료 전이에 대상이 없으면(`OnTransition` 만) 상태에 머무르며, 그 액션은 진입마다 한 번만 실행된다(v0.10.0, 이전에는 `Run()` 이나 대기 완료로 진행 요청이 올 때마다 다시 실행됐다).
  - 어느 영역이든 Leave 상태에 도달하면 그 Leave 상태의 전이로 바로 위 영역의 상태로 이동한다.
  - 이벤트는 Nest/Split 자신의 `Event` 를 먼저 검사하고, 일치하지 않으면 하위 영역에 전달한다.
  - 대상 있는 이벤트나 Leave 로 떠날 때 하위 영역(중첩 영역 포함)의 현재 상태가 `Wait` 면 강제 완료하고, 실행 중인 `TaskWait` 면 태스크가 끝날 때까지 전이를 지연한다. 지연을 일으킨 이벤트(Leave 면 그 Leave)를 Nest/Split 이 기억했다가 태스크가 모두 끝나면 그것으로 한 번 퇴장하고, 지연 중 들어온 다른 이벤트는 버린다. 토큰을 받는 `WaitingFor` 로 시작한 태스크에는 이때 취소를 요청한다.
  - 대상 없는 이벤트(`OnTransition` 만 있는 전이)는 상태를 떠나지 않으므로 하위 영역의 대기를 건드리지 않고 바로 실행한다(v0.10.0).
  - 상태를 떠날 때 각 하위 영역에 대해 `NestedStateData.ExecuteExit` 가 참이면 현재 내부 상태의 `OnExit` 을, `ExecuteFinal` 이 참이고 현재 내부 상태가 Final/Leave 가 아니면 그 영역 Final 상태의 `OnEnter` 를 실행한다.
  - `Nest()`/`Split()` 을 같은 상태에 두 번 호출하면 `InvalidOperationException`.
- **Wait**: 진입할 때마다 새 `IWaitActivity` 를 만들고 첫 진행 시 `waitAction(activity)` 를 호출한다. 활동(과 모든 자식 활동)이 완료되면 `WaitingFor()` 의 전이를 실행한다. `Target` 이 있는 이벤트 전이가 일어나면 활동을 강제 완료한다. `waitAction` 안에서 동기적으로 완료해도 전이는 한 번만 실행된다.
- **TaskWait**: 첫 진행 시 태스크를 시작하고 완료되면 `WaitingFor()` 의 전이를 실행한다. `Func<Task>` 는 내부에서 `UniTask` 로 변환된다(`AsUniTask` 가 동기화 컨텍스트로 완료를 넘기므로 이미 완료된 `Task` 도 동기화 컨텍스트가 그 작업을 처리한 뒤에 전이된다). 이미 완료된 `UniTask` 는 그 자리에서 한 번 전이된다. 이벤트를 받지 않는다.
  - 태스크가 예외로 끝나면 로그를 남기고 `Failed()` 전이를, 없으면 `WaitingFor()` 전이를 실행한다(v0.10.0).
  - `CancellationToken` 을 받는 `WaitingFor` 는 실행마다 새 토큰을 넘긴다. 부모 Nest/Split 이 퇴장하려 하거나 `Statechart.Reset()` 되면 취소를 요청한다. 이 취소로 생긴 `OperationCanceledException` 은 실패가 아니며, 리셋으로 취소된 실행의 완료는 무시된다.
- **Leave**: Nest/Split 내부에서만 의미가 있다. `Transition()` 의 대상은 바로 위 영역(한 레이어 위)의 상태여야 한다.

`OnEnter`/`OnExit`/`OnTransition` 과 대기 액션에서 발생한 예외는 잡혀서 `Geuneda.Statechart` 로거로 Error 줄 + 예외가 출력되며 흐름은 계속된다. `Wait` 의 대기 액션이 예외를 던지면 활동이 완료되거나 이벤트가 올 때까지 기다리고, `TaskWait` 의 태스크가 예외로 끝나면 위 규칙대로 전이한다.

---

## IWaitActivity

`IWaitState.WaitingFor` 콜백에 전달되는 대기 컨트롤러.

| 멤버 | 설명 |
|---|---|
| `uint Id { get; }` | 활동 고유 ID |
| `bool Complete()` | 이 활동을 완료로 표시. 모든 자식 활동도 완료되었으면 `true` 를 반환하고 Wait 상태를 진행시킴 |
| `IWaitActivity Split()` | 자식 활동 생성. 부모와 모든 자식이 완료되어야 부모가 완료됨 |

---

## NestedStateData (struct)

`INestState.Nest`, `ISplitState.Split` 에 넘기는 하위 영역 설정.

| 필드 | 타입 | 설명 |
|---|---|---|
| `Setup` | `Action<IStateFactory>` | 하위 영역 정의 콜백 |
| `ExecuteExit` | `bool` | 상태를 떠날 때 하위 영역의 현재 상태 `OnExit` 실행 여부 |
| `ExecuteFinal` | `bool` | 이벤트나 Leave 로 떠날 때 하위 영역 Final 상태의 `OnEnter` 실행 여부 |

```csharp
public NestedStateData(Action<IStateFactory> setup, bool executeExit, bool executeFinal)
public NestedStateData(Action<IStateFactory> setup) // executeExit = true, executeFinal = true
public static implicit operator NestedStateData(Action<IStateFactory> setup)
```

`Nest(Action<IStateFactory>)`, `Split(params Action<IStateFactory>[])` 는 두 옵션이 모두 `true` 인 것과 같다.

---

## 검증 규칙

`UNITY_EDITOR || DEBUG` 에서 `Statechart` 생성자가 실행한다. 별도 표기가 없으면 `InvalidOperationException`.

| 상태 | 규칙 |
|---|---|
| `Statechart` | 최상위 Initial 필수 (`MissingMemberException`, 빌드 종류와 무관하게 항상 검사) |
| Initial | 전이 대상 필수 (`MissingMemberException`), 자기 자신 전이 금지 |
| Final | 없음 |
| Simple | 이벤트 전이의 자기 자신 전이 금지 |
| Transition | 전이 대상 필수, 자기 자신 전이 금지 |
| Choice | 모든 전이에 대상 필수, 자기 자신 전이 금지, 조건 전이 1개 이상, 기본 전이 1개 이상 (2개 이상이면 경고 로그) |
| Nest | 하위 영역 정확히 1개, 하위 영역의 Initial 필수, 하위 상태 검증, 완료 전이와 이벤트 전이의 자기 자신 전이 금지 |
| Split | 하위 영역 2개 이상, 각 하위 영역의 Initial 필수, 하위 상태 검증, 완료 전이와 이벤트 전이의 자기 자신 전이 금지 |
| Wait | `WaitingFor` 필수, 전이 대상 필수, 자기 자신 전이 금지(완료 전이와 이벤트 전이) |
| TaskWait | `WaitingFor` 필수, 전이 대상 필수, 자기 자신 전이 금지. `Failed()` 를 호출했으면 그 전이도 대상 필수, 자기 자신 전이 금지 |
| Leave | 전이 대상 필수, 대상이 바로 위 영역 레이어에 있어야 함 |
