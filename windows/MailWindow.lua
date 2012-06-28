local Addon, private = ...

-- Builtins
local floor = math.floor
local format = string.format
local max = math.max
local pairs = pairs
local strfind = string.find
local strlower = string.lower
local sort = table.sort

-- Globals
local Inspect = Inspect
local UICreateFrame = UI.CreateFrame

-- Frames cannot be deleted, keep a cache and only create new frames if the cache is empty
local cachedLabels = { }

setfenv(1, private)
Ux = Ux or { }
Ux.MailWindow = { }

-- Private methods
-- ============================================================================

local function createLabel(self)
	local label = UICreateFrame("Text", "", self.itemsContainer)
	label:SetText("")
	label:SetWordwrap(true)
	label:SetFontSize(14)
	label:SetBackgroundColor(1, 1, 1, 0.1)
	function label:Dispose()
		self:SetVisible(false)
		cachedLabels[#cachedLabels + 1] = self
	end
	function label:SetInfo(sell, slots)
	end
	-- Show mail body
	label.bodyIndicator = UICreateFrame("Texture", "", label)
	label.bodyIndicator:SetPoint("TOPLEFT", label, "TOPLEFT")
	label.bodyIndicator:SetTexture("Rift", [[Data/\UI\item_icons\charcoal_and_parchment.dds]])
	label.bodyIndicator:SetWidth(18)
	label.bodyIndicator:SetHeight(18)
	label.bodyIndicator:SetAlpha(0.7)
	-- CoD label
	label.cod = UICreateFrame("Text", "", label)
	label.cod:SetText(L.Ux.cashOnDelivery .. ": ")
	label.cod:SetFontSize(12)
	label.cod:SetFontColor(1.0, 1.0, 0)
	label.cod:SetPoint("BOTTOMLEFT", label, "BOTTOMLEFT")
	-- CoD money
	label.codMoney = Ux.MoneyFrame.New(label.cod)
	label.codMoney:SetPoint("LEFTCENTER", label.cod, "RIGHTCENTER")
	-- Highlight
	label.highlight = UICreateFrame("Texture", "", label)
	label.highlight:SetAllPoints()
	label.highlight:SetTexture("ImhoBags", "textures/ItemButton/highlight.png")
	label.highlight:SetVisible(false)
	label.highlight:SetAlpha(0.5)
	label.Event.LeftDown = function()
		if(label.body and label.body ~= "")
			then self:showBodyText(label)
		end
	end
	label.Event.MouseIn = function()
		if(self.showBodyLabel == label) then
			label.highlight:SetAlpha(0.5)
		else
			label.highlight:SetVisible(label.body and label.body ~= "")
		end
	end
	label.Event.MouseOut = function()
		if(self.showBodyLabel == label) then
			label.highlight:SetAlpha(0.3)
		else
			label.highlight:SetVisible(false)
		end
	end
	return label
end

local function getGroupLabel(self, mail)
	local label
	if(#cachedLabels == 0) then
		label = createLabel(self)
	else
		label = cachedLabels[#cachedLabels]
		cachedLabels[#cachedLabels] = nil
		label:SetVisible(true)
		label:SetParent(self.itemsContainer)
	end
	label:SetText(format("\t%s: %s", mail[2].from, mail[2].subject))
	if(mail[2].cod) then
		label.cod:SetVisible(true)
		label.codMoney:SetCoin(mail[2].cod)
		label:SetHeight(label:GetFullHeight() + label.cod:GetFullHeight())
	else
		label.cod:SetVisible(false)
		label:SetHeight(label:GetFullHeight())
	end
	label.body = mail[2].body
	if(label.body and label.body ~= "") then
--		label:SetFontColor(1, 0.8, 0)
		label.bodyIndicator:SetVisible(true)
	else
--		label:SetFontColor(1, 1, 1)
		label.bodyIndicator:SetVisible(false)
	end
	return label, self.itemSize, self.itemSize
end

local empty = { }
local function sortGroups(self)
	local function getItems(mail)
		for k, v in pairs(self.groupKeys) do
			if(v == mail) then
				return k
			end
		end
		return empty
	end
	
	self.sortedMails = { }
	for mail, data in pairs(self.mails) do
		self.sortedMails[#self.sortedMails + 1] = { self.mailSortKey(data), data, getItems(data) }
	end
	sort(self.sortedMails, function(a, b) return a[1] < b[1] end)
end

local function sortItems(self)
	for i = 1, #self.groups do
		sort(self.groups[i], function(a, b) return self.sortFunc(a.type, b.type) end)
	end
end

local function getGroups(self)
	self.groups, self.groupKeys = ItemDB.GetGroupedItems(self.items, self.groupFunc)
	self.mails = self.matrix:GetUnsortedMails()

	sortGroups(self)
	sortItems(self)
end

local function getIndices(self)
	local indices = { }
	for i = 1, #self.sortedMails do
		indices[#indices + 1] = i
		indices[#indices + 1] = 0
	end
	if(#indices > 0) then
		indices[#indices] = nil -- Remove last line break
	end
	return indices
end

local function iterateGroups(self)
	local indices = getIndices(self)
	local i, n = 1, #indices
	local f = function(self)
		if(i > n) then
			return nil
		else
			local index = indices[i]
			i = i + 1
			if(index < 1) then
				return false
			else
				local mail = self.sortedMails[index]
				return mail, mail[3]
			end
		end
	end
	return f, self
end

local function leftUp(self)
end

local function setCharacter(self)
	self.bodyFrame:SetText("")
	self.bodyFrame:SetVisible(false)
end

local function onClose(self)
	self.bodyFrame:SetText("")
	self.bodyFrame:SetVisible(false)
end

local function showBodyText(self, label)
	if(self.showBodyLabel) then
		self.showBodyLabel.highlight:SetVisible(false)
		self.showBodyLabel.highlight:SetAlpha(0.5)
	end
	if(self.showBodyLabel ~= label) then
		self.bodyFrame:SetText(label.body)
		self.bodyFrame:SetVisible(true)
		self.showBodyLabel = label
	else
		
		if(self.showBodyLabel == label) then
			self.bodyFrame:SetVisible(false)
			self.showBodyLabel = nil
		else
			self.bodyFrame:SetText(label.body)
			self.showBodyLabel = label
		end
	end
	if(self.showBodyLabel) then
		self.showBodyLabel.highlight:SetVisible(true)
		self.showBodyLabel.highlight:SetAlpha(0.3)
	end
end

local function applySearchFilter(self)
	self:base_applySearchFilter()
	
	-- Search in mail subject and body
	if(self.searchString == "") then
		for i = 1, #self.groupLabels do
			self.groupLabels[i]:SetBackgroundColor(1, 1, 1, 0.1)
		end
	else
		for i = 1, #self.groupLabels do
			local label = self.groupLabels[i]
			if(strfind(label:GetText(), self.searchString) or strfind(label.body, self.searchString)) then
				label:SetBackgroundColor(0, 1, 0, 0.1)
			else
				label:SetBackgroundColor(1, 1, 1, 0.1)
			end
		end
	end
end

local function getContentPadding(self)
	return 0, 0, 0, 0
end

local function content_LeftDown(self)
	local mouse = Inspect.Mouse()
	local left, top, right, bottom = self.window:GetTrimDimensions()
	self.mouseOffsetX = floor(mouse.x - self.window:GetLeft())
	self.mouseOffsetY = floor(mouse.y - self.window:GetTop())
end

local function setItemsContentHeight(self, height)
	self.itemsContainer:SetHeight(height)
end

local function scrollBarChanged(self)
	local window = self:GetParent()
	local offset = floor(self:GetPosition())
	window.itemsContainer:SetPoint("TOPLEFT", window.mask, "TOPLEFT", 0, -offset)
	window.itemsContainer:SetPoint("TOPRIGHT", window.mask, "TOPRIGHT", 0, -offset)
end

local function contentSizeChanged(self)
	local window = self:GetParent():GetParent()
	local h = window.itemsContainer:GetHeight() - window.mask:GetHeight()
	window.scrollbar:SetEnabled(h > 0)
	if(h > 0) then
		window.scrollbar:SetRange(0, h)
		window.scrollbar:SetPosition(0)
	end
end

-- Public methods
-- ============================================================================

local function MailWindow_Update(self)
	self:base_Update()
	self:SetTitle(format("%s: %s", self.character == "player" and PlayerName or self.character, self.title))
end

function Ux.MailWindow.New(title, character, location, itemSize, sorting)
	-- Sort mail by name
	local self = Ux.ItemWindowBase.New(title, character, location, itemSize, "name")
	self:SetTitle(self.title)
	
	self.mailButton:SetIcon([[Data/\UI\item_icons\bag20.dds]])
	self.mailButton:SetTooltip(L.Ux.WindowTitle.inventory)
	function self.mailButton.LeftPress()
		Ux.ToggleItemWindow(self.charSelector:GetText(), "inventory")
	end
	
	local left, top, right, bottom = self:getContentPadding()
	local borderLeft, borderTop, borderRight, borderBottom = self:GetTrimDimensions()
	
	-- Hide money frame
	self.coinFrame:SetVisible(false)
	self.filter:SetPoint("BOTTOMRIGHT", self.coinFrame, "BOTTOMRIGHT", 0, 2)

	-- Create side window with mail body text
	self.bodyFrame = UICreateFrame("Mask", "", self)
	self.bodyFrame:SetPoint("TOPLEFT", self, "TOPRIGHT", borderRight - 6, top)
	self.bodyFrame:SetWidth(330)
	self.bodyFrame:SetHeight(300)
	self.bodyFrame:SetBackgroundColor(0, 0, 0, 0.8)
	self.bodyFrame:SetVisible(false)
	local bodyscroll = UICreateFrame("RiftScrollbar", "", self.bodyFrame)
	bodyscroll:SetPoint("TOPRIGHT", self.bodyFrame, "TOPRIGHT")
	bodyscroll:SetPoint("BOTTOMRIGHT",self.bodyFrame, "BOTTOMRIGHT")
	local bodytxt = UICreateFrame("Text", "", self.bodyFrame)
	bodytxt:SetPoint("TOPLEFT", self.bodyFrame, "TOPLEFT", 0, 0)
	bodytxt:SetPoint("TOPRIGHT", self.bodyFrame, "TOPRIGHT", -bodyscroll:GetWidth(), 0)
	bodytxt:SetFontSize(13)
	bodytxt:SetWordwrap(true)
	function self.bodyFrame:SetText(txt)
		bodytxt:SetText(txt)
		local h = bodytxt:GetHeight() - self:GetHeight()
		bodyscroll:SetEnabled(h > 0)
		if(h > 0) then
			bodyscroll:SetRange(0, h)
		else
			bodyscroll:SetRange(0, 1)
		end
		bodyscroll:SetPosition(0)
	end
	function bodyscroll.Event.ScrollbarChange()
		bodytxt:SetPoint("TOPLEFT", self.bodyFrame, "TOPLEFT", 0, -bodyscroll:GetPosition())
		bodytxt:SetPoint("TOPRIGHT", self.bodyFrame, "TOPRIGHT", -bodyscroll:GetWidth(), -bodyscroll:GetPosition())
	end
	
	self.showBodyText = showBodyText
	self.showBodyLabel = nil
	
	-- Scrollbar
	self.scrollbar = UICreateFrame("RiftScrollbar", "", self)
	self.scrollbar:SetPoint("TOPRIGHT", self.filter, "BOTTOMRIGHT", -Ux.ItemWindowPadding, Ux.ItemWindowPadding)
	self.scrollbar:SetPoint("BOTTOMRIGHT", self:GetContent(), "BOTTOMRIGHT", -Ux.ItemWindowPadding, 0)
	self.scrollbar.Event.ScrollbarChange = scrollBarChanged
	self.scrollbar:SetLayer(10)
	
	-- Content mask and item container
	self.mask = UICreateFrame("Mask", "", self)
	self.mask:SetPoint("TOPLEFT", self, "TOPLEFT", left, top)
	self.mask:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -(right + self.scrollbar:GetWidth()), -bottom)
	self.mask.Event.WheelBack = function() self.scrollbar:NudgeDown() end
	self.mask.Event.WheelForward = function() self.scrollbar:NudgeUp() end
	self.mask:SetMouseMasking("limited")
	self.mask:SetLayer(10)
	self.itemsContainer = UICreateFrame("Frame", "", self.mask)
	self.itemsContainer:SetPoint("TOPLEFT", self.mask, "TOPLEFT", 0, 0)
	self.itemsContainer:SetPoint("TOPRIGHT", self.mask, "TOPRIGHT", 0, 0)
	self.itemsContainer.Event.Size = contentSizeChanged
	
	-- Set width to a fixed value and disable resizing
	self:SetWidth(self:columnsWidth(7) + left + right)
	self.SetWidth = function() end
	self:GetBorder().Event.LeftDown = content_LeftDown
	self:GetContent().Event.LeftDown = content_LeftDown

	self.base_applySearchFilter = self.applySearchFilter
	self.applySearchFilter = applySearchFilter
	self.base_getContentPadding = self.getContentPadding
	self.getContentPadding = getContentPadding
	self.base_Update = self.Update
	self.Update = MailWindow_Update
	self.setItemsContentHeight = setItemsContentHeight
	self.onClose = onClose
	self.getGroups = getGroups
	self.leftUp = leftUp
	self.setCharacter = setCharacter
	self.getGroupLabel = getGroupLabel
	self.iterateGroups = iterateGroups

	self.groupFunc = Group.Default.GetMail
	self.groupSortFunc = Group.Default.SortByCategoryKey
	self.sortFunc = Sort.Default.ByItemName
	self.mailSortKey = function(mail) return strlower(mail.from .. ": " .. mail.subject) end
	
	self:SetCharacter(character, "mail")
	
	return self
end
