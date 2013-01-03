local Addon, private = ...

local contentPadding = 10
local contentPanePaddingLeft = 140
local contentPanePaddingRight = 25
local headingColor = { 216 / 255, 203 / 255, 153 / 255 }
local accountBoundColor = { 251 / 255, 242 / 255, 142 / 255 }

setfenv(1, private)
Ux = Ux or { }

local topPanes = {
	{
		name = L.Ux.ConfigWindow.appearanceSection,
		content = {
			{
				description = L.Ux.ConfigWindow.condensed,
				config = "condensed",
				options = {
					{ true, "textures/ConfigWindow/condensed yes.png", "/imhobags condensed yes" },
					{ false, "textures/ConfigWindow/condensed no.png", "/imhobags condensed no" },
				},
			},
			{
				description = L.Ux.ConfigWindow.packGroups,
				config = "packGroups",
				options = {
					{ true, "textures/ConfigWindow/packGroups yes.png", "/imhobags packGroups yes" },
					{ false, "textures/ConfigWindow/packGroups no.png", "/imhobags packGroups no" },
				},
			},
			{
				description = L.Ux.ConfigWindow.itemButtonSkin,
				config = "itemButtonSkin",
				options = {
					{ "pretty", "textures/ConfigWindow/itemButtonSkin pretty.png", "/imhobags itemButtonSkin pretty" },
					{ "simple", "textures/ConfigWindow/itemButtonSkin simple.png", "/imhobags itemButtonSkin simple" },
				},
			},
			{
				description = L.Ux.ConfigWindow.showBoundIcon,
				config = "showBoundIcon",
				options = {
					{ true, "textures/ConfigWindow/showBoundIcon.png", "/imhobags showBoundIcon yes/no" },
				},
			},
		},
	},
	{
		name = L.Ux.ConfigWindow.behaviorSection,
		content = {
			{
				description = L.Ux.ConfigWindow.autoOpen,
				config = "autoOpen",
				options = {
					{ true, "textures/ConfigWindow/autoOpen.png", "/imhobags autoOpen yes/no" },
				},
			},
		},
	},
	{
		name = L.Ux.ConfigWindow.extrasSection,
		content = {
			{
				description = L.Ux.ConfigWindow.enhanceTooltips,
				config = "enhanceTooltips",
				options = {
					{ true, "textures/ConfigWindow/enhanceTooltips.png", "/imhobags enhanceTooltips yes/no" },
				},
			},
			{
				description = L.Ux.ConfigWindow.showEmptySlots,
				config = "showEmptySlots",
				options = {
					{ true, "textures/ConfigWindow/showEmptySlots.png", "/imhobags showEmptySlots yes/no" },
				},
			},
		},
	},
}

-- Private methods
-- ============================================================================

local slashTooltip = UI.CreateFrame("Text", "", Ux.TooltipContext)
slashTooltip:SetVisible(false)
slashTooltip:SetFontSize(12)
slashTooltip:SetBackgroundColor(0, 0, 0, 0.75)

local function createHighlightedTexture(parent, path, tooltip, textureCallback)
	local icon = UI.CreateFrame("Texture", "", parent)
	icon:SetTexture("ImhoBags", path)
	local highlight = UI.CreateFrame("Texture", "", parent)
	highlight:SetTexture("ImhoBags", "textures/highlight.png")
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
	self.mouseOffsetX = math.floor(mouse.x - self.window:GetLeft())
	self.mouseOffsetY = math.floor(mouse.y - self.window:GetTop())
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
	local button = UI.CreateFrame("RiftButton", "", self)
	button:SetText(name)
	name = string.upper(name)
	function button.Event.LeftPress()
		for k, v in pairs(self.panes) do
			v:SetVisible(v == pane)
		end
		for k, v in pairs(self.buttons) do
			v:SetEnabled(v ~= button)
		end
		self.heading:SetText(name)
		self.activePane = pane
		local scroll = math.max(0, pane:GetHeight() - self.scrollbar:GetThickness())
		self.scrollbar:SetRange(0, scroll)
		self.scrollbar:SetPosition(pane.offset)
		self.scrollbar:SetEnabled(scroll > 0)
	end
	
	if(previous) then
		button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT")
		button:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT")
	else
		button:SetPoint("TOPLEFT", self, "TOPLEFT", 3, 25)
	end
	return button
end

