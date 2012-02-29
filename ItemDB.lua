local identifier = (...).id
local addon = (...).data

-- Builtins
local _G = _G
local ipairs = ipairs
local next = next
local pairs = pairs
local print = print
local setfenv = setfenv
local string = string
local table = table
local tostring = tostring
local type = type

-- Globals
local dump = dump

local Event = Event
local Inspect = Inspect
local Utility = Utility

-- Locals
local playerItems
local readonly = true

setfenv(1, addon)
ItemDB = { }

-- Private methods
-- ============================================================================

local function ItemDB_newCharacter()
	return {
		-- List only locations we care about
		bank = ItemMatrix.New(),
		equipment = ItemMatrix.New(),
		inventory = ItemMatrix.New(),
		guild = ItemMatrix.New(),
		wardrobe = ItemMatrix.New(),
	}
end

local function ItemDB_mergeSlotChanges(slots)
	for slot, item in pairs(slots) do
		local container, bag, index = Utility.Item.Slot.Parse(slot)
		local matrix = playerItems[container]
		if(matrix) then
			matrix:MergeSlot(slot, item, bag, index)
		end
	end
end

local function ItemDB_variablesLoaded(addonIdentifier)
	if(addonIdentifier ~= identifier) then
		return
	end
	
	-- A /reloadui does not trigger all the Event.Item.Slot events as on loggin or teleport.
	-- That's why we need a separate "character"-stored table with
	-- readily available data after a /reloadui
	playerItems = _G.ImhoBagsPlayerItemMatrix or newCharacter()

	-- Ensure at least the shard table exists
	if(_G.ImhoBagsItemMatrix == nil) then
		_G.ImhoBagsItemMatrix = { }
	end
	local shardName = Inspect.Shard().name
	if(_G.ImhoBagsItemMatrix[shardName] == nil) then
		_G.ImhoBagsItemMatrix[shardName] = { }
	end
	-- Apply the metatable to all item matrixes on the current shard
	for k,v in pairs(_G.ImhoBagsItemMatrix[shardName]) do
		ItemMatrix.ApplyMetaTable(v.bank)
		ItemMatrix.ApplyMetaTable(v.equipment)
		ItemMatrix.ApplyMetaTable(v.guild)
		ItemMatrix.ApplyMetaTable(v.inventory)
		ItemMatrix.ApplyMetaTable(v.wardrobe)
	end
	ItemMatrix.ApplyMetaTable(playerItems.bank)
	ItemMatrix.ApplyMetaTable(playerItems.equipment)
	ItemMatrix.ApplyMetaTable(playerItems.guild)
	ItemMatrix.ApplyMetaTable(playerItems.inventory)
	ItemMatrix.ApplyMetaTable(playerItems.wardrobe)
end

local function ItemDB_saveVariables(addonIdentifier)
	if(addonIdentifier ~= identifier) then
		return
	end
	
	-- Forst lastUpdate to -1 in all matrixes, this ensures the
	-- math works for all characters on the shard
	playerItems.lastUpdate = -1
	playerItems.lastUpdate = -1
	playerItems.lastUpdate = -1
	playerItems.lastUpdate = -1
	playerItems.lastUpdate = -1
	playerItems.faction = Inspect.Unit.Detail("player").faction
	_G.ImhoBagsItemMatrix[Inspect.Shard().name][Inspect.Unit.Detail("player").name] = playerItems
	_G.ImhoBagsPlayerItemMatrix = playerItems
end

-- Public methods
-- ============================================================================

--[[
Get the matrix for the given character's location matrix
location: "inventory", "bank", "equipped", "guild", "wardrobe"
location: "inventory", "bank"
return: The matrix table for the character and location
]]
function ItemDB.GetItemMatrix(character, location)
	local matrix;
	if(character == "player" or Inspect.Unit.Detail("player").name == character) then
		matrix = playerItems;
	else
		matrix = _G.ImhoBagsItemMatrix[Inspect.Shard().name][character] or ItemDB_newCharacter()
	end
	return matrix[location] or ItemMatrix.New()
end

-- Return an array of all characters on the current shard and faction for which item data is available
function ItemDB.GetAvailableCharacters()
	local result = { }
	for k in pairs(_G.ImhoBagsItemMatrix[Inspect.Shard().name]) do
		table.insert(result, k)
	end
	table.sort(result)
	return result
end

-- Helper for ItemMatrix
function ItemDB.IsPlayerMatrix(matrix)
	for k, v in pairs(playerItems) do
		if(v == matrix) then
			return true
		end
	end
	return false
end

table.insert(Event.Addon.SavedVariables.Load.End, { ItemDB_variablesLoaded, identifier, "ItemDB_variablesLoaded" })
table.insert(Event.Addon.SavedVariables.Save.Begin, { ItemDB_saveVariables, identifier, "ItemDB_saveVariables" })
table.insert(Event.Item.Slot, { ItemDB_mergeSlotChanges, identifier, "ItemDB_mergeSlotChanges" })
table.insert(Event.Item.Update, { ItemDB_mergeSlotChanges, identifier, "ItemDB_mergeSlotChanges" })
