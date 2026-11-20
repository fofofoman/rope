--!strict
-- 2026-11-20 모바일에서 로블록스 기본 터치 컨트롤(썸스틱, 점프 버튼) 숨김

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local MobileLayout = {}

function MobileLayout.start()
	if not UserInputService.TouchEnabled then
		return
	end

	-- PlayerModule 로드를 기다려야 하므로 별도 스레드에서 처리한다.
	task.spawn(function()
		local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
		local moduleScript = playerScripts:WaitForChild("PlayerModule")
		if not moduleScript:IsA("ModuleScript") then
			warn("[PullPanic] PlayerModule을 찾을 수 없어 기본 터치 컨트롤을 숨기지 못했습니다.")
			return
		end

		local ok, result = pcall(function()
			local playerModule: any = require(moduleScript)
			playerModule:GetControls():Disable()
		end)
		if not ok then
			warn("[PullPanic] 기본 터치 컨트롤을 숨기지 못했습니다: " .. tostring(result))
		end
	end)
end

return MobileLayout
