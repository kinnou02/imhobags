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
	
	if(location == "currency") then
		self.currencyButton:SetIcon([[Data/\UI\item_icons\bag20.dds]])
		self.currencyButton:SetTooltip(L.Ux.WindowTitle.inventory)
		function self.currencyButton.LeftPress()
			Ux.ToggleItemWindow(self.character, "inventory")
		end
	end
	
	-- Disable the sort button as it doesn't make sense
	self.sortButton:SetVisible(false)

	self.groupFunc = Group.Default.GetCurrencyGroup
	
	self:SetCharacter(character, location)
	
	return self
end
