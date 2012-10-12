local Addon, private = ...

-- Builtins
local ipairs = ipairs
local max = math.max
local pairs = pairs
local tostring = tostring

-- Globals
local InspectMouse = Inspect.Mouse
local UICreateFrame = UI.CreateFrame

-- Locals
local filterBoxLeft = 24
local filterBoxWidth = 100
local rightPanelMinWidth = 40
local rightHiddenMinWidth = 20
local rightHiddenMaxWidth = 6 * 20

setfenv(1, private)
Ux.ItemWindowTemplate = Ux.ItemWindowTemplate or { }

-- Private methods
-- ============================================================================

local function hitTest(frame, x, y)
	local left, top, right, bottom = frame:GetBounds()
	return not frame:GetVisible() or x < left or x > right or y < top or y > bottom
end

local function createFadeAnimationLeft(self)
	local hotArea = UICreateFrame("Frame", "", self)
	hotArea:SetLayer(100)
	hotArea:SetAllPoints(self.leftPanel)
	hotArea:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 2)
	hotArea:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, -2)
	hotArea:SetPoint("RIGHT", self.rightPanel, "LEFT")
	hotArea:SetMouseMasking("limited")
	
	hotArea.extern = { }
	function self:HotArea(frame, hot)
		hotArea.extern[frame] = hot or nil
	end
	
	hotArea.animation = 0
	self.frozen = false
	
	local function tick(height) self.leftHidden:SetHeight(height) end
	local function freeze(self, value) self.frozen = value end
	local function fadeIn()
		if(not self.frozen) then
			Animate.stop(hotArea.animation)
			self.leftHidden:SetVisible(true)
			hotArea.animation = Animate.smoothstep(self.leftHidden:GetHeight(), self:GetHeight() - 4, 0.3, tick, function()
				hotArea.animation = 0
				self.leftPanel:SetVisible(false)
			end)
		end
	end
	local function fadeOut()
		if(not self.frozen) then
			Animate.stop(hotArea.animation)
			self.leftPanel:SetVisible(true)
			hotArea.animation = Animate.smoothstep(self.leftHidden:GetHeight(), 0, 0.3, tick, function()
				hotArea.animation = 0
				self.leftHidden:SetVisible(false)
			end)
			for frame in pairs(hotArea.extern) do
				frame:FadeOut()
			end
		end
	end
	local function isMouseHot(self)
		local mouse = InspectMouse()
		local outside = hitTest(hotArea, mouse.x, mouse.y)
		for k, v in pairs(hotArea.extern) do
			outside = outside and hitTest(k, mouse.x, mouse.y)
		end
		return not outside
	end
	local function fadeOutIfOutside(self)
		if(not isMouseHot(self)) then
			fadeOut()
		end
	end
	
	hotArea.Event.MouseIn = fadeIn
	hotArea.Event.MouseOut = fadeOutIfOutside
	
	self.Freeze = freeze
	self.FadeIn = fadeIn
	self.FadeOut = fadeOut
	self.FadeOutIfOutside = fadeOutIfOutside
	self.IsMouseHot = isMouseHot
end

local function createFadeAnimationRight(self)
	local hotArea = UICreateFrame("Frame", "", self)
	hotArea:SetLayer(100)
	hotArea:SetAllPoints(self.rightPanel)
	hotArea:SetMouseMasking("limited")
	
	hotArea.animation = 0
	
	local function tick(values) 
		self.rightHidden:SetWidth(values[1])
		self.rightPanel:SetWidth(max(rightPanelMinWidth, values[1]))
		self.rightHiddenButtonsOffsetCurrent = values[2]
		self.locationButtons[1]:SetPoint("LEFTCENTER", self.rightHidden, "LEFTCENTER", values[2], 0)
	end
	local function fadeIn()
		if(not self.frozen) then
			Animate.stop(hotArea.animation)
			hotArea.animation = Animate.smoothstep({ self.rightHidden:GetWidth(), self.rightHiddenButtonsOffsetCurrent }, { rightHiddenMaxWidth, 0 }, 0.3, tick, function()
				hotArea.animation = 0
			end)
		end
	end
	local function fadeOut()
		if(not hotArea.frozen) then
			Animate.stop(hotArea.animation)
			hotArea.animation = Animate.smoothstep({ self.rightHidden:GetWidth(), self.rightHiddenButtonsOffsetCurrent }, { rightHiddenMinWidth, self.rightHiddenButtonsOffset }, 0.3, tick, function()
				hotArea.animation = 0
			end)
		end
	end

	hotArea.Event.MouseIn = fadeIn
	hotArea.Event.MouseOut = fadeOut
