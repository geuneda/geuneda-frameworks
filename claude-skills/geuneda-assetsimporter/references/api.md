# Geuneda AssetsImporter API Reference

## Runtime API

네임스페이스: `Geuneda.AssetsImporter`

---

### IAssetLoader (인터페이스)

에셋 로딩 방식을 객체 참조로 래핑하는 인터페이스.

#### 메서드

| 메서드 | 반환 타입 | 설명 |
|--------|-----------|------|
| `LoadAssetAsync<T>(object key, Action<T> onCompleteCallback = null)` | `UniTask<T>` | 주어진 key에서 지정된 타입 T의 에셋을 비동기 로드 |
| `InstantiateAsync(object key, Transform parent, bool instantiateInWorldSpace, Action<GameObject> onCompleteCallback = null)` | `UniTask<GameObject>` | 프리팹을 부모 Transform 기준으로 로드 및 인스턴스화 |
| `InstantiateAsync(object key, Vector3 position, Quaternion rotation, Transform parent, Action<GameObject> onCompleteCallback = null)` | `UniTask<GameObject>` | 프리팹을 위치/회전값 기준으로 로드 및 인스턴스화 |
| `UnloadAssetAsync<T>(T asset, Action onCompleteCallback = null)` | `UniTask` | 에셋을 메모리에서 언로드. GameObject인 경우 파괴도 수행 |

---

### ISceneLoader (인터페이스)

씬 로딩 방식을 객체 참조로 래핑하는 인터페이스.

#### 메서드

| 메서드 | 반환 타입 | 설명 |
|--------|-----------|------|
| `LoadSceneAsync(string path, LoadSceneMode loadMode = LoadSceneMode.Single, bool activateOnLoad = true, Action<Scene> onCompleteCallback = null)` | `UniTask<Scene>` | 씬을 비동기 로드 |
| `UnloadSceneAsync(Scene scene, Action onCompleteCallback = null)` | `UniTask` | 씬을 메모리에서 언로드 |

---

### AddressablesAssetLoader (클래스)

Addressables와 함께 사용하는 에셋 로더. `IAssetLoader`와 `ISceneLoader`를 구현한다.

- 상속: `IAssetLoader`, `ISceneLoader`
- `LoadAssetAsync<T>`: `Addressables.LoadAssetAsync<T>(key)`를 사용하여 에셋 로드
- `InstantiateAsync`: `Addressables.InstantiateAsync(key, instantiateParameters)`를 사용
- `UnloadAssetAsync<T>`: `Addressables.Release(asset)` 후 `GC.Collect()`, `Resources.UnloadUnusedAssets()` 실행
- `LoadSceneAsync`: `Addressables.LoadSceneAsync(path, loadMode, activateOnLoad)` 사용
- `UnloadSceneAsync`: `SceneManager.UnloadSceneAsync(scene)` 사용

---

### IAssetResolverService (인터페이스)

프로젝트 커스텀 요구사항에 따라 에셋 로드 동작을 확장하는 서비스. `IAssetLoader`와 `ISceneLoader`를 상속한다.

#### 메서드

| 메서드 | 반환 타입 | 설명 |
|--------|-----------|------|
| `RequestAsset<TId, TAsset>(TId id, bool loadAsynchronously = true, bool instantiate = true, Action<TId, TAsset, bool> onLoadCallback = null)` | `UniTask<TAsset>` | ID로 에셋 요청. TAsset은 UnityEngine.Object 제약 |
| `RequestAsset<TId, TAsset, TData>(TId id, TData data, bool loadAsynchronously = true, bool instantiate = true, Action<TId, TAsset, TData, bool> onLoadCallback = null)` | `UniTask<TAsset>` | 추가 데이터를 콜백에 전달하는 에셋 요청 |
| `LoadSceneAsync<TId>(TId id, LoadSceneMode loadMode = LoadSceneMode.Single, bool activateOnLoad = true, bool setActive = true, Action<TId, SceneInstance> onLoadCallback = null)` | `UniTask<SceneInstance>` | ID로 매핑된 씬을 비동기 로드 |
| `LoadAllAssets<TId, TAsset>(bool loadAsynchronously = true, Action<TId, TAsset> onLoadCallback = null)` | `UniTask<List<Pair<TId, TAsset>>>` | 이전에 추가된 모든 에셋을 로드 |
| `UnloadSceneAsync<TId>(TId id, Action<TId> onUnloadCallback = null)` | `UniTask` | ID로 매핑된 씬을 비동기 언로드 |
| `UnloadAssets<TId, TAsset>(bool clearReferences)` | `void` | 지정된 타입의 모든 에셋 참조 언로드 |
| `UnloadAssets<TId, TAsset>(bool clearReferences, AssetConfigsScriptableObject<TId, TAsset> assetConfigs)` | `void` | 특정 설정의 에셋 참조 언로드 |
| `UnloadAssets<TId, TAsset>(bool clearReferences, params TId[] ids)` | `void` | 특정 ID의 에셋 참조 언로드 |

---

### IAssetAdderService (인터페이스)

서비스에 새로운 에셋 참조를 추가하는 인터페이스. `IAssetResolverService`를 상속한다.

