local Addon, private = ...

-- Builtins
local ceil = math.ceil
local floor = math.floor
local format = string.format
local min = math.min
local next = next
local pairs = pairs
local pcall = pcall
local setmetatable = setmetatable
local sort = table.sort
local tostring = tostring
local type = type

-- Globals
local Command = Command
local Event = Event
local Inspect = Inspect
local InspectCurrencyCategoryDetail = Inspect.Currency.Category.Detail
local InspectCurrencyDetail = Inspect.Currency.Detail
local InspectItemDetail = Inspect.Item.Detail
local UICreateFrame = UI.CreateFrame

-- Locals
local labelFontSize = 14
local labelHeight = 20

setfenv(1, private)
ItemContainer = ItemContainer or { }
ItemContainer.Display = { }

-- Private methods
-- ============================================================================

local function inspectDetailTwink(self, slot, type, stack, fn, solver)
	local ok, item = pcall(fn, type)
	if(not (ok and item)) then
		self.pendingItemDetails[slot] = solver
		return {
			name = "?",
			icon = "placeholder_icon.dds",
			type = type,
			stack = stack,
			slot = slot,
		}
	else
		item.stack = stack
		item.slot = slot
		return item
	end
end

local function inspectItemDetailTwink(self, slot, type, stack)
	local solver
	solver = function()
		local id = self.set.slots[slot] or self.set.bags[slot]
		local detail = inspectDetailTwink(self, slot, type, stack, InspectItemDetail, solver)
		self.set.items[id] = detail
		self.set.groups[id] = self.groupFunc(detail)
		self.layouter:UpdateItem(id)
	end
	return inspectDetailTwink(self, slot, type, stack, InspectItemDetail, solver)
end

local function inspectCurrencyDetailTwink(self, slot, type, stack)
	local solver
	solver = function()
		local id = self.set.slots[slot] or self.set.bags[slot]
		local detail = inspectDetailTwink(self, slot, type, stack, InspectItemDetail, solver)
		self.set.items[id] = detail
		self.layouter:UpdateItem(id)
	end
	return inspectDetailTwink(self, slot, type, stack, InspectItemDetail, solver)
end

local function getGroupLabelMinWidth(self)
	return self.text:GetWidth()
end

local function setupGroupLabel(self, display, group, items)
	if(display.layouter.layout == "default") then
		self.text:SetText(group)
	elseif(display.layouter.layout == "bags") then
		if(group == 0) then
			self.text:SetText(L.Ux.WindowTitle.bank)
		else
			local info = display.set.items[display.set.bags[group]]
			self.text:SetText(info.name)
		end
	end
end

local function groupLabelFactory(parent)
	local self = UICreateFrame("Texture", "", parent)
	self:SetTexture("Rift", "QuestBarUp.png.dds")
	self.text = UICreateFrame("Text", "", self)
	self.text:SetFontSize(labelFontSize)
	self.text:SetPoint("CENTER", self, "CENTER")
	self:SetHeight(labelHeight)
	self.GetMinWidth = getGroupLabelMinWidth
	self.Setup = setupGroupLabel
	return self
end

local function updateButton(self, id)
	if(self.set == self.playerSet) then
		self.layouter:UpdateItem(id)
	end
end

local function makeEmptyItemDetail(slot)
	return {
		-- Pick a name/icon that is sorted last
		name = "\255",
		icon = "\255",
		rarity = "empty",
		slot = slot,
	}
end

local function removeItem(self, set, slot, item)
	if(item == "nil") then
		set.slots[slot] = nil
		set.empty[slot] = nil
		set.items[slot] = nil
	else
		set.slots[slot] = false
		set.empty[slot] = true
		set.items[slot] = makeEmptyItemDetail(slot)
	end
end

local function eventItemSlot(self, slot, item, container, bag, index)
	local set = self.playerSet
	
--	log("eventItemSlot", slot, item, container, bag, index)
	if(bag == "bag") then
		set.bags[index] = item
		if(item) then
			set.items[item] = InspectItemDetail(item)
		end
	elseif(item and item ~= "nil") then
		-- Remove the item from its old slot if present
		local old = set.items[item]
		if(old and old.slot) then
			removeItem(self, set, old.slot, "nil") -- "nil" prevents unnecessary makeEmptyItemDetail call
		end
		set.slots[slot] = item
		set.empty[slot] = nil
		set.items[slot] = nil
		local detail = InspectItemDetail(item)
		detail.slot = slot -- Add custom field for slot-sorting
		set.items[item] = detail
		set.groups[item] = self.groupFunc(detail)
	else
		local old = set.slots[slot]
		if(old) then
			set.items[old] = nil
			set.groups[old] = nil
		end
		removeItem(self, set, slot, item)
	end

	if(set == self.set) then
		self.needsUpdate = true
		self.itemsChanged = true
	end
