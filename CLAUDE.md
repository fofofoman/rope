# PULL PANIC! — 프로젝트 명세

- 게임 표기명: **PULL PANIC!**
- 코드/파일/레포 식별자: `PullPanic` (공백·특수문자 없이)

양손 멀티태스킹 줄다리기 Roblox 게임. 1인 개발.
이 파일은 프로젝트 루트용 명세이며, 전역 `~/.claude/CLAUDE.md` 규칙 위에 추가로 적용된다.

> **인코딩 예외:** 이 프로젝트의 모든 파일은 **UTF-8**이다. 전역 규칙의 EUC-KR 보존 규칙은 이 프로젝트에 적용하지 않는다.

---

## 1. 게임 컨셉

- **한 줄 요약:** 왼손으로 연타해서 줄을 당기고, 오른손으로 수시로 뜨는 짧은 퍼즐을 풀어 버프를 얻는 줄다리기.
- **핵심 재미:** 양손이 서로 다른 일을 동시에 해야 하는 **주의력 분할**. "퍼즐에 신경 쓸까, 연타에 집중할까"라는 순간 판단.
- **차별점:** 기존 로블록스 줄다리기 게임은 훈련/펫 수집형(시뮬레이터)이거나 단순 QTE형이다. 이 게임의 정체성은 **연타 + 퍼즐 동시 진행**이며, 모든 기능은 이 경험을 강화하는 방향으로만 추가한다.
- **플랫폼:** PC + 모바일(가로 모드). 콘솔은 범위 밖.

---

## 2. 핵심 규칙

### 2.1 경기
- 줄 위치 `RopePosition`: -100(팀 B 승리) ~ +100(팀 A 승리), 시작값 0.
- 한쪽 끝에 도달하면 즉시 승리. 제한 시간(기본 45초) 종료 시 줄이 넘어간 쪽 승리, 정확히 0이면 무승부.
- 매 프레임 줄 이동량:
  `delta = (teamForceA - teamForceB) * ROPE_SPEED * dt`
- 팀 힘 = 팀원 각자의 유효 힘의 합. 인원이 부족하면 빈자리는 봇으로 채운다(팀 인원 항상 동일).

### 2.2 왼손 — 연타 (Mash)
- 입력: PC `Space`, 모바일 화면 왼쪽의 큰 연타 버튼.
- 개인 유효 힘 = `effectiveTps(rawTps) * buffMultiplier * stunFactor`
- `effectiveTps`는 **체감 곡선**을 적용한다(PC 키보드와 모바일 터치의 최고 속도 차이를 줄이기 위함):
  - `rawTps <= SOFT_CAP` → 그대로
  - 초과분은 `OVER_CAP_RATIO`만 반영
  - `MAX_TAPS_PER_SEC` 초과 입력은 서버에서 버림

### 2.3 왼손 — 액션 (QTE)
- 연타 중 일정 간격으로 지시가 뜬다. 종류: `SwipeUp`, `SwipeDown`, `SwipeBack`(자기 진영 쪽으로 밀기).
- 입력: 모바일은 왼쪽 영역에서 스와이프, PC는 `W` / `S` / `A`.
- 모바일에서 탭과 스와이프 구분: 터치 이동 거리가 `SWIPE_MIN_DISTANCE` 이상이면 스와이프, 미만이면 연타 탭.
- 제한 시간 안에 성공하면 줄을 즉시 `QTE_SUCCESS_PULL`만큼 당긴다. 실패하거나 무시하면 `QTE_FAIL_STUN`초 동안 연타 무효("미끄러짐").

### 2.4 오른손 — 퍼즐
- `PUZZLE_INTERVAL` 범위 안에서 랜덤 간격으로 화면 오른쪽 패널에 등장하며, 제한 시간은 `PUZZLE_TIMEOUT`.
- 3~5초 안에 풀리는 난이도가 기준이다. 길고 어려운 퍼즐은 만들지 않는다.
- 퍼즐 종류마다 보상 타입을 지정한다:
  - `Buff`: `BUFF_DURATION`초 동안 힘 × `BUFF_MULT`
  - `InstantPull`: 줄을 즉시 `INSTANT_PULL`만큼 당김
