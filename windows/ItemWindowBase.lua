local Addon, private = ...

-- Builtins
local ceil = math.ceil
local coroutine = coroutine
local floor = math.floor
local format = string.format
local max = math.max
local min = math.min
local mod = math.mod
local strfind = string.find
local strgsub = string.gsub
local strlower = string.lower
local strupper = string.upper
local tonumber = tonumber
local type = type

-- Globals
local Command = Command
local Event = Event
local Inspect = Inspect
local UI = UI
local UIParent = UIParent

setfenv(1, private)
Ux = Ux or { }
Ux.ItemWindowBase = { }

Ux.ItemWindowColumns = 8
Ux.ItemWindowPadding = 4
Ux.ItemWindowCellSpacing = 2
Ux.ItemWindowFilterHeight = 24
Ux.ItemWindowMinWidth = 345 -- Prevents header buttons from overlapping and is lower bound for full columns
Ux.ItemWindowMinHeight = 310 -- Title bar stats resizing below this content size
Ux.ItemWindowUpateStep = 0.010 -- After how many seconds does the update function yield?

-- Private methods
-- ============================================================================

local function clearGroupLabels(self)
	-- Clear all groups and buttons and return them to cache
	for i = 1, #self.groupLabels do
		self.groupLabels[i]:Dispose()
	end
	self.groupLabels = { }
end

local function isAvailable(self)
	-- Non-player characters always report a number as empty slots.
	-- Whereas the player gets a list of all empty slot ids
	return type(self.empty) == "table" and self.interaction
end

local function getItems(self)
	local success
	if(self.enemy) then
		self.items, self.empty, success = self.matrix:GetUnsortedItems(Config.condensed, Config.showEnemyFaction == "account")
	else
		self.items, self.empty, success = self.matrix:GetUnsortedItems(Config.condensed)
	end
	if(success) then
		self.getItemFailed = 0
	else
		self.getItemFailed = self.getItemFailed + 1
	end
	self:getGroups()
end

local function closeButton_LeftPress(self)
	local window = self:GetParent()
	window:SetVisible(false)
	window.filter.text:SetKeyFocus(false)
	window:onClose()
	log("TODO", "close the native frame(s)")
end

local function systemUpdateBegin(self)
	-- Inspect.Time.Frame() is not good enough and can cause multiple updates per frame
	local now = Inspect.Time.Real()
	if(self.matrix.lastUpdate >= self.lastUpdate) then
		getItems(self)
		self:Update()
		self.lastUpdate = now
		log("update", self:GetTitle(), self.lastUpdate)
	elseif(self.getItemFailed > 0 and (now - self.lastUpdate > 1)) then
		log("getItemFailed", self:GetTitle(), self.getItemFailed)
		getItems(self)
		-- Limit the number of retries to avoid permanent performance drops
		if(self.getItemFailed > 3) then
			log("getItemFailed", self:GetTitle(), "giving up")
			self.getItemFailed = 0
		end
		self:Update()
		self.lastUpdate = now
		log("update", self:GetTitle(), self.lastUpdate)
	end
	
	if(self.updateCoroutine) then
		local result = coroutine.resume(self.updateCoroutine, self, now)
		if(coroutine.status(self.updateCoroutine) == "dead") then
			self.updateCoroutine = nil
		end
	end
end

local function content_MouseMove(self)
	local mouse = Inspect.Mouse()
	if(self.sizingOffset) then
		self.window:SetWidth(max(Ux.ItemWindowMinWidth, mouse.x - self.window:GetLeft() + self.sizingOffset))
		self.window:Update()
	elseif(self.mouseOffsetX) then
		self.window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", mouse.x - self.mouseOffsetX, mouse.y - self.mouseOffsetY)
	end
end

local function content_LeftDown(self)
	local mouse = Inspect.Mouse()
	local left, top, right, bottom = self.window:GetTrimDimensions()
	if(mouse.x > self.window:GetRight() - right - Ux.ItemWindowPadding and mouse.y > self.window:GetTop() + top) then
		self.sizingOffset = self.window:GetRight() - mouse.x
	else
		self.mouseOffsetX = floor(mouse.x - self.window:GetLeft())
		self.mouseOffsetY = floor(mouse.y - self.window:GetTop())
	end
end

local function content_LeftUpoutside(self)
	self.mouseOffsetX, self.mouseOffsetY = nil, nil
	self.sizingOffset = nil
end

local function content_LeftUp(self)
	content_LeftUpoutside(self)
	-- Drop item
	self.window:leftUp()
end

local function interactionChanged(self, interaction, state)
	if(interaction == self.location) then
		self.interaction = state
		self:Update()
	end
end

local function filter_KeyFocusGain(self, window)
	if(self:GetText() == L.Ux.search) then
		self:SetText("")
	end
