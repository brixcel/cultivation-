--!strict
-- client/controllers/AuraController.luau
-- Shows every player's realm/title above their head, so others can see your
-- progress. Reads only from Player attributes the server already syncs.

local Players = game:GetService("Players")

local AuraController = {}

function AuraController:Init(_controllers: { [string]: any }) end

local function attachBillboard(player: Player, character: Model)
	local head = character:WaitForChild("Head", 5)
	if not head then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RealmBillboard"
	billboard.Size = UDim2.fromOffset(160, 36)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(212, 175, 55)
	label.TextStrokeTransparency = 0.5
	label.Text = ""
	label.Parent = billboard

	local function refresh()
		local title = player:GetAttribute("Title")
		local realm = player:GetAttribute("Realm")
		label.Text = tostring(if title ~= nil then title else (if realm ~= nil then realm else ""))
	end

	player.AttributeChanged:Connect(refresh)
	refresh()
end

function AuraController:Start()
	local function onPlayer(player: Player)
		if player.Character then
			attachBillboard(player, player.Character)
		end
		player.CharacterAdded:Connect(function(character: Model)
			attachBillboard(player, character)
		end)
	end

	for _, existingPlayer in Players:GetPlayers() do
		onPlayer(existingPlayer)
	end
	Players.PlayerAdded:Connect(onPlayer)

	print("[AuraController] started")
end

return AuraController
