local Addon, private = ...

-- Builtins
local _G = _G
local pairs = pairs

-- Globals
local Event = Event
local InspectCurrencyDetail = Inspect.Currency.Detail
local InspectItemDetail = Inspect.Item.Detail
local UtilityItemSlotParse = Utility.Item.Slot.Parse

-- Locals
local data
local player

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
			-- [*] = newLocation()
		},
	}
end

local function eventAddonSavedVariablesLoadEnd(identifier)
	if(identifier ~= Addon.identifier) then
		return
	end
	
	data = _G.ImhoBags_ItemStorageCharacters or { }
	player = data[Player.name] or newCharacter()
	data[Player.name] = player
	
	Trigger.StorageLoaded()
end

local function eventAddonSavedVariablesSaveBegin(identifier)
	if(identifier ~= Addon.identifier) then
		return
	end
	
	_G.ImhoBags_ItemStorageCharacters = data
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

local function mergeSlot(container, slot, item, bag, index)
	if(item and item ~= "nil") then
		item = InspectItemDetail(item)
	end
	if(bag == "bag") then
		removeFromTotals(container, container.bags[index], 1)
		if(item) then
			container.bags[index] = item.type
			container.totals[item.type] = (container.totals[item.type] or 0) + 1
		else
			container.bags[index] = false
		end
	elseif(item and item ~= "nil") then
		removeFromTotals(container, container.slots[slot], container.counts[slot] or 0)

		container.slots[slot] = item.type
		container.counts[slot] = item.stack or 1
		container.totals[item.type] = (container.totals[item.type] or 0) + (item.stack or 1)
	else
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

local function eventItemSlot(items)
	for slot, item in pairs(items) do
		local container, bag, index = UtilityItemSlotParse(slot)
		if(player[container]) then
			mergeSlot(player[container], slot, item, bag, index)
		else
			-- TODO: handle guild
		end
	end
end

local function eventItemUpdate(items)
	for slot, item in pairs(items) do
		local container, bag, index = UtilityItemSlotParse(slot)
		item = InspectItemDetail(item)
		if(player[container]) then
			container = player[container]
			container.totals[item.type] = container.totals[item.type] - container.counts[slot] + (item.stack or 1)
			container.counts[slot] = item.stack or 1
		else
			-- TODO: handle guild
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

local function init()
	player.info.guild = Player.guild
	player.info.alliance = Player.alliance
end

-- Public methods
-- ============================================================================

function Item.Storage.GetCharacterAlliances()
	local chars = { }
	for name, data in pairs(data) do
		chars[name] = data.info.alliance
	end
	return chars
end

function Item.Storage.GetCharacterCoins()
	local chars = { }
	for name, data in pairs(data) do
		chars[name] = data.currency.totals.coin or 0
	end
	return chars
end

function Item.Storage.GetCharacterNames()
	local chars = { }
	for name in pairs(data) do
		chars[#chars + 1] = name
	end
	return chars
end

function Item.Storage.GetCharacterItems(character, location)
	local char = data[character]
	if(char) then
		local loc = char[location]
		if(loc) then
			return loc.totals, (loc.slots or loc.categories), loc.counts, loc.bags
		end
	end
	return { }, { }, { }, { }
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
Event.Item.Slot[#Event.Item.Slot + 1] = {
	eventItemSlot,
	Addon.identifier,
	"Item.Storage.eventItemSlot"
}
Event.Item.Slot[#Event.Item.Slot + 1] = {
	eventItemSlot,
	Addon.identifier,
	"Item.Storage.eventItemSlot"
}
Event.Currency[#Event.Currency + 1] = {
	eventCurrency,
	Addon.identifier,
	"Item.Storage.eventCurrency"
}
Event.ImhoBags.Private.Init[#Event.ImhoBags.Private.Init + 1] = {
	init,
	Addon.identifier,
	"Item.Storage.init"
}
