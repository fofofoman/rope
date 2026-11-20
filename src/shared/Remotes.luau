--!strict
-- 2026-11-19 Rojo에서 생성한 RemoteEvent 참조를 공용 모듈에서 제공

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(script.Parent.Types)

local remoteFolder = ReplicatedStorage:WaitForChild("Remotes")
assert(remoteFolder:IsA("Folder"), "ReplicatedStorage.Remotes는 Folder여야 합니다.")

local function waitForRemote(name: string): RemoteEvent
	local remote = remoteFolder:WaitForChild(name)
	assert(remote:IsA("RemoteEvent"), name .. "은 RemoteEvent여야 합니다.")
	return remote
end

local remotes: Types.RemoteEvents = {
	MashBatch = waitForRemote("MashBatch"),
	QteIssued = waitForRemote("QteIssued"),
	QteResponse = waitForRemote("QteResponse"),
	PuzzleIssued = waitForRemote("PuzzleIssued"),
	PuzzleSubmit = waitForRemote("PuzzleSubmit"),
	PuzzleResult = waitForRemote("PuzzleResult"),
	MatchState = waitForRemote("MatchState"),
	-- 2026-11-20 재시작 요청 Remote 참조 추가
	MatchRestart = waitForRemote("MatchRestart"),
}

return remotes
