local Addon, private = ...local _G = _Glocal ipairs = ipairslocal getmetatable = getmetatablelocal math = mathlocal print = printlocal string = stringlocal table = tablelocal type = typelocal dump = dumplocal Command = Commandlocal Event = Eventlocal Inspect = Inspectlocal UI = UI-- Frames cannot be deleted, keep a cache and only create new frames if the cache is emptylocal cachedGroups = { }setfenv(1, private)Ux = Ux or { }Ux.ItemWindow = { }Ux.ItemWindowColumns = 8Ux.ItemWindowPadding = 4Ux.ItemWindowCellSpacing = 2-- Private methods-- ============================================================================local function createGroupLabel(window)	local text	if(#cachedGroups == 0) then		text = UI.CreateFrame("Text", "", window)		text:SetFontSize(14)		text:SetBackgroundColor(1, 1, 1, 0.1)	else		text = table.remove(cachedGroups)		text:SetVisible(true)		text:SetParent(window)	end	return textendlocal function clearItemDisplay(self)	-- Clear all groups and buttons and return them to cache	for _, label in ipairs(self.groupLabels) do		label:SetVisible(false)		table.insert(cachedGroups, label)	end	for _, btn in ipairs(self.buttons) do		btn:Dispose()	end	self.groupLabels = { }	self.buttons = { }endlocal function isNotLocked(window)	-- Non-player characters always report a number as empty slots.	-- Whereas the player gets a list of all empty slots	return type(window.empty == "table") and window.interactionendlocal function sortGroups(self)	table.sort(self.groups, function(a, b) return self.groupSortFunc(a, b, self.groupKeys) end)endlocal function sortItems(self)	for _, group in ipairs(self.groups) do		table.sort(group, function(a, b) return self.sortFunc(a.type, b.type) end)	endendlocal function getGroups(self)	self.groups, self.groupKeys = self.matrix:GetGroupedItems(self.items, self.groupFunc)	sortGroups(self)	sortItems(self)endlocal function getItems(self)	self.items, self.empty, self.success = self.matrix:GetUnsortedItems(self.condensed)	getGroups(self)endlocal function closeButton_LeftPress(self)	local window = self:GetParent()	window:SetVisible(false)	log("TODO", "close the native frame(s)")endlocal function systemUpdateBegin(self)	-- Inspect.Time.Frame() is not good enough and can cause multiple updates per frame	local now = Inspect.Time.Real()	if(self.matrix.lastUpdate >= self.lastUpdate) then		getItems(self)		self:Update()		self.lastUpdate = now		log("update", self:GetTitle(), self.lastUpdate)	elseif(not self.success and (now - self.lastUpdate > 1)) then		getItems(self)		self:Update()		self.lastUpdate = now		log("update", self:GetTitle(), self.lastUpdate)	endendlocal function hookToNative(window, native)	-- This will not work if other addons try to do the same	function native.Event:Loaded()		window:SetVisible(native:GetLoaded())		log("TODO", "move native frame(s) out of screen")	end	window.native = native	window:SetVisible(native:GetLoaded()) -- Initially visible?endlocal function content_MouseMove(self)	local mouse = Inspect.Mouse()	if(self.sizingOffset) then		self.window:SetWidth(mouse.x - self.window:GetLeft() + self.sizingOffset)		self.window:Update()	elseif(self.mouseOffsetX) then		self.window:SetPoint("TOPLEFT", _G.UIParent, "TOPLEFT", mouse.x - self.mouseOffsetX, mouse.y - self.mouseOffsetY)	endendlocal function content_LeftDown(self)	local mouse = Inspect.Mouse()	local left, top, right, bottom = self.window:GetTrimDimensions()	if(mouse.x > self.window:GetRight() - right - Ux.ItemWindowPadding and mouse.y > self.window:GetTop() + top) then		self.sizingOffset = self.window:GetRight() - mouse.x	else		self.mouseOffsetX = mouse.x - self.window:GetLeft()		self.mouseOffsetY = mouse.y - self.window:GetTop()	endendlocal function content_LeftUp(self)	self.mouseOffsetX, self.mouseOffsetY = nil, nil	self.sizingOffset = nil	-- Drop item	local cursor, held = Inspect.Cursor()	if(cursor and cursor == "item") then		if(isNotLocked(self.window) and #self.window.empty > 0) then			Command.Item.Move(held, self.window.empty[1])		end	endendlocal function interactionChanged(self, interaction, state)	if(interaction == self.location) then		self.interaction = state		self:Update()	endend-- Public methods-- ============================================================================local function ItemWindow_SetCharacter(self, character, location)	self.matrix = ItemDB.GetItemMatrix(character, location)	self.character = character	self.location = location	self.lastUpdate = -2endlocal function ItemWindow_Update(self)	clearItemDisplay(self)		local notLocked = isNotLocked(self)	local content = self:GetContent()	local width = math.ceil(content:GetWidth() - Ux.ItemWindowPadding)		local left = Ux.ItemWindowPadding	local top = 0		local x, y = left, 0	local dx, dy = Ux.ItemButtonWidth, Ux.ItemButtonHeight	local spacing = Ux.ItemWindowCellSpacing		for _, group in ipairs(self.groups) do		if(x > left) then			x = left			y = y + dy + spacing		end		local label = createGroupLabel(self)		table.insert(self.groupLabels, label)		local text = self.groupKeys[group];		label:SetText(text)		label:SetHeight(label:GetFullHeight())		label:SetWidth(width - Ux.ItemWindowPadding)				if(text == L.CategoryNames.sellable) then			y = y + 10		end		label:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)		y = y + label:GetHeight() + spacing				local sell = 0		local slots = 0				for _, item in ipairs(group) do			local button = Ux.ItemButton.New(self)			table.insert(self.buttons, button)			if(x + dx > width) then				x = left				y = y + dy + spacing			end			button:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)			button:SetItem(item.type, item.slots, item.stack, notLocked)			sell = sell + item.stack * (item.type.sell or 0)			if(type(item.slots) == "table") then				slots = slots + #item.slots			else				slots = slots + item.slots			end			x = x + dx + spacing		end				if(text == L.CategoryNames.sellable) then			text = text .. " (" .. slots .. ") - "			if(sell >= 10000) then				text = text .. math.floor(sell / 10000) .. "p "			end			if(sell >= 100) then				text = text .. math.floor(sell / 100 % 100) .. "g "			end			text = text .. (sell % 100) .. "s"			label:SetText(text)		end	end		local left, top, right, bottom = self:GetTrimDimensions()	self:SetHeight(top + y + dy + bottom + Ux.ItemWindowPadding)		-- Show number of empty slots	if(type(self.empty) == "table") then		self:SetTitle(string.format("%s (%i)", self.title, #self.empty))	else		self:SetTitle(string.format("%s (%i)", self.title, self.empty))	end	-- Display lock item and dim frame if item commands are not allowed	if(notLocked) then		self:SetAlpha(1.0)		self.readonlyLock:SetVisible(false)	else		self:SetAlpha(0.75)		self.readonlyLock:SetVisible(true)	endendfunction Ux.ItemWindow.New(title, character, location, condensed, native)	local window = UI.CreateFrame("RiftWindow", "ImhoBags_ItemWindow_"..location, Ux.Context)	window.title = title	window:SetTitle(title)	local left, top, right, bottom = window:GetTrimDimensions()	local width = Ux.ItemWindowColumns * Ux.ItemButtonWidth + left + right + 2 * Ux.ItemWindowPadding	width = width + (Ux.ItemWindowColumns - 1) * Ux.ItemWindowCellSpacing	window:SetWidth(width)		local closeButton = UI.CreateFrame("RiftButton", "", window)	closeButton:SetSkin("close")	closeButton:SetPoint("TOPRIGHT", window, "TOPRIGHT", -8, 15)	closeButton.Event.LeftPress = closeButton_LeftPress		window.readonlyLock = UI.CreateFrame("Texture", "", window)	window.readonlyLock:SetPoint("TOPLEFT", window, "TOPLEFT", 10, -2)	window.readonlyLock:SetWidth(46)	window.readonlyLock:SetHeight(53)	window.readonlyLock:SetTexture(Addon.identifier, "textures/lock_big.png")		window.SetCharacter = ItemWindow_SetCharacter	window.Update = ItemWindow_Update		window.buttons = { }	window.groupLabels = { }		window.groupFunc = Group.Default.GetLocalizedShortCategoryWithJunk	window.groupSortFunc = Group.Default.SortByCategoryNameWithJunk	window.sortFunc = Sort.Default.ByItemName		window.condensed = condensed	window:SetCharacter(character, location)		hookToNative(window, native)		local content = window:GetContent()	content.window = window	content.Event.MouseMove = content_MouseMove	content.Event.LeftDown = content_LeftDown	content.Event.LeftUp = content_LeftUp	local border = window:GetBorder()	border.window = window	border.Event.MouseMove = content_MouseMove	border.Event.LeftDown = content_LeftDown	border.Event.LeftUp = content_LeftUp		table.insert(Event.System.Update.Begin, { function() systemUpdateBegin(window) end, Addon.identifier, "systemUpdateBegin" })		-- If no interaction flag for this location exists it is always available	local interactions = Inspect.Interaction()	if(interactions[location] ~= nil) then		window.interaction = interactions[location]		table.insert(Event.Interaction, { function(...) interactionChanged(window, ...) end, Addon.identifier, "ItemWindow_interactionChanged" })	else		window.interaction = true	end	return windowend