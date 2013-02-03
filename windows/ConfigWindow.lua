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
--[[			{
				description = L.Ux.ConfigWindow.condensed,
				config = "condensed",
				height = 118,
				options = {
					{ true, "textures/ConfigWindow/condensed yes.png", "/imhobags condensed yes" },
					{ false, "textures/ConfigWindow/condensed no.png", "/imhobags condensed no" },
				},
			},
]]			{
				description = L.Ux.ConfigWindow.itemButtonSkin,
				config = "itemButtonSkin",
				height = 160,
				options = {
					{ "pretty", "textures/ConfigWindow/itemButtonSkin pretty.png", "/imhobags itemButtonSkin pretty" },
					{ "simple", "textures/ConfigWindow/itemButtonSkin simple.png", "/imhobags itemButtonSkin simple" },
				},
			},
			{
				description = L.Ux.ConfigWindow.showBoundIcon,
				config = "showBoundIcon",
				height = 191,
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
				height = 150,
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
				height = 170,
				options = {
					{ true, "textures/ConfigWindow/enhanceTooltips.png", "/imhobags enhanceTooltips yes/no" },
				},
			},
			{
				description = L.Ux.ConfigWindow.showEmptySlots,
				config = "showEmptySlots",
				height = 87,
				options = {
					{ true, "textures/ConfigWindow/showEmptySlots.png", "/imhobags showEmptySlots yes/no" },
				},
			},
		},
	},
}
local bottomPanes = {
	{
		name = "Known Issues",
		content = {
			{ description = "Annotations:", },
			{ description = "<font color='#FF0000'>[!]</font>: Critical issue which is being actively worked on.", },
			{ description = "<font color='#FFFF00'>[Rift API]</font>: Requires changes or additions to the Rift API in order to be possible.", },
			{ description = "<font color='#FF8000'>[Rift Bug]</font>: Is broken due to an internal bug in Rift and requires an official Rift patch.", },
			"separator",
			
			{ description = "<font color='#FF0000'>[!]</font> After a few hours of playing loading screens may cause performance errors.", },
			{ description = "<font color='#FF0000'>[!]</font> Opening big containers may cause performance warnings.", },
			{ description = "Condensing of full stacks is currently disabled.", },
			{ description = "Cooldowns are missing.", },
			{ description = "<font color='#FFFF00'>[Rift API]</font> Visual indicator for new items is missing.", },
			{ description = "The mail database is cleared everytime the Trion mail window is opened.", },
			{ description = "Some items may not show up in the item windows due to broken values in the API.", },
			{ description = "<font color='#FF8000'>[Rift Bug]</font> Equipped and wardrobe items cannot be draged until the character/wardrobe window has been opened at least once with the respective set.", },
			{ description = "<font color='#FF8000'>[Rift Bug]</font> Item tooltips triggered by the Addons are display in the top left corner of the screen.", },
			{ description = "<font color='#FF8000'>[Rift Bug]</font> Tooltip summaries don't display for comparison and chat link tooltips.", },
			{ description = "<font color='#FFFF00'>[Rift API]</font> The native Trion windows cannot be hidden.", },
			{ description = "The stack grouping feature is currently disabled.", },
			{ description = "Tracking of mailbox items is currently disabled.", },
		},
	},
	{
		name = "Help",
		content = {
			{
				description = "Help string",
				height = 132,
				options = {
					{ true, "textures/ConfigWindow/help_sort_menu.png" },
				},
				list = {
					{ "Alphabetically.\n<font color='#C0C0C0'>Sorts items from left to right alphabetically. The order depends on the sort algorithm implemented by the game's localization.</font>", "ImhoBags", "textures/icon_menu_sort_name.png" },
					{ "Texture.\n<font color='#C0C0C0'>Sorts items by the file name of their in-game icon texture. This has the chance of grouping similar items together.</font>\n", "ImhoBags", "textures/icon_menu_sort_icon.png" },
					{ "Rarity.\n<font color='#C0C0C0'>Sorts items by their rarity from left to right in the order: <font color='#FFFF00'>quest</font>, <font color='#FF8000'>relic</font>, <font color='#AC47F9'>epic</font>, <font color='#257EF9'>rare</font>, <font color='#00CB00'>uncommon</font>, <font color='#C0C0C0'>common</font>, <font color='#808080'>junk</font>.</font>", "ImhoBags", "textures/icon_menu_sort_rarity.png" },
					{ "None.\n<font color='#C0C0C0'>Does not apply any sorting. The items are displayed from left to right in the same order as they appear in the game's default bag windows.</font>", "ImhoBags", "textures/icon_menu_bags.png" },
				}
			},
		},
	},
}
if(string.find(Addon.toc.Version, "alpha")) then
	table.insert(bottomPanes[1].content, 1, { description = "<font color='#FF8000'>This is an ALPHA development version of ImhoBags and not intended for release. It may be broken, have errors or not work at all. You have been warned.</font>" })