end

local function eventItemUpdate(self, slot, item, container, bag, index)
	local set = self.playerSet
	
	if(bag == "bag") then
		return
	end
	
	if(item and item ~= "nil") then
		local detail = InspectItemDetail(item)
		detail.slot = slot -- Add custom field for slot-sorting
		set.items[item] = detail
		updateButton(self, item)
	else
		removeItem(self, set, slot, item)
	end
end

local function eventCurrency(self, currencies)
	local set = self.playerSet
	
	for id, count in pairs(currencies) do
		-- Don't show money here
		if(id ~= "coin" and count > 0) then
			local detail = InspectItemDetail(id)
			detail.type = id
			set.items[id] = detail
			set.groups[id] = InspectCurrencyCategoryDetail(InspectCurrencyDetail(id).category).name
		end
	end
	if(set == self.set) then
		self.needsUpdate = true
	end
end

local function queryPendingItemDetail(self)
	local pendingItemDetails = self.pendingItemDetails
	self.pendingItemDetails = { }
	
	local set = self.set
	for slot, fn in pairs(pendingItemDetails) do
		fn()
	end
end

local function systemUpdateBegin(self)
	if(self.needsUpdate) then
		self.needsUpdate = false
		self.needsLayout = false
		local height = self.layouter:UpdateItems()
		
		self:SetHeight(height)
		self:changeCallback({ height = height })
	elseif(self.needsLayout) then
		self.needsLayout = false
		local height = self.layouter:UpdateLayout()
		self:SetHeight(height)
		self:changeCallback({ height = height })
	end
	local now = Inspect.Time.Frame()
	if(now >= self.nextItemDetailQuery and (next(self.pendingItemDetails))) then
		self.nextItemDetailQuery = now + Const.ItemDisplayQueryInterval
		queryPendingItemDetail(self)
		self.needsUpdate = true
	end
	if(self.itemsChanged) then
		self.itemsChanged = false
		self:changeCallback({ empty = self:GetNumEmptySlots() })
	end
end

local function checkConfig(location, config)
	if(location == "currency") then
		config.layout = "default"
		if(config.sort == "slot") then
			config.sort = "name"
		end
	end
	return config
end

local function eventInteraction(self, interaction, state)
	if(interaction == self.location) then
		self.layouter:SetAvailable(state)
		self.available = state
	end
end

-- Public methods
-- ============================================================================

local function GetNumEmptySlots(self)
	local empty = 0
	for k, v in pairs(self.set.empty) do
		empty = empty + 1
	end
	return empty
end

local function SetItemSize(self, size)
	self.layouter:SetItemSize(size)
	self.needsLayout = true
end

local function SetShowEmptySlots(self, showEmpty)
	self.layouter:SetShowEmptySlots(showEmpty)
	self.needsUpdate = true
end

local function SetCharacter_item(self, character)
	self.pendingItemDetails = { }
	if(character == "player" or character == Player.name) then
		self.set = self.playerSet
		local interaction = Inspect.Interaction()
		if(interaction[self.location] ~= nil) then
			eventInteraction(self, self.location, interaction[self.location])
		else
			self.layouter:SetAvailable(true)
		end
	else
		self.layouter:SetAvailable(false)
		local set = {
			bags = { },
			slots = { },
			items = { },
			groups = { },
			empty = { },
		}
		self.set = set
		local totals, slots, counts, bags = Item.Storage.GetCharacterItems(character, self.location)
		local id = 1
		for slot, type in pairs(slots or { }) do
			if(type) then
				local detail = inspectItemDetailTwink(self, slot, type, counts[slot])
				set.slots[slot] = id
				set.items[id] = detail
				set.groups[id] = self.groupFunc(detail)
				id = id + 1
			else
				set.slots[slot] = false
				set.empty[slot] = true
				set.items[slot] = makeEmptyItemDetail(slot)
			end
		end
		for slot, type in pairs(bags or { }) do
			if(type) then
				local detail = inspectItemDetailTwink(self, slot, type, counts[slot])
				set.bags[slot] = id
				set.items[id] = detail
				id = id + 1
			else
				set.bags[slot] = false
			end
		end
	end
	
	self.layouter:SetItemSet(self.set)
	self.needsUpdate = true
	self.itemsChanged = true
end

