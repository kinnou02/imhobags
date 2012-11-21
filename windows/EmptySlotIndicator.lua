local Addon, private = ...

-- Builtins
local ceil = math.ceil
local tostring = tostring

-- Globals
local Event = Event
local InspectTimeReal = Inspect.Time.Real
local UI = UI

setfenv(1, private)
Ux = Ux or { }

-- Private methods
-- ============================================================================

local function adjustPosition()
	local normalWidth = 275 -- Width of UI.Native.Bag at 100% scale
	local actualWidth = UI.Native.Bag:GetWidth()
	local factor = actualWidth / normalWidth
	
	Ux.EmptySlotIndicator:SetWidth(ceil(29 * factor))
	Ux.EmptySlotIndicator:SetHeight(ceil(29 * factor))
	Ux.EmptySlotIndicator.label:SetFontSize(ceil(18 * factor))
	Ux.EmptySlotIndicator:SetPoint("CENTER", UI.Native.Bag, "TOPLEFT", ceil(71 * factor), ceil(28 * factor))
end

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
	adjustPosition()
	function resizeFrame.Event:Size()
		adjustPosition()
	end
	
	function UI.Native.Bag.Event:Loaded()
		window:SetVisible(self:GetLoaded() and Config.showEmptySlots)
	end
	window:SetVisible(UI.Native.Bag:GetLoaded() and Config.showEmptySlots)
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
