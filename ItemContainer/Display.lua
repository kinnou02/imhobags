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
local InspectGuildBankList = Inspect.Guild.Bank.List
local InspectItemDetail = Inspect.Item.Detail
local UICreateFrame = UI.CreateFrame
local UtilityItemSlotGuild = Utility.Item.Slot.Guild
local UtilityItemSlotParse = Utility.Item.Slot.Parse

-- Locals
local labelFontSize = 14
local labelHeight = 20

setfenv(1, private)
ItemContainer = ItemContainer or { }
ItemContainer.Display = { }

-- Private methods
-- ============================================================================

local function getGroupLabelMinWidth(self)
	return self.text:GetWidth()
end

local function showsPlayerSet(self, set)
	set = set or self.set
	if(set == self.playerSet) then
		return true
	else
		for k, v in pairs(self.playerSet) do
			if(v == set) then
				return true
			end
		end
	end
	return false
end

local function setupGroupLabel(self, display, group, items)
	if(display.layouter.layout == "default") then
		self.text:SetText(group)
	elseif(display.layouter.layout == "bags") then
		if(group == 0) then
			self.text:SetText(L.Ux.WindowTitle[display.location])
		else
			local info = display.set.Items[display.set.Bags[group]]
			self.text:SetText(info and info.name or "?")
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
	if(showsPlayerSet(self)) then
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

local function eventItemSlot(self, slot, item, container, bag, index)
	self.playerSet:UpdateSlot(slot, item, container, bag, index)
	
	if(showsPlayerSet(self)) then
		self.needsUpdate = true
		self.itemsChanged = true
	end
end

local function eventItemUpdate(self, slot, item, container, bag, index)
	self.playerSet:UpdateItem(slot, item, container, bag, index)
	
	if(item and item ~= "nil") then
		updateButton(self, item)
	end
end

local function eventItemSlotGuild(self, slot, item, container, bag, index)
	local set = self.playerSet[bag]
	if(not set) then
		set = ItemContainer.ItemSet("guildbank")
		self.playerSet[bag] = set
	end
	set:UpdateSlot(slot, item, container, bag, index)
	
	if(set == self.set) then
		self.needsUpdate = true
		self.itemsChanged = true
	end
end

local function eventItemUpdateGuild(self, slot, item, container, bag, index)
	local set = self.playerSet[bag]
	if(not set) then
		set = ItemContainer.ItemSet("guildbank")
		self.playerSet[bag] = set
	end
	set:UpdateItem(slot, item, container, bag, index)
	
	if(item and item ~= "nil") then
		updateButton(self, item)
	end
end

local function eventCurrency(self, currencies)
	if(showsPlayerSet(self)) then
		self.playerSet:UpdateCurrency(currencies, function(id) updateButton(self, id) end)
		self.needsUpdate = true
		self.itemsChanged = true
	else
		self.playerSet:UpdateCurrency(currencies, function() end)
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
	if(now >= self.nextItemDetailQuery and (next(self.unknownItemDetails))) then
		self.nextItemDetailQuery = now + Const.ItemDisplayQueryInterval
		self.unknownItemDetails = self.set:ResolveUnknownItems(self.unknownItemDetails, function(id) updateButton(self, id) end)
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
	elseif(location == "quest") then
		config.layout = "onebag"
	elseif(location == "equipment") then
		config.layout = "default"
	elseif(location == "guildbank") then
		if(config.layout == "bags") then
			config.layout = "default"
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

local function eventGuildBankChange(self, vaults)
	for slot in pairs(vaults) do
		local container, bag = UtilityItemSlotParse(slot)
		self.playerSet[bag] = self.playerSet[bag] or ItemContainer.ItemSet("guildbank")
	end
end

-- Public methods
-- ============================================================================

local function GetNumEmptySlots(self)
	local empty = 0
	for k, v in pairs(self.set.Empty) do
		empty = empty + 1
	end
	return empty
end

local function SetItemSize(self, size)
	self.layouter:SetItemSize(size)
	self.needsLayout = true
end

local function FillConfig(self, config)
	return self.layouter:FillConfig(config)
end

local function SetShowEmptySlots(self, showEmpty)
	self.layouter:SetShowEmptySlots(showEmpty)
	self.needsUpdate = true
end

local function SetCharacter(self, character)
	if(character == "player" or character == Player.name) then
		self.set = self.playerSet
		local interaction = Inspect.Interaction()
		if(interaction[self.location] ~= nil) then
			eventInteraction(self, self.location, interaction[self.location])
		else
			self.layouter:SetAvailable(true)
		end
		self.unknownItemDetails = { }
	else
		self.layouter:SetAvailable(false)
		self.set, self.unknownItemDetails = ItemContainer.ItemSet(self.location, character)
	end
	
	self.layouter:SetItemSet(self.set)
	self.needsUpdate = true
	self.itemsChanged = true
end

local function SetGuild(self, guild, vault)
	if(guild == Player.guild) then
		if(Inspect.Interaction("guildbank")) then
			self.set = self.playerSet[vault or 1] or ItemContainer.ItemSet("guildbank")
		else
			self.set = ItemContainer.ItemSet("guildbank", guild or "", vault or 1)
		end
	else
		self.set = ItemContainer.ItemSet("guildbank", guild or "", vault or 1)
	end
	self.layouter:SetItemSet(self.set)
	self.needsUpdate = true
	self.itemsChanged = true
end

local function SetSearchFilter(self, filter)
	self.layouter:SetSearchFilter(filter)
end

local function SetLayout(self, layout)
	if(self.location ~= "currency" and self.location ~= "equipment") then
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
	if(showsPlayerSet(self) and self.available) then
		local slot = next(self.playerSet.Empty)
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
	if(location == "guildbank") then
		self.playerSet = { ItemContainer.ItemSet("guildbank") }
		self.set = self.playerSet[1]
	else
		self.playerSet =  ItemContainer.ItemSet(location)
		self.set = self.playerSet
	end
	self.unknownItemDetails = {
		-- [slot] = type
	}
	self.available = true
	self.needsUpdate = false
	self.needsLayout = false
	self.itemsChanged = false
	self.changeCallback = changeCallback
	self.location = location
	self.nextItemDetailQuery = 0
	
	self.DropCursorItem = DropCursorItem
	self.FillConfig = FillConfig
	self.GetNumEmptySlots = GetNumEmptySlots
	self.SetCharacter = SetCharacter
	self.SetGuild = SetGuild
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
	elseif(location == "guildbank") then
		Item.Dispatcher.AddSlotCallback("guild", function(...) eventItemSlotGuild(self, ...) end)
		Item.Dispatcher.AddUpdateCallback("guild", function(...) eventItemUpdateGuild(self, ...) end)
		Event.Guild.Bank.Change[#Event.Guild.Bank.Change + 1] = { function(...) eventGuildBankChange(self, ...) end, Addon.identifier, "eventGuildBankChange" }
	else
		Item.Dispatcher.AddSlotCallback(location, function(...) eventItemSlot(self, ...) end)
		Item.Dispatcher.AddUpdateCallback(location, function(...) eventItemUpdate(self, ...) end)
		if(location == "equipment") then
			Item.Dispatcher.AddSlotCallback("wardrobe", function(...) eventItemSlot(self, ...) end)
			Item.Dispatcher.AddUpdateCallback("wardrobe", function(...) eventItemUpdate(self, ...) end)
		end
	end
	Event.System.Update.Begin[#Event.System.Update.Begin + 1] = { function() systemUpdateBegin(self) end, Addon.identifier, "ItemContainer." .. location .. ".systemUpdateBegin" }
	
	return self
end
