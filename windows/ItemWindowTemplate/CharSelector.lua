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
local backgroundWidth = 128
local backgroundHeight = 128

local itemWidth = 100
local itemHeight = 32
local itemSpacing = -10
local itemClickableHeight = 20

local contentPaddingTop = 1
local contentPaddingLeft = 7
local contentPaddingBottom = 9

local textColor = { 245 / 255, 240 / 255, 198 / 255 }

setfenv(1, private)
Ux.ItemWindowTemplate = Ux.ItemWindowTemplate or { }

-- Private methods
-- ============================================================================

local function createItem(self, i)
	local item = UICreateFrame("Texture", "", self.scrolling)
	item:SetTexture("Rift", "dropdown_bar_(normal).png.dds")
	item:SetWidth(itemWidth)
	item:SetHeight(itemHeight)
	item:SetPoint("TOPCENTER", self.scrolling, "TOPCENTER", 0, itemSpacing / 2 + (i - 1) * (itemHeight + itemSpacing))
	
	local text = UICreateFrame("Text", "", item)
	text:SetPoint("CENTER", item, "CENTER")
	text:SetFontColor(textColor[1], textColor[2], textColor[3])

	local clickable = UICreateFrame("Frame", "", text)
	clickable:SetPoint("CENTER", text, "CENTER")
	clickable:SetWidth(itemWidth)
	clickable:SetHeight(itemClickableHeight)

	function clickable.Event.LeftUp()
		self:FadeOut()
		self.callback(text:GetText())
	end

	item.text = text
	return item
end

local function showForChars(self, chars)
	self:FadeIn()

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

function Ux.ItemWindowTemplate.CharSelector(parent, titleBar)
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
	
	self.chars = { }
	self.items = { }
	
	function self:SetCallback(callback)
		self.callback = callback
	end
	
	makeScrollable(self, Ux.ItemWindowTemplate.FadingPopup.MakeFadeable(self, titleBar, backgroundHeight))

	self.ShowForChars = showForChars
	return self
end