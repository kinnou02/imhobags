local Addon, private = ...

-- Locals
local width = 20
local height = 20

setfenv(1, private)
Ux.ItemWindowTemplate = Ux.ItemWindowTemplate or { }

-- Private methods
-- ============================================================================

-- Public methods
-- ============================================================================

function Ux.ItemWindowTemplate.TitleBarButton(parent, source, texture, dx, dy, offsetx, offsety, callback)
	local self = UI.CreateFrame("Frame", "", parent)
	self:SetWidth(width)
	self:SetHeight(height)
	self:SetMouseMasking("limited")
	self:EventAttach(Event.UI.Input.Mouse.Left.Click, callback, "")
	self.callback = callback
	
	local tex = UI.CreateFrame("Texture", "", self)
	tex:SetPoint("CENTER", self, "CENTER", offsetx or 0, offsety or 0)
	tex:SetTextureAsync(source, texture, function()
		tex:SetWidth(dx or tex:GetWidth())
		tex:SetHeight(dy or tex:GetHeight())
	end)

	function self:SetTexture(source, texture, dx, dy, offsetx, offsety)
		tex:SetTextureAsync(source, texture)
		tex:SetPoint("CENTER", self, "CENTER", offsetx or 0, offsety or 0)
		tex:SetWidth(dx or tex:GetWidth())
		tex:SetHeight(dy or tex:GetHeight())
	end
	function self:SetCallback(callback)
		self:EventDetach(Event.UI.Input.Mouse.Left.Click, self.callback)
		self:EventAttach(Event.UI.Input.Mouse.Left.Click, callback, "")
	end
	return self
end
