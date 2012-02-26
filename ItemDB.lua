local _G = _G
local ipairs = ipairs
local pairs = pairs
local print = print
local setfenv = setfenv
local string = string
local table = table
local tostring = tostring
local type = type

local dump = dump

local Event = Event
local Inspect = Inspect
local Utility = Utility

local playerItemMatrix = { items = { }, slots = { } }
local itemMatrix
local readonly = true

local categoryCache = { } -- Used for avoiding string.match on known categories

setfenv(1, ImhoBags)
ItemDB = { }

-- Private methods
-- ============================================================================

local function mergeSlotUpdate(slots)
	for slot, item in pairs(slots) do
		if(item) then
			local details = Inspect.Item.Detail(slot)
			itemMatrix.slots[slot] = details.type
			if(itemMatrix.items[details.type] == nil) then
				itemMatrix.items[details.type] = { }
			end
			itemMatrix.items[details.type][slot] = (details.stack or 1)
		end
	end
end

local function startupEnd()
	-- A /reloadui does not trigger all the Event.Item.Slot events as on loggin or teleport.
	-- That's why we need a separate "character"-stored table with
	-- readily available data after a /reloadui
	playerItemMatrix = _G.ImhoBagsPlayerItemMatrix or playerItemMatrix
	itemMatrix = playerItemMatrix

	-- Ensure at least the shard table exists
	if(_G.ImhoBagsItemMatrix == nil) then
		_G.ImhoBagsItemMatrix = { }
	end
	local shardName = Inspect.Shard().name
	if(_G.ImhoBagsItemMatrix[shardName] == nil) then
		_G.ImhoBagsItemMatrix[shardName] = { }
	end
end

local function saveVariables(addonName)
	if(addonName ~= AddonName) then
		return
	end
	
	_G.ImhoBagsItemMatrix[Inspect.Shard().name][Inspect.Unit.Detail("player").name] = playerItemMatrix
	_G.ImhoBagsPlayerItemMatrix = playerItemMatrix
end

local function extractUnsortedPlayerItems(prefix, condense)
	local items = { }
	for itemType, slots in pairs(playerItemMatrix.items) do
		-- We have to treat full and partial stacks differently
		-- otherwise the user would not be able to select partial stacks
		local usedFullSlots = { }
		local usedPartialSlots = { }
		local detail = Inspect.Item.Detail(itemType)
		local stackMax = detail.stackMax or 0 -- non-stackable items have stackMax = nil and must not be condensed
		for slot, stack in pairs(slots) do
			-- Do not include bag slots
			if(string.find(slot, prefix, 1, true) and not string.find(slot, "bg.", 3, true)) then
				if(condense and stack == stackMax) then
					table.insert(usedFullSlots, slot)
				else
					table.insert(usedPartialSlots, { slot, stack })
				end
			end
		end
		if(#usedFullSlots > 0) then
			table.insert(items, { type = detail, slots = usedFullSlots, stack = #usedFullSlots * stackMax })
		end
		for k, v in ipairs(usedPartialSlots) do
			table.insert(items, { type = detail, slots = { v[1] }, stack = v[2] })
		end
	end
	return items, { }, true
end

local function extractUnsortedCharacterItems(matrix, prefix, condense)
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
				if(string.find(slot, prefix, 1, true) and not string.find(slot, "bg.", 3, true)) then
					if(condense and stack == stackMax) then
						table.insert(usedFullSlots, stack)
					else
						table.insert(usedPartialSlots, stack)
					end
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
	return items, 0, success
end

-- Public methods
-- ============================================================================

--[[
character: Either the name of a secodary character or "player"
location: "inventory", "bank"
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
function ItemDB:GetItems(character, location, condense, predicate)
	-- Find out the slot prefix we are lookign for
	local prefix;
	if(location == "inventory") then
		prefix = Utility.Item.Slot.Inventory();
	elseif(location == "bank") then
		prefix = Utility.Item.Slot.Bank();
	else
		return {}
	end
	-- Find the correct item matrix
	local matrix;
	if(character == "player") then
		matrix = playerItemMatrix;
	else
		matrix = _G.ImhoBagsItemMatrix[Inspect.Shard().name][character] or { items = { }, slots = { } }
	end
	-- Dump all relevant items into a temporary table to be sorted later
	local items, empty, success;
	if(character == "player") then
		items, empty, success = extractUnsortedPlayerItems(prefix, condense)
	else
		items, empty, success = extractUnsortedCharacterItems(matrix, prefix, condense)
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

table.insert(Event.Addon.Startup.End, { startupEnd, AddonName, "ItemDB_startupEnd" })
table.insert(Event.Addon.SavedVariables.Save.Begin, { saveVariables, AddonName, "ItemDB_saveVariables" })
table.insert(Event.Item.Slot, { mergeSlotUpdate, AddonName, "ItemDB_mergeSlotUpdate" })
table.insert(Event.Item.Update, { function(arg) print("Event.Item.Update") dump(arg) end, AddonName, "ItemDB_print" })
