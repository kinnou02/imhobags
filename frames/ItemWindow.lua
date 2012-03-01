local identifier = (...).idlocal addon = (...).datalocal _G = _Glocal ipairs = ipairslocal getmetatable = getmetatablelocal math = mathlocal print = printlocal string = stringlocal table = tablelocal type = typelocal dump = dumplocal Command = Commandlocal Event = Eventlocal Inspect = Inspectlocal UI = UI-- Frames cannot be deleted, keep a cache and only create new frames if the cache is emptylocal cachedGroups = { }setfenv(1, addon)Ux = Ux or { }Ux.ItemWindow = { }Ux.ItemWindowColumns = 8Ux.ItemWindowPadding = 8Ux.ItemWindowCellSpacing = 2-- Private methods-- ============================================================================local function ItemWindow_createGroupLabel(window)	local text	if(#cachedGroups == 0) then		text = UI.CreateFrame("Text", "", window.content)		text:SetFontSize(14)		text:SetBackgroundColor(1, 1, 1, 0.1)	else		text = table.remove(cachedGroups)		text:SetVisible(true)		text:SetParent(window)	end	return textendlocal function ItemWindow_clear(self)	-- Clear all groups and buttons and return them to cache	for _, label in ipairs(self.groupLabels) do		label:SetVisible(false)		table.insert(cachedGroups, label)	end	for _, btn in ipairs(self.buttons) do		btn:Dispose()	end	self.groupLabels = { }	self.buttons = { }endlocal function ItemWindow_sortGroups(self)	table.sort(self.groups, function(a, b) return self.groupSortFunc(a, b, self.groupKeys) end)endlocal function ItemWindow_sortItems(self)	for _, group in ipairs(self.groups) do		table.sort(group, function(a, b) return self.sortFunc(a.type, b.type) end)	endendlocal function ItemWindow_getGroups(self)	self.groups, self.groupKeys = self.matrix:GetGroupedItems(self.items, self.groupFunc)	ItemWindow_sortGroups(self)	ItemWindow_sortItems(self)endlocal function ItemWindow_getItems(self)	self.items, self.empty, self.success = self.matrix:GetUnsortedItems(condensed)	ItemWindow_getGroups(self)endlocal function ItemWindow_Update(self)	ItemWindow_clear(self)		local left, top, right, bottom = self:GetTrimDimensions()	left = left + Ux.ItemWindowPadding	top = top + Ux.ItemWindowPadding	right = right + Ux.ItemWindowPadding	bottom = bottom + Ux.ItemWindowPadding		local x, y = left, top	local dx, dy = Ux.ItemButtonWidth, Ux.ItemButtonHeight	local spacing = Ux.ItemWindowCellSpacing		for _, group in ipairs(self.groups) do		if(x > left) then			x = left			y = y + dy + spacing		end		local label = ItemWindow_createGroupLabel(self)		table.insert(self.groupLabels, label)		local text = self.groupKeys[group];		label:SetText(text)		label:SetHeight(label:GetFullHeight())		label:SetWidth(self:GetWidth() - right - x)				if(text == L.CategoryNames.sellable) then			y = y + 10		end		label:SetPoint("TOPLEFT", self.content, "TOPLEFT", x, y)		y = y + label:GetHeight() + spacing				local sell = 0		local slots = 0				for _, item in ipairs(group) do			local button = Ux.ItemButton.New(self.content)			table.insert(self.buttons, button)			if(x + dx > self:GetWidth() - right) then				x = left				y = y + dy + spacing			end			button:SetPoint("TOPLEFT", self.content, "TOPLEFT", x, y)			button:SetItem(item.type, item.slots, item.stack)			sell = sell + item.stack * (item.type.sell or 0)			if(type(item.slots) == "table") then				slots = slots + #item.slots			else				slots = slots + item.slots			end			x = x + dx + spacing		end				if(text == L.CategoryNames.sellable) then			text = text .. " (" .. slots .. ") - "			if(sell >= 10000) then				text = text .. math.floor(sell / 10000) .. "p "			end			if(sell >= 100) then				text = text .. math.floor(sell / 100 % 100) .. "g "			end			text = text .. (sell % 100) .. "s"			label:SetText(text)		end	end		self:SetHeight(y + bottom + dy)		-- Show number of empty slots	if(type(self.empty) == "table") then		self:SetTitle(self.title .. " (" .. #self.empty .. ")")	else		self:SetTitle(self.title .. " (" .. self.empty .. ")")	endendlocal function ItemWindow_Close(self)	local window = self:GetParent():GetParent()	window:SetVisible(false)	-- TODO: close the native frame(s)endlocal function ItemWindow_systemUpdateBegin(self, ...)	-- Inspect.Time.Frame() is not good enough and can cause multiple updates per frame	local now = Inspect.Time.Real()	if(self.matrix.lastUpdate >= self.lastUpdate) then		ItemWindow_getItems(self)		ItemWindow_Update(self)		self.lastUpdate = now		debug("update", self:GetTitle(), self.lastUpdate)	elseif(not self.success and (now - self.lastUpdate > 1)) then		ItemWindow_getItems(self)		ItemWindow_Update(self)		self.lastUpdate = now		debug("update", self:GetTitle(), self.lastUpdate)	endendlocal function ItemWindow_hookToNative(window, native)	-- This will not work if other addons try to do the same	function native.Event:Loaded()		window:SetVisible(native:GetLoaded())		-- TODO: move native frame(s) out of screen	end	window.native = native	window:SetVisible(native:GetLoaded()) -- Initially visible?endlocal function ItemWindow_hitTest(self, x, y)	for _, button in ipairs(self.buttons) do		local left, top, right, bottom = button:GetBounds()		if(x >= left and x <= right and y >= top and y <= bottom) then			return button		end	endendlocal function ItemWindow_content_MouseMove(self)	local window = self:GetParent()	local mouse = Inspect.Mouse()	if(self.mouseOffsetX) then		window:SetPoint("TOPLEFT", _G.UIParent, "TOPLEFT", mouse.x - self.mouseOffsetX, mouse.y - self.mouseOffsetY)	endendlocal function ItemWindow_content_LeftDown(self)	local mouse = Inspect.Mouse()	self.mouseOffsetX = mouse.x - self:GetLeft()	self.mouseOffsetY = mouse.y - self:GetTop()endlocal function ItemWindow_content_LeftUp(self)	self.mouseOffsetX, self.mouseOffsetY = nil, nil	-- Drop item	local window = self:GetParent()	local cursor, held = Inspect.Cursor()	if(cursor and cursor == "item") then		if(type(window.empty) == "table" and #window.empty > 0) then			Command.Item.Move(held, window.empty[1])		end	endend-- Public methods-- ============================================================================local function ItemWindow_SetCharacter(self, character, location)	self.matrix = ItemDB.GetItemMatrix(character, location)	self.lastUpdate = -2endfunction Ux.ItemWindow.New(title, character, location, condensed, native)	local window = UI.CreateFrame("RiftWindow", "ImhoBags_ItemWindow_"..title, Ux.Context)	window.title = title	window:SetTitle(title)	local left, top, right, bottom = window:GetTrimDimensions()	local width = Ux.ItemWindowColumns * Ux.ItemButtonWidth + left + right + 2 * Ux.ItemWindowPadding	width = width + (Ux.ItemWindowColumns - 1) * Ux.ItemWindowCellSpacing	window:SetWidth(width)		-- RiftWindow can't be hooked for mouse events so use helper frame	window.content = UI.CreateFrame("Frame", "", window)	window.content:SetAllPoints()		local closeButton = UI.CreateFrame("RiftButton", "", window.content)	closeButton:SetSkin("close")	closeButton:SetPoint("TOPRIGHT", window.content, "TOPRIGHT", -7, 16)	closeButton.Event.LeftPress = ItemWindow_Close		window.SetCharacter = ItemWindow_SetCharacter		window.buttons = { }	window.groupLabels = { }		window.groupFunc = Group.Default.GetLocalizedShortCategoryWithJunk	window.groupSortFunc = Group.Default.SortByCategoryNameWithJunk	window.sortFunc = Sort.Default.ByItemName		window.condensed = condensed	window:SetCharacter(character, location)		ItemWindow_hookToNative(window, native)		window.content.Event.MouseMove = ItemWindow_content_MouseMove	window.content.Event.LeftDown = ItemWindow_content_LeftDown	window.content.Event.LeftUp = ItemWindow_content_LeftUp		table.insert(Event.System.Update.Begin, { function(...) ItemWindow_systemUpdateBegin(window, ...) end, identifier, "ItemWindow_systemUpdateBegin" })	return windowend