--!strict
-- 2026-11-19 단순 도형 경기장과 서버 줄 위치 보간 표시 추가

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local RopeView = {}

local function createPart(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Parent = parent
	return part
end

function RopeView.start(arena: Model)
	local view = Config.ARENA_VIEW
	local visuals = Instance.new("Folder")
	visuals.Name = "PullPanicArenaView"
	visuals.Parent = Workspace

	createPart(visuals, "Floor", Vector3.new(view.width, view.floorThickness, view.depth),
		Vector3.new(0, -view.floorThickness / 2, 0), Color3.fromRGB(44, 52, 65))
	createPart(visuals, "CenterLine", Vector3.new(view.centerLineWidth, view.centerLineWidth, view.depth),
		Vector3.zero, Color3.fromRGB(217, 226, 233))
	local endLineSize = Vector3.new(view.endLineWidth, view.centerLineWidth, view.depth)
	createPart(visuals, "PlayerLine", endLineSize, Vector3.new(-view.travel, 0, 0), Color3.fromRGB(73, 147, 255))
	createPart(visuals, "BotLine", endLineSize, Vector3.new(view.travel, 0, 0), Color3.fromRGB(255, 117, 72))

	local center = Vector3.new(0, view.ropeHeight, 0)
	local rope = createPart(visuals, "Rope", Vector3.new(view.ropeLength, view.ropeThickness, view.ropeThickness),
		center, Color3.fromRGB(202, 154, 92))
	local knot = createPart(visuals, "Knot", Vector3.one * view.knotSize, center, Color3.fromRGB(255, 223, 120))

	local function updateCamera()
		local camera = Workspace.CurrentCamera
		if camera then
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = CFrame.lookAt(Vector3.new(0, view.cameraHeight, view.cameraDistance), Vector3.zero)
			camera.Focus = CFrame.new(Vector3.zero)
		end
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateCamera)
	updateCamera()

	local function readPosition(): number
		local value = arena:GetAttribute("RopePosition")
		return if typeof(value) == "number" then value else 0
	end
	local function drawPosition(position: number)
		local x = -position / Config.ROPE_LIMIT * view.travel
		local centerPosition = Vector3.new(x, view.ropeHeight, 0)
		rope.Position = centerPosition
		knot.Position = centerPosition
	end

	local targetPosition = readPosition()
	local shownPosition = targetPosition
	local fromPosition = targetPosition
	local elapsed = 0
	drawPosition(shownPosition)
	arena:GetAttributeChangedSignal("RopePosition"):Connect(function()
		fromPosition = shownPosition
		targetPosition = readPosition()
		elapsed = 0
	end)
	RunService.PreRender:Connect(function(dt: number)
		if shownPosition == targetPosition then
			return
		end
		elapsed += dt
		local alpha = math.min(elapsed / Config.ROPE_REPLICATE_INTERVAL, 1)
		shownPosition = if alpha == 1 then targetPosition else fromPosition + (targetPosition - fromPosition) * alpha
		drawPosition(shownPosition)
	end)
end

return RopeView
