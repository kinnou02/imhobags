local Addon, private = ...

-- Builtins
local _G = _G
local assert = assert
local coroutine = coroutine
local pairs = pairs
local print = print
local setmetatable = setmetatable
local sort = table.sort
local strmatch = string.match
local tremove = table.remove
local tonumber = tonumber
local type = type

-- Globals
local Event = Event
local Inspect = Inspect
local Utility = Utility

-- Locals
local playerItems
local playerGuildItems

local playerFactionCharacters
local enemyFactionCharacters

local playerFactionGuilds
local enemyFactionGuilds

local lowestCompatibleItemDBMajor = 0
local lowestCompatibleItemDBMinor = 9

local maxMergeTime = 0.050

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
		wardrobe = WardrobeMatrix.New(),
		
		version = Addon.toc.Version,
	}
end

local function newGuild()
	return {
		vaults = 0,
		name = "<none>",
		
		version = Addon.toc.Version,
	}
end

local function checkForCompatibleItemDB(character, name)
	if(not character) then
		return nil
	end
	local major, minor = strmatch(character.version or "0.1", "(%d+)%.(%d+)")
	if(tonumber(major) < lowestCompatibleItemDBMajor or (tonumber(major) == lowestCompatibleItemDBMajor and tonumber(minor) < lowestCompatibleItemDBMinor)) then
		print("Deleting incompatible item database for: " .. name, character.version)
		return nil
	else
		character.bank		= ItemMatrix.ApplyMetaTable(character.bank)
		character.currency	= CurrencyMatrix.ApplyMetaTable(character.currency)
		character.equipment	= ItemMatrix.ApplyMetaTable(character.equipment)
		character.inventory	= ItemMatrix.ApplyMetaTable(character.inventory)
		character.mail		= MailMatrix.ApplyMetaTable(character.mail)
		character.wardrobe	= WardrobeMatrix.ApplyMetaTable(character.wardrobe)
		
		character.version = Addon.toc.Version
		return character
	end
end

local function checkForCompatibleGuildDB(guild, name)
	if(not guild) then
		return nil
	end
	local major, minor = strmatch(guild.version or "0.1", "(%d+)%.(%d+)")
	if(tonumber(major) < lowestCompatibleItemDBMajor or tonumber(minor) < lowestCompatibleItemDBMinor) then
		print("Deleting incompatible item database for: " .. name, guild.version)
		return nil
	else
		for i = 1, guild.vaults do
			guild[i] = ItemMatrix.ApplyMetaTable(guild[i])
		end
		guild.version = Addon.toc.Version
		return guild
	end
end

local function variablesLoaded(addonIdentifier)
	if(addonIdentifier ~= Addon.identifier) then
		return
	end
	-- A /reloadui does not trigger all the Event.Item.Slot events as on log in or teleport.
	-- That's why we need a separate "character"-stored table with
	-- readily available data after a /reloadui
	playerItems = checkForCompatibleItemDB(_G.ImhoBags_PlayerItemMatrix, "player") or newCharacter()
	playerItems.guild = nil
end

