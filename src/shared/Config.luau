--!strict
-- 2026-11-19 경기, 입력, 퍼즐 및 봇의 초기 밸런스 값 정의

return {
	ROUND_DURATION = 45,
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

	PUZZLE_INTERVAL = { 8, 12 },
	PUZZLE_TIMEOUT = 5,
	PUZZLE_MIN_SOLVE_TIME = 0.6,
	PUZZLE_ACTIVE_MASH_MULT = 1.0,
	BUFF_MULT = 1.5,
	BUFF_DURATION = 3,
	INSTANT_PULL = 8,
	-- 2026-11-19 첫 퍼즐 시점과 화살표 순서 설정 추가
	PUZZLE_FIRST_DELAY = 2,
	ARROW_SEQUENCE_LENGTH = { 4, 6 },
	ARROW_DIRECTIONS = { "Up", "Right", "Down", "Left" },

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

	DEBUG = true,
}