- 실패나 시간 초과는 보상 없음(페널티 없음).
- 퍼즐이 떠 있는 동안 연타 효율 배수는 `PUZZLE_ACTIVE_MASH_MULT`(기본 1.0, 밸런스 테스트로 조정).
- **퍼즐 목록**
  | 종류 | 설명 | 보상 | 단계 |
  |---|---|---|---|
  | `ArrowSequence` | 화살표 4~6개를 순서대로 입력 | Buff | Phase 1 |
  | `NumberOrder` | 흩어진 1~6을 순서대로 탭 | InstantPull | Phase 2 |
  | `ColorMatch` | 제시된 색과 같은 타일 탭 | InstantPull | Phase 2 |
  | `MiniMaze` | 5×5 미로를 드래그로 통과 | Buff | Phase 2 |

---

## 3. 아키텍처

### 3.1 개발 환경
- **Rojo** 기반 파일 동기화 (Studio ↔ 로컬 파일). Claude Code는 로컬 파일만 수정한다.
- 언어: Luau. 모든 스크립트 첫 줄은 `--!strict`.
- 외부 라이브러리(Wally 패키지 등)는 **요청 없이 추가하지 않는다.**

### 3.2 폴더 구조
```
default.project.json
src/
  shared/                     → ReplicatedStorage.Shared
    Config.luau               -- 모든 밸런스 상수 (매직 넘버 금지)
    Types.luau                -- 공용 타입 정의
    Remotes.luau              -- Remote 참조 헬퍼 (WaitForChild 래핑)
  server/                     → ServerScriptService.Server
    Main.server.luau          -- 진입점, 서비스 초기화
    MatchService.luau         -- 경기 생성/진행/종료, Match 객체 관리
    Match.luau                -- 경기 1개의 상태 (클래스)
    MashService.luau          -- 연타 배치 수신, 검증, 유효 힘 계산
    QteService.luau           -- QTE 발행/검증
    PuzzleService.luau        -- 퍼즐 발행/검증/보상
    Puzzles/                  -- 퍼즐 정의 (서버 전용)
      ArrowSequence.luau
    BotService.luau           -- 봇 = 가상 플레이어
  client/                     → StarterPlayer.StarterPlayerScripts.Client
    Main.client.luau
    MashController.luau
    QteController.luau
    PuzzleController.luau
    PuzzleRenderers/          -- 퍼즐 종류별 UI (kind 이름으로 매칭)
      ArrowSequence.luau
    RopeView.luau             -- 줄 위치 보간 + 연출
    HudController.luau        -- 타이머, 줄 위치 바, 버프 표시, 결과 화면
    MobileLayout.luau         -- 가로 모드, 기본 터치 컨트롤 숨김
```

### 3.3 default.project.json
```json
{
  "name": "PullPanic",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Shared": { "$path": "src/shared" },
      "Remotes": {
        "$className": "Folder",
        "MashBatch":    { "$className": "RemoteEvent" },
        "QteIssued":    { "$className": "RemoteEvent" },
        "QteResponse":  { "$className": "RemoteEvent" },
        "PuzzleIssued": { "$className": "RemoteEvent" },
        "PuzzleSubmit": { "$className": "RemoteEvent" },
        "PuzzleResult": { "$className": "RemoteEvent" },
        "MatchState":   { "$className": "RemoteEvent" }
      }
    },
    "ServerScriptService": {
      "Server": { "$path": "src/server" }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "Client": { "$path": "src/client" }
      }
    }
  }
}
```

### 3.4 네트워크 원칙 — 서버가 모든 판정을 한다
- **클라이언트는 입력만 보낸다.** 줄 위치, 힘, 승패, 버프는 모두 서버가 계산한다.
- **연타는 묶어서 보낸다:** 클라이언트는 탭 수를 세어 `INPUT_BATCH_INTERVAL`(0.2초)마다 `MashBatch(count)` 1회 전송. 탭마다 Remote를 보내지 않는다.
- **줄 위치 복제:** 서버는 `ROPE_REPLICATE_INTERVAL`(0.1초)마다 경기장 모델의 Attribute `RopePosition`을 갱신하고, 클라이언트 `RopeView`가 보간해서 부드럽게 표시한다.
- **Remote 목록**
  | 이름 | 방향 | 인자 |
  |---|---|---|
  | `MashBatch` | C→S | `count: number` |
  | `QteIssued` | S→C | `id: number, kind: string, window: number` |
  | `QteResponse` | C→S | `id: number, kind: string` |
  | `PuzzleIssued` | S→C | `id: number, kind: string, displayData: any, timeout: number, expiresAt: number` (서버 마감 시각) |
  | `PuzzleSubmit` | C→S | `id: number, submission: any` |
  | `PuzzleResult` | S→C | `id: number, success: boolean, reward: string?` |
  | `MatchState` | S→C | `phase: string, timeLeft: number, extra: any?` |

