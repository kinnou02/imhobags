local _G = _G

local UI = UI

setfenv(1, ImhoBags)
Ux = Ux or { }

Context = UI.CreateContext(AddonName)

BackpackWindow = CreateItemWindow("Rucksack")
BackpackWindow:SetPoint("CENTER", _G.UIParent, "CENTER", 0, 0)

local button = UI.CreateFrame("RiftButton", "", BackpackWindow)
button:SetText("Test")
button:SetPoint("BOTTOMCENTER", BackpackWindow, "BOTTOMCENTER", 0, -5)
function button.Event:LeftClick()
	local items = ItemDB:GetItems("player", "bank", true, function(a, b) return a.name < b.name end)
	BackpackWindow:UpdateItems(items)
end