end
-- Private methods
-- ============================================================================

local slashTooltip = UI.CreateFrame("Text", "", Ux.TooltipContext)
slashTooltip:SetVisible(false)
slashTooltip:SetFontSize(12)
slashTooltip:SetBackgroundColor(0, 0, 0, 0.75)

local function createHighlightedTexture(parent, path, tooltip)
	local icon = UI.CreateFrame("Texture", "", parent)
	icon:SetTexture("ImhoBags", path)
	if(type(tooltip) == "string") then
		local highlight = UI.CreateFrame("Texture", "", parent)
		highlight:SetTextureAsync("ImhoBags", "textures/highlight.png")
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
	end
	
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

local function createPaneButton(self, pane, name, previous, down)
	local button = UI.CreateFrame("RiftButton", "", self)
	button:SetText(name)
	name = string.upper(name)
	function button.Event.LeftPress()
		for k, v in pairs(self.panes) do
			if(v == pane) then
				v:FadeIn()
			else
				v:FadeOut()
			end
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
		if(down) then
			button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT")
			button:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT")
		else
			button:SetPoint("BOTTOMLEFT", previous, "TOPLEFT")
			button:SetPoint("BOTTOMRIGHT", previous, "TOPRIGHT")
		end
	else
		if(down) then
			button:SetPoint("TOPLEFT", self, "TOPLEFT", 3, 25)
		else
			button:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 3, -contentPadding)
		end
	end
	return button
end

local function createSeparator(content, parent, dy)
	local separator = UI.CreateFrame("Texture", "", parent)
	separator:SetTexture("Rift", "header_divider.png.dds")
	separator:SetPoint("TOPLEFT", parent, "TOPLEFT", contentPadding, dy)
	separator:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -contentPadding, dy)
	separator:SetHeight(separator:GetHeight() * separator:GetWidth() / 512) -- Unscaled texture width is 512
	return separator and separator:GetHeight() or 0
end

