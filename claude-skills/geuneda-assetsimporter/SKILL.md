---
name: geuneda-assetsimporter
description: Unity Addressables 기반 에셋 로딩/관리 패키지. Unity 프로젝트에서 Addressables 에셋의 로드, 인스턴스화, 언로드, 씬 관리, 에셋 설정 임포트 관련 코드를 작성하거나 수정할 때 사용한다.
---

# Geuneda AssetsImporter

Unity Addressables의 에셋 로딩 기능을 확장하는 패키지이다. 에셋 임포트 파이프라인을 확장하여 게임 내 모든 에셋의 약한 참조(weak link)를 타입별로 분리된 여러 ScriptableObject에 포함할 수 있다. Addressable 에셋 정보 자동 생성, 타입별 에셋 분류, 비동기 에셋/씬 로딩을 지원한다.

## 활성화 시점

- Addressables 에셋 로딩/언로딩 코드를 작성할 때
- 씬을 Addressables로 비동기 로드/언로드할 때
- AssetResolverService를 통해 에셋을 관리할 때
- 에셋 설정 ScriptableObject (AssetConfigsScriptableObject)를 생성하거나 확장할 때
- Addressable ID 생성기를 사용하거나 커스터마이즈할 때
- 커스텀 에셋 임포터를 작성할 때

## 패키지 정보

- **런타임 네임스페이스**: `Geuneda.AssetsImporter`
- **에디터 네임스페이스**: `GeunedaEditor.AssetsImporter`
- **설치**: `https://github.com/geuneda/geuneda-assetsimporter.git`
- **Unity 버전**: 6000.0 이상
- **의존성**:
  - `com.unity.addressables` (1.21.20)
  - `com.geuneda.gamedata` (1.0.0)
  - `com.cysharp.unitask` (2.5.10)

## 핵심 API

### IAssetLoader (인터페이스)

에셋 로딩 방식을 객체 참조로 래핑하는 인터페이스.

```csharp
UniTask<T> LoadAssetAsync<T>(object key, Action<T> onCompleteCallback = null);
UniTask<GameObject> InstantiateAsync(object key, Transform parent, bool instantiateInWorldSpace, Action<GameObject> onCompleteCallback = null);
UniTask<GameObject> InstantiateAsync(object key, Vector3 position, Quaternion rotation, Transform parent, Action<GameObject> onCompleteCallback = null);
UniTask UnloadAssetAsync<T>(T asset, Action onCompleteCallback = null);
```

### ISceneLoader (인터페이스)

씬 로딩 방식을 객체 참조로 래핑하는 인터페이스.

```csharp
UniTask<Scene> LoadSceneAsync(string path, LoadSceneMode loadMode = LoadSceneMode.Single, bool activateOnLoad = true, Action<Scene> onCompleteCallback = null);
UniTask UnloadSceneAsync(Scene scene, Action onCompleteCallback = null);
```

### AddressablesAssetLoader (클래스)

`IAssetLoader`와 `ISceneLoader`를 구현하는 Addressables 기반 로더.

### IAssetResolverService (인터페이스)

프로젝트 커스텀 요구사항에 따라 에셋 로드 동작을 확장하는 서비스.

```csharp
UniTask<TAsset> RequestAsset<TId, TAsset>(TId id, ...);
UniTask<TAsset> RequestAsset<TId, TAsset, TData>(TId id, TData data, ...);
UniTask<SceneInstance> LoadSceneAsync<TId>(TId id, ...);
UniTask<List<Pair<TId, TAsset>>> LoadAllAssets<TId, TAsset>(...);
UniTask UnloadSceneAsync<TId>(TId id, ...);
void UnloadAssets<TId, TAsset>(bool clearReferences);
void UnloadAssets<TId, TAsset>(bool clearReferences, AssetConfigsScriptableObject<TId, TAsset> assetConfigs);
void UnloadAssets<TId, TAsset>(bool clearReferences, params TId[] ids);
```

### IAssetAdderService (인터페이스)

서비스에 에셋 참조를 추가하는 인터페이스. `IAssetResolverService`를 상속.

