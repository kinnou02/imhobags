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

local categoryCache = { } -- Used for avoiding string.match on known categories

setfenv(1, addon)
ItemDB = { }

-- Private methods
-- ============================================================================

local function newCharacter()
	return {
		-- List only locations we care about
		bank = ItemMatrix.New(),
		equipment = ItemMatrix.New(),
		inventory = ItemMatrix.New(),
		guild = ItemMatrix.New(),
		wardrobe = ItemMatrix.New(),
	}
end

local function mergeSlotChanges(slots)
	for slot, item in pairs(slots) do
		local container, bag, index = Utility.Item.Slot.Parse(slot)
		local matrix = playerItems[container]
		if(matrix) then
			matrix:MergeSlot(slot, item, bag, index)
		end
	end
end

local function startupEnd()
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
end

local function saveVariables(addonName)
	if(addonName ~= identifier) then
		return
	end
	
	playerItems.faction = Inspect.Unit.Detail("player").faction
	-- Forst lastUpdate to -1 in all matrixes, this ensures the
	-- math works for all characters on the shard
	for k, v in pairs(playerItems) do
		if(type(v) == "table" and v.lastUpdate) then
			v.lastUpdate = -1
		end
	end
	_G.ImhoBagsItemMatrix[Inspect.Shard().name][Inspect.Unit.Detail("player").name] = playerItems
	_G.ImhoBagsPlayerItemMatrix = playerItems
end

-- Public methods
-- ============================================================================

--[[
character: Either the name of a secodary character or "player"
location: "inventory", "bank", "equipped", "guild", "wardrobe"
condense: true to condense max stacks together into one displayed item
predicate: a function to call for sorting items (a, b) => boolean
	both parameters are item type tables as returned by Inspect.Item.Detail()
return: items, empty, success
	"success" determines whether all items could be retrieved successfully or
	whether the local item cache is incomplete and you have to try again later.
	This is common if requesting items from other characters than the player.
	
	The other return values are as follows:
	
	For the player, the return value has the following structure:
	items = {
		[#] = {
			name = "Name of category",
			[#] = {
				type = result of Inspect.Item.Detail(type),
				slots = { array of item slots }
				stack = #, -- displayed stack size
			}
		}
	}
	empty = {
		[#] = slot
	}
	For all other characters the structure is as follows:
	items = {
		[#] = {
			name = "Name of category",
			[#] = {
				type = result of Inspect.Item.Detail(type),
				slots = number,
				stack = #, -- displayed stack size
			}
		}
	}
	empty = number
]]
function ItemDB.GetItems(character, location, condense, predicate)
	-- Find the correct item matrix
	local matrix = ItemDB.GetAvailableCharacters(character, location)[location] or ItemMatrix.New()
	-- Dump all relevant items into a temporary table to be sorted later
	local items, empty, success;
	if(character == "player") then
		items, empty, success = extractUnsortedPlayerItems(matrix, condense)
	else
		items, empty, success = extractUnsortedCharacterItems(matrix, condense)
	end
	-- Sort according to provided predicate
	-- HACK: hardoced stable sort by category, make this customizable
	table.sort(items, function(a, b) return (a.type.category < b.type.category) or (a.type.category == b.type.category and a.type.name < b.type.name) end)
	table.sort(items, function(a, b) return predicate(a.type, b.type) end)
	-- Build the sorted category table
	local result = { }
	local categoryMap = { }
	for _, item in ipairs(items) do
		-- Find the localized category name for sorting
		local categoryName = categoryCache[item.type.category]
		if(categoryName == nil) then
			categoryName = string.match(item.type.category, "(%w+)")
			categoryName = L.CategoryNames[categoryName]
			categoryCache[item.type.category] = categoryName
		end
		-- Add the item to the correct category, preserving item sorting order
		local category = categoryMap[categoryName];
		if(category == nil) then
			table.insert(result, { name = categoryName })
			category = result[#result]
			categoryMap[categoryName] = category
		end
		table.insert(category, item)
	end
	-- And finally sort by category name
	table.sort(result, function(a, b) return a.name < b.name end)
	return result, empty, success
end

--[[
Get the matrix for the given character's location matrix
location: "inventory", "bank", "equipped", "guild", "wardrobe"
location: "inventory", "bank"
return: The matrix table for the character and location
]]
function ItemDB.GetItemMatrix(character, location)
	local matrix;
	if(character == "player" or Inspect.Unit.Detail("player").name == character) then
		return playerItems;
	else
		return _G.ImhoBagsItemMatrix[Inspect.Shard().name][character] or newMatrix()
	end
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

table.insert(Event.Addon.Startup.End, { startupEnd, identifier, "ItemDB_startupEnd" })
table.insert(Event.Addon.SavedVariables.Save.Begin, { saveVariables, identifier, "ItemDB_saveVariables" })
table.insert(Event.Item.Slot, { mergeSlotChanges, identifier, "ItemDB_mergeSlotChanges" })
table.insert(Event.Item.Update, { mergeSlotChanges, identifier, "ItemDB_mergeSlotChanges" })
