---
name: geuneda-services
description: Geuneda Services(com.geuneda.services) 패키지로 Unity 코드를 작성하거나 고칠 때 사용한다. MainInstaller/Installer 서비스 바인딩과 해석, IMessageBrokerService 메시지 발행/구독, ITickService 업데이트 구독, ICoroutineService 코루틴, IPoolService/ObjectPool/GameObjectPool 오브젝트 풀, IDataService PlayerPrefs 저장, IRngService 결정론적 난수, ITimeService 시간 조작, CommandService 커맨드, VersionServices 빌드 버전 정보, AssetResolverService/AddressablesAssetLoader Addressables 에셋 로딩, Addressable Ids 생성기와 AssetsConfigsImporter, Services Explorer 창을 다루는 작업이 대상이다. 코드에 using Geuneda.Services 가 있거나 위 타입 이름이 나오면 이 스킬을 쓴다.
---

# Geuneda Services

Unity 게임용 기반 서비스 모음이다. 전체 공개 API 는 [references/api.md](references/api.md) 에 있다.

## 패키지 정보

- 패키지: `com.geuneda.services` (현재 4.0.0), 설치 URL `https://github.com/geuneda/geuneda-services.git`
- Unity 6000.3 이상
- 의존성: `com.geuneda.core` 0.3.0, `com.geuneda.gamedata` 1.0.0, `com.unity.addressables` 1.21.20, `com.cysharp.unitask` 2.5.10. core, gamedata, UniTask 는 Unity 레지스트리에 없으므로 `manifest.json` 에 git URL 로 직접 추가해야 한다.
- 에셋 로딩/임포트는 v2.0.0 에서 예전 `com.geuneda.assetsimporter` 를 흡수한 것이다. `com.geuneda.assetsimporter` 를 따로 추가하지 않는다.

## 네임스페이스 (자주 틀림)

| 네임스페이스 | 타입 |
|--------------|------|
| `Geuneda.Services` | `MainInstaller`, `Installer`, `IInstaller`, `IMessage`, `IMessageBrokerService`, `MessageBrokerService`, `ITickService`, `TickService`, `ICoroutineService`, `CoroutineService`, `IAsyncCoroutine`, `IDataService`, `IDataProvider`, `DataService`, `ITimeService`, `ITimeManipulator`, `TimeService`, `IRngService`, `RngService`, `RngData`, `VersionServices`, **`PoolService`**, **`CommandService<T>`**, **`AssetResolverService`**, `IAssetResolverService`, `IAssetAdderService` |
| `Geuneda.Services.Pooling` | `IPoolService`, `IObjectPool<T>`, `ObjectPool<T>`, `GameObjectPool`, `GameObjectPool<T>`, `IPoolEntitySpawn`, `IPoolEntitySpawn<T>`, `IPoolEntityDespawn`, `IPoolEntityObject<T>` |
| `Geuneda.Services.Commands` | `ICommandService<T>`, `IGameCommand<T>`, `IGameServerCommand<T>`, `IGameCommandBase` |
| `Geuneda.Services.AssetsImporter` | `IAssetLoader`, `ISceneLoader`, `AddressablesAssetLoader`, `AssetConfigsScriptableObject<TId, TAsset>`, `AddressableConfig`, `AssetReferenceScene` |
| `Geuneda.Services.AssetsImporter.Editor` (에디터) | `AssetsConfigsImporter<TId, TAsset, TScriptableObject>` 등 |
| `Geuneda.DataExtensions` (gamedata) | `floatP`, `Pair<TKey, TValue>` |
| `Geuneda.Core` (core) | `AppEnv`(내부 버전의 환경 이름) |

`IPoolService` 를 쓰면 `using Geuneda.Services.Pooling;`, `IGameCommand<T>` 를 쓰면 `using Geuneda.Services.Commands;` 가 추가로 필요하다.

## 사용 패턴

### 부트스트랩과 해석

```csharp
using Geuneda.Services;
using Geuneda.Services.Pooling;
using UnityEngine;

public class GameBootstrap : MonoBehaviour
{
    private void Awake()
    {
        MainInstaller.Bind<IMessageBrokerService>(new MessageBrokerService());
        MainInstaller.Bind<ITickService>(new TickService());
        MainInstaller.Bind<ICoroutineService>(new CoroutineService());
        MainInstaller.Bind<IPoolService>(new PoolService());
        MainInstaller.Bind<IDataService>(new DataService());

        // MainInstaller.Bind 는 인터페이스 하나만 받는다. 같은 인스턴스는 인터페이스마다 바인딩한다
        var time = new TimeService();
        MainInstaller.Bind<ITimeService>(time);
        MainInstaller.Bind<ITimeManipulator>(time);
    }

    private void OnDestroy()
    {
        MainInstaller.CleanDispose<ITickService>();      // Dispose 후 제거
        MainInstaller.CleanDispose<ICoroutineService>();
        MainInstaller.CleanDispose<IPoolService>();
        MainInstaller.Clean();                           // 나머지 바인딩 제거 (Dispose 안 함)
    }
}
```

