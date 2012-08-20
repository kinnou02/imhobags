local Addon, private = ...

-- Builtins
local floor = math.floor
local format = string.format
local max = math.max
local sort = table.sort
local tostring = tostring
local type = type

-- Globals
local Command = Command
local Inspect = Inspect
local UICreateFrame = UI.CreateFrame

-- Frames cannot be deleted, keep a cache and only create new frames if the cache is empty
local cachedLabels = { }
local labelFontSize = 14

setfenv(1, private)
Ux = Ux or { }
Ux.ItemWindow = { }

-- Private methods
-- ============================================================================

local function getGroupLabel(self, name)
	local label
	if(#cachedLabels == 0) then
		label = UICreateFrame("Texture", "", self.itemsContainer)
		label:SetTexture("Rift", "QuestBarUp.png.dds")
		label.text = UICreateFrame("Text", "", label)
		label.text:SetFontSize(labelFontSize)
		label.text:SetPoint("CENTER", label, "CENTER")
		function label:Dispose()
			self:SetVisible(false)
			cachedLabels[#cachedLabels + 1] = self
		end
		function label.SetInfo(label, sell, slots)
			if(label.text:GetText() == L.CategoryName.sellable) then
				label.text:SetText(format("%s (%i)", L.CategoryName.sellable, slots))
				self.sellableCoinFrame:SetPoint("RIGHTCENTER", label, "RIGHTCENTER", -2, 0)
				self.sellableCoinFrame:SetCoin(sell)
				self.sellableCoinFrame:SetVisible(true)
				self.sellableCoinFrame:SetParent(label)
			end
		end
	else
		label = cachedLabels[#cachedLabels]
		cachedLabels[#cachedLabels] = nil
		label:SetVisible(true)
		label:SetParent(self.itemsContainer)
	end
	label.text:SetText(name)
	label:SetHeight(label.text:GetHeight())
	label:SetWidth(label.text:GetWidth())
	if(name == L.CategoryName.sellable) then
		return label, Ux.ItemButtonSizeJunk, Ux.ItemButtonSizeJunk
	else
		return label, self.itemSize, self.itemSize
	end
end

local function sortGroups(self)
	sort(self.groups, function(a, b) return self.groupSortFunc(a, b, self.groupKeys) end)
end

local function sortItems(self)
	for i = 1, #self.groups do
		sort(self.groups[i], function(a, b) return self.sortFunc(a.type, b.type) end)
	end
end

local function getGroups(self)
	self.groups, self.groupKeys = ItemDB.GetGroupedItems(self.items, self.groupFunc)
	sortGroups(self)
	sortItems(self)
end

local dummytext = UICreateFrame("Text", "", Ux.Context)
dummytext:SetVisible(false)
dummytext:SetFontSize(labelFontSize)

local function getIndices(self)
	local indices = { }
	for i = 1, #self.groups do
		indices[#indices + 1] = i
		indices[#indices + 1] = 0
	end
	if(#indices > 0) then
		indices[#indices] = nil -- Remove last line break
	end
	return indices
end

local function getPackedIndices(self)
	local lines = { }
	local columns = self:GetNumColumns()
	local n = #self.groups
	local width = self:columnsWidth(columns)
	local size, spacing = self.itemSize, Ux.ItemWindowCellSpacing
	if(self.groupKeys[self.groups[n]] == L.CategoryName.sellable) then
		n = n - 1
	end
	
	local function line(textWidth, itemsWidth)
		local w = max(textWidth, itemsWidth)
		for i = 1, #lines do
			local v = lines[i]
			if(w + v[1] <= width) then
				-- Round to next cell width and ensure there is at least one empty gap between adjacent groups
				w = (floor((w + spacing) / (size + spacing)) + 1) * (size + spacing)
				v[1] = v[1] + w
				return v
			end
		end
		w = (floor((w + spacing) / (size + spacing)) + 1) * (size + spacing)
		lines[#lines + 1] = { w }
		return lines[#lines]
	end
	
	for i = 1, n do
		local items = self.groups[i]
		dummytext:SetText(self.groupKeys[items])
		local line = line(dummytext:GetFullWidth(), self:columnsWidth(#items))
		line[#line + 1] = i
	end
	
	-- Unfold into a single list
	local indices = { }
	for i = 1, #lines do
		local line = lines[i]
		for j = 2, #line do
			indices[#indices + 1] = line[j]
		end
		indices[#indices + 1] = 0
	end
	for i = n + 1, #self.groups do
		indices[#indices + 1] = i
		indices[#indices + 1] = 0
	end
	if(#indices > 0) then
		indices[#indices] = nil -- Remove last line break
	end
	return indices
end

local function iterateGroups(self)
	local indices = Config.packGroups and getPackedIndices(self) or getIndices(self)
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
				local items = self.groups[index]
				return self.groupKeys[items], items
			end
		end
	end
	return f, self
end

local function leftUp(self)
	-- Drop item
	local cursor, held = Inspect.Cursor()
	if(cursor and cursor == "item") then
		if(self:isAvailable() and #self.empty > 0) then
			ItemHandler.Standard.Drop(self.empty[1])
		else
			-- Ping-back the item to prevent the item destruction dialog from appearing
			ItemHandler.Standard.Drop(held)
		end
	end
end

local function setCharacter(self)
	self.coinMatrix = ItemDB.GetItemMatrix(self.character, "currency")
end

local function configChanged(self, name, value)
	self:base_configChanged(name, value)
	if(name == "packGroups") then
		self:Update()
	end
end

-- Protected methods
-- ============================================================================

local function update(self)
	-- Show number of empty slots
	local n = (type(self.empty) == "table" and #self.empty) or self.empty
	self.titleBar:SetEmptySlots(n)
	self.titleBar:SetMainLabel(format("%s", self.character == "player" and Player.name or self.character, self.title))
	self.sellableCoinFrame:SetVisible(false)
	
	self:base_update()
end

-- Public methods
-- ============================================================================

function Ux.ItemWindow.New(title, character, location, itemSize, sorting)
	local self = Ux.ItemWindowBase.New(title, character, location, itemSize)

	local sortAlgorithms = {
		name = Sort.Default.ByItemName,
		icon = Sort.Default.ByItemIcon,
		rarity = Sort.Default.ByItemRarity,
	}
	self.titleBar:SetSortSelectorCallback(function(sort)
			self.sort = sort
			self.sortFunc = sortAlgorithms[self.sort]
			self.titleBar:SetSortSelectorValue(sort)
			sortItems(self)
			self:Update()
		end)
	self.titleBar:SetSortSelectorValue(sorting)

	self.sellableCoinFrame = Ux.MoneyFrame.New(self)
	
	self.base_update = self.update
	self.update = update
	self.base_configChanged = self.configChanged
	self.configChanged = configChanged

	self.onClose = function() end
	self.getGroups = getGroups
	self.leftUp = leftUp
	self.setCharacter = setCharacter
	self.getGroupLabel = getGroupLabel
	self.iterateGroups = iterateGroups

	self.sort = sorting
	self.groupFunc = Group.Default.GetLocalizedShortCategoryWithJunkAndLootable
	self.groupSortFunc = Group.Default.SortByCategoryNameWithJunk
	self.sortFunc = sortAlgorithms[self.sort]
	
	self:SetCharacter(character, location)
	
	return self
end
