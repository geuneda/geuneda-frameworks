# Geuneda Statechart API Reference

## 네임스페이스: Geuneda.StatechartMachine

---

## Public 인터페이스

### IStateMachineDebug

상태 차트 디버깅 인터페이스.

**프로퍼티:**
- `bool LogsEnabled { get; set; }` - 콘솔 디버그 로그 활성화/비활성화

---

### IStatechart : IStateMachineDebug

상태 차트의 메인 인터페이스. 런타임 중 상태 구성 수정 불가.

**메서드:**
- `void Trigger(IStatechartEvent trigger)` - 이벤트를 run-to-completion 방식으로 처리. 일시정지 중에는 무시됨
- `void Run()` - 현재 위치에서 상태 차트 실행 시작/재개. 이미 실행 중이면 무시
- `void Pause()` - 상태 차트 일시정지. `Run()`으로 재개
- `void Reset()` - 초기 상태로 리셋. 실행/정지 상태를 변경하지 않음

---

### IStatechartEvent : IEquatable<IStatechartEvent>

상태 차트를 전진시키는 고유 이벤트 입력.

**프로퍼티:**
- `uint Id { get; }` - 이벤트 고유 ID (자동 생성)
- `string Name { get; }` - 이벤트 이름 (디버깅용)

---

### IStateFactory

상태 차트의 상태와 전이를 설정하는 팩토리.

**메서드:**
| 메서드 | 반환 타입 | 설명 |
|--------|----------|------|
| `Initial(string name)` | `IInitialState` | 초기 의사 상태 생성 |
| `Final(string name)` | `IFinalState` | 최종 상태 생성 |
| `State(string name)` | `ISimpleState` | 단순 상태 생성 |
| `Transition(string name)` | `ITransitionState` | 전이 상태 생성 |
| `Nest(string name)` | `INestState` | 중첩 상태 생성 |
| `Choice(string name)` | `IChoiceState` | 선택 상태 생성 |
| `Wait(string name)` | `IWaitState` | 대기 상태 생성 |
| `TaskWait(string name)` | `ITaskWaitState` | 태스크 대기 상태 생성 |
| `Split(string name)` | `ISplitState` | 분할 상태 생성 |
| `Leave(string name)` | `ILeaveState` | 이탈 상태 생성 |

---

### IState

모든 상태의 기본 인터페이스.

**프로퍼티:**
- `bool LogsEnabled { get; set; }` - 이 상태의 디버그 로그 활성화

---

### IStateEnter : IState

상태 진입 시 액션 실행.

**메서드:**
- `void OnEnter(Action action)` - 상태 활성화 시 호출할 액션 추가. null이면 `NullReferenceException`

---

### IStateExit : IState

상태 퇴장 시 액션 실행.

**메서드:**
- `void OnExit(Action action)` - 상태 비활성화 시 호출할 액션 추가. null이면 `NullReferenceException`

---

### IStateTransition : IState

상태에 전이 설정.

**메서드:**
- `ITransition Transition()` - 전이 생성. 이미 존재하면 `InvalidOperationException`

---

### IStateEvent : IState

이벤트 기반 전이.

**메서드:**
- `ITransition Event(IStatechartEvent statechartEvent)` - 이벤트에 의한 전이 생성. null이면 `NullReferenceException`

---

### ITransition

두 상태 간의 전이.

**메서드:**
- `ITransition OnTransition(Action action)` - 전이 시 실행할 액션 추가 (체이닝 가능). null이면 `NullReferenceException`
- `void Target(IState state)` - 전이 대상 상태 설정. null이면 `NullReferenceException`

---

### ITransitionCondition : ITransition

조건부 전이. `IChoiceState`에서 사용.

**메서드:**
- `ITransition Condition(Func<bool> condition)` - 전이 실행 조건 함수 설정. 실패하면 전이 미실행. null이면 `NullReferenceException`

---

## 상태 인터페이스 상세

### IInitialState : IStateExit, IStateTransition

초기 의사 상태. 영역의 시작점. 각 영역에 하나만 가능.

**상속 메서드:**
- `ITransition Transition()` - 자동 전이 (단 하나만 허용)
- `void OnExit(Action action)` - 퇴장 액션

---

### IFinalState : IStateEnter

최종 상태. 영역 완료 표시. 각 영역에 하나만 가능.

**상속 메서드:**
- `void OnEnter(Action action)` - 진입 액션

---

### ISimpleState : IStateEnter, IStateExit, IStateEvent

이벤트를 기다리며 차단하는 단순 상태.

**상속 메서드:**
- `void OnEnter(Action action)` - 진입 액션
- `void OnExit(Action action)` - 퇴장 액션
- `ITransition Event(IStatechartEvent statechartEvent)` - 이벤트 전이

