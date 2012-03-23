local Addon, private = ...

-- Builtins
local _G = _G
local pairs = pairs
local sort = table.sort
local type = type

-- Globals
local Event = Event
local Inspect = Inspect
local Utility = Utility

-- Locals
local playerItems
local playerFactionItems
local enemyFactionItems

setfenv(1, private)
ItemDB = { }

-- Private methods
-- ============================================================================

local function newCharacter()
	return {
		-- List only locations we care about
		bank = ItemMatrix.New(),
		currency = CurrencyMatrix.New(),
		equipment = ItemMatrix.New(),
		inventory = ItemMatrix.New(),
		mail = MailMatrix.New(),
		wardrobe = ItemMatrix.New(),
		
		version = Addon.toc.Version,
	}
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
	playerItems.currency	= CurrencyMatrix.ApplyMetaTable(playerItems.currency)
	playerItems.equipment	= ItemMatrix.ApplyMetaTable(playerItems.equipment)
	playerItems.inventory	= ItemMatrix.ApplyMetaTable(playerItems.inventory)
	playerItems.mail		= MailMatrix.ApplyMetaTable(playerItems.mail)
	playerItems.wardrobe	= ItemMatrix.ApplyMetaTable(playerItems.wardrobe)
end

local function prepareTables()
	-- Ensure our data table exists
	playerFactionItems = _G["ImhoBags_ItemMatrix_" .. PlayerFaction] or {
		version = Addon.toc.Version,
	}
	_G["ImhoBags_ItemMatrix_" .. PlayerFaction] = playerFactionItems
	enemyFactionItems = _G["ImhoBags_ItemMatrix_" .. EnemyFaction] or {
		version = Addon.toc.Version,
	}
	_G["ImhoBags_ItemMatrix_" .. EnemyFaction] = enemyFactionItems
	
	-- Apply the metatable to all item matrices on the current shard
	for k, v in pairs(playerFactionItems) do
		if(type(v) == "table") then
			v.bank		= ItemMatrix.ApplyMetaTable(v.bank)
			v.currency	= CurrencyMatrix.ApplyMetaTable(v.currency)
			v.equipment	= ItemMatrix.ApplyMetaTable(v.equipment)
			v.inventory	= ItemMatrix.ApplyMetaTable(v.inventory)
			v.mail		= MailMatrix.ApplyMetaTable(v.mail)
			v.wardrobe	= ItemMatrix.ApplyMetaTable(v.wardrobe)
		end
	end
	for k, v in pairs(enemyFactionItems) do
		if(type(v) == "table") then
			v.bank		= ItemMatrix.ApplyMetaTable(v.bank)
			v.currency	= CurrencyMatrix.ApplyMetaTable(v.currency)
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

local function mergeSlotChanges(slots)
	for slot, item in pairs(slots) do
		local container, bag, index = Utility.Item.Slot.Parse(slot)
		local matrix = playerItems[container]
		if(matrix) then
			matrix:MergeSlot(slot, item, bag, index)
		end
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
	-- TODO: When the window is closing this method is called with all entries false
	-- 		We have to fall back to deleting when the window is opened
--[[	if(Inspect.Interaction("mail")) then
		-- Inspect.Mail.List() returns an empty table when the window is closing.
		-- Thus merge the two tables as the mails argument always contains at least one mail.
		local list = Inspect.Mail.List()
		for k, v in pairs(mails) do
			list[k] = v
		end
		dump(list)
		playerItems.mail:Purge(list)
	end
]]
end

local function currencyChanged(currencies)
	for k, v in pairs(currencies) do
		playerItems.currency:MergeCurrency(k, v)
	end
end

local function init()
	prepareTables()
end

-- Public methods
-- ============================================================================

--[[
Get the matrix for the given character's location matrix
location: "inventory", "bank", "equipped", "mail", "wardrobe", "currency"
return: matrix, enemy
	matrix: The matrix table for the character and location
	enemy: True if the matrix belongs to the enemy faction
]]
function ItemDB.GetItemMatrix(character, location)
	local items
	local enemy
	if(character == "player" or PlayerName == character) then
		items, enemy = playerItems, false
	else
		items, enemy = playerFactionItems[character], false
		if(not items and Config.showEnemyFaction ~= "no") then
			items, enemy = enemyFactionItems[character], true
		end
	end
	return (items and items[location]) or ItemMatrix.New(), enemy
end

