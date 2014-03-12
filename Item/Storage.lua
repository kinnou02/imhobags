local Addon, private = ...

-- Upvalue
local InspectCurrencyDetail = Inspect.Currency.Detail
local InspectItemDetail = Inspect.Item.Detail
local InspectItemList = Inspect.Item.List
local InspectGuildBankCoin = Inspect.Guild.Bank.Coin
local InspectGuildBankList = Inspect.Guild.Bank.List
local InspectGuildRankDetail = Inspect.Guild.Rank.Detail
local InspectGuildRosterDetail = Inspect.Guild.Roster.Detail
local pairs = pairs
local UtilityItemSlotGuild = Utility.Item.Slot.Guild
local UtilityItemSlotParse = Utility.Item.Slot.Parse

-- Locals
local characters
local guilds
local player
local guild
local guildVaultSlots = { }
local hookEvents

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

local function eventAddonSavedVariablesLoadEnd(handle, identifier)
	if(identifier ~= Addon.identifier) then
		return
	end
	
	_G.ImhoBags_ItemStorage = _G.ImhoBags_ItemStorage or { }
	_G.ImhoBags_ItemStorage.version = 0.16
	_G.ImhoBags_ItemStorage[Shard.name] = _G.ImhoBags_ItemStorage[Shard.name] or {
		characters = {
		},
		guilds = {
		},
	}
	
	characters = _G.ImhoBags_ItemStorage[Shard.name].characters
	characters[Player.name] = characters[Player.name] or newCharacter()
	player = characters[Player.name]
	characters[Player.name] = player
	
	Trigger.StorageLoaded()
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

local function eventCurrency(handle, currencies)
	for type, count in pairs(currencies) do
		if(not count or count <= 0) then
			player.currency.totals[type] = nil
			player.currency.categories[type] = nil
		else
			local currencyDetail = InspectCurrencyDetail(type)
			if currencyDetail then 
				player.currency.categories[type] = currencyDetail.category
				player.currency.totals[type] = count
			else
				player.currency.totals[type] = nil
				player.currency.categories[type] = nil
			end
		end
	end
end

local function eventGuildBankChange(handle, vaults)
	for id, name in pairs(vaults) do
		guild.vault[id] = guild.vault[id] or newLocation()
		guild.vault[id].name = name
	end
end

local function eventGuildBankCoin(handle, coin)
	guild.info.coin = coin
end

local function eventInteraction(handle, interaction, state)
	if(interaction == "guildbank" and state) then
		eventGuildBankCoin(handle, InspectGuildBankCoin())
	end
end

