local Addon, private = ...

-- Builtins
local pairs = pairs
local pcall = pcall
local setmetatable = setmetatable

-- Globals
local InspectItemDetail = Inspect.Item.Detail
local UtilityItemSlotParse = Utility.Item.Slot.Parse

setfenv(1, private)
WardrobeMatrix = { }

-- Private methods
-- ============================================================================

local function extractUnsortedPlayerItems(matrix, condensed)
	local items = { }
	for itemType, slots in pairs(matrix.items) do
		for slot, stack in pairs(slots) do
			local type = InspectItemDetail(itemType)
			if(type) then
				local _, set = UtilityItemSlotParse(slot)
				type.category = "wardrobeSet" .. set
				items[#items + 1] = { type = InspectItemDetail(slot), slots = { slot }, stack = 1 }
			else
				log("item detail nil", slot)
			end
		end
	end
	return items, { }, true
end

local function extractUnsortedCharacterItems(matrix, condensed, accountBoundOnly)
	local items = { }
	local success = true
	for itemType, slots in pairs(matrix.items) do
		if(not accountBoundOnly or detail.bind == "account") then
			for slot, stack in pairs(slots) do
				local result, detail = pcall(InspectItemDetail, itemType)
				success = success and result
				if(result and detail) then
					local _, set = UtilityItemSlotParse(slot)
					detail.category = "wardrobeSet" .. set
					items[#items + 1] = { type = detail, slots = 1, stack = 1 }
				end
			end
		end
	end
	return items, 0, success
end

-- Public methods
-- ============================================================================

local matrixMetaTable
function WardrobeMatrix.New()
	return setmetatable(ItemMatrix.New(), matrixMetaTable)
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
function WardrobeMatrix.GetUnsortedItems(matrix, condensed, accountBoundOnly)
	if(ItemDB.IsPlayerMatrix(matrix)) then
		return extractUnsortedPlayerItems(matrix, condensed)
	else
		return extractUnsortedCharacterItems(matrix, condensed, accountBoundOnly)
	end
end


matrixMetaTable = {
	__index = {
		MergeSlot = ItemMatrix.MergeSlot,
		GetAllItemTypes = ItemMatrix.GetAllItemTypes,
		GetItemCount = ItemMatrix.GetItemCount,
		GetUnsortedItems = WardrobeMatrix.GetUnsortedItems,
	}
}

function WardrobeMatrix.ApplyMetaTable(matrix)
	if(not matrix) then
		return WardrobeMatrix.New()
	else
		return setmetatable(matrix, matrixMetaTable)
	end
end
