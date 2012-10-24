local Addon, private = ...

-- Builtins
local format = string.format
local pairs = pairs
local pcall = pcall
local setmetatable = setmetatable

-- Globals
local InspectCurrencyCategoryDetail = Inspect.Currency.Category.Detail
local InspectCurrencyDetail = Inspect.Currency.Detail
local InspectItemDetail = Inspect.Item.Detail
local UtilityItemSlotParse = Utility.Item.Slot.Parse

-- Locals

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

local function inspectItemDetailTwink(type, slot, count, unknown)
	local ok, detail = pcall(InspectItemDetail, type)
	if(not (ok and detail)) then
		detail = makeUnknownItemDetail(type)
		unknown[slot] = type
	end
	detail.slot = slot
	detail.stack = count
	return detail
end

local function loadStoredCurrency(self, character)
	local unknown = { }
	local totals, categories = Item.Storage.GetCharacterItems(character, self.location)
	totals.coin = nil -- Don't show coin here
	local slot = 1
	for type, count in pairs(totals) do
		local detail = inspectItemDetailTwink(type, slot, count, unknown)
		self.Slots[slot] = type
		self.Items[type] = detail
		self.Groups[type] = InspectCurrencyCategoryDetail(categories[type]).name
		slot = slot + 1
	end
	return unknown
end

local function loadStoredItems(self, location, character)
	local unknown = { }
	local totals, slots, counts, bags = Item.Storage.GetCharacterItems(character, location)
	local id = 1
	for slot, type in pairs(slots or { }) do
		if(type) then
			local detail = inspectItemDetailTwink(type, slot, counts[slot], unknown)
			self.Slots[slot] = id
			self.Items[id] = detail
			local container, bag, index = UtilityItemSlotParse(slot)
			self.Groups[id] = container == "wardrobe" and format(L.CategoryName.wardrobe, bag) or self.groupFunc(detail)
			id = id + 1
		else
			self.Slots[slot] = false
			self.Empty[slot] = true
			self.Items[slot] = makeEmptyItemDetail(slot)
		end
	end
	for slot, type in pairs(bags or { }) do
		local container, bag, index = UtilityItemSlotParse(slot)
		if(type) then
			local detail = inspectItemDetailTwink(type, slot, 1, unknown)
			self.Bags[index] = id
			self.Items[id] = detail
			id = id + 1
		else
			self.Bags[index] = false
		end
	end
	return unknown
end

-- Public methods
-- ============================================================================

function ResolveUnknownItems(self, unknownTypes, callback)
	local unknown = { }
	for slot, type in pairs(unknownTypes) do
		local id = self.Slots[slot]
		local ok, detail = pcall(InspectItemDetail, type)
		if(ok and detail) then
			detail.stack = self.Items[id].stack
			detail.slot = slot
			self.Items[id] = detail
			if(self.location ~= "currency") then
				local container, bag, index = UtilityItemSlotParse(slot)
				self.Groups[id] = container == "wardrobe" and format(L.CategoryName.wardrobe, bag) or self.groupFunc(detail)
			end
			callback(id)
		else
			unknown[slot] = type
		end
	end
	return unknown
end

function UpdateCurrency(self, currencies, callback)
	for id, count in pairs(currencies) do
		-- Don't show money here
		if(id ~= "coin" and count > 0) then
			local detail = InspectItemDetail(id)
			detail.stack = count
			detail.type = id
			self.Items[id] = detail
			self.Groups[id] = InspectCurrencyCategoryDetail(InspectCurrencyDetail(id).category).name
			callback(id)
		end
	end
end

function UpdateItem(self, slot, item, container, bag, index)
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

function UpdateSlot(self, slot, item, container, bag, index)
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
		self.Slots[slot] = item
		self.Empty[slot] = nil
		self.Items[slot] = nil
		local detail = InspectItemDetail(item)
		detail.slot = slot -- Add custom field for slot-sorting
		self.Items[item] = detail
		self.Groups[item] = container == "wardrobe" and format(L.CategoryName.wardrobe, bag) or self.groupFunc(detail)
	else
		local old = self.Slots[slot]
		if(old) then
			self.Items[old] = nil
			self.Groups[old] = nil
		end
		removeItem(self, slot, item)
	end
end

function ItemContainer.ItemSet(location, character)
	local self = {
		Bags = {
			-- [index] = id|false
		},
		Slots = {
			-- [slot] = id|false
		},
		Items = setmetatable({
			-- [id] = detail
			-- [slot] = detail
		}, { __mode = " " }),
		Empty = {
			-- [slot] = true
		},
		Groups = setmetatable({
			-- [id] = group
		}, { __mode = " " }),
		
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
		else
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