---

### ITransitionState : IStateEnter, IStateExit, IStateTransition

비차단 통과 상태. 자동으로 대상 상태로 진행.

**상속 메서드:**
- `void OnEnter(Action action)` - 진입 액션
- `void OnExit(Action action)` - 퇴장 액션
- `ITransition Transition()` - 자동 전이 (단 하나만 허용)

---

### INestState : IStateEnter, IStateExit, IStateEvent

중첩 상태. 새로운 중첩 영역 생성.

**상속 메서드:**
- `void OnEnter(Action action)` - 진입 액션
- `void OnExit(Action action)` - 퇴장 액션
- `ITransition Event(IStatechartEvent statechartEvent)` - 외부 이벤트로 강제 종료

**고유 메서드:**
- `ITransition Nest(Action<IStateFactory> data)` - 중첩 영역 정의 (ExecuteExit=true, ExecuteFinal=true)
- `ITransition Nest(NestedStateData data)` - 세밀한 제어가 가능한 중첩 영역 정의

**동작:**
- 완료 시 현재 활성 상태의 `OnExit` 실행 (`ExecuteExit`에 따라)
- 완료 시 `IFinalState`는 실행하지 않음 (`ExecuteFinal`에 따라)

---

### IWaitState : IStateEnter, IStateExit, IStateEvent

활동 완료를 기다리는 대기 상태.

**상속 메서드:**
- `void OnEnter(Action action)` - 진입 액션
- `void OnExit(Action action)` - 퇴장 액션
- `ITransition Event(IStatechartEvent statechartEvent)` - 이벤트로 대기 중단 가능

**고유 메서드:**
- `ITransition WaitingFor(Action<IWaitActivity> waitAction)` - 대기 활동 정의

**동작:**
- 이벤트로 전이 시 대기 활동 강제 완료
- 부모 Nest/Split에서 퇴장 시 강제 완료

---

### ITaskWaitState : IStateEnter, IStateExit

비동기 Task 완료를 기다리는 대기 상태.

**상속 메서드:**
- `void OnEnter(Action action)` - 진입 액션
- `void OnExit(Action action)` - 퇴장 액션

**고유 메서드:**
- `ITransition WaitingFor(Func<Task> taskAwaitAction)` - Task 대기
- `ITransition WaitingFor(Func<UniTask> taskAwaitAction)` - UniTask 대기

**동작:**
- 이벤트 처리 불가 (동시성 방지)
- 부모 Nest/Split에서 퇴장 시 완료 대기 후 이벤트 큐잉

---

### IChoiceState : IStateEnter, IStateExit

조건 기반 분기 상태.

**상속 메서드:**
- `void OnEnter(Action action)` - 진입 액션
- `void OnExit(Action action)` - 퇴장 액션

**고유 메서드:**
- `ITransitionCondition Transition()` - 조건부 전이 생성

**제약:**
- 최소 하나의 `Condition()` 전이 필요
- 정확히 하나의 조건 없는 기본 전이 필요
- 조건 없는 전이가 2개 이상이면 경고

---

### ISplitState : IStateEnter, IStateExit, IStateEvent

병렬 영역 분할 상태.

**상속 메서드:**
- `void OnEnter(Action action)` - 진입 액션
- `void OnExit(Action action)` - 퇴장 액션
- `ITransition Event(IStatechartEvent statechartEvent)` - 외부 이벤트로 강제 종료

**고유 메서드:**
- `ITransition Split(params Action<IStateFactory>[] data)` - 병렬 영역 정의 (간략)
- `ITransition Split(params NestedStateData[] data)` - 병렬 영역 정의 (세밀 제어)

**제약:**
- 최소 2개의 중첩 영역 필요

---

### ILeaveState : IStateEnter, IStateTransition

이탈 상태. 중첩 영역에서 상위 영역으로 전이.

**상속 메서드:**
- `void OnEnter(Action action)` - 진입 액션
- `ITransition Transition()` - 상위 영역의 상태를 타겟으로 지정

**제약:**
- Nest 또는 Split 내부에서만 사용 가능
- 한 영역 레이어만 점프 가능

---

### IWaitActivity

대기 상태의 컨트롤러.

**프로퍼티:**
- `uint Id { get; }` - 고유 활동 ID

**메서드:**
- `bool Complete()` - 활동을 완료로 표시. 모든 내부 활동도 완료되었으면 true
- `IWaitActivity Split()` - 새로운 내부 활동 계층 생성 (모든 자식 완료 시 부모 완료)

---

## Public 클래스

### Statechart : IStatechart

