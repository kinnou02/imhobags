local Addon, private = ...

local tostring = tostring

local UICreateFrame = UI.CreateFrame

local iconSize = 46

setfenv(1, private)
Ux = Ux or { }
Ux.ItemButton_simple = { }

-- Private methods
-- ============================================================================

local highlight = UICreateFrame("Texture", "", Ux.Context)
highlight:SetTexture("ImhoBags", "textures/ItemButton/highlight.png")
highlight:SetVisible(false)
highlight:SetLayer(3)

-- Public methods
-- ============================================================================

local function ItemButton_simple_SetFiltered(self, filtered)
	self.icon:SetAlpha(filtered and 0.3 or 1.0)
end

local function ItemButton_simple_SetHighlighted(self, highlighted)
	highlight:SetVisible(highlighted)
	if(highlighted) then
		highlight:SetParent(self)
		highlight:SetAllPoints(self)
	end
end

local function ItemButton_simple_ShowHighlight(self)
	highlight:SetVisible(true)
end

local function ItemButton_simple_SetRarity(self, rarity)
	self:SetBackgroundColor(Utils.RarityColor(rarity))
end

local function ItemButton_simple_SetStack(self, stack)
	self.stackText:SetText(tostring(stack))
	self.stackBack:SetWidth(self.stackText:GetFullWidth())
	self.stackBack:SetVisible(stack > 1)
	if(stack >= 100000) then
		self.stackText:SetFontSize(12)
		self.stackText:SetPoint("BOTTOMRIGHT", self.backdrop, "BOTTOMRIGHT", 0, 3)
	else
		self.stackText:SetFontSize(14)
		self.stackText:SetPoint("BOTTOMRIGHT", self.backdrop, "BOTTOMRIGHT", 0, 5)
	end
end

local function ItemButton_simple_SetSlots(self, slots)
	self.slotsText:SetText(tostring(slots))
	self.slotsBack:SetWidth(self.slotsText:GetFullWidth())
	self.slotsBack:SetVisible(slots > 1)
end

local function ItemButton_simple_SetIcon(self, icon)
	self.icon:SetTexture("Rift", icon)
end

local function ItemButton_simple_SetDepressed(self, depressed)
	if(depressed) then
		self.icon:SetPoint("TOPLEFT", self.backdrop, "TOPLEFT", 2, 2)
		self.icon:SetPoint("BOTTOMRIGHT", self.backdrop, "BOTTOMRIGHT", -2, -2)
	else
		self.icon:SetPoint("TOPLEFT", self.backdrop, "TOPLEFT")
		self.icon:SetPoint("BOTTOMRIGHT", self.backdrop, "BOTTOMRIGHT")
	end
end

local function ItemButton_simple_SetBound(self, bound)
	self.bound:SetVisible(bound == true)
end

function Ux.ItemButton_simple.New(parent)
	local self = UICreateFrame("Frame", "ImhoBags_ItemButton", parent)
	
	self:SetWidth(Ux.ItemButtonSize)
	self:SetHeight(Ux.ItemButtonSize)
	
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
	self.slotsText:SetFontSize(11)
	self.slotsText:SetFontColor(0.8, 0.8, 0.8)
	
	self.bound = UICreateFrame("Texture", "", self)
	self.bound:SetPoint("TOPRIGHT", self.icon, "TOPRIGHT")
	self.bound:SetTexture("Rift", [[Data/\UI\ability_icons\soulbind.dds]])
	self.bound:SetWidth(self.icon:GetWidth() / 3)
	self.bound:SetHeight(self.bound:GetWidth())
	self.bound:SetAlpha(0.8)
	self.bound:SetLayer(self.icon:GetLayer() + 1)

	self.SetHighlighted = ItemButton_simple_SetHighlighted
	self.ShowHighlight = ItemButton_simple_ShowHighlight
	self.SetFiltered = ItemButton_simple_SetFiltered
	self.SetRarity = ItemButton_simple_SetRarity
	self.SetStack = ItemButton_simple_SetStack
	self.SetSlots = ItemButton_simple_SetSlots
	self.SetIcon = ItemButton_simple_SetIcon
	self.SetDepressed = ItemButton_simple_SetDepressed
	self.SetBound = ItemButton_simple_SetBound
	
	self:SetStack(0)
	self:SetSlots(0)
	
	return self
end