#### 메서드

| 메서드 | 반환 타입 | 설명 |
|--------|-----------|------|
| `AddConfigs<TId, TAsset>(AssetConfigsScriptableObject<TId, TAsset> configs)` | `void` | ScriptableObject에서 에셋 설정을 추가 |
| `AddAssets<TId>(Type assetType, List<Pair<TId, AssetReference>> assets)` | `void` | 에셋 참조 목록을 추가 |
| `AddAsset<TId>(Type assetType, TId id, AssetReference assetReference)` | `void` | 단일 에셋 참조를 추가 |
| `AddDebugConfigs(Sprite errorSprite = null, GameObject errorCube = null, Material errorMaterial = null, AudioClip errorClip = null)` | `void` | 오류 발생 시 사용할 디버그 에셋 추가 |

---

### AssetResolverService (클래스)

`IAssetAdderService`를 구현하는 핵심 서비스 클래스.

- 상속: `AddressablesAssetLoader`, `IAssetAdderService`
- 내부적으로 `Dictionary<Type, IDictionary<Type, IDictionary>>` 구조의 에셋 맵을 사용
- `RequestAsset`에서 `instantiate: true`일 경우:
  - `GameObject`: `Object.Instantiate()`로 복제본 반환
  - `Material`: `new Material()`로 복제본 반환
  - `Sprite`, `AudioClip`: 원본 반환
- 디버그 에셋(`_errorSprite`, `_errorCube`, `_errorMaterial`, `_errorClip`)은 로딩 실패 시 폴백으로 사용

---

### AddressableConfig (클래스)

Addressable 에셋의 설정 정보를 담는 클래스.

#### 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `Id` | `int` | AddressableId의 정수 표현 |
| `Address` | `string` | Addressable 주소 |
| `Path` | `string` | 에셋 경로 |
| `AssetFileType` | `string` | 에셋 파일 확장자 |
| `AssetType` | `Type` | 에셋의 타입 |
| `Labels` | `ReadOnlyCollection<string>` | 레이블 목록 |

#### 생성자

```csharp
AddressableConfig(int id, string address, string path, Type assetType, string[] labels)
```

#### 메서드

| 메서드 | 반환 타입 | 설명 |
|--------|-----------|------|
| `GetSceneName()` | `string` | 씬 설정인 경우 씬 이름 반환. 씬이 아닌 경우 InvalidOperationException 발생 |

---

### AddressableConfigComparer (클래스)

`IEqualityComparer<AddressableConfig>` 구현. Dictionary에서 박싱을 방지한다.

---

### AssetReferenceScene (클래스)

씬 전용 `AssetReference` 구현.

- 상속: `AssetReference`
- 생성자: `AssetReferenceScene(string guid)`
- `ValidateAsset(Object obj)`: 에디터에서 SceneAsset 타입 검증
- `ValidateAsset(string path)`: 에디터에서 경로 기반 SceneAsset 타입 검증

---

### AssetConfigsScriptableObject (추상 클래스)

에셋 설정 ScriptableObject의 기본 클래스.

#### 프로퍼티

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `AssetType` | `Type` (abstract) | 설정된 에셋의 타입 |
| `AssetsFolderPath` | `string` | 에셋 폴더 경로 (get/set) |

---

### AssetConfigsScriptableObjectBase\<TId, TAsset\> (추상 제네릭 클래스)

- 상속: `AssetConfigsScriptableObject`, `IPairConfigsContainer<TId, TAsset>`, `ISerializationCallbackReceiver`

#### 프로퍼티

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `Configs` | `List<Pair<TId, TAsset>>` | 에셋 설정 목록 (get/set) |
| `ConfigsDictionary` | `IReadOnlyDictionary<TId, TAsset>` | 읽기 전용 딕셔너리 형태의 설정 |

---

### AssetConfigsScriptableObject\<TId, TAsset\> (추상 제네릭 클래스)

- 상속: `AssetConfigsScriptableObjectBase<TId, AssetReference>`
- `AssetType`은 `typeof(TAsset)`을 반환

---

### AssetLoaderUtils (정적 클래스)

로딩 메서드를 위한 유틸리티 헬퍼 클래스.

#### 메서드

| 메서드 | 반환 타입 | 설명 |
|--------|-----------|------|
| `Interleaved<T>(IEnumerable<Task<T>> tasks)` | `Task<Task<T>>[]` | 태스크 목록을 순회하며 먼저 완료된 태스크부터 반환 |

---

## Editor API

네임스페이스: `GeunedaEditor.AssetsImporter`

---

### IAssetConfigsImporter (인터페이스)

에셋 임포터의 기본 인터페이스.

#### 프로퍼티

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `ScriptableObjectType` | `Type` | 저장될 ScriptableObject의 타입 |

#### 메서드

| 메서드 | 반환 타입 | 설명 |
|--------|-----------|------|
| `Import(string assetsFolderPath = null)` | `void` | 에셋 설정 범위의 모든 에셋을 임포트 |

---

### IAssetConfigsGeneratorImporter (인터페이스)

에셋 설정 데이터를 생성하는 임포터 인터페이스. `IAssetConfigsImporter`를 상속한다.

