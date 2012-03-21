local Addon, private = ...

if(Addon.toc.debug) then
	_G[Addon.identifier] = private
end

local pairs = pairs
local print = print
local string = string
local table = table

local Command = Command
local Event = Event
local Inspect = Inspect
local UI = UI
local Utility = Utility

setfenv(1, private)

print("Looking for French, Korean and Russian translators and reviewers.")

if(Addon.toc.debug) then
	log = function(...)
		print(string.tostring(...))
	end
else
	log = function() end
end

-- Always available
PlayerName = ""
PlayerFaction = ""
EnemyFaction = ""
PlayerShard = Inspect.Shard().name

ImhoEvent = { }
Trigger = { }

-- The Init event is postponed until the full Inspect.Unit.Detail("player") data is available
Trigger.Init, ImhoEvent.Init = Utility.Event.Create(Addon.identifier, "ImhoBags.Event.Init")
-- The Config event is fired whenever a cvonfig option has changed: (name, value)
Trigger.Config, ImhoEvent.Config = Utility.Event.Create(Addon.identifier, "ImhoBags.Event.Config")

local unitAvailableIndex
local function unitAvailable(units)
	for k, v in pairs(units) do
		if(v == "player") then
			local player = Inspect.Unit.Detail("player")
			PlayerName = player.name
			PlayerFaction = player.faction
			EnemyFaction = (PlayerFaction == "defiant" and "guardian") or "defiant"
			Trigger.Init()
			
			Event.Unit.Available[unitAvailableIndex][1] = function() end
			break
		end
	end
end

table.insert(Event.Unit.Available, { unitAvailable, Addon.identifier, "unitAvailable" })
unitAvailableIndex = #Event.Unit.Available
