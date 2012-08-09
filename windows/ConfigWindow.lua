local Addon, private = ...

-- Builtins
local floor = math.floor
local max = math.max
local pairs = pairs
local pcall = pcall
local strupper = string.upper
local tinsert = table.insert
local unpack = unpack

-- Globals
local Command = Command
local Inspect = Inspect
local LibAsyncTextures = LibAsyncTextures
local UICreateFrame = UI.CreateFrame
local UIParent = UIParent

local contentPadding = 10
local contentPanePaddingLeft = 140
local headingColor = { 216 / 255, 203 / 255, 153 / 255 }
local accountBoundColor = { 251 / 255, 242 / 255, 142 / 255 }

setfenv(1, private)
Ux = Ux or { }

-- Private methods
-- ============================================================================

local slashTooltip = UICreateFrame("Text", "", Ux.TooltipContext)
slashTooltip:SetVisible(false)
slashTooltip:SetFontSize(12)
slashTooltip:SetBackgroundColor(0, 0, 0, 0.75)

local function createHighlightedTexture(parent, path, tooltip, textureCallback)
	local icon = UICreateFrame("Texture", "", parent)
	icon:SetTextureAsync("ImhoBags", path, textureCallback)
	local highlight = UICreateFrame("Texture", "", parent)
	highlight:SetTexture("ImhoBags", "textures/ItemButton/highlight.png")
	highlight:SetAllPoints(icon)
	highlight:SetVisible(false)
	icon:SetLayer(highlight:GetLayer() + 1)
	function icon.Event:MouseIn()
		highlight:SetVisible(true)
		highlight:SetAlpha(1.0)
		if(Ux.ConfigWindow.showSlashTooltips) then
			slashTooltip:SetVisible(true)
			slashTooltip:ClearAll()
			slashTooltip:SetText(tooltip)
		end
		self.Event.MouseMove(self)
	end
	function icon.Event:MouseMove()
		local mouse = Inspect.Mouse()
		slashTooltip:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", mouse.x, mouse.y)
	end
	function icon.Event:MouseOut()
		if(self.checked) then
			highlight:SetAlpha(0.7)
		else
			highlight:SetVisible(false)
		end
		slashTooltip:SetVisible(false)
	end
	function icon:SetChecked(checked)
		self.checked = checked
		if(checked) then
			highlight:SetAlpha(0.7)
			highlight:SetVisible(true)
		else
			highlight:SetAlpha(1.0)
			highlight:SetVisible(false)
		end
	end
	function icon:GetChecked() return icon.checked end
	icon.highlight = highlight
	
	return icon
end

local function content_MouseMove(self)
	local mouse = Inspect.Mouse()
	if(self.mouseOffsetX) then
		self.window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", mouse.x - self.mouseOffsetX, mouse.y - self.mouseOffsetY)
	end
end

local function content_LeftDown(self)
	local mouse = Inspect.Mouse()
	local left, top, right, bottom = self.window:GetTrimDimensions()
	self.mouseOffsetX = floor(mouse.x - self.window:GetLeft())
	self.mouseOffsetY = floor(mouse.y - self.window:GetTop())
end

local function content_LeftUpoutside(self)
	self.mouseOffsetX, self.mouseOffsetY = nil, nil
end

local function content_LeftUp(self)
	content_LeftUpoutside(self)
end

local function makeMovable(self)
	local content = self:GetContent()
	content.window = self
	content.Event.MouseMove = content_MouseMove
	content.Event.LeftDown = content_LeftDown
	content.Event.LeftUp = content_LeftUp
	local border = self:GetBorder()
	border.window = self
	border.Event.MouseMove = content_MouseMove
	border.Event.LeftDown = content_LeftDown
	border.Event.LeftUp = content_LeftUp
	border.Event.LeftUpoutside = content_LeftUpoutside
end

local function createPaneButton(self, pane, name, previous)
	local button = UICreateFrame("RiftButton", "", self)
	button:SetText(name)
	name = strupper(name)
	function button.Event.LeftPress()
		for k, v in pairs(self.panes) do
			v:SetVisible(v == pane)
		end
		for k, v in pairs(self.buttons) do
			v:SetEnabled(v ~= button)
		end
		self.heading:SetText(name)
	end
	
	if(previous) then
		button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT")
		button:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT")
	else
		button:SetPoint("TOPLEFT", self, "TOPLEFT", 3, 25)
	end
	return button
