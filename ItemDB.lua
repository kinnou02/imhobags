local _G = _G
local pairs = pairs
local print = print
local setfenv = setfenv
local table = table
local tostring = tostring
local type = type

local dump = dump
local Event = Event
local Inspect = Inspect
local Utility = Utility

local playerItemMatrix = { items = { }, slots = { } }
local itemMatrix = playerItemMatrix
local readonly = true

setfenv(1, ImhoBags)
ItemDB = { }

-- Private methods
-- ============================================================================

local function mergeSlotUpdate(slots)
	for slot, item in pairs(slots) do
		if(type(item) == "string") then
			local details = Inspect.Item.Detail(slot)
			dump(details)
			itemMatrix.slots[slot] = details.type
			if(itemMatrix.items[details.type] == nil) then
				itemMatrix.items[details.type] = { }
			end
			itemMatrix.items[details.type][slot] = (details.stack or 1)
		else
			dump(item)
		end
	end
end

local function startupEnd()
	-- A /reloadui does not trigger all the Event.Item.Slot events
	-- so we have to scan everything manually
	mergeSlotUpdate(Inspect.Item.List(Utility.Item.Slot.All()))
end

local function saveVariables(addonName)
	if(addonName ~= AddonName) then
		return
	end
	
	local shardName = Inspect.Shard().name
	local playerName = Inspect.Unit.Detail("player").name
	
	if(_G.ImhoBagsItems == nil) then
		_G.ImhoBagsItems = { }
	end
	if(_G.ImhoBagsItems[shardName] == nil) then
		_G.ImhoBagsItems[shardName] = { }
	end
	_G.ImhoBagsItems[shardName][playerName] = playerItemMatrix
end

-- Public methods
-- ============================================================================

function ItemDB:IsReadonly()
	return readonly
end

table.insert(Event.Addon.Startup.End, { startupEnd, AddonName, "ItemDB_startupEnd" })
table.insert(Event.Addon.SavedVariables.Save.Begin, { saveVariables, AddonName, "ItemDB_saveVariables" })
table.insert(Event.Item.Slot, { mergeSlotUpdate, AddonName, "ItemDB_mergeSlotUpdate" })
table.insert(Event.Item.Update, { function(arg) print("Event.Item.Update") dump(arg) end, AddonName, "ItemDB_print" })