-- Return an array of all characters on the current shard and faction for which item data is available
function ItemDB.GetAvailableCharacters()
	local result = { }
	for char, data in pairs(playerFactionItems) do
		if(char ~= PlayerName and type(data) == "table") then
			result[#result + 1] = char
		end
	end
	if(Config.showEnemyFaction ~= "no") then
		for char, data in pairs(enemyFactionItems) do
			if(type(data) == "table") then
				result[#result + 1] = char
			end
		end
	end
	result[#result + 1] = PlayerName
	sort(result)
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
	[#] = { name, inventory, bank, mail, equipment, wardrobe, currency }
}
The table is sorted by character name.
]]
function ItemDB.GetItemCounts(itemType)
	local result = { }
	local t = itemType.type
	for char, data in pairs(playerFactionItems) do
		if(char ~= PlayerName and type(data) == "table") then
			result[#result + 1] = {
				char,
				data.inventory:GetItemCount(t),
				data.bank:GetItemCount(t),
				data.mail:GetItemCount(t),
				data.equipment:GetItemCount(t),
				data.wardrobe:GetItemCount(t),
				data.currency:GetItemCount(t),
			}
		end
	end
	if(Config.showEnemyFaction ~= "no") then
		if(Config.showEnemyFaction == "yes" or itemType.bind == "account") then
			for char, data in pairs(enemyFactionItems) do
				if(type(data) == "table") then
					result[#result + 1] = {
						char,
						data.inventory:GetItemCount(t),
						data.bank:GetItemCount(t),
						data.mail:GetItemCount(t),
						data.equipment:GetItemCount(t),
						data.wardrobe:GetItemCount(t),
						data.currency:GetItemCount(t),
					}
				end
			end
		end
	end
	result[#result + 1] = {
		PlayerName,
		playerItems.inventory:GetItemCount(t),
		playerItems.bank:GetItemCount(t),
		playerItems.mail:GetItemCount(t),
		playerItems.equipment:GetItemCount(t),
		playerItems.wardrobe:GetItemCount(t),
		playerItems.currency:GetItemCount(t),
	}
	sort(result, function(a, b) return a[1] < b[1] end)
	return result
end

function ItemDB.CharacterExists(name)
	if(name == "player" or name == PlayerName) then
		return true
	end
	if(Config.showEnemyFaction ~= "no") then
		return (playerFactionItems[name] or enemyFactionItems) ~= nil
	else
		return playerFactionItems[name] ~= nil
	end
end

-- Return a table with all stored item types where the key is the type and the value is true
function ItemDB.GetAllItemTypes()
	local result = { }
	for char, data in pairs(playerFactionItems) do
		if(char ~= PlayerName and type(data) == "table") then
			data.bank:GetAllItemTypes(result)
			data.currency:GetAllItemTypes(result)
			data.inventory:GetAllItemTypes(result)
			data.mail:GetAllItemTypes(result)
			data.equipment:GetAllItemTypes(result)
			data.wardrobe:GetAllItemTypes(result)
		end
	end
	if(Config.showEnemyFaction ~= "no") then
		local accountBoundOnly = Config.showEnemyFaction == "account"
		for char, data in pairs(enemyFactionItems) do
			if(type(data) == "table") then
				data.bank:GetAllItemTypes(result, accountBoundOnly)
				data.currency:GetAllItemTypes(result, accountBoundOnly)
				data.inventory:GetAllItemTypes(result, accountBoundOnly)
				data.mail:GetAllItemTypes(result, accountBoundOnly)
				data.equipment:GetAllItemTypes(result, accountBoundOnly)
				data.wardrobe:GetAllItemTypes(result, accountBoundOnly)
			end
		end
	end
	playerItems.bank:GetAllItemTypes(result)
	playerItems.currency:GetAllItemTypes(result)
	playerItems.inventory:GetAllItemTypes(result)
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
		groups[#groups + 1] = g
		keys[g] = key
		return g
	end
	
	for i = 1, #items do
		local item = items[i]
		local g = groupForKey(group(item.type))
		g[#g + 1] = item
	end
	return groups, keys
end

_G.table.insert(Event.Addon.SavedVariables.Load.End, { variablesLoaded, Addon.identifier, "ItemDB_variablesLoaded" })
_G.table.insert(Event.Addon.SavedVariables.Save.Begin, { saveVariables, Addon.identifier, "ItemDB_saveVariables" })
_G.table.insert(Event.Currency, { currencyChanged, Addon.identifier, "ItemDB_currencyChanged" })
_G.table.insert(Event.Interaction, { interactionChanged, Addon.identifier, "ItemDB_interactionChanged" })
_G.table.insert(Event.Item.Slot, { mergeSlotChanges, Addon.identifier, "ItemDB_mergeSlotChanges" })
_G.table.insert(Event.Item.Update, { mergeSlotChanges, Addon.identifier, "ItemDB_mergeSlotChanges" })
_G.table.insert(Event.Mail, { mailsChanged, Addon.identifier, "ItemDB_mailsChanged" })

_G.table.insert(ImhoEvent.Init, { init, Addon.identifier, "ItemDB_init" })
