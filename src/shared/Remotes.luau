local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()

local REMOTE_EVENT_NAMES = {
	"UpdateBalance",
	"RequestBalance",
	"ShowOfflineEarnings",
	"ShowGachaResult",
	"ShowDailyStreak",
}

local REMOTE_FUNCTION_NAMES = {
	"RollGacha",
	"GetInventory",
	"EquipPet", 
	"UnequipPet",
	"EquipBest",
}

local folder
if IS_SERVER then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
	for _, name in REMOTE_EVENT_NAMES do
		local r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = folder
	end
	for _, name in REMOTE_FUNCTION_NAMES do
		local r = Instance.new("RemoteFunction")
		r.Name = name
		r.Parent = folder
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes", 10)
end

local Remotes = {}
for _, name in REMOTE_EVENT_NAMES do
	Remotes[name] = IS_SERVER and folder:FindFirstChild(name) or folder:WaitForChild(name, 10)
end
for _, name in REMOTE_FUNCTION_NAMES do
	Remotes[name] = IS_SERVER and folder:FindFirstChild(name) or folder:WaitForChild(name, 10)
end

return Remotes