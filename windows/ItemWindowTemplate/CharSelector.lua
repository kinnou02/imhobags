local Addon, private = ...

-- Builtins
local floor = math.floor
local ipairs = ipairs
local max = math.max
local min = math.min
local sort = table.sort

-- Globals
local InspectMouse = Inspect.Mouse
local UICreateFrame = UI.CreateFrame

-- Locals
local metatable = { }

private.Ux.ItemWindowTemplate = private.Ux.ItemWindowTemplate or { }
private.Ux.ItemWindowTemplate.CharSelector = setmetatable({ }, metatable)

setfenv(1, private)

local backgroundOffset = 3
local backgroundWidth = 128
local backgroundHeight = 128

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
	self.animation = Animate.easeInOut(self:GetHeight(), backgroundHeight, 0.3, tick, function()
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

local function createItem(self, i)
	local item = UICreateFrame("Texture", "", self.scrolling)
	item:SetTexture("Rift", "dropdown_bar_(normal).png.dds")
	item:SetWidth(itemWidth)
	item:SetHeight(itemHeight)
	item:SetPoint("TOPCENTER", self.scrolling, "TOPCENTER", 0, itemSpacing + (i - 1) * (itemHeight + itemSpacing))
	
	local text = UICreateFrame("Text", "", item)
	text:SetPoint("CENTER", item, "CENTER")
	text:SetFontColor(245 / 255, 240 / 255, 198 / 255)

	local clickable = UICreateFrame("Frame", "", text)
	clickable:SetPoint("CENTER", text, "CENTER")
	clickable:SetWidth(itemWidth)
	clickable:SetHeight(itemClickableHeight)

	function clickable.Event.LeftUp()
		fadeOut(self)
		self.callback(text:GetText())
	end

	item.text = text
	return item
end

local function showForChars(self, chars)
	fadeIn(self)

	sort(chars)
	self.chars = chars
	
	for i = 1, #chars do
		if(not self.items[i]) then
			self.items[i] = createItem(self, i)
		end
		local item = self.items[i]
		item:SetVisible(true)
		item.text:SetText(chars[i])
	end
	
	for i = #chars + 1, #self.items do
		self.items[i]:SetVisible(false)
	end
	
	self.itemsHeight = itemSpacing / 2 + (#self.chars - 1) * (itemHeight + itemSpacing)
	local left, top, right, bottom = self.mask:GetBounds()
	self.visibleHeight = bottom - top - (itemHeight + itemSpacing)
end

local function makeScrollable(self, hotArea)
	function hotArea.Event.MouseMove()
		if(self.itemsHeight > self.visibleHeight) then
			local top, bottom = self.mask:GetTop(), self.mask:GetBottom()
			top = top + (itemHeight + itemSpacing) / 2
			bottom = bottom - (itemHeight + itemSpacing) / 2
			local mouse = InspectMouse()
			
			mouse.y = max(top, mouse.y)
			mouse.y = min(bottom, mouse.y)
			mouse.y = (mouse.y - top) / self.visibleHeight
			
			self.scrolling:SetPoint("TOPCENTER", self.mask, "TOPCENTER", 0, floor(mouse.y * (self.visibleHeight - self.itemsHeight)))
		end
	end
end

-- Public methods
-- ============================================================================

local function new(_, parent, titleBar)
	local self = UICreateFrame("Mask", "", Ux.TooltipContext)
	self:SetWidth(backgroundWidth)
	self:SetHeight(0)
	
	local background = UICreateFrame("Texture", "", self)
	background:SetPoint("BOTTOMCENTER", self, "BOTTOMCENTER")
	background:SetTexture("Rift", "dropdown_list.png.dds")
	
	self.mask = UICreateFrame("Mask", "", background)
	self.mask:SetPoint("TOPLEFT", background, "TOPLEFT", contentPaddingLeft, contentPaddingTop)
	self.mask:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", -contentPaddingLeft, -contentPaddingBottom)
	
	self.scrolling = UICreateFrame("Frame", "", self.mask)
	self.scrolling:SetPoint("TOPCENTER", self.mask, "TOPCENTER")
	
	local hotArea = UICreateFrame("Frame", "", self)
	hotArea:SetLayer(100)
	hotArea:SetAllPoints(self)
	hotArea:SetMouseMasking("limited")
	
	self.chars = { }
	self.items = { }
	makeScrollable(self, hotArea)
	
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
	
	self.ShowForChars = showForChars
	self.FadeIn = fadeIn
	self.FadeOut = fadeOut
	return self
end

metatable.__call = new