end

local function filter_KeyFocusLoss(self, window)
	if(self:GetText() == "") then
		self:SetText(L.Ux.search)
	end
end

local function filter_TextfieldChange(self, window)
	-- Build a case-insensitive search pattern
	window.searchString = strgsub(self:GetText(), "%a", function(ch)
		return format("[%s%s]", strlower(ch), strupper(ch))
	end)

	window:applySearchFilter()
end

-- Protected methods
-- ============================================================================

local function configChanged(self, name, value)
	if(name == "condensed") then
		getItems(self)
		self:Update()
	elseif(name == "showBoundIcon") then
		self:Update()
	elseif(name == "showEnemyFaction") then
		if(self.enemy) then
			if(Config.showEnemyFaction == "no") then
				self:SetCharacter(PlayerName, self.location)
			else
				getItems(self)
				self:Update()
			end
		end
	end
end

local function applySearchFilter(self)
	if(self.searchString == "") then
		for i = 1, #self.buttons do
			self.buttons[i]:SetFiltered(false)
		end
	else
		for i = 1, #self.buttons do
			local button = self.buttons[i]
			button:SetFiltered(strfind(button.item.name, self.searchString) == nil)
		end
	end
end

local function getButton(self, content, index)
	if(not self.buttons[index]) then
		self.buttons[index] = Ux.ItemButton.New(content)
	end
	return self.buttons[index]
end

local function renderItems(self, items, left, x, y, width, dx, dy, spacing, content, available, buttons, endTime)
	local sell = 0
	local slots = 0
	local previous = false

	width = width + left
	for i = 1, #items do
		local item = items[i]
		local button = getButton(self, content, i + buttons)
		if(button:GetWidth() ~= dx) then
			button:SetWidth(dx)
		end
		if(button:GetHeight() ~= dy) then
			button:SetHeight(dy)
		end
		if(x + dx > width) then
			x = left
			y = y + dy + spacing
			button:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
			button.previous = nil
		elseif(not previous) then
			button:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
			button.previous = nil
		elseif(button.previous ~= previous) then
			button:SetPoint("TOPLEFT", previous, "TOPRIGHT", spacing, 0)
			button.previous = previous
		end
		previous = button
		button:SetItem(item.type, item.slots, item.stack, available)
		sell = sell + item.stack * (item.type.sell or 0)
		if(type(item.slots) == "table") then
			slots = slots + #item.slots
		else
			slots = slots + item.slots
		end
		x = x + dx + spacing

		if(Inspect.Time.Real() >= endTime) then
			log("coroutine.yield", buttons + i)
			coroutine.yield()
			endTime = Inspect.Time.Real() + Ux.ItemWindowUpateStep
		end
	
	end
	
	return x, y, sell, slots, endTime
end

