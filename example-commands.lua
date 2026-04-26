--[[
  Example MongoDB Lua Commands
  
  Copy these into the web UI to test the system
]]

-- Example 1: Simple Print with Variables
[[
print("Received command from MongoDB!")
print("Target player:", variables.targetPlayer or "none")
print("Message:", variables.message or "Hello!")
]]

-- Variables:
[[
{
  "targetPlayer": "Player1",
  "message": "Welcome to the game!"
}
]]

-- Example 2: Teleport with Coordinates
[[
local pos = variables.position or {x=0, y=0, z=0}
print("Teleporting to coordinates:")
print("X:", pos.x, "Y:", pos.y, "Z:", pos.z)

-- In Roblox, you'd do:
-- player.Character:SetPrimaryPartCFrame(CFrame.new(pos.x, pos.y, pos.z))
]]

-- Variables:
[[
{
  "position": {"x": 100, "y": 50, "z": -200}
}
]]

-- Example 3: Spawn Items
[[
local item = variables.itemType or "Sword"
local quantity = variables.quantity or 1
local rarity = variables.rarity or "common"

print("Spawning", quantity, rarity, item)

for i = 1, quantity do
    print("Spawned", item, "#" .. i)
end
]]

-- Variables:
[[
{
  "itemType": "Legendary Sword",
  "quantity": 5,
  "rarity": "legendary"
}
]]

-- Example 4: Conditional Logic Based on Variables
[[
local mode = variables.mode or "normal"
local health = variables.playerHealth or 100

if mode == "god" then
    print("God mode activated!")
    -- player.Character.Humanoid.MaxHealth = math.huge
elseif mode == "heal" then
    print("Healing player...")
    -- player.Character.Humanoid.Health = player.Character.Humanoid.MaxHealth
else
    print("Normal mode, current health:", health)
end
]]

-- Variables:
[[
{
  "mode": "heal",
  "playerHealth": 45
}
]]

-- Example 5: Loop with MongoDB Data
[[
local waypoints = variables.waypoints or {}
local delay = variables.delay or 1

print("Following", #waypoints, "waypoints")

for i, point in ipairs(waypoints) do
    print("Moving to waypoint", i, ":", point.x, point.y, point.z)
    -- Move to point here
    wait(delay)
end

print("Route complete!")
]]

-- Variables:
[[
{
  "waypoints": [
    {"x": 0, "y": 0, "z": 0},
    {"x": 50, "y": 0, "z": 50},
    {"x": 100, "y": 0, "z": 0}
  ],
  "delay": 2
}
]]
