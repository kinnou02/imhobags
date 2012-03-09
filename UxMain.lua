local Addon, private = ...

local _G = _G
local pairs = pairs
local string = string
local table = table

local dump = dump
local UIParent = UIParent

local Command = Command
local Event = Event
local UI = UI

local defaultItemWindows =  {
	BackpackItemWindow = { "inventory", UI.Native.BagInventory1 },
	BankItemWindow = { "bank", UI.Native.Bank },
}

setfenv(1, private)
Ux = Ux or { }

Ux.Context = UI.CreateContext(Addon.identifier)
Ux.TooltipContext = UI.CreateContext(Addon.identifier)
Ux.TooltipContext:SetStrata("topmost")

-- Private methods
-- ============================================================================

local unitAvailableIndex
local function unitAvailable(units)
	for k, v in pairs(units) do
		if(v == "player") then
			-- Create the ordinary item windows.
			-- Their creation must be delayed until after Inspect.Unit.Detail("player") is available
			for k, v in pairs(defaultItemWindows) do
				local title = L.WindowTitles[v[1]]
				local window = Ux.ItemWindow.New(string.upper(title), "player", v[1], true, v[2])

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
			
			Event.Unit.Available[unitAvailableIndex][1] = function() end
			break
		end
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

table.insert(Event.Addon.SavedVariables.Load.End, { Ux_savedVariablesLoadEnd, Addon.identifier, "Ux_savedVariablesLoadEnd" })
table.insert(Event.Addon.SavedVariables.Save.Begin, { Ux_savedVariablesSaveBegin, Addon.identifier, "Ux_savedVariablesSaveBegin" })
table.insert(Event.Unit.Available, { unitAvailable, Addon.identifier, "Ux_unitAvailable" })
unitAvailableIndex = #Event.Unit.Available

-- Public methods
-- ============================================================================

function Ux.ShowItemWindow(char, location)
	for k, v in pairs(defaultItemWindows) do
		if(v[1] == location) then
			local window = Ux[k]
			window:SetCharacter(char, location)
			window:SetVisible(true)
			break
		end
	end
end
