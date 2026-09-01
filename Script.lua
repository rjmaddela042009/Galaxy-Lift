-- GALAXY LIFTING - ALL IN ONE
-- For your own Roblox Studio game

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DATA = DataStoreService:GetDataStore("GalaxyLifting_V1")

--==================================================
-- SETTINGS
--==================================================

local LIFT_AMOUNT = 1
local COINS_PER_LIFT = 1
local AUTO_INTERVAL = 1

local BASE_REBIRTH_COST = 1000
local BASE_SPEED_COST = 100

local EGG_COST = 500

--==================================================
-- REMOTES
--==================================================

local Remotes = ReplicatedStorage:FindFirstChild("GalaxyRemotes")

if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "GalaxyRemotes"
	Remotes.Parent = ReplicatedStorage
end

local function makeRemote(name)
	local remote = Remotes:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = Remotes
	end

	return remote
end

local LiftRemote = makeRemote("Lift")
local RebirthRemote = makeRemote("Rebirth")
local HatchRemote = makeRemote("Hatch")
local SpeedRemote = makeRemote("Speed")
local AutoRemote = makeRemote("Auto")
local WorldRemote = makeRemote("World")

--==================================================
-- PLAYER DATA
--==================================================

local function setupPlayer(player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local Strength = Instance.new("IntValue")
	Strength.Name = "Strength"
	Strength.Value = 0
	Strength.Parent = leaderstats

	local Coins = Instance.new("IntValue")
	Coins.Name = "Coins"
	Coins.Value = 0
	Coins.Parent = leaderstats

	local Rebirths = Instance.new("IntValue")
	Rebirths.Name = "Rebirths"
	Rebirths.Value = 0
	Rebirths.Parent = leaderstats

	local SpeedLevel = Instance.new("IntValue")
	SpeedLevel.Name = "SpeedLevel"
	SpeedLevel.Value = 0
	SpeedLevel.Parent = player

	local World = Instance.new("IntValue")
	World.Name = "World"
	World.Value = 1
	World.Parent = player

	local AutoLift = Instance.new("BoolValue")
	AutoLift.Name = "AutoLift"
	AutoLift.Value = false
	AutoLift.Parent = player

	local Pets = Instance.new("Folder")
	Pets.Name = "Pets"
	Pets.Parent = player

	-- LOAD DATA
	local success, data = pcall(function()
		return DATA:GetAsync("Player_" .. player.UserId)
	end)

	if success and data then
		Strength.Value = data.Strength or 0
		Coins.Value = data.Coins or 0
		Rebirths.Value = data.Rebirths or 0
		SpeedLevel.Value = data.SpeedLevel or 0
		World.Value = data.World or 1
	end

	player.CharacterAdded:Connect(function(character)

		local humanoid = character:WaitForChild("Humanoid")

		humanoid.WalkSpeed =
			16 + (SpeedLevel.Value * 2)

	end)
end

Players.PlayerAdded:Connect(setupPlayer)

--==================================================
-- SAVE DATA
--==================================================

local function savePlayer(player)

	local stats = player:FindFirstChild("leaderstats")

	if not stats then
		return
	end

	local data = {
		Strength = stats.Strength.Value,
		Coins = stats.Coins.Value,
		Rebirths = stats.Rebirths.Value,
		SpeedLevel = player.SpeedLevel.Value,
		World = player.World.Value
	}

	pcall(function()
		DATA:SetAsync(
			"Player_" .. player.UserId,
			data
		)
	end)
end

Players.PlayerRemoving:Connect(savePlayer)

game:BindToClose(function()

	for _, player in ipairs(Players:GetPlayers()) do
		savePlayer(player)
	end

end)

--==================================================
-- LIFTING
--==================================================

local function lift(player)

	local stats = player:FindFirstChild("leaderstats")

	if not stats then
		return
	end

	local multiplier =
		1 + stats.Rebirths.Value

	local worldMultiplier =
		player.World.Value

	local amount =
		LIFT_AMOUNT *
		multiplier *
		worldMultiplier

	stats.Strength.Value += amount
	stats.Coins.Value +=
		COINS_PER_LIFT * worldMultiplier
end

LiftRemote.OnServerEvent:Connect(function(player)

	lift(player)

end)

--==================================================
-- AUTO LIFT
--==================================================

AutoRemote.OnServerEvent:Connect(function(player, enabled)

	if typeof(enabled) ~= "boolean" then
		return
	end

	player.AutoLift.Value = enabled

end)

task.spawn(function()

	while true do

		task.wait(AUTO_INTERVAL)

		for _, player in ipairs(Players:GetPlayers()) do

			local auto =
				player:FindFirstChild("AutoLift")

			if auto and auto.Value then
				lift(player)
			end

		end

	end

end)

--==================================================
-- REBIRTH
--==================================================

RebirthRemote.OnServerEvent:Connect(function(player)

	local stats = player:FindFirstChild("leaderstats")

	if not stats then
		return
	end

	local required =
		BASE_REBIRTH_COST *
		(stats.Rebirths.Value + 1)

	if stats.Strength.Value >= required then

		stats.Strength.Value = 0

		stats.Rebirths.Value += 1

	end

end)

--==================================================
-- SPEED UPGRADES
--==================================================

SpeedRemote.OnServerEvent:Connect(function(player)

	local stats = player:FindFirstChild("leaderstats")

	if not stats then
		return
	end

	local level =
		player.SpeedLevel.Value

	local cost =
		BASE_SPEED_COST *
		(level + 1)

	if stats.Coins.Value >= cost then

		stats.Coins.Value -= cost

		player.SpeedLevel.Value += 1

		if player.Character then

			local humanoid =
				player.Character:FindFirstChildOfClass("Humanoid")

			if humanoid then

				humanoid.WalkSpeed =
					16 +
					(player.SpeedLevel.Value * 2)

			end

		end

	end

end)

--==================================================
-- EGGS / PETS
--==================================================

HatchRemote.OnServerEvent:Connect(function(player)

	local stats =
		player:FindFirstChild("leaderstats")

	if not stats then
		return
	end

	if stats.Coins.Value < EGG_COST then
		return
	end

	stats.Coins.Value -= EGG_COST

	local pets =
		player:FindFirstChild("Pets")

	if not pets then
		return
	end

	-- Random pet
	local random = math.random(1, 100)

	local petName

	if random <= 60 then
		petName = "Moon Cat"
	elseif random <= 90 then
		petName = "Galaxy Dog"
	elseif random <= 98 then
		petName = "Cosmic Dragon"
	else
		petName = "Galaxy Titan"
	end

	local pet = Instance.new("StringValue")

	pet.Name = petName
	pet.Parent = pets

end)

--==================================================
-- WORLDS
--==================================================

WorldRemote.OnServerEvent:Connect(function(player, requestedWorld)

	if typeof(requestedWorld) ~= "number" then
		return
	end

	local stats =
		player:FindFirstChild("leaderstats")

	if not stats then
		return
	end

	-- Example world requirements
	local requirements = {
		[1] = 0,
		[2] = 10000,
		[3] = 100000,
		[4] = 1000000,
		[5] = 10000000
	}

	local requirement =
		requirements[requestedWorld]

	if not requirement then
		return
	end

	if stats.Strength.Value >= requirement then

		player.World.Value =
			requestedWorld

	end

end)

--==================================================
-- DAILY / AFK REWARD
--==================================================

task.spawn(function()

	while true do

		task.wait(300)

		for _, player in ipairs(Players:GetPlayers()) do

			local stats =
				player:FindFirstChild("leaderstats")

			if stats then

				stats.Coins.Value += 1000

				stats.Strength.Value += 500

			end

		end

	end

end)

print("🌌 GALAXY LIFTING SYSTEM LOADED!")
