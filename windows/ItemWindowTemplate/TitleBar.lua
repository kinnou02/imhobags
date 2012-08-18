local Addon, private = ...

-- Builtins
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
			self.emptySlotsBackground:SetWidth(24)
			self.emptySlotsIndicator:SetVisible(true)
			self.emptySlotsIndicator:SetText(tostring(n))
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

local function createCharSelector(self)
	self.charSelector = Ux.ItemWindowTemplate.CharSelector(self, self)
	self.charSelector:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 5, 0)
	self.charSelector:SetVisible(false)
	self:HotArea(self.charSelector, true)
	
	function self:ShowCharSelector(chars) self.charSelector:ShowForChars(chars) end
	function self:HideCharSelector() self.charSelector:FadeOut() end
	function self:SetCharSelectorCallback(callback) self.charSelector:SetCallback(callback) end
end

local function createSizeSelector(self)
	self.sizeSelector = Ux.ItemWindowTemplate.SizeSelector(self, self)
	self.sizeSelector:SetPoint("TOPCENTER", self, "BOTTOMLEFT", filterBoxLeft + filterBoxWidth + 55, 0)
	self.sizeSelector:SetVisible(false)
	self:HotArea(self.sizeSelector, true)
		
	function self:SetSizSelectorCallback(callback) self.sizeSelector:SetCallback(callback) end
	function self:SetSizSelectorValue(n) self.sizeSelector:SetValue(n) end
end

local function createButtons(self)
	local background = UICreateFrame("Frame", "", self.hidden)
--	background:SetTexture("Rift", "window_field.png.dds")
	background:SetPoint("TOPLEFT", self.hidden, "TOPLEFT")
	background:SetHeight(20)
	background:SetWidth(74)
	
	local highlight = UICreateFrame("Texture", "", background)
	highlight:SetTexture("Rift", "SoulTree_I9.dds")
	
	local player = UICreateFrame("Texture", "", background)
	player:SetTexture("Rift", "icon_menu_charpanel.png.dds")
	player:SetPoint("LEFTCENTER", background, "LEFTCENTER", 3, -1)
	player:SetHeight(20)
	player:SetWidth(20)
	player.Event.LeftUp = function()
		if(self.charSelector:GetVisible()) then
			self.charSelector:FadeOut()
		else
			self.playerButtonCallback()
		end
	end
	createCharSelector(self)
	
	local sort = UICreateFrame("Texture", "", background)
	sort:SetTexture("ImhoBags", "textures/icon_menu_sort.png")
	sort:SetPoint("LEFTCENTER", background, "LEFTCENTER", filterBoxLeft + filterBoxWidth, -1)
	
	local size = UICreateFrame("Texture", "", background)
	size:SetTexture("ImhoBags", "textures/icon_menu_size.png")
	size:SetPoint("LEFTCENTER", sort, "RIGHTCENTER", -6, 0)
	size.Event.LeftUp = function()
		if(self.sizeSelector:GetVisible()) then
			self.sizeSelector:FadeOut()
		else
			self.sizeSelector:FadeIn()
		end
	end
	createSizeSelector(self)
	
	function self:SetPlayerButtonCallback(callback) self.playerButtonCallback = callback end
	function self:SetPlayerButtonSkin(skin)
		if(skin == "player") then
			player:SetTexture("Rift", "icon_menu_charpanel.png.dds")
			player:SetHeight(20)
			player:SetWidth(20)
		elseif(skin == "guild") then
			player:SetTexture("Rift", "icon_menu_guild.png.dds")
			player:SetHeight(24)
			player:SetWidth(24)
		end
	end
	
	self.buttonsBox = background
end

local function createSearchFilter(self)
	local background = UICreateFrame("Texture", "", self.hidden)
	background:SetTexture("Rift", "window_field.png.dds")
	background:SetPoint("TOPLEFT", self.hidden, "TOPLEFT", filterBoxLeft, 0)
	background:SetWidth(filterBoxWidth)
	background:SetHeight(20)

	local icon = UICreateFrame("Texture", "", background)
	icon:SetTexture("Rift", "icon_menu_LFP.png.dds")
	icon:SetPoint("RIGHTCENTER", background, "RIGHTCENTER", -4, -1)
	icon:SetWidth(26)
	icon:SetHeight(26)
	icon.Event.LeftUp = function() Ux.SearchWindow:Toggle() end
	
	local input = UICreateFrame("RiftTextfield", "", background)
	input:SetPoint("LEFTCENTER", background, "LEFTCENTER", 4, 1)
	input:SetPoint("RIGHTCENTER", icon, "LEFTCENTER", 0, 1)
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

-- Public methods
-- ============================================================================

local function new(_, parent)
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
	
	-- Visible panel
	createFadeAnimation(self)
	createAllianceLogo(self)
	createEmptySlotIndicator(self)
	createMainLabel(self)
	
	-- Hidden panel
	createButtons(self)
	createSearchFilter(self)
	
	return self
end

metatable.__call = new
