local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")

local TestHooks = {}

local MOVE_START_THRESHOLD = 0.5

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

local function horizontalDistance(a, b)
local dx = a.X - b.X
local dz = a.Z - b.Z

return math.sqrt(dx * dx + dz * dz)
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
state:SetAttribute("harnessVersion", "0.1")

state:SetAttribute("checkpointReached", false)
state:SetAttribute("goalReached", false)
state:SetAttribute("completed", false)
state:SetAttribute("runStarted", false)

state:SetAttribute("deathCount", 0)
state:SetAttribute("deathCountBeforeGoal", 0)
state:SetAttribute("postGoalDeathCount", 0)

state:SetAttribute("playerPosition", Vector3.zero)
state:SetAttribute("startPosition", Vector3.zero)

-- elapsedTime = gameplay run time.
-- It begins on first meaningful horizontal movement
-- and freezes when Goal is reached.
state:SetAttribute("elapsedTime", 0)

-- Diagnostic only: total time since TestHooks started.
state:SetAttribute("wallClockElapsed", 0)

state:SetAttribute("activeErrors", 0)

state:SetAttribute(
"maxElapsedSeconds",
spec.acceptance.maxElapsedSeconds
)

state:SetAttribute(
"maxDeaths",
spec.acceptance.maxDeaths
)

local hooksStartedAt = os.clock()
local runStartedAt = nil
local completedAt = nil
local initialPlayerPosition = nil

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
-- MCP console inspection remains an independent error oracle.
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
local total = state:GetAttribute("deathCount") or 0
total += 1
state:SetAttribute("deathCount", total)

if state:GetAttribute("completed") then
local postGoal =
state:GetAttribute("postGoalDeathCount") or 0

postGoal += 1

state:SetAttribute(
"postGoalDeathCount",
postGoal
)

print("TEST_POST_GOAL_DEATH", postGoal)
else
local beforeGoal =
state:GetAttribute("deathCountBeforeGoal") or 0

beforeGoal += 1

state:SetAttribute(
"deathCountBeforeGoal",
beforeGoal
)

print("TEST_PRE_GOAL_DEATH", beforeGoal)
end

print("TEST_DEATH_COUNT", total)
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

if state:GetAttribute("completed") then
return
end

if not runStartedAt then
-- Defensive fallback. Physical Goal contact implies
-- the character has moved even if sampling missed start.
runStartedAt = os.clock()
state:SetAttribute("runStarted", true)
end

completedAt = os.clock()

local completionTime =
math.round(
(completedAt - runStartedAt) * 1000
) / 1000

state:SetAttribute("elapsedTime", completionTime)
state:SetAttribute("goalReached", true)
state:SetAttribute("completed", true)

print(
"TEST_GOAL_REACHED",
"elapsedTime",
completionTime,
"deathCountBeforeGoal",
state:GetAttribute("deathCountBeforeGoal")
)
end)

killPlane.Touched:Connect(function(hit)
local character = hit:FindFirstAncestorOfClass("Model")
if not character then
return
end

local humanoid =
character:FindFirstChildOfClass("Humanoid")

if humanoid and humanoid.Health > 0 then
humanoid.Health = 0
end
end)

task.spawn(function()
while state.Parent do
local now = os.clock()

state:SetAttribute(
"wallClockElapsed",
math.round(
(now - hooksStartedAt) * 1000
) / 1000
)

local player = Players:GetPlayers()[1]

if player and player.Character then
local root =
player.Character:FindFirstChild(
"HumanoidRootPart"
)

if root then
local position = root.Position

state:SetAttribute(
"playerPosition",
position
)

if not initialPlayerPosition then
initialPlayerPosition = position

state:SetAttribute(
"startPosition",
position
)
end

if not runStartedAt
and initialPlayerPosition
and horizontalDistance(
position,
initialPlayerPosition
) >= MOVE_START_THRESHOLD then

runStartedAt = now
state:SetAttribute(
"runStarted",
true
)

print("TEST_RUN_STARTED")
end

if runStartedAt and not completedAt then
state:SetAttribute(
"elapsedTime",
math.round(
(now - runStartedAt) * 1000
) / 1000
)
end
end
end

task.wait(
spec.test.sampleIntervalSeconds or 0.1
)
end
end)

print("TEST_HOOKS_READY", spec.id)

return state
end

return TestHooks