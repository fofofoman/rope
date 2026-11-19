--!strict
-- 2026-11-19 Normal 봇을 사람과 동일한 참가자 상태로 생성

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)

local BotService = {}

function BotService.createNormalParticipant(): Types.ParticipantState
	return { rawTps = Config.BOT.Normal.tps, buffUntil = 0, stunUntil = 0 }
end

return BotService