local function SetCharacter_currency(self, character)
	self.pendingItemDetails = { }
	if(character == "player" or character == Player.name) then
		self.set = self.playerSet
		local interaction = Inspect.Interaction()
		if(interaction[self.location] ~= nil) then
			eventInteraction(self, self.location, interaction[self.location])
		else
			self.layouter:SetAvailable(true)
		end
	else
		self.layouter:SetAvailable(false)
		local set = {
			bags = { },
			slots = { },
			items = { },
			groups = { },
			empty = { },
		}
		self.set = set
		local totals, categories = Item.Storage.GetCharacterItems(character, self.location)
		totals.coin = nil -- Don't show coin here
		local slot = 1
		for type, count in pairs(totals) do
			local detail = inspectCurrencyDetailTwink(self, slot, type, count)
			set.slots[slot] = type
			set.items[type] = detail
			set.groups[type] = InspectCurrencyCategoryDetail(categories[type]).name
			slot = slot + 1
		end
	end
	
	self.layouter:SetItemSet(self.set)
	self.needsUpdate = true
	self.itemsChanged = true
end

local function SetSearchFilter(self, filter)
	self.layouter:SetSearchFilter(filter)
end

local function SetLayout(self, layout)
	if(self.location ~= "currency") then
		self.layouter:SetLayout(layout)
		self.needsUpdate = true
	end
end

local function SetNeedsLayout(self)
	self.needsUpdate = true
end

local function SetSortMethod(self, sort)
	if(self.location ~= "currency" or sort ~= "slot") then
		self.layouter:SetSortMethod(sort)
		self.needsUpdate = true
	end
end

local function DropCursorItem(self)
	if(self.set == self.playerSet and self.available) then
		local slot = next(self.set.empty)
		if(slot) then
			ItemHandler.Standard.Drop(slot)
			return
		end
	end
	Command.Cursor(nil)
end

function ItemContainer.Display(parent, location, config, changeCallback)
	local self = UICreateFrame("Frame", "ItemContainer." .. location, parent)
	
	config = checkConfig(location, config)
	self.playerSet = {
		bags = {
			-- [index] = id/false
		},
		slots = {
			-- [slot] = id/false
		},
		items = setmetatable({
			-- [id] = detail
			-- [slot] = detail
		}, { __mode = " " }),
		empty = {
			-- [slot] = true
		},
		new = {
			-- [id] = true
		},
		groups = setmetatable({
			-- [id] = group
		}, { __mode = " " }),
	}
	self.pendingItemDetails = {
		-- [slot] = type
	}
	self.available = true
	self.set = self.playerSet
	self.needsUpdate = false
	self.needsLayout = false
	self.itemsChanged = false
	self.changeCallback = changeCallback
	self.location = location
	self.nextItemDetailQuery = 0
	
	self.DropCursorItem = DropCursorItem
	self.GetItemSize = function(self) return self.layouter.itemSize end
	self.GetLayout = function(self) return self.layouter.layout end
	self.GetNumEmptySlots = GetNumEmptySlots
	self.GetSortMethod = function(self) return self.layouter.sort end
	self.SetCharacter = location == "currency" and SetCharacter_currency or SetCharacter_item
	self.SetItemSize = SetItemSize
	self.SetLayout = SetLayout
	self.SetNeedsLayout = SetNeedsLayout
	self.SetSearchFilter = SetSearchFilter
	self.SetShowEmptySlots = SetShowEmptySlots
	self.SetSortMethod = SetSortMethod
	
	self.groupFunc = Group.Default.GetLocalizedShortCategoryWithJunkAndLootable
	
	self.layouter = ItemContainer.Layouter(self, config, groupLabelFactory)
	self.layouter:SetItemSet(self.playerSet)
	
	local interaction = Inspect.Interaction()
	if(interaction[location] ~= nil) then
		Event.Interaction[#Event.Interaction + 1] = { function(...) eventInteraction(self, ...) end, Addon.identifier, "eventInteraction" }
		eventInteraction(self, location, interaction[location])
	end
	
	if(location == "currency") then
		Event.Currency[#Event.Currency + 1] = { function(...) eventCurrency(self, ...) end, Addon.identifier, "ItemContainer.currency.eventCurrency" }
		eventCurrency(self, Inspect.Currency.List())
	else
		Item.Dispatcher.AddSlotCallback(location, function(...) eventItemSlot(self, ...) end)
		Item.Dispatcher.AddUpdateCallback(location, function(...) eventItemUpdate(self, ...) end)
	end
	Event.System.Update.Begin[#Event.System.Update.Begin + 1] = { function() systemUpdateBegin(self) end, Addon.identifier, "ItemContainer." .. location .. ".systemUpdateBegin" }
	
	return self
end