end

local function createAppearance1Pane(self)
	local backdrop = UICreateFrame("Frame", "", self)
	backdrop:SetPoint("TOPLEFT", self, "TOPLEFT", contentPanePaddingLeft, 25)
	backdrop:SetPoint("TOPRIGHT", self, "TOPRIGHT", -contentPadding, 25)
	backdrop:SetBackgroundColor(0, 0, 0, 0.5)
	
	-- Condensed config
	local description = UICreateFrame("Text", "", backdrop)
	description:SetWordwrap(true)
	description:SetPoint("TOPLEFT", backdrop, "TOPLEFT", contentPadding, contentPadding / 2)
	description:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -contentPadding, contentPadding / 2)
	description:SetText(L.Ux.ConfigWindow.condensed)

	local condensed_y = createHighlightedTexture(backdrop, "textures/ConfigWindow/condensed yes.png", "/imhobags condensed yes")
	condensed_y:SetPoint("TOPLEFT", description, "BOTTOMLEFT")
	local condensed_n = createHighlightedTexture(backdrop, "textures/ConfigWindow/condensed no.png", "/imhobags condensed no")
	condensed_n:SetPoint("TOPRIGHT", description, "BOTTOMRIGHT")
	
	condensed_y:SetChecked(Config.condensed == true)
	condensed_n:SetChecked(Config.condensed == false)
	function condensed_y.Event:LeftDown() Config.condensed = true end
	function condensed_n.Event:LeftDown() Config.condensed = false end
	
	tinsert(ImhoEvent.Config, { function(k, v)
		if(k == "condensed") then
			condensed_y:SetChecked(v == true)
			condensed_n:SetChecked(v == false)
		end
	end , Addon.identifier, "" })
	
	-- Group packing option
	description = UICreateFrame("Text", "", backdrop)
	description:SetWordwrap(true)
	description:SetPoint("TOPLEFT", condensed_y, "BOTTOMLEFT", 0, contentPadding)
	description:SetPoint("TOPRIGHT", condensed_n, "BOTTOMRIGHT", 0, contentPadding)
	description:SetText(L.Ux.ConfigWindow.packGroups)
	
	local packGroups_y = createHighlightedTexture(backdrop, "textures/ConfigWindow/packGroups yes.png", "/imhobags packGroups yes")
	packGroups_y:SetPoint("TOPLEFT", description, "BOTTOMLEFT")
	local packGroups_n = createHighlightedTexture(backdrop, "textures/ConfigWindow/packGroups no.png", "/imhobags packGroups no")
	packGroups_n:SetPoint("TOPRIGHT", description, "BOTTOMRIGHT")
	
	packGroups_y:SetChecked(Config.packGroups == true)
	packGroups_n:SetChecked(Config.packGroups == false)
	function packGroups_y.Event:LeftDown() Config.packGroups = true end
	function packGroups_n.Event:LeftDown() Config.packGroups = false end
	
	tinsert(ImhoEvent.Config, { function(k, v)
		if(k == "packGroups") then
			packGroups_y:SetChecked(v == true)
			packGroups_n:SetChecked(v == false)
		end
	end , Addon.identifier, "" })
	
	-- Item button skin option
	description = UICreateFrame("Text", "", backdrop)
	description:SetWordwrap(true)
	description:SetPoint("TOPLEFT", packGroups_y, "BOTTOMLEFT", 0, contentPadding)
	description:SetPoint("TOPRIGHT", packGroups_n, "BOTTOMRIGHT", 0, contentPadding)
	description:SetText(L.Ux.ConfigWindow.itemButtonSkin)
	
	local itemButtonSkin_pretty = createHighlightedTexture(backdrop, "textures/ConfigWindow/itemButtonSkin pretty.png", "/imhobags itemButtonSkin pretty")
	itemButtonSkin_pretty:SetPoint("TOPLEFT", description, "BOTTOMLEFT")
	local itemButtonSkin_simple = createHighlightedTexture(backdrop, "textures/ConfigWindow/itemButtonSkin simple.png", "/imhobags itemButtonSkin simple", function(frame)
		backdrop:SetHeight(frame:GetBottom() - backdrop:GetTop() + contentPadding)
	end)
	itemButtonSkin_simple:SetPoint("TOPRIGHT", description, "BOTTOMRIGHT")
	backdrop:SetHeight(itemButtonSkin_simple:GetBottom() - backdrop:GetTop() + contentPadding)
	
	itemButtonSkin_pretty:SetChecked(Config.itemButtonSkin == "pretty")
	itemButtonSkin_simple:SetChecked(Config.itemButtonSkin == "simple")
	function itemButtonSkin_pretty.Event:LeftDown() Config.itemButtonSkin = "pretty" end
	function itemButtonSkin_simple.Event:LeftDown() Config.itemButtonSkin = "simple" end

	tinsert(ImhoEvent.Config, { function(k, v)
		if(k == "itemButtonSkin") then
			itemButtonSkin_pretty:SetChecked(v == "pretty")
			itemButtonSkin_simple:SetChecked(v == "simple")
		end
	end , Addon.identifier, "" })
	
	backdrop:SetVisible(false)
	return backdrop
