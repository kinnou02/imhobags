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

local function storageLoaded()
	_G.ImhoBags_WindowInfo = _G.ImhoBags_WindowInfo or {
		ItemContainer = { }
	}
	
	for k, v in pairs(itemWindows) do
		Ux.ItemWindow[v[1]] = Ux.ItemWindowTemplate.WindowFrame(v[1], _G.ImhoBags_WindowInfo.ItemContainer[v[1]] or { }, v[2])
	end
	
	if(_G.ImhoBags_WindowInfo.SearchWindow) then
		Ux.SearchWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", _G.ImhoBags_WindowInfo.SearchWindow.x or 0, _G.ImhoBags_WindowInfo.SearchWindow.y or 0)
	end
end

local function savedVariablesSaveBegin(identifier)
	if(identifier ~= Addon.identifier) then
		return
	end
	
	_G.ImhoBags_WindowInfo.version = 0.14
	_G.ImhoBags_WindowInfo.SearchWindow = {
		x = Ux.SearchWindow:GetLeft(),
		y = Ux.SearchWindow:GetTop(),
	}
	if(type(Ux.ConfigWindow) ~= "function") then
		_G.ImhoBags_WindowInfo.ConfigWindow = {
			x = Ux.ConfigWindow:GetLeft(),
			y = Ux.ConfigWindow:GetTop(),
		}
	end

	for k, v in pairs(itemWindows) do
		local window = Ux.ItemWindow[v[1]]
		_G.ImhoBags_WindowInfo.ItemContainer[v[1]] = window:FillConfig({ })
	end
end

local function toggleFade(self)
	if(not self:GetVisible()) then
		self:FadeIn()
	elseif(self:FadingOut()) then
		self:FadeIn()
	else
		self:FadeOut()
	end
end

Event.Addon.SavedVariables.Save.Begin[#Event.Addon.SavedVariables.Save.Begin + 1] = { savedVariablesSaveBegin, Addon.identifier, "savedVariablesSaveBegin" }
Event.ImhoBags.Private.StorageLoaded[#Event.ImhoBags.Private.StorageLoaded + 1] = { storageLoaded, Addon.identifier, "storageLoaded" }

-- Public methods
-- ============================================================================

function Ux.ToggleItemWindow(character, location)
	local window = Ux.ItemWindow[location]
	if(window) then
		toggleFade(window)
		if(window:FadingIn()) then
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
		window:FadeIn()
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
		window:FadeOut()
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
		Ux.ConfigWindow:SetVisible(false)
		Ux.ConfigWindow:FadeIn()
	else
		toggleFade(Ux.ConfigWindow)
	end
end

function Ux.ToggleMenuWindow()
	if(type(Ux.MenuWindow) == "function") then
		Ux.MenuWindow()
		Ux.MenuWindow:SetVisible(false)
		Ux.MenuWindow:FadeIn()
	else
		toggleFade(Ux.MenuWindow)
	end
end
