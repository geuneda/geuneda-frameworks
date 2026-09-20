---
type: llm
weight: 1
---

응답의 C# 코드가 아래를 **모두** 만족해야 통과다.

1. `using Geuneda.Services;` 를 포함한다.
2. 풀 서비스 때문에 `using Geuneda.Services.Pooling;` 을 **추가로** 포함한다 (PoolService 는 `Geuneda.Services.Pooling` 네임스페이스에 있다).
3. `MainInstaller.Bind<IMessageBrokerService>(new MessageBrokerService())` 형태로 **인터페이스를 제네릭 인자**로 바인딩한다. `ITickService`, `IPoolService` 도 같은 방식이다.
4. 정리에 `MainInstaller.Clean()` / `Clean<T>()` / `CleanDispose<T>()` 중 하나를 쓴다.

다음 중 하나라도 해당하면 실패다.
- `Geuneda.Services.Pooling` 네임스페이스를 빠뜨렸다.
- Zenject, VContainer, `ServiceLocator`, 직접 만든 싱글톤 등으로 대체한다.
- `MainInstaller.Bind<PoolService>(...)` 처럼 구현 타입을 제네릭 인자로 넘긴다 (인터페이스만 가능).
- 정리 API 이름이 틀렸다 (`Dispose()`, `Unbind<T>()`, `Reset()` 등).
