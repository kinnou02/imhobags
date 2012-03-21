local Addon, private = ...

-- Builtins
local ipairs = ipairs
local next = next
local pairs = pairs
local pcall = pcall
local tconcat = table.concat
local tinsert = table.insert
local setmetatable = setmetatable
local strsplit = string.split
local strsub = string.sub

-- Globals
local dump = dump

local Inspect = Inspect

setfenv(1, private)
ItemMatrix = { }

-- Private methods
-- ============================================================================

local function ItemMatrix_extractUnsortedPlayerItems(matrix, condensed)
	local items = { }
	for itemType, slots in pairs(matrix.items) do
		-- We have to treat full and partial stacks differently
		-- otherwise the user would not be able to select partial stacks
		local usedFullSlots = { }
		local usedPartialSlots = { }
		
		local detail = Inspect.Item.Detail((next(slots)))
		if(detail) then
			local stackMax = detail.stackMax or 0 -- non-stackable items have stackMax = nil and must not be condensed
			for slot, stack in pairs(slots) do
				if(condensed and stack == stackMax) then
					tinsert(usedFullSlots, slot)
				else
					usedPartialSlots[slot] = stack
				end
			end
			if(#usedFullSlots > 0) then
				tinsert(items, { type = Inspect.Item.Detail(usedFullSlots[1]), slots = usedFullSlots, stack = #usedFullSlots * stackMax })
			end
			for slot, stack in pairs(usedPartialSlots) do
				tinsert(items, { type = Inspect.Item.Detail(slot), slots = { slot }, stack = stack })
			end
		else
			log("item detail nil", next(slots))
		end
	end
	local empty = { }
	for slot, type in pairs(matrix.slots) do
		if(not type) then
			tinsert(empty, slot)
		end
	end
	return items, empty, true
end

local function ItemMatrix_extractUnsortedCharacterItems(matrix, condensed, accountBoundOnly)
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
		if(result and detail) then
			if(not accountBoundOnly or detail.bind == "account") then
				-- Non-stackable items have stackMax = nil and must not be condensed
				local stackMax = detail.stackMax or 0
				for slot, stack in pairs(slots) do
					if(condensed and stack == stackMax) then
						tinsert(usedFullSlots, stack)
					else
						tinsert(usedPartialSlots, stack)
					end
				end
				if(#usedFullSlots > 0) then
					tinsert(items, { type = detail, slots = #usedFullSlots, stack = #usedFullSlots * stackMax })
				end
				for k, v in ipairs(usedPartialSlots) do
					tinsert(items, { type = detail, slots = 1, stack = v })
				end
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
	return setmetatable(matrix, ItemMatrix_matrixMetaTable)
end

--[[
Merge a slot change into the matrix.
Also available as instance metamethod.
]]
function ItemMatrix.MergeSlot(matrix, slot, item, bag, index)
	if(item) then
		item = Inspect.Item.Detail(slot)
		-- Make sure only working types land in the DB
		item.type = Utils.FixItemType(item.type)
	end
	
	-- Bags are special
	if(bag == "bag") then
		if(item) then
			matrix.bags[index] = item.type
		else
			matrix.bags[index] = false -- Keep table entries for retrieving empty slots
		end
		return
	end
	
	-- First check if an item needs to be removed from the DB
	-- This solves the "bag replaced in-place with content" issue
	local type = matrix.slots[slot]
	if(type and (not item or type ~= item.type)) then
		if(matrix.items[type]) then
			matrix.items[type][slot] = nil
			-- Delete empty entries or otherwise the table will grow indefinitely
			if(next(matrix.items[type]) == nil) then
				matrix.items[type] = nil
			end
		end
	end
	matrix.slots[slot] = item and item.type -- Keep table entries for retrieving empty slots
	
	-- Now add the new item
	if(item) then
		if(bag == "bag") then
			matrix.bags[index] = item.type
		else
			matrix.slots[slot] = item.type
			if(matrix.items[item.type] == nil) then
				matrix.items[item.type] = { }
			end
			matrix.items[item.type][slot] = item.stack or 1
		end
	end
	matrix.lastUpdate = Inspect.Time.Real() -- Inspect.Time.Frame() is not good enough and can cause multiple updates per frame
	log("update", bag, slot, item and item.name, matrix.lastUpdate)
end

--[[
Get the list of items for this container in one flat table and no particular sorting.
The returned list serves as staging base for further operations.
Also available as instance metamethod.
condensed: True to condense max stacks together into one displayed item
accountBoundOnly: Return only items which are account-bound (ignored for the player)
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
function ItemMatrix.GetUnsortedItems(matrix, condensed, accountBoundOnly)
	if(ItemDB.IsPlayerMatrix(matrix)) then
		return ItemMatrix_extractUnsortedPlayerItems(matrix, condensed)
	else
		return ItemMatrix_extractUnsortedCharacterItems(matrix, condensed, accountBoundOnly)
	end
end


-- Get the amount of items in this matrix of the given item type (including bags).
-- Also available as instance metamethod.
function ItemMatrix.GetItemCount(matrix, itemType)
	itemType = Utils.FixItemType(itemType)
	local result = 0
	for _, type in ipairs(matrix.bags) do
		if(type == itemType) then
			result = result + 1
		end
	end
	
	local entry = matrix.items[itemType]
	if(entry) then
		for slot, count in pairs(entry) do
			result = result + count
		end
	end
	return result
end

function ItemMatrix.GetAllItemTypes(matrix, result, accountBoundOnly)
	if(accountBoundOnly) then
		for k in pairs(matrix.items) do
			local s, detail = pcall(Inspect.Item.Detail, k)
			if(s and detail.bind == "account") then
				result[k] = true
			end
		end
	else
		for k in pairs(matrix.items) do
			result[k] = true
		end
	end
end

local ItemMatrix_matrixMetaTable = {
	__index = {
		MergeSlot = ItemMatrix.MergeSlot,
		GetAllItemTypes = ItemMatrix.GetAllItemTypes,
		GetItemCount = ItemMatrix.GetItemCount,
		GetUnsortedItems = ItemMatrix.GetUnsortedItems,
	}
}

function ItemMatrix.ApplyMetaTable(matrix)
	if(not matrix) then
		return ItemMatrix.New()
	else
		return setmetatable(matrix, ItemMatrix_matrixMetaTable)
	end
end