#### 프로퍼티

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `TIdName` | `string` | 식별자 타입의 이름 |
| `TScriptableObjectName` | `string` | ScriptableObject 타입의 이름 |
| `CacheScriptAsOld` | `bool` | 생성된 스크립트를 캐시할지 여부 |

---

### AssetsConfigsImporter\<TId, TAsset, TScriptableObject\> (추상 클래스)

에셋 설정 임포터의 기본 구현. `TId`는 `Enum` 제약 조건.

- 상속: `AssetsConfigsImporterBase<TId, TAsset, TScriptableObject>`
- `Ids`는 `Enum.GetValues(typeof(TId))`를 사용하여 자동 생성

---

### AssetsConfigsImporterBase\<TId, TAsset, TScriptableObject\> (추상 클래스)

에셋 임포터의 기본 구현.

- 제약 조건: `TScriptableObject : AssetConfigsScriptableObject<TId, TAsset>`

#### 프로퍼티

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `ScriptableObjectType` | `Type` | `typeof(TScriptableObject)` |
| `AssetType` | `Type` (virtual) | `typeof(TAsset)` |
| `Ids` | `TId[]` (abstract, protected) | 임포트 대상 식별자 배열 |

#### 메서드

| 메서드 | 반환 타입 | 설명 |
|--------|-----------|------|
| `Import(string assetsFolderPath = null)` | `void` | 에셋 폴더에서 에셋을 검색하고 ScriptableObject에 저장 |
| `IdPattern(TId id)` (protected, virtual) | `string` | ID를 문자열 패턴으로 변환 (기본: `id.ToString()`) |
| `OnImportIds(TScriptableObject, List<string>, List<string>)` (protected, virtual) | `List<Pair<TId, AssetReference>>` | ID별 에셋 참조 매핑 |
| `IndexOfId(string id, IList<string> assetsPath)` (protected) | `int` | 에셋 경로에서 ID 인덱스 검색 |
| `OnImportComplete(TScriptableObject)` (protected, virtual) | `void` | 임포트 완료 후 콜백 |

---

### AssetsConfigsGeneratorImporter\<TAsset\> (추상 클래스)

코드 생성 기능을 포함한 에셋 임포터. enum ID, ScriptableObject, Importer 스크립트를 자동 생성한다.

#### 프로퍼티

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `TIdName` | `string` (abstract) | 생성될 ID enum 이름 |
| `TScriptableObjectName` | `string` (abstract) | 생성될 ScriptableObject 클래스 이름 |
| `CacheScriptAsOld` | `bool` (virtual) | 이전 스크립트 캐시 여부 (기본: true) |

---

### AddressablesIdGeneratorSettings (ScriptableObject)

Addressable ID 생성기 설정.

- CreateAssetMenu: `ScriptableObjects/Editor/AddressablesIdGenerator`

#### 필드

| 필드 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `ScriptFilename` | `string` | `"AddressableId"` | 생성될 스크립트 파일명 |
| `Namespace` | `string` | `"Game.Ids"` | 생성될 스크립트 네임스페이스 |
| `AddressableLabel` | `string` | `"GenerateIds"` | ID 생성 대상 Addressable 레이블 (빈 값 = 모든 항목) |

#### 메서드

| 메서드 | 반환 타입 | 설명 |
|--------|-----------|------|
| `SelectSheetImporter()` (static) | `AddressablesIdGeneratorSettings` | 설정 에셋 선택 또는 생성 |

---

### AddressablesIdGeneratorSettingsEditor (CustomEditor)

`AddressablesIdGeneratorSettings`의 커스텀 인스펙터.

#### 메뉴

- `Tools/AddressableIds Generator/Generate AddressableIds`: Addressable ID 코드 자동 생성
- `Tools/AddressableIds Generator/Select Settings.asset`: 설정 에셋 선택

#### 자동 생성 코드 구조

생성되는 파일에는 다음이 포함된다:
- `{ScriptFilename}` enum: 모든 Addressable 에셋의 열거형
- `AddressableLabel` enum: 레이블 열거형
- `AddressablePathLookup` static class: 에셋 경로 상수
- `AddressableConfigLookup` static class: 설정 조회 메서드 및 맵

---

### AssetsImporter (ScriptableObject)

에셋 데이터 임포트 도구.

- CreateAssetMenu: `ScriptableObjects/Editor/AssetsImporter`

#### 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `AutoUpdateOnRefresh` | `bool` (static) | 스크립트 컴파일 후 자동 임포트 여부 |

---

### AssetsToolImporter (CustomEditor)

`AssetsImporter`의 커스텀 인스펙터. 모든 `IAssetConfigsImporter` 구현체를 검색하고 관리한다.

#### 메뉴

- `Tools/Assets Importer/Select AssetsImporter.asset`: 임포터 에셋 선택
- `Tools/Assets Importer/Get All Importers`: 모든 임포터 갱신
- `Tools/Assets Importer/Import Assets Data`: 모든 에셋 데이터 임포트
- `Tools/Assets Importer/Toggle Auto Import On Refresh`: 자동 임포트 토글
