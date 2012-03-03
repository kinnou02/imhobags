local Addon, private = ...

local _G = _G
local pairs = pairs
local table = table

local UIParent = UIParent

local Event = Event
local UI = UI

local defaultItemWindows =  {
	BackpackItemWindow = { "inventory", UI.Native.BagInventory1 },
	BankItemWindow = { "bank", UI.Native.Bank },
}

setfenv(1, private)
Ux = Ux or { }

Ux.Context = UI.CreateContext(Addon.identifier)

--Private methods
-- ============================================================================

local function Ux_addonStartupEnd()
	for k, v in pairs(defaultItemWindows) do
		local title = L.WindowTitles[v[1]]
		local window = Ux.ItemWindow.New(title,"player", v[1], true, v[2])

		local position = _G.ImhoBagsWindowPositions[k]
		if(position) then
			window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", position.x, position.y)
			window:SetWidth(position.width)
		else
			local width, height = UIParent:GetWidth(), UIParent:GetHeight()
			window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (width - window:GetWidth()) / 2, (height - window:GetHeight()) / 2)
		end
		Ux[k] = window
	end
end

local function Ux_savedVariablesLoadEnd(addonIdentifier)
	if(addonIdentifier ~= Addon.identifier) then
		return
	end
	_G.ImhoBagsWindowPositions = _G.ImhoBagsWindowPositions or { }
end

local function Ux_savedVariablesSaveBegin(addonIdentifier)
	if(addonIdentifier ~= Addon.identifier) then
		return
	end
	for k, v in pairs(defaultItemWindows) do
		_G.ImhoBagsWindowPositions[k] = { x = Ux[k]:GetLeft(), y = Ux[k]:GetTop(), width = Ux[k]:GetWidth() }
	end
end

table.insert(Event.Addon.Startup.End, { Ux_addonStartupEnd, Addon.identifier, "Ux_addonStartupEnd" })
table.insert(Event.Addon.SavedVariables.Load.End, { Ux_savedVariablesLoadEnd, Addon.identifier, "Ux_savedVariablesLoadEnd" })
table.insert(Event.Addon.SavedVariables.Save.Begin, { Ux_savedVariablesSaveBegin, Addon.identifier, "Ux_savedVariablesSaveBegin" })
