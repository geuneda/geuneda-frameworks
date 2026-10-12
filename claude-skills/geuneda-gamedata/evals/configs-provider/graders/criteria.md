---
type: llm
weight: 1
---

응답의 C# 코드가 아래를 **모두** 만족해야 통과다.

1. `using Geuneda.DataExtensions;` 로 네임스페이스를 가져온다.
2. `new ConfigsProvider()` 를 생성한다.
3. `provider.AddConfigs(item => item.Id, itemConfigs)` 처럼 **ID 리졸버 람다를 첫 인자로** 넘겨 컬렉션을 등록한다.
4. `GetConfig<ItemConfig>(42)` (또는 `TryGetConfig<ItemConfig>(42, out ...)`) 로 ID 조회를 한다.
5. 매 프레임 루프에서 컬렉션을 새로 할당하지 않는다. 다음 중 하나면 통과다.
   - 초기화 시점에 `GetConfigsList<EnemyConfig>()` 로 **한 번만** 캐싱해두고, 매 프레임 루프에서는 캐싱된 `List<EnemyConfig>` 를 `for` 또는 `foreach` 로 순회한다. `List<T>` 의 foreach 는 struct 열거자를 쓰므로 할당이 없다. 요구한 "힙 할당 없음" 을 실제로 만족하는 방식이다.
   - `EnumerateConfigs<EnemyConfig>()` 를 순회한다. 반환 타입이 `IEnumerable<T>` 라 foreach 마다 열거자 박싱 1회가 남는다. 이 점을 함께 언급하면 더 좋지만, 언급이 없어도 통과다.
   - 초기화 시점에 `GetConfigsDictionary<EnemyConfig>()` 결과를 **한 번만** 캐싱해두고 순회한다. 반환 타입이 `IReadOnlyDictionary<int, T>` 라 캐싱한 값(또는 `.Values`)을 foreach 하면 인터페이스로 열거자를 얻으므로 foreach 마다 박싱 1회가 생긴다. `EnumerateConfigs` 와 같은 수준이므로 통과로 본다. 이 방식이 할당이 전혀 없다고 설명하는 것은 부정확하지만 통과 여부에는 영향이 없다.

다음 중 하나라도 해당하면 실패다.
- 매 프레임 루프 **안에서** `GetConfigsList<T>()` 를 호출한다 (호출마다 새 List 를 할당한다).
- `Dictionary`, `ScriptableObject`, LINQ, 직접 만든 저장소 클래스 등으로 ConfigsProvider 를 대체한다.
- `AddConfigs` 에 ID 리졸버를 넘기지 않는다.