end

local function createAppearance2Pane(self)
	local backdrop = UICreateFrame("Frame", "", self)
	backdrop:SetPoint("TOPLEFT", self, "TOPLEFT", contentPanePaddingLeft, 25)
	backdrop:SetPoint("TOPRIGHT", self, "TOPRIGHT", -contentPadding, 25)
	backdrop:SetBackgroundColor(0, 0, 0, 0.5)
	
	-- Condensed config
	local description = UICreateFrame("Text", "", backdrop)
	description:SetWordwrap(true)
	description:SetPoint("TOPLEFT", backdrop, "TOPLEFT", contentPadding, contentPadding / 2)
	description:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -contentPadding, contentPadding / 2)
	description:SetText(L.Ux.ConfigWindow.showBoundIcon)

	local showBoundIcon = createHighlightedTexture(backdrop, "textures/ConfigWindow/showBoundIcon.png", "/imhobags showBoundIcon yes/no", function(frame)
		backdrop:SetHeight(frame:GetBottom() - backdrop:GetTop() + contentPadding)
	end)
	showBoundIcon:SetPoint("TOPCENTER", description, "BOTTOMCENTER")
	
	showBoundIcon:SetChecked(Config.showBoundIcon == true)
	function showBoundIcon.Event:LeftDown() Config.showBoundIcon = not self:GetChecked() end
	
	tinsert(ImhoEvent.Config, { function(k, v)
		if(k == "showBoundIcon") then
			showBoundIcon:SetChecked(v)
		end
	end , Addon.identifier, "" })
	
	backdrop:SetVisible(false)
	return backdrop
end

local function createBehaviorPane(self)
	local backdrop = UICreateFrame("Frame", "", self)
	backdrop:SetPoint("TOPLEFT", self, "TOPLEFT", contentPanePaddingLeft, 25)
	backdrop:SetPoint("TOPRIGHT", self, "TOPRIGHT", -contentPadding, 25)
	backdrop:SetBackgroundColor(0, 0, 0, 0.5)
	
	-- Auto Open
	local description = UICreateFrame("Text", "", backdrop)
	description:SetWordwrap(true)
	description:SetPoint("TOPLEFT", backdrop, "TOPLEFT", contentPadding, contentPadding / 2)
	description:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -contentPadding, contentPadding / 2)
	description:SetText(L.Ux.ConfigWindow.autoOpen)

	local autoOpen = createHighlightedTexture(backdrop, "textures/ConfigWindow/autoOpen.png", "/imhobags autoOpen yes/no")
	autoOpen:SetPoint("TOPLEFT", description, "BOTTOMLEFT")
	
	autoOpen:SetChecked(Config.autoOpen == true)
	function autoOpen.Event:LeftDown() Config.autoOpen = not self:GetChecked() end

	tinsert(ImhoEvent.Config, { function(k, v)
		if(k == "autoOpen") then
			autoOpen:SetChecked(v)
		end
	end , Addon.identifier, "" })
	
	-- Enemy faction treatment
	description = UICreateFrame("Text", "", backdrop)
	description:SetWordwrap(true)
	description:SetPoint("TOPLEFT", autoOpen, "BOTTOMLEFT", 0, 0)
	description:SetPoint("TOPRIGHT", autoOpen, "BOTTOMRIGHT", 0, 0)
	description:SetText(L.Ux.ConfigWindow.showEnemyFaction)

	local showEnemyFaction_y = createHighlightedTexture(backdrop, "textures/ConfigWindow/showEnemyFaction yes.png", "/imhobags showEnemyFaction yes")
	showEnemyFaction_y:SetPoint("TOPLEFT", description, "BOTTOMLEFT")
	local showEnemyFaction_a = createHighlightedTexture(backdrop, "textures/ConfigWindow/showEnemyFaction account.png", "/imhobags showEnemyFaction account")
	showEnemyFaction_a:SetPoint("TOPCENTER", description, "BOTTOMCENTER")
	local showEnemyFaction_n = createHighlightedTexture(backdrop, "textures/ConfigWindow/showEnemyFaction " .. Player.alliance .. ".png", "/imhobags showEnemyFaction no", function(frame)
		backdrop:SetHeight(frame:GetBottom() - backdrop:GetTop() + contentPadding)
	end)
	showEnemyFaction_n:SetPoint("TOPRIGHT", description, "BOTTOMRIGHT")
