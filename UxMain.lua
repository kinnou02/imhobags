local Addon, private = ...

local _G = _G
local math = math
local pairs = pairs
local string = string
local table = table

local dump = dump
local UIParent = UIParent

local Command = Command
local Event = Event
local UI = UI

local defaultItemWindows =  {
	BackpackItemWindow = { "inventory", UI.Native.BagInventory1, "ItemWindow" },
	BankItemWindow = { "bank", UI.Native.Bank, "ItemWindow" },
	MailItemWindow = { "mail", nil, "MailWindow" },
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
	window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", math.floor((screenWidth - window:GetWidth()) / 2), math.floor((screenHeight - window:GetHeight()) / 2))
end

local function init()
	-- Create the ordinary item windows.
	-- Their creation must be delayed until after Inspect.Unit.Detail("player") is available.
	for k, v in pairs(defaultItemWindows) do
		local info = _G.ImhoBags_WindowInfo[k] or { }
		if(info.condensed == nil) then
			info.condensed = true
		end
		
		local title = L.Ux.WindowTitle[v[1]]
		local window = Ux[v[3]].New(title, "player", v[1], info.condensed, v[2])

		if(info and info.x and info.y) then
			window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", math.floor(info.x), math.floor(info.y))
			window:SetWidth(info.width)
		else
			centerWindow(window)
		end
		Ux[k] = window
	end

	-- Load the search window's position
	local info = _G.ImhoBags_WindowInfo.SearchWindow
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
	_G.ImhoBags_WindowInfo = _G.ImhoBags_WindowInfo or { }
end

local function Ux_savedVariablesSaveBegin(addonIdentifier)
	if(addonIdentifier ~= Addon.identifier) then
		return
	end
	for k, v in pairs(defaultItemWindows) do
		local window = Ux[k]
		_G.ImhoBags_WindowInfo[k] = {
			x = window:GetLeft(),
			y = window:GetTop(),
			width = window:GetWidth(),
			condensed = window.condensed,
		}
	end
	_G.ImhoBags_WindowInfo.SearchWindow = {
		x = Ux.SearchWindow:GetLeft(),
		y = Ux.SearchWindow:GetTop(),
	}
end

table.insert(Event.Addon.SavedVariables.Load.End, { Ux_savedVariablesLoadEnd, Addon.identifier, "Ux_savedVariablesLoadEnd" })
table.insert(Event.Addon.SavedVariables.Save.Begin, { Ux_savedVariablesSaveBegin, Addon.identifier, "Ux_savedVariablesSaveBegin" })

table.insert(ImhoEvent.Init, { init, Addon.identifier, "UxMain_init" })

-- Public methods
-- ============================================================================

function Ux.ToggleItemWindow(char, location)
	for k, v in pairs(defaultItemWindows) do
		if(v[1] == location) then
			local window = Ux[k]
			if(window:GetVisible()) then
				window:SetVisible(false)
			else
				window:SetCharacter(char, location)
				window:SetVisible(true)
			end
			break
		end
	end
end
