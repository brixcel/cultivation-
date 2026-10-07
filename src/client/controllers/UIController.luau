--!strict
-- client/controllers/UIController.luau
-- HUD: Qi bar, realm label, Cultivate/Circulate/Breakthrough buttons, toast
-- notifications. Reads truth from Player attributes, which the server keeps in
-- sync; this controller only renders them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.remotes.Remotes)

local player = Players.LocalPlayer
local TOAST_DURATION = 2.5

local UIController = {}

local function createQiBar(parent: Instance): (Frame, Frame, TextLabel)
	local frame = Instance.new("Frame")
	frame.Name = "QiBar"
	frame.Size = UDim2.fromOffset(280, 24)
	frame.Position = UDim2.new(0.5, -140, 0, 70)
	frame.BackgroundColor3 = Color3.fromRGB(20, 25, 22)
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
	fill.BorderSizePixel = 0
	fill.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(235, 240, 245)
	label.Text = "0 / 0 Qi"
	label.Parent = frame

	return frame, fill, label
end

function UIController:Init(controllers: { [string]: any })
	self._meditationController = controllers.MeditationController
	self._circulationController = controllers.QiCirculationController
end

function UIController:Start()
	local playerGui = player:WaitForChild("PlayerGui")

	local screen = Instance.new("ScreenGui")
	screen.Name = "CultivationHud"
	screen.ResetOnSpawn = false
	screen.Parent = playerGui

	local realmLabel = Instance.new("TextLabel")
	realmLabel.Name = "RealmLabel"
	realmLabel.Size = UDim2.fromOffset(280, 32)
	realmLabel.Position = UDim2.new(0.5, -140, 0, 30)
	realmLabel.BackgroundTransparency = 1
	realmLabel.Font = Enum.Font.GothamBold
	realmLabel.TextSize = 20
	realmLabel.TextColor3 = Color3.fromRGB(212, 175, 55)
	realmLabel.Text = "Mortal"
	realmLabel.Parent = screen

	local _qiFrame, qiFill, qiLabel = createQiBar(screen)

	local cultivateButton = Instance.new("TextButton")
	cultivateButton.Name = "CultivateButton"
	cultivateButton.Size = UDim2.fromOffset(160, 44)
	cultivateButton.Position = UDim2.new(0.5, -80, 0, 110)
	cultivateButton.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
	cultivateButton.Font = Enum.Font.GothamBold
	cultivateButton.TextSize = 18
	cultivateButton.TextColor3 = Color3.fromRGB(235, 240, 245)
	cultivateButton.Text = "Cultivate"
	cultivateButton.Parent = screen

	local meditationController = self._meditationController
	cultivateButton.Activated:Connect(function()
		meditationController:Toggle()
	end)

	local circulateButton = Instance.new("TextButton")
	circulateButton.Name = "CirculateButton"
	circulateButton.Size = UDim2.fromOffset(160, 44)
	circulateButton.Position = UDim2.new(0.5, -80, 0, 160)
	circulateButton.BackgroundColor3 = Color3.fromRGB(212, 175, 55)
	circulateButton.Font = Enum.Font.GothamBold
	circulateButton.TextSize = 18
	circulateButton.TextColor3 = Color3.fromRGB(20, 25, 22)
	circulateButton.Text = "Circulate"
	circulateButton.Parent = screen

	local circulationController = self._circulationController
	circulateButton.Activated:Connect(function()
		circulationController:StartCycle()
	end)

	local breakthroughButton = Instance.new("TextButton")
	breakthroughButton.Name = "BreakthroughButton"
	breakthroughButton.Size = UDim2.fromOffset(160, 44)
	breakthroughButton.Position = UDim2.new(0.5, -80, 0, 210)
	breakthroughButton.BackgroundColor3 = Color3.fromRGB(150, 60, 200)
	breakthroughButton.Font = Enum.Font.GothamBold
	breakthroughButton.TextSize = 18
	breakthroughButton.TextColor3 = Color3.fromRGB(235, 240, 245)
	breakthroughButton.Text = "Breakthrough"
	breakthroughButton.Parent = screen

	breakthroughButton.Activated:Connect(function()
		local attemptBreakthrough = Remotes.Get("AttemptBreakthrough") :: RemoteEvent
		attemptBreakthrough:FireServer()
	end)

	local toastLabel = Instance.new("TextLabel")
	toastLabel.Name = "ToastLabel"
	toastLabel.Size = UDim2.fromOffset(320, 28)
	toastLabel.Position = UDim2.new(0.5, -160, 0, 265)
	toastLabel.BackgroundTransparency = 1
	toastLabel.Font = Enum.Font.Gotham
	toastLabel.TextSize = 15
	toastLabel.TextColor3 = Color3.fromRGB(220, 70, 70)
	toastLabel.Text = ""
	toastLabel.Parent = screen

	local notify = Remotes.Get("Notify") :: RemoteEvent
	notify.OnClientEvent:Connect(function(text: string, _kind: string?)
		toastLabel.Text = text
		task.delay(TOAST_DURATION, function()
			if toastLabel.Text == text then
				toastLabel.Text = ""
			end
		end)
	end)

	local onboardingLabel = Instance.new("TextLabel")
	onboardingLabel.Name = "OnboardingHint"
	onboardingLabel.Size = UDim2.fromOffset(340, 50)
	onboardingLabel.Position = UDim2.new(0.5, -170, 0, 300)
	onboardingLabel.BackgroundTransparency = 1
	onboardingLabel.Font = Enum.Font.Gotham
	onboardingLabel.TextWrapped = true
	onboardingLabel.TextSize = 14
	onboardingLabel.TextColor3 = Color3.fromRGB(190, 195, 200)
	onboardingLabel.Text = "Press Cultivate to begin meditating. Once meditating, try Circulate for faster Qi!"
	onboardingLabel.Parent = screen

	local function refresh()
		local realm = player:GetAttribute("Realm")
		local qi = player:GetAttribute("Qi")
		local qiMax = player:GetAttribute("QiMax")
		local tutorialDone = player:GetAttribute("TutorialDone")

		if realm then
			realmLabel.Text = tostring(realm)
		end

		if typeof(qi) == "number" and typeof(qiMax) == "number" and qiMax > 0 then
			qiFill.Size = UDim2.fromScale(math.clamp(qi / qiMax, 0, 1), 1)
			qiLabel.Text = `{math.floor(qi)} / {math.floor(qiMax)} Qi`
		end

		onboardingLabel.Visible = tutorialDone ~= true
		cultivateButton.Text = if meditationController:IsMeditating() then "Stop" else "Cultivate"
	end

	player.AttributeChanged:Connect(refresh)
	refresh()

	print("[UIController] started")
end

return UIController