local function prepareTables()
	-- Ensure our data table exists
	playerFactionCharacters = _G["ImhoBags_ItemMatrix_" .. PlayerFaction] or { }
	_G["ImhoBags_ItemMatrix_" .. PlayerFaction] = playerFactionCharacters
	enemyFactionCharacters = _G["ImhoBags_ItemMatrix_" .. EnemyFaction] or { }
	_G["ImhoBags_ItemMatrix_" .. EnemyFaction] = enemyFactionCharacters
	
	playerFactionCharacters.version = nil -- From older versions
	enemyFactionCharacters.version = nil

	playerFactionGuilds = _G["ImhoBags_GuildMatrix_" .. PlayerFaction] or { }
	_G["ImhoBags_GuildMatrix_" .. PlayerFaction] = playerFactionGuilds
	enemyFactionGuilds = _G["ImhoBags_GuildMatrix_" .. EnemyFaction] or { }
	_G["ImhoBags_GuildMatrix_" .. EnemyFaction] = enemyFactionGuilds
	
	-- Apply the metatable to all item matrices on the current shard
	for k, v in pairs(playerFactionCharacters) do
		if(type(v) == "table") then
			playerFactionCharacters[k] = checkForCompatibleItemDB(v, k)
		end
	end
	for k, v in pairs(enemyFactionCharacters) do
		if(type(v) == "table") then
			enemyFactionCharacters[k] = checkForCompatibleItemDB(v, k)
		end
	end
	
	-- Apply the metatable to all item matrices on the current shard
	for k, v in pairs(playerFactionGuilds) do
		if(type(v) == "table") then
			playerFactionGuilds[k] = checkForCompatibleGuildDB(v, k)
		end
	end
	for k, v in pairs(enemyFactionGuilds) do
		if(type(v) == "table") then
			enemyFactionGuilds[k] = checkForCompatibleGuildDB(v, k)
		end
	end

	-- Delete the player from the shard DB to save space and other computations
	playerFactionCharacters[PlayerName] = nil
	-- Find the player's guild
	if(PlayerGuild) then
		playerGuildItems = playerFactionGuilds[PlayerGuild] or newGuild()
		playerGuildItems.name = PlayerGuild
		playerFactionGuilds[PlayerGuild] = playerGuildItems
		playerItems.guild = playerGuildItems
	else
		playerGuildItems = newGuild()
	end
	
	-- Make the guild table values weak so we don't need to clean it up all the time
	setmetatable(playerFactionGuilds, { __mode = "v" })
end

local function saveVariables(addonIdentifier)
	if(addonIdentifier ~= Addon.identifier) then
		return
	end
	
	-- Force lastUpdate to -1 in all matrices, this ensures the
	-- math works for all characters on the shard
	playerItems.bank.lastUpdate = -1
	playerItems.currency.lastUpdate = -1
	playerItems.equipment.lastUpdate = -1
	playerItems.inventory.lastUpdate = -1
	playerItems.mail.lastUpdate = -1
	playerItems.wardrobe.lastUpdate = -1
	_G["ImhoBags_ItemMatrix_" .. PlayerFaction][PlayerName] = playerItems
	_G.ImhoBags_PlayerItemMatrix = playerItems
	
	if(playerItems.guild) then
		for i = 1, playerGuildItems.vaults do
			if(playerGuildItems[i]) then
				playerGuildItems[i].lastUpdate = -1
			end
		end
	end
end

