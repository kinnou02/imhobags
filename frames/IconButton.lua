local Addon, private = ...

setfenv(1, private)
Ux = Ux or { }
Ux.IconButton = { }

Ux.DefaultIconButtonSize = 30

-- Private methods
-- ============================================================================

-- Public methods
-- ============================================================================

function Ux.IconButton.New(parent, icon, tooltip, size)
	local self = Ux.ItemButton_pretty.New(parent)
	self:SetWidth(size or Ux.DefaultIconButtonSize)
	self:SetHeight(size or Ux.DefaultIconButtonSize)
	self:SetIcon(icon)
	self:SetRarity("common")
	self:SetBound(false)
	self.clicked = false
	self:SetTooltip(tooltip)
	
	function self.Event.MouseIn()
		self:SetHighlighted(true)
		self:ShowTooltip()
	end
	function self.Event.MouseMove()
		self:SetHighlighted(true)
		self:ShowTooltip()
	end
	function self.Event.MouseOut()
		self:SetHighlighted(false)
		self:SetDepressed(false)
		self:HideTooltip()
	end
	
	function self.Event.LeftDown()
		self:SetDepressed(true)
		self.clicked = true
	end
	function self.Event.LeftUp()
		self:SetDepressed(false)
		if(self.clicked and self.LeftPress) then
			self:LeftPress()
		end
		self.clicked = false
	end
	function self.Event.LeftUpoutside()
		self.clicked = false
	end
	
	return self
end
