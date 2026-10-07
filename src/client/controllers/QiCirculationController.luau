--!strict
-- client/controllers/QiCirculationController.luau
-- Renders the circulation minigame and collects tap timestamps. The server issues
-- the pattern/tempo and is the only source of truth for scoring; this controller
-- never computes Qi itself.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage.Shared.remotes.Remotes)

local player = Players.LocalPlayer
local SUBMIT_GRACE = 0.5 -- seconds of buffer above the nominal cycle duration before auto-submit

local QiCirculationController = {}

local function buildOverlay(): (ScreenGui, TextLabel, TextLabel, TextButton)
	local screen = Instance.new("ScreenGui")
	screen.Name = "CirculationOverlay"
	screen.ResetOnSpawn = false
	screen.Enabled = false
	screen.Parent = player:WaitForChild("PlayerGui")

	local nodeLabel = Instance.new("TextLabel")
	nodeLabel.Name = "NodeLabel"
	nodeLabel.Size = UDim2.fromOffset(300, 40)
	nodeLabel.Position = UDim2.new(0.5, -150, 0, 160)
	nodeLabel.BackgroundTransparency = 1
	nodeLabel.Font = Enum.Font.GothamBold
	nodeLabel.TextSize = 24
	nodeLabel.TextColor3 = Color3.fromRGB(212, 175, 55)
	nodeLabel.Text = ""
	nodeLabel.Parent = screen

	local feedbackLabel = Instance.new("TextLabel")
	feedbackLabel.Name = "FeedbackLabel"
	feedbackLabel.Size = UDim2.fromOffset(300, 30)
	feedbackLabel.Position = UDim2.new(0.5, -150, 0, 200)
	feedbackLabel.BackgroundTransparency = 1
	feedbackLabel.Font = Enum.Font.GothamBold
	feedbackLabel.TextSize = 18
	feedbackLabel.TextColor3 = Color3.fromRGB(235, 240, 245)
	feedbackLabel.Text = ""
	feedbackLabel.Parent = screen

	local tapButton = Instance.new("TextButton")
	tapButton.Name = "TapButton"
	tapButton.Size = UDim2.fromOffset(140, 140)
	tapButton.Position = UDim2.new(0.5, -70, 0, 240)
	tapButton.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
	tapButton.Font = Enum.Font.GothamBold
	tapButton.TextSize = 22
	tapButton.TextColor3 = Color3.fromRGB(235, 240, 245)
	tapButton.Text = "TAP"
	tapButton.Visible = UserInputService.TouchEnabled
	tapButton.Parent = screen

	return screen, nodeLabel, feedbackLabel, tapButton
end

function QiCirculationController:Init(controllers: { [string]: any })
	self._meditationController = controllers.MeditationController
	self._inputController = controllers.InputController
	self._active = false
end

function QiCirculationController:IsActive(): boolean
	return self._active
end

function QiCirculationController:Start()
	local screen, nodeLabel, feedbackLabel, tapButton = buildOverlay()
	self._screen = screen
	self._nodeLabel = nodeLabel
	self._feedbackLabel = feedbackLabel

	tapButton.Activated:Connect(function()
		self._inputController:FireTap()
	end)

	print("[QiCirculationController] started")
end

function QiCirculationController:StartCycle()
	if self._active or not self._meditationController:IsMeditating() then
		return
	end

	local requestCycle = Remotes.Get("RequestCycle") :: RemoteFunction
	local result = requestCycle:InvokeServer()
	if not result then
		return
	end

	self._active = true
	self._screen.Enabled = true
	self._feedbackLabel.Text = ""

	local pattern = result.pattern :: { string }
	local tempo = result.tempo :: number
	local cycleId = result.cycleId :: string

	local hits: { number } = {}
	local startTime = os.clock()
	self._nodeLabel.Text = pattern[1]

	local connection = self._inputController.Tapped:Connect(function()
		local index = #hits + 1
		if index > #pattern then
			return
		end
		hits[index] = os.clock() - startTime
		if index < #pattern then
			self._nodeLabel.Text = pattern[index + 1]
		end
	end)

	task.delay(#pattern * tempo + SUBMIT_GRACE, function()
		connection.Disconnect()

		local submitCycle = Remotes.Get("SubmitCycle") :: RemoteFunction
		local score = submitCycle:InvokeServer(cycleId, hits)

		self._nodeLabel.Text = ""
		if score then
			self._feedbackLabel.Text = `+{math.floor(score.qiGained)} Qi (combo x{string.format("%.2f", score.combo)})`
		else
			self._feedbackLabel.Text = "Cycle failed"
		end

		task.wait(1.5)
		self._active = false
		self._screen.Enabled = false
	end)
end

return QiCirculationController