end

local function createAllianceLogo(self)
	self.allianceIcon = UICreateFrame("Texture", "", self.leftPanel)
	self.allianceIcon:SetPoint("BOTTOMLEFT", self.leftPanel, "BOTTOMLEFT", 0, 14)
	self.allianceIcon:SetWidth(36)
	self.allianceIcon:SetHeight(36)
	
	function self:SetAlliance(alliance)
		if(alliance) then
			self.allianceIcon:SetWidth(36)
			self.allianceIcon:SetTextureAsync("Rift", alliance .. ".png.dds")
		else
			self.allianceIcon:SetWidth(0)
		end
	end
end

local function createMainLabel(self)
	self.mainLabel = UICreateFrame("Text", "", self.leftPanel)
	self.mainLabel:SetFontColor(0, 0, 0)
	self.mainLabel:SetFontSize(18)
	self.mainLabel:SetText("")
	self.mainLabel:SetPoint("TOPLEFT", self.allianceIcon, "TOPLEFT", 20, -2)
	
	function self:SetMainLabel(text) self.mainLabel:SetText(text) end
end

local function hideAllMenus(self)
	for i = 1, #self.fadeOutMenus do
		self.fadeOutMenus[i]:FadeOut()
	end
end

local function createCharButton(self)
	self.charButton = Ux.ItemWindowTemplate.TitleBarButton(self.leftHidden, "Rift", "icon_menu_charpanel.png.dds", 20, 20, 0, 0, function()
		if(self.charSelector:GetVisible()) then
			self.charSelector:FadeOut()
		else
			self.charButtonCallback()
		end
	end)
	self.charButton:SetPoint("TOPLEFT", self.leftHidden, "TOPLEFT", 0, -1)
	function self:SetCharButtonCallback(callback) self.charButtonCallback = callback end
	function self:SetCharButtonSkin(skin)
		if(skin == "player") then
			self.charButton:SetTexture("Rift", "icon_menu_charpanel.png.dds", 20, 20)
		elseif(skin == "guild") then
			self.charButton:SetTexture("Rift", "icon_menu_guild.png.dds", 24, 24)
		end
	end

	self.charSelector = Ux.ItemWindowTemplate.CharSelector(self, self)
	self.charSelector:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 5, 0)
	self.charSelector:SetVisible(false)
	self:HotArea(self.charSelector, true)
	self.fadeOutMenus[#self.fadeOutMenus + 1] = self.charSelector
	
	function self:ShowCharSelector(chars)
		hideAllMenus(self)
		self.charSelector:ShowForChars(chars)
	end
	function self:HideCharSelector() self.charSelector:FadeOut() end
	function self:SetCharSelectorCallback(callback) self.charSelector:SetCallback(callback) end
end

local function createGoldButton(self)
	self.goldButton = Ux.ItemWindowTemplate.TitleBarButton(self.leftHidden, "ImhoBags", "textures/icon_menu_gold.png", 24, 24, 0, 1, function()
		if(self.coinSummary:GetVisible()) then
			self.coinSummary:FadeOut()
		else
			hideAllMenus(self)
			self.coinSummary:FadeIn()
		end
	end)
	self.goldButton:SetPoint("TOPLEFT", self.charButton, "TOPRIGHT")

	self.coinSummary = Ux.ItemWindowTemplate.CoinSummary(self, self)
	self.coinSummary:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 15, 0)
	self.coinSummary:SetVisible(false)
	self:HotArea(self.coinSummary, true)
	self.fadeOutMenus[#self.fadeOutMenus + 1] = self.coinSummary
end

local function createSearchFilter(self)
	local background = UICreateFrame("Texture", "", self.leftHidden)
	background:SetTexture("Rift", "window_field.png.dds")
	background:SetPoint("TOPLEFT", self.goldButton, "TOPRIGHT", 0, 0)
	background:SetWidth(filterBoxWidth)
	background:SetHeight(20)

	local button = Ux.ItemWindowTemplate.TitleBarButton(background, "Rift", "icon_menu_LFP.png.dds", 26, 26, 0, 1, function() Ux.SearchWindow:Toggle() end)
	button:SetPoint("RIGHTCENTER", background, "RIGHTCENTER", -4, -1)
	
	local input = UICreateFrame("RiftTextfield", "", background)
	input:SetPoint("LEFTCENTER", background, "LEFTCENTER", 4, 1)
	input:SetPoint("RIGHTCENTER", button, "LEFTCENTER", 0, 1)
	input:SetText("")
	
	function self:ClearKeyFocus()
		input:SetKeyFocus(false)
	end
	
	function self:SetFilterCallback(callback) input.callback = callback end

	input.Event.KeyFocusGain = function() self:Freeze(true) end
	input.Event.KeyFocusLoss = function()
		self:Freeze(false)
		self:FadeOutIfOutside()
		input:SetText("")
		input.callback("")
	end
	input.Event.TextfieldChange = function() input.callback(input:GetText()) end
	
	self.filterBox = background
end

local function createSizeButton(self)
	self.sizeButton = Ux.ItemWindowTemplate.TitleBarButton(self.leftHidden, "ImhoBags", "textures/icon_menu_size.png", nil, nil, 0, 0, function()
		if(self.sizeSelector:GetVisible()) then
			self.sizeSelector:FadeOut()
		else
			hideAllMenus(self)
			self.sizeSelector:FadeIn()
		end
	end)
	self.sizeButton:SetPoint("LEFTCENTER", self.filterBox, "RIGHTCENTER", 5, 0)

	self.sizeSelector = Ux.ItemWindowTemplate.SizeSelector(self, self)
	self.sizeSelector:SetPoint("TOPCENTER", self, "BOTTOMLEFT", filterBoxLeft + filterBoxWidth + 35, 0)
	self.sizeSelector:SetVisible(false)
	self:HotArea(self.sizeSelector, true)
	self.fadeOutMenus[#self.fadeOutMenus + 1] = self.sizeSelector
		
	function self:SetSizeSelectorCallback(callback) self.sizeSelector:SetCallback(callback) end
	function self:SetSizeSelectorValue(n) self.sizeSelector:SetValue(n) end
end

local function createSortButton(self)
	self.sortButton = Ux.ItemWindowTemplate.TitleBarButton(self.leftHidden, "ImhoBags", "textures/icon_menu_sort.png", nil, nil, 0, 0, function()
		if(self.sortSelector:GetVisible()) then
			self.sortSelector:FadeOut()
		else
			hideAllMenus(self)
			self.sortSelector:FadeIn()
		end
	end)
	self.sortButton:SetPoint("LEFTCENTER", self.sizeButton, "RIGHTCENTER", 5, 0)
	self.sortButton:SetVisible(false)

	self.sortSelector = Ux.ItemWindowTemplate.SortSelector(self, self)
	self.sortSelector:SetPoint("TOPCENTER", self, "BOTTOMLEFT", filterBoxLeft + filterBoxWidth + 55, 0)
	self.sortSelector:SetVisible(false)
	self:HotArea(self.sortSelector, true)
	self.fadeOutMenus[#self.fadeOutMenus + 1] = self.sortSelector
		
	function self:SetSortSelectorCallback(callback) self.sortButton:SetVisible(callback ~= nil) self.sortSelector:SetCallback(callback) end
	function self:SetSortSelectorValue(n) self.sortSelector:SetValue(n) end
end

local function createEmptySlotIndicator(self)
	self.emptySlotsBackground = UICreateFrame("Texture", "", self)
	self.emptySlotsBackground:SetTexture("Rift", "icon_empty.png.dds")
	self.emptySlotsBackground:SetWidth(24)
	self.emptySlotsBackground:SetHeight(24)
	self.emptySlotsBackground:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -1)
	
	self.emptySlotsIndicator = UICreateFrame("Text", "", self.emptySlotsBackground)
	self.emptySlotsIndicator:SetPoint("BOTTOMRIGHT", self.emptySlotsBackground, "BOTTOMRIGHT", -2, 0)
	self.emptySlotsIndicator:SetFontSize(12)
	
	function self:SetEmptySlots(n)
		if(n) then
			self.emptySlotsIndicator:SetVisible(true)
			self.emptySlotsIndicator:SetText(tostring(n))
			n = self.emptySlotsIndicator:GetWidth()
			self.emptySlotsBackground:SetWidth(n > 24 and (n + 5) or 24)
		else
			self.emptySlotsBackground:SetWidth(0)
			self.emptySlotsIndicator:SetVisible(false)
		end
	end
end

local function createLocationButtons(self, location)
	local locations = {
		"inventory",	"ImhoBags",	"textures/icon_menu_inventory.png",	28, 28, -1, 0,
		"bank",			"ImhoBags",	"textures/icon_menu_bank.png",		28, 28, 2, 2,
		"mail",			"ImhoBags",	"textures/icon_menu_mail.png",		29, 29, 1, 1,
		"equipment",	"Rift",		"icon_menu_raid.png.dds",			22, 22, 0, 0,
		"currency",		"ImhoBags",	"textures/icon_menu_gold.png",		24, 24, 0, 0,
		"guildbank",	"Rift",		"icon_menu_guild.png.dds",			26, 26, -1, 0,
	}
	local offsets = {
		inventory = 0,
		bank = -20,
		mail = -40,
		equipment = -60,
		currency = -80,
		guildbank = -100,
	}
	self.rightHiddenButtonsOffset = offsets[location]
	self.rightHiddenButtonsOffsetCurrent = self.rightHiddenButtonsOffset
	local prev = Ux.ItemWindowTemplate.TitleBarButton(self.rightHidden, locations[2], locations[3], locations[4], locations[5], locations[6], locations[7], function() self.locationCallback(locations[1]) end)
	prev:SetPoint("LEFTCENTER", self.rightHidden, "LEFTCENTER", self.rightHiddenButtonsOffset, 0)
	self.locationButtons = { prev }
	for i = 1, 5 do
		local j = i * 7
		local btn = Ux.ItemWindowTemplate.TitleBarButton(self.rightHidden, locations[j+2], locations[j+3], locations[j+4], locations[j+5], locations[j+6], locations[j+7], function() self.locationCallback(locations[j+1]) end)
		btn:SetPoint("LEFTCENTER", prev, "RIGHTCENTER")
		prev = btn
		self.locationButtons[#self.locationButtons + 1] = btn
	end
	
	function self:SetLocationCallback(callback) self.locationCallback = callback end
end

-- Public methods
-- ============================================================================

function Ux.ItemWindowTemplate.TitleBar(parent, location)
	local border = parent:GetBorder()
	
	local self = UICreateFrame("Frame", "", border)
	self:SetPoint("TOPLEFT", border, "TOPLEFT", 80, 18)
	self:SetPoint("TOPRIGHT", border, "TOPRIGHT", -80, 18)
	self:SetHeight(24)
	
	-- Right panel
	createEmptySlotIndicator(self)
	
	local rightPanel = UICreateFrame("Mask", "", self)
	rightPanel:SetPoint("TOPRIGHT", self.emptySlotsBackground, "TOPLEFT", 3, 3)
	rightPanel:SetPoint("BOTTOMRIGHT", self.emptySlotsBackground, "BOTTOMLEFT", 3, -3)
	rightPanel:SetWidth(rightPanelMinWidth)
	
	local rightHidden = UICreateFrame("Mask", "", self)
	rightHidden:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT")
	rightHidden:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT")
	rightHidden:SetWidth(rightHiddenMinWidth)
	
	self.rightHidden = rightHidden
	self.rightPanel = rightPanel
	createLocationButtons(self, location)

	-- Left panel
	local leftHidden = UICreateFrame("Mask", "", self)
	leftHidden:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, -2)
	leftHidden:SetPoint("RIGHT", rightPanel, "LEFT")
	leftHidden:SetHeight(0)
	
	local leftPanel = UICreateFrame("Mask", "", self)
	leftPanel:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 2)
	leftPanel:SetPoint("BOTTOMLEFT", leftHidden, "TOPLEFT")
	leftPanel:SetPoint("RIGHT", rightPanel, "LEFT")
	
	if(not Addon.toc.debug) then
		leftPanel:SetBackgroundColor(1, 0, 0, 0.5)
		leftHidden:SetBackgroundColor(0, 0, 1, 0.5)
		rightPanel:SetBackgroundColor(0, 0, 0, 0.5)
		rightHidden:SetBackgroundColor(0, 1, 0, 0.5)
	end

	self.leftHidden = leftHidden
	self.leftPanel = leftPanel
	
	self.fadeOutMenus = { }
	
	createFadeAnimationLeft(self)
	createFadeAnimationRight(self)
	
	-- Left leftPanel panel
	createAllianceLogo(self)
	createMainLabel(self)
	
	-- Left leftHidden panel
	createCharButton(self)
	createGoldButton(self)
	createSearchFilter(self)
	createSizeButton(self)
	createSortButton(self)
	
	return self
end
