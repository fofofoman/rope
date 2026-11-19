--!strict
-- 2026-11-19 화살표 순서 생성 및 제출 검증 추가

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)

local function generate(rng: Random, difficulty: number): ({ sequence: { string } }, nil)
	local minLength, maxLength = Config.ARROW_SEQUENCE_LENGTH[1], Config.ARROW_SEQUENCE_LENGTH[2]
	local count = math.min(maxLength, minLength + math.floor(difficulty * (maxLength - minLength + 1)))
	local directions = Config.ARROW_DIRECTIONS
	local sequence: { string } = {}
	for index = 1, count do
		sequence[index] = directions[rng:NextInteger(1, #directions)]
	end
	return { sequence = sequence }, nil
end

local function validate(displayData: any, _solutionInfo: any, submission: unknown): boolean
	if typeof(submission) ~= "table" then
		return false
	end

	local sequence: { string } = displayData.sequence
	local count = 0
	for index, direction in pairs(submission) do
		if typeof(index) ~= "number" or typeof(direction) ~= "string" or sequence[index] ~= direction then
			return false
		end
		count += 1
	end
	return count == #sequence
end

local ArrowSequence: Types.PuzzleDef = {
	kind = "ArrowSequence",
	reward = "Buff",
	generate = generate,
	validate = validate,
}

return ArrowSequence
