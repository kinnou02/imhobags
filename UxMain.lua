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

local function centerWindow(window)
	local screenWidth = UIParent:GetWidth()
	local screenHeight = UIParent:GetHeight()
	window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (screenWidth - window:GetWidth()) / 2, (screenHeight - window:GetHeight()) / 2)
end

local unitAvailableIndex
local function unitAvailable(units)
	for k, v in pairs(units) do
		if(v == "player") then
			-- Create the ordinary item windows.
			-- Their creation must be delayed until after Inspect.Unit.Detail("player") is available.
			for k, v in pairs(defaultItemWindows) do
				local info = _G.ImhoBagsWindowInfo[k] or { }
				if(info.condensed == nil) then
					info.condensed = true
				end
				
				local title = L.Ux.WindowTitle[v[1]]
				local window = Ux.ItemWindow.New(title, "player", v[1], info.condensed, v[2])

				if(info and info.x and info.y) then
					window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", info.x, info.y)
					window:SetWidth(info.width)
				else
					centerWindow(window)
				end
				Ux[k] = window
			end
			
			Event.Unit.Available[unitAvailableIndex][1] = function() end
			break
		end
	end
	
	local info = _G.ImhoBagsWindowInfo.SearchWindow
	if(info) then
		Ux.SearchWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", info.x, info.y)
	else
		centerWindow(Ux.SearchWindow)
	end
end

local function Ux_savedVariablesLoadEnd(addonIdentifier)
	if(addonIdentifier ~= Addon.identifier) then
		return
	end
	_G.ImhoBagsWindowInfo = _G.ImhoBagsWindowInfo or { }
end

local function Ux_savedVariablesSaveBegin(addonIdentifier)
	if(addonIdentifier ~= Addon.identifier) then
		return
	end
	for k, v in pairs(defaultItemWindows) do
		local window = Ux[k]
		_G.ImhoBagsWindowInfo[k] = {
			x = window:GetLeft(),
			y = window:GetTop(),
			width = window:GetWidth(),
			condensed = window.condensed,
		}
	end
	_G.ImhoBagsWindowInfo.SearchWindow = {
		x = Ux.SearchWindow:GetLeft(),
		y = Ux.SearchWindow:GetTop(),
	}
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
