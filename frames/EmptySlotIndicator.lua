local Addon, private = ...

local _G = _G
local print = print
local table = table
local tostring = tostring
local type = type

local dump = dump

local Command = Command
local Event = Event
local Inspect = Inspect
local UI = UI

setfenv(1, private)
Ux = Ux or { }

-- Private methods
-- ============================================================================

local function systemUpdateBegin(self)
	-- Inspect.Time.Frame() is not good enough and can cause multiple updates per frame
	local now = Inspect.Time.Real()
	if(self.matrix.lastUpdate >= self.lastUpdate) then
		local items, empty, success = self.matrix:GetUnsortedItems(false)
		self:SetText(tostring(#empty))
		self.lastUpdate = now
	end
end

-- Create a little window over the native bags frame showing the number of empty bags
local function createFrame()
	local window = UI.CreateFrame("Text", "ImhoBags_EmptySlotIndicator", Ux.Context)
	Ux.EmptySlotIndicator = window
	
	window:SetFontSize(18)
	window:SetBackgroundColor(0, 0, 0, 0.5)
	
	window.matrix = ItemDB.GetItemMatrix("player", "inventory")
	window.character = character
	window.location = location
	window.lastUpdate = -2
	
	window:SetPoint("CENTER", UI.Native.Bag, "TOPLEFT", 71, 29)
	
	table.insert(Event.System.Update.Begin, { function() systemUpdateBegin(window) end, Addon.identifier, "systemUpdateBegin" })
end

-- Creation of the frame must be postponed until after saved variables are loaded
table.insert(ImhoEvent.Init, { createFrame, Addon.identifier, "Ux.EmptySlotIndicator createFrame" })

-- Public methods
-- ============================================================================