### 3.5 Match 객체
- `Match`는 클래스로 만들어 **한 서버에서 여러 경기가 동시에 돌 수 있게** 설계한다. MVP에서는 1개만 사용한다.
- 상태: `phase`("Waiting" | "Countdown" | "Playing" | "Ended"), `ropePosition`, `timeLeft`, `teams`, 참가자별 `{ rawTps, buffUntil, stunUntil, activeQte, activePuzzle }`.
- 봇도 같은 참가자 구조를 쓴다. `Match`/줄 계산 로직은 봇과 사람을 구분하지 않는다.

### 3.6 퍼즐 모듈 인터페이스
```lua
-- 서버: src/server/Puzzles/<Kind>.luau
export type PuzzleDef = {
	kind: string,
	reward: "Buff" | "InstantPull",
	generate: (rng: Random, difficulty: number) -> (any, any), -- (displayData, solutionInfo)
	validate: (displayData: any, solutionInfo: any, submission: any) -> boolean,
}

-- 클라이언트: src/client/PuzzleRenderers/<Kind>.luau
export type PuzzleRenderer = {
	render: (parent: GuiObject, displayData: any, onSubmit: (submission: any) -> ()) -> (),
	cleanup: () -> (),
}
```
- 검증은 정답 문자열 비교보다 **규칙 검증**을 우선한다(예: 미로는 제출 경로가 벽을 통과하지 않고 출구에 닿는지 확인).

---

## 4. 안티치트 (서버)
- `MashBatch`: 배치 간격 대비 `MAX_TAPS_PER_SEC` 초과분은 버린다. 비정상 빈도의 Remote 호출은 무시한다.
- 퍼즐: 발행 후 `PUZZLE_MIN_SOLVE_TIME` 이전에 들어온 제출은 실패 처리한다. 존재하지 않거나 만료된 `id`는 무시한다.
- QTE: 발행 후 `QTE_MIN_REACTION` 이전에 들어온 응답은 실패 처리한다.
- 클라이언트가 보낸 값은 타입과 범위를 항상 검사한다(`typeof`, NaN, 음수).

---

## 5. 조작 / UI

### 5.1 화면 배치 (가로)
```
┌──────────────────────────────────────────────┐
│        [타이머]   [====|=====] 줄 위치 바      │
│                                              │
│  ┌──────────┐                ┌────────────┐  │
│  │ QTE 지시  │    (경기장/     │  퍼즐 패널   │  │
│  │          │     캐릭터)     │ (등장 시만)  │  │
│  │ [ 연타 ]  │                │            │  │
│  └──────────┘                └────────────┘  │
│   왼손 영역                       오른손 영역   │
└──────────────────────────────────────────────┘
```
- 버프 중에는 힘 게이지에 색과 효과를 표시하고, 스턴 중에는 연타 버튼을 회색으로 표시한다.

### 5.2 모바일
- 가로 모드 고정.
- 로블록스 기본 터치 컨트롤(이동 썸스틱, 점프 버튼)을 숨긴다(`PlayerModule:GetControls():Disable()` 등). 캐릭터는 경기 중 이동하지 않는다.
- 스와이프 판정은 왼쪽 화면 영역 안의 터치 시작/끝 좌표로 직접 계산한다.

### 5.3 PC
- 왼손: `Space` 연타, `W`/`A`/`S` QTE.
- 오른손: 마우스로 퍼즐 조작.

### 5.4 디버그
- `Config.DEBUG = true`이면 화면 구석에 내 rawTps, 유효 힘, 양 팀 힘, 버프/스턴 상태를 표시한다(밸런스 조정용).

---

## 6. Config 초기값
`src/shared/Config.luau` 한 곳에 모은다. 아래 값은 출발점이며 플레이 테스트로 조정한다.