----------------------------------------------------------
local itemSlotEvents = { }
local eventItemSlotHookEnabled = false
local function eventItemSlot(handle, items)
	-- create the thread (a function)
  local eventItemSlotInstance = coroutine.create( 
  	function (handle, items)
			for slot, item in pairs(items) do
				if Inspect.System.Watchdog() < 0.02 then
					coroutine.yield()
				end
				local container, bag, index = UtilityItemSlotParse(slot)
				if container == "vault" then container = "bank" end
				log("eventItemSlot", slot, container, item)
				if(player[container]) then
					mergeSlot(player[container], slot, item, bag, index)
				elseif(container == "guild") then
					local vault = guildVaultSlots[bag]
					if(not vault) then
						vault = UtilityItemSlotGuild(bag)
						guildVaultSlots[bag] = vault
					end
					container = guild.vault[vault]
					if(container) then
						mergeSlotGuild(container, slot, item, bag, index)
					end
				end
			end
		end
	)
  
  -- Run the thread.  If it is suspended immediately, then add it to 'itemSlotEvents' for handling at the System.Update.Begin event.
	coroutine.resume(eventItemSlotInstance,handle,items)
	if coroutine.status(eventItemSlotInstance) == 'suspended' then
  	itemSlotEvents[#itemSlotEvents + 1] = eventItemSlotInstance
  end
  
  -- System.Update.Begin:   Go through all 'itemSlotEvents' and handle them appropriately
  if not eventItemSlotHookEnabled then
    eventItemSlotHookEnabled = true
    Command.Event.Attach(Event.System.Update.Begin, function (handle)
    	if (#itemSlotEvents > 0) then
				for i = 1, #itemSlotEvents do
					local thread = itemSlotEvents[i]
					if thread and type(thread) == 'thread' then
						local status = coroutine.status(thread)
						--print(string.format("DEBUG:  #itemSlotEvents: %d -- type(thread): %s -- status: %s -- i: %d",#itemSlotEvents,type(thread), tostring(status), i))
						if status == 'suspended' then
							coroutine.resume(thread)
						elseif status == 'dead' then
							table.remove(itemSlotEvents,i)
						end
					end
				end
	    end
    end, "Display")
  end
end
----------------------------------------------------------

local function eventItemUpdate(handle, items)
	for slot, item in pairs(items) do
		local container, bag, index = UtilityItemSlotParse(slot)
		if container == "vault" then container = "bank" end
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
	local guildRankDetail = InspectGuildRankDetail(rank)
	local vaultAccess = { }
	if (guildRankDetail) then
		vaultAccess = guildRankDetail.vaultAccess
	end
	
	-- Delete item data for vaults we have no longer access to
	for slot in pairs(guild.vault) do
		local vault = vaultAccess and vaultAccess[slot] or { }
		if(not vault.access) then
			local name = guild.vault[slot].name
			guild.vault[slot] = newLocation()
			guild.vault[slot].name = name
		end
		if (vault) then
			guild.vault[slot].access = vault.access
			guild.vault[slot].withdrawLimit = vault.withdrawLimit
		end
	end
end

local function eventGuildRank(handle, ranks)
	local member = InspectGuildRosterDetail(Player.name)
	if(member) then
		local playerRank = member.rank
		if(ranks[playerRank]) then
			applyGuildRank(playerRank)
		end
	end
end

local function eventGuildRosterDetailRank(handle, units)
	local rank = units[Player.name]
	if(rank) then
		applyGuildRank(rank)
	end
end

local function guildChanged(handle, old, new)
	player.info.guild = new
	if(old) then
		local members = 0
		for name, data in pairs(characters) do
			if(data.info.guild == old) then
				members = members + 1
			end
		end
		if(members == 0) then
			guilds[old] = nil
		end
	end
	if(new) then
		guild = guilds[new] or newGuild()
		guilds[new] = guild
		eventGuildBankChange(handle, InspectGuildBankList())
		local roster = InspectGuildRosterDetail(Player.name)
		if(roster) then
			applyGuildRank(roster.rank)
		end
	else
		guild = newGuild()
	end
end

local function hookGuildEvents()
	Command.Event.Attach(Event.Guild.Bank.Change, eventGuildBankChange, "Item.Storage.eventGuildBankChange")
	Command.Event.Attach(Event.Guild.Bank.Coin, eventGuildBankCoin, "Item.Storage.eventGuildBankCoin")
	Command.Event.Attach(Event.Guild.Rank, eventGuildRank, "Item.Storage.eventGuildRank")
	Command.Event.Attach(Event.Guild.Roster.Detail.Rank, eventGuildRosterDetailRank, "Item.Storage.eventGuildRosterDetailRank")
end

local function init(handle)
	player.info.alliance = Player.alliance
	eventItemSlot(handle, InspectItemList("si"))

	guilds = _G.ImhoBags_ItemStorage[Shard.name].guilds
	-- Catch cases where a character is removed from a guild while offline
	guildChanged(handle, player.info.guild, Player.guild)
	hookGuildEvents()
end

Command.Event.Attach(Event.Addon.SavedVariables.Load.End, eventAddonSavedVariablesLoadEnd, "Item.Storage.eventAddonSavedVariablesLoadEnd")
Command.Event.Attach(Event.Currency, eventCurrency, "Item.Storage.eventCurrency")
Command.Event.Attach(Event.Interaction, eventInteraction, "Item.Storage.eventInteraction")
Command.Event.Attach(Event.Item.Slot, eventItemSlot, "Item.Storage.eventItemSlot")
Command.Event.Attach(Event.Item.Update, eventItemUpdate, "Item.Storage.eventItemUpdate")
Command.Event.Attach(Event.ImhoBags.Private.Init, init, "Item.Storage.init")
Command.Event.Attach(Event.ImhoBags.Private.Guild, guildChanged, "Item.Storage.guildChanged")

-- Public methods
-- ============================================================================

function Item.Storage.FindGuild(name)
	if(characters[name]) then
		return characters[name].info.guild
	else
		return guilds[name]
	end
end

function Item.Storage.GetCharacterAlliances()
	local chars = { }
	for name, data in pairs(characters) do
		chars[name] = data.info.alliance
	end
	return chars
end

function Item.Storage.GetCharacterCoins()
	local chars = { }
	for name, data in pairs(characters) do
		chars[name] = data.currency.totals.coin or 0
	end
	return chars
end

function Item.Storage.GetCharacterItems(character, location)
	local char = characters[character]
	if(char) then
		local loc = char[location]
		if(loc) then
			return loc.totals, (loc.slots or loc.categories), loc.counts, loc.bags
		end
	end
	return { }, { }, { }, { }
end

function Item.Storage.GetEmptySlots(character, location)
	local char = characters[character]
	if(char) then
		local loc = char[location]
		if(loc) then
			local n = 0
			for k, v in pairs(loc.slots or loc.categories) do
				if(v == false) then
					n = n + 1
				end
			end
			return n
		end
	end
	return 0
end

function Item.Storage.GetCharacterNames()
	local chars = { }
	for name in pairs(characters) do
		chars[#chars + 1] = name
	end
	return chars
end

function Item.Storage.GetGuildCoins()
	local coins = { }
	for name, data in pairs(guilds) do
		coins[name] = data.info.coin or 0
	end
	return coins
end

function Item.Storage.GetGuildItems(guild, vault)
	guild = guilds[guild]
	if(type(vault) == "number" and vault > 0) then
		vault = UtilityItemSlotGuild(vault)
	end
	if(guild) then
		vault = guild.vault[vault]
		if(vault) then
			return vault.totals, vault.slots, vault.counts
		end
	end
	return { }, { }, { }
end

function Item.Storage.GetGuildNames()
	local names = { }
	for name in pairs(guilds) do
		names[#names + 1] = name
	end
	return names
end

function Item.Storage.GetGuildVaults(name)
	local vaults = { }
	if(guilds[name]) then
		for slot, data in pairs(guilds[name].vault) do
			vaults[slot] = data.name
		end
	end
	return vaults
end

function Item.Storage.GetGuildVaultAccess(name)
	local vaults = { }
	if(guilds[name]) then
		for slot, data in pairs(guilds[name].vault) do
			vaults[slot] = { access = data.access, withdrawLimit = data.withdrawLimit }
		end
	end
	return vaults
end

function Item.Storage.GetAllItemTypes()
	local types = { }
	
	local function merge(location)
		for type, count in pairs(location.totals) do
			types[type] = (types[type] or 0) + count
		end
	end
	
	for char, data in pairs(characters) do
		merge(data.bank)
		merge(data.currency)
		merge(data.equipment)
		merge(data.inventory)
		merge(data.quest)
		merge(data.wardrobe)
	end
	
	for guild, data in pairs(guilds) do
		for id, vault in pairs(data.vault) do
			merge(vault)
		end
	end
	types.coin = nil
	return types
end

function Item.Storage.GetCharacterItemCounts(type)
	local counts = { }
	for char, data in pairs(characters) do
		counts[char] = {
			bank		= data.bank.totals[type] or 0,
			currency	= data.currency.totals[type] or 0,
			equipment	= data.equipment.totals[type] or 0,
			inventory	= data.inventory.totals[type] or 0,
			quest		= data.quest.totals[type] or 0,
			wardrobe	= data.wardrobe.totals[type] or 0,
		}
	end
	return counts
end

function Item.Storage.GetGuildItemCounts(type)
	local counts = { }
	local function merge(counts, vault)
		local count = vault.totals[type] or 0
		if(count > 0) then
			counts[#counts + 1] = vault.name
			counts[#counts + 1] = count
		end
	end

	for guild, data in pairs(guilds) do
		counts[guild] = { }
		for id, vault in pairs(data.vault) do
			merge(counts[guild], vault)
		end
	end
	return counts
end
