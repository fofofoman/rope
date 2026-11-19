--!strict
-- 2026-11-19 경기 중 퍼즐 발행, 만료, 제출 판정과 버프 적용 추가

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local ArrowSequence = require(script.Parent.Puzzles.ArrowSequence)

export type Schedule = { nextAt: number? }

local rng = Random.new()
local lastPuzzleId = 0
local PuzzleService = {}

function PuzzleService.newSchedule(): Schedule
	return { nextAt = nil }
end

function PuzzleService.update(schedule: Schedule, participant: Types.ParticipantState, now: number): (Types.ActivePuzzle?, number?)
	local current = participant.activePuzzle
	if current then
		if now >= current.expiresAt then
			participant.activePuzzle = nil
			return nil, current.id
		end
		return nil, nil
	end

	local nextAt = schedule.nextAt
	if nextAt == nil then
		schedule.nextAt = now + Config.PUZZLE_FIRST_DELAY
		return nil, nil
	end
	if now < nextAt then
		return nil, nil
	end

	lastPuzzleId += 1
	local displayData, solutionInfo = ArrowSequence.generate(rng, rng:NextNumber())
	local puzzle: Types.ActivePuzzle = {
		id = lastPuzzleId,
		definition = ArrowSequence,
		displayData = displayData,
		solutionInfo = solutionInfo,
		issuedAt = now,
		expiresAt = now + Config.PUZZLE_TIMEOUT,
	}
	participant.activePuzzle = puzzle
	schedule.nextAt = now + rng:NextNumber(Config.PUZZLE_INTERVAL[1], Config.PUZZLE_INTERVAL[2])
	return puzzle, nil
end

function PuzzleService.submit(participant: Types.ParticipantState, id: unknown, submission: unknown, now: number): (boolean?, Types.PuzzleReward?)
	local puzzle = participant.activePuzzle
	if not puzzle or id ~= puzzle.id or now >= puzzle.expiresAt then
		return nil, nil
	end

	-- 제출 기회는 발행된 퍼즐마다 한 번이다.
	participant.activePuzzle = nil
	local definition = puzzle.definition
	if now < puzzle.issuedAt + Config.PUZZLE_MIN_SOLVE_TIME
		or not definition.validate(puzzle.displayData, puzzle.solutionInfo, submission) then
		return false, nil
	end

	if definition.reward == "Buff" then
		participant.buffUntil = now + Config.BUFF_DURATION
	end
	return true, definition.reward
end

return PuzzleService
