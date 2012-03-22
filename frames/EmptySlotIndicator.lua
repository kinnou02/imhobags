local Addon, private = ...

local tostring = tostring

-- Globals
local Event = Event
local InspectTimeReal = Inspect.Time.Real
local UI = UI

setfenv(1, private)
Ux = Ux or { }

-- Private methods
-- ============================================================================

local function systemUpdateBegin(self)
	-- Inspect.Time.Frame() is not good enough and can cause multiple updates per frame
	local now = InspectTimeReal()
	if(self.matrix.lastUpdate >= self.lastUpdate) then
		local items, empty, success = self.matrix:GetUnsortedItems(false)
		self.label:SetText(tostring(#empty))
		self.lastUpdate = now
	end
end

local function adjustPosition()
	local normalWidth = 275 -- Width of UI.Native.Bag at 100% scale
	local actualWidth = UI.Native.Bag:GetWidth()
	local factor = actualWidth / normalWidth
	
	Ux.EmptySlotIndicator:SetWidth(29 * factor)
	Ux.EmptySlotIndicator:SetHeight(29 * factor)
	Ux.EmptySlotIndicator.label:SetFontSize(18 * factor)
	Ux.EmptySlotIndicator:SetPoint("CENTER", UI.Native.Bag, "TOPLEFT", 71 * factor, 28 * factor)
end

-- Create a little window over the native bags frame showing the number of empty bags
local function createFrame()
	local window = UI.CreateFrame("Frame", "ImhoBags_EmptySlotIndicator", Ux.Context)
	Ux.EmptySlotIndicator = window
	
	local label = UI.CreateFrame("Text", "", window)
	window.label = label
	label:SetPoint("CENTER", window, "CENTER")
	
	window:SetBackgroundColor(0, 0, 0, 0.5)
	
	window.matrix = ItemDB.GetItemMatrix("player", "inventory")
	window.character = character
	window.location = location
	window.lastUpdate = -2
	
	Event.System.Update.Begin[#Event.System.Update.Begin + 1] = { function() systemUpdateBegin(window) end, Addon.identifier, "systemUpdateBegin" }

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
		Ux.EmptySlotIndicator:SetVisible(UI.Native.Bag:GetLoaded() and Config.showEmptySlots)
	end
end

-- Creation of the frame must be postponed until after saved variables are loaded
ImhoEvent.Init[#ImhoEvent.Init + 1] = { createFrame, Addon.identifier, "Ux.EmptySlotIndicator_createFrame" }
ImhoEvent.Config[#ImhoEvent.Config + 1] = { configChanged, Addon.identifier, "Ux.EmptySlotIndicator_configChanged" }

-- Public methods
-- ============================================================================
