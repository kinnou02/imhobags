local Addon, private = ...

-- Builtins
local floor = math.floor
local format = string.format
local max = math.max
local sort = table.sort
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
Ux.EquipmentWindow = { }

-- Private methods
-- ============================================================================

local function getGroupLabel(self, name)
	local label
	if(#cachedLabels == 0) then
		label = UICreateFrame("Text", "", self.itemsContainer)
		label:SetFontSize(labelFontSize)
		label:SetBackgroundColor(1, 1, 1, 0.1)
		local p = UICreateFrame("Texture", "", label)
		p:SetWidth(16)
		p:SetHeight(16)
		p:SetPoint("TOPRIGHT", label, "TOPRIGHT")
		function label:Dispose()
			self:SetVisible(false)
			cachedLabels[#cachedLabels + 1] = self
		end
		function label.SetInfo(label, sell, slots)
		end
	else
		label = cachedLabels[#cachedLabels]
		cachedLabels[#cachedLabels] = nil
		label:SetVisible(true)
		label:SetParent(self.itemsContainer)
	end
	label:ClearHeight()
	label:SetText(name)
	return label, self.itemSize, self.itemSize
end

-- Protected methods
-- ============================================================================

local function update(self)
	self:item_update()
	self.titleBar:SetEmptySlots(nil)
end

-- Public methods
-- ============================================================================

function Ux.EquipmentWindow.New(title, character, location, itemSize, sorting)
	-- Sort equipment and wardrobe by icon, that will most likely keep a consistent ordering for now
	local self = Ux.ItemWindow.New(title, character, location, itemSize, "icon")
	
	-- Disable the sort button as it doesn't make sense
	self.titleBar:SetSortSelectorCallback(nil)
	
	self.item_update = self.update
	self.update = update
	
	self.getGroupLabel = getGroupLabel

	self:SetCharacter(character, location)
	
	return self
end
