--!strict
-- 2026-11-19 서버와 클라이언트가 공유하는 RemoteEvent 참조 타입 정의

export type RemoteEvents = {
	MashBatch: RemoteEvent,
	QteIssued: RemoteEvent,
	QteResponse: RemoteEvent,
	PuzzleIssued: RemoteEvent,
	PuzzleSubmit: RemoteEvent,
	PuzzleResult: RemoteEvent,
	MatchState: RemoteEvent,
	-- 2026-11-20 경기 종료 후 재시작 요청 Remote 추가
	MatchRestart: RemoteEvent,
}

-- 2026-11-19 경기 상태와 참가자 타입 추가
export type MatchPhase = "Waiting" | "Countdown" | "Playing" | "Ended"
export type MatchWinner = "A" | "B" | "Draw"
export type MatchStateExtra = { winner: MatchWinner }

-- 2026-11-19 퍼즐 정의, 클라이언트 렌더러 및 발행 상태 타입 추가
export type PuzzleReward = "Buff" | "InstantPull"
export type PuzzleDef = {
	kind: string,
	reward: PuzzleReward,
	generate: (rng: Random, difficulty: number) -> (any, any),
	validate: (displayData: any, solutionInfo: any, submission: unknown) -> boolean,
}

export type PuzzleRenderer = {
	render: (parent: GuiObject, displayData: any, onSubmit: (submission: unknown) -> ()) -> (),
	cleanup: () -> (),
}

export type ActivePuzzle = {
	id: number,
	definition: PuzzleDef,
	displayData: any,
	solutionInfo: any,
	issuedAt: number,
	expiresAt: number,
}

export type ParticipantState = {
	rawTps: number,
	buffUntil: number,
	stunUntil: number,
	activePuzzle: ActivePuzzle?,
}

return {}
