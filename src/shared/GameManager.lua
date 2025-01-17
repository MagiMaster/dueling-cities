local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Convert = ReplicatedStorage:WaitForChild("Convert")
local GunScript = require(ReplicatedStorage:WaitForChild("Gun"))
local Building = require(ReplicatedStorage:WaitForChild("Building"))

local buildings = {}
local Gun = nil

-- Client functions

local function onCharacterAddedClient(character)
	local GunModel = character:WaitForChild("Gun")
	GunModel.Handle.WeldConstraint.Part1 = character.RightHand
	GunModel.Handle.Position = character.RightHand.Position

	Gun = GunScript.new(GunModel.Handle, GunModel.Target, Convert)
	Gun:connectToUserInput()
end

local function onCharacterRemovingClient()
	Gun:cleanup()
	Gun = nil
end

local function initClient()
    local localPlayer = Players.LocalPlayer
    localPlayer.CharacterAdded:Connect(onCharacterAddedClient)
    localPlayer.CharacterRemoving:Connect(onCharacterRemovingClient)

    for _, part in workspace:GetChildren() do
        if part:IsA("Model") and part:FindFirstChild("OldVersion") then
            -- This assumes that buildings aren't created or destroyed.
            local building = Building.new(part)
            building:initClient()
        end
    end
end

-- Server functions

local function hitBuilding(instance: Instance, team: Team)
	local model = instance:FindFirstAncestorWhichIsA("Model")
	local building = buildings[model]
	if building then
		building:onHit(team)
	end
end

local function onPlayerAdded(player)
	local added = nil
	local removing = nil
	local gun = nil

	local function onCharacterAddedServer(character)
		local gunModel = character.Gun
		gun = GunScript.new(gunModel.Handle, gunModel.Target, Convert)
		gun:connectToServerEvent()
		gun.onHit.Event:Connect(hitBuilding)
	end

	local function onCharacterRemovingServer()
		if added then
			added:Disconnect()
			added = nil
		end
		if removing then
			removing:Disconnect()
			removing = nil
		end
		if gun then
			gun:cleanup()
			gun = nil
		end
	end

	player.CharacterAdded:Connect(onCharacterAddedServer)
	player.CharacterRemoving:Connect(onCharacterRemovingServer)
end

local function initServer()
    Players.PlayerAdded:Connect(onPlayerAdded)

    for _, part in workspace:GetChildren() do
        if part:IsA("Model") and part:FindFirstChild("OldVersion") then
            -- This assumes that buildings aren't created or destroyed.
            local building = Building.new(part)
            buildings[part] = building
            building:initServer()
        end
    end
end

return  {
    initClient = initClient,
    initServer = initServer,
}