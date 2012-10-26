local Addon, private = ...

-- Builtins
local _G = _G
local pairs = pairs

-- Globals
local Event = Event
local InspectCurrencyDetail = Inspect.Currency.Detail
local InspectItemDetail = Inspect.Item.Detail
local InspectItemList = Inspect.Item.List
local InspectGuildBankCoin = Inspect.Guild.Bank.Coin
local InspectGuildBankList = Inspect.Guild.Bank.List
local InspectGuildRankDetail = Inspect.Guild.Rank.Detail
local InspectGuildRosterDetail = Inspect.Guild.Roster.Detail
local UtilityItemSlotGuild = Utility.Item.Slot.Guild
local UtilityItemSlotParse = Utility.Item.Slot.Parse

-- Locals
local charData
local guildData
local player
local guild
local guildVaultSlots = { }

setfenv(1, private)
Item = Item or { }
Item.Storage = { }

-- Private methods
-- ============================================================================

local function newLocation(bags)
	return {
		bags = bags and { } or nil,
		slots = { },
		counts = { },
		totals = { },
	}
end

local function newCharacter()
	return {
		info = {
			guild = nil,
			alliance = nil,
		},
		bank = newLocation(true),
		currency = {
			totals = { },
			categories = { },
		},
		equipment = newLocation(),
		inventory = newLocation(true),
		quest = newLocation(),
		wardrobe = newLocation(),
	}
end

local function newGuild()
	return {
		info = {
			coin = 0,
		},
		vault = {
			-- [*] = { newLocation(), [name] = name }
		},
	}
end

local function eventAddonSavedVariablesLoadEnd(identifier)
	if(identifier ~= Addon.identifier) then
		return
	end
	
	charData = _G.ImhoBags_ItemStorageCharacters or { }
	player = charData[Player.name] or newCharacter()
	charData[Player.name] = player
	
	Trigger.StorageLoaded()
end

local function eventAddonSavedVariablesSaveBegin(identifier)
	if(identifier ~= Addon.identifier) then
		return
	end
	
	_G.ImhoBags_ItemStorageCharacters = charData
	_G.ImhoBags_ItemStorageGuilds = guildData
end

local function removeFromTotals(container, item, count)
	if(item) then
		local total = container.totals[item] and (container.totals[item] - count)
		-- Prevent table from growing indefinitely
		if(total and total <= 0) then
			total = nil
		end
		container.totals[item] = total
	end
end

local function mergeSlotShared(container, slot, item, bag, index)
	if(item and item ~= "nil") then
		item = InspectItemDetail(item)
	end
	if(bag == "bag") then
		removeFromTotals(container, container.bags[slot], 1)
		if(item) then
			container.bags[slot] = item.type
			container.totals[item.type] = (container.totals[item.type] or 0) + 1
		else
			container.bags[slot] = false
		end
		return nil
	elseif(item and item ~= "nil") then
		removeFromTotals(container, container.slots[slot], container.counts[slot] or 0)

		container.slots[slot] = item.type
		container.counts[slot] = item.stack or 1
		container.totals[item.type] = (container.totals[item.type] or 0) + (item.stack or 1)
	end
	return item
end

local function mergeSlot(container, slot, item, bag, index)
	item = mergeSlotShared(container, slot, item, bag, index)
	
	if(item == false or item == "nil") then
		removeFromTotals(container, container.slots[slot], container.counts[slot] or 0)

		if(item) then
			container.slots[slot] = nil
			container.counts[slot] = nil
		else
			container.slots[slot] = false
			container.counts[slot] = 0
		end
	end
end

local function mergeSlotGuild(container, slot, item, bag, index)
	-- Do not remove item for "nil" arguments.
	-- That is handled separately by rank permissions and roster membership
	if(item ~= "nil") then
		item = mergeSlotShared(container, slot, item, bag, index)
		if(item == false) then
			removeFromTotals(container, container.slots[slot], container.counts[slot] or 0)
			container.slots[slot] = false
			container.counts[slot] = 0
		end
	end
