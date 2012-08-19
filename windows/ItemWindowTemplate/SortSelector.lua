local Addon, private = ...

-- Builtins

-- Globals
local InspectMouse = Inspect.Mouse
local UICreateFrame = UI.CreateFrame

-- Locals
local metatable = { }

private.Ux.ItemWindowTemplate = private.Ux.ItemWindowTemplate or { }
private.Ux.ItemWindowTemplate.SortSelector = setmetatable({ }, metatable)

setfenv(1, private)

local backgroundOffset = 3
local backgroundWidth = 160
local backgroundHeight = 32

local contentPaddingLeft = 7
local contentPaddingBottom = 9

local textColor = { 245 / 255, 240 / 255, 198 / 255 }

-- Private methods
-- ============================================================================

-- Public methods
-- ============================================================================

function metatable.__call(_, parent, titleBar)
	local self = UICreateFrame("Mask", "", Ux.TooltipContext)
	self:SetHeight(0)
	
	local background = UICreateFrame("Texture", "", self)
	background:SetPoint("BOTTOMCENTER", self, "BOTTOMCENTER")
	background:SetTexture("Rift", "dropdown_list.png.dds")
	
	local icon = UICreateFrame("Text", "", background)
	icon:SetPoint("BOTTOMCENTER", background, "BOTTOMCENTER", 0, -contentPaddingBottom)
	icon:SetFontColor(textColor[1], textColor[2], textColor[3])
	icon:SetFontSize(14)
	icon:SetText(L.Ux.SortOption.icon)
	
	local name = UICreateFrame("Text", "", background)
	name:SetPoint("RIGHTCENTER", icon, "LEFTCENTER", -contentPaddingLeft, 0)
	name:SetFontColor(textColor[1], textColor[2], textColor[3])
	name:SetFontSize(14)
	name:SetText(L.Ux.SortOption.name)
	
	local rarity = UICreateFrame("Text", "", background)
	rarity:SetPoint("LEFTCENTER", icon, "RIGHTCENTER", contentPaddingLeft, 0)
	rarity:SetFontColor(textColor[1], textColor[2], textColor[3])
	rarity:SetFontSize(14)
	rarity:SetText(L.Ux.SortOption.rarity)
	
	self:SetWidth(icon:GetWidth() + name:GetWidth() + rarity:GetWidth() + 4 * contentPaddingLeft)
	background:SetWidth(self:GetWidth())
	
	function icon.Event.LeftUp() self.callback("icon") end
	function name.Event.LeftUp() self.callback("name") end
	function rarity.Event.LeftUp() self.callback("rarity") end
	
	function self:SetCallback(callback)
		self.callback = callback
	end
	function self:SetValue(sort)
		icon:SetAlpha(sort == "icon" and 1.0 or 0.5)
		name:SetAlpha(sort == "name" and 1.0 or 0.5)
		rarity:SetAlpha(sort == "rarity" and 1.0 or 0.5)
	end
	
	Ux.ItemWindowTemplate.FadingPopup.MakeFadeable(self, titleBar, backgroundHeight + backgroundOffset)

	return self
end
