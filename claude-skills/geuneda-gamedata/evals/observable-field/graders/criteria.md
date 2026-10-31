---
type: llm
weight: 1
---

응답의 C# 코드가 아래를 **모두** 만족해야 통과다.

1. `using Geuneda.DataExtensions;` 로 네임스페이스를 가져온다 (다른 네임스페이스면 실패).
2. `new ObservableField<int>(...)` 로 필드를 생성한다.
3. `.Observe(...)` 콜백으로 변경을 구독하며, 콜백이 이전값과 현재값 두 인자를 받는다 (예: `(prev, curr) =>`).
4. `.Value = 100` 형태로 값을 변경한다.

다음 중 하나라도 해당하면 실패다.
- UniRx, R3, System.Reactive, `ReactiveProperty`, C# `event`, `UnityEvent`, `Action` 직접 구현 등 Geuneda 외 수단으로 대체했다.
- `ObservableField` 대신 존재하지 않는 타입명(`Observable<T>`, `ObservableValue` 등)을 썼다.
- `Observe` 콜백 인자가 1개뿐이거나 시그니처가 다르다.
