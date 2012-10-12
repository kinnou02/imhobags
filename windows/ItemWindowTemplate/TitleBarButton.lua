local Addon, private = ...

-- Globals
local UICreateFrame = UI.CreateFrame

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
	local self = UICreateFrame("Frame", "", parent)
	self:SetWidth(width)
	self:SetHeight(height)
	self:SetMouseMasking("limited")
	self.Event.LeftClick = callback
	
	local tex = UICreateFrame("Texture", "", self)
	tex:SetTextureAsync(source, texture)
	tex:SetPoint("CENTER", self, "CENTER", offsetx or 0, offsety or 0)
	tex:SetWidth(dx or tex:GetWidth())
	tex:SetHeight(dy or tex:GetHeight())

	function self:SetTexture(source, texture, dx, dy, offsetx, offsety)
		tex:SetTextureAsync(source, texture)
		tex:SetPoint("CENTER", self, "CENTER", offsetx or 0, offsety or 0)
		tex:SetWidth(dx or tex:GetWidth())
		tex:SetHeight(dy or tex:GetHeight())
	end
	function self:SetCallback(callback)
		self.Event.LeftClick = callback
	end
	return self
end
