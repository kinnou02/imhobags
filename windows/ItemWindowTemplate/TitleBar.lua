local Addon, private = ...

-- Builtins
local max = math.max
local pairs = pairs
local tostring = tostring

-- Globals
local InspectMouse = Inspect.Mouse
local UICreateFrame = UI.CreateFrame

-- Locals
local metatable = { }
local filterBoxLeft = 24
local filterBoxWidth = 100

private.Ux.ItemWindowTemplate = private.Ux.ItemWindowTemplate or { }
private.Ux.ItemWindowTemplate.TitleBar = setmetatable({ }, metatable)

setfenv(1, private)

-- Private methods
-- ============================================================================

local function createFadeAnimation(self)
	local hotArea = UICreateFrame("Frame", "", self)
	hotArea:SetLayer(100)
	hotArea:SetAllPoints(self)
	hotArea:SetMouseMasking("limited")
	
	hotArea.extern = { }
	function self:HotArea(frame, hot)
		hotArea.extern[frame] = hot or nil
	end
	
	hotArea.animation = 0
	hotArea.freeze = false
	
	local function tick(width) self.hidden:SetHeight(width) end
	local function freeze(self, value) hotArea.freeze = value end
	local function fadeIn()
		if(not hotArea.freeze) then
			Animate.stop(hotArea.animation)
			self.hidden:SetVisible(true)
			hotArea.animation = Animate.easeInOut(self.hidden:GetHeight(), self:GetHeight() - 4, 0.3, tick, function()
				hotArea.animation = 0
				self.visible:SetVisible(false)
			end)
		end
	end
	local function fadeOut()
		if(not hotArea.freeze) then
			Animate.stop(hotArea.animation)
			self.visible:SetVisible(true)
			hotArea.animation = Animate.easeInOut(self.hidden:GetHeight(), 0, 0.3, tick, function()
				hotArea.animation = 0
				self.hidden:SetVisible(false)
			end)
			for frame in pairs(hotArea.extern) do
				frame:FadeOut()
			end
		end
	end
	local function isMouseHot(self)
		local function test(f, x, y)
			local left, top, right, bottom = f:GetBounds()
			return not f:GetVisible() or x < left or x > right or y < top or y > bottom
		end
		local mouse = InspectMouse()
		local outside = test(hotArea, mouse.x, mouse.y)
		for k, v in pairs(hotArea.extern) do
			outside = outside and test(k, mouse.x, mouse.y)
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

local function createAllianceLogo(self)
	self.allianceIcon = UICreateFrame("Texture", "", self.visible)
	self.allianceIcon:SetPoint("BOTTOMLEFT", self.visible, "BOTTOMLEFT", 0, 14)
	self.allianceIcon:SetWidth(36)
	self.allianceIcon:SetHeight(36)
	
	function self:SetAlliance(alliance)
		if(alliance) then
			self.allianceIcon:SetWidth(36)
			self.allianceIcon:SetTexture("Rift", alliance .. ".png.dds")-- == "defiant" and "MainMap_I21B.dds" or "MainMap_I221.dds")
		else
			self.allianceIcon:SetWidth(0)
		end
	end
end

local function createEmptySlotIndicator(self)
	self.emptySlotsBackground = UICreateFrame("Texture", "", self.visible)
	self.emptySlotsBackground:SetTexture("Rift", "icon_empty.png.dds")
	self.emptySlotsBackground:SetWidth(24)
	self.emptySlotsBackground:SetHeight(24)
	self.emptySlotsBackground:SetPoint("TOPLEFT", self.allianceIcon, "TOPLEFT", 20, -1)
	
	self.emptySlotsIndicator = UICreateFrame("Text", "", self.emptySlotsBackground)
	self.emptySlotsIndicator:SetPoint("BOTTOMRIGHT", self.emptySlotsBackground, "BOTTOMRIGHT", -2, 0)
	self.emptySlotsIndicator:SetFontSize(12)
	
	function self:SetEmptySlots(n)
		if(n) then
			self.emptySlotsIndicator:SetVisible(true)
			self.emptySlotsIndicator:SetText(tostring(n*10))
			n = self.emptySlotsIndicator:GetWidth()
			self.emptySlotsBackground:SetWidth(n > 24 and (n + 5) or 24)
		else
			self.emptySlotsBackground:SetWidth(0)
			self.emptySlotsIndicator:SetVisible(false)
		end
	end
end

