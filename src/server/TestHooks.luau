local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")

local TestHooks = {}

local function playerFromHit(hit)
local character = hit:FindFirstAncestorOfClass("Model")
if not character then
return nil
end

return Players:GetPlayerFromCharacter(character)
end

local function findRole(world, role)
for _, instance in world:GetDescendants() do
if instance:IsA("BasePart")
and instance:GetAttribute("TestRole") == role then
return instance
end
end

return nil
end

function TestHooks.start(spec, world)
if not spec.test.enabled then
return nil
end

local previous = ReplicatedStorage:FindFirstChild("TestState")
if previous then
previous:Destroy()
end

local state = Instance.new("Folder")
state.Name = "TestState"
state.Parent = ReplicatedStorage

state:SetAttribute("testId", spec.id)
state:SetAttribute("checkpointReached", false)
state:SetAttribute("goalReached", false)
state:SetAttribute("deathCount", 0)
state:SetAttribute("playerPosition", Vector3.zero)
state:SetAttribute("elapsedTime", 0)
state:SetAttribute("activeErrors", 0)
state:SetAttribute(
"maxElapsedSeconds",
spec.acceptance.maxElapsedSeconds
)

local startedAt = os.clock()

local checkpoint = assert(
findRole(world, "Checkpoint"),
"Checkpoint not found"
)

local goal = assert(
findRole(world, "Goal"),
"Goal not found"
)

local killPlane = assert(
findRole(world, "KillPlane"),
"KillPlane not found"
)

-- Diagnostic only.
-- External MCP console inspection remains the acceptance oracle for errors.
LogService.MessageOut:Connect(function(_, messageType)
if messageType == Enum.MessageType.MessageError then
local current = state:GetAttribute("activeErrors") or 0
state:SetAttribute("activeErrors", current + 1)
end
end)

local function bindCharacter(character)
local humanoid = character:WaitForChild("Humanoid", 5)

if not humanoid then
return
end

humanoid.Died:Connect(function()
local current = state:GetAttribute("deathCount") or 0
state:SetAttribute("deathCount", current + 1)
print("TEST_DEATH_COUNT", current + 1)
end)
end

local function bindPlayer(player)
if player.Character then
task.spawn(bindCharacter, player.Character)
end

player.CharacterAdded:Connect(bindCharacter)
end

for _, player in Players:GetPlayers() do
bindPlayer(player)
end

Players.PlayerAdded:Connect(bindPlayer)

checkpoint.Touched:Connect(function(hit)
if not playerFromHit(hit) then
return
end

if not state:GetAttribute("checkpointReached") then
state:SetAttribute("checkpointReached", true)
print("TEST_CHECKPOINT_REACHED")
end
end)

goal.Touched:Connect(function(hit)
if not playerFromHit(hit) then
return
end

if spec.acceptance.requiresCheckpoint
and not state:GetAttribute("checkpointReached") then
return
end

if not state:GetAttribute("goalReached") then
state:SetAttribute("goalReached", true)
print("TEST_GOAL_REACHED")
end
end)

killPlane.Touched:Connect(function(hit)
local character = hit:FindFirstAncestorOfClass("Model")
if not character then
return
end

local humanoid = character:FindFirstChildOfClass("Humanoid")
if humanoid and humanoid.Health > 0 then
humanoid.Health = 0
end
end)

task.spawn(function()
while state.Parent do
local elapsed = os.clock() - startedAt

state:SetAttribute(
"elapsedTime",
math.round(elapsed * 1000) / 1000
)

local player = Players:GetPlayers()[1]

if player and player.Character then
local root =
player.Character:FindFirstChild("HumanoidRootPart")

if root then
state:SetAttribute("playerPosition", root.Position)
end
end

task.wait(spec.test.sampleIntervalSeconds or 0.1)
end
end)

print("TEST_HOOKS_READY", spec.id)

return state
end

return TestHooks