--[[	local text = UICreateFrame("Text", "", showEnemyItems_a)
	text:SetPoint("TOPCENTER", showEnemyFaction_a, "BOTTOMCENTER", 0, -3)
	text:SetText("Bound to Account")
	text:SetFontSize(14)
	text:SetFontColor(unpack(accountBoundColor))
	showEnemyFaction_a.highlight:SetLayer(2)
]]	
	showEnemyFaction_y:SetChecked(Config.showEnemyFaction == "yes")
	function showEnemyFaction_y.Event:LeftDown() Config.showEnemyFaction = "yes" end
	showEnemyFaction_a:SetChecked(Config.showEnemyFaction == "account")
	function showEnemyFaction_a.Event:LeftDown() Config.showEnemyFaction = "account" end
	showEnemyFaction_n:SetChecked(Config.showEnemyFaction == "no")
	function showEnemyFaction_n.Event:LeftDown() Config.showEnemyFaction = "no" end
	
	tinsert(ImhoEvent.Config, { function(k, v)
		if(k == "showEnemyFaction") then
			showEnemyFaction_y:SetChecked(v == "yes")
			showEnemyFaction_a:SetChecked(v == "account")
			showEnemyFaction_n:SetChecked(v == "no")
		end
	end , Addon.identifier, "" })
	
	backdrop:SetVisible(false)
	return backdrop
end

local function createExtrasPane(self)
	local backdrop = UICreateFrame("Frame", "", self)
	backdrop:SetPoint("TOPLEFT", self, "TOPLEFT", contentPanePaddingLeft, 25)
	backdrop:SetPoint("TOPRIGHT", self, "TOPRIGHT", -contentPadding, 25)
	backdrop:SetBackgroundColor(0, 0, 0, 0.5)
	
	-- Tooltip enhancement
	local description = UICreateFrame("Text", "", backdrop)
	description:SetWordwrap(true)
	description:SetPoint("TOPLEFT", backdrop, "TOPLEFT", contentPadding, contentPadding / 2)
	description:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -contentPadding, contentPadding / 2)
	description:SetText(L.Ux.ConfigWindow.enhanceTooltips)

	local enhanceTooltips = createHighlightedTexture(backdrop, "textures/ConfigWindow/enhanceTooltips.png", "/imhobags enhanceTooltips yes/no")
	enhanceTooltips:SetPoint("TOPCENTER", description, "BOTTOMCENTER")

	enhanceTooltips:SetChecked(Config.enhanceTooltips == true)
	function enhanceTooltips.Event:LeftDown() Config.enhanceTooltips = not self:GetChecked() end

	tinsert(ImhoEvent.Config, { function(k, v)
		if(k == "enhanceTooltips") then
			enhanceTooltips:SetChecked(v)
		end
	end , Addon.identifier, "" })
	
	-- Empty slot indication
	local description2 = UICreateFrame("Text", "", backdrop)
	description2:SetWordwrap(true)
	description2:SetPoint("TOPCENTER", enhanceTooltips, "BOTTOMCENTER")
	description2:SetWidth(description:GetWidth())
	description2:SetText(L.Ux.ConfigWindow.showEmptySlots)

	local showEmptySlots = createHighlightedTexture(backdrop, "textures/ConfigWindow/showEmptySlots.png", "/imhobags showEmptySlots yes/no", function(frame)
		backdrop:SetHeight(frame:GetBottom() - backdrop:GetTop() + contentPadding)
	end)
	showEmptySlots:SetPoint("TOPCENTER", description2, "BOTTOMCENTER")

	showEmptySlots:SetChecked(Config.showEmptySlots == true)
	function showEmptySlots.Event:LeftDown() Config.showEmptySlots = not self:GetChecked() end

	tinsert(ImhoEvent.Config, { function(k, v)
		if(k == "showEmptySlots") then
			showEmptySlots:SetChecked(v)
		end
	end , Addon.identifier, "" })
	
	
	backdrop:SetVisible(false)
	return backdrop
