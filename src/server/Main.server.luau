--!strict
-- 2026-11-19 서버 진입점에서 공용 설정과 RemoteEvent 초기화 확인

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

-- 2026-11-19 서버 시작 시 1대1 경기 서비스를 실행
local MatchService = require(script.Parent.MatchService)
MatchService.start()

if Config.DEBUG and RunService:IsStudio() then
	print("[PullPanic] 서버 초기화 완료")
end
