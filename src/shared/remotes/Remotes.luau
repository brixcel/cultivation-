--!strict
-- shared/remotes/Remotes.luau
-- Every RemoteEvent/RemoteFunction is defined and fetched from here, nowhere else.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()
local FOLDER_NAME = "Remotes"

export type RemoteKind = "RemoteEvent" | "RemoteFunction"

local DEFINITIONS: { [string]: RemoteKind } = {
	SetMeditating = "RemoteEvent",
	Notify = "RemoteEvent",
}

local Remotes = {}
local cache: { [string]: Instance } = {}

local function getFolder(): Folder
	if IS_SERVER then
		local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME) :: Folder?
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = FOLDER_NAME
			folder.Parent = ReplicatedStorage
		end
		return folder :: Folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

function Remotes.Get(name: string): RemoteEvent | RemoteFunction
	local cached = cache[name]
	if cached then
		return cached :: any
	end

	local kind = DEFINITIONS[name]
	assert(kind, `Remotes.Get: unknown remote "{name}"`)

	local folder = getFolder()
	local instance: Instance

	if IS_SERVER then
		instance = folder:FindFirstChild(name) :: Instance
		if not instance then
			instance = Instance.new(kind)
			instance.Name = name
			instance.Parent = folder
		end
	else
		instance = folder:WaitForChild(name)
	end

	cache[name] = instance
	return instance :: any
end

return Remotes
