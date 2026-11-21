--!strict
-- 2026-11-19 경기, 입력, 퍼즐 및 봇의 초기 밸런스 값 정의

return {
	-- 2026-11-20 경기 시간을 45초에서 30초로 단축
	-- 2026-11-21 경기 시간을 30초에서 50초로 연장
	ROUND_DURATION = 50,
	COUNTDOWN = 3,
	ROPE_LIMIT = 100,
	ROPE_SPEED = 2.5,

	INPUT_BATCH_INTERVAL = 0.2,
	ROPE_REPLICATE_INTERVAL = 0.1,

	SOFT_CAP = 8,
	OVER_CAP_RATIO = 0.5,
	MAX_TAPS_PER_SEC = 15,

	QTE_INTERVAL = { 6, 10 },
	QTE_WINDOW = 1.5,
	QTE_MIN_REACTION = 0.15,
	QTE_SUCCESS_PULL = 5,
	QTE_FAIL_STUN = 0.6,
	SWIPE_MIN_DISTANCE = 40,

	-- 2026-11-20 30초 경기에서 긴장감이 유지되도록 퍼즐 간격과 제한 시간을 단축
	PUZZLE_INTERVAL = { 5, 8 },
	PUZZLE_TIMEOUT = 4,
	PUZZLE_MIN_SOLVE_TIME = 0.6,
	PUZZLE_ACTIVE_MASH_MULT = 1.0,
	BUFF_MULT = 1.5,
	BUFF_DURATION = 3,
	INSTANT_PULL = 8,
	-- 2026-11-19 첫 퍼즐 시점과 화살표 순서 설정 추가
	PUZZLE_FIRST_DELAY = 2,
	ARROW_SEQUENCE_LENGTH = { 4, 6 },
	ARROW_DIRECTIONS = { "Up", "Right", "Down", "Left" },

	-- 2026-11-21 퍼즐 3종(NumberOrder, ColorMatch, MiniMaze) 설정과 종류별 제목·제한 시간 추가
	PUZZLE_TITLES = {
		ArrowSequence = "화살표 순서",
		NumberOrder = "숫자 순서",
		ColorMatch = "같은 색 찾기",
		MiniMaze = "미로 탈출",
	} :: { [string]: string },
	-- 목록에 없는 종류는 PUZZLE_TIMEOUT을 사용한다.
	PUZZLE_TIMEOUT_BY_KIND = { MiniMaze = 6 } :: { [string]: number },
	NUMBER_ORDER = { count = 6, columns = 3, rows = 2, jitter = 0.08, buttonWidth = 0.28, buttonHeight = 0.38 },
	COLOR_MATCH = {
		tileCount = 6,
		columns = 3,
		-- 타일 색은 중복 없이 뽑으므로 tileCount 이상이어야 한다.
		names = { "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink", "Cyan" },
		colors = {
			Red = Color3.fromRGB(225, 70, 70),
			Orange = Color3.fromRGB(240, 150, 50),
			Yellow = Color3.fromRGB(240, 220, 70),
			Green = Color3.fromRGB(80, 190, 90),
			Blue = Color3.fromRGB(70, 120, 230),
			Purple = Color3.fromRGB(150, 90, 210),
			Pink = Color3.fromRGB(240, 130, 190),
			Cyan = Color3.fromRGB(70, 200, 220),
		} :: { [string]: Color3 },
		targetHeight = 0.28,
	},
	MINI_MAZE = { size = 5, wallThickness = 0.08, cursorScale = 0.5 },

	BOT = {
		Easy = { tps = 5, qteRate = 0.5, puzzleRate = 0.5 },
		Normal = { tps = 7, qteRate = 0.7, puzzleRate = 0.7 },
		Hard = { tps = 9, qteRate = 0.9, puzzleRate = 0.9 },
	},

	-- 2026-11-19 연타 제한과 프로토타입 경기장 표시 설정 추가
	MASH_WINDOW = 1,
	MIN_MASH_BATCH_INTERVAL = 0.1,
	MAX_MASH_BATCH_INTERVAL = 0.4,
	ARENA_NAME = "PullPanicArena",
	ARENA_VIEW = {
		width = 44,
		depth = 12,
		floorThickness = 1,
		centerLineWidth = 0.15,
		endLineWidth = 0.45,
		travel = 12,
		ropeLength = 17,
		ropeHeight = 2.5,
		ropeThickness = 0.35,
		knotSize = 0.9,
		cameraHeight = 20,
		cameraDistance = 33,
	},
	MASH_BUTTON = { left = 0.04, bottom = 0.08, width = 0.22, height = 0.23 },

	-- 2026-11-19 퍼즐 패널과 버프 표시 배치 추가
	PUZZLE_VIEW = {
		right = 0.04, centerY = 0.48, width = 0.33, height = 0.52, inset = 0.06,
		titleTop = 0.06, titleHeight = 0.17, bodyTop = 0.29, bodyHeight = 0.48,
		footerTop = 0.81, footerHeight = 0.13,
		sequenceHeight = 0.42, buttonTop = 0.54, tileGap = 0.035,
		cornerRadius = 8, badgeBottom = 0.08, badgeHeight = 0.1, resultDuration = 1,
	},

	-- 2026-11-20 HUD, 결과 화면, 재시작 요청 제한, 디버그 강제 전송 설정 추가
	HUD_VIEW = {
		timerTop = 0.02, timerWidth = 0.14, timerHeight = 0.09,
		barTop = 0.12, barWidth = 0.5, barHeight = 0.035, markerWidth = 0.008,
		barLabelTop = 0.16, barLabelHeight = 0.04, barSmoothing = 12,
		urgentSeconds = 5,
		countdownWidth = 0.4, countdownHeight = 0.3, startShowDuration = 0.8,
		resultWidth = 0.36, resultHeight = 0.42, resultTitleTop = 0.1, resultTitleHeight = 0.36,
		restartTop = 0.62, restartWidth = 0.7, restartHeight = 0.22,
		cornerRadius = 8, overlayTransparency = 0.45, displayOrder = 10,
		debugLeft = 0.01, debugTop = 0.02, debugWidth = 0.26, debugHeight = 0.24, debugTextSize = 16,
	},
	RESTART_MIN_INTERVAL = 0.5,
	DEBUG_FLOOD = { key = Enum.KeyCode.F, tapsPerBatch = 10 },

	DEBUG = true,
}
