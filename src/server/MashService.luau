--!strict
-- 2026-11-19 연타 배치 검증과 참가자 유효 힘 계산 추가

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)

type AcceptedBatch = { time: number, count: number }
export type InputState = {
	batches: { AcceptedBatch },
	total: number,
	lastBatchAt: number?,
}

local MashService = {}

function MashService.newInputState(): InputState
	return { batches = {}, total = 0, lastBatchAt = nil }
end

function MashService.getRawTps(state: InputState, now: number): number
	local cutoff = now - Config.MASH_WINDOW
	local oldest = state.batches[1]
	while oldest and oldest.time <= cutoff do
		state.total -= oldest.count
		table.remove(state.batches, 1)
		oldest = state.batches[1]
	end
	return state.total / Config.MASH_WINDOW
end

function MashService.acceptBatch(state: InputState, count: unknown, now: number): ()
	if typeof(count) ~= "number" or count ~= count or count < 1 or count == math.huge or count % 1 ~= 0 then
		return
	end

	local lastBatchAt = state.lastBatchAt
	local elapsed = if lastBatchAt then now - lastBatchAt else Config.INPUT_BATCH_INTERVAL
	if elapsed < Config.MIN_MASH_BATCH_INTERVAL then
		return
	end
	state.lastBatchAt = now

	MashService.getRawTps(state, now)
	local batchInterval = math.clamp(elapsed, Config.INPUT_BATCH_INTERVAL, Config.MAX_MASH_BATCH_INTERVAL)
	local batchLimit = math.floor(Config.MAX_TAPS_PER_SEC * batchInterval)
	local windowLimit = math.floor(Config.MAX_TAPS_PER_SEC * Config.MASH_WINDOW)
	local accepted = math.min(count, batchLimit, windowLimit - state.total)
	if accepted > 0 then
		table.insert(state.batches, { time = now, count = accepted })
		state.total += accepted
	end
end

function MashService.getEffectiveForce(participant: Types.ParticipantState, now: number): number
	if participant.stunUntil > now then
		return 0
	end

	local rawTps = participant.rawTps
	local cappedTps = math.min(rawTps, Config.SOFT_CAP)
	local excessTps = math.max(rawTps - Config.SOFT_CAP, 0)
	local multiplier = if participant.buffUntil > now then Config.BUFF_MULT else 1
	-- 2026-11-19 진행 중인 퍼즐의 연타 배수 적용
	local puzzle = participant.activePuzzle
	if puzzle and now < puzzle.expiresAt then
		multiplier *= Config.PUZZLE_ACTIVE_MASH_MULT
	end
	return (cappedTps + excessTps * Config.OVER_CAP_RATIO) * multiplier
end

return MashService
