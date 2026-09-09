local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSpec = require(Shared:WaitForChild("GameSpec"))

local MicroObbyBuilder =
require(script.Parent:WaitForChild("MicroObbyBuilder"))

local TestHooks =
require(script.Parent:WaitForChild("TestHooks"))

local world = MicroObbyBuilder.build(GameSpec)
TestHooks.start(GameSpec, world)

print("FACTORY_MICRO_OBBY_READY", GameSpec.id)