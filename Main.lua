local Addon, private = ...

if(Addon.toc.debug) then
	ImhoBagsDebug = private
end

local pairs = pairs
local print = print

local Command = Command
local Event = Event
local Inspect = Inspect
local UI = UI
local Utility = Utility

if(string.find(Addon.toc.Version, "alpha")) then
	Command.Console.Display("general", false, "<font color='#FF8000'>This is a development version of ImhoBags and not intended for release. It may be broken, have errors or not work at all. You have been warned.</font>", true)
end
local lang = Inspect.System.Language()
local translators = {
	German = true,
	English = true,
}
if(not translators[lang]) then
	Command.Console.Display("general", false, "<font color='#FFFF00'>ImhoBags is looking for " .. lang .. " translators and reviewers!\nContact Imhothar on Curse or RiftUI if you'd like to help!</font>", true)
end

-- Make this global available everywhere
private.dump = dump

setfenv(1, private)

if(Addon.toc.debug) then
	log = print
else
	log = function() end
end

-- Always available
Player = Inspect.Unit.Detail("player")
Shard = Inspect.Shard()

ImhoEvent = { }
Trigger = { }

-- The VariablesLoaded event signals all ImhoBags data was loaded, usually triggered before Init
Trigger.StorageLoaded, ImhoEvent.StorageLoaded = Utility.Event.Create(Addon.identifier, "Private.StorageLoaded")
-- The Init event is postponed until the full Inspect.Unit.Detail("player") data is available
Trigger.Init, ImhoEvent.Init = Utility.Event.Create(Addon.identifier, "Private.Init")
-- The Config event is fired whenever a cvonfig option has changed: (name, value)
Trigger.Config, ImhoEvent.Config = Utility.Event.Create(Addon.identifier, "Private.Config")
-- Triggered when the player's guild has changed (but not on startup): (old, new)
Trigger.Guild, ImhoEvent.Guild = Utility.Event.Create(Addon.identifier, "Private.Guild")

local unitAvailableEntry
local function unitAvailable(units)
	for k, v in pairs(units) do
		if(v == "player") then
			local defiants = {
				eth = true,
				bahmi = true,
				kelari = true,
			}
			Player = Inspect.Unit.Detail("player")
			
			Player.alliance = defiants[Player.race] and "defiant" or "guardian"
			Player.enemyAlliance = defiants[Player.race] and "guardian" or "defiant"
			Trigger.Init()
			
			unitAvailableEntry[1] = function() end
			break
		end
	end
end

local function guildChanged(units)
	for unit, guild in pairs(units) do
		if(unit == "player") then
			local old = Player.guild
			Player.guild = guild
			Trigger.Guild(old, guild)
			return
		end
	end
end

unitAvailableEntry = { unitAvailable, Addon.identifier, "unitAvailable" }
Event.Unit.Availability.Full[#Event.Unit.Availability.Full + 1] = unitAvailableEntry

Event.Unit.Detail.Guild[#Event.Unit.Detail.Guild + 1] = { guildChanged, Addon.identifier, "guildChanged" }
