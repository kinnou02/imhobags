local Addon, private = ...

-- Builtins
local floor = math.floor
local ipairs = ipairs
local max = math.max
local min = math.min
local sort = table.sort
local tostring = tostring

-- Globals
local InspectMouse = Inspect.Mouse
local UICreateFrame = UI.CreateFrame

-- Locals
local metatable = { }

private.Ux.ItemWindowTemplate = private.Ux.ItemWindowTemplate or { }
private.Ux.ItemWindowTemplate.SizeSelector = setmetatable({ }, metatable)

setfenv(1, private)

local backgroundOffset = 3
local backgroundWidth = 160
local backgroundHeight = 32

local itemWidth = 100
local itemHeight = 32
local itemSpacing = -10
local itemClickableHeight = 20

local contentPaddingTop = 1
local contentPaddingLeft = 7
local contentPaddingBottom = 9

-- Private methods
-- ============================================================================

local function fadeIn(self)
	local function tick(width) self:SetHeight(width) end
	
	self:SetVisible(true)
	Animate.stop(self.animation)
	self.animation = Animate.easeInOut(self:GetHeight(), backgroundHeight + backgroundOffset, 0.3, tick, function()
		self.animation = 0
	end)
end

local function fadeOut(self)
	local function tick(width) self:SetHeight(width) end
	
	Animate.stop(self.animation)
	self.animation = Animate.easeInOut(self:GetHeight(), 0, 0.3, tick, function()
		self.animation = 0
		self:SetVisible(false)
	end)
end

-- Public methods
-- ============================================================================

local function new(_, parent, titleBar)
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
	indicator:SetFontColor(245 / 255, 240 / 255, 198 / 255)
	indicator:SetFontSize(14)
	indicator:SetText("50")
	
	function slider.Event.SliderChange()
		local n = slider:GetPosition() * 10
		indicator:SetText(tostring(n))
		self.callback(n)
	end
	
	local hotArea = UICreateFrame("Frame", "", self)
	hotArea:SetLayer(100)
	hotArea:SetAllPoints(self)
	hotArea:SetMouseMasking("limited")
	
	if(titleBar) then
		function hotArea.Event.MouseOut()
			if(not titleBar:IsMouseHot()) then
				titleBar:FadeOut()
			end
			fadeOut(self)
		end
	else
		function hotArea.Event.MouseOut()
			fadeOut(self)
		end
	end
	
	function self:SetCallback(callback)
		self.callback = callback
	end
	function self:SetValue(n)
		slider:SetPosition(n / 10)
		indicator:SetText(tostring(n))
	end
	
	self.FadeIn = fadeIn
	self.FadeOut = fadeOut
	return self
end

metatable.__call = new
