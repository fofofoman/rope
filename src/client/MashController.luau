--!strict
-- 2026-11-19 Space와 모바일 연타 버튼의 입력을 묶어 전송

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local MashController = {}

local function createTouchButton(): TextButton
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	assert(playerGui:IsA("PlayerGui"), "PlayerGui를 찾을 수 없습니다.")
	playerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor

	local gui = Instance.new("ScreenGui")
	gui.Name = "MashControls"
	gui.ResetOnSpawn = false

	local layout = Config.MASH_BUTTON
	local button = Instance.new("TextButton")
	button.Name = "MashButton"
	button.AnchorPoint = Vector2.new(0, 1)
	button.Position = UDim2.fromScale(layout.left, 1 - layout.bottom)
	button.Size = UDim2.fromScale(layout.width, layout.height)
	button.Text = "연타"
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.new(1, 1, 1)
	button.BackgroundColor3 = Color3.fromRGB(34, 82, 164)
	button.BorderSizePixel = 0
	button.Visible = false
	button.Parent = gui
	gui.Parent = playerGui
	return button
end

function MashController.start(arena: Model)
	local player = Players.LocalPlayer
	local pendingTaps = 0
	local elapsed = 0
	local spaceHeld = false
	local playing = false
	local button = if UserInputService.TouchEnabled then createTouchButton() else nil

	local function updatePlaying()
		local canMash = arena:GetAttribute("Phase") == "Playing" and arena:GetAttribute("PlayerUserId") == player.UserId
		if canMash ~= playing then
			playing = canMash
			pendingTaps = 0
			elapsed = 0
		end
		if button then
			button.Visible = playing
		end
	end

	local function queueTap()
		if playing then
			pendingTaps += 1
		end
	end

	arena:GetAttributeChangedSignal("Phase"):Connect(updatePlaying)
	arena:GetAttributeChangedSignal("PlayerUserId"):Connect(updatePlaying)
	updatePlaying()
	if button then
		button.Activated:Connect(queueTap)
	end

	ContextActionService:BindActionAtPriority("PullPanicMash", function(_, state)
		if state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			spaceHeld = false
		end
		if UserInputService:GetFocusedTextBox() then
			return Enum.ContextActionResult.Pass
		end
		if state == Enum.UserInputState.Begin and not spaceHeld then
			spaceHeld = true
			queueTap()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space)
	UserInputService.WindowFocusReleased:Connect(function()
		spaceHeld = false
	end)

	RunService.Heartbeat:Connect(function(dt: number)
		if not playing then
			return
		end
		elapsed += dt
		if elapsed >= Config.INPUT_BATCH_INTERVAL then
			elapsed %= Config.INPUT_BATCH_INTERVAL
			if pendingTaps > 0 then
				Remotes.MashBatch:FireServer(pendingTaps)
				pendingTaps = 0
			end
		end
	end)
end

return MashController
