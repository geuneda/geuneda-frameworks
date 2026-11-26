---
name: geuneda-adcapture
description: com.geuneda.adcapture 패키지(Geuneda.AdCapture, 에디터 전용)로 광고 영상용 게임 플레이를 촬영 스크립트(JSON)대로 연출·녹화할 때 사용한다. AdCapture.Run/Status/Abort/Register, 촬영 스크립트의 op(wait, waitfor, record, stop, zoom, shake, timescale, hide, show, tap, action), 게임별 동작 등록, 배치 모드 Unity Recorder 녹화를 다룰 때 활성화한다. 광고 기획·편집 흐름은 game-ad-creative 스킬이 맡는다.
---

# Geuneda Ad Capture

에디터 플레이 모드에서 JSON 촬영 스크립트를 한 단계씩 실행해 카메라 줌·흔들림, 시간 배율, HUD 숨기기, 손가락 탭, 게임 동작 호출을 연출하고 Unity Recorder 로 MP4(H.264, 게임 오디오)를 녹화한다. 실행기는 MonoBehaviour 가 아니라 PlayerLoop 의 `PostLateUpdate` 맨 앞에 붙는다. 게임 `LateUpdate` 뒤, 렌더 전에 카메라를 덮어쓴다.

## 패키지 정보

- **패키지**: `com.geuneda.adcapture` (버전은 `package.json` 기준)
- **설치**: `https://github.com/geuneda/geuneda-adcapture.git`
- **의존성**: `com.unity.recorder` 5.1.8, `com.unity.ugui` 2.0.0(레지스트리에서 자동). Geuneda 패키지 의존 없음
- **최소 Unity**: 6000.0
- **어셈블리 / 네임스페이스**: `Geuneda.AdCapture.Editor`(Editor 전용) / `Geuneda.AdCapture`
- **문서**: 패키지 `README.md`(스크립트 필드·op 표)

## 핵심 API

```csharp
public static class AdCapture
{
    public static string State { get; }
    public static void Register(string name, Func<string[], string> action);
    public static string Run(string shotPath);
    public static string Status();
    public static string Abort();
}
```

- `Run` 은 플레이 모드에서만 시작한다. 시작 전에 스크립트 전체를 검사한다(op 이름, 등록된 action, 값 범위, `output` 절대 경로·폴더 존재·기존 파일 없음). 하나라도 틀리면 아무것도 하지 않고 `실패: …` 를 돌려준다.
- `Status` 는 `시작` → `진행: i/n op` → `완료 (녹화 저장: path)`·`실패: steps[i] op: 이유`·`중단: …` 순으로 바뀐다.
- `Register` 의 동작은 `null` 이면 성공, 문자열이면 그 이유로 촬영을 멈춘다. 게임 에디터 어셈블리의 `[InitializeOnLoad]` 정적 생성자에서 등록한다. 도메인 리로드 뒤 다시 등록되도록 이 위치를 지킨다.

## 사용 규칙

- 녹화는 `record`~`stop` 사이만 파일에 들어간다. 게임 상태 준비(action), HUD 숨기기, 팝업 닫기는 `record` 앞에 둔다.
- 녹화 중 게임 시간은 녹화 프레임에 맞춰 흐른다(Recorder `CapFrameRate`). `wait` 등 단계 시간도 같은 기준이다. 실제 시간보다 오래 걸려도 영상 길이는 정확하다.
- 끝날 때(완료·실패·중단·플레이 종료) 카메라·`Time.timeScale`·숨긴 대상을 되돌리고 녹화를 멈춘다.
- 탭은 uGUI 대상에 실제 포인터 Down·Up·Click 을 보낸다. 대상이 꺼져 있으면 실패한다. `waitfor` 로 팝업이 뜬 뒤 탭한다.
- 경로는 씬 루트부터 `/` 로 이은 이름이고 뒤쪽 일부만 맞으면 된다. 같은 경로가 여럿이면 켜진 것을 먼저 쓴다.
- 배치 모드(`-batchmode`, `-nographics` 없음)에서 녹화된다. 실행 중인 다른 에디터를 건드리지 않도록 별도 작업 트리에 에디터를 띄우고 `--project-path` 로 고정한다.
- 실사용자 계정·저장으로 촬영하지 않는다. 게임마다 샌드박스(별도 productName, 새 게스트)를 먼저 준비한다.

## 함정

- 에디터 전용 어셈블리의 MonoBehaviour 는 `AddComponent` 할 수 없다(Unity 가 거부). 확장할 때도 PlayerLoop 콜백을 쓴다.
- 로컬 `file:` 패키지로 시험할 때 배치 모드 에디터는 파일 변경을 자동으로 다시 컴파일하지 않는다. `unity recompile --project-path …` 를 실행한다.
- 손가락 그림의 손끝 위치(`handTip`)는 그림마다 다르다. 첫 테이크의 탭 장면을 정지 화면으로 보고 맞춘다.