local function createMainLabel(self)
	self.mainLabel = UICreateFrame("Text", "", self.visible)
	self.mainLabel:SetFontColor(0, 0, 0)
	self.mainLabel:SetFontSize(18)
	self.mainLabel:SetText("")
	self.mainLabel:SetPoint("LEFTCENTER", self.emptySlotsBackground, "RIGHTCENTER")
	
	function self:SetMainLabel(text) self.mainLabel:SetText(text) end
end

local function hideAllMenus(self)
	for i = 1, #self.fadeOutFrames do
		self.fadeOutFrames[i]:FadeOut()
	end
end

local function createCharButton(self)
	self.charButton = Ux.ItemWindowTemplate.TitleBarButton(self.hidden, "Rift", "icon_menu_charpanel.png.dds", 20, 20, 0, 0, function()
		if(self.charSelector:GetVisible()) then
			self.charSelector:FadeOut()
		else
			self.charButtonCallback()
		end
	end)
	self.charButton:SetPoint("TOPLEFT", self.hidden, "TOPLEFT", 0, -1)
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
	self.fadeOutFrames[#self.fadeOutFrames + 1] = self.charSelector
	
	function self:ShowCharSelector(chars)
		hideAllMenus(self)
		self.charSelector:ShowForChars(chars)
	end
	function self:HideCharSelector() self.charSelector:FadeOut() end
	function self:SetCharSelectorCallback(callback) self.charSelector:SetCallback(callback) end
end

local function createGoldButton(self)
	self.goldButton = Ux.ItemWindowTemplate.TitleBarButton(self.hidden, "ImhoBags", "textures/icon_menu_gold.png", 24, 24, 0, 1, function()
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
	self.fadeOutFrames[#self.fadeOutFrames + 1] = self.coinSummary
end

local function createSearchFilter(self)
	local background = UICreateFrame("Texture", "", self.hidden)
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
	self.sizeButton = Ux.ItemWindowTemplate.TitleBarButton(self.hidden, "ImhoBags", "textures/icon_menu_size.png", nil, nil, 0, 0, function()
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
	self.fadeOutFrames[#self.fadeOutFrames + 1] = self.sizeSelector
		
	function self:SetSizeSelectorCallback(callback) self.sizeSelector:SetCallback(callback) end
	function self:SetSizeSelectorValue(n) self.sizeSelector:SetValue(n) end
end

local function createSortButton(self)
	self.sortButton = Ux.ItemWindowTemplate.TitleBarButton(self.hidden, "ImhoBags", "textures/icon_menu_sort.png", nil, nil, 0, 0, function()
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
	self.sortSelector:SetPoint("TOPCENTER", self, "BOTTOMLEFT", filterBoxLeft + filterBoxWidth + 35, 0)
	self.sortSelector:SetVisible(false)
	self:HotArea(self.sortSelector, true)
	self.fadeOutFrames[#self.fadeOutFrames + 1] = self.sortSelector
		
	function self:SetSortSelectorCallback(callback) self.sortButton:SetVisible(callback ~= nil) self.sortSelector:SetCallback(callback) end
	function self:SetSortSelectorValue(n) self.sortSelector:SetValue(n) end
end

-- Public methods
-- ============================================================================

function metatable.__call(_, parent)
	local border = parent:GetBorder()
	
	local self = UICreateFrame("Frame", "", border)
	self:SetPoint("TOPLEFT", border, "TOPLEFT", 80, 18)
	self:SetPoint("TOPRIGHT", border, "TOPRIGHT", -80, 18)
	self:SetHeight(24)
	
	local hidden = UICreateFrame("Mask", "", self)
	hidden:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, -2)
	hidden:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, -2)
	hidden:SetHeight(0)
	
	local visible = UICreateFrame("Mask", "", self)
	visible:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 2)
	visible:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 2)
	visible:SetPoint("BOTTOMLEFT", hidden, "TOPLEFT")
	visible:SetPoint("BOTTOMRIGHT", hidden, "TOPRIGHT")
	
	self.hidden = hidden
	self.visible = visible
	
	self.fadeOutFrames = { }
	
	-- Visible panel
	createFadeAnimation(self)
	createAllianceLogo(self)
	createEmptySlotIndicator(self)
	createMainLabel(self)
	
	-- Hidden panel
	createCharButton(self)
	createGoldButton(self)
	createSearchFilter(self)
	createSizeButton(self)
	createSortButton(self)
	
	return self
end
