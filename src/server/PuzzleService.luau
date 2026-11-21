--!strict
-- 2026-11-19 경기 중 퍼즐 발행, 만료, 제출 판정과 버프 적용 추가

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local ArrowSequence = require(script.Parent.Puzzles.ArrowSequence)
-- 2026-11-21 숫자 순서, 같은 색 찾기, 미니 미로 퍼즐 추가
local ColorMatch = require(script.Parent.Puzzles.ColorMatch)
local MiniMaze = require(script.Parent.Puzzles.MiniMaze)
local NumberOrder = require(script.Parent.Puzzles.NumberOrder)

export type Schedule = { nextAt: number?, lastKind: string? }

local definitions: { Types.PuzzleDef } = { ArrowSequence, NumberOrder, ColorMatch, MiniMaze }
local rng = Random.new()
local lastPuzzleId = 0
local PuzzleService = {}

function PuzzleService.newSchedule(): Schedule
	return { nextAt = nil, lastKind = nil }
end

-- 같은 종류가 연속으로 나오지 않도록 직전 종류를 제외하고 무작위로 고른다.
local function pickDefinition(schedule: Schedule): Types.PuzzleDef
	local candidates: { Types.PuzzleDef } = {}
	for _, definition in definitions do
		if definition.kind ~= schedule.lastKind then
			table.insert(candidates, definition)
		end
	end
	local picked = candidates[rng:NextInteger(1, #candidates)]
	schedule.lastKind = picked.kind
	return picked
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
	local definition = pickDefinition(schedule)
	local displayData, solutionInfo = definition.generate(rng, rng:NextNumber())
	local puzzle: Types.ActivePuzzle = {
		id = lastPuzzleId,
		definition = definition,
		displayData = displayData,
		solutionInfo = solutionInfo,
		issuedAt = now,
		expiresAt = now + (Config.PUZZLE_TIMEOUT_BY_KIND[definition.kind] or Config.PUZZLE_TIMEOUT),
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
