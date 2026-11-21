--!strict
-- 2026-11-21 미니 미로 퍼즐 화면 추가 (드래그로 칸을 따라 이동, 벽 방향으로는 이동하지 않음)

-- 2026-11-21 PC 키보드 방향키로 한 칸씩 이동할 수 있도록 추가

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)

local settings = Config.MINI_MAZE
local FAST_DRAG_MAX_STEPS = 3 -- 빠르게 드래그해 칸을 건너뛰어도 이 거리 안이면 길을 따라 이어준다
local BASE_COLOR = Color3.fromRGB(27, 37, 52)
local START_COLOR = Color3.fromRGB(60, 140, 90)
local EXIT_COLOR = Color3.fromRGB(230, 190, 70)
local PATH_COLOR = Color3.fromRGB(66, 102, 156)
local HEAD_COLOR = Color3.fromRGB(120, 170, 240)
local WALL_COLOR = Color3.fromRGB(200, 215, 235)

local KEY_ACTION_NAME = "PullPanicPuzzleMaze"
local content: Frame? = nil
local connections: { RBXScriptConnection } = {}

local function cleanup()
	ContextActionService:UnbindAction(KEY_ACTION_NAME)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if content then
		content:Destroy()
		content = nil
	end
end

local function render(parent: GuiObject, displayData: any, onSubmit: (unknown) -> ())
	cleanup()
	local size: number = displayData.size
	local right: { boolean } = displayData.right
	local down: { boolean } = displayData.down
	local startCell: number = displayData.start
	local exitCell: number = displayData.exit

	local root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = parent
	content = root

	-- 미로 판은 정사각형으로 가운데에 둔다.
	local board = Instance.new("Frame")
	board.Name = "Board"
	board.AnchorPoint = Vector2.new(0.5, 0.5)
	board.Position = UDim2.fromScale(0.5, 0.5)
	board.Size = UDim2.fromScale(1, 1)
	board.BorderSizePixel = 0
	board.BackgroundColor3 = BASE_COLOR
	board.Active = true
	board.Parent = root
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = board
	local border = Instance.new("UIStroke")
	border.Color = WALL_COLOR
	border.Thickness = 2
	border.Parent = board

	local cellScale = 1 / size
	local cells: { Frame } = {}
	local function baseColor(cell: number): Color3
		if cell == startCell then
			return START_COLOR
		elseif cell == exitCell then
			return EXIT_COLOR
		end
		return BASE_COLOR
	end

	for cell = 1, size * size do
		local row = (cell - 1) // size
		local column = (cell - 1) % size
		local frame = Instance.new("Frame")
		frame.Name = tostring(cell)
		frame.Position = UDim2.fromScale(column * cellScale, row * cellScale)
		frame.Size = UDim2.fromScale(cellScale, cellScale)
		frame.BorderSizePixel = 0
		frame.BackgroundColor3 = baseColor(cell)
		frame.Parent = board
		cells[cell] = frame
	end

	-- 열려 있지 않은 칸 사이에 벽을 그린다. 모서리 틈이 생기지 않도록 벽 길이를 두께만큼 늘린다.
	local thick = settings.wallThickness * cellScale
	local function addWall(x: number, y: number, width: number, height: number)
		local wall = Instance.new("Frame")
		wall.AnchorPoint = Vector2.new(0.5, 0.5)
		wall.Position = UDim2.fromScale(x, y)
		wall.Size = UDim2.fromScale(width, height)
		wall.BorderSizePixel = 0
		wall.BackgroundColor3 = WALL_COLOR
		wall.ZIndex = 2
		wall.Parent = board
	end
	for cell = 1, size * size do
		local row = (cell - 1) // size + 1
		local column = (cell - 1) % size + 1
		if column < size and not right[cell] then
			addWall(column * cellScale, (row - 0.5) * cellScale, thick, cellScale + thick)
		end
		if row < size and not down[cell] then
			addWall((column - 0.5) * cellScale, row * cellScale, cellScale + thick, thick)
		end
	end

	-- 서버 검증과 같은 규칙: 인접한 칸이고 사이가 열려 있어야 이동할 수 있다.
	local function isOpen(from: number, to: number): boolean
		local column = (from - 1) % size + 1
		if to == from + 1 then
			return column < size and right[from]
		elseif to == from - 1 then
			return column > 1 and right[to]
		elseif to == from + size then
			return down[from] == true
		elseif to == from - size then
			return down[to] == true
		end
		return false
	end

	local path: { number } = { startCell }
	local inPath: { [number]: boolean } = { [startCell] = true }
	local function paint()
		for cell, frame in cells do
			frame.BackgroundColor3 = if inPath[cell] then PATH_COLOR else baseColor(cell)
		end
		cells[path[#path]].BackgroundColor3 = HEAD_COLOR
	end
	paint()

	-- 머리(현재 칸)에서 목표 칸까지 열린 길을 따라 최대 maxSteps칸 안에 갈 수 있으면 그 경로를 돌려준다.
	local function findRoute(target: number, maxSteps: number): { number }?
		local head = path[#path]
		local cameFrom: { [number]: number } = {}
		local frontier: { number } = { head }
		local seen: { [number]: boolean } = { [head] = true }
		for _ = 1, maxSteps do
			local nextFrontier: { number } = {}
			for _, cell in frontier do
				for _, neighbor in { cell + 1, cell - 1, cell + size, cell - size } do
					if neighbor >= 1 and neighbor <= size * size and not seen[neighbor]
						and not inPath[neighbor] and isOpen(cell, neighbor) then
						seen[neighbor] = true
						cameFrom[neighbor] = cell
						if neighbor == target then
							local route: { number } = {}
							local step: number? = neighbor
							while step and step ~= head do
								table.insert(route, 1, step)
								step = cameFrom[step]
							end
							return route
						end
						table.insert(nextFrontier, neighbor)
					end
				end
			end
			frontier = nextFrontier
		end
		return nil
	end

	local dragging = false
	local finished = false
	local function moveTo(target: number)
		if finished then
			return
		end
		-- 지나온 칸으로 돌아오면 그 칸까지 경로를 되감는다.
		if inPath[target] then
			while path[#path] ~= target do
				inPath[table.remove(path) :: number] = nil
			end
		else
			local route = findRoute(target, FAST_DRAG_MAX_STEPS)
			if not route then
				return
			end
			for _, cell in route do
				table.insert(path, cell)
				inPath[cell] = true
			end
		end
		paint()
		if path[#path] == exitCell then
			finished = true
			dragging = false
			onSubmit(table.clone(path))
		end
	end

	local function cellAt(position: Vector3): number?
		local relativeX = (position.X - board.AbsolutePosition.X) / board.AbsoluteSize.X
		local relativeY = (position.Y - board.AbsolutePosition.Y) / board.AbsoluteSize.Y
		if relativeX < 0 or relativeX >= 1 or relativeY < 0 or relativeY >= 1 then
			return nil
		end
		return math.floor(relativeY * size) * size + math.floor(relativeX * size) + 1
	end

	table.insert(connections, board.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			local cell = cellAt(input.Position)
			if cell then
				moveTo(cell)
			end
		end
	end))
	table.insert(connections, UserInputService.InputChanged:Connect(function(input: InputObject)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local cell = cellAt(input.Position)
			if cell then
				moveTo(cell)
			end
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	-- 방향키 한 번에 한 칸씩 이동한다. 벽이 있거나 판 밖이면 무시하고, 이전 칸 방향이면 되돌아간다.
	local keyOffsets: { [Enum.KeyCode]: number } = {
		[Enum.KeyCode.Up] = -size,
		[Enum.KeyCode.Down] = size,
		[Enum.KeyCode.Left] = -1,
		[Enum.KeyCode.Right] = 1,
	}
	-- 퍼즐이 떠 있는 동안 방향키 입력을 퍼즐로 받고, 카메라 회전 등 기본 동작으로 넘기지 않음
	ContextActionService:BindActionAtPriority(KEY_ACTION_NAME, function(_, state: Enum.UserInputState, input: InputObject)
		if UserInputService:GetFocusedTextBox() then
			return Enum.ContextActionResult.Pass
		end
		local offset = keyOffsets[input.KeyCode]
		if state == Enum.UserInputState.Begin and offset then
			local target = path[#path] + offset
			if target >= 1 and target <= size * size and isOpen(path[#path], target) then
				moveTo(target)
			end
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Up, Enum.KeyCode.Right, Enum.KeyCode.Down, Enum.KeyCode.Left)
end

local MiniMaze: Types.PuzzleRenderer = { render = render, cleanup = cleanup }
return MiniMaze
