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
	self:SetTooltip(tooltip)
	
	self:EventAttach(Event.UI.Input.Mouse.Cursor.Move, function(self)
		self:SetHighlighted(true)
		self:ShowTooltip()
	end, "")
	self:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function(self)
		self:SetHighlighted(false)
		self:SetDepressed(false)
		self:HideTooltip()
	end, "")
	
	self:EventAttach(Event.UI.Input.Mouse.Left.Down, function(self)
		self:SetDepressed(true)
	end, "")
	self:EventAttach(Event.UI.Input.Mouse.Left.Up, function(self)
		self:SetDepressed(false)
	end, "")
	self:EventAttach(Event.UI.Input.Mouse.Left.Click, function(self)
		self:LeftPress()
	end, "")
	
	return self
end
