# Ad Capture 촬영 스크립트 형식

## 촬영 스크립트

```json
{
  "output": "/abs/path/take01.mp4",
  "width": 1080, "height": 1920, "fps": 60,
  "hand": "Assets/UI/finger.png", "handTip": [0.2, 0.85], "handSize": 0.12,
  "steps": [
    { "op": "action", "name": "game.setup", "args": ["stage", "3"] },
    { "op": "hide", "targets": ["Canvas/TopBar"] },
    { "op": "record" },
    { "op": "wait", "seconds": 1.5 },
    { "op": "waitfor", "target": "Popup/CardA/Button", "seconds": 5 },
    { "op": "tap", "target": "Popup/CardA/Button", "seconds": 0.7 },
    { "op": "zoom", "scale": 1.3, "focus": [0.5, 0.62], "seconds": 0.3 },
    { "op": "shake", "amplitude": 0.02, "seconds": 0.25 },
    { "op": "timescale", "scale": 0.4, "seconds": 0.1 },
    { "op": "stop" }
  ]
}
```

| 필드 | 기본값 | 설명 |
|---|---|---|
| `output` | 없음 | 녹화 파일의 절대 경로(`<` `>` 금지). 같은 폴더의 임시 파일로 녹화한 뒤 이 이름으로 옮깁니다. 이미 있는 파일은 덮어쓰지 않습니다(시작 전 거절, 종료 시 생겼으면 임시 파일을 남기고 실패) |
| `width`·`height`·`fps` | 1080·1920·60 | 짝수 해상도(최대 4096), 1~120 fps. 녹화 중에는 게임 시간이 녹화 프레임에 맞춰 흐릅니다 |
| `mute` | false | true 면 오디오 트랙을 넣지 않습니다 |
| `hand`·`handTip`·`handSize` | 없음·[0.2, 0.85]·0.12 | 탭할 때 보일 손가락 그림의 에셋 경로, 손끝 위치(그림 안 0~1), 화면 높이 대비 크기. 없으면 손가락 없이 탭만 보냅니다 |

| op | 필드 | 동작 |
|---|---|---|
| `wait` | `seconds` | 녹화 시간 기준으로 기다립니다 |
| `waitfor` | `target`, `seconds`(제한, 기본 10) | 경로의 오브젝트가 화면에 보일 때까지 기다립니다(활성, 켜진 Canvas, CanvasGroup 투명도 0 아님) |
| `record` / `stop` | | 녹화를 시작하고 멈춥니다. `record` 는 Recorder 가 첫 프레임을 저장할 때까지(실시간 최대 10초) 기다린 뒤 다음 단계로 갑니다. Recorder 프레임 수를 읽을 수 없거나, 첫 프레임이 오지 않거나, 녹화 중 10초 동안 프레임이 늘지 않으면 실패합니다. 한 스크립트는 한 파일을 녹화합니다. `stop` 이 없으면 끝날 때 멈춥니다. 완료 상태에 Recorder 가 처리한 프레임 수를 적으니 `ffprobe -count_frames` 의 영상 프레임 수와 대조합니다 |
| `zoom` | `scale`, `focus`[x, y], `seconds` | 현재 `Camera.main` 을 기준으로 확대하며 `focus`(화면 0~1) 쪽으로 다가갑니다. `scale` 1 이 원래 화면입니다. 카메라가 바뀌면 새 카메라로 옮겨 붙고, 카메라가 없으면 실패합니다 |
| `shake` | `amplitude`(화면 높이 비율), `seconds` | 줄어드는 흔들림을 시작하고 바로 다음 단계로 넘어갑니다 |
| `timescale` | `scale`, `seconds` | 게임 속도를 부드럽게 바꿉니다(1.5 면 영상에서 1.5배속). 녹화 중에는 프레임 동기화와 함께 적용합니다. 끝나면 원래 값으로 돌아갑니다 |
| `hide` / `show` | `targets` | UI 는 CanvasGroup 투명도로, 월드 오브젝트는 Renderer 로 숨깁니다. 여러 경로가 같은 대상을 가리켜도 마지막 `show` 에서 원래 값으로 돌아옵니다. 끝나면 모두 되돌립니다 |
| `tap` | `target` 또는 `focus`, `seconds` | 손가락이 다가가 누르는 동작을 보여 주고, 누르는 순간 그 좌표의 UI 레이캐스트 결과로 Down·Up·Click 을 보냅니다. `target` 이 다른 UI 에 가려 있거나 비활성이거나 사라졌으면 실패합니다 |
| `action` | `name`, `args` | 게임이 등록한 동작을 부릅니다 |

경로는 씬 루트부터 `/` 로 잇되 뒤쪽 일부만 적어도 됩니다(예: `Popup/CardA/Button`). 같은 경로가 여럿이면 켜진 것을 먼저 고릅니다. 이름이 같은 형제는 `이름[형제 순서]` 로 고릅니다(예: `List/Row(Clone)[1]/UpgradeButton`, 순서는 0부터).

스크립트는 실행 전에 전체를 검사합니다. 알 수 없는 op, 등록되지 않은 action, 범위를 벗어난 값이 하나라도 있으면 아무것도 하지 않고 실패를 돌려줍니다.

