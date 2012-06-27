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
	Command.Console.Display("general", true, "<font color='#FFFF00'>ImhoBags is looking for " .. lang .. " translators and reviewers!\nCheck by the official Rift forums in the 'Addon API Development' section if you'd like to help!</font>", true)
end
Command.Console.Display("general", false, "Try out the new popup menu with <font color='#00FF00'>/imhobags menu</font> (try putting it in a macro!)", true)

setfenv(1, private)

if(Addon.toc.debug) then
	log = print
else
	log = function() end
end

-- Always available
PlayerName = ""
PlayerGuild = false
PlayerFaction = ""
EnemyFaction = ""
PlayerShard = Inspect.Shard().name

ImhoEvent = { }
Trigger = { }

-- The Init event is postponed until the full Inspect.Unit.Detail("player") data is available
Trigger.Init, ImhoEvent.Init = Utility.Event.Create(Addon.identifier, "ImhoBags.Event.Init")
-- The Config event is fired whenever a cvonfig option has changed: (name, value)
Trigger.Config, ImhoEvent.Config = Utility.Event.Create(Addon.identifier, "ImhoBags.Event.Config")
-- Triggered when the player's guild has changed (but not on startup): (old, new)
Trigger.Guild, ImhoEvent.Guild = Utility.Event.Create(Addon.identifier, "ImhoBags.Event.Guild")

local unitAvailableEntry
local function unitAvailable(units)
	for k, v in pairs(units) do
		if(v == "player") then
			local player = Inspect.Unit.Detail("player")
			PlayerName = player.name
			PlayerGuild = player.guild
			PlayerFaction = player.alliance
			EnemyFaction = (PlayerFaction == "defiant" and "guardian") or "defiant"
			Trigger.Init()
			
			unitAvailableEntry[1] = function() end
			break
		end
	end
end

local function guildChanged(units)
	for unit, guild in pairs(units) do
		if(unit == "player") then
			local old = PlayerGuild
			PlayerGuild = guild
			Trigger.Guild(old, guild)
			return
		end
	end
end

unitAvailableEntry = { unitAvailable, Addon.identifier, "Main_unitAvailable" }
Event.Unit.Available[#Event.Unit.Available + 1] = unitAvailableEntry

Event.Unit.Detail.Guild[#Event.Unit.Detail.Guild + 1] = { guildChanged, Addon.identifier, "Main_guildChanged" }
