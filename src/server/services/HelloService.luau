--!strict
-- Phase 0 smoke test: a part that changes color when touched. Remove in Phase 1.
local Players = game:GetService("Players")

local HelloService = {}

local COLORS = {
	Color3.fromRGB(46, 139, 87), -- jade
	Color3.fromRGB(212, 175, 55), -- gold
	Color3.fromRGB(235, 240, 245), -- mist
}

function HelloService:Init(_services: { [string]: any })
	self._colorIndex = 1
end

function HelloService:Start()
	local part = Instance.new("Part")
	part.Name = "HelloPart"
	part.Size = Vector3.new(6, 1, 6)
	part.Position = Vector3.new(0, 0.5, -15)
	part.Anchored = true
	part.Color = COLORS[1]
	part.Parent = workspace

	local debounce = false
	part.Touched:Connect(function(hit: BasePart)
		if debounce or not Players:GetPlayerFromCharacter(hit.Parent) then
			return
		end
		debounce = true
		self._colorIndex = self._colorIndex % #COLORS + 1
		part.Color = COLORS[self._colorIndex]
		print(`[HelloService] HelloPart touched, color {self._colorIndex}`)
		task.wait(0.5)
		debounce = false
	end)

	print("[HelloService] started")
end

return HelloService
