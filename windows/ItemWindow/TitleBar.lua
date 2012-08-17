local Addon, private = ...

-- Builtins
local pairs = pairs
local tostring = tostring

-- Globals
local InspectMouse = Inspect.Mouse
local UICreateFrame = UI.CreateFrame

-- Locals
local metatable = { }

private.Ux.TitleBar = setmetatable({ }, metatable)

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
			hotArea.animation = Animate.easeInOut(self.hidden:GetHeight(), self:GetHeight(), 0.3, tick, function()
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
		end
	end
	
	hotArea.Event.MouseIn = fadeIn
	hotArea.Event.MouseOut = fadeOut
	
	self.Freeze = freeze
	self.FadeIn = fadeIn
	self.FadeOut = fadeOut
	self.FadeOutIfOutside = function(self)
		local function test(f, x, y)
			left, top, right, bottom = f:GetBounds()
			return not f:GetVisible() or x < left or x > right or y < top or y > bottom
		end
		local mouse = InspectMouse()
		local outside = test(hotArea, mouse.x, mouse.y)
		for k, v in pairs(hotArea.extern) do
			outside = outside and test(k, mouse.x, mouse.y)
		end
		if(outside) then
			fadeOut()
		end
	end
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
	
	function self:SetMainLabel(text)
		self.mainLabel:SetText(text)
	end
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
	
	local guild = UICreateFrame("Texture", "", background)
	guild:SetTexture("Rift", "icon_menu_guild.png.dds")
	guild:SetPoint("LEFTCENTER", player, "RIGHTCENTER")
	guild:SetHeight(24)
	guild:SetWidth(24)
	
	local search = UICreateFrame("Texture", "", background)
	search:SetTexture("Rift", "icon_menu_LFP.png.dds")
	search:SetPoint("LEFTCENTER", guild, "RIGHTCENTER")
	search:SetHeight(24)
	search:SetWidth(24)
	search.Event.LeftUp = function() Ux.SearchWindow:Toggle() end
	
	self.buttonsBox = background
end

local function createSearchFilter(self)
	local background = UICreateFrame("Texture", "", self.hidden)
	background:SetTexture("Rift", "window_field.png.dds")
	background:SetPoint("LEFTCENTER", self.buttonsBox, "RIGHTCENTER")
	background:SetWidth(130)
	background:SetHeight(20)

	local icon = UICreateFrame("Texture", "", background)
	icon:SetTexture("Rift", "filter_icon.png.dds")
	icon:SetPoint("RIGHTCENTER", background, "RIGHTCENTER", -4, 0)
	
	local input = UICreateFrame("RiftTextfield", "", background)
	input:SetPoint("LEFTCENTER", background, "LEFTCENTER", 4, 1)
	input:SetPoint("RIGHTCENTER", icon, "LEFTCENTER", 0, 1)
	input:SetText("")
	
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
	self:SetPoint("TOPLEFT", border, "TOPLEFT", 80, 20)
	self:SetPoint("TOPRIGHT", border, "TOPRIGHT", -80, 20)
	self:SetHeight(20)
	
	local hidden = UICreateFrame("Mask", "", self)
	hidden:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT")
	hidden:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
	hidden:SetHeight(0)
	
	local visible = UICreateFrame("Mask", "", self)
	visible:SetPoint("TOPLEFT", self, "TOPLEFT")
	visible:SetPoint("TOPRIGHT", self, "TOPRIGHT")
	visible:SetPoint("BOTTOMLEFT", hidden, "TOPLEFT")
	visible:SetPoint("BOTTOMRIGHT", hidden, "TOPRIGHT")
	
--@debug@
--	hidden:SetBackgroundColor(0, 0, 1, 0.5)
--	visible:SetBackgroundColor(1, 0, 0, 0.5)
--@end-debug@
	
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
