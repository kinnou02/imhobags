local Addon, private = ...

-- Builtins
local tostring = tostring
local type = type

-- Globals
local Inspect = Inspect
local UIParent = UIParent

-- Locals
local UICreateFrame = UI.CreateFrame

local stackFontSizes = {
	[30] = 10,
	[40] = 12,
	[50] = 14,
	[60] = 16,
}

setfenv(1, private)
Ux = Ux or { }
Ux.ItemButton_simple = { }

-- Private methods
-- ============================================================================

local highlight = UICreateFrame("Texture", "", Ux.Context)
highlight:SetTexture("Rift", "IconSlot_Blue_Blur_Glow.png.dds")
highlight:SetVisible(false)
highlight:SetLayer(3)

local tooltip = UICreateFrame("Text", "", Ux.TooltipContext)
tooltip:SetBackgroundColor(0, 0, 0, 0.75)
tooltip:SetText("")
tooltip:SetVisible(false)

-- Public methods
-- ============================================================================

local function SetFiltered(self, filtered)
	self.icon:SetAlpha(filtered and 0.3 or 1.0)
end

local function SetHighlighted(self, highlighted)
	highlight:SetVisible(highlighted)
	if(highlighted) then
		highlight:SetParent(self)
		highlight:SetPoint("TOPLEFT", self, -0.14, -0.14)
		highlight:SetPoint("BOTTOMRIGHT", self, 1.14, 1.14)
	end
end

local function ShowHighlight(self)
	highlight:SetVisible(true)
end

local function SetRarity(self, rarity)
	if(rarity == "empty") then
		self:SetBackgroundColor(Item.Type.Color("sellable"))
	else
		self:SetBackgroundColor(Item.Type.Color(rarity))
	end
end

local function SetStack(self, stack)
	if(type(stack) == "string") then
		self.stackText:SetText(stack)
		self.stackBack:SetVisible(stack ~= "")
	else
		self.stackText:SetText(tostring(stack))
		self.stackBack:SetVisible(stack > 1)
	end
	if(self.stackBack:GetVisible()) then
		local fontSize = stackFontSizes[self:GetWidth()] or 14
		self.stackText:SetFontSize(fontSize)
		self.stackText:SetPoint("BOTTOMRIGHT", self.backdrop, "BOTTOMRIGHT", 0, 4)
		
		local tw = self.stackText:GetWidth()
		local iw = self.icon:GetWidth()
		if(tw > iw) then
			self.stackText:SetFontSize(fontSize * iw / tw)
		end
		self.stackBack:SetWidth(self.stackText:GetWidth())
	end
end

local function SetSlots(self, slots)
	self.slotsText:SetText(tostring(slots))
	self.slotsBack:SetWidth(self.slotsText:GetWidth())
	self.slotsBack:SetVisible(slots > 1)
end

local function SetIcon(self, icon)
	self.icon:SetTextureAsync("Rift", icon)
end

local function SetDepressed(self, depressed)
	if(depressed) then
		self.icon:SetPoint("TOPLEFT", self.backdrop, "TOPLEFT", 2, 2)
		self.icon:SetPoint("BOTTOMRIGHT", self.backdrop, "BOTTOMRIGHT", -2, -2)
	else
		self.icon:SetPoint("TOPLEFT", self.backdrop, "TOPLEFT")
		self.icon:SetPoint("BOTTOMRIGHT", self.backdrop, "BOTTOMRIGHT")
	end
end

local function SetBound(self, bound, bind)
	self.bind:SetVisible(bound == true)
	if(bound) then
		self.bind:SetTextureAsync("Rift", bind == "account" and "elementalward3.dds" or "soulbind.dds")
	end
end

local function SetTooltip(self, tooltip)
	self.tooltip = tooltip
end

local function SetAvailable(self, available)
	self:SetAlpha(available and 1.0 or Const.ItemButtonUnavailableAlpha)
	self.available = available
end