### 메시지

```csharp
public struct PlayerDiedMessage : IMessage
{
    public int PlayerId;
}

public class DeathHandler : MonoBehaviour
{
    private IMessageBrokerService _broker;

    private void Start()
    {
        _broker = MainInstaller.Resolve<IMessageBrokerService>();
        _broker.Subscribe<PlayerDiedMessage>(msg => HandlePlayerDeath(msg.PlayerId)); // this 를 캡처하는 람다
        _broker.Publish(new PlayerDiedMessage { PlayerId = 1 });
    }

    private void OnDestroy()
    {
        _broker?.Unsubscribe<PlayerDiedMessage>(this);
    }

    private void HandlePlayerDeath(int playerId) { }
}
```

### 틱, 풀, 커맨드

```csharp
var tick = MainInstaller.Resolve<ITickService>();
tick.SubscribeOnUpdate(OnUpdate);                    // 매 프레임, 인자는 경과 시간
tick.SubscribeOnUpdate(OnSlowUpdate, deltaTime: 0.5f); // 최소 0.5초 간격
tick.UnsubscribeAll(this);

var pools = MainInstaller.Resolve<IPoolService>();
pools.AddPool(new GameObjectPool<Bullet>(50, bulletPrefab)); // Bullet : MonoBehaviour
Bullet bullet = pools.Spawn<Bullet>();
pools.Despawn(bullet);

var commands = new CommandService<GameLogic>(gameLogic, MainInstaller.Resolve<IMessageBrokerService>());
commands.ExecuteCommand(new AttackCommand { TargetId = 42 }); // AttackCommand : IGameCommand<GameLogic>
```

### Addressables 에셋

```csharp
using Geuneda.Services;
using Geuneda.Services.AssetsImporter;

public class SpriteConfigs : AssetConfigsScriptableObject<SpriteId, Sprite> { }

// AddConfigs 는 기본 인터페이스 메서드라 IAssetAdderService 타입으로 호출해야 한다
IAssetAdderService resolver = new AssetResolverService();
resolver.AddConfigs(spriteConfigs);
Sprite hero = await resolver.RequestAsset<SpriteId, Sprite>(SpriteId.Hero, instantiate: false);
resolver.UnloadAssets<SpriteId, Sprite>(clearReferences: false);
MainInstaller.Bind<IAssetResolverService>(resolver);
```

## 함정

