--!strict
-- 2026-11-21 숫자 순서 퍼즐 생성 및 제출 검증 추가

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)

local settings = Config.NUMBER_ORDER

-- 숫자는 칸마다 하나씩 배치하고 칸 안에서만 흔들어서 서로 겹치지 않게 한다.
local function generate(rng: Random, _difficulty: number): ({ items: { { number: number, x: number, y: number } } }, nil)
	local cells: { number } = {}
	for index = 1, settings.columns * settings.rows do
		cells[index] = index
	end
	for index = #cells, 2, -1 do
		local swapIndex = rng:NextInteger(1, index)
		cells[index], cells[swapIndex] = cells[swapIndex], cells[index]
	end

	local items = {}
	for number = 1, settings.count do
		local cell = cells[number] - 1
		local column = cell % settings.columns
		local row = cell // settings.columns
		items[number] = {
			number = number,
			x = (column + 0.5) / settings.columns + rng:NextNumber(-settings.jitter, settings.jitter) / settings.columns,
			y = (row + 0.5) / settings.rows + rng:NextNumber(-settings.jitter, settings.jitter) / settings.rows,
		}
	end
	return { items = items }, nil
end

-- 제출은 눌린 숫자를 순서대로 담은 배열이어야 하고, 1부터 count까지 정확히 이어져야 한다.
local function validate(_displayData: any, _solutionInfo: any, submission: unknown): boolean
	if typeof(submission) ~= "table" then
		return false
	end

	local count = 0
	for index, number in pairs(submission) do
		if typeof(index) ~= "number" or typeof(number) ~= "number" or number ~= index then
			return false
		end
		-- 1..count 범위의 정수 칸만 허용 (예: 1~5와 7을 보내 개수만 맞추는 제출 차단)
		if index < 1 or index > settings.count or index % 1 ~= 0 then
			return false
		end
		count += 1
	end
	return count == settings.count
end

local NumberOrder: Types.PuzzleDef = {
	kind = "NumberOrder",
	reward = "InstantPull",
	generate = generate,
	validate = validate,
}

return NumberOrder