end

local function eventCurrency(currencies)
	for type, count in pairs(currencies) do
		if(not count or count <= 0) then
			player.currency.totals[type] = nil
			player.currency.categories[type] = nil
		else
			player.currency.totals[type] = count
			player.currency.categories[type] = InspectCurrencyDetail(type).category
		end
	end
end

local function eventGuildBankChange(vaults)
	for id, name in pairs(vaults) do
		guild.vault[id] = guild.vault[id] or newLocation()
		guild.vault[id].name = name
	end
end

local function eventGuildBankCoin(coin)
	guild.info.coin = coin
end

local function eventInteraction(interaction, state)
	if(interaction == "guildbank" and state) then
		eventGuildBankCoin(InspectGuildBankCoin())
	end
end

local function eventItemSlot(items)
	for slot, item in pairs(items) do
		local container, bag, index = UtilityItemSlotParse(slot)
		log("eventItemSlot", slot, container, item)
		if(player[container]) then
			mergeSlot(player[container], slot, item, bag, index)
		elseif(container == "guild") then
			local vault = guildVaultSlots[bag]
			if(not vault) then
				vault = UtilityItemSlotGuild(bag)
				guildVaultSlots[bag] = vault
			end
			mergeSlotGuild(guild.vault[vault], slot, item, bag, index)
		end
	end
end

local function eventItemUpdate(items)
	for slot, item in pairs(items) do
		local container, bag, index = UtilityItemSlotParse(slot)
		log("eventItemUpdate", slot, container, item)
		item = InspectItemDetail(item)
		if(player[container]) then
			container = player[container]
		elseif(container == "guild") then
			local vault = guildVaultSlots[bag]
			log(vault)
			if(not vault) then
				vault = UtilityItemSlotGuild(bag)
				guildVaultSlots[bag] = vault
			end
			container = guild.vault[vault]
		end
		container.totals[item.type] = (container.totals[item.type] or 0) - (container.counts[slot] or 0) + (item.stack or 1)
		container.counts[slot] = item.stack or 1
	end
end

local function applyGuildRank(rank)
	local vaultAccess = InspectGuildRankDetail(rank).vaultAccess
	
	-- Delete item data for vaults we have no longer access to
	for slot in pairs(guild.vault) do
		local vault = vaultAccess[slot] or { }
		if(not vault.access) then
			local name = guild.vault[slot].name
			guild.vault[slot] = newLocation()
			guild.vault[slot].name = name
		end
		guild.vault[slot].access = vault.access
		guild.vault[slot].withdrawLimit = vault.withdrawLimit
	end
end

local function eventGuildRank(ranks)
	local playerRank = InspectGuildRosterDetail(Player.name).rank
	if(ranks[playerRank]) then
		applyGuildRank(playerRank)
	end
end

local function eventGuildRosterDetailRank(units)
	local rank = units[Player.name]
	if(rank) then
		applyGuildRank(rank)
	end
end

local function guildChanged(old, new)
	player.info.guild = new
	if(old) then
		local members = 0
		for name, data in pairs(charData) do
			if(data.info.guild == old) then
				members = members + 1
			end
		end
		if(members == 0) then
			guildData[old] = nil
		end
	end
	if(new) then
		guild = guildData[new] or newGuild()
		guildData[new] = guild
		eventGuildBankChange(InspectGuildBankList())
		local roster = InspectGuildRosterDetail(Player.name)
		if(roster) then
			applyGuildRank(roster.rank)
		end
	else
		guild = newGuild()
	end
end

local function init()
	player.info.alliance = Player.alliance
	eventItemSlot(InspectItemList("si"))

	guildData = _G.ImhoBags_ItemStorageGuilds or { }
	-- Catch cases where a character is removed from a guild while offline
	guildChanged(player.info.guild, Player.guild)
end

-- Public methods
-- ============================================================================

function Item.Storage.FindGuild(name)
	if(charData[name]) then
		return charData[name].info.guild
	else
		return guildData[name]
	end
end

