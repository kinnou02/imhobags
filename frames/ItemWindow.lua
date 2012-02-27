local addon = (...).datalocal ipairs = ipairslocal print = printlocal table = tablelocal dump = dumplocal UI = UI-- Frames cannot be deleted, keep a cache and only create new frames if the cache is emptylocal cachedCategories = { }setfenv(1, addon)Ux = Ux or { }ItemWindowColumns = 8ItemWindowPadding = 8ItemWindowCellSpacing = 2-- Private methods-- ============================================================================local function createCategoryLabel(window)	local text	if(#cachedCategories == 0) then		text = UI.CreateFrame("Text", "", window)		text:SetFontSize(14)	else		text = table.remove(cachedCategories)	end	return textendlocal function clear(self)	-- Clear all categories and buttons and return them to cache	for _, cat in ipairs(self.categories) do		cat:SetVisible(false)		table.insert(cachedCategories, cat)	end	for _, btn in ipairs(self.buttons) do		btn:Dispose()	end	self.categories = { }	self.buttons = { }endlocal function window_UpdateItems(self, items)	clear(self)	self.items = items		local left, top, right, bottom = self:GetTrimDimensions()	left = left + ItemWindowPadding	top = top + ItemWindowPadding	right = right + ItemWindowPadding	bottom = bottom + ItemWindowPadding		local x, y = left, top	local dx, dy = ItemButtonWidth, ItemButtonHeight	local spacing = ItemWindowCellSpacing		for _, cat in ipairs(items) do		if(x > left) then			x = left			y = y + dy		end		local label = createCategoryLabel(self)		table.insert(self.categories, label)		label:SetText(cat.name)		label:SetHeight(label:GetFullHeight())		label:SetWidth(self:GetWidth() - right)		label:SetPoint("TOPLEFT", self, "TOPLEFT", x, y)		y = y + label:GetHeight()				for _, item in ipairs(cat) do			local button = Ux.CreateItemButton(self)			table.insert(self.buttons, button)			if(x + dx > self:GetWidth() - right) then				x = left				y = y + dy + spacing			end			button:SetPoint("TOPLEFT", self, "TOPLEFT", x, y)			button:SetItem(item.type, item.slots, item.stack)			x = x + dx + spacing		end	end		self:SetHeight(y + bottom + dy)endlocal function window_MouseMove(...)	print("move")endlocal function window_Close(self)	self:SetVisible(false)end-- Public methods-- ============================================================================function CreateItemWindow(title)	local window = UI.CreateFrame("RiftWindow", "ImhoBags_ItemWindow_"..title, Ux.Context)	window.buttons = { }	window.categories = { }	window.items = { }		window:SetMouseMasking("full")	window:SetTitle(title)	local left, top, right, bottom = window:GetTrimDimensions()	local width = ItemWindowColumns * ItemButtonWidth + left + right + 2 * ItemWindowPadding	width = width + (ItemWindowColumns - 1) * ItemWindowCellSpacing	window:SetWidth(width)		local closeButton = UI.CreateFrame("RiftButton", "", window)	closeButton:SetSkin("close")	closeButton:SetPoint("TOPRIGHT", window, "TOPRIGHT", -7, 16)	closeButton.Event = window_Close		window.UpdateItems = window_UpdateItems		window.Event.MouseMove = window_MouseMove		return windowend