```lua
ROUND_DURATION = 45
COUNTDOWN = 3
ROPE_LIMIT = 100
ROPE_SPEED = 2.5

INPUT_BATCH_INTERVAL = 0.2
ROPE_REPLICATE_INTERVAL = 0.1

SOFT_CAP = 8            -- tps
OVER_CAP_RATIO = 0.5
MAX_TAPS_PER_SEC = 15

QTE_INTERVAL = {6, 10}  -- 초, 랜덤 범위
QTE_WINDOW = 1.5
QTE_MIN_REACTION = 0.15
QTE_SUCCESS_PULL = 5
QTE_FAIL_STUN = 0.6
SWIPE_MIN_DISTANCE = 40 -- px

PUZZLE_INTERVAL = {8, 12}
PUZZLE_TIMEOUT = 5
PUZZLE_MIN_SOLVE_TIME = 0.6
PUZZLE_ACTIVE_MASH_MULT = 1.0
BUFF_MULT = 1.5
BUFF_DURATION = 3
INSTANT_PULL = 8

BOT = {
	Easy   = { tps = 5, qteRate = 0.5, puzzleRate = 0.5 },
	Normal = { tps = 7, qteRate = 0.7, puzzleRate = 0.7 },
	Hard   = { tps = 9, qteRate = 0.9, puzzleRate = 0.9 },
}

DEBUG = true
```

---

## 7. 개발 단계 (한 번에 한 Phase만 진행)

### Phase 1 — MVP: 손맛 검증
목표: "연타하면서 퍼즐 풀기"가 재밌는지 확인한다.
- 1대1, 상대는 봇(Normal).
- 연타 → 서버 힘 계산 → 줄 이동 → 승패.
- 퍼즐 `ArrowSequence` 1종 + Buff 보상.
- 줄 위치 바, 타이머, 결과 화면, 재시작 버튼.
- 경기장 연출은 단순 도형(Part)으로만.
- **완료 기준**
  - Studio Play로 봇과 45초 경기가 끝까지 진행되고 승패가 표시된다.
  - 퍼즐 성공 시 3초 버프가 화면과 줄 이동에 반영된다.
  - 디버그 HUD에 수치가 표시된다.
  - 연타를 초당 15회 넘게 보내는 테스트(디버그용 강제 전송)를 하면 초과분이 무시된다.
  - 모바일 에뮬레이터(Studio Device Emulator)에서 레이아웃이 깨지지 않고, 기본 썸스틱/점프 버튼이 보이지 않는다.

### Phase 2 — 왼손 액션 + 퍼즐 확장
- QTE 3종(`SwipeUp`/`SwipeDown`/`SwipeBack`) 및 모바일 탭/스와이프 구분.
- 퍼즐 `NumberOrder`, `ColorMatch`, `MiniMaze` 추가.
- 봇 난이도 선택.
- **완료 기준:** 모바일 에뮬레이터에서 연타 중 스와이프가 오인식 없이 판정되고, 퍼즐 4종이 랜덤으로 등장한다.

### Phase 3 — 실제 PvP
- 로비 + 경기장 패드에 올라서면 매칭(1대1).
- 팀전 2대2 ~ 4대4, 빈자리는 봇으로 채움.
- 한 서버에서 경기장 여러 개 동시 진행.
- **완료 기준:** Studio "Clients and Servers" 테스트에서 플레이어 2~4명으로 경기가 정상 진행되고, 중간에 나간 플레이어 자리가 봇으로 대체된다.

### Phase 4 — 견제 + 연출
- 방해 퍼즐: 내가 퍼즐을 풀면 상대 화면에 방해 효과(퍼즐 추가 등장, 연타 버튼 위치 이동 등).
- 지는 팀이 진흙/용암에 빠지는 래그돌 연출, 캐릭터 기울기 애니메이션, 효과음.
- 맵 2~3종.

### Phase 5 — 운영
- DataStore: 승수, 연승, 퍼즐 최고 기록.
- 리더보드.
- 수익화는 **코스메틱만**(줄 스킨, 승리 연출, 이펙트). PvP 공정성을 위해 힘이나 버프에 영향 주는 판매는 하지 않는다.

---

## 8. 작업 규칙
- 각 Phase 시작 전에 **구현 계획(만들/수정할 파일 목록 + 순서)을 먼저 보여주고** 확인받은 뒤 코드를 작성한다.
- 현재 Phase 범위 밖 기능은 미리 만들지 않는다. 다만 위 설계(Match 객체, 퍼즐 인터페이스)는 처음부터 지킨다.
- 숫자 상수는 반드시 `Config`에 넣는다.
- 서버 판정 원칙(3.4)을 어기는 구현은 하지 않는다.
- 작업이 끝나면 **Studio에서 직접 확인하는 테스트 순서**를 체크리스트로 알려준다.
- 주석과 설명은 한국어로 작성한다.
