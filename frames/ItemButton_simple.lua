local Addon, private = ...

local tostring = tostring

local UICreateFrame = UI.CreateFrame

local iconSize = 46

setfenv(1, private)
Ux = Ux or { }
Ux.ItemButton_simple = { }

-- Private methods
-- ============================================================================

-- Public methods
-- ============================================================================

local function ItemButton_simple_SetFiltered(self, filtered)
	self.icon:SetAlpha(filtered and 0.3 or 1.0)
end

local function ItemButton_simple_SetRarity(self, rarity)
	self:SetBackgroundColor(Utils.RarityColor(rarity))
end

local function ItemButton_simple_SetStack(self, stack)
	self.stackText:SetText(tostring(stack))
	self.stackBack:SetWidth(self.stackText:GetFullWidth())
	self.stackBack:SetVisible(stack > 1)
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
	self.stackText:SetLayer(self.stackBack:GetLayer() + 1)
	
	self.slotsBack = UICreateFrame("Frame", "", self)
	self.slotsBack:SetPoint("BOTTOMRIGHT", self.stackBack, "TOPRIGHT", 0, 0)
	self.slotsBack:SetHeight(12)
	self.slotsBack:SetBackgroundColor(0.0, 0.0, 0.0, 0.5)
	self.slotsBack:SetLayer(self.icon:GetLayer() + 1)
	
	self.slotsText = UICreateFrame("Text", "", self.slotsBack)
	self.slotsText:SetPoint("BOTTOMRIGHT", self.slotsBack, "BOTTOMRIGHT", 0, 3)
	self.slotsText:SetFontSize(11)
	self.slotsText:SetFontColor(0.8, 0.8, 0.8)
	self.slotsText:SetLayer(self.slotsBack:GetLayer() + 1)
	
	self.SetFiltered = ItemButton_simple_SetFiltered
	self.SetRarity = ItemButton_simple_SetRarity
	self.SetStack = ItemButton_simple_SetStack
	self.SetSlots = ItemButton_simple_SetSlots
	self.SetIcon = ItemButton_simple_SetIcon
	self.SetDepressed = ItemButton_simple_SetDepressed
	
	return self
end
