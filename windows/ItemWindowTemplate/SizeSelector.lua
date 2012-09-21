local Addon, private = ...

-- Builtins
local tostring = tostring

-- Globals
local UICreateFrame = UI.CreateFrame

-- Locals
local backgroundOffset = 3
local backgroundWidth = 160
local backgroundHeight = 32

local textColor = { 245 / 255, 240 / 255, 198 / 255 }

setfenv(1, private)
Ux.ItemWindowTemplate = Ux.ItemWindowTemplate or { }

-- Private methods
-- ============================================================================

-- Public methods
-- ============================================================================

function Ux.ItemWindowTemplate.SizeSelector(parent, titleBar)
	local self = UICreateFrame("Mask", "", Ux.TooltipContext)
	self:SetWidth(backgroundWidth)
	self:SetHeight(0)
	
	local background = UICreateFrame("Texture", "", self)
	background:SetPoint("BOTTOMCENTER", self, "BOTTOMCENTER")
	background:SetWidth(self:GetWidth())
	background:SetTexture("Rift", "dropdown_list.png.dds")
	
	local slider = UICreateFrame("RiftSlider", "", background)
	slider:SetPoint("BOTTOMCENTER", background, "BOTTOMCENTER", -14, 0)
	slider:SetWidth(self:GetWidth() - 64)
	slider:SetRange(3, 6)
	slider:SetPosition(3)
	
	local indicator = UICreateFrame("Text", "", background)
	indicator:SetPoint("LEFTCENTER", slider, "RIGHTCENTER", 10, -6)
	indicator:SetFontColor(textColor[1], textColor[2], textColor[3])
	indicator:SetFontSize(14)
	indicator:SetText("50")
	
	function slider.Event.SliderChange()
		local n = slider:GetPosition() * 10
		indicator:SetText(tostring(n))
		self.callback(n)
	end
	
	function self:SetCallback(callback)
		self.callback = callback
	end
	function self:SetValue(n)
		slider:SetPosition(n / 10)
		indicator:SetText(tostring(n))
	end
	
	Ux.ItemWindowTemplate.FadingPopup.MakeFadeable(self, titleBar, backgroundHeight + backgroundOffset)

	return self
end
