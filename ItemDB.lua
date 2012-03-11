local Addon, private = ...

-- Builtins
local _G = _G
local ipairs = ipairs
local next = next
local pairs = pairs
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
local factionItems

setfenv(1, private)
ItemDB = { }

-- Private methods
-- ============================================================================

local function newCharacter()
	return {
		-- List only locations we care about
		bank = ItemMatrix.New(),
		equipment = ItemMatrix.New(),
		inventory = ItemMatrix.New(),
		mail = MailMatrix.New(),
		wardrobe = ItemMatrix.New(),
		
		version = Addon.toc.Version,
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

local function variablesLoaded(addonIdentifier)
	if(addonIdentifier ~= Addon.identifier) then
		return
	end
	-- A /reloadui does not trigger all the Event.Item.Slot events as on log in or teleport.
	-- That's why we need a separate "character"-stored table with
	-- readily available data after a /reloadui
	playerItems = _G.ImhoBags_PlayerItemMatrix or newCharacter()
	
	playerItems.bank		= ItemMatrix.ApplyMetaTable(playerItems.bank)
	playerItems.equipment	= ItemMatrix.ApplyMetaTable(playerItems.equipment)
	playerItems.inventory	= ItemMatrix.ApplyMetaTable(playerItems.inventory)
	playerItems.mail		= MailMatrix.ApplyMetaTable(playerItems.mail)
	playerItems.wardrobe	= ItemMatrix.ApplyMetaTable(playerItems.wardrobe)
end

local function prepareTables()
	-- Ensure our data table exists
	factionItems = _G["ImhoBags_ItemMatrix_" .. PlayerFaction] or {
		version = Addon.toc.Version,
	}
	_G["ImhoBags_ItemMatrix_" .. PlayerFaction] = factionItems
	
	-- Apply the metatable to all item matrices on the current shard
	for k, v in pairs(factionItems) do
		if(type(v) == "table") then
			v.bank		= ItemMatrix.ApplyMetaTable(v.bank)
			v.equipment	= ItemMatrix.ApplyMetaTable(v.equipment)
			v.inventory	= ItemMatrix.ApplyMetaTable(v.inventory)
			v.mail		= MailMatrix.ApplyMetaTable(v.mail)
			v.wardrobe	= ItemMatrix.ApplyMetaTable(v.wardrobe)
		end
	end
end

local function saveVariables(addonIdentifier)
	if(addonIdentifier ~= Addon.identifier) then
		return
	end
	
	-- Force lastUpdate to -1 in all matrices, this ensures the
	-- math works for all characters on the shard
	playerItems.bank.lastUpdate = -1
	playerItems.equipment.lastUpdate = -1
	playerItems.inventory.lastUpdate = -1
	playerItems.mail.lastUpdate = -1
	playerItems.wardrobe.lastUpdate = -1
	_G["ImhoBags_ItemMatrix_" .. PlayerFaction][PlayerName] = playerItems
	_G.ImhoBags_PlayerItemMatrix = playerItems
end

local function interactionChanged(interaction, state)
	if(interaction == "mail" and state) then
		playerItems.mail:Purge(Inspect.Mail.List())
	end
end

local function mailsChanged(mails)
	for mail, info in pairs(mails) do
		if(info == "detail") then
			playerItems.mail:MergeMail(Inspect.Mail.Detail(mail))
		end
	end
	-- Remove deleted mails.
	-- If interaction is still available then mails flagged as "false" no longer exist.
	if(Inspect.Interaction("mail")) then
		playerItems.mail:Purge(Inspect.Mail.List())
	end
end

local function init()
	prepareTables()
end

-- Public methods
-- ============================================================================

--[[
Get the matrix for the given character's location matrix
location: "inventory", "bank", "equipped", "mail", "wardrobe"
return: The matrix table for the character and location
]]
function ItemDB.GetItemMatrix(character, location)
	local matrix;
	if(character == "player" or PlayerName == character) then
		matrix = playerItems;
	else
		matrix = factionItems[character] or ItemDB_newCharacter()
	end
	return matrix[location] or ItemMatrix.New()
end

-- Return an array of all characters on the current shard and faction for which item data is available
function ItemDB.GetAvailableCharacters()
	local result = { }
	for char, data in pairs(factionItems) do
		if(char ~= PlayerName and type(data) == "table") then
			table.insert(result, char)
		end
	end
	table.insert(result, PlayerName)
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
	for char, data in pairs(factionItems) do
		if(char ~= PlayerName and type(data) == "table") then
			table.insert(result, {
				char,
				data.inventory:GetItemCount(itemType),
				data.bank:GetItemCount(itemType),
				data.mail:GetItemCount(itemType),
				data.equipment:GetItemCount(itemType),
				data.wardrobe:GetItemCount(itemType),
			})
		end
	end
	table.insert(result, {
		PlayerName,
		playerItems.inventory:GetItemCount(itemType),
		playerItems.bank:GetItemCount(itemType),
		playerItems.mail:GetItemCount(itemType),
		playerItems.equipment:GetItemCount(itemType),
		playerItems.wardrobe:GetItemCount(itemType),
	})
	table.sort(result, function(a, b) return a[1] < b[1] end)
	return result
end

function ItemDB.CharacterExists(name)
	if(name == "player" or name == PlayerName) then
		return true
	end
	return factionItems[name] ~= nil
end

-- Return a table with all stored item types where the key is the type and the value is true
function ItemDB.GetAllItemTypes()
	local result = { }
	for char, data in pairs(factionItems) do
		if(char ~= PlayerName and type(data) == "table") then
			data.inventory:GetAllItemTypes(result)
			data.bank:GetAllItemTypes(result)
			data.mail:GetAllItemTypes(result)
			data.equipment:GetAllItemTypes(result)
			data.wardrobe:GetAllItemTypes(result)
		end
	end
	playerItems.inventory:GetAllItemTypes(result)
	playerItems.bank:GetAllItemTypes(result)
	playerItems.mail:GetAllItemTypes(result)
	playerItems.equipment:GetAllItemTypes(result)
	playerItems.wardrobe:GetAllItemTypes(result)
	return result
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
function ItemDB.GetGroupedItems(items, group)
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

table.insert(Event.Addon.SavedVariables.Load.End, { variablesLoaded, Addon.identifier, "ItemDB_variablesLoaded" })
table.insert(Event.Addon.SavedVariables.Save.Begin, { saveVariables, Addon.identifier, "ItemDB_saveVariables" })
table.insert(Event.Interaction, { interactionChanged, Addon.identifier, "ItemDB_interactionChanged" })
table.insert(Event.Item.Slot, { mergeSlotChanges, Addon.identifier, "ItemDB_mergeSlotChanges" })
table.insert(Event.Item.Update, { mergeSlotChanges, Addon.identifier, "ItemDB_mergeSlotChanges" })
table.insert(Event.Mail, { mailsChanged, Addon.identifier, "ItemDB_mailsChanged" })

table.insert(ImhoEvent.Init, { init, Addon.identifier, "ItemDB_init" })