local function ShowTooltip(self)
	if(self.tooltip) then
		tooltip:SetText(self.tooltip)
		local mouse = Inspect.Mouse()
		local width, height = tooltip:GetWidth(), tooltip:GetHeight()
		local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
		local anchor
		if(mouse.y <= height) then
			anchor = "TOP"
			if(mouse.x < width) then
				anchor = anchor .. "LEFT"
				mouse.x = mouse.x + 20
			else
				anchor = anchor .. "RIGHT"
			end
		else
			anchor = "BOTTOM" .. ((mouse.x + width > screenWidth) and "RIGHT" or "LEFT")
		end
		tooltip:ClearAll()
		tooltip:SetPoint(anchor, UIParent, "TOPLEFT", mouse.x, mouse.y)
		tooltip:SetVisible(true)
	end
end

local function HideTooltip(self)
	tooltip:SetVisible(false)
end

local function SetSize(self, size)
	if(self.size == size) then
		return
	end
	self.size = size
	self:SetWidth(size)
	self:SetHeight(size)
	
	self.gridx = -1
	self.gridy = -1
	
	local fontSize = stackFontSizes[self:GetWidth()] or 14
	self.stackBack:SetHeight(fontSize)
	self.stackText:SetFontSize(fontSize)
	self.stackText:SetPoint("BOTTOMRIGHT", self.backdrop, "BOTTOMRIGHT", 0, 4)
end

function Ux.ItemButton_simple.New(parent)
	local self = UICreateFrame("Frame", "ImhoBags_ItemButton", parent)
	
	self.backdrop = UICreateFrame("Frame", "", self)
	self.backdrop:SetBackgroundColor(0.0, 0.0, 0.0)
	self.backdrop:SetPoint("TOPLEFT", self, "TOPLEFT", 2, 2)
	self.backdrop:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -2, -2)
	
	self.icon = UICreateFrame("Texture", "", self.backdrop)
	self.icon:SetPoint("TOPLEFT", self.backdrop, "TOPLEFT")
	self.icon:SetPoint("BOTTOMRIGHT", self.backdrop, "BOTTOMRIGHT")

	self.stackBack = UICreateFrame("Frame", "", self)
	self.stackBack:SetPoint("BOTTOMRIGHT", self.backdrop, "BOTTOMRIGHT", 0, 0)
	self.stackBack:SetHeight(14)
	self.stackBack:SetBackgroundColor(0.0, 0.0, 0.0, 0.5)
	self.stackBack:SetLayer(self.icon:GetLayer() + 1)
	
	self.stackText = UICreateFrame("Text", "", self.stackBack)
	self.stackText:SetPoint("BOTTOMRIGHT", self.backdrop, "BOTTOMRIGHT", 0, 5)
	self.stackText:SetFontSize(14)
	
	self.slotsBack = UICreateFrame("Frame", "", self)
	self.slotsBack:SetPoint("BOTTOMRIGHT", self.stackBack, "TOPRIGHT", 0, 0)
	self.slotsBack:SetHeight(12)
	self.slotsBack:SetBackgroundColor(0.0, 0.0, 0.0, 0.5)
	self.slotsBack:SetLayer(self.icon:GetLayer() + 1)
	
	self.slotsText = UICreateFrame("Text", "", self.slotsBack)
	self.slotsText:SetPoint("BOTTOMRIGHT", self.slotsBack, "BOTTOMRIGHT", 0, 3)
	self.slotsText:SetFontSize(10)
	self.slotsText:SetFontColor(0.8, 0.8, 0.8)
	
	self.bind = UICreateFrame("Texture", "", self)
	self.bind:SetPoint("TOPRIGHT", self.icon, "TOPRIGHT")
	self.bind:SetPoint("BOTTOMLEFT", self.icon, 0.66, 0.33)
	self.bind:SetTexture("Rift", "soulbind.dds")
	self.bind:SetAlpha(0.8)
	self.bind:SetLayer(self.icon:GetLayer() + 1)

	self.SetHighlighted = SetHighlighted
	self.ShowHighlight = ShowHighlight
	self.SetFiltered = SetFiltered
	self.SetRarity = SetRarity
	self.SetStack = SetStack
	self.SetSlots = SetSlots
	self.SetIcon = SetIcon
	self.SetDepressed = SetDepressed
	self.SetBound = SetBound
	self.SetTooltip = SetTooltip
	self.SetAvailable = SetAvailable
	self.ShowTooltip = ShowTooltip
	self.HideTooltip = HideTooltip
	self.SetSize = SetSize
	
	self:SetStack(0)
	self:SetSlots(0)
	
	return self
end