- **인터페이스만 바인딩**: `MainInstaller.Bind<PoolService>(...)` 처럼 구체 타입을 넘기면 `ArgumentException`. 같은 인터페이스 재바인딩도 `ArgumentException`, 미바인딩 `Resolve` 도 `ArgumentException`(`KeyNotFoundException` 아님). 없을 수 있으면 `TryResolve`.
- **`MainInstaller` 에는 다중 인터페이스 `Bind` 가 없다**. `Bind<T, T1, T2>` / `Bind<T, T1, T2, T3>` 는 `Installer` 인스턴스에만 있고, `T` 는 구현 타입이다.
- **메시지 브로커**: 정적 메서드 구독 불가. 구독자 키가 `action.Target` 이라 같은 객체가 같은 메시지를 다시 구독하면 덮어쓰고, 지역 변수를 캡처한 람다는 `Unsubscribe<T>(this)` 로 안 지워진다. `Publish` 핸들러 안에서 구독/해제하면 `InvalidOperationException` 이므로 `PublishSafe` 를 쓴다. `Unsubscribe<T>()` 를 인자 없이 부르면 그 타입 구독자 전부가 지워진다.
- `TickService` 콜백은 구독 역순으로 불린다. 콜백 안에서 해제해도 다른 구독자가 건너뛰거나 두 번 불리지 않는다. 지금 순회 중인 단계에 새로 구독하면 그 단계의 다음 순회부터 불리고, 다른 단계(예: Update 콜백에서 LateUpdate)에 구독하면 같은 프레임에도 불릴 수 있다. 콜백 예외는 로그로 남기고 나머지 구독자를 계속 부른다(v3.0.0).
- **`TickService` / `CoroutineService`** 는 생성자에서 `DontDestroyOnLoad` GameObject 를 만든다. 런타임에 만들고 `Dispose()`(또는 `CleanDispose<T>()`)로 정리한다. `MainInstaller.Clean()` 은 Dispose 하지 않는다.
- `MainInstaller` 는 플레이 세션 시작(`SubsystemRegistration`)에 바인딩을 비운다. 도메인 리로드를 꺼도 이전 세션 바인딩이 남지 않지만, 그 시점에 바인딩하면 지워질 수 있으니 `AfterAssembliesLoaded` 이후에 바인딩한다(v3.0.0).
- **FixedUpdate 콜백 인자**는 경과 시간이 아니라 `Time.fixedTime` 이다.
- **`IAsyncCoroutine.OnComplete`** 는 교체 방식이다. `StopCoroutine(triggerOnComplete)` 기본값은 `false`(콜백 없음). 서비스의 `StopAllCoroutines()` 는 핸들을 완료 처리하지 않는다.
- **풀**: 타입당 풀 1개(중복 `AddPool` 은 `ArgumentException`). `GameObjectPool` 계열은 훅을 `GetComponent` 로 찾으므로 훅 인터페이스는 컴포넌트에 구현한다. `Spawn(data)` 는 `OnSpawn()` 과 `OnSpawn(data)` 를 둘 다 호출한다. `GameObjectPool.Dispose(bool)` 는 인자가 `true` 일 때만 샘플을 `Object.Destroy` 한다(v2.1.4 부터. 이전 버전은 인자와 관계없이 파괴). 대기 중인 항목이 풀 밖에서 파괴되면 `Spawn` 이 그 항목을 건너뛰고, 인스턴시에이터가 null 이나 파괴된 객체를 돌려주면 재시도 없이 `InvalidOperationException` 을 던진다(v3.0.0. v2.1.4 까지는 파괴된 항목에서 `MissingReferenceException`, null 을 돌려주는 인스턴시에이터에서 무한 루프).
- **`DataService`**: 참조 타입만, `PlayerPrefs` 키는 `typeof(T).FullName`, 값은 `{"version":n,"data":{...}}` 봉투(`[DataVersion(n)]`, 마이그레이션은 `AddMigration<T>`). `LoadData<T>` 는 매개변수 없는 생성자 필요, 저장값을 읽지 못하면 예외 대신 `{키}.corrupt` 에 원문을 남기고 새 인스턴스로 시작한다. 더 새 버전 세이브를 읽은 타입은 `AddOrReplaceData` 로 교체하기 전까지 저장하지 않는다. `GetData<T>` 는 없으면 `KeyNotFoundException`. 이전 버전(2.x) 세이브는 읽지 않는다(v3.0.0, 호환되지 않는 변경).
- **`RngService`**: v4.0.0 부터 core 의 `Pcg32`(PCG32)를 쓴다. 상태는 `RngData`(`Seed`, `Stream`, `Count` 모두 `ulong`)이고 서비스가 `Count` 를 직접 바꾼다(필드를 바깥에서 바꾸면 다음 호출부터 반영). `Count` 는 호출 수가 아니라 쓴 32비트 출력 수. `Range(int, int)` 는 max 미포함, `Range(floatP, floatP)` 는 max 포함이고 `maxInclusive` 로 바꾸면 max 도 나온다. 잘못된 범위는 `ArgumentOutOfRangeException`(상태 그대로). 스트림이 여러 개 필요하면 스트림마다 `RngData`/`RngService` 를 만든다. `Restore(count)` 는 O(log n). v3.x 이하와 수열·`RngData` 형식이 달라 이전 리플레이와 호환되지 않는다.
- **`VersionServices`** 는 `SubsystemRegistration` 에서 자동 로드되므로 `LoadVersionData()` 를 부를 필요가 없다. `version-data` 리소스가 없으면 예외 없이 `Application.version` / 빈 문자열로 폴백하고 `Debug.LogError` 를 남긴다(지연 로드는 한 번만 시도). git 저장소가 아닌 프로젝트에서는 `Branch` / `Commit` 이 빈 문자열이다. `IsOutdatedVersion` 은 `Major[.Minor[.Patch]]` 와 접미사(`-rc`, `+42`)를 받고, 읽을 수 없으면 경고 후 `false` 다. `VersionInternal` 끝의 환경 이름은 core 의 `AppEnv.Name`(`dev`/`qa`/`prod`, 컴파일 define 으로 정해짐)이고 `version-data` 에는 쓰지 않는다(`VersionData.BuildType` 없음, v3.0.0). 플레이어 빌드 직전 훅이 빌드 대상의 빌드 번호(Android 는 `bundleVersionCode`)를 쓰고, 빌드가 끝나면(실패·취소 포함) 활성 타깃 값으로 되돌린다.
- **`AssetResolverService`**: `AddConfigs` 는 `IAssetAdderService` 로만 호출된다(`AssetResolverService` 변수로 호출하면 CS1061). 등록 전 `RequestAsset` / `LoadSceneAsync<TId>` 는 `MissingMemberException`. `RequestAsset` 의 `instantiate` 기본값이 `true` 라 `GameObject` 는 인스턴스가 만들어진다. 씬은 에셋 타입 `UnityEngine.SceneManagement.Scene` 으로 등록한다.
- **`AddressablesAssetLoader.UnloadAsset`** 은 동기 `void` 이며 참조 카운트만 줄인다. 메모리 회수는 호출자가 `Resources.UnloadUnusedAssets()` 로 한다.
- **Services Explorer**(`Tools > Geuneda > Services Explorer`)는 `MainInstaller` 에 인터페이스로 바인딩된 서비스만 보여 준다.
