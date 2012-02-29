local identifier = (...).id
local addon = (...).data

local _G = _G
local pairs = pairs
local table = table

local Event = Event
local UI = UI

local defaultItemWindows =  {
--	BackpackItemWindow = { "inventory", UI.Native.BagInventory1 },
	BankItemWindow = { "bank", UI.Native.Bank },
}

setfenv(1, addon)
Ux = Ux or { }

Ux.Context = UI.CreateContext(identifier)

--Private methods
-- ============================================================================

local function Ux_addonStartupEnd()
	for k, v in pairs(defaultItemWindows) do
		local title = L.WindowTitles[v[1]]
		local window = Ux.ItemWindow.New(title,"player", v[1], true, v[2])
		-- TODO: Restore window position
--		window:SetPoint("TOPLEFT", _G.UIParent, "TOPLEFT", 0, 0)
		Ux[k] = window
	end
end
--[[
local window = Ux.ItemWindow.New("Rucksack","player", "bank", true)
window:SetPoint("CENTER", _G.UIParent, "CENTER", 0, 0)
Ux.BackpackWindow = window

local button = UI.CreateFrame("RiftButton", "", Ux.BackpackWindow)
button:SetText("Test")
button:SetPoint("BOTTOMCENTER", Ux.BackpackWindow, "BOTTOMCENTER", 0, -5)
function button.Event:LeftClick()
	Ux.BackpackWindow:SetCharacter("player", "bank")
end
]]
table.insert(Event.Addon.Startup.End, { Ux_addonStartupEnd, identifier, "Ux_addonStartupEnd" })