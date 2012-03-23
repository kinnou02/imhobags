local Addon, private = ...

-- Builtins
local next = next
local pairs = pairs
local pcall = pcall
local setmetatable = setmetatable

-- Globals
local InspectCurrencyDetail = Inspect.Currency.Detail
local InspectItemDetail = Inspect.Item.Detail
local InspectTimeReal = Inspect.Time.Real

setfenv(1, private)
CurrencyMatrix = { }

-- Private methods
-- ============================================================================

local function extractUnsortedCharacterItems(matrix)
	local items = { }
	local success = true
	for itemType, amount in pairs(matrix.items) do
		if(itemType ~= "coin") then
			-- Because the mail window does not allow for item manipulation
			-- all stacks are condensed.

			-- If looking at other characters item information might not be available.
			-- In this case Inspect.Item.Detail throws an error and we need to remember
			-- to ask later.
			local result, curr = pcall(InspectCurrencyDetail, itemType)
			local result2, item = pcall(InspectItemDetail, itemType)
			success = success and (result and result2)
			if(result and result2) then
				items[#items + 1] = { type = curr, slots = 1, stack = amount, }
				-- Missing in currency info
				curr.type = itemType
				curr.rarity = item.rarity
			end
		end
	end
	return items, 0, success
end

-- Public methods
-- ============================================================================

local matrixMetaTable
function CurrencyMatrix.New()
	local matrix = {
		items = {
--			[type] = count
		},
		lastUpdate = -1, -- Forced to -1 on save
	}
	return setmetatable(matrix, matrixMetaTable)
end

--[[
Merge a currency change into the matrix.
Also available as instance metamethod.
]]
function CurrencyMatrix.MergeCurrency(matrix, type, amount)
	if(amount <= 0) then
		matrix.items[type] = nil
	else
		matrix.items[type] = amount
	end
	matrix.lastUpdate = InspectTimeReal() -- Inspect.Time.Frame() is not good enough and can cause multiple updates per frame
	log("update", "currency", type, matrix.lastUpdate)
end

--[[
Get the list of items for this container in one flat table and no particular sorting.
The returned list serves as staging base for further operations.
Also available as instance metamethod.
condensed: True to condense max stacks together into one displayed item (ignored for mails)
return: items, empty, success
	"success" determines whether all items could be retrieved successfully or
	whether the local item cache is incomplete and you have to try again later.
	This is common if requesting items from other characters than the player and
	you need to call the function later to retrieve the remaining items until succes becomes true.
	
	The other return values are as follows:
	
	items = { -- Array
		[#] = {
			type = result of Inspect.Item.Detail(type),
			slots = number, -- always 1 for mails
			stack = #, -- displayed stack size
		}
	}
	empty = number
]]
function CurrencyMatrix.GetUnsortedItems(matrix, condensed)
	return extractUnsortedCharacterItems(matrix)
end

-- Get the amount of items in this matrix of the given item type (including bags).
-- Also available as instance metamethod.
function CurrencyMatrix.GetItemCount(matrix, itemType)
	return matrix.items[itemType] or 0
end

function CurrencyMatrix.GetAllItemTypes(matrix, result, accountBoundOnly)
	if(accountBoundOnly) then
		for k in pairs(matrix.items) do
			local s, detail = pcall(InspectItemDetail, k)
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

matrixMetaTable = {
	__index = {
		GetAllItemTypes = CurrencyMatrix.GetAllItemTypes,
		GetItemCount = CurrencyMatrix.GetItemCount,
		GetUnsortedItems = CurrencyMatrix.GetUnsortedItems,
		MergeCurrency = CurrencyMatrix.MergeCurrency,
	}
}

function CurrencyMatrix.ApplyMetaTable(matrix)
	if(not matrix) then
		return CurrencyMatrix.New()
	else
		return setmetatable(matrix, matrixMetaTable)
	end
end
