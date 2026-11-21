--!strict
-- 2026-11-21 미니 미로 퍼즐 생성 및 경로 검증 추가

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)

local SIZE: number = Config.MINI_MAZE.size
local CELL_COUNT = SIZE * SIZE
local START_CELL = 1
local EXIT_CELL = CELL_COUNT
-- 되돌아가는 경로를 감안한 제출 길이 상한 (비정상적으로 긴 배열 차단)
local MAX_PATH_LENGTH = CELL_COUNT * 4

export type MazeData = {
	size: number,
	right: { boolean }, -- right[i]: i번 칸과 오른쪽 칸 사이가 열려 있는지
	down: { boolean }, -- down[i]: i번 칸과 아래쪽 칸 사이가 열려 있는지
	start: number,
	exit: number,
}

-- 칸 번호는 (행 - 1) * SIZE + 열 이다. 시작은 왼쪽 위, 출구는 오른쪽 아래로 고정한다.
local function isOpen(maze: MazeData, from: number, to: number): boolean
	local column = (from - 1) % SIZE + 1
	if to == from + 1 then
		return column < SIZE and maze.right[from]
	elseif to == from - 1 then
		return column > 1 and maze.right[to]
	elseif to == from + SIZE then
		return maze.down[from] == true
	elseif to == from - SIZE then
		return maze.down[to] == true
	end
	return false
end

-- 깊이 우선 탐색으로 모든 칸이 연결된 미로를 만든다. 시작에서 출구까지 길이 반드시 존재한다.
local function generate(rng: Random, _difficulty: number): (MazeData, nil)
	local maze: MazeData = { size = SIZE, right = {}, down = {}, start = START_CELL, exit = EXIT_CELL }
	local visited: { boolean } = {}
	for cell = 1, CELL_COUNT do
		maze.right[cell] = false
		maze.down[cell] = false
		visited[cell] = false
	end

	local stack: { number } = { START_CELL }
	visited[START_CELL] = true
	while #stack > 0 do
		local cell = stack[#stack]
		local row = (cell - 1) // SIZE + 1
		local column = (cell - 1) % SIZE + 1

		local candidates: { number } = {}
		if column < SIZE and not visited[cell + 1] then
			table.insert(candidates, cell + 1)
		end
		if column > 1 and not visited[cell - 1] then
			table.insert(candidates, cell - 1)
		end
		if row < SIZE and not visited[cell + SIZE] then
			table.insert(candidates, cell + SIZE)
		end
		if row > 1 and not visited[cell - SIZE] then
			table.insert(candidates, cell - SIZE)
		end

		if #candidates == 0 then
			table.remove(stack)
		else
			local nextCell = candidates[rng:NextInteger(1, #candidates)]
			if nextCell == cell + 1 then
				maze.right[cell] = true
			elseif nextCell == cell - 1 then
				maze.right[nextCell] = true
			elseif nextCell == cell + SIZE then
				maze.down[cell] = true
			else
				maze.down[nextCell] = true
			end
			visited[nextCell] = true
			table.insert(stack, nextCell)
		end
	end
	return maze, nil
end

-- 제출은 지나간 칸 번호의 배열이다. 시작칸에서 출발해 벽을 통과하지 않고 출구에 닿으면 성공이다.
local function validate(displayData: any, _solutionInfo: any, submission: unknown): boolean
	if typeof(submission) ~= "table" then
		return false
	end

	local path: { unknown } = submission :: any
	local count = 0
	for index in pairs(path) do
		if typeof(index) ~= "number" then
			return false
		end
		count += 1
	end
	if count < 2 or count > MAX_PATH_LENGTH then
		return false
	end

	local maze: MazeData = displayData
	local previous: number? = nil
	for index = 1, count do
		local cell = path[index]
		if typeof(cell) ~= "number" or cell % 1 ~= 0 or cell < 1 or cell > CELL_COUNT then
			return false
		end
		if previous == nil then
			if cell ~= maze.start then
				return false
			end
		elseif not isOpen(maze, previous, cell) then
			return false
		end
		previous = cell
	end
	return previous == maze.exit
end

local MiniMaze: Types.PuzzleDef = {
	kind = "MiniMaze",
	reward = "Buff",
	generate = generate,
	validate = validate,
}

return MiniMaze
