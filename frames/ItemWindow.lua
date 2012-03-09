local Addon, private = ...local _G = _Glocal ipairs = ipairslocal getmetatable = getmetatablelocal math = mathlocal string = stringlocal table = tablelocal type = typelocal dump = dumplocal Command = Commandlocal Event = Eventlocal Inspect = Inspectlocal UI = UI-- Frames cannot be deleted, keep a cache and only create new frames if the cache is emptylocal cachedGroups = { }setfenv(1, private)Ux = Ux or { }Ux.ItemWindow = { }Ux.ItemWindowColumns = 8Ux.ItemWindowPadding = 4Ux.ItemWindowCellSpacing = 2Ux.ItemWindowMinWidth = 345 -- Prevents header buttons from overlapping and is lower bound for full columnsUx.ItemWindowMinHeight = 380 -- Title bar stats resizing below this size-- Private methods-- ============================================================================local function createGroupLabel(window)	local text	if(#cachedGroups == 0) then		text = UI.CreateFrame("Text", "", window)		text:SetFontSize(14)		text:SetBackgroundColor(1, 1, 1, 0.1)	else		text = table.remove(cachedGroups)		text:SetVisible(true)		text:SetParent(window)	end	return textendlocal function clearItemDisplay(self)	-- Clear all groups and buttons and return them to cache	for _, label in ipairs(self.groupLabels) do		label:SetVisible(false)		table.insert(cachedGroups, label)	end	for _, btn in ipairs(self.buttons) do		btn:Dispose()	end	self.groupLabels = { }	self.buttons = { }endlocal function isNotLocked(window)	-- Non-player characters always report a number as empty slots.	-- Whereas the player gets a list of all empty slots--@alpha@	return type(window.empty) == "table" and window.interaction--@end-alpha@--[===[@non-alpha@	return false--@end-nonealpha@]===]endlocal function sortGroups(self)	table.sort(self.groups, function(a, b) return self.groupSortFunc(a, b, self.groupKeys) end)endlocal function sortItems(self)	for _, group in ipairs(self.groups) do		table.sort(group, function(a, b) return self.sortFunc(a.type, b.type) end)	endendlocal function getGroups(self)	self.groups, self.groupKeys = self.matrix:GetGroupedItems(self.items, self.groupFunc)	sortGroups(self)	sortItems(self)endlocal function getItems(self)	self.items, self.empty, self.success = self.matrix:GetUnsortedItems(self.condensed)	getGroups(self)endlocal function closeButton_LeftPress(self)	local window = self:GetParent()	window:SetVisible(false)	log("TODO", "close the native frame(s)")endlocal function systemUpdateBegin(self)	-- Inspect.Time.Frame() is not good enough and can cause multiple updates per frame	local now = Inspect.Time.Real()	if(self.matrix.lastUpdate >= self.lastUpdate) then		getItems(self)		self:Update()		self.lastUpdate = now		log("update", self:GetTitle(), self.lastUpdate)	elseif(not self.success and (now - self.lastUpdate > 1)) then		getItems(self)		self:Update()		self.lastUpdate = now		log("update", self:GetTitle(), self.lastUpdate)	endendlocal function hookToNative(window, native)	-- This will not work if other addons try to do the same	function native.Event:Loaded()		window:SetVisible(native:GetLoaded())		window:SetCharacter(PlayerName, window.location)		log("TODO", "move native frame(s) out of screen")	end	window.native = native	window:SetVisible(native:GetLoaded()) -- Initially visible?endlocal function applySearchFilter(self)	if(self.searchString == "") then		for _, button in ipairs(self.buttons) do			button.icon:SetAlpha(1.0)		end	else		local lower = string.lower		local find = string.find		for _, button in ipairs(self.buttons) do			if(find(lower(button.type.name), self.searchString, 1, true)) then				button.icon:SetAlpha(1.0)			else				button.icon:SetAlpha(0.3)			end		end	endendlocal function content_MouseMove(self)	local mouse = Inspect.Mouse()	if(self.sizingOffset) then		self.window:SetWidth(math.max(Ux.ItemWindowMinWidth, mouse.x - self.window:GetLeft() + self.sizingOffset))		self.window:Update()	elseif(self.mouseOffsetX) then		self.window:SetPoint("TOPLEFT", _G.UIParent, "TOPLEFT", mouse.x - self.mouseOffsetX, mouse.y - self.mouseOffsetY)	endendlocal function content_LeftDown(self)	local mouse = Inspect.Mouse()	local left, top, right, bottom = self.window:GetTrimDimensions()	if(mouse.x > self.window:GetRight() - right - Ux.ItemWindowPadding and mouse.y > self.window:GetTop() + top) then		self.sizingOffset = self.window:GetRight() - mouse.x	else		self.mouseOffsetX = mouse.x - self.window:GetLeft()		self.mouseOffsetY = mouse.y - self.window:GetTop()	endendlocal function content_LeftUpoutside(self)	self.mouseOffsetX, self.mouseOffsetY = nil, nil	self.sizingOffset = nilendlocal function content_LeftUp(self)	content_LeftUpoutside(self)	-- Drop item	local cursor, held = Inspect.Cursor()	if(cursor and cursor == "item") then		if(isNotLocked(self.window) and #self.window.empty > 0) then			Command.Item.Move(held, self.window.empty[1])		end	endendlocal function interactionChanged(self, interaction, state)	if(interaction == self.location) then		self.interaction = state		self:Update()	endendlocal function filter_KeyFocusGain(self, window)	if(self:GetText() == L.Ux.search) then		self:SetText("")	endendlocal function filter_KeyFocusLoss(self, window)	if(self:GetText() == "") then		self:SetText(L.Ux.search)	endendlocal function filter_TextfieldChange(self, window)	window.searchString = string.lower(self:GetText())	applySearchFilter(window)endlocal function createIconButton(parent, data, icon)	local btn = UI.CreateFrame("Texture", "", parent)	btn:SetTexture(data, icon)	btn:SetWidth(32)	btn:SetHeight(32)	btn:SetAlpha(0.7)	function btn.Event:MouseIn() self:SetAlpha(1.0) end	function btn.Event:MouseOut() self:SetAlpha(0.7) end	return btnend-- Public methods-- ============================================================================local function ItemWindow_SetCharacter(self, character, location)	self.matrix = ItemDB.GetItemMatrix(character, location)	self.character = character	self.location = location	self.lastUpdate = -2	self.charSelector:SetText((character == "player" and PlayerName) or character)endlocal function ItemWindow_Update(self)	clearItemDisplay(self)		local notLocked = isNotLocked(self)	local content = self:GetContent()	local width = math.ceil(content:GetWidth() - Ux.ItemWindowPadding)		local left = Ux.ItemWindowPadding	local top = self.contentOffset		local x, y = left, top	local dx, dy = Ux.ItemButtonWidth, Ux.ItemButtonHeight	local spacing = Ux.ItemWindowCellSpacing		for _, group in ipairs(self.groups) do		if(x > left) then			x = left			y = y + dy + spacing		end		local label = createGroupLabel(self)		table.insert(self.groupLabels, label)		local text = self.groupKeys[group];		label:SetText(text)		label:SetHeight(label:GetFullHeight())		label:SetWidth(width - Ux.ItemWindowPadding)				if(text == L.CategoryName.sellable) then			y = y + 10		end		label:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)		y = y + label:GetHeight() + spacing				local sell = 0		local slots = 0				for _, item in ipairs(group) do			local button = Ux.ItemButton.New(self)			table.insert(self.buttons, button)			if(x + dx > width) then				x = left				y = y + dy + spacing			end			button:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)			button:SetItem(item.type, item.slots, item.stack, notLocked)			sell = sell + item.stack * (item.type.sell or 0)			if(type(item.slots) == "table") then				slots = slots + #item.slots			else				slots = slots + item.slots			end			x = x + dx + spacing		end				if(text == L.CategoryName.sellable) then			text = text .. " (" .. slots .. ") - " .. Utils.FormatCoin(sell)			label:SetText(text)		end	end		local left, top, right, bottom = self:GetTrimDimensions()	self:SetHeight(math.max(Ux.ItemWindowMinHeight, top + y + dy + bottom + Ux.ItemWindowPadding))		-- Show number of empty slots	if(type(self.empty) == "table") then		self:SetTitle(string.format("%s (%i)", self.title, #self.empty))	else		self:SetTitle(string.format("%s (%i)", self.title, self.empty))	end	-- Display lock item and dim frame if item commands are not allowed	if(notLocked) then--		self:SetAlpha(1.0)		self.readonlyLock:SetVisible(false)	else--		self:SetAlpha(0.75)		self.readonlyLock:SetVisible(true)	end		applySearchFilter(self)endfunction Ux.ItemWindow.New(title, character, location, condensed, native)	local window = UI.CreateFrame("RiftWindow", "ImhoBags_ItemWindow_"..location, Ux.Context)	window.title = title	window:SetTitle(title)	local left, top, right, bottom = window:GetTrimDimensions()	local width = Ux.ItemWindowColumns * Ux.ItemButtonWidth + left + right + 2 * Ux.ItemWindowPadding	width = width + (Ux.ItemWindowColumns - 1) * Ux.ItemWindowCellSpacing	window:SetWidth(width)		Ux.RiftWindowCloseButton.New(window, closeButton_LeftPress)		window.charSelector = Ux.CharSelector.New(window, ItemDB.GetAvailableCharacters(), Inspect.Unit.Detail("player").name, function(char)		window:SetCharacter(char, window.location)	end)	window.charSelector:SetPoint("TOPLEFT", window:GetContent(), "TOPLEFT")		-- Secondary buttons on inventory window	local searchBtn = createIconButton(window, "Rift", [[Data/\UI\item_icons\intact_shambler_eye.dds]])	searchBtn:SetPoint("TOPRIGHT", window:GetContent(), "TOPRIGHT", -2 * Ux.ItemWindowPadding, -Ux.ItemWindowPadding)	function searchBtn.Event.LeftDown(self)		Ux.SearchWindow:Show()	end		if(location == "inventory") then		local bankButton = createIconButton(window, "Rift", [[Data/\UI\item_icons\Chest2.dds]])		bankButton:SetPoint("TOPRIGHT", searchBtn, "TOPLEFT")		function bankButton.Event.LeftDown(self)			Ux.ShowItemWindow(window.charSelector:GetText(), "bank")		end	end	window.readonlyLock = UI.CreateFrame("Texture", "", window)	window.readonlyLock:SetPoint("LEFTCENTER", window.charSelector, "RIGHTCENTER", -5, -7)	window.readonlyLock:SetWidth(36)	window.readonlyLock:SetHeight(36)	window.readonlyLock:SetTexture(Addon.identifier, "textures/lock_silver.png")		-- Condensed checkbox	local cb = Ux.Checkbox.New(window, "Condensed", "LEFT")	cb:SetPoint("TOPRIGHT", searchBtn, "BOTTOMRIGHT", 0, 3)	cb:SetChecked(condensed)	function cb.Event:CheckboxChange()		window.condensed = self:GetChecked()		window:SetCharacter(window.character, window.location)	end		-- Search filter	local filter = Ux.Textfield.New(window, "RIGHT", L.Ux.search)	filter:SetPoint("TOPLEFT", window.charSelector, "BOTTOMLEFT", Ux.ItemWindowPadding, -3)	filter:SetPoint("BOTTOMRIGHT", cb, "TOPLEFT", -Ux.ItemWindowPadding - cb.text:GetWidth(), 23)	filter.text.Event.KeyFocusGain = function(self) filter_KeyFocusGain(self, window) end	filter.text.Event.KeyFocusLoss = function(self) filter_KeyFocusLoss(self, window) end	filter.text.Event.TextfieldChange = function(self) filter_TextfieldChange(self, window) end		window.contentOffset = window.charSelector:GetHeight() + filter:GetHeight() + 5		window.SetCharacter = ItemWindow_SetCharacter	window.Update = ItemWindow_Update		window.buttons = { }	window.groupLabels = { }		window.groupFunc = Group.Default.GetLocalizedShortCategoryWithJunk	window.groupSortFunc = Group.Default.SortByCategoryNameWithJunk	window.sortFunc = Sort.Default.ByItemName	window.searchString = ""		window.condensed = condensed	window:SetCharacter(character, location)	--@alpha@	hookToNative(window, native)--@end-alpha@	window:SetVisible(false)		local content = window:GetContent()	content.window = window	content.Event.MouseMove = content_MouseMove	content.Event.LeftDown = content_LeftDown	content.Event.LeftUp = content_LeftUp	local border = window:GetBorder()	border.window = window	border.Event.MouseMove = content_MouseMove	border.Event.LeftDown = content_LeftDown	border.Event.LeftUp = content_LeftUp	border.Event.LeftUpoutside = content_LeftUpoutside		table.insert(Event.System.Update.Begin, { function() systemUpdateBegin(window) end, Addon.identifier, "systemUpdateBegin" })		-- If no interaction flag for this location exists it is always available	local interactions = Inspect.Interaction()	if(interactions[location] ~= nil) then		window.interaction = interactions[location]		table.insert(Event.Interaction, { function(...) interactionChanged(window, ...) end, Addon.identifier, "ItemWindow_interactionChanged" })	else		window.interaction = true	end	return windowend