상태 차트 구현.

**생성자:**
```csharp
public Statechart(Action<IStateFactory> setup)
```
- `setup` - 상태와 전이를 정의하는 콜백
- Initial 상태가 없으면 `MissingMemberException`

**프로퍼티:**
- `bool LogsEnabled { get; set; }` - 전역 디버그 로그 활성화
- `string CurrentState { get; }` - 현재 상태 이름 (UNITY_EDITOR 전용)

**메서드:**
- `void Trigger(IStatechartEvent trigger)` - 이벤트 트리거
- `void Run()` - 실행 시작/재개
- `void Pause()` - 일시정지
- `void Reset()` - 초기 상태로 리셋

---

### StatechartEvent : IStatechartEvent

상태 차트 이벤트 구현.

**생성자:**
```csharp
public StatechartEvent(string name)
```
- `name` - 이벤트 이름
- ID는 자동 생성 (정적 증가)

**프로퍼티:**
- `uint Id { get; }` - 고유 ID
- `string Name { get; }` - 이벤트 이름

**메서드:**
- `bool Equals(IStatechartEvent statechartEvent)` - ID 기반 비교

---

## Public 구조체

### NestedStateData

Nest/Split 상태의 중첩 설정 데이터.

**필드:**
| 이름 | 타입 | 설명 |
|------|------|------|
| `Setup` | `Action<IStateFactory>` | 중첩 상태 정의 콜백 |
| `ExecuteExit` | `bool` | 중첩 떠날 때 현재 활성 상태의 OnExit 실행 여부 |
| `ExecuteFinal` | `bool` | 이벤트/Leave로 떠날 때 FinalState의 OnEnter 실행 여부 |

**생성자:**
```csharp
public NestedStateData(Action<IStateFactory> setup, bool executeExit, bool executeFinal)
public NestedStateData(Action<IStateFactory> setup) // executeExit=true, executeFinal=true
```

**암시적 변환:**
```csharp
public static implicit operator NestedStateData(Action<IStateFactory> setup)
```

---

## 검증 규칙 (UNITY_EDITOR / DEBUG)

생성자에서 자동 실행되는 검증:

| 상태 | 규칙 |
|------|------|
| `Statechart` | Initial 상태 필수 |
| `InitialState` | 전이 타겟 필수, 자기 자신 전이 금지, 중복 전이 금지 |
| `FinalState` | 검증 없음 |
| `SimpleState` | 이벤트 전이의 자기 자신 전이 금지 |
| `TransitionState` | 전이 타겟 필수, 자기 자신 전이 금지, 중복 전이 금지 |
| `NestState` | 중첩 설정 1개 필수, 자기 자신 전이 금지, 내부 상태 검증 |
| `SplitState` | 중첩 설정 2개 이상 필수, 자기 자신 전이 금지, 내부 상태 검증 |
| `ChoiceState` | 최소 1개 조건 전이 + 정확히 1개 기본 전이, 자기 자신 전이 금지 |
| `WaitState` | 대기 활동 필수, 전이 타겟 필수, 자기 자신 전이 금지 |
| `TaskWaitState` | Task 액션 필수, 전이 타겟 필수, 자기 자신 전이 금지 |
| `LeaveState` | 전이 타겟 필수, 타겟이 상위 영역 레이어에 있어야 함 |

---

## 실행 흐름 요약

```
1. new Statechart(setup) -> 상태/전이 정의 + 검증
2. statechart.Run() -> Initial 상태에서 시작
3. Initial -> (자동 전이) -> 다음 상태
4. State/Nest/Wait 등에서 대기
5. statechart.Trigger(event) -> 이벤트 매칭 -> 전이 실행
6. 반복 (Final 도달 시 정지)
```

---

## Internal 타입 (참고용)

아래 타입들은 internal이지만 동작 이해에 도움이 됩니다.

### StateInternal (internal abstract class)

모든 상태의 기본 구현. `Id` (uint, 자동 증가), `Name` (string), `RegionLayer` (uint) 프로퍼티를 가짐. `Trigger()` 메서드에서 전이 로직 처리, Enter/Exit 호출 시 예외를 catch하여 `Debug.LogError`로 출력.

### Transition (internal class)

전이 구현. `_onTransition` (액션 리스트), `_condition` (조건 리스트), `TargetState` (대상 상태)를 관리. `CheckCondition()`은 모든 조건이 true일 때만 true 반환.

### WaitActivity (internal class)

`IWaitActivity` 구현. `Complete()` 호출 시 내부 활동이 모두 완료되어야 성공. `Split()`으로 자식 활동 생성 가능. `ForceComplete()`으로 강제 완료.
