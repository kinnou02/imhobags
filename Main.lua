local Addon, private = ...

if(Addon.toc.debug) then
	_G[Addon.identifier] = private
end

local pairs = pairs
local print = print

local Command = Command
local Event = Event
local Inspect = Inspect
local UI = UI
local Utility = Utility

local lang = Inspect.System.Language()
if(lang == "Korean" or lang == "French" or lang == "Russian") then
	print("Looking for French, Korean and Russian translators and reviewers!")
end
print("Try out the new configuration window with /imhobags config")

setfenv(1, private)

if(Addon.toc.debug) then
	log = print
else
	log = function() end
end

-- Always available
PlayerName = ""
PlayerGuild = ""
PlayerFaction = ""
EnemyFaction = ""
PlayerShard = Inspect.Shard().name

ImhoEvent = { }
Trigger = { }

-- The Init event is postponed until the full Inspect.Unit.Detail("player") data is available
Trigger.Init, ImhoEvent.Init = Utility.Event.Create(Addon.identifier, "ImhoBags.Event.Init")
-- The Config event is fired whenever a cvonfig option has changed: (name, value)
Trigger.Config, ImhoEvent.Config = Utility.Event.Create(Addon.identifier, "ImhoBags.Event.Config")

local unitAvailableEntry
local function unitAvailable(units)
	for k, v in pairs(units) do
		if(v == "player") then
			local player = Inspect.Unit.Detail("player")
			PlayerName = player.name
			PlayerGuild = player.guild
			PlayerFaction = player.faction
			EnemyFaction = (PlayerFaction == "defiant" and "guardian") or "defiant"
			Trigger.Init()
			
			unitAvailableEntry[1] = function() end
			break
		end
	end
end

unitAvailableEntry = { unitAvailable, Addon.identifier, "Main_unitAvailable" }
Event.Unit.Available[#Event.Unit.Available + 1] = unitAvailableEntry