local function update(self)
	clearGroupLabels(self)
	
	local available = isAvailable(self)
	local content = self.itemsContainer
	local contentRight = content:GetRight()
	
	local left, top, right, bottom = self:getContentPadding()
	local width = ceil(content:GetWidth() - left - right)
	
	local x, y = left, top
	local dx, dy = self.itemSize, self.itemSize
	local spacing = Ux.ItemWindowCellSpacing
	local buttons = 0
	local endTime = Inspect.Time.Real() + Ux.ItemWindowUpateStep

	local label
	for group, items in self:iterateGroups() do
		if(not group) then
			label:SetWidth(contentRight - label:GetLeft() - right)
			x = left
			y = y + dy + 2 * spacing + label:GetHeight()
		else
			label, dx, dy = self:getGroupLabel(group)
			self.groupLabels[#self.groupLabels + 1] = label
			label:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
			
			local x2, y2, sell, slots
			x2, y2, sell, slots, endTime = renderItems(self, items, left, x, y + label:GetHeight() + spacing, width, dx, dy, spacing, content, available, buttons, endTime)
			buttons = buttons + #items

			-- Insert empty gap between adjacent groups
			local w = max(x2 - x + dx + spacing, ceil(label:GetFullWidth() / (dx + spacing)) * (dx + spacing))
			label:SetWidth(min(w, width - x))
			y = y2 - label:GetHeight() - spacing
			x = x + w

			label:SetInfo(sell, slots)
		end
	end
	if(label) then
		label:SetWidth(contentRight - label:GetLeft() - right)
		y = y + label:GetHeight()
	end
	for i = buttons + 1, #self.buttons do
		self.buttons[i].previous = nil
		self.buttons[i]:Dispose()
		self.buttons[i] = nil
	end

	self:setItemsContentHeight(y + dy + bottom)
	self:applySearchFilter()
end

local function getContentPadding(self)
	return Ux.ItemWindowPadding, self.contentOffset, Ux.ItemWindowPadding, Ux.ItemWindowPadding
end

local function columnsWidth(self, cols)
	return cols * self.itemSize + (cols - 1) * Ux.ItemWindowCellSpacing
end

local function setItemsContentHeight(self, height)
	self:SetHeight(max(Ux.ItemWindowMinHeight, height))
end

-- Public methods
-- ============================================================================

local function ItemWindowBase_SetCharacter(self, character, location)
	if(character ~= self.character or location ~= self.location) then
		self.getItemFailed = 0
		self.matrix, self.enemy = ItemDB.GetItemMatrix(character, location)
		self.character = character
		self.location = location
		self.lastUpdate = -2
		self:setCharacter()
	end
end

local function ItemWindowBase_Update(self)
	self.updateCoroutine = coroutine.create(self.update)
end

local function ItemWindowBase_GetNumColumns(self)
	return floor((self:GetContent():GetWidth() - 2 * Ux.ItemWindowPadding + Ux.ItemWindowCellSpacing) / (self.itemSize + Ux.ItemWindowCellSpacing))
end

function Ux.ItemWindowBase.New(title, character, location, itemSize)
	local context = UI.CreateContext(Addon.identifier)
	local self = UI.CreateFrame("RiftWindow", "ImhoBags_ItemWindow_"..location, context)

	self.title = title
	self:SetController("content")
	self.itemsContainer = self:GetContent()
	self.itemSize = itemSize
	self.updateCoroutine = nil
	
	-- Close button
	Ux.RiftWindowCloseButton.New(self, closeButton_LeftPress)
	
	-- Char selector
	self.charSelector = Ux.OptionSelector.New(self, [[Data/\UI\ability_icons\combat_survival.dds]],
		L.Ux.Tooltip.character,
		ItemDB.GetAvailableCharacters,
		function(char)
			self:SetCharacter(char, self.location)
		end)
	self.charSelector:SetPoint("TOPLEFT", self:GetContent(), "TOPLEFT",Ux.ItemWindowPadding, -2)
	
	-- Tool buttons
	self.bankButton = Ux.IconButton.New(self, [[Data/\UI\item_icons\chest2.dds]], L.Ux.WindowTitle.bank)
	self.bankButton:SetPoint("TOPLEFT", self.charSelector, "TOPRIGHT", 2 * Ux.ItemWindowPadding, 0)
	function self.bankButton.LeftPress()
		Ux.ToggleItemWindow(self.character, "bank")
	end

	self.mailButton = Ux.IconButton.New(self, [[Data/\UI\item_icons\collection_of_love_letters.dds]], L.Ux.WindowTitle.mail)
	self.mailButton:SetPoint("TOPLEFT", self.bankButton, "TOPRIGHT")
	function self.mailButton.LeftPress()
		Ux.ToggleItemWindow(self.character, "mail")
	end

	self.equipmentButton = Ux.IconButton.New(self, [[Data/\UI\item_icons\1h_sword_065b.dds]], L.Ux.WindowTitle.equipment)
	self.equipmentButton:SetPoint("TOPLEFT", self.mailButton, "TOPRIGHT")
	function self.equipmentButton.LeftPress()
		Ux.ToggleItemWindow(self.character, "equipment")
	end

	self.wardrobeButton = Ux.IconButton.New(self, [[Data/\UI\item_icons\festival_hat_03.dds]], L.Ux.WindowTitle.wardrobe)
	self.wardrobeButton:SetPoint("TOPLEFT", self.equipmentButton, "TOPRIGHT")
	function self.wardrobeButton.LeftPress()
		Ux.ToggleItemWindow(self.character, "wardrobe")
	end

	self.currencyButton = Ux.IconButton.New(self, [[Data/\UI\item_icons\loot_gold_coins.dds]], L.Ux.WindowTitle.currency)
	self.currencyButton:SetPoint("TOPLEFT", self.wardrobeButton, "TOPRIGHT")
	function self.currencyButton.LeftPress()
		Ux.ToggleItemWindow(self.character, "currency")
	end
	
	self.guildButton = Ux.IconButton.New(self, PlayerFaction == "defiant" and [[Data/\UI\item_icons\GuildCharter_Defiants.dds]] or [[Data/\UI\item_icons\GuildCharter_Guardians.dds]], L.Ux.Tooltip.guild)
	self.guildButton:SetPoint("TOPLEFT", self.currencyButton, "TOPRIGHT")
	function self.guildButton.LeftPress()
		Ux.ToggleGuildWindow(self.character)
	end
	
	self.configButton = Ux.IconButton.New(self, [[Data/\UI\item_icons\small_student_experiment.dds]], L.Ux.Tooltip.config)
	self.configButton:SetPoint("TOPRIGHT", self:GetContent(), "TOPRIGHT", -Ux.ItemWindowPadding, -2)
	function self.configButton.LeftPress()
		Ux.ToggleConfigWindow()
	end
	
	self.sizeButton = Ux.OptionSelector.New(self, [[Data/\UI\ability_icons\warden-healing_flood_a.dds]],
		L.Ux.Tooltip.size,
		{ "30", "40", "50", "60" },
		function(size)
			self.itemSize = tonumber(size)
			self.sizeButton:SetStack(self.itemSize)
			self:Update()
		end)
	self.sizeButton:SetPoint("TOPRIGHT", self.configButton, "TOPLEFT", -Ux.ItemWindowPadding, 0)
	self.sizeButton:SetStack(itemSize)
	
	-- Money indicator
	self.coinFrame = Ux.MoneyFrame.New(self)
	self.coinFrame:SetPoint("BOTTOMRIGHT", self.configButton, "BOTTOMRIGHT", 0, Ux.ItemWindowFilterHeight)
	self.coinFrame.Event.MouseIn = function() Ux.MoneySummaryWindow:ShowAtCursor() end
	self.coinFrame.Event.MouseOut = function() Ux.MoneySummaryWindow:SetVisible(false) end
	
	-- Search filter and button
	local searchBtn = UI.CreateFrame("Texture", "", self)
	searchBtn:SetPoint("TOPLEFT", self.charSelector, "BOTTOMLEFT", Ux.ItemWindowPadding, 3)
	searchBtn:SetWidth(Ux.ItemWindowFilterHeight - 1)
	searchBtn:SetHeight(Ux.ItemWindowFilterHeight - 1)
	searchBtn:SetTexture("ImhoBags", "textures/search.png")
	searchBtn.Event.LeftDown = function() Ux.SearchWindow:Toggle() end
	
	local searchHighlight = UI.CreateFrame("Texture", "", searchBtn)
	searchHighlight:SetAllPoints()
	searchHighlight:SetVisible(false)
	searchHighlight:SetTexture("ImhoBags", "textures/ItemButton/highlight.png")
	searchBtn.Event.MouseIn = function() searchHighlight:SetVisible(true) end
	searchBtn.Event.MouseOut = function() searchHighlight:SetVisible(false) end
	
	self.filter = Ux.Textfield.New(self, "RIGHT", L.Ux.search)
	self.filter:SetPoint("TOPLEFT", searchBtn, "TOPRIGHT", 2, 0)
	self.filter:SetPoint("BOTTOMRIGHT", self.coinFrame, "BOTTOMLEFT", -2, 2)
	self.filter.text.Event.KeyFocusGain = function() filter_KeyFocusGain(self.filter.text, self) end
	self.filter.text.Event.KeyFocusLoss = function() filter_KeyFocusLoss(self.filter.text, self) end
	self.filter.text.Event.TextfieldChange = function() filter_TextfieldChange(self.filter.text, self) end
	self.searchString = ""

	-- General initialization
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
	
	self.buttons = { }
	self.groupLabels = { }

	self.contentOffset = self.charSelector:GetHeight() + self.filter:GetHeight() + Ux.ItemWindowPadding
	
	-- Protected (+abstract) methods
	self.isAvailable = isAvailable
	self.applySearchFilter = applySearchFilter
	self.configChanged = configChanged
	self.getContentPadding = getContentPadding
	self.columnsWidth = columnsWidth
	self.setItemsContentHeight = setItemsContentHeight
	self.onClose = nil
	self.getGroups = nil
	self.leftUp = nil
	self.setCharacter = nil
	self.getGroupLabel = nil
	self.iterateGroups = nil -- return group, items. group can be anything
	self.update = update
	
	-- Public methods
	self.SetCharacter = ItemWindowBase_SetCharacter
	self.Update = ItemWindowBase_Update
	self.GetNumColumns = ItemWindowBase_GetNumColumns

	Event.System.Update.Begin[#Event.System.Update.Begin + 1] = { function() systemUpdateBegin(self) end, Addon.identifier, "ItemWindowBase_systemUpdateBegin" }
	ImhoEvent.Config[#ImhoEvent.Config + 1] = { function(...) self:configChanged(...) end, Addon.identifier, "ItemWindowBase_configChanged" }
	
	-- If no interaction flag for this location exists it is always available
	local interactions = Inspect.Interaction()
	if(interactions[location] ~= nil) then
		self.interaction = interactions[location]
		Event.Interaction[#Event.Interaction + 1] = { function(...) interactionChanged(self, ...) end, Addon.identifier, "ItemWindowBase_interactionChanged" }
	else
		self.interaction = true
	end

	return self
end
