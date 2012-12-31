local Addon, private = ...

local itemWindows = {
	{ "bank", UI.Native.Bank },
	{ "currency", nil },
	{ "equipment", nil },
	{ "inventory", UI.Native.BagInventory1 },
	{ "guildbank", UI.Native.BankGuild},
	{ "quest", nil },
}

setfenv(1, private)
Ux = Ux or { }
Ux.ItemWindow = { }

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

local function Ux_savedVariablesSaveBegin(addonIdentifier)
	if(addonIdentifier ~= Addon.identifier) then
		return
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

local function storageLoaded()
	_G.ImhoBags_WindowInfo = _G.ImhoBags_WindowInfo or { }
	
	for k, v in pairs(itemWindows) do
		Ux.ItemWindow[v[1]] = Ux.ItemWindowTemplate.WindowFrame(v[1], _G.ImhoBags_WindowInfo[v[1]] or { }, v[2])
	end
end

local function savedVariablesSaveBegin(identifier)
	if(identifier ~= Addon.identifier) then
		return
	end

	for k, v in pairs(itemWindows) do
		local window = Ux.ItemWindow[v[1]]
		_G.ImhoBags_WindowInfo[v[1]] = window:FillConfig({ })
	end
end

Event.Addon.SavedVariables.Save.Begin[#Event.Addon.SavedVariables.Save.Begin + 1] = { savedVariablesSaveBegin, Addon.identifier, "savedVariablesSaveBegin" }
Event.ImhoBags.Private.StorageLoaded[#Event.ImhoBags.Private.StorageLoaded + 1] = { storageLoaded, Addon.identifier, "storageLoaded" }

-- Public methods
-- ============================================================================

function Ux.ToggleItemWindow(character, location)
	local window = Ux.ItemWindow[location]
	if(window) then
		window:SetVisible(not window:GetVisible())
		if(window:GetVisible()) then
			if(location == "guildbank") then
				window:SetGuild(Item.Storage.FindGuild(character))
			else
				window:SetCharacter(character)
			end
		end
	end
end

function Ux.ShowItemWindow(character, location)
	local window = Ux.ItemWindow[location]
	if(window) then
		window:SetVisible(true)
		if(location == "guildbank") then
			window:SetGuild(Item.Storage.FindGuild(character))
		else
			window:SetCharacter(character)
		end
	end
end

function Ux.HideItemWindow(location)
	local window = Ux.ItemWindow[location]
	if(window) then
		window:SetVisible(false)
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

function Ux.ToggleMenuWindow()
	if(type(Ux.MenuWindow) == "function") then
		Ux.MenuWindow()
	else
		Ux.MenuWindow:SetVisible(not Ux.MenuWindow:GetVisible())
	end
end
