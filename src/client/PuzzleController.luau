--!strict
-- 2026-11-19 퍼즐 표시, 제출 결과 및 서버 기준 버프 표시 추가

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Types = require(Shared.Types)

local renderers: { [string]: Types.PuzzleRenderer } = {
	ArrowSequence = require(script.Parent.PuzzleRenderers.ArrowSequence),
}

type PresentedPuzzle = {
	id: number,
	renderer: Types.PuzzleRenderer,
	expiresAt: number,
	submitted: boolean,
}

local layout = Config.PUZZLE_VIEW
local PuzzleController = {}

local function addCorner(parent: GuiObject)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, layout.cornerRadius)
	corner.Parent = parent
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

function PuzzleController.start(arena: Model)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	assert(playerGui:IsA("PlayerGui"), "PlayerGui를 찾을 수 없습니다.")

	local gui = Instance.new("ScreenGui")
	gui.Name = "PuzzleControls"
	gui.ResetOnSpawn = false
	local panel = Instance.new("Frame")
	panel.Name = "PuzzlePanel"
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.fromScale(1 - layout.right, layout.centerY)
	panel.Size = UDim2.fromScale(layout.width, layout.height)
	panel.BackgroundColor3 = Color3.fromRGB(19, 29, 44)
	panel.Visible = false
	panel.Parent = gui
	addCorner(panel)

	local innerWidth = 1 - 2 * layout.inset
	local title = createLabel(panel, "Title", Color3.fromRGB(232, 240, 255))
	title.Position = UDim2.fromScale(layout.inset, layout.titleTop)
	title.Size = UDim2.fromScale(innerWidth, layout.titleHeight)
	title.Text = "화살표 순서"

	local body = Instance.new("Frame")
	body.Name = "PuzzleBody"
	body.Position = UDim2.fromScale(layout.inset, layout.bodyTop)
	body.Size = UDim2.fromScale(innerWidth, layout.bodyHeight)
	body.BackgroundTransparency = 1
	body.Parent = panel

	local status = createLabel(panel, "Status", Color3.fromRGB(175, 202, 236))
	status.Position = UDim2.fromScale(layout.inset, layout.footerTop)
	status.Size = UDim2.fromScale(innerWidth, layout.footerHeight)

	local buff = createLabel(gui, "Buff", Color3.fromRGB(255, 229, 165))
	buff.AnchorPoint = Vector2.new(1, 1)
	buff.Position = UDim2.fromScale(1 - layout.right, 1 - layout.badgeBottom)
	buff.Size = UDim2.fromScale(layout.width, layout.badgeHeight)
	buff.BackgroundColor3 = Color3.fromRGB(68, 49, 19)
	buff.BackgroundTransparency = 0
	buff.Visible = false
	addCorner(buff)
	gui.Parent = playerGui

	local active: PresentedPuzzle? = nil
	local resultUntil = 0
	local playing = false

	local function clearPuzzle()
		local puzzle = active
		if puzzle then
			puzzle.renderer.cleanup()
			active = nil
		end
		resultUntil = 0
		panel.Visible = false
	end

	local function showResult(message: string, now: number)
		clearPuzzle()
		status.Text = message
		panel.Visible = true
		resultUntil = now + layout.resultDuration
	end

	local function syncPlaying()
		playing = arena:GetAttribute("Phase") == "Playing" and arena:GetAttribute("PlayerUserId") == player.UserId
		if not playing then
			clearPuzzle()
			buff.Visible = false
		end
	end

	arena:GetAttributeChangedSignal("Phase"):Connect(syncPlaying)
	arena:GetAttributeChangedSignal("PlayerUserId"):Connect(syncPlaying)
	syncPlaying()

	-- 2026-11-19 퍼즐 수신 지연을 반영해 서버 마감 시각까지 남은 시간만 표시
	Remotes.PuzzleIssued.OnClientEvent:Connect(function(id: number, kind: string, displayData: any, _timeout: number, expiresAt: number)
		local renderer = renderers[kind]
		local remaining = expiresAt - Workspace:GetServerTimeNow()
		if not playing or not renderer or remaining <= 0 then
			return
		end

		clearPuzzle()
		local puzzle: PresentedPuzzle = {
			id = id,
			renderer = renderer,
			expiresAt = expiresAt,
			submitted = false,
		}
		active = puzzle
		status.Text = string.format("%.1f초", remaining)
		renderer.render(body, displayData, function(submission)
			if active ~= puzzle or puzzle.submitted or Workspace:GetServerTimeNow() >= puzzle.expiresAt then
				return
			end
			puzzle.submitted = true
			status.Text = "판정 중"
			Remotes.PuzzleSubmit:FireServer(puzzle.id, submission)
		end)
		panel.Visible = true
	end)

	Remotes.PuzzleResult.OnClientEvent:Connect(function(id: number, success: boolean)
		local puzzle = active
		if puzzle and puzzle.id == id then
			local message = if success then "성공" elseif puzzle.submitted then "실패" else "시간 초과"
			showResult(message, Workspace:GetServerTimeNow())
		end
	end)

	RunService.Heartbeat:Connect(function()
		if not playing then
			return
		end
		local now = Workspace:GetServerTimeNow()
		local buffUntil = arena:GetAttribute("BuffUntil")
		local buffRemaining = if typeof(buffUntil) == "number" then buffUntil - now else 0
		buff.Visible = buffRemaining > 0
		if buff.Visible then
			buff.Text = string.format("당기는 힘 ×%.1f  %.1f초", Config.BUFF_MULT, buffRemaining)
		end

		local puzzle = active
		if puzzle then
			if not puzzle.submitted then
				local remaining = puzzle.expiresAt - now
				if remaining > 0 then
					status.Text = string.format("%.1f초", remaining)
				else
					showResult("시간 초과", now)
				end
			end
		elseif panel.Visible and now >= resultUntil then
			clearPuzzle()
		end
	end)
end

return PuzzleController