end
	
-- Public methods
-- ============================================================================

function Ux.ConfigWindow()
	local self = UICreateFrame("RiftWindow", "", Ux.Context)
	self:SetTitle(L.Ux.ConfigWindow.title)
	self:SetController("content")
	self:SetWidth(650)
	Ux.ConfigWindow = self
	makeMovable(self)
	self.showSlashTooltips = false
	
	-- Close button
	Ux.RiftWindowCloseButton.New(self, self)
	
	-- Section headline
	self.heading = UICreateFrame("Text", "", self)
	self.heading:SetFontSize(18)
	self.heading:SetFontColor(unpack(headingColor))
	self.heading:SetPoint("TOPLEFT", self, "TOPLEFT", contentPanePaddingLeft + 15, 0)
	self.underline = UICreateFrame("Texture", "", self)
	self.underline:SetTexture("ImhoBags", "textures/hr1.png")
	self.underline:SetWidth(350)
	self.underline:SetHeight(self.underline:GetTextureHeight())
	self.underline:SetPoint("TOPLEFT", self.heading, "BOTTOMLEFT", -30, -3)
	self.underline:SetLayer(2)
	
	-- Slash tooltip checkbox
	local tooltipCheck = Ux.Checkbox.New(self, L.Ux.ConfigWindow.showTooltips, "LEFT")
	tooltipCheck:SetPoint("TOPRIGHT", self, "TOPRIGHT", -contentPadding, contentPadding / 2)
	tooltipCheck.Event.CheckboxChange = function() self.showSlashTooltips = tooltipCheck:GetChecked() end
	
	-- Config panes
	self.panes = { }
	self.panes.appearance1 = createAppearance1Pane(self)
	self.panes.appearance2 = createAppearance2Pane(self)
	self.panes.behavior = createBehaviorPane(self)
	self.panes.extras = createExtrasPane(self)
	
	-- Make all backdrops have the same height after all textures have loaded
	LibAsyncTextures.EnqueueCallback(function()
		local height = 0
		for k, v in pairs(self.panes) do
			height = max(v:GetHeight(), height)
		end
		for k, v in pairs(self.panes) do
			v:SetHeight(height)
		end
		self:SetHeight(height + contentPadding + 25)
	end)
	
	-- Pane selection buttons
	self.buttons = { }
	self.buttons[#self.buttons + 1] = createPaneButton(self, self.panes.appearance1, L.Ux.ConfigWindow.appearance1Section, nil)
	self.buttons[#self.buttons + 1] = createPaneButton(self, self.panes.appearance2, L.Ux.ConfigWindow.appearance2Section, self.buttons[#self.buttons])
	self.buttons[#self.buttons + 1] = createPaneButton(self, self.panes.behavior, L.Ux.ConfigWindow.behaviorSection, self.buttons[#self.buttons])
	self.buttons[#self.buttons + 1] = createPaneButton(self, self.panes.extras, L.Ux.ConfigWindow.extrasSection, self.buttons[#self.buttons])

	self.buttons[1].Event.LeftPress(self.buttons[1])
end

