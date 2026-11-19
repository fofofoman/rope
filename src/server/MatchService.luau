--!strict
-- 2026-11-19 플레이어와 Normal 봇의 경기 진행 및 서버 상태 복제 추가

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Types = require(Shared.Types)
local BotService = require(script.Parent.BotService)
local MashService = require(script.Parent.MashService)
local Match = require(script.Parent.Match)
local PuzzleService = require(script.Parent.PuzzleService)

type Round = {
	player: Player,
	participant: Types.ParticipantState,
	mashInput: MashService.InputState,
	puzzleSchedule: PuzzleService.Schedule,
	match: Match.Match,
	replicateElapsed: number,
	lastPhase: Types.MatchPhase?,
	lastTimeLeft: number?,
}

local MatchService = {}

local function publishState(arena: Model, round: Round)
	local match = round.match
	local phase = match.phase
	local timeLeft = math.ceil(match.timeLeft)
	local phaseChanged = round.lastPhase ~= phase
	if not phaseChanged and round.lastTimeLeft == timeLeft then
		return
	end

	round.lastPhase = phase
	round.lastTimeLeft = timeLeft
	if phaseChanged then
		arena:SetAttribute("Phase", phase)
	end
	local winner = match.winner
	local extra: Types.MatchStateExtra? = if winner then { winner = winner } else nil
	Remotes.MatchState:FireClient(round.player, phase, timeLeft, extra)
end

function MatchService.start()
	Players.CharacterAutoLoads = false

	local arena = Instance.new("Model")
	arena.Name = Config.ARENA_NAME
	arena.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	arena:SetAttribute("RopePosition", 0)
	arena:SetAttribute("Phase", "Waiting")
	arena:SetAttribute("BuffUntil", 0)
	arena.Parent = Workspace

	local activeRound: Round? = nil
	local function startRound(player: Player)
		local participant: Types.ParticipantState = { rawTps = 0, buffUntil = 0, stunUntil = 0 }
		local match = Match.new({ A = { participant }, B = { BotService.createNormalParticipant() } })
		match:start()
		local round: Round = {
			player = player,
			participant = participant,
			mashInput = MashService.newInputState(),
			puzzleSchedule = PuzzleService.newSchedule(),
			match = match,
			replicateElapsed = 0,
			lastPhase = nil,
			lastTimeLeft = nil,
		}
		activeRound = round
		arena:SetAttribute("PlayerUserId", player.UserId)
		arena:SetAttribute("RopePosition", match.ropePosition)
		arena:SetAttribute("BuffUntil", 0)
		publishState(arena, round)
	end

	local function startForFirstPlayer(excluded: Player?)
		for _, player in Players:GetPlayers() do
			if player ~= excluded then
				startRound(player)
				return
			end
		end
	end

	Remotes.MashBatch.OnServerEvent:Connect(function(player: Player, count: unknown)
		local round = activeRound
		if round and round.player == player and round.match.phase == "Playing" then
			MashService.acceptBatch(round.mashInput, count, Workspace:GetServerTimeNow())
		end
	end)

	-- 2026-11-19 경기 참가자의 퍼즐 제출과 버프 만료 시각 동기화
	Remotes.PuzzleSubmit.OnServerEvent:Connect(function(player: Player, id: unknown, submission: unknown)
		local round = activeRound
		if not round or round.player ~= player or round.match.phase ~= "Playing" or typeof(id) ~= "number" then
			return
		end

		local success, reward = PuzzleService.submit(round.participant, id, submission, Workspace:GetServerTimeNow())
		if success ~= nil then
			if reward == "Buff" then
				arena:SetAttribute("BuffUntil", round.participant.buffUntil)
			end
			Remotes.PuzzleResult:FireClient(player, id, success, reward)
		end
	end)

	RunService.Heartbeat:Connect(function(dt: number)
		local round = activeRound
		if not round or round.match.phase == "Ended" then
			return
		end

		local now = Workspace:GetServerTimeNow()
		local match = round.match
		round.participant.rawTps = MashService.getRawTps(round.mashInput, now)
		match:step(dt, now)
		if match.phase == "Playing" then
			local puzzle, expiredId = PuzzleService.update(round.puzzleSchedule, round.participant, now)
			if puzzle then
				-- 2026-11-19 서버가 판정에 사용하는 마감 시각을 퍼즐과 함께 전송
				Remotes.PuzzleIssued:FireClient(
					round.player, puzzle.id, puzzle.definition.kind, puzzle.displayData, Config.PUZZLE_TIMEOUT, puzzle.expiresAt
				)
			elseif expiredId then
				Remotes.PuzzleResult:FireClient(round.player, expiredId, false)
			end
		elseif match.phase == "Ended" then
			round.participant.activePuzzle = nil
			round.participant.buffUntil = 0
			arena:SetAttribute("BuffUntil", 0)
		end

		round.replicateElapsed += dt
		if match.phase == "Ended" or round.replicateElapsed >= Config.ROPE_REPLICATE_INTERVAL then
			round.replicateElapsed %= Config.ROPE_REPLICATE_INTERVAL
			arena:SetAttribute("RopePosition", match.ropePosition)
		end
		publishState(arena, round)
	end)

	Players.PlayerAdded:Connect(function(player: Player)
		if not activeRound then
			startRound(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		local round = activeRound
		if round and round.player == player then
			activeRound = nil
			arena:SetAttribute("Phase", "Waiting")
			arena:SetAttribute("PlayerUserId", nil)
			arena:SetAttribute("RopePosition", 0)
			arena:SetAttribute("BuffUntil", 0)
			startForFirstPlayer(player)
		end
	end)
	startForFirstPlayer(nil)
end

return MatchService
