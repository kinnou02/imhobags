﻿local Addon, private = ...

-- Builtins
local _G = _G
local floor = math.floor
local pairs = pairs
local type = type

-- Globals
local Event = Event
local UICreateContext = UI.CreateContext
local UIParent = UIParent

local defaultItemWindows =  {
	BackpackItemWindow = { "inventory", UI.Native.BagInventory1, "ItemWindow" },
	BankItemWindow = { "bank", UI.Native.Bank, "ItemWindow" },
	CurrencyItemWindow = { "currency", nil, "CurrencyWindow" },
	EquipmentItemWindow = { "equipment", nil, "EquipmentWindow" },
	GuildItemWindow = { "guildbank", nil, "GuildWindow" },
	MailItemWindow = { "mail", nil, "MailWindow" },
	WardrobeItemWindow = { "wardrobe", nil, "EquipmentWindow" },
}

setfenv(1, private)
Ux = Ux or { }

Ux.Context = UICreateContext(Addon.identifier)
Ux.TooltipContext = UICreateContext(Addon.identifier)
Ux.TooltipContext:SetStrata("topmost")

-- Private methods
-- ============================================================================

local function centerWindow(window)
	local screenWidth = UIParent:GetWidth()
	local screenHeight = UIParent:GetHeight()
	window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", floor((screenWidth - window:GetWidth()) / 2), floor((screenHeight - window:GetHeight()) / 2))
end

local function createItemWindow(name, character)
	local data = defaultItemWindows[name]
	local info = _G.ImhoBags_WindowInfo[name] or { }
	
	local title = L.Ux.WindowTitle[data[1]]
	local window = Ux[data[3]].New(title, character, data[1])

	if(info and info.x and info.y) then
		window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", floor(info.x), floor(info.y))
		window:SetWidth(info.width)
	else
		centerWindow(window)
	end
	Ux[name] = window
	return window
end

local function init()
	-- Hook the native opening events
	for k, v in pairs(defaultItemWindows) do
		local native = v[2]
		if(native) then
			-- This will not work if other addons try to do the same
			function native.Event:Loaded()
				if(Config.autoOpen) then
					if(self:GetLoaded()) then
						Ux.ShowItemWindow("player", v[1])
					else
						Ux.HideItemWindow("player", v[1])
					end
					log("TODO", "disable native frame(s)")
				end
			end
		end
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
		if(window) then
			_G.ImhoBags_WindowInfo[k] = {
				x = window:GetLeft(),
				y = window:GetTop(),
				width = window:GetWidth(),
				condensed = window.condensed,
			}
		end
	end
	_G.ImhoBags_WindowInfo.SearchWindow = {
		x = Ux.SearchWindow:GetLeft(),
		y = Ux.SearchWindow:GetTop(),
	}
	if(type(Ux.ConfigWindow) ~= "function") then
		log("save")
		_G.ImhoBags_WindowInfo.ConfigWindow = {
			x = Ux.ConfigWindow:GetLeft(),
			y = Ux.ConfigWindow:GetTop(),
		}
	end
end

_G.table.insert(Event.Addon.SavedVariables.Load.End, { Ux_savedVariablesLoadEnd, Addon.identifier, "Ux_savedVariablesLoadEnd" })
_G.table.insert(Event.Addon.SavedVariables.Save.Begin, { Ux_savedVariablesSaveBegin, Addon.identifier, "Ux_savedVariablesSaveBegin" })

_G.table.insert(ImhoEvent.Init, { init, Addon.identifier, "UxMain_init" })

-- Public methods
-- ============================================================================

function Ux.ToggleItemWindow(character, location)
	for k, v in pairs(defaultItemWindows) do
		if(v[1] == location) then
			local window = Ux[k]
			if(not window) then
				Ux.ShowItemWindow(character, location)
			else
				if(window:GetVisible() and window.character == character) then
					Ux.HideItemWindow(character, location)
				else
					Ux.ShowItemWindow(character, location)
				end
			end
			break
		end
	end
end

function Ux.ToggleGuildWindow(character)
	for k, v in pairs(defaultItemWindows) do
		if(v[1] == "guildbank") then
			local window = Ux[k]
			if(not window) then
				Ux.ShowItemWindow(ItemDB.FindGuild(character) or "<none>", "guildbank")
			else
				if(window:GetVisible() and window.character == character) then
					Ux.HideItemWindow("guildbank")
				else
					Ux.ShowItemWindow(ItemDB.FindGuild(character) or "<none>", "guildbank")
				end
			end
			break
		end
	end
end

function Ux.ShowItemWindow(character, location)
	for k, v in pairs(defaultItemWindows) do
		if(v[1] == location) then
			local window = Ux[k]
			if(not window) then
				window = createItemWindow(k, character)
			else
				window:SetCharacter(character, location)
			end
			window:SetVisible(true)
			break
		end
	end
end

function Ux.HideItemWindow(location)
	for k, v in pairs(defaultItemWindows) do
		if(v[1] == location) then
			local window = Ux[k]
			if(window) then
				window:SetVisible(false)
			end
			break
		end
	end
end

function Ux.ToggleConfigWindow()
	if(type(Ux.ConfigWindow) == "function") then
		Ux.ConfigWindow()
		-- Load the config window's position
		local info = _G.ImhoBags_WindowInfo.ConfigWindow
		if(info) then
			Ux.ConfigWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", info.x, info.y)
		else
			centerWindow(Ux.ConfigWindow)
		end
	else
		Ux.ConfigWindow:SetVisible(not Ux.ConfigWindow:GetVisible())
	end
end