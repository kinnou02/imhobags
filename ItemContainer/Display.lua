local Addon, private = ...

-- Upvalue
local pairs = pairs
local UtilityItemSlotParse = Utility.Item.Slot.Parse
local format = string.format

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
		elseif(display.location == "guildbank") then							
			self.text:SetText(format(L.Ux.guildVault,group))										-- This solution works because there are (currently) no "bags" in the guildbank
		elseif(group > Const.MaxBankBags) then																-- There are Const.MaxBankBags bags in the bank.  Therefore, bank vaults are Const.MaxBankBags+vault#
			self.text:SetText(format(L.Ux.bankVault,group-Const.MaxBankBags))
		else
			local info = display.set.Items[display.set.Bags[group]]
			self.text:SetText(info and info.name or "?")
		end
	end
end

local function groupLabelFactory(parent)
	local self = UI.CreateFrame("Texture", "", parent)
	self:SetTexture("Rift", "QuestBarUp.png.dds")
	self.text = UI.CreateFrame("Text", "", self)
	self.text:SetFontSize(labelFontSize)
	self.text:SetPoint("CENTER", self, "CENTER")
	self:SetHeight(labelHeight)
	self.GetMinWidth = getGroupLabelMinWidth
	self.Setup = setupGroupLabel
	return self
end

local function updateButton(self, id)
	self.layouter:UpdateItem(id)
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
	
	if(showsPlayerSet(self) and item and item ~= "nil") then
		updateButton(self, item)
	end
end

local function eventItemSlotGuild(self, slot, item, container, bag, index)
	if(item == "nil") then
		return
	end
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
	
	if(showsPlayerSet(self) and item and item ~= "nil") then
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
	local now = Inspect.Time.Frame()
	if(self.needsUpdate) then
		if (Config.updateItemsTimerInterval == 0) then		-- ignore new code and work as before
			self.needsUpdate = false
			self.needsLayout = false
			local height = self.layouter:UpdateItems()
			self.updateItemsTimer = now + Config.updateItemsTimerInterval
			self:SetHeight(height)
			self:changeCallback({ height = height })
		elseif (now < (self.updateItemsTimer + Config.updateItemsTimerInterval)) then
			self.needsUpdate = false
			self.needsLayout = false
			self.updateItemsTimer = now
			self.forceUpdateItems = true
		else
			self.updateItemsTimer = now
			self.needsUpdate = false
			self.needsLayout = false
			local height = self.layouter:UpdateItems()
			self.updateItemsTimer = now + Config.updateItemsTimerInterval
			self:SetHeight(height)
			self:changeCallback({ height = height })
		end
	elseif self.forceUpdateItems then
		if (now >= (self.updateItemsTimer + Config.updateItemsTimerInterval)) then
			local height = self.layouter:UpdateItems()
			self.updateItemsTimer = now + Config.updateItemsTimerInterval
			self:SetHeight(height)
			self:changeCallback({ height = height })
			self.forceUpdateItems = false
		end
	elseif(self.needsLayout) then
		self.needsLayout = false
		local height = self.layouter:UpdateLayout()
		self:SetHeight(height)
		self:changeCallback({ height = height })
	end
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
		log("eventGuildBankChange", slot, container, bag)
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
	log(Player.guild, guild, vault)
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
		if self.playerSet.Empty then
			local slot = next(self.playerSet.Empty)
			if(slot) then
				ItemHandler.Standard.Drop(slot)
				return
			end
		end
	end
	Command.Cursor(nil)
end

function ItemContainer.Display(parent, location, config, changeCallback)
	local self = UI.CreateFrame("Frame", "ItemContainer." .. location, parent)
	
	config = checkConfig(location, config)
	if(location == "guildbank") then
		self.playerSet = { (ItemContainer.ItemSet("guildbank")) }
		self.set = self.playerSet[1]
	else
		self.playerSet = ItemContainer.ItemSet(location)
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
	self.updateItemsTimer = 0
	self.forceUpdateItems = false
	
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
	self.layouter:SetItemSet(self.set)
	
	local interaction = Inspect.Interaction()
	if(interaction[location] ~= nil) then
		Command.Event.Attach(Event.Interaction, function(handle, ...) eventInteraction(self, ...) end, "eventInteraction")
		eventInteraction(self, location, interaction[location])
	end
	
	if(location == "currency") then
		Command.Event.Attach(Event.Currency, function(handle, ...) eventCurrency(self, ...) end, "ItemContainer.currency.eventCurrency")
		eventCurrency(self, Inspect.Currency.List())
	elseif(location == "guildbank") then
		Item.Dispatcher.AddSlotCallback("guild", function(...) eventItemSlotGuild(self, ...) end)
		Item.Dispatcher.AddUpdateCallback("guild", function(...) eventItemUpdateGuild(self, ...) end)
		Command.Event.Attach(Event.Guild.Bank.Change, function(handle, ...) eventGuildBankChange(self, ...) end, "eventGuildBankChange")
	else
		Item.Dispatcher.AddSlotCallback(location, function(...) eventItemSlot(self, ...) end)
		Item.Dispatcher.AddUpdateCallback(location, function(...) eventItemUpdate(self, ...) end)
		if(location == "equipment") then
			Item.Dispatcher.AddSlotCallback("wardrobe", function(...) eventItemSlot(self, ...) end)
			Item.Dispatcher.AddUpdateCallback("wardrobe", function(...) eventItemUpdate(self, ...) end)
		end
	end
	Command.Event.Attach(Event.System.Update.Begin, function() systemUpdateBegin(self) end, "ItemContainer[" .. location .. "].systemUpdateBegin")
	
	return self
end
