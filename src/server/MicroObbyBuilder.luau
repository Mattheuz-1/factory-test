local Workspace = game:GetService("Workspace")

local Builder = {}

local function vector3(values)
return Vector3.new(values[1], values[2], values[3])
end

local function makePart(parent, definition, role)
local part = Instance.new("Part")

part.Name = definition.name
part.Anchored = true
part.Size = vector3(definition.size)
part.Position = vector3(definition.position)
part.Material = Enum.Material.SmoothPlastic
part:SetAttribute("TestRole", role)

if role == "Checkpoint" then
part.CanCollide = false
part.CanTouch = true
part.Transparency = 0.25
part.Color = Color3.fromRGB(255, 213, 79)
elseif role == "Goal" then
part.CanCollide = false
part.CanTouch = true
part.Transparency = 0.25
part.Color = Color3.fromRGB(80, 220, 120)
elseif role == "KillPlane" then
part.CanCollide = false
part.CanTouch = true
part.Transparency = 0.5
part.Color = Color3.fromRGB(220, 70, 70)
else
part.CanCollide = true
part.CanTouch = true
end

part.Parent = parent
return part
end

function Builder.build(spec)
local worldSpec = spec.world

local existing = Workspace:FindFirstChild(worldSpec.modelName)
if existing then
existing:Destroy()
end

if worldSpec.removeDefaultBaseplate then
local baseplate = Workspace:FindFirstChild("Baseplate")
if baseplate then
baseplate:Destroy()
end
end

local model = Instance.new("Model")
model.Name = worldSpec.modelName
model.Parent = Workspace

for _, definition in worldSpec.platforms do
makePart(model, definition, "Platform")
end

local spawnSpec = worldSpec.spawn
local spawn = Instance.new("SpawnLocation")
spawn.Name = spawnSpec.name
spawn.Anchored = true
spawn.Size = vector3(spawnSpec.size)
spawn.Position = vector3(spawnSpec.position)
spawn.Neutral = true
spawn.CanCollide = true
spawn.CanTouch = true
spawn:SetAttribute("TestRole", "Spawn")
spawn.Parent = model

makePart(model, worldSpec.checkpoint, "Checkpoint")
makePart(model, worldSpec.goal, "Goal")
makePart(model, worldSpec.killPlane, "KillPlane")

return model
end

return Builder