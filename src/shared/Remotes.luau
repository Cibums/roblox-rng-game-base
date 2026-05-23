local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()

local REMOTE_NAMES = {
	"UpdateBalance",
	"RequestBalance",
}

local folder
if IS_SERVER then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage

	for _, name in REMOTE_NAMES do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes", 10)
end

local Remotes = {}
for _, name in REMOTE_NAMES do
	if IS_SERVER then
		Remotes[name] = folder:FindFirstChild(name)
	else
		Remotes[name] = folder:WaitForChild(name, 10)
	end
end

return Remotes