local Addon, private = ...

-- Builtins
local ceil = math.ceil
local floor = math.floor
local format = string.format
local min = math.min
local pairs = pairs
local sort = table.sort
local tostring = tostring
local type = type

-- Globals
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

local function inspectItemDetailTwink(self, slot, item)
	local detail = InspectItemDetail(item.type)
	if(not detail) then
		self.pendingItemDetail[slot] = item
		return {
			name = "?",
			icon = "placeholder_icon.dds",
			type = item.type,
			stack = item.stack,
		}
	else
		detail.stack = item.stack
		return detail
	end
end

local function getGroupLabelMinWidth(self)
	return self.text:GetWidth()
end

local function setupGroupLabel(self, display, group, items)
	if(display.layouter.layout == "default") then
		self.text:SetText(group)
	elseif(display.layouter.layout == "bags") then
		local info = display.set.items[display.set.bags[group]]
		self.text:SetText(format("%s - %i/%i", info.name, #items, info.slots))
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

local function removeItem(self, set, slot, item)
	local id = set.slots[slot]
	if(id) then
		set.new[id] = nil
		set.items[id] = nil
		set.groups[id] = nil
	end
	if(item == "nil") then
		set.slots[slot] = nil
	else
		set.slots[slot] = false
	end
end

local function eventItemSlot(self, slot, item, container, bag, index)
	local set = self.playerSet
	
--	log("eventItemSlot", slot, item, container, bag, index)
	if(bag == "bag") then
		local old = set.bags[index]
		if(old) then
			set.items[old] = nil
		end
		set.bags[index] = item
		set.items[item] = InspectItemDetail(item)
	elseif(item and item ~= "nil") then
		if(not set.items[item]) then
			set.new[item] = true
		end
		set.slots[slot] = item
		local detail = InspectItemDetail(item)
		detail.slot = slot -- Add custom field for slot-sorting
		set.items[item] = detail
		set.groups[item] = self.groupFunc(detail)
	else
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
		local details = InspectItemDetail(item)
		if((details.stack or 1) > (set.items[item].stack or 1)) then
			set.new[item] = true
		end
		set.items[item] = details
		updateButton(self, item)
	else
		removeItem(self, set, slot, item)
	end
end

local function eventCurrency(self, currencies)
	local set = self.playerSet
	
	for id, count in pairs(currencies) do
		-- Don't show money here
		if(id ~= "coin") then
			local detail = InspectCurrencyDetail(id)
			detail.type = id
			set.items[id] = detail
			set.groups[id] = InspectCurrencyCategoryDetail(detail.category).name
		end
	end
	if(set == self.set) then
		self.needsUpdate = true
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

-- Public methods
-- ============================================================================

local function GetNumEmptySlots(self)
	local empty = 0
	for k, v in pairs(self.set.slots) do
		empty = empty + (v == false and 1 or 0)
	end
	return empty
end

local function SetButtonSize(self, size)
	self.layouter:SetButtonSize(size)
	self.needsLayout = true
end

local function SetCharacter(self, character)
	if(character == "player" or character == Player.name) then
		self.set = self.playerSet
	else
		self.set = {
			bags = { },
			slots = { },
			items = { },
			groups = { },
		}
		
	end
	self.needsUpdate = true
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
		items = {
			-- [id] = detail
		},
		new = {
			-- [id] = true
		},
		groups = {
			-- [id] = group
		}
	}
	self.pendingItemDetail = {
		-- [slot] = item
	}
	self.set = self.playerSet
	self.needsUpdate = false
	self.needsLayout = false
	self.itemsChanged = false
	self.changeCallback = changeCallback
	self.location = location
	
	self.GetNumEmptySlots = GetNumEmptySlots
	self.SetButtonSize = SetButtonSize
	self.SetLayout = SetLayout
	self.SetNeedsLayout = SetNeedsLayout
	self.SetSearchFilter = SetSearchFilter
	self.SetSortMethod = SetSortMethod
	
	self.groupFunc = Group.Default.GetLocalizedShortCategoryWithJunkAndLootable
	self.itemDetailFunc = getItemDetailsPlayer
	
	self.layouter = ItemContainer.Layouter(self, config, groupLabelFactory)
	self.layouter:SetItemSet(self.playerSet)
	
	if(location == "currency") then
		Event.Currency[#Event.Currency + 1] = { function(...) log("x") eventCurrency(self, ...) end, Addon.identifier, "ItemContainer.currency.eventCurrency" }
		eventCurrency(self, Inspect.Currency.List())
	else
		Item.Dispatcher.AddSlotCallback(location, function(...) eventItemSlot(self, ...) end)
		Item.Dispatcher.AddUpdateCallback(location, function(...) eventItemUpdate(self, ...) end)
	end
	Event.System.Update.Begin[#Event.System.Update.Begin + 1] = { function() systemUpdateBegin(self) end, Addon.identifier, "ItemContainer." .. location .. ".systemUpdateBegin" }
	
	return self
end
