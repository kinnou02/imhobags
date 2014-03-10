local Addon, private = ...

-- Upvalue
local format = string.format
local InspectCurrencyCategoryDetail = Inspect.Currency.Category.Detail
local InspectCurrencyDetail = Inspect.Currency.Detail
local InspectItemDetail = Inspect.Item.Detail
local pairs = pairs
local pcall = pcall
local UtilityItemSlotParse = Utility.Item.Slot.Parse

setfenv(1, private)
ItemContainer = ItemContainer or { }
ItemContainer.ItemSet = { }

-- Private methods
-- ============================================================================

local function makeEmptyItemDetail(slot)
	return {
		-- Pick a name/icon that is sorted last
		name = "\255",
		icon = "\255",
		rarity = "empty",
		slot = slot,
	}
end

local function makeUnknownItemDetail(type)
	return {
		name = "?",
		icon = "placeholder_icon.dds",
		type = type,
	}
end

local function removeItem(self, slot, item)
	if(item == "nil") then
		self.Slots[slot] = nil
		self.Empty[slot] = nil
		self.Items[slot] = nil
	else
		self.Slots[slot] = false
		self.Empty[slot] = true
		self.Items[slot] = makeEmptyItemDetail(slot)
	end
end

local function inspectItemDetailTwink(id, type, slot, count, unknown)
	local ok, detail = pcall(InspectItemDetail, type)
	if(not (ok and detail)) then
		detail = makeUnknownItemDetail(type)
		unknown[slot] = id
	end
	detail.slot = slot
	detail.stack = count
	return detail
end

local function loadStoredCurrency(self, character)
	local unknown = { }
	local totals, categories = Item.Storage.GetCharacterItems(character, self.location)
	totals.coin = nil -- Don't show coin and credits here
	totals.credit = nil
	local slot = 1
	for type, count in pairs(totals) do
		local detail = inspectItemDetailTwink(type, type, slot, count, unknown)
		self.Slots[slot] = type
		self.Items[type] = detail
		self.Groups[type] = InspectCurrencyCategoryDetail(categories[type]).name
		slot = slot + 1
	end
	return unknown
end

local function populateWithStoredItems(self, totals, slots, counts, bags)
	local secure = Inspect.System.Secure()
	local unknown = { }
	local id = 1
	if (self.itemsCounter) then
		id = self.itemsCounter
	end
	if not secure then
		Command.System.Watchdog.Quiet()
	end
	for slot, type in pairs(slots or { }) do
		if(type) then
			local detail = inspectItemDetailTwink(id, type, slot, counts[slot], unknown)
			self.Slots[slot] = id
			self.Items[id] = detail
			local container, bag, index = UtilityItemSlotParse(slot)
			if container == "vault" then container = "bank" end
			self.Groups[id] = container ~= "wardrobe" and self.groupFunc(detail) or format(L.CategoryName.wardrobe, bag)
			id = id + 1
			self.itemsCounter = id
		else
			self.Slots[slot] = false
			self.Empty[slot] = true
			self.Items[slot] = makeEmptyItemDetail(slot)
		end
	end
	for slot, type in pairs(bags or { }) do
		local container, bag, index = UtilityItemSlotParse(slot)
		if(type) then
			local detail = inspectItemDetailTwink(id, type, slot, 1, unknown)
			self.Bags[index] = id
			self.Items[id] = detail
			id = id + 1
			self.itemsCounter = id
		else
			self.Bags[index] = false
		end
	end
	return unknown
end

local function loadStoredItems(self, location, character)
	return populateWithStoredItems(self, Item.Storage.GetCharacterItems(character, location))
end

local function loadStoredGuild(self, guild, vault)
	return populateWithStoredItems(self, Item.Storage.GetGuildItems(guild, vault))
end

-- Public methods
-- ============================================================================

