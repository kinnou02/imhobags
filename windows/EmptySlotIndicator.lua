local Addon, private = ...

setfenv(1, private)
Ux = Ux or { }

-- Private methods
-- ============================================================================

local function showOrHideEmptySlotIndicator()
	log(UI.Native.Bag:GetLoaded(), Config.showEmptySlots)
	Ux.EmptySlotIndicator:SetVisible(UI.Native.Bag:GetLoaded() and Config.showEmptySlots)
end

-- Create a little window over the native bags frame showing the number of empty bags
local function createEmptySlotIndicator()
	local window = UI.CreateFrame("Frame", "ImhoBags_EmptySlotIndicator", Ux.Context)
	Ux.EmptySlotIndicator = window
	
	local label = UI.CreateFrame("Text", "", window)
	window.label = label
	label:SetPoint("CENTER", window, "CENTER")
	
	window:SetBackgroundColor(0, 0, 0, 0.5)
	local resizeFrame = UI.CreateFrame("Frame", "", Ux.Context)
	resizeFrame:SetAllPoints(UI.Native.Bag)
	resizeFrame:SetVisible(false)
	function window.Event:Size()
		Ux.EmptySlotIndicator.label:SetFontSize(math.ceil(0.6 * window:GetHeight()))
	end
	
	window:SetPoint("TOPLEFT", UI.Native.Bag, 57 / 275, 14 / 85)
	window:SetPoint("BOTTOMRIGHT", UI.Native.Bag, 85 / 275, 42 / 85)
	
	UI.Native.Bag.Event.Loaded = showOrHideEmptySlotIndicator
end

local function configChanged(name, value)
	if(name == "showEmptySlots") then
		showOrHideEmptySlotIndicator()
	end
end

local function eventItemSlot()
	local empty = Item.Storage.GetEmptySlots(Player.name, "inventory")
	Ux.EmptySlotIndicator.label:SetText(tostring(empty))
end

Event.ImhoBags.Private.StorageLoaded[#Event.ImhoBags.Private.StorageLoaded + 1] = {
	eventItemSlot,
	Addon.identifier,
	"Ux.EmptySlotIndicator_storageLoaded"
}
Event.ImhoBags.Private.Init[#Event.ImhoBags.Private.Init + 1] = {
	showOrHideEmptySlotIndicator,
	Addon.identifier,
	"Ux.EmptySlotIndicator_init"
}
Event.ImhoBags.Private.Config[#Event.ImhoBags.Private.Config + 1] = {
	configChanged,
	Addon.identifier,
	"Ux.EmptySlotIndicator_configChanged"
}
Event.Item.Slot[#Event.Item.Slot + 1] = {
	eventItemSlot,
	Addon.identifier,
	"Ux.EmptySlotIndicator_eventItemSlot",
}

-- Public methods
-- ============================================================================

createEmptySlotIndicator()
