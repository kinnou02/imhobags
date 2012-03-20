local Addon, private = ...local ipairs = ipairslocal math = mathlocal string = stringlocal table = tablelocal type = typelocal Command = Commandlocal Inspect = Inspectlocal UI = UI-- Frames cannot be deleted, keep a cache and only create new frames if the cache is emptylocal cachedLabels = { }local labelFontSize = 14setfenv(1, private)Ux = Ux or { }Ux.ItemWindow = { }-- Private methods-- ============================================================================local function getGroupLabel(self, name)	local label	if(#cachedLabels == 0) then		label = UI.CreateFrame("Text", "", self)		label:SetFontSize(labelFontSize)		label:SetBackgroundColor(1, 1, 1, 0.1)		local p = UI.CreateFrame("Texture", "", label)		p:SetWidth(16)		p:SetHeight(16)		p:SetPoint("TOPRIGHT", label, "TOPRIGHT")		function label:Dispose()			self:SetVisible(false)			table.insert(cachedLabels, self)		end		function label.SetInfo(label, sell, slots)			if(label:GetText() == L.CategoryName.sellable) then				label:SetText(string.format("%s (%i)", L.CategoryName.sellable, slots))				self.moneyFrame:SetPoint("RIGHTCENTER", label, "RIGHTCENTER", -2, 0)				self.moneyFrame:SetCoin(sell)				self.moneyFrame:SetVisible(true)				self.moneyFrame:SetLayer(label:GetLayer() + 1)			end		end	else		label = table.remove(cachedLabels)		label:SetVisible(true)		label:SetParent(self)	end	label:SetText(name)	label:SetHeight(label:GetFullHeight())	return labelendlocal function sortGroups(self)	table.sort(self.groups, function(a, b) return self.groupSortFunc(a, b, self.groupKeys) end)endlocal function sortItems(self)	for _, group in ipairs(self.groups) do		table.sort(group, function(a, b) return self.sortFunc(a.type, b.type) end)	endendlocal function getGroups(self)	self.groups, self.groupKeys = ItemDB.GetGroupedItems(self.items, self.groupFunc)	sortGroups(self)	sortItems(self)endlocal dummytext = UI.CreateFrame("Text", "", Ux.Context)dummytext:SetVisible(false)dummytext:SetFontSize(labelFontSize)local function colsWidth(cols)	return cols * Ux.ItemButtonSize + (cols - 1) * Ux.ItemWindowCellSpacingendlocal function getIndices(self)	local indices = { }	for k, v in ipairs(self.groups) do		indices[#indices + 1] = k		indices[#indices + 1] = 0	end	if(#indices > 0) then		indices[#indices] = nil -- Remove last line break	end	return indicesendlocal function getPackedIndices(self)	local lines = { }	local columns = self:GetNumColumns()	local n = #self.groups	local width = colsWidth(columns)	local size, spacing = Ux.ItemButtonSize, Ux.ItemWindowCellSpacing	if(self.groupKeys[self.groups[n]] == L.CategoryName.sellable) then		n = n - 1	end		local function line(textWidth, itemsWidth)		local w = math.max(textWidth, itemsWidth)		for k, v in ipairs(lines) do			if(w + v[1] <= width) then				-- Round to next cell width and ensure there is at least one empty gap between adjacent groups				w = (math.floor((w + spacing) / (size + spacing)) + 1) * (size + spacing)				v[1] = v[1] + w				return v			end		end		w = (math.floor((w + spacing) / (size + spacing)) + 1) * (size + spacing)		lines[#lines + 1] = { w }		return lines[#lines]	end		for i = 1, n do		local items = self.groups[i]		dummytext:SetText(self.groupKeys[items])		table.insert(line(dummytext:GetFullWidth(), colsWidth(#items)), i)	end		-- Unfold into a single list	local indices = { }	for _, line in ipairs(lines) do		for i = 2, #line do			indices[#indices + 1] = line[i]		end		indices[#indices + 1] = 0	end	for i = n + 1, #self.groups do		indices[#indices + 1] = i		indices[#indices + 1] = 0	end	if(#indices > 0) then		indices[#indices] = nil -- Remove last line break	end	return indicesendlocal function iterateGroups(self)	local indices = Config.packGroups and getPackedIndices(self) or getIndices(self)	local i, n = 1, #indices	local f = function(self)		if(i > n) then			return nil		else			local index = indices[i]			i = i + 1			if(index < 1) then				return false			else				local items = self.groups[index]				return self.groupKeys[items], items			end		end	end	return f, selfendlocal function leftUp(self)	-- Drop item	local cursor, held = Inspect.Cursor()	if(cursor and cursor == "item") then		if(self:isAvailable() and #self.empty > 0) then			Command.Item.Move(held, self.empty[1])		end	endendlocal function setCharacter(self)endlocal function configChanged(self, name, value)	self:base_configChanged(name, value)	if(name == "stackGroups") then		self:Update()	endend-- Public methods-- ============================================================================local function ItemWindow_Update(self)	self.moneyFrame:SetVisible(false)	self:base_Update()		-- Show number of empty slots	local n = (type(self.empty) == "table" and #self.empty) or self.empty	self:SetTitle(string.format("%s (%i)", self.title, n))endfunction Ux.ItemWindow.New(title, character, location, condensed, native)	local self = Ux.ItemWindowBase.New(title, character, location, condensed, native)		if(location == "bank") then		self.bankButton:SetIcon([[Data/\UI\item_icons\bag20.dds]])		function self.bankButton.LeftPress()			Ux.ToggleItemWindow(self.charSelector:GetText(), "inventory")		end	end		self.moneyFrame = Ux.MoneyFrame.New(self)		self.base_Update = self.Update	self.Update = ItemWindow_Update	self.base_configChanged = self.configChanged	self.configChanged = configChanged	self.onClose = function() end	self.getGroups = getGroups	self.leftUp = leftUp	self.setCharacter = setCharacter	self.getGroupLabel = getGroupLabel	self.iterateGroups = iterateGroups	self.groupFunc = Group.Default.GetLocalizedShortCategoryWithJunkAndLootable	self.groupSortFunc = Group.Default.SortByCategoryNameWithJunk	self.sortFunc = Sort.Default.ByItemName		self:SetCharacter(character, location)		return selfend