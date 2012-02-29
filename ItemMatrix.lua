local identifier = (...).id
local addon = (...).data

-- Builtins
local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local table = table
local setmetatable = setmetatable

-- Globals
local dump = dump

local Inspect = Inspect

setfenv(1, addon)
ItemMatrix = { }

-- Private methods
-- ============================================================================

local function extractUnsortedPlayerItems(matrix, condensed)
	local items = { }
	for itemType, slots in pairs(matrix.items) do
		-- We have to treat full and partial stacks differently
		-- otherwise the user would not be able to select partial stacks
		local usedFullSlots = { }
		local usedPartialSlots = { }
		local detail = Inspect.Item.Detail(itemType)
		local stackMax = detail.stackMax or 0 -- non-stackable items have stackMax = nil and must not be condensed
		for slot, stack in pairs(slots) do
			if(condensed and stack == stackMax) then
				table.insert(usedFullSlots, slot)
			else
				table.insert(usedPartialSlots, { slot, stack })
			end
		end
		if(#usedFullSlots > 0) then
			table.insert(items, { type = detail, slots = usedFullSlots, stack = #usedFullSlots * stackMax })
		end
		for k, v in ipairs(usedPartialSlots) do
			table.insert(items, { type = detail, slots = { v[1] }, stack = v[2] })
		end
	end
	local empty = { }
	for slot, type in pairs(matrix.slots) do
		if(not type) then
			table.insert(empty, slot)
		end
	end
	return items, empty, true
end

local function extractUnsortedCharacterItems(matrix, condensed)
	local items = { }
	local success = true
	for itemType, slots in pairs(matrix.items) do
		-- Technically, the player is not able to manipulate items of
		-- other characters, but we keep the stacking consistent to
		-- keep the spatial location as visual clue
		local usedFullSlots = { }
		local usedPartialSlots = { }
		-- If looking at other characters item information might not be available.
		-- In this case Inspect.Item.Detail throws an error and we need to remember
		-- to ask later.
		local result, detail = pcall(Inspect.Item.Detail, itemType)
		success = success and result
		if(result) then
			-- Non-stackable items have stackMax = nil and must not be condensed
			local stackMax = detail.stackMax or 0
			for slot, stack in pairs(slots) do
				if(condensed and stack == stackMax) then
					table.insert(usedFullSlots, stack)
				else
					table.insert(usedPartialSlots, stack)
				end
			end
			if(#usedFullSlots > 0) then
				table.insert(items, { type = detail, slots = #usedFullSlots, stack = #usedFullSlots * stackMax })
			end
			for k, v in ipairs(usedPartialSlots) do
				table.insert(items, { type = detail, slots = 1, stack = v })
			end
		end
	end
	local empty  = 0
	for slot, type in pairs(matrix.slots) do
		if(not type) then
			empty = empty + 1
		end
	end
	return items, empty, success
end

-- Public methods
-- ============================================================================

function ItemMatrix.ApplyMetaTable(matrix)
	return setmetatable(matrix, matrixMetaTable)
end

function ItemMatrix.New()
	local matrix = {
		items = {
--[[		[type] = {
				[slot] = count
			}
]]		},
		slots = {
--			[slot] = type
		},
		bags = {
--			[index] = type -- Index is numerical for keeping correct order
		},
		lastUpdate = -1, -- Forced to -1 on save
	}
	return setmetatable(matrix, matrixMetaTable)
end

--[[
Merge a slot change into the matrix.
Also available as instance metamethod.
]]
function ItemMatrix.MergeSlot(matrix, slot, item, bag, index)
	if(item) then
		local details = Inspect.Item.Detail(slot)
		if(bag == "bag") then
			matrix.bags[index] = details.type
		else
			matrix.slots[slot] = details.type
			if(matrix.items[details.type] == nil) then
				matrix.items[details.type] = { }
			end
			matrix.items[details.type][slot] = details.stack or 1
		end
	else
		if(bag == "bag") then
			matrix.bags[index] = false -- Keep table entries for retrieving empty slots
		else
			local type = matrix.slots[slot]
			if(type) then
				if(matrix.items[type]) then
					matrix.items[type][slot] = nil
					-- Delete empty entries or otherwise the table will grow indefinitely
					if(next(matrix.items[type]) == nil) then
						matrix.items[type] = nil
					end
				end
			end
			matrix.slots[slot] = false -- Keep table entries for retrieving empty slots
		end
	end
	matrix.lastUpdate = Inspect.Time.Frame() --Guaranteed to be non-negative
end

--[[
Get the list of items for this container in one flat table and no particular sorting.
The returned list serves as staging base for further operations.
Also available as instance metamethod.
condensed: True to condense max stacks together into one displayed item
groupOf: A function to determine the group of an item. The return value is used as key.
	It is called with item type as argument
return: items, empty, success
	"success" determines whether all items could be retrieved successfully or
	whether the local item cache is incomplete and you have to try again later.
	This is common if requesting items from other characters than the player and
	you need to call the function later to retrieve the remaining items until succes becomes true.
	
	The other return values are as follows:
	
	For the player, the return values have the following structure:
	items = { -- Array
		[#] = {
			type = result of Inspect.Item.Detail(type),
			slots = { array of item slots }
			stack = #, -- displayed stack size
		}
	}
	empty = { -- Array
		[#] = slot
	}
	For all other characters the structure is as follows:
	items = { -- Array
		[#] = {
			type = result of Inspect.Item.Detail(type),
			slots = number,
			stack = #, -- displayed stack size
		}
	}
	empty = number
]]
function ItemMatrix.GetUnsortedItems(matrix, condensed)
	if(ItemDB.IsPlayerMatrix(matrix)) then
		return extractUnsortedPlayerItems(matrix, condensed, groupOf)
	else
		return extractUnsortedCharacterItems(matrix, condensed, groupOf)
	end
end

--[[
Transforms the given items list and returns a table where the items have a grouped structure.
items: result of GetUnsortedItems()
group: A function taking an item type as argument and returning a key
return: groups, keys

	groups = { -- Array
		[#] = { -- Array
			[#] = item -- value is a reference to an entry in the items table
		}
	}
	The items are given in no particular order, however the relative order
	of the items as they are listed in the items table is preserved.
	
	keys = {
		[group] = key
	}
	The table keys are the values in the groups table.
	The table values are the keys returned by group()
	
	These two tables together allow an efficient sorting of the groups
	and their contained items without the need to reallocate new tables.
]]
function ItemMatrix.GetGroupedItems(matrix, items, group)
	local groups = { }
	local keys = { }
	
	local function groupForKey(key)
		for k, v in pairs(keys) do
			if(key == v) then
				return k
			end
		end
		local g = { }
		table.insert(groups, g)
		keys[g] = key
		return g
	end
	
	for _, item in ipairs(items) do
		local g = groupForKey(group(item.type))
		table.insert(g, item)
	end
	return groups, keys
end

local matrixMetaTable = {
	__index = {
		MergeSlot = matrix_mergeSlot,
		GetGroupedItems = GetGroupedItems,
		GetUnsortedItems = GetUnsortedItems,
	}
}
