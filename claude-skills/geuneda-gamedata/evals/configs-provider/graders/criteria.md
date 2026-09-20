---
type: llm
weight: 1
---

응답의 C# 코드가 아래를 **모두** 만족해야 통과다.

1. `using Geuneda.DataExtensions;` 로 네임스페이스를 가져온다.
2. `new ConfigsProvider()` 를 생성한다.
3. `provider.AddConfigs(item => item.Id, itemConfigs)` 처럼 **ID 리졸버 람다를 첫 인자로** 넘겨 컬렉션을 등록한다.
4. `GetConfig<ItemConfig>(42)` (또는 `TryGetConfig<ItemConfig>(42, out ...)`) 로 ID 조회를 한다.
5. 매 프레임 루프의 힙 할당을 실제로 피한다. 다음 둘 중 하나면 통과다.
   - `EnumerateConfigs<EnemyConfig>()` 를 쓴다. (`IEnumerable<T>` 반환이라 열거자 박싱 1회가 남는다는 점을 함께 언급하면 더 좋지만, 언급이 없어도 통과다.)
   - 초기화 시점에 `GetConfigsList<EnemyConfig>()` 또는 `GetConfigsDictionary<EnemyConfig>()` 로 **한 번만** 캐싱해두고, 매 프레임 루프에서는 캐싱된 구체 타입을 순회한다.

다음 중 하나라도 해당하면 실패다.
- 매 프레임 루프 **안에서** `GetConfigsList<T>()` 를 호출한다 (호출마다 새 List 를 할당한다).
- `Dictionary`, `ScriptableObject`, LINQ, 직접 만든 저장소 클래스 등으로 ConfigsProvider 를 대체한다.
- `AddConfigs` 에 ID 리졸버를 넘기지 않는다.
