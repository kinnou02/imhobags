local Addon, private = ...

if(Addon.toc.debug) then
	_G[Addon.identifier] = private
end

local pairs = pairs
local print = print
local table = table

local Command = Command
local Event = Event
local Inspect = Inspect
local UI = UI

setfenv(1, private)

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
PlayerShard = Inspect.Shard().name

local unitAvailableIndex
local function unitAvailable(units)
	for k, v in pairs(units) do
		if(v == "player") then
			local player = Inspect.Unit.Detail("player")
			PlayerName = player.name
			PlayerFaction = player.faction
			
			Event.Unit.Available[unitAvailableIndex][1] = function() end
			break
		end
	end
end

table.insert(Event.Unit.Available, { unitAvailable, Addon.identifier, "unitAvailable" })
unitAvailableIndex = #Event.Unit.Available