local function createList(list, parent, dy)
	local bullets = { }
	local labels = { }
	local bulletsWidth = 0
	local dyStart = dy
	for i = 1, #list do
		local entry = list[i]
		local label = UI.CreateFrame("Text", "", parent)
		labels[i] = label
		label:SetWordwrap(true)
		label:SetPoint("RIGHT", parent, "RIGHT", -contentPadding, nil)
		label:SetText("", true)
		if(#entry > 1) then
			local bullet = UI.CreateFrame("Texture", "", parent)
			bullets[i] = bullet
			bullet:SetTexture(entry[2], entry[3])
			bulletsWidth = math.max(bulletsWidth, bullet:GetWidth())
		end
	end
	
	for i = 1, #list do
		local bullet = bullets[i]
		local label = labels[i]
		label:SetPoint("RIGHT", parent, "RIGHT", -contentPadding, nil)
		label:SetPoint("LEFT", parent, "LEFT", contentPadding + bulletsWidth + (bulletsWidth > 0 and contentPadding / 2 or 0), nil)
		label:SetText(list[i][1], true)
		if(bullet) then
			bullet:SetPoint("TOPLEFT", parent, "TOPLEFT", contentPadding, dy)
			if(label:GetHeight() > bullet:GetHeight()) then
				label:SetPoint("TOP", parent, "TOP", nil, dy)
			else
				label:SetPoint("CENTERY", bullet, "CENTERY")
			end
			dy = dy + math.max(label:GetHeight(), bullet:GetHeight())
		else
			label:SetPoint("TOP", parent, "TOP", nil, dy)
			dy = dy + label:GetHeight()
		end
		dy = dy-- + contentPadding / 2
	end
	return dy - dyStart
end

local function createContent(content, parent, dy)
	if(content == "separator") then
		return createSeparator(content, parent, dy)
	else
		local description = UI.CreateFrame("Text", "", parent)
		description:SetWordwrap(true)
		description:SetPoint("TOPLEFT", parent, "TOPLEFT", contentPadding, dy + contentPadding / 2)
		description:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -contentPadding, dy + contentPadding / 2)
		description:SetText("", true)
		description:SetText(content.description or "", true)
		
		local options = content.options or { }
		local pictures = { }
		local isOption = #options > 0 and options[1][3] ~= nil
		for i = 1, #options do
			pictures[i] = createHighlightedTexture(parent, content.options[i][2], content.options[i][3])
			if(isOption) then
				pictures[i]:SetChecked(Config[content.config] == content.options[i][1])
			end
		end
		if(#pictures == 1) then
			pictures[1]:SetPoint("TOPCENTER", description, "BOTTOMCENTER")
			if(isOption) then
				pictures[1].Event.LeftDown = function(self) Config[content.config] = not self:GetChecked() end
			end
		elseif(#pictures == 2) then
			pictures[1]:SetPoint("TOPLEFT", description, "BOTTOMLEFT")
			pictures[2]:SetPoint("TOPRIGHT", description, "BOTTOMRIGHT")
			if(isOption) then
				pictures[1].Event.LeftDown = function(self) Config[content.config] = content.options[1][1] end
				pictures[2].Event.LeftDown = function(self) Config[content.config] = content.options[2][1] end
			end
		end

		if(isOption) then
			ImhoEvent.Config[#ImhoEvent.Config + 1] = { function(k, v)
				if(k == content.config) then
					for i = 1, #pictures do
						pictures[i]:SetChecked(v == content.options[i][1])
					end
				end
			end , Addon.identifier, "" }
		end
		
		local offset = contentPadding / 2 + description:GetHeight() + (content.height or 0)
		
		local list
		if(content.list) then
			createList(content.list, parent, dy + offset)
		end

		return contentPadding / 2 + offset + (list and list:GetHeight() or 0)
	end
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
	Ux.RiftWindowCloseButton.New(self, self, true)
	
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
		self.panes[#self.panes + 1] = createPane(topPanes[i], backdrop)
	end
	for i = 1, #bottomPanes do
		self.panes[#self.panes + 1] = createPane(bottomPanes[i], backdrop)
	end
	
	-- Pane selection buttons
	self.buttons = { }
	for i = 1, #topPanes do
		self.buttons[#self.buttons + 1] = createPaneButton(self, self.panes[#self.buttons + 1], topPanes[i].name, self.buttons[#self.buttons], true)
	end
	for i = 1, #bottomPanes do
		local count = #topPanes + #bottomPanes
		self.buttons[count - i + 1] = createPaneButton(self, self.panes[#topPanes + i], bottomPanes[i].name, self.buttons[count - i + 2], false)
	end

	self.buttons[1].Event.LeftPress(self.buttons[1])
	
	-- Get rid of the no longer needed tables
	topPanes = nil
	bottomPanes = nil
end
