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
	label:SetEffectGlow({
		colorR = 0,
		colorG = 0,
		colorB = 0,
		colorA = 1,
		blurX = 4,
		blurY = 4,
		strength = 5,
	})
	label:SetPoint("CENTER", window, "CENTER")
	
	local resizeFrame = UI.CreateFrame("Frame", "", Ux.Context)
	resizeFrame:SetAllPoints(UI.Native.Bag)
	resizeFrame:SetVisible(false)
	window:EventAttach(Event.UI.Layout.Size, function(self)
		Ux.EmptySlotIndicator.label:SetFontSize(math.ceil(0.6 * self:GetHeight()))
	end, "")
	
	window:SetPoint("TOPLEFT", UI.Native.Bag, 15 / 275, 12 / 85)
	window:SetPoint("BOTTOMRIGHT", UI.Native.Bag, 37 / 275, 35 / 85)
	
	UI.Native.Bag:EventAttach(Event.UI.Native.Loaded, showOrHideEmptySlotIndicator, "")
end

local function configChanged(handle, name, value)
	if(name == "showEmptySlots") then
		showOrHideEmptySlotIndicator()
	end
end

local function eventItemSlot()
	local empty = Item.Storage.GetEmptySlots(Player.name, "inventory")
	Ux.EmptySlotIndicator.label:SetText(tostring(empty))
end

Command.Event.Attach(Event.ImhoBags.Private.StorageLoaded, eventItemSlot, "Ux.EmptySlotIndicator.storageLoaded")
Command.Event.Attach(Event.ImhoBags.Private.Init, showOrHideEmptySlotIndicator, "Ux.EmptySlotIndicator.init")
Command.Event.Attach(Event.ImhoBags.Private.Config, configChanged, "Ux.EmptySlotIndicator.configChanged")
Command.Event.Attach(Event.Item.Slot, eventItemSlot, "Ux.EmptySlotIndicator.eventItemSlot")

-- Public methods
-- ============================================================================

createEmptySlotIndicator()