function Item.Storage.GetCharacterAlliances()
	local chars = { }
	for name, data in pairs(charData) do
		chars[name] = data.info.alliance
	end
	return chars
end

function Item.Storage.GetCharacterCoins()
	local chars = { }
	for name, data in pairs(charData) do
		chars[name] = data.currency.totals.coin or 0
	end
	return chars
end

function Item.Storage.GetCharacterItems(character, location)
	local char = charData[character]
	if(char) then
		local loc = char[location]
		if(loc) then
			return loc.totals, (loc.slots or loc.categories), loc.counts, loc.bags
		end
	end
	return { }, { }, { }, { }
end

function Item.Storage.GetCharacterNames()
	local chars = { }
	for name in pairs(charData) do
		chars[#chars + 1] = name
	end
	return chars
end

function Item.Storage.GetGuildCoins()
	local coins = { }
	for name, data in pairs(guildData) do
		coins[name] = data.info.coin or 0
	end
	return coins
end

function Item.Storage.GetGuildItems(guild, vault)
	guild = guildData[guild]
	if(guild) then
		vault = guild.vault[vault]
		if(vault) then
			return vault.totals, vault.slots, vault.counts
		end
	end
	return { }, { }, { }
end

function Item.Storage.GetGuildNames()
	local guilds = { }
	for name in pairs(guildData) do
		guilds[#guilds + 1] = name
	end
	return guilds
end

function Item.Storage.GetGuildVaults(name)
	local vaults = { }
	if(guildData[name]) then
		for id, name in pairs(guildData[name].vault) do
			vaults[id] = name
		end
	end
	return vaults
end

Event.Addon.SavedVariables.Load.End[#Event.Addon.SavedVariables.Load.End + 1] = {
	eventAddonSavedVariablesLoadEnd,
	Addon.identifier,
	"Item.Storage.eventAddonSavedVariablesLoadEnd"
}
Event.Addon.SavedVariables.Save.Begin[#Event.Addon.SavedVariables.Save.Begin + 1] = {
	eventAddonSavedVariablesSaveBegin,
	Addon.identifier,
	"Item.Storage.eventAddonSavedVariablesSaveBegin"
}
Event.Currency[#Event.Currency + 1] = {
	eventCurrency,
	Addon.identifier,
	"Item.Storage.eventCurrency"
}
Event.Guild.Bank.Change[#Event.Guild.Bank.Change + 1] = {
	eventGuildBankChange,
	Addon.identifier,
	"Item.Storage.eventGuildBankChange"
}
Event.Guild.Bank.Coin[#Event.Guild.Bank.Coin + 1] = {
	eventGuildBankCoin,
	Addon.identifier,
	"Item.Storage.eventGuildBankCoin"
}
Event.Guild.Rank[#Event.Guild.Rank + 1] = {
	eventGuildRank,
	Addon.identifier,
	"Item.Storage.eventGuildRank"
}
Event.Guild.Roster.Detail.Rank[#Event.Guild.Roster.Detail.Rank + 1] = {
	eventGuildRosterDetailRank,
	Addon.identifier,
	"Item.Storage.eventGuildRosterDetailRank"
}
Event.Interaction[#Event.Interaction + 1] = {
	eventInteraction,
	Addon.identifier,
	"Item.Storage.eventInteraction"
}
Event.Item.Slot[#Event.Item.Slot + 1] = {
	eventItemSlot,
	Addon.identifier,
	"Item.Storage.eventItemSlot"
}
Event.Item.Update[#Event.Item.Update + 1] = {
	eventItemUpdate,
	Addon.identifier,
	"Item.Storage.eventItemUpdate"
}
Event.ImhoBags.Private.Guild[#Event.ImhoBags.Private.Guild + 1] = {
	guildChanged,
	Addon.identifier,
	"Item.Storage.guildChanged"
}
Event.ImhoBags.Private.Init[#Event.ImhoBags.Private.Init + 1] = {
	init,
	Addon.identifier,
	"Item.Storage.init"
}
