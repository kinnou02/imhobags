local identifier = (...).id
local addon = (...).data

local _G = _G

local UI = UI

setfenv(1, addon)
Ux = Ux or { }

Ux.Context = UI.CreateContext(identifier)

local window = CreateItemWindow("Rucksack")
window:SetPoint("CENTER", _G.UIParent, "CENTER", 0, 0)
Ux.BackpackWindow = window

local button = UI.CreateFrame("RiftButton", "", Ux.BackpackWindow)
button:SetText("Test")
button:SetPoint("BOTTOMCENTER", Ux.BackpackWindow, "BOTTOMCENTER", 0, -5)
function button.Event:LeftClick()
	local matrix = ItemDB.GetItemMatrix("player", "bank")
	Ux.BackpackWindow:SetItemMatrix(matrix)
end
