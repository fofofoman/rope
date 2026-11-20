--!strict
-- 2026-11-19 클라이언트 진입점에서 공용 설정과 RemoteEvent 초기화 확인

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Types = require(Shared.Types)

-- 2026-11-19 서버 경기장에 줄 화면과 연타 입력 연결
local MashController = require(script.Parent.MashController)
local RopeView = require(script.Parent.RopeView)
-- 2026-11-19 기존 연타 조작과 별도로 오른쪽 퍼즐 UI 시작
local PuzzleController = require(script.Parent.PuzzleController)
-- 2026-11-20 HUD와 모바일 기본 터치 컨트롤 숨김 연결
local HudController = require(script.Parent.HudController)
local MobileLayout = require(script.Parent.MobileLayout)
Remotes.MatchState.OnClientEvent:Connect(function(phase: Types.MatchPhase, _timeLeft: number, extra: Types.MatchStateExtra?)
	if phase == "Ended" and extra and Config.DEBUG and RunService:IsStudio() then
		local result = if extra.winner == "A" then "플레이어 승리" elseif extra.winner == "B" then "Normal 봇 승리" else "무승부"
		print("[PullPanic] " .. result)
	end
end)

local arena = Workspace:WaitForChild(Config.ARENA_NAME)
assert(arena:IsA("Model"), "경기장은 Model이어야 합니다.")
RopeView.start(arena)
MashController.start(arena)
PuzzleController.start(arena)
MobileLayout.start()
HudController.start(arena)

if Config.DEBUG and RunService:IsStudio() then
	print("[PullPanic] 클라이언트 초기화 완료")
end