local jobs = { }
local function runJobs()
	if(#jobs > 0) then
		local job = jobs[#jobs]
		if(coroutine.status(job) == "dead") then
			tremove(jobs, 1)
		else
			assert(coroutine.resume(job))
		end
	end
end

local function addJob(f, ...)
	local job = coroutine.create(f)
	assert(coroutine.resume(job, ...))
	if(coroutine.status(job) ~= "dead") then
		jobs[#jobs + 1] = job
	end
end

local function interactionChanged(interaction, state)
	if(interaction == "mail" and state) then
		playerItems.mail:Purge(Inspect.Mail.List())
	end
end

local function mergeSlotChanges(slots)
	local yield = Inspect.Time.Real() + maxMergeTime
	for slot, item in pairs(slots) do
		if(item ~= "nil") then
			local container, bag, index = Utility.Item.Slot.Parse(slot)
			if(container == "guild") then
				if(not playerGuildItems[bag]) then
					playerGuildItems[bag] = ItemMatrix.New()
					if(bag > playerGuildItems.vaults) then
						playerGuildItems.vaults = bag
					end
				end
				playerGuildItems[bag]:MergeSlot(slot, item, bag, index)
			else
				local matrix = playerItems[container]
				if(matrix) then
					matrix:MergeSlot(slot, item, bag, index)
				end
			end
		end
		if(Inspect.Time.Real() > yield) then
			coroutine.yield()
			yield = Inspect.Time.Real() + maxMergeTime
		end
	end
end

local function mailsChanged(mails)
	if(not Inspect.Interaction("mail")) then
		return -- Can happen in laggy situations
	end
	
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

local function guildChanged(old, new)
	if(old) then
		for i = 1, playerGuildItems.vaults do
			if(playerGuildItems[i]) then
				playerGuildItems[i].lastUpdate = -1
			end
		end
	end
	if(new) then
		playerGuildItems = playerFactionGuilds[new] or newGuild()
		playerFactionGuilds[new] = playerGuildItems
		playerItems.guild = playerGuildItems
	else
		playerGuildItems = newGuild()
		playerItems.guild = nil
	end
end

local function init()
	prepareTables()
end

-- Public methods
-- ============================================================================

--[[
Get the matrix for the given character's location
location: "inventory", "bank", "equipped", "mail", "wardrobe", "currency"
return: matrix, enemy
	matrix: The matrix table for the character and location
	enemy: True if the matrix belongs to the enemy faction
]]
function ItemDB.GetItemMatrix(character, location)
	local items, enemy
	if(character == "player" or PlayerName == character) then
		items, enemy = playerItems, false
	else
		items, enemy = playerFactionCharacters[character], false
		if(not items and Config.showEnemyFaction ~= "no") then
			items, enemy = enemyFactionCharacters[character], true
		end
	end
	return (items and items[location]) or (location == "mail" and MailMatrix.New() or ItemMatrix.New()), enemy
end

--[[
Get the matrix for the given guilds's vault
vault: The vault index
return: matrix, enemy
	matrix: The matrix table for the guild vault
	enemy: True if the matrix belongs to the enemy faction
]]
function ItemDB.GetGuildMatrix(guild, vault)
	local items, enemy = playerFactionGuilds[guild], false
	if(not items and Config.showEnemyFaction ~= "no") then
		items, enemy = enemyFactionGuilds[guild], true
	end
	return (items and items[vault]) or ItemMatrix.New(), enemy
end

--[[
Get information about a guild's vaults
return: info, enemy
	info: The vault information
	enemy: True if the matrix belongs to the enemy faction
]]
function ItemDB.GetGuildVaults(guild)
	local info = playerFactionGuilds[guild], false
	if(not info and Config.showEnemyFaction ~= "no") then
		info, enemy = enemyFactionGuilds[guild], true
	end
	return info and info.vaults, enemy
end

function ItemDB.GetCharactersCoin()
	local result = {
		guardian = { },
		defiant = { }
	}
	local tbl = result[PlayerFaction]
	tbl[PlayerName] = playerItems.currency.items.coin or 0
	for char, data in pairs(playerFactionCharacters) do
		tbl[char] = data.currency.items.coin or 0
	end
	local tbl = result[EnemyFaction]
	for char, data in pairs(enemyFactionCharacters) do
		tbl[char] = data.currency.items.coin or 0
	end
	return result
end

-- Return an array of all characters on the current shard and faction for which item data is available
function ItemDB.GetAvailableCharacters()
	local result = { }
	for char, data in pairs(playerFactionCharacters) do
		result[#result + 1] = char
	end
	if(Config.showEnemyFaction ~= "no") then
		for char, data in pairs(enemyFactionCharacters) do
			result[#result + 1] = char
		end
	end
	result[#result + 1] = PlayerName
	sort(result)
	return result
end

-- Return an array of all guilds on the current shard and faction for which item data is available
function ItemDB.GetAvailableGuilds()
	local result = { }
	for guild, data in pairs(playerFactionGuilds) do
		result[#result + 1] = guild
	end
	if(Config.showEnemyFaction ~= "no") then
		for guild, data in pairs(enemyFactionGuilds) do
			result[#result + 1] = guild
		end
	end
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
	for char, data in pairs(playerFactionCharacters) do
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
	if(Config.showEnemyFaction ~= "no") then
		if(Config.showEnemyFaction == "yes" or itemType.bind == "account") then
			for char, data in pairs(enemyFactionCharacters) do
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

function ItemDB.GetGuildItemCounts(itemType)
	local result = { }
	local t = itemType.type
	for guild, data in pairs(playerFactionGuilds) do
		local temp = { guild }
		for i = 1, data.vaults do
			if(data[i]) then
				temp[#temp + 1] = data[i]:GetItemCount(t)
			else
				temp[#temp + 1] = 0
			end
		end
		result[#result + 1] = temp
	end
	if(Config.showEnemyFaction ~= "no") then
		if(Config.showEnemyFaction == "yes" or itemType.bind == "account") then
			for guild, data in pairs(enemyFactionGuilds) do
				local temp = { guild }
				for i = 1, data.vaults do
					if(data[i]) then
						temp[#temp + 1] = data[i]:GetItemCount(t)
					else
						temp[#temp + 1] = 0
					end
				end
				result[#result + 1] = temp
			end
		end
	end
	sort(result, function(a, b) return a[1] < b[1] end)
	return result
end

function ItemDB.CharacterExists(name)
	if(name == "player" or name == PlayerName) then
		return true
	end
	if(Config.showEnemyFaction ~= "no") then
		return (playerFactionCharacters[name] or enemyFactionCharacters[name]) ~= nil
	else
		return playerFactionCharacters[name] ~= nil
	end
end

-- Return a table with all stored item types where the key is the type and the value is true
function ItemDB.GetAllItemTypes()
	local result = { }
	for char, data in pairs(playerFactionCharacters) do
		data.bank:GetAllItemTypes(result)
		data.currency:GetAllItemTypes(result)
		data.inventory:GetAllItemTypes(result)
		data.mail:GetAllItemTypes(result)
		data.equipment:GetAllItemTypes(result)
		data.wardrobe:GetAllItemTypes(result)
	end
	for guild, data in pairs(playerFactionGuilds) do
		for i = 1, data.vaults do
			if(data[i]) then
				data[i]:GetAllItemTypes(result)
			end
		end
	end
	if(Config.showEnemyFaction ~= "no") then
		local accountBoundOnly = Config.showEnemyFaction == "account"
		for char, data in pairs(enemyFactionCharacters) do
			data.bank:GetAllItemTypes(result, accountBoundOnly)
			data.currency:GetAllItemTypes(result, accountBoundOnly)
			data.inventory:GetAllItemTypes(result, accountBoundOnly)
			data.mail:GetAllItemTypes(result, accountBoundOnly)
			data.equipment:GetAllItemTypes(result, accountBoundOnly)
			data.wardrobe:GetAllItemTypes(result, accountBoundOnly)
		end
		for guild, data in pairs(enemyFactionGuilds) do
			for i = 1, data.vaults do
				if(data[i]) then
					data[i]:GetAllItemTypes(result, accountBoundOnly)
				end
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

--[[
If given the name of a guild returns the guild, otherwise tries to
find the guild belonging to the given character
]]
function ItemDB.FindGuild(name)
	if(name == "player") then
		return playerItems.guild and playerItems.guild.name
	end
	-- Check guilds first
	for guild, data in pairs(playerFactionGuilds) do
		if(guild == name) then
			return guild
		end
	end
	if(Config.showEnemyFaction ~= "no") then
		for guild, data in pairs(enemyFactionGuilds) do
			if(guild == name) then
				return guild
			end
		end
	end
	-- Now find matching characters
	for char, data in pairs(playerFactionCharacters) do
		if(char == name) then
			return data.guild and data.guild.name
		end
	end
	if(Config.showEnemyFaction ~= "no") then
		for char, data in pairs(enemyFactionCharacters) do
			if(char == name) then
				return data.guild and data.guild.name
			end
		end
	end
	return nil
end

_G.table.insert(Event.Addon.SavedVariables.Load.End, { variablesLoaded, Addon.identifier, "ItemDB_variablesLoaded" })
_G.table.insert(Event.Addon.SavedVariables.Save.Begin, { saveVariables, Addon.identifier, "ItemDB_saveVariables" })
_G.table.insert(Event.Currency, { currencyChanged, Addon.identifier, "ItemDB_currencyChanged" })
_G.table.insert(Event.Interaction, { interactionChanged, Addon.identifier, "ItemDB_interactionChanged" })
_G.table.insert(Event.Item.Slot, { function(...) addJob(mergeSlotChanges, ...) end, Addon.identifier, "ItemDB_mergeSlotChanges" })
_G.table.insert(Event.Item.Update, { function(...) addJob(mergeSlotChanges, ...) end, Addon.identifier, "ItemDB_mergeSlotChanges" })
_G.table.insert(Event.Mail, { mailsChanged, Addon.identifier, "ItemDB_mailsChanged" })
_G.table.insert(Event.System.Update.Begin, { runJobs, Addon.identifier, "ItemDB_runJobs" })

_G.table.insert(ImhoEvent.Init, { init, Addon.identifier, "ItemDB_init" })
_G.table.insert(ImhoEvent.Guild, { guildChanged, Addon.identifier, "ItemDB_guildChanged" })