local function createContent(content, parent, dy)
	local description = UI.CreateFrame("Text", "", parent)
	description:SetWordwrap(true)
	description:SetPoint("TOPLEFT", parent, "TOPLEFT", contentPadding, dy + contentPadding / 2)
	description:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -contentPadding, dy + contentPadding / 2)
	description:SetText(content.description)
	
	local pictureHeight = 0
	local pictures = { }
	for i = 1, #content.options do
		pictures[i] = createHighlightedTexture(parent, content.options[i][2], content.options[i][3])
		pictures[i]:SetChecked(Config[content.config] == content.options[i][1])
	end
	if(#pictures == 1) then
		pictures[1]:SetPoint("TOPCENTER", description, "BOTTOMCENTER")
		pictures[1].Event.LeftDown = function(self) Config[content.config] = not self:GetChecked() end
	elseif(#pictures == 2) then
		pictures[1]:SetPoint("TOPLEFT", description, "BOTTOMLEFT")
		pictures[2]:SetPoint("TOPRIGHT", description, "BOTTOMRIGHT")
		pictures[1].Event.LeftDown = function(self) Config[content.config] = content.options[1][1] end
		pictures[2].Event.LeftDown = function(self) Config[content.config] = content.options[2][1] end
	end

	ImhoEvent.Config[#ImhoEvent.Config + 1] = { function(k, v)
		if(k == content.config) then
			for i = 1, #pictures do
				pictures[i]:SetChecked(v == content.options[i][1])
			end
		end
	end , Addon.identifier, "" }

	return contentPadding + description:GetHeight() + (#pictures > 0 and pictures[1]:GetHeight() or 0)
end

local function createPane(pane, parent)
	local content = UI.CreateFrame("Frame", "", parent)
	content:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
	content:SetWidth(parent:GetWidth())
	
	local height = 0
	for i = 1, #pane.content do
		height = height + createContent(pane.content[i], content, height)
	end
	content:SetHeight(height)
	content.offset = 0
	return content
end
	
-- Public methods
-- ============================================================================

function Ux.ConfigWindow()
	local self = UI.CreateFrame("RiftWindow", "", Ux.Context)
	self:SetTitle(L.Ux.ConfigWindow.title)
	self:SetController("content")
	self:SetWidth(665)
	Ux.ConfigWindow = self
	makeMovable(self)
	self.showSlashTooltips = false
	
	-- Close button
	Ux.RiftWindowCloseButton.New(self, self)
	
	-- Section headline
	self.heading = UI.CreateFrame("Text", "", self)
	self.heading:SetFontSize(18)
	self.heading:SetFontColor(unpack(headingColor))
	self.heading:SetPoint("TOPLEFT", self, "TOPLEFT", contentPanePaddingLeft + 15, 0)
	self.underline = UI.CreateFrame("Texture", "", self)
	self.underline:SetTexture("Rift", "quest_description_short_frame.png.dds")
	self.underline:SetHeight(self.underline:GetTextureHeight())
	self.underline:SetPoint("TOPLEFT", self.heading, "BOTTOMLEFT", -15, -20)
	self.heading:SetLayer(3)
	self.underline:SetLayer(2)
	
	-- Slash tooltip checkbox
	local tooltipCheck = Ux.Checkbox.New(self, L.Ux.ConfigWindow.showTooltips, "LEFT")
	tooltipCheck:SetPoint("TOPRIGHT", self, "TOPRIGHT", -contentPadding, contentPadding / 2)
	tooltipCheck.Event.CheckboxChange = function() self.showSlashTooltips = tooltipCheck:GetChecked() end
	
	-- ScrolPane background and scrolling
	local backdrop = UI.CreateFrame("Mask", "", self)
	backdrop:SetPoint("TOPLEFT", self, "TOPLEFT", contentPanePaddingLeft, 25)
	backdrop:SetPoint("TOPRIGHT", self, "TOPRIGHT", -contentPanePaddingRight, 25)
	backdrop:SetPoint("BOTTOM", self, "BOTTOM", nil, -contentPadding)
	backdrop:SetBackgroundColor(0, 0, 0, 0.5)

	self.scrollbar = UI.CreateFrame("RiftScrollbar", "", self)
	self.scrollbar:SetPoint("TOPRIGHT", self, "TOPRIGHT", -contentPadding, 25)
	self.scrollbar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -contentPadding, -contentPadding)
	self.scrollbar:SetThickness(backdrop:GetHeight())
	self.scrollbar.Event.ScrollbarChange = function()
		self.activePane.offset = self.scrollbar:GetPosition()
		self.activePane:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 0, -self.activePane.offset)
	end
	
	-- Config panes
	self.panes = { }
	for i = 1, #topPanes do
		self.panes[i] = createPane(topPanes[i], backdrop)
	end
	
	-- Pane selection buttons
	self.buttons = { }
	for i = 1, #topPanes do
		self.buttons[i] = createPaneButton(self, self.panes[i], topPanes[i].name, self.buttons[i - 1])
	end

	self.buttons[1].Event.LeftPress(self.buttons[1])
end

