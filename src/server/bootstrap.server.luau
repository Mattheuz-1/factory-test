local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSpec = require(Shared:WaitForChild("GameSpec"))

local AcceptanceContracts =
ServerStorage:WaitForChild("AcceptanceContracts")

local AcceptanceContract = require(
AcceptanceContracts:WaitForChild(GameSpec.id)
)

assert(
AcceptanceContract.testId == GameSpec.id,
"Acceptance contract does not match GameSpec"
)

local MicroObbyBuilder =
require(script.Parent:WaitForChild("MicroObbyBuilder"))

local TestHooks =
require(script.Parent:WaitForChild("TestHooks"))

local world = MicroObbyBuilder.build(GameSpec)
TestHooks.start(GameSpec, AcceptanceContract, world)

print("FACTORY_MICRO_OBBY_READY", GameSpec.id)