```csharp
void AddConfigs<TId, TAsset>(AssetConfigsScriptableObject<TId, TAsset> configs);
void AddAssets<TId>(Type assetType, List<Pair<TId, AssetReference>> assets);
void AddAsset<TId>(Type assetType, TId id, AssetReference assetReference);
void AddDebugConfigs(Sprite errorSprite = null, GameObject errorCube = null, Material errorMaterial = null, AudioClip errorClip = null);
```

### AssetResolverService (클래스)

`IAssetAdderService`를 구현하는 핵심 서비스 클래스. `AddressablesAssetLoader`를 상속하여 에셋 맵 기반으로 타입별 에셋 관리를 수행한다.

### AssetConfigsScriptableObject (추상 클래스)

에셋 설정의 기본 ScriptableObject. `AssetType`과 `AssetsFolderPath`를 제공.

### AssetConfigsScriptableObject\<TId, TAsset\> (추상 제네릭 클래스)

타입별 에셋 설정 ScriptableObject. `TId`를 식별자, `TAsset`을 에셋 타입으로 사용.

### AddressableConfig (클래스)

Addressable 에셋의 설정 정보를 담는 클래스. Id, Address, Path, AssetType, Labels를 포함.

### AssetReferenceScene (클래스)

씬 전용 `AssetReference` 구현.

## 사용 패턴

### 에셋 로드 및 인스턴스화

```csharp
// AssetResolverService를 통한 에셋 요청
var service = new AssetResolverService();
service.AddConfigs(spriteConfigs); // ScriptableObject에서 설정 추가

// ID로 에셋 요청
var sprite = await service.RequestAsset<MySpriteId, Sprite>(
    MySpriteId.PlayerIcon,
    loadAsynchronously: true,
    instantiate: false
);

// 씬 로드
var sceneInstance = await service.LoadSceneAsync<MySceneId>(
    MySceneId.GameScene,
    LoadSceneMode.Single,
    activateOnLoad: true,
    setActive: true
);
```

### 커스텀 에셋 설정 ScriptableObject 정의

```csharp
// 1. enum ID 정의
public enum SpriteId { PlayerIcon, EnemyIcon, ItemIcon }

// 2. ScriptableObject 정의
public class SpriteConfigs : AssetConfigsScriptableObject<SpriteId, Sprite> { }

// 3. 에디터 임포터 정의
public class SpriteConfigsImporter : AssetsConfigsImporter<SpriteId, Sprite, SpriteConfigs> { }
```

### 직접 Addressables 로딩

```csharp
var loader = new AddressablesAssetLoader();

// 에셋 로드
var prefab = await loader.LoadAssetAsync<GameObject>("prefabs/player");

// 프리팹 인스턴스화
var instance = await loader.InstantiateAsync(
    "prefabs/player", parent, false
);

// 에셋 언로드
await loader.UnloadAssetAsync(prefab);
```

### 에디터에서 Addressable ID 생성

Unity 메뉴 `Tools > AddressableIds Generator > Generate AddressableIds`를 사용하여 enum, config lookup 코드를 자동 생성한다. `AddressablesIdGeneratorSettings` ScriptableObject로 파일명, 네임스페이스, 레이블을 설정할 수 있다.

## 주의사항

- UniTask 의존성이 필수이므로 프로젝트에 `com.cysharp.unitask` 패키지가 설치되어 있어야 한다
- `com.geuneda.gamedata` 패키지의 `Pair<TKey, TValue>` 및 `IPairConfigsContainer` 타입을 사용한다
- `UnloadAssetAsync`는 내부적으로 `GC.Collect()`와 `Resources.UnloadUnusedAssets()`를 호출하므로 빈번한 호출을 피해야 한다
- `AssetResolverService`의 `RequestAsset`에서 `instantiate: true`일 경우 GameObject와 Material은 복제본을 반환한다
- 에디터 전용 코드(`AddressableIdsGenerator`, `AssetsToolImporter` 등)는 런타임에서 사용할 수 없다
- Addressable ID 생성기는 자동 생성 코드를 덮어쓰므로 생성된 파일을 수동 편집하지 않아야 한다

## 참조 문서

상세 API 문서는 `references/api.md` 참조.
