--!strict
-- client/controllers/InputController.luau
-- Maps PC (Space bar) and mobile (on-screen tap button, wired by
-- QiCirculationController) input to one Tapped signal.

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Shared.util.Signal)

local InputController = {}

function InputController:Init(_controllers: { [string]: any })
	self.Tapped = Signal.new()
end

function InputController:Start()
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then
			return
		end
		if input.KeyCode == Enum.KeyCode.Space then
			self.Tapped:Fire()
		end
	end)

	print("[InputController] started")
end

-- Called by the on-screen mobile tap button; kept separate from InputBegan so a raw
-- touch anywhere on screen doesn't double-count as a tap.
function InputController:FireTap()
	self.Tapped:Fire()
end

return InputController
