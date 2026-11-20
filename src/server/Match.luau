--!strict
-- 2026-11-19 경기별 상태, 줄 위치 계산과 승패 판정 추가

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local MashService = require(script.Parent.MashService)

type Teams = { A: { Types.ParticipantState }, B: { Types.ParticipantState } }
type MatchState = {
	phase: Types.MatchPhase,
	ropePosition: number,
	timeLeft: number,
	teams: Teams,
	winner: Types.MatchWinner?,
}

local Match = {}
Match.__index = Match
export type Match = typeof(setmetatable({} :: MatchState, Match))

function Match.new(teams: Teams): Match
	local state: MatchState = {
		phase = "Waiting",
		ropePosition = 0,
		timeLeft = 0,
		teams = teams,
		winner = nil,
	}
	return setmetatable(state, Match)
end

function Match.start(self: Match): ()
	if self.phase ~= "Waiting" then
		return
	end
	self.phase = "Countdown"
	self.timeLeft = Config.COUNTDOWN
end

local function getTeamForce(participants: { Types.ParticipantState }, now: number): number
	local force = 0
	for _, participant in participants do
		force += MashService.getEffectiveForce(participant, now)
	end
	return force
end

-- 2026-11-20 디버그 HUD용 양 팀 힘 조회 추가
function Match.getForces(self: Match, now: number): (number, number)
	return getTeamForce(self.teams.A, now), getTeamForce(self.teams.B, now)
end

function Match.step(self: Match, dt: number, now: number): ()
	if self.phase == "Countdown" then
		self.timeLeft -= dt
		if self.timeLeft > 0 then
			return
		end

		dt = -self.timeLeft
		self.phase = "Playing"
		self.timeLeft = Config.ROUND_DURATION
	end
	if self.phase ~= "Playing" then
		return
	end

	local playingDt = math.min(dt, self.timeLeft)
	local forceA = getTeamForce(self.teams.A, now)
	local forceB = getTeamForce(self.teams.B, now)
	local speed = (forceA - forceB) * Config.ROPE_SPEED
	local limit = Config.ROPE_LIMIT
	local target = math.clamp(self.ropePosition + speed * playingDt, -limit, limit)
	local reachedLimit = math.abs(target) == limit
	if reachedLimit and speed ~= 0 then
		playingDt = math.min(playingDt, (target - self.ropePosition) / speed)
	end

	self.ropePosition = target
	self.timeLeft -= playingDt
	if reachedLimit or self.timeLeft <= 0 then
		self.phase = "Ended"
		self.winner = if target > 0 then "A" elseif target < 0 then "B" else "Draw"
	end
end

return Match
