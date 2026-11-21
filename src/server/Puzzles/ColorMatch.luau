--!strict
-- 2026-11-21 같은 색 찾기 퍼즐 생성 및 제출 검증 추가

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)

local settings = Config.COLOR_MATCH

-- 타일 색은 중복 없이 뽑으므로 목표 색과 같은 타일은 항상 정확히 하나다.
local function generate(rng: Random, _difficulty: number): ({ target: string, tiles: { string } }, nil)
	local names: { string } = table.clone(settings.names)
	for index = #names, 2, -1 do
		local swapIndex = rng:NextInteger(1, index)
		names[index], names[swapIndex] = names[swapIndex], names[index]
	end

	local tiles: { string } = {}
	for index = 1, settings.tileCount do
		tiles[index] = names[index]
	end
	return { target = tiles[rng:NextInteger(1, #tiles)], tiles = tiles }, nil
end

-- 제출은 고른 타일의 번호(정수)이며, 그 타일의 색이 목표 색이어야 한다.
local function validate(displayData: any, _solutionInfo: any, submission: unknown): boolean
	if typeof(submission) ~= "number" or submission % 1 ~= 0 then
		return false
	end

	local tiles: { string } = displayData.tiles
	return tiles[submission] == displayData.target
end

local ColorMatch: Types.PuzzleDef = {
	kind = "ColorMatch",
	reward = "InstantPull",
	generate = generate,
	validate = validate,
}

return ColorMatch
