--!strict
-- 2026-11-21 같은 색 찾기 퍼즐 화면 추가 (틀린 타일은 회색으로 비활성화하고 계속 선택 가능)

-- 2026-11-21 PC 키보드 숫자키(1~6)로 타일 번호를 골라 입력할 수 있도록 추가

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)

local settings = Config.COLOR_MATCH
local layout = Config.PUZZLE_VIEW
local keyNumbers: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
}
local KEY_ACTION_NAME = "PullPanicPuzzleColor"
local content: Frame? = nil

local function cleanup()
	ContextActionService:UnbindAction(KEY_ACTION_NAME)
	if content then
		content:Destroy()
		content = nil
	end
end

local function render(parent: GuiObject, displayData: any, onSubmit: (unknown) -> ())
	cleanup()
	local root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = parent
	content = root

	local target: string = displayData.target
	local tiles: { string } = displayData.tiles

	-- 목표 색: 아래 타일과 구분되도록 흰 테두리를 둔다.
	local targetSwatch = Instance.new("Frame")
	targetSwatch.Name = "Target"
	targetSwatch.AnchorPoint = Vector2.new(0.5, 0)
	targetSwatch.Position = UDim2.fromScale(0.5, 0)
	targetSwatch.Size = UDim2.fromScale(0.5, settings.targetHeight)
	targetSwatch.BorderSizePixel = 0
	targetSwatch.BackgroundColor3 = settings.colors[target]
	targetSwatch.Parent = root
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 2
	stroke.Parent = targetSwatch

	local columns = settings.columns
	local rows = math.ceil(#tiles / columns)
	local gap = layout.tileGap
	local gridTop = settings.targetHeight + gap
	local grid = Instance.new("Frame")
	grid.Name = "Tiles"
	grid.Position = UDim2.fromScale(0, gridTop)
	grid.Size = UDim2.fromScale(1, 1 - gridTop)
	grid.BackgroundTransparency = 1
	grid.Parent = root

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.CellPadding = UDim2.fromScale(gap, gap)
	gridLayout.CellSize = UDim2.fromScale((1 - gap * (columns - 1)) / columns, (1 - gap * (rows - 1)) / rows)
	gridLayout.Parent = grid

	-- 마우스·터치와 키보드가 같은 입력 처리를 쓴다. 이미 틀린 타일은 다시 고르지 못한다.
	local tileButtons: { TextButton } = {}
	local wrong: { [number]: boolean } = {}
	local function choose(index: number)
		local tile = tileButtons[index]
		if not tile or wrong[index] then
			return
		end
		if tiles[index] == target then
			onSubmit(index)
			return
		end
		wrong[index] = true
		tile.Active = false
		tile.BackgroundColor3 = Color3.fromRGB(58, 66, 78)
	end

	for index, colorName in tiles do
		local tile = Instance.new("TextButton")
		tile.Name = colorName
		tile.LayoutOrder = index
		tile.BorderSizePixel = 0
		tile.AutoButtonColor = false
		tile.BackgroundColor3 = settings.colors[colorName]
		tile.Text = tostring(index)
		tile.TextScaled = true
		tile.Font = Enum.Font.GothamBold
		tile.TextColor3 = Color3.fromRGB(20, 28, 40)
		tile.TextTransparency = 0.45
		tile.Parent = grid
		tileButtons[index] = tile

		tile.Activated:Connect(function()
			choose(index)
		end)
	end

	-- 퍼즐이 떠 있는 동안 숫자키 입력을 퍼즐로 받고 다른 기본 동작으로 넘기지 않음
	ContextActionService:BindActionAtPriority(KEY_ACTION_NAME, function(_, state: Enum.UserInputState, input: InputObject)
		if UserInputService:GetFocusedTextBox() then
			return Enum.ContextActionResult.Pass
		end
		local number = keyNumbers[input.KeyCode]
		if state == Enum.UserInputState.Begin and number then
			choose(number)
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three,
		Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six)
end

local ColorMatch: Types.PuzzleRenderer = { render = render, cleanup = cleanup }
return ColorMatch
