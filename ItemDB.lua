local Addon, private = ...

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

setfenv(1, private)
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
		mail = ItemMatrix.New(),
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
	if(addonIdentifier ~= Addon.identifier) then
		return
	end
	
	-- A /reloadui does not trigger all the Event.Item.Slot events as on loggin or teleport.
	-- That's why we need a separate "character"-stored table with
	-- readily available data after a /reloadui
	playerItems = _G.ImhoBagsPlayerItemMatrix or ItemDB_newCharacter()

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
		v.bank = ItemMatrix.ApplyMetaTable(v.bank)
		v.equipment = ItemMatrix.ApplyMetaTable(v.equipment)
		v.guild = ItemMatrix.ApplyMetaTable(v.guild)
		v.inventory = ItemMatrix.ApplyMetaTable(v.inventory)
		v.mail = ItemMatrix.ApplyMetaTable(v.mail)
		v.wardrobe = ItemMatrix.ApplyMetaTable(v.wardrobe)
	end
	playerItems.bank = ItemMatrix.ApplyMetaTable(playerItems.bank)
	playerItems.equipment = ItemMatrix.ApplyMetaTable(playerItems.equipment)
	playerItems.guild = ItemMatrix.ApplyMetaTable(playerItems.guild)
	playerItems.inventory = ItemMatrix.ApplyMetaTable(playerItems.inventory)
	playerItems.mail = ItemMatrix.ApplyMetaTable(playerItems.mail)
	playerItems.wardrobe = ItemMatrix.ApplyMetaTable(playerItems.wardrobe)
end

local function ItemDB_saveVariables(addonIdentifier)
	if(addonIdentifier ~= Addon.identifier) then
		return
	end
	
	-- Forst lastUpdate to -1 in all matrixes, this ensures the
	-- math works for all characters on the shard
	playerItems.bank.lastUpdate = -1
	playerItems.equipment.lastUpdate = -1
	playerItems.guild.lastUpdate = -1
	playerItems.inventory.lastUpdate = -1
	playerItems.mail.lastUpdate = -1
	playerItems.wardrobe.lastUpdate = -1
	playerItems.faction = Inspect.Unit.Detail("player").faction
	_G.ImhoBagsItemMatrix[Inspect.Shard().name][Inspect.Unit.Detail("player").name] = playerItems
	_G.ImhoBagsPlayerItemMatrix = playerItems
end

-- Public methods
-- ============================================================================

--[[
Get the matrix for the given character's location matrix
location: "inventory", "bank", "equipped", "mail", "guild", "wardrobe"
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

--[[
Return a table containing the counts of the given item type for each character:
result = {
	[#] = { name, inventory, bank, mail, equipment, wardrobe }
}
The table is sorted by character name.
]]
function ItemDB.GetItemCounts(itemType)
	local result = { }
	for character, data in pairs(_G.ImhoBagsItemMatrix[Inspect.Shard().name]) do
		if(character == Inspect.Unit.Detail("player").name) then
			data = playerItems
		end
		table.insert(result, {
			character,
			data.inventory:GetItemCount(itemType),
			data.bank:GetItemCount(itemType),
			data.mail:GetItemCount(itemType),
			data.equipment:GetItemCount(itemType),
			data.wardrobe:GetItemCount(itemType),
		})
	end
	table.sort(result, function(a, b) return a[1] < b[1] end)
	return result
end

table.insert(Event.Addon.SavedVariables.Load.End, { ItemDB_variablesLoaded, Addon.identifier, "ItemDB_variablesLoaded" })
table.insert(Event.Addon.SavedVariables.Save.Begin, { ItemDB_saveVariables, Addon.identifier, "ItemDB_saveVariables" })
table.insert(Event.Item.Slot, { ItemDB_mergeSlotChanges, Addon.identifier, "ItemDB_mergeSlotChanges" })
table.insert(Event.Item.Update, { ItemDB_mergeSlotChanges, Addon.identifier, "ItemDB_mergeSlotChanges" })
