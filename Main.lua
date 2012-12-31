local Addon, private = ...

setfenv(1, private)

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
			log("Init", Player.guild)
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
