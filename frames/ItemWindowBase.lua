local Addon, private = ...-- Builtinslocal ceil = math.ceillocal floor = math.floorlocal format = string.formatlocal max = math.maxlocal min = math.minlocal strfind = string.findlocal strgsub = string.gsublocal strlower = string.lowerlocal strupper = string.upperlocal type = type-- Globalslocal Event = Eventlocal Inspect = Inspectlocal UI = UIlocal UIParent = UIParentsetfenv(1, private)Ux = Ux or { }Ux.ItemWindowBase = { }Ux.ItemWindowColumns = 8Ux.ItemWindowPadding = 4Ux.ItemWindowCellSpacing = 2Ux.ItemWindowFilterHeight = 22Ux.ItemWindowMinWidth = 345 -- Prevents header buttons from overlapping and is lower bound for full columnsUx.ItemWindowMinHeight = 380 -- Title bar stats resizing below this size-- Private methods-- ============================================================================local function clearItemDisplay(self)	-- Clear all groups and buttons and return them to cache	for i = 1, #self.groupLabels do		self.groupLabels[i]:Dispose()	end	for i = 1, #self.buttons do		self.buttons[i]:Dispose()	end	self.groupLabels = { }	self.buttons = { }endlocal function isAvailable(self)	-- Non-player characters always report a number as empty slots.	-- Whereas the player gets a list of all empty slot ids--@debug@	return type(self.empty) == "table" and self.interaction--@end-debug@--[===[@non-debug@	return false--@end-non-debug@]===]endlocal function getItems(self)	local success	if(self.enemy) then		self.items, self.empty, success = self.matrix:GetUnsortedItems(self.condensedCheck:GetChecked(), Config.showEnemyFaction == "account")	else		self.items, self.empty, success = self.matrix:GetUnsortedItems(self.condensedCheck:GetChecked())	end	if(success) then		self.getItemFailed = 0	else		self.getItemFailed = self.getItemFailed + 1	end	self:getGroups()endlocal function closeButton_LeftPress(self)	local window = self:GetParent()	window:SetVisible(false)	window.filter.text:SetKeyFocus(false)	window:onClose()	log("TODO", "close the native frame(s)")endlocal function systemUpdateBegin(self)	-- Inspect.Time.Frame() is not good enough and can cause multiple updates per frame	local now = Inspect.Time.Real()	if(self.matrix.lastUpdate >= self.lastUpdate) then		getItems(self)		self:Update()		self.lastUpdate = now		log("update", self:GetTitle(), self.lastUpdate)	elseif(self.getItemFailed > 0 and (now - self.lastUpdate > 1)) then		log("getItemFailed", self:GetTitle(), self.getItemFailed)		getItems(self)		-- Limit the number of retries to avoid permanent performance drops		if(self.getItemFailed > 3) then			log("getItemFailed", self:GetTitle(), "giving up")			self.getItemFailed = 0		end		self:Update()		self.lastUpdate = now		log("update", self:GetTitle(), self.lastUpdate)	endendlocal function hookToNative(window, native)	if(not native) then		return	end	-- This will not work if other addons try to do the same	function native.Event:Loaded()		if(Config.autoOpen) then			window:SetVisible(self:GetLoaded())			window:SetCharacter(PlayerName, window.location)			log("TODO", "move native frame(s) out of screen")		end	end	window.native = native	window:SetVisible(native:GetLoaded()) -- Initially visible?endlocal function content_MouseMove(self)	local mouse = Inspect.Mouse()	if(self.sizingOffset) then		self.window:SetWidth(max(Ux.ItemWindowMinWidth, mouse.x - self.window:GetLeft() + self.sizingOffset))		self.window:Update()	elseif(self.mouseOffsetX) then		self.window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", mouse.x - self.mouseOffsetX, mouse.y - self.mouseOffsetY)	endendlocal function content_LeftDown(self)	local mouse = Inspect.Mouse()	local left, top, right, bottom = self.window:GetTrimDimensions()	if(mouse.x > self.window:GetRight() - right - Ux.ItemWindowPadding and mouse.y > self.window:GetTop() + top) then		self.sizingOffset = self.window:GetRight() - mouse.x	else		self.mouseOffsetX = floor(mouse.x - self.window:GetLeft())		self.mouseOffsetY = floor(mouse.y - self.window:GetTop())	endendlocal function content_LeftUpoutside(self)	self.mouseOffsetX, self.mouseOffsetY = nil, nil	self.sizingOffset = nilendlocal function content_LeftUp(self)	content_LeftUpoutside(self)	-- Drop item	self.window:leftUp()endlocal function interactionChanged(self, interaction, state)	if(interaction == self.location) then		self.interaction = state		self:Update()	endendlocal function filter_KeyFocusGain(self, window)	if(self:GetText() == L.Ux.search) then		self:SetText("")	endendlocal function filter_KeyFocusLoss(self, window)	if(self:GetText() == "") then		self:SetText(L.Ux.search)	endendlocal function filter_TextfieldChange(self, window)	-- Build a case-insensitive search pattern	window.searchString = strgsub(self:GetText(), "%a", function(ch)		return format("[%s%s]", strlower(ch), strupper(ch))	end)	window:applySearchFilter()endlocal function configChanged(self, name, value)	if(name == "showEnemyFaction") then		if(self.enemy) then			if(Config.showEnemyFaction == "no") then				self:SetCharacter(PlayerName, self.location)			else				getItems(self)				self:Update()			end		end	endend-- Protected methods-- ============================================================================local function applySearchFilter(self)	if(self.searchString == "") then		for i = 1, #self.buttons do			self.buttons[i]:SetFiltered(false)		end	else		for i = 1, #self.buttons do			local button = self.buttons[i]			button:SetFiltered(strfind(button.item.name, self.searchString) == nil)		end	endend-- return x, y, sell, slotslocal function renderItems(self, items, left, x, y, width, dx, dy, spacing, content, notLocked)	local sell = 0	local slots = 0	for i = 1, #items do		local item = items[i]		local button = Ux.ItemButton.New(self)		button:SetWidth(dx)		button:SetHeight(dy)		self.buttons[#self.buttons + 1] = button		if(x + dx > width) then			x = left			y = y + dy + spacing		end		button:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)		button:SetItem(item.type, item.slots, item.stack, notLocked)		sell = sell + item.stack * (item.type.sell or 0)		if(type(item.slots) == "table") then			slots = slots + #item.slots		else			slots = slots + item.slots		end		x = x + dx + spacing	end	return x, y, sell, slotsend-- Public methods-- ============================================================================local function ItemWindowBase_SetCharacter(self, character, location)	self.getItemFailed = 0	self.matrix, self.enemy = ItemDB.GetItemMatrix(character, location)	self.character = character	self.location = location	self.lastUpdate = -2	self.charSelector:SetText((character == "player" and PlayerName) or character)	self:setCharacter()endlocal function ItemWindowBase_Update(self)	clearItemDisplay(self)		local available = isAvailable(self)	local content = self:GetContent()	local width = ceil(content:GetWidth() - Ux.ItemWindowPadding)		local left = Ux.ItemWindowPadding	local top = self.contentOffset		local x, y = left, top	local dx, dy = Ux.ItemButtonSize, Ux.ItemButtonSize	local spacing = Ux.ItemWindowCellSpacing	local label	for group, items in self:iterateGroups() do		if(not group) then			label:SetWidth(content:GetRight() - label:GetLeft() - left)			x = left			y = y + dy + 2 * spacing + label:GetHeight()		else			label, dx, dy = self:getGroupLabel(group)			self.groupLabels[#self.groupLabels + 1] = label			label:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)						local x2, y2, sell, slots = renderItems(self, items, left, x, y + label:GetHeight() + spacing, width, dx, dy, spacing, content, available)			-- Insert empty gap between adjacent groups			local w = max(x2 - x + dx + spacing, ceil(label:GetFullWidth() / (dx + spacing)) * (dx + spacing))			label:SetWidth(min(w, width - x))			y = y2 - label:GetHeight() - spacing			x = x + w			label:SetInfo(sell, slots)		end	end	if(label) then		label:SetWidth(label:GetWidth() + width - x)		y = y + label:GetHeight()	end	local left, top, right, bottom = self:GetTrimDimensions()	self:SetHeight(max(Ux.ItemWindowMinHeight, top + y + dy + bottom + Ux.ItemWindowPadding))	-- Display lock item and dim frame if item commands are not allowed	if(available) then--		self:SetAlpha(1.0)		self.readonlyLock:SetVisible(false)	else--		self:SetAlpha(0.75)		self.readonlyLock:SetVisible(true)	end		self:applySearchFilter()endlocal function ItemWindowBase_GetNumColumns(self)	return floor((self:GetContent():GetWidth() - 2 * Ux.ItemWindowPadding + Ux.ItemWindowCellSpacing) / (Ux.ItemButtonSize + Ux.ItemWindowCellSpacing))endfunction Ux.ItemWindowBase.New(title, character, location, condensed, native)	local context = UI.CreateContext(Addon.identifier)	local self = UI.CreateFrame("RiftWindow", "ImhoBags_ItemWindow_"..location, context)	self.title = title	self:SetTitle(title)	local left, top, right, bottom = self:GetTrimDimensions()	local width = Ux.ItemWindowColumns * Ux.ItemButtonSize + left + right + 2 * Ux.ItemWindowPadding	width = width + (Ux.ItemWindowColumns - 1) * Ux.ItemWindowCellSpacing	self:SetWidth(width)		-- Close button	Ux.RiftWindowCloseButton.New(self, closeButton_LeftPress)		-- Char selector	self.charSelector = Ux.CharSelector.New(self, Inspect.Unit.Detail("player").name, function(char)		self:SetCharacter(char, self.location)	end)	self.charSelector:SetPoint("TOPLEFT", self:GetContent(), "TOPLEFT")		-- Readonly indicator	self.readonlyLock = UI.CreateFrame("Texture", "", self)	self.readonlyLock:SetPoint("LEFTCENTER", self.charSelector, "RIGHTCENTER", -5, -7)	self.readonlyLock:SetWidth(36)	self.readonlyLock:SetHeight(36)	self.readonlyLock:SetTexture(Addon.identifier, "textures/lock_silver.png")		-- Tool buttons	self.searchButton = Ux.IconButton.New(self, [[Data/\UI\item_icons\intact_shambler_eye.dds]])	self.searchButton:SetPoint("TOPRIGHT", self:GetContent(), "TOPRIGHT", -Ux.ItemWindowPadding, -2)	function self.searchButton.LeftPress()		Ux.SearchWindow:Toggle()	end		self.mailButton = Ux.IconButton.New(self, [[Data/\UI\item_icons\collection_of_love_letters.dds]])	self.mailButton:SetPoint("TOPRIGHT", self.searchButton, "TOPLEFT", -10, 0)	function self.mailButton.LeftPress()		Ux.ToggleItemWindow(self.charSelector:GetText(), "mail")	end		self.bankButton = Ux.IconButton.New(self, [[Data/\UI\item_icons\chest2.dds]])	self.bankButton:SetPoint("TOPRIGHT", self.mailButton, "TOPLEFT")	function self.bankButton.LeftPress()		Ux.ToggleItemWindow(self.charSelector:GetText(), "bank")	end	-- Condensed checkbox	self.condensedCheck = Ux.Checkbox.New(self, "Condensed", "LEFT")	self.condensedCheck:SetPoint("TOPRIGHT", self.searchButton, "BOTTOMRIGHT", 0, 3)	self.condensedCheck:SetChecked(condensed)	function self.condensedCheck.Event.CheckboxChange()		self:SetCharacter(self.character, self.location)	end		-- Search filter	self.filter = Ux.Textfield.New(self, "RIGHT", L.Ux.search)	self.filter:SetPoint("TOPLEFT", self.charSelector, "BOTTOMLEFT", Ux.ItemWindowPadding, -3)	self.filter:SetPoint("BOTTOMRIGHT", self.condensedCheck, "TOPLEFT", -Ux.ItemWindowPadding - self.condensedCheck.text:GetWidth(), Ux.ItemWindowFilterHeight)	self.filter.text.Event.KeyFocusGain = function() filter_KeyFocusGain(self.filter.text, self) end	self.filter.text.Event.KeyFocusLoss = function() filter_KeyFocusLoss(self.filter.text, self) end	self.filter.text.Event.TextfieldChange = function() filter_TextfieldChange(self.filter.text, self) end	self.searchString = ""	-- General initialization	hookToNative(self, native)	self:SetVisible(false)		local content = self:GetContent()	content.window = self	content.Event.MouseMove = content_MouseMove	content.Event.LeftDown = content_LeftDown	content.Event.LeftUp = content_LeftUp	local border = self:GetBorder()	border.window = self	border.Event.MouseMove = content_MouseMove	border.Event.LeftDown = content_LeftDown	border.Event.LeftUp = content_LeftUp	border.Event.LeftUpoutside = content_LeftUpoutside		self.buttons = { }	self.groupLabels = { }	self.contentOffset = self.charSelector:GetHeight() + self.filter:GetHeight() + 5		-- Protected (abstract) methods	self.isAvailable = isAvailable	self.applySearchFilter = applySearchFilter	self.configChanged = configChanged	self.onClose = nil	self.getGroups = nil	self.leftUp = nil	self.setCharacter = nil	self.getGroupLabel = nil	self.iterateGroups = nil -- return group, items. group can be anything		-- Public methods	self.SetCharacter = ItemWindowBase_SetCharacter	self.Update = ItemWindowBase_Update	self.GetNumColumns = ItemWindowBase_GetNumColumns	Event.System.Update.Begin[#Event.System.Update.Begin + 1] = { function() systemUpdateBegin(self) end, Addon.identifier, "ItemWindowBase_systemUpdateBegin" }	ImhoEvent.Config[#ImhoEvent.Config + 1] = { function(...) self:configChanged(...) end, Addon.identifier, "ItemWindowBase_configChanged" }		-- If no interaction flag for this location exists it is always available	local interactions = Inspect.Interaction()	if(interactions[location] ~= nil) then		self.interaction = interactions[location]		Event.Interaction[#Event.Interaction + 1] = { function(...) interactionChanged(self, ...) end, Addon.identifier, "ItemWindowBase_interactionChanged" }	else		self.interaction = true	end	return selfend