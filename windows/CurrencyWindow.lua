local Addon, private = ...

setfenv(1, private)
Ux = Ux or { }
Ux.CurrencyWindow = { }

-- Private methods
-- ============================================================================

-- Public methods
-- ============================================================================

function Ux.CurrencyWindow.New(title, character, location, itemSize, sorting)
	-- Sort curreny by name
	local self = Ux.EquipmentWindow.New(title, character, location, itemSize, "name")
	
	-- Disable the sort button as it doesn't make sense
	self.titleBar:SetSortSelectorCallback(nil)

	self.groupFunc = Group.Default.GetCurrencyGroup
	
	self:SetCharacter(character, location)
	
	return self
end
