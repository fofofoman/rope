--!strict
-- 2026-11-21 숫자 순서 퍼즐 화면 추가 (틀린 숫자는 무시하고 순서대로 누른 숫자만 제출)
-- 2026-11-21 PC 키보드 숫자키(1~6)로도 입력할 수 있도록 추가

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)

local settings = Config.NUMBER_ORDER
local keyNumbers: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
}
local KEY_ACTION_NAME = "PullPanicPuzzleNumber"
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

	local items: { { number: number, x: number, y: number } } = displayData.items
	local submission: { number } = {}
	local buttons: { [number]: TextButton } = {}

	-- 마우스·터치와 키보드가 같은 입력 처리를 쓴다. 순서가 아닌 숫자는 무시한다.
	local function press(number: number)
		local button = buttons[number]
		if not button or number ~= #submission + 1 then
			return
		end
		table.insert(submission, number)
		button.Active = false
		button.BackgroundColor3 = Color3.fromRGB(31, 43, 58)
		button.TextColor3 = Color3.fromRGB(147, 166, 191)
		if #submission == settings.count then
			onSubmit(submission)
		end
	end

	for _, item in items do
		local button = Instance.new("TextButton")
		button.Name = tostring(item.number)
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		button.Position = UDim2.fromScale(item.x, item.y)
		button.Size = UDim2.fromScale(settings.buttonWidth, settings.buttonHeight)
		button.BorderSizePixel = 0
		button.BackgroundColor3 = Color3.fromRGB(50, 82, 133)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Text = tostring(item.number)
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.Parent = root
		buttons[item.number] = button

		-- 버튼이 찌그러지지 않도록 정사각형으로 맞춘다.
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1
		aspect.Parent = button

		button.Activated:Connect(function()
			press(item.number)
		end)
	end

	-- 퍼즐이 떠 있는 동안 숫자키 입력을 퍼즐로 받고 다른 기본 동작으로 넘기지 않음
	ContextActionService:BindActionAtPriority(KEY_ACTION_NAME, function(_, state: Enum.UserInputState, input: InputObject)
		if UserInputService:GetFocusedTextBox() then
			return Enum.ContextActionResult.Pass
		end
		local number = keyNumbers[input.KeyCode]
		if state == Enum.UserInputState.Begin and number then
			press(number)
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three,
		Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six)
end

local NumberOrder: Types.PuzzleRenderer = { render = render, cleanup = cleanup }
return NumberOrder
