--!strict
-- 2026-11-19 화살표 순서 표시와 마우스·터치 제출 추가

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)

local glyphs: { [string]: string } = { Up = "↑", Right = "→", Down = "↓", Left = "←" }
local layout = Config.PUZZLE_VIEW
local content: Frame? = nil

local function cleanup()
	if content then
		content:Destroy()
		content = nil
	end
end

local function createRow(parent: Frame, top: number, height: number): Frame
	local row = Instance.new("Frame")
	row.Position = UDim2.fromScale(0, top)
	row.Size = UDim2.fromScale(1, height)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(layout.tileGap, 0)
	list.Parent = row
	return row
end

local function tileSize(count: number): UDim2
	return UDim2.fromScale((1 - layout.tileGap * (count - 1)) / count, 1)
end

local function render(parent: GuiObject, displayData: any, onSubmit: (unknown) -> ())
	cleanup()
	local root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = parent
	content = root

	local sequence: { string } = displayData.sequence
	local targetRow = createRow(root, 0, layout.sequenceHeight)
	local labels: { TextLabel } = {}
	for index, direction in sequence do
		local label = Instance.new("TextLabel")
		label.LayoutOrder = index
		label.Size = tileSize(#sequence)
		label.BorderSizePixel = 0
		label.BackgroundColor3 = Color3.fromRGB(33, 48, 69)
		label.TextColor3 = Color3.fromRGB(224, 235, 250)
		label.Text = glyphs[direction]
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = targetRow
		labels[index] = label
	end
	labels[1].BackgroundColor3 = Color3.fromRGB(66, 102, 156)

	local submission: { string } = {}
	local directions = Config.ARROW_DIRECTIONS
	local buttonRow = createRow(root, layout.buttonTop, 1 - layout.buttonTop)
	for index, direction in directions do
		local button = Instance.new("TextButton")
		button.Name = direction
		button.LayoutOrder = index
		button.Size = tileSize(#directions)
		button.BorderSizePixel = 0
		button.BackgroundColor3 = Color3.fromRGB(50, 82, 133)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Text = glyphs[direction]
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.Parent = buttonRow
		button.Activated:Connect(function()
			if #submission >= #sequence then
				return
			end
			table.insert(submission, direction)
			local position = #submission
			labels[position].BackgroundColor3 = Color3.fromRGB(31, 43, 58)
			labels[position].TextColor3 = Color3.fromRGB(147, 166, 191)
			if position == #sequence then
				onSubmit(submission)
			else
				labels[position + 1].BackgroundColor3 = Color3.fromRGB(66, 102, 156)
			end
		end)
	end
end

local ArrowSequence: Types.PuzzleRenderer = { render = render, cleanup = cleanup }
return ArrowSequence
