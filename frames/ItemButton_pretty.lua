local Addon, private = ...

local UICreateFrame = UI.CreateFrame

local iconSize = 48

setfenv(1, private)
Ux = Ux or { }
Ux.ItemButton_pretty = { }

-- Private methods
-- ============================================================================

-- Public methods
-- ============================================================================

local function ItemButton_pretty_SetHighlighted(self, highlighted)
	self.highlight:SetVisible(highlighted)
end

local function ItemButton_pretty_SetRarity(self, rarity)
	self.border:SetTexture("ImhoBags", "textures/ItemButton/" .. (rarity or "common") .. ".png")
end

local function ItemButton_pretty_SetDepressed(self, depressed)
	if(depressed) then
		self.icon:SetPoint("TOPLEFT", self.backdrop, "TOPLEFT", 2, 2)
		self.icon:SetPoint("BOTTOMRIGHT", self.backdrop, "BOTTOMRIGHT", -2, -2)
	else
		self.icon:SetPoint("TOPLEFT", self.backdrop, "TOPLEFT")
		self.icon:SetPoint("BOTTOMRIGHT", self.backdrop, "BOTTOMRIGHT")
	end
end

function Ux.ItemButton_pretty.New(parent)
	local self = Ux.ItemButton_simple.New(parent)
	
	self.backdrop:SetPoint("TOPLEFT", self, "TOPLEFT", 1, 1)
	self.backdrop:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -1, -1)
	
	self.highlight = UICreateFrame("Texture", "", self)
	self.highlight:SetTexture("ImhoBags", "textures/ItemButton/highlight.png")
	self.highlight:SetAllPoints(self)
	self.highlight:SetLayer(self.icon:GetLayer() + 1)
	self.highlight:SetVisible(false)
	
	self.stackBack:SetLayer(self.highlight:GetLayer() + 1)
	self.stackText:SetLayer(self.stackBack:GetLayer() + 1)
	
	self.slotsBack:SetLayer(self.highlight:GetLayer() + 1)
	self.slotsText:SetLayer(self.slotsBack:GetLayer() + 1)

	self.border = UICreateFrame("Texture", "", self)
	self.border:SetPoint("TOPLEFT", self, "TOPLEFT")
	self.border:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
	self.border:SetLayer(self.stackText:GetLayer() + 1)
	
	self.SetHighlighted = ItemButton_pretty_SetHighlighted
	self.SetRarity = ItemButton_pretty_SetRarity
	self.SetDepressed = ItemButton_pretty_SetDepressed
	
	return self
end
