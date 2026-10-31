---
type: llm
weight: 1
---

응답의 C# 코드가 아래를 **모두** 만족해야 통과다.

1. `using Geuneda.Services;` 로 네임스페이스를 가져온다.
2. 메시지 타입이 `IMessage` 를 구현한다 (예: `public struct PlayerDiedMessage : IMessage`).
3. 브로커를 `MainInstaller.Resolve<IMessageBrokerService>()` 로 얻는다.
4. `broker.Subscribe<PlayerDiedMessage>(msg => ...)` 로 구독한다.
5. `broker.Publish(new PlayerDiedMessage { ... })` 로 발행한다.
6. `broker.Unsubscribe<PlayerDiedMessage>(this)` 또는 `broker.UnsubscribeAll(this)` 로 해제한다.

다음 중 하나라도 해당하면 실패다.
- MessagePipe, UniRx, Zenject/VContainer SignalBus, C# `event`, `static Action` 등 Geuneda 외 수단으로 대체한다.
- `MainInstaller` 를 거치지 않고 `new MessageBrokerService()` 를 사용처에서 직접 만들어 쓴다.
- 구독 해제 API 이름이 틀렸다 (`Dispose`, `RemoveListener` 등).
