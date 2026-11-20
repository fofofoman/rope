--!strict
-- 2026-11-20 타이머, 줄 위치 바, 카운트다운, 결과 화면, 재시작 버튼, 디버그 HUD 추가

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local layout = Config.HUD_VIEW
local HudController = {}

local function addCorner(parent: GuiObject)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, layout.cornerRadius)
	corner.Parent = parent
end

local function createFrame(parent: Instance, name: string, color: Color3): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

local function createLabel(parent: Instance, name: string, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = color
	label.Parent = parent
	return label
end

local function createDebugLabel(parent: Instance): TextLabel
	local label = createLabel(parent, "Debug", Color3.fromRGB(190, 255, 190))
	label.TextScaled = false
	label.TextSize = layout.debugTextSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.5
	label.Position = UDim2.fromScale(layout.debugLeft, layout.debugTop)
	label.Size = UDim2.fromScale(layout.debugWidth, layout.debugHeight)
	return label
end

function HudController.start(arena: Model)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	assert(playerGui:IsA("PlayerGui"), "PlayerGui를 찾을 수 없습니다.")

	local function readNumber(name: string, fallback: number): number
		local value = arena:GetAttribute(name)
		return if typeof(value) == "number" then value else fallback
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "PullPanicHud"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = layout.displayOrder

	-- 상단: 타이머와 줄 위치 바 (왼쪽 = 플레이어, 오른쪽 = 봇. 경기장 배치와 동일)
	local timerColor = Color3.fromRGB(240, 246, 255)
	local timerUrgentColor = Color3.fromRGB(255, 96, 96)
	local timer = createLabel(gui, "Timer", timerColor)
	timer.AnchorPoint = Vector2.new(0.5, 0)
	timer.Position = UDim2.fromScale(0.5, layout.timerTop)
	timer.Size = UDim2.fromScale(layout.timerWidth, layout.timerHeight)

	local bar = createFrame(gui, "RopeBar", Color3.fromRGB(19, 29, 44))
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.fromScale(0.5, layout.barTop)
	bar.Size = UDim2.fromScale(layout.barWidth, layout.barHeight)
	local playerSide = createFrame(bar, "PlayerSide", Color3.fromRGB(73, 147, 255))
	playerSide.Size = UDim2.fromScale(0.5, 1)
	local botSide = createFrame(bar, "BotSide", Color3.fromRGB(255, 117, 72))
	botSide.Position = UDim2.fromScale(0.5, 0)
	botSide.Size = UDim2.fromScale(0.5, 1)
	local marker = createFrame(bar, "Marker", Color3.new(1, 1, 1))
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Size = UDim2.fromScale(layout.markerWidth, 1.8)

	local barLeft = 0.5 - layout.barWidth / 2
	local playerTag = createLabel(gui, "PlayerTag", Color3.fromRGB(73, 147, 255))
	playerTag.Position = UDim2.fromScale(barLeft, layout.barLabelTop)
	playerTag.Size = UDim2.fromScale(layout.barWidth / 2, layout.barLabelHeight)
	playerTag.TextXAlignment = Enum.TextXAlignment.Left
	playerTag.Text = "플레이어"
	local botTag = createLabel(gui, "BotTag", Color3.fromRGB(255, 117, 72))
	botTag.Position = UDim2.fromScale(0.5, layout.barLabelTop)
	botTag.Size = UDim2.fromScale(layout.barWidth / 2, layout.barLabelHeight)
	botTag.TextXAlignment = Enum.TextXAlignment.Right
	botTag.Text = "Normal 봇"

	-- 중앙: 카운트다운 / START
	local countdown = createLabel(gui, "Countdown", Color3.fromRGB(255, 229, 165))
	countdown.AnchorPoint = Vector2.new(0.5, 0.5)
	countdown.Position = UDim2.fromScale(0.5, 0.5)
	countdown.Size = UDim2.fromScale(layout.countdownWidth, layout.countdownHeight)
	countdown.Visible = false

	-- 결과 화면과 재시작 버튼
	local overlay = createFrame(gui, "ResultOverlay", Color3.new(0, 0, 0))
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundTransparency = layout.overlayTransparency
	overlay.Active = true
	overlay.Visible = false
	local resultPanel = createFrame(overlay, "ResultPanel", Color3.fromRGB(19, 29, 44))
	resultPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	resultPanel.Position = UDim2.fromScale(0.5, 0.5)
	resultPanel.Size = UDim2.fromScale(layout.resultWidth, layout.resultHeight)
	addCorner(resultPanel)
	local resultTitle = createLabel(resultPanel, "Title", Color3.new(1, 1, 1))
	resultTitle.AnchorPoint = Vector2.new(0.5, 0)
	resultTitle.Position = UDim2.fromScale(0.5, layout.resultTitleTop)
	resultTitle.Size = UDim2.fromScale(layout.restartWidth, layout.resultTitleHeight)

	local restart = Instance.new("TextButton")
	restart.Name = "RestartButton"
	restart.AnchorPoint = Vector2.new(0.5, 0)
	restart.Position = UDim2.fromScale(0.5, layout.restartTop)
	restart.Size = UDim2.fromScale(layout.restartWidth, layout.restartHeight)
	restart.Font = Enum.Font.GothamBold
	restart.TextScaled = true
	restart.TextColor3 = Color3.new(1, 1, 1)
	restart.BackgroundColor3 = Color3.fromRGB(34, 82, 164)
	restart.BorderSizePixel = 0
	restart.Parent = resultPanel
	addCorner(restart)

	local debugLabel: TextLabel? = if Config.DEBUG then createDebugLabel(gui) else nil
	gui.Parent = playerGui

	local function resetRestart()
		restart.Active = true
		restart.Text = "다시 시작"
	end
	resetRestart()

	restart.Activated:Connect(function()
		if not restart.Active then
			return
		end
		restart.Active = false
		restart.Text = "대기 중..."
		Remotes.MatchRestart:FireServer()
		-- 서버가 요청을 거절해도 결과 화면에서 다시 누를 수 있게 복구
		task.delay(Config.RESTART_MIN_INTERVAL * 2, resetRestart)
	end)

	local function showResult(phase: unknown)
		local ended = phase == "Ended"
		overlay.Visible = ended
		resetRestart()
		if not ended then
			return
		end

		local winner = arena:GetAttribute("Winner")
		if winner == "A" then
			resultTitle.Text = "승리!"
			resultTitle.TextColor3 = Color3.fromRGB(255, 223, 120)
		elseif winner == "B" then
			resultTitle.Text = "패배"
			resultTitle.TextColor3 = Color3.fromRGB(255, 117, 72)
		else
			resultTitle.Text = "무승부"
			resultTitle.TextColor3 = Color3.fromRGB(200, 210, 225)
		end
	end

	local lastPhase: unknown = nil
	local startShownUntil = 0
	local lastDebugText = ""
	local shownPosition = readNumber("RopePosition", 0)

	RunService.PreRender:Connect(function(dt: number)
		local mine = arena:GetAttribute("PlayerUserId") == player.UserId
		gui.Enabled = mine
		if not mine then
			return
		end

		local phase = arena:GetAttribute("Phase")
		local now = Workspace:GetServerTimeNow()
		local remaining = math.max(readNumber("PhaseEndsAt", 0) - now, 0)

		if phase ~= lastPhase then
			lastPhase = phase
			if phase == "Playing" then
				startShownUntil = now + layout.startShowDuration
			end
			showResult(phase)
		end

		-- 타이머: 경기 종료 후에는 마지막 표시값을 유지
		if phase == "Playing" then
			timer.Text = tostring(math.ceil(remaining))
			timer.TextColor3 = if remaining <= layout.urgentSeconds then timerUrgentColor else timerColor
		elseif phase ~= "Ended" then
			timer.Text = tostring(Config.ROUND_DURATION)
			timer.TextColor3 = timerColor
		end

		if phase == "Countdown" then
			countdown.Text = tostring(math.max(math.ceil(remaining), 1))
			countdown.Visible = true
		elseif phase == "Playing" and now < startShownUntil then
			countdown.Text = "START!"
			countdown.Visible = true
		else
			countdown.Visible = false
		end

		-- 줄 위치 바: 서버 값(0.1초 간격)을 부드럽게 따라간다. 줄이 왼쪽(플레이어)으로 갈수록 마커도 왼쪽.
		local target = readNumber("RopePosition", 0)
		shownPosition += (target - shownPosition) * math.min(dt * layout.barSmoothing, 1)
		marker.Position = UDim2.fromScale(0.5 - shownPosition / (2 * Config.ROPE_LIMIT), 0.5)

		local label = debugLabel
		if label then
			local buffRemaining = readNumber("BuffUntil", 0) - now
			local buffText = if buffRemaining > 0 then string.format("x%.1f (%.1f초)", Config.BUFF_MULT, buffRemaining) else "없음"
			local stunText = if arena:GetAttribute("DebugStunned") == true then "스턴" else "없음"
			local text = string.format(
				"rawTps %.1f\n내 유효 힘 %.1f\n팀A %.1f / 팀B %.1f\n버프 %s / 스턴 %s",
				readNumber("DebugRawTps", 0), readNumber("DebugForce", 0),
				readNumber("DebugForceA", 0), readNumber("DebugForceB", 0), buffText, stunText
			)
			if text ~= lastDebugText then
				lastDebugText = text
				label.Text = text
			end
		end
	end)
end

return HudController
