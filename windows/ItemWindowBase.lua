local Addon, private = ...

-- Builtins
local assert = assert
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
	window.titleBar:ClearKeyFocus()
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
		if(coroutine.status(self.updateCoroutine) == "dead") then
			self.updateCoroutine = nil
		else
			assert(coroutine.resume(self.updateCoroutine, self, now))
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

local function filter_TextfieldChange(window, filterText)
	-- Build a case-insensitive search pattern
	window.searchString = strgsub(filterText, "%a", function(ch)
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
				self:SetCharacter(Player.name, self.location)
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
			local w = max(x2 - x + dx + spacing, ceil(label:GetWidth() / (dx + spacing)) * (dx + spacing))
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

local function createSearchFilter(self)
	local frame = UI.CreateFrame("Frame", "", self)
	frame:SetHeight(20)
	frame:SetWidth(100)
	
	local mask = UI.CreateFrame("Mask", "", frame)
	mask:SetPoint("TOPLEFT", frame, "TOPLEFT")
	mask:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
	mask:SetWidth(0)
	
	local background = UI.CreateFrame("Texture", "", mask)
	background:SetTexture("Rift", "window_field.png.dds")
	background:SetAllPoints(frame)

	local icon = UI.CreateFrame("Texture", "", background)
	icon:SetTexture("Rift", "filter_icon.png.dds")
--	icon:SetTexture("Rift", "icon_menu_LFP.png.dds")
	icon:SetPoint("LEFTCENTER", mask, "LEFTCENTER", 4, 0)
	
	local input = UI.CreateFrame("RiftTextfield", "", background)
	input:SetPoint("LEFTCENTER", icon, "RIGHTCENTER", 0, 1)
	input:SetPoint("RIGHTCENTER", mask, "RIGHTCENTER", 0, 1)
	input:SetText("")

	local hitArea = UI.CreateFrame("Frame", "", frame)
	hitArea:SetLayer(10)
	hitArea:SetAllPoints(frame)
	hitArea:SetMouseMasking("limited")
	
	frame.animation = 0
	local function tick(width)
		mask:SetWidth(width)
	end
	local function fadeIn()
		Animate.stop(frame.animation)
		frame.animation = Animate.easeInOut(mask:GetWidth(), frame:GetWidth(), 0.3, tick, function() frame.animation = 0 end)
	end
	local function fadeOut()
		Animate.stop(frame.animation)
		frame.animation = Animate.easeInOut(mask:GetWidth(), 0, 0.3, tick, function() frame.animation = 0 end)
	end
	
	hitArea.Event.MouseIn = fadeIn
	hitArea.Event.MouseOut = fadeOut
	
	input.Event.KeyFocusGain = function() fadeIn() end
	input.Event.KeyFocusLoss = function() fadeOut() filter_KeyFocusLoss(input, self) end
	input.Event.TextfieldChange = function() filter_TextfieldChange(input, self) end
	
	frame.input = input
	frame.mask = mask
	return frame
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
		self.titleBar:SetAlliance(ItemDB.GetCharacterAlliance(character))
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
	self:SetTitle("")

	self.title = title
	self:SetController("content")
	self.itemsContainer = self:GetContent()
	self.itemSize = itemSize
	self.updateCoroutine = nil
	self.searchString = ""
	
	local content = self:GetContent()
	
	-- Close button
	Ux.RiftWindowCloseButton.New(self, closeButton_LeftPress)
	
	-- Tool buttons
	self.bankButton = Ux.IconButton.New(self, [[Data/\UI\item_icons\chest2.dds]], L.Ux.WindowTitle.bank)
	self.bankButton:SetPoint("TOPLEFT", content, "TOPLEFT",Ux.ItemWindowPadding, -2)
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

	self.wardrobeButton = Ux.IconButton.New(self, [[wardrobe_none.dds]], L.Ux.WindowTitle.wardrobe)
	self.wardrobeButton:SetPoint("TOPLEFT", self.equipmentButton, "TOPRIGHT")
	function self.wardrobeButton.LeftPress()
		Ux.ToggleItemWindow(self.character, "wardrobe")
	end

	self.currencyButton = Ux.IconButton.New(self, [[Data/\UI\item_icons\loot_gold_coins.dds]], L.Ux.WindowTitle.currency)
	self.currencyButton:SetPoint("TOPLEFT", self.wardrobeButton, "TOPRIGHT")
	function self.currencyButton.LeftPress()
		Ux.ToggleItemWindow(self.character, "currency")
	end
	
	self.guildButton = Ux.IconButton.New(self, Player.alliance == "defiant" and [[Data/\UI\item_icons\GuildCharter_Defiants.dds]] or [[Data/\UI\item_icons\GuildCharter_Guardians.dds]], L.Ux.Tooltip.guild)
	self.guildButton:SetPoint("TOPLEFT", self.currencyButton, "TOPRIGHT")
	function self.guildButton.LeftPress()
		Ux.ToggleGuildWindow(self.character)
	end
	
	-- Search button
	local helpBtn = UI.CreateFrame("Frame", "", self)
	helpBtn:SetPoint("BOTTOMLEFT", content, "TOPLEFT", -4, -6)
	helpBtn:SetWidth(36)
	helpBtn:SetHeight(36)
	helpBtn.Event.MouseIn = function(self) self.icon:SetTexture("Rift", "AATree_I3A.dds") end
	helpBtn.Event.MouseOut = function(self) self.icon:SetTexture("Rift", "AATree_I38.dds") end
	helpBtn.Event.LeftUpoutside = function(self) self.icon:SetTexture("Rift", "AATree_I38.dds") end
	helpBtn.Event.LeftDown = function(self)
		self.icon:SetTexture("Rift", "AATree_I3F.dds")
	end
	helpBtn.Event.LeftUp = function(self)
		self.icon:SetTexture("Rift", "AATree_I3A.dds")
		Ux.ToggleConfigWindow()
	end
	helpBtn.icon = UI.CreateFrame("Texture", "", self)
	helpBtn.icon:SetPoint("CENTER", helpBtn, "CENTER")
	helpBtn.icon:SetWidth(38)
	helpBtn.icon:SetHeight(38)
	helpBtn.icon:SetTexture("Rift", "AATree_I38.dds")
	
	-- General initialization
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

	self.contentOffset = self.bankButton:GetHeight() + Ux.ItemWindowPadding
	
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

	-- Title bar
	self.titleBar = Ux.ItemWindowTemplate.TitleBar(self, location)
	self.titleBar:SetFilterCallback(function(...) filter_TextfieldChange(self, ...) end)
	self.titleBar:SetCharButtonCallback(function() self.titleBar:ShowCharSelector(ItemDB.GetAvailableCharacters()) end)
	self.titleBar:SetCharSelectorCallback(function(char) self:SetCharacter(char, self.location) self.titleBar:FadeOut() end)
	self.titleBar:SetSizeSelectorCallback(function(n) self.itemSize = n self:Update() end)
	self.titleBar:SetSizeSelectorValue(self.itemSize)

	return self
end
