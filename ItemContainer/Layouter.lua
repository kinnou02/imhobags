local Addon, private = ...

-- Builtins
local ceil = math.ceil
local floor = math.floor
local format = string.format
local max = math.max
local min = math.min
local pairs = pairs
local sort = table.sort
local strfind = string.find

-- Globals
local UICreateFrame = UI.CreateFrame
local UtilityItemSlotParse = Utility.Item.Slot.Parse

-- Locals
local emptyName = private.L.CategoryName.empty
local junkName = private.L.CategoryName.sellable
local newLine = false

setfenv(1, private)
ItemContainer = ItemContainer or { }

-- Private methods
-- ============================================================================

local function getGroupLabelMinWidth()
	return 1
end

local function setupGroupLabel()
end

local function onebagGroupFactory(parent)
	local self = UICreateFrame("Frame", "", parent)
	self:SetHeight(0)
	self.GetMinWidth = getGroupLabelMinWidth
	self.Setup = setupGroupLabel
	return self
end

local function getGroupAssociation_default(set, showEmptySlots)
	local groups, junk, empty = { }, nil, { }
	for id, group in pairs(set.groups) do
		local items = groups[group] or { }
		groups[group] = items
		items[#items + 1] = id
	end
	junk = groups[junkName] or { }
	groups[junkName] = nil

	if(showEmptySlots) then
		for slot in pairs(set.empty) do
			empty[#empty + 1] = slot
		end
	end

	return groups, junk, empty
end

local function getGroupAssociation_bags(set, showEmptySlots)
	local groups = { }
	for slot, item in pairs(set.slots) do
		local container, bag, index = UtilityItemSlotParse(slot)
		if(bag == "main") then
			bag = 0
		end
		local items = groups[bag] or { }
		groups[bag] = items
		if(item) then
			items[#items + 1] = item
		elseif(showEmptySlots) then
			items[#items + 1] = slot
		end
	end
	
	return groups, { }, { }
end

local function getGroupAssociation_onebag(set, showEmptySlots)
	local items = { }
	for slot, item in pairs(set.slots) do
		if(item) then
			items[#items + 1] = item
		elseif(showEmptySlots) then
			items[#items + 1] = slot
		end
	end
	
	return { onebag = items }, { }, { }
end

local function arrangePacked(self, elementWidth, spacing, keys, sizes, minWidths, newLine)
	-- keys, sizes and minWidths are arrays
	local lines = { }
	local lineWidths = { }
	local columns = { }

	for i = 1, #keys do
		-- Round to next cell width and ensure there is at least one empty gap between adjacent groups
		local key = keys[i]
		local itemsWidth = sizes[i] * (elementWidth + spacing)
		local width = max(ceil(minWidths[i] / (elementWidth + spacing)), sizes[i])
		columns[key] = max(width, sizes[i] + 1)
		width = width * (elementWidth + spacing)

		local added = false
		for j = 1, #lines do
			if(lineWidths[j] + width <= self.width) then
				lines[j][#lines[j] + 1] = i
				lineWidths[j] = lineWidths[j] + max(width, itemsWidth + elementWidth + spacing)
				added = true
				break
			end
		end
		if(not added) then
			lines[#lines + 1] = { i }
			lineWidths[#lineWidths + 1] = max(width, itemsWidth + elementWidth + spacing)
		end
	end
	
	-- Flatten list
	local layout = { }
	for i = 1, #lines do
		local key
		for j = 1, #lines[i] do
			key = keys[lines[i][j]]
			layout[#layout + 1] = key
		end
		columns[key] = columns[key] - 1
		layout[#layout + 1] = newLine
	end

	return layout, columns
end

local function moveGroups(self, groups, junk, empty, duration, layout, sizes)
	local line, x, y = 0, 0, 0
	local columns = floor(self.width / (self.itemSize + Const.ItemWindowCellSpacing))
	local height = 0
	local prevGroup
	for i = 1, #layout do
		local name = layout[i]
		if(name == newLine) then
			line = line + 1
			x = 0
			local rows = ceil(sizes[layout[i - 1]] / columns)
			y = y + rows
			height = height + prevGroup:GetHeight() + rows * (self.itemSize + Const.ItemWindowCellSpacing)
		else
			prevGroup = groups[name].frame
			local isLast = layout[i + 1] == newLine
			prevGroup:MoveToGrid(line, x, y, self.itemSize, self.itemSize, Const.ItemWindowCellSpacing,
				min(self.width, (isLast and self.width - x * (self.itemSize + Const.ItemWindowCellSpacing) or sizes[name] * (self.itemSize + Const.ItemWindowCellSpacing))),
				self.groups[name] and duration)
			x = x + sizes[name]
		end
	end
	if(#empty > 0) then
		empty.frame:MoveToGrid(line, 0, y, self.itemSize, self.itemSize, Const.ItemWindowCellSpacing, self.width, #self.empty > 0 and duration)
		line = line + 1
		local rows = ceil(#empty / columns)
		y = y + rows
		height = height + empty.frame:GetHeight() + rows * (self.itemSize + Const.ItemWindowCellSpacing)
	end
	if(#junk > 0) then
		self.junkCoinFrame:SetVisible(true)
		self.junkCoinFrame:SetParent(junk.frame)
		self.junkCoinFrame:SetPoint("RIGHTCENTER", junk.frame, "RIGHTCENTER", -5, 0)
		junk.frame:MoveToGrid(line, 0, y, self.itemSize, self.itemSize, Const.ItemWindowCellSpacing, self.width, #self.junk > 0 and duration)
		line = line + 1
		local rows = ceil(#junk / columns)
		y = y + rows
		height = height + junk.frame:GetHeight() + rows * (Const.ItemWindowJunkButtonSize + Const.ItemWindowCellSpacing)
	else
		self.junkCoinFrame:SetVisible(false)
	end
	return height
end

local function setupJunk(self, junk)
	if(#junk > 0) then
		junk.frame = self.junk.frame or ItemContainer.Group(self.parent, self.groupFrameFactory)
		junk.frame.text:SetText(format("%s (%i)", junkName, #junk))
		local value = 0
		for i = 1, #junk do
			value = value + (self.set.items[junk[i]].sell or 0) * (self.set.items[junk[i]].stack or 1)
		end
		self.junkCoinFrame:SetCoin(value)
	end
end

local function setupEmpty(self, empty)
	if(#empty > 0 and self.layout == "default") then
		empty.frame = self.empty.frame or ItemContainer.Group(self.parent, self.groupFrameFactory)
		empty.frame.text:SetText(format("%s (%i)", emptyName, #empty))
	end
end

local function replaceIdsWithButtons(self, items, allButtons, itemButtons, itemSize)
	-- Replace ids/empty slots in-place with actual buttons
	for i = 1, #items do
		local item = items[i]
		local button = self.itemButtons[item]
		local details = self.set.items[item]
		if(not button) then
			button = Ux.ItemButton.New(self.parent, self.available, Const.AnimationsDuration)
			self.itemButtons[item] = button
			if(details.rarity == "empty") then
				button:SetItem(false, item, 1, self.available, Const.AnimationsDuration)
			else
				self:UpdateItem(item)
			end
		elseif(details.rarity == "empty") then
			button:SetItem(false, item, 1, self.available, Const.AnimationsDuration)
		end
		button:SetSize(itemSize)
		items[i] = button
		allButtons[button] = true
		itemButtons[item] = button
	end
end

local function sortItemsAndCreateButtons(self, groups, junk, empty)
	local allButtons = { }
	local itemButtons = { }
	for name, items in pairs(groups) do
		sort(items, function(a, b) return self.sortFunc(self.set.items[a], self.set.items[b]) end)
		replaceIdsWithButtons(self, items, allButtons, itemButtons, self.itemSize)
	end
	if(#junk > 0) then
		sort(junk, function(a, b) return self.sortFunc(self.set.items[a], self.set.items[b]) end)
		replaceIdsWithButtons(self, junk, allButtons, itemButtons, Const.ItemWindowJunkButtonSize)
	end
	if(#empty > 0) then
		sort(empty, function(a, b) return self.sortFunc(self.set.items[a], self.set.items[b]) end)
		replaceIdsWithButtons(self, empty, allButtons, itemButtons, self.itemSize)
	end
	self.itemButtons = itemButtons
	self.prevButtons = self.allButtons
	self.allButtons = allButtons
end

local function hideEmptyGroups(self, groups, junk, empty)
	for name, group in pairs(self.groups) do
		if(not groups[name]) then
			group.frame:Dispose(Const.AnimationsDuration, self.allButtons)
		end
	end
	if(#self.junk > 0 and #junk == 0) then
		self.junk.frame:Dispose(0, self.allButtons)
	end
	if(#self.empty > 0 and #empty == 0) then
		self.empty.frame:Dispose(0, self.allButtons)
	end
end

local function createNewGroups(self, groups)
	local factory = self.layout == "onebag" and onebagGroupFactory or self.groupFrameFactory
	for name, items in pairs(groups) do
		local group = self.groups[name] and self.groups[name].frame
		if(not group) then
			group = ItemContainer.Group(self.parent, factory, Const.AnimationsDuration)
			group:Setup(self.parent, name, items)
		end
		groups[name].frame = group
	end
end

local function getGroupMetrics(self, groups)
	local names, sizes, groupWidths = { }, { }, { }
	for group in pairs(groups) do
		names[#names + 1] = group
	end
	sort(names)
	for i = 1, #names do
		sizes[i] = #groups[names[i]]
		groupWidths[i] = groups[names[i]].frame:GetMinWidth()
	end
	
	return names, sizes, groupWidths
end

local function reset(self)
	-- Reset everything, requires an UpdateItems call
	for name, group in pairs(self.groups) do
		group.frame:Dispose()
	end
	if(#self.junk > 0) then
		self.junk.frame:Dispose()
	end
	if(#self.empty > 0) then
		self.empty.frame:Dispose()
	end
	self.itemButtons = { }
	self.allButtons = { }
	self.prevButtons = { }
	self.groups = { }
	self.junk = { }
	self.empty = { }
end

-- Public methods
-- ============================================================================

-- Rebuild the item grouping and sorting information
local function UpdateItems(self)
	self.width = self.parent:GetWidth()
	local groups, junk, empty = self.getGroupAssociation(self.set, self.showEmptySlots)
	
	setupJunk(self, junk)
	setupEmpty(self, empty)
	sortItemsAndCreateButtons(self, groups, junk, empty)
	hideEmptyGroups(self, groups, junk, empty)
	createNewGroups(self, groups)
	local names, sizes, groupWidths = getGroupMetrics(self, groups)

	-- Move groups and buttons
	local height = moveGroups(self, groups, junk, empty, Const.AnimationsDuration, arrangePacked(self, self.itemSize, Const.ItemWindowCellSpacing, names, sizes, groupWidths, newLine))
	if(empty.frame) then
		empty.frame:SetButtons(Const.AnimationsDuration, self.allButtons, self.prevButtons, empty, self.itemSize, Const.ItemWindowCellSpacing)
	end
	if(junk.frame) then
		junk.frame:SetButtons(Const.AnimationsDuration, self.allButtons, self.prevButtons, junk, Const.ItemWindowJunkButtonSize, Const.ItemWindowCellSpacing)
	end
	for name, group in pairs(groups) do
		group.frame:SetButtons(Const.AnimationsDuration, self.allButtons, self.prevButtons, group, self.itemSize, Const.ItemWindowCellSpacing)
	end
	self.groups = groups
	self.junk = junk
	self.empty = empty
	return height
end

-- The items did not change, only their sorting order or the area width
local function UpdateLayout(self)
	self.width = self.parent:GetWidth()
	local names, sizes, groupWidths = getGroupMetrics(self, self.groups)

	-- Move groups and buttons
	local height = moveGroups(self, self.groups, self.junk, self.empty, Const.AnimationsDuration, arrangePacked(self, self.itemSize, Const.ItemWindowCellSpacing, names, sizes, groupWidths, newLine))
	if(self.empty.frame) then
		self.empty.frame:Rearrange(Const.AnimationsDuration, self.itemSize, Const.ItemWindowCellSpacing)
	end
	if(self.junk.frame) then
		self.junk.frame:Rearrange(Const.AnimationsDuration, Const.ItemWindowJunkButtonSize, Const.ItemWindowCellSpacing)
	end
	for name, group in pairs(self.groups) do
		group.frame:Rearrange(Const.AnimationsDuration, self.itemSize, Const.ItemWindowCellSpacing)
	end
	return height
end

local function UpdateItem(self, id)
	local duration = Const.AnimationsDuration
	local button = self.itemButtons[id]
	if(not button) then
		return
	end
	if(not button:GetVisible()) then
		duration = 0
	end
	local item = self.set.items[id]
	button:SetItem(item, item.slot, item.stack or 1, self.available, duration)
	if(button.item) then
		button:SetFiltered(strfind(button.item.name, self.filter) == nil)
	end
end

local function SetSearchFilter(self, filter)
	if(filter == "") then
		for button in pairs(self.allButtons) do
			button:SetFiltered(false)
		end
	else
		for button in pairs(self.allButtons) do
			if(button.item) then
				button:SetFiltered(strfind(button.item.name, filter) == nil)
			end
		end
	end
	self.filter = filter
end

local function SetLayout(self, layout)
	layout = layout or Const.ItemWindowDefaultLayout
	if(layout == "default") then
		self.getGroupAssociation = getGroupAssociation_default
	elseif(layout == "bags") then
		self.getGroupAssociation = getGroupAssociation_bags
	elseif(layout == "onebag") then
		self.getGroupAssociation = getGroupAssociation_onebag
	end
	if(layout ~= self.layout) then
--		reset(self)
	end
	self.layout = layout
end

local function SetItemSet(self, set)
	if(self.set ~= set) then
		reset(self)
	end
	self.set = set
end

local function SetLocked(self, locked)
	self.locked = locked
	for button in pairs(self.allButtons) do
		button:SetLocked(locked)
	end
end

local function SetAvailable(self, available)
	self.available = available
	for button in pairs(self.allButtons) do
		button:SetAvailable(available)
	end
end

local function SetItemSize(self, size)
	self.itemSize = size
	for group, buttons in pairs(self.groups) do
		for i = 1, #buttons do
			buttons[i]:SetSize(size)
		end
	end
end

local sortFuncs = {
	name = Sort.Default.ByItemName,
	icon = Sort.Default.ByItemIcon,
	rarity = Sort.Default.ByItemRarity,
	slot = Sort.Default.ByItemSlot,
}
local function SetSortMethod(self, sort)
	self.sortFunc = sortFuncs[sort] or sortFuncs[Const.ItemWindowDefaultSort]
	self.sort = sort
end

local function FillConfig(self, config)
	config.itemSize = self.itemSize
	config.layout = self.layout
	config.sort = self.sort
	config.showEmptySlots = self.showEmptySlots
	return config
end

local function SetShowEmptySlots(self, showEmptySlots)
	self.showEmptySlots = showEmptySlots
end

function ItemContainer.Layouter(parent, config, groupFrameFactory)
	local self = {
		itemButtons = {
			-- [id] = button
		},
		allButtons = {
			-- [button] = true
		},
		prevButtons = {
			-- [button] = true
		},
		groups = {
			-- [name] = { [frame] = group, [*] = sorted buttons }
		},
		junk = {
			-- [frame] = group, [*] = sorted buttons
		},
		empty = {
			-- [frame] = group, [*] = sorted buttons
		},
		available = true,
		itemSize = config.itemSize or Const.ItemButtonDefaultSize,
		filter = "",
		groupFrameFactory = groupFrameFactory,
		height = 0,
		junkCoinFrame = Ux.MoneyFrame.New(parent),
		layout = config.layout,
		parent = parent,
		set = nil,
		sortFunc = nil,
		showEmptySlots = config.showEmptySlots,
		width = parent:GetWidth(),
		
		FillConfig = FillConfig,
		SetAvailable = SetAvailable,
		SetItemSet = SetItemSet,
		SetItemSize = SetItemSize,
		SetLayout = SetLayout,
		SetLocked = SetLocked,
		SetSearchFilter = SetSearchFilter,
		SetShowEmptySlots = SetShowEmptySlots,
		SetSortMethod = SetSortMethod,
		UpdateItem = UpdateItem,
		UpdateItems = UpdateItems,
		UpdateLayout = UpdateLayout,
	}
	self.junkCoinFrame:SetVisible(false)
	SetLayout(self, config.layout)
	SetSortMethod(self, config.sort)
	
	return self
end

