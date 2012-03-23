local Addon, private = ...-- Builtinslocal floor = math.floorlocal strupper = string.upperlocal unpack = unpack-- Globalslocal Inspect = Inspectlocal UICreateFrame = UI.CreateFramelocal UIParent = UIParentlocal contentPadding = 10local headingColor = { 216 / 255, 203 / 255, 153 / 255 }setfenv(1, private)Ux = Ux or { }-- Private methods-- ============================================================================local slashTooltip = UICreateFrame("Text", "", Ux.TooltipContext)slashTooltip:SetVisible(false)slashTooltip:SetFontSize(12)slashTooltip:SetBackgroundColor(0, 0, 0, 0.75)local function createHighlightedTexture(parent, path, tooltip)	local icon = UICreateFrame("Texture", "", parent)	icon:SetTexture("ImhoBags", path)	local highlight = UICreateFrame("Texture", "", parent)	highlight:SetTexture("ImhoBags", "textures/ItemButton/highlight.png")	highlight:SetAllPoints(icon)	highlight:SetVisible(false)	icon:SetLayer(highlight:GetLayer() + 1)	function icon.Event:MouseIn()		highlight:SetVisible(true)		highlight:SetAlpha(1.0)		if(Ux.ConfigWindow.showSlashTooltips) then			slashTooltip:SetVisible(true)			slashTooltip:ClearAll()			slashTooltip:SetText(tooltip)		end		self.Event.MouseMove(self)	end	function icon.Event:MouseMove()		local mouse = Inspect.Mouse()		slashTooltip:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", mouse.x, mouse.y)	end	function icon.Event:MouseOut()		if(self.checked) then			highlight:SetAlpha(0.7)		else			highlight:SetVisible(false)		end		slashTooltip:SetVisible(false)	end	function icon:SetChecked(checked)		self.checked = checked		if(checked) then			highlight:SetAlpha(0.7)			highlight:SetVisible(true)		else			highlight:SetAlpha(1.0)			highlight:SetVisible(false)		end	end		return iconendlocal function content_MouseMove(self)	local mouse = Inspect.Mouse()	if(self.mouseOffsetX) then		self.window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", mouse.x - self.mouseOffsetX, mouse.y - self.mouseOffsetY)	endendlocal function content_LeftDown(self)	local mouse = Inspect.Mouse()	local left, top, right, bottom = self.window:GetTrimDimensions()	self.mouseOffsetX = floor(mouse.x - self.window:GetLeft())	self.mouseOffsetY = floor(mouse.y - self.window:GetTop())endlocal function content_LeftUpoutside(self)	self.mouseOffsetX, self.mouseOffsetY = nil, nilendlocal function content_LeftUp(self)	content_LeftUpoutside(self)endlocal function makeMovable(self)	local content = self:GetContent()	content.window = self	content.Event.MouseMove = content_MouseMove	content.Event.LeftDown = content_LeftDown	content.Event.LeftUp = content_LeftUp	local border = self:GetBorder()	border.window = self	border.Event.MouseMove = content_MouseMove	border.Event.LeftDown = content_LeftDown	border.Event.LeftUp = content_LeftUp	border.Event.LeftUpoutside = content_LeftUpoutsideend-- Public methods-- ============================================================================function Ux.ConfigWindow()	local self = UICreateFrame("RiftWindow", "", Ux.Context)	self:SetTitle(L.Ux.ConfigWindow.title)	self:SetController("content")	self:SetWidth(500)	Ux.ConfigWindow = self	makeMovable(self)	self.showSlashTooltips = false		-- Close button	Ux.RiftWindowCloseButton.New(self, self)		-- Section headline	self.heading = UICreateFrame("Text", "", self)	self.heading:SetText(strupper(L.Ux.ConfigWindow.appearanceSection))	self.heading:SetFontSize(18)	self.heading:SetFontColor(unpack(headingColor))	self.heading:SetPoint("TOPLEFT", self, "TOPLEFT", 30, 0)	self.underline = UICreateFrame("Texture", "", self)	self.underline:SetTexture("ImhoBags", "textures/hr1.png")	self.underline:SetWidth(350)	self.underline:SetHeight(self.underline:GetTextureHeight())	self.underline:SetPoint("TOPLEFT", self.heading, "BOTTOMLEFT", -30, -3)	self.underline:SetLayer(2)		-- Slash tooltip checkbox	local tooltipCheck = Ux.Checkbox.New(self, L.Ux.ConfigWindow.showTooltips, "LEFT")	tooltipCheck:SetPoint("TOPRIGHT", self, "TOPRIGHT", -contentPadding, contentPadding / 2)	tooltipCheck.Event.CheckboxChange = function() self.showSlashTooltips = tooltipCheck:GetChecked() end		-- Condensed config	local backdrop = UICreateFrame("Frame", "", self)	backdrop:SetPoint("TOPLEFT", self, "TOPLEFT", contentPadding, 25)	backdrop:SetPoint("TOPRIGHT", self, "TOPRIGHT", -contentPadding, 25)	backdrop:SetBackgroundColor(0, 0, 0, 0.5)		local description = UICreateFrame("Text", "", backdrop)	description:SetWordwrap(true)	description:SetPoint("TOPLEFT", backdrop, "TOPLEFT", contentPadding, contentPadding / 2)	description:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -contentPadding, contentPadding / 2)	description:SetText(L.Ux.ConfigWindow.condensed)	local condensed_y = createHighlightedTexture(backdrop, "textures/ConfigWindow/condensed yes.png", "/imhobags condensed yes")	condensed_y:SetPoint("TOPLEFT", description, "BOTTOMLEFT")	local condensed_n = createHighlightedTexture(backdrop, "textures/ConfigWindow/condensed no.png", "/imhobags condensed no")	condensed_n:SetPoint("TOPRIGHT", description, "BOTTOMRIGHT")		condensed_y:SetChecked(Config.condensed == true)	condensed_n:SetChecked(Config.condensed == false)	function condensed_y.Event:LeftDown() self:SetChecked(true) condensed_n:SetChecked(false) Config.condensed = true end	function condensed_n.Event:LeftDown() self:SetChecked(true) condensed_y:SetChecked(false) Config.condensed = false end		-- Group packing option	description = UICreateFrame("Text", "", backdrop)	description:SetWordwrap(true)	description:SetPoint("TOPLEFT", condensed_y, "BOTTOMLEFT", 0, contentPadding)	description:SetPoint("TOPRIGHT", condensed_n, "BOTTOMRIGHT", 0, contentPadding)	description:SetText(L.Ux.ConfigWindow.packGroups)		local packGroups_y = createHighlightedTexture(backdrop, "textures/ConfigWindow/packGroups yes.png", "/imhobags packGroups yes")	packGroups_y:SetPoint("TOPLEFT", description, "BOTTOMLEFT")	local packGroups_n = createHighlightedTexture(backdrop, "textures/ConfigWindow/packGroups no.png", "/imhobags packGroups no")	packGroups_n:SetPoint("TOPRIGHT", description, "BOTTOMRIGHT")		packGroups_y:SetChecked(Config.packGroups == true)	packGroups_n:SetChecked(Config.packGroups == false)	function packGroups_y.Event:LeftDown() self:SetChecked(true) packGroups_n:SetChecked(false) Config.packGroups = true end	function packGroups_n.Event:LeftDown() self:SetChecked(true) packGroups_y:SetChecked(false) Config.packGroups = false end		-- Item button skin option	description = UICreateFrame("Text", "", backdrop)	description:SetWordwrap(true)	description:SetPoint("TOPLEFT", packGroups_y, "BOTTOMLEFT", 0, contentPadding)	description:SetPoint("TOPRIGHT", packGroups_n, "BOTTOMRIGHT", 0, contentPadding)	description:SetText(L.Ux.ConfigWindow.itemButtonSkin)		local itemButtonSkin_pretty = createHighlightedTexture(backdrop, "textures/ConfigWindow/itemButtonSkin pretty.png", "/imhobags itemButtonSkin pretty")	itemButtonSkin_pretty:SetPoint("TOPLEFT", description, "BOTTOMLEFT")	local itemButtonSkin_simple = createHighlightedTexture(backdrop, "textures/ConfigWindow/itemButtonSkin simple.png", "/imhobags itemButtonSkin simple")	itemButtonSkin_simple:SetPoint("TOPRIGHT", description, "BOTTOMRIGHT")	backdrop:SetHeight(itemButtonSkin_simple:GetBottom() - backdrop:GetTop() + contentPadding)		itemButtonSkin_pretty:SetChecked(Config.itemButtonSkin == "pretty")	itemButtonSkin_simple:SetChecked(Config.itemButtonSkin == "simple")	function itemButtonSkin_pretty.Event:LeftDown() self:SetChecked(true) itemButtonSkin_simple:SetChecked(false) Config.itemButtonSkin = "pretty" end	function itemButtonSkin_simple.Event:LeftDown() self:SetChecked(true) itemButtonSkin_pretty:SetChecked(false) Config.itemButtonSkin = "simple" end	backdrop:SetHeight(itemButtonSkin_simple:GetBottom() - backdrop:GetTop() + contentPadding)	self:SetHeight(backdrop:GetBottom() - backdrop:GetTop() + contentPadding + 25)end