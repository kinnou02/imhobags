local Addon, private = ...

-- Globals
local UICreateFrame = UI.CreateFrame

-- Locals
local metatable = { }
local width = 20
local height = 20

private.Ux.ItemWindowTemplate = private.Ux.ItemWindowTemplate or { }
private.Ux.ItemWindowTemplate.TitleBarButton = setmetatable({ }, metatable)

setfenv(1, private)

-- Private methods
-- ============================================================================

-- Public methods
-- ============================================================================

function metatable.__call(_, parent, source, texture, dx, dy, offsetx, offsety, callback)
	local self = UICreateFrame("Frame", "", parent)
	self:SetHeight(20)
	self:SetWidth(20)
	self:SetMouseMasking("limited")
	self.Event.LeftUp = callback
	
	local tex = UICreateFrame("Texture", "", self)
	tex:SetTexture(source, texture)
	tex:SetPoint("CENTER", self, "CENTER", offsetx or 0, offsety or 0)
	tex:SetWidth(dx or tex:GetWidth())
	tex:SetHeight(dy or tex:GetHeight())

	function self:SetTexture(source, texture, dx, dy, offsetx, offsety)
		tex:SetTexture(source, texture)
		tex:SetPoint("CENTER", self, "CENTER", offsetx or 0, offsety or 0)
		tex:SetWidth(dx or tex:GetWidth())
		tex:SetHeight(dy or tex:GetHeight())
	end
	function self:SetCallback(callback)
		self.Event.LeftUp = callback
	end
	return self
end