local function ResolveUnknownItems(self, unknownTypes, callback)
	local unknown = { }
	for slot, id in pairs(unknownTypes) do
		local type = self.Items[id].type
		local ok, detail = pcall(InspectItemDetail, type)
		if(ok and detail) then
			detail.stack = self.Items[id].stack
			detail.slot = slot
			self.Items[id] = detail
			if(self.location ~= "currency") then
				local container, bag, index = UtilityItemSlotParse(slot)
				if container == "vault" then container = "bank" end
				self.Groups[id] = container ~= "wardrobe" and self.groupFunc(detail) or format(L.CategoryName.wardrobe, bag)
			end
			callback(id)
		else
			unknown[slot] = id
		end
	end
	return unknown
end

local function UpdateCurrency(self, currencies, callback)
	for id, count in pairs(currencies) do
		-- Don't show money and credits here
		if(id ~= "coin" and id ~= "credit" and count > 0) then
			local detail = InspectItemDetail(id)
			detail.stack = count
			detail.type = id
			self.Items[id] = detail
			local groupName = "Unknown"
			local currencyDetail = InspectCurrencyDetail(id) 
			local category = currencyDetail and currencyDetail.category
			if category then
				local categoryDetail = InspectCurrencyCategoryDetail(category)
				if (categoryDetail) then
					groupName = categoryDetail.name
				end
			end
			self.Groups[id] = groupName
			callback(id)
		end
	end
end

local function UpdateItem(self, slot, item, container, bag, index)
	if(bag == "bag") then
		return
	end
	
	if(item and item ~= "nil") then
		local detail = InspectItemDetail(item)
		detail.slot = slot -- Add custom field for slot-sorting
		self.Items[item] = detail
	else
		removeItem(self, slot, item)
	end
end

local function UpdateSlot(self, slot, item, container, bag, index)
	if(bag == "bag") then
		self.Bags[index] = item
		if(item) then
			self.Items[item] = InspectItemDetail(item)
		end
	elseif(item and item ~= "nil") then
		-- Remove the item which was in this slot before
		local old = self.Slots[slot]
		if(old) then
			self.Items[old] = nil
			self.Groups[old] = nil
		end
		-- Remove the item from its previous slot if present
		old = self.Items[item]
		if(old and old.slot) then
			removeItem(self, old.slot, "nil") -- "nil" prevents unnecessary makeEmptyItemDetail call
		end
		local detail = InspectItemDetail(item)
		if(detail) then
			self.Slots[slot] = item
			self.Empty[slot] = nil
			self.Items[slot] = nil
			detail.slot = slot -- Add custom field for slot-sorting
			self.Items[item] = detail
			self.Groups[item] = container == "wardrobe" and format(L.CategoryName.wardrobe, bag) or self.groupFunc(detail)
		end
	else
		local old = self.Slots[slot]
		if(old) then
			self.Items[old] = nil
			self.Groups[old] = nil
		end
		removeItem(self, slot, item)
	end
end

function ItemContainer.ItemSet(location, character, vault)
	local self = {
		Bags = {
			-- [index] = id|false
		},
		Slots = {
			-- [slot] = id|false
		},
		Items = {
			-- [id] = detail
			-- [slot] = detail
		},
		Empty = {
			-- [slot] = true
		},
		Groups = {
			-- [id] = group
		},
		
		ResolveUnknownItems = ResolveUnknownItems,
		UpdateCurrency = UpdateCurrency,
		UpdateItem = UpdateItem,
		UpdateSlot = UpdateSlot,
		
		groupFunc = Group.Default.GetLocalizedShortCategoryWithJunkAndLootable,
		location = location,
	}
	local unknown = { }
	if(character) then
		if(location == "currency") then
			unknown = loadStoredCurrency(self, character)
		elseif(location == "guildbank") then
			self.itemsCounter = 1
			unknown = loadStoredGuild(self, character, vault)
		else
			self.itemsCounter = 1
			unknown = loadStoredItems(self, location, character)
			if(location == "equipment") then
				local unknown2 = loadStoredItems(self, "wardrobe", character)
				for k, v in pairs(unknown2) do
					unknown[k] = v
				end
			end
		end
	end
	return self, unknown
end
