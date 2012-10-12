local Addon, private = ...

-- Bulitins
local ipairs = ipairs

-- Globals
local Command = Command
local UICreateFrame = UI.CreateFrame

-- Locals
local iconSize = 48

setfenv(1, private)
Ux = Ux or { }
Ux.ItemButton_pretty = { }

-- Private methods
-- ============================================================================

local rarityTextureMap = {
	common =		"icon_border.dds",
	epic =			"icon_border_epic.dds",
	quest =			"icon_border_quest.dds",
	rare =			"icon_border_rare.dds",
	relic =			"icon_border_relic.dds",
	sellable =		"icon_border_disabled.dds",
	transcendant =	"icon_border_relic.dds",
	uncommon =		"icon_border_uncommon.dds",
}
-- preload external textures
for i, v in ipairs({ "common", "epic", "quest", "rare", "relic", "sellable", "transcendant", "uncommon" }) do
	local tex = UICreateFrame("Texture", "", Ux.Context)
	tex:SetTexture("Rift", rarityTextureMap[v])
	tex:SetVisible(false)
end

-- Public methods
-- ============================================================================

local function ItemButton_pretty_SetRarity(self, rarity)
	if(rarity == "empty") then
		self.border:SetTextureAsync("Rift", "icon_empty.png.dds")
		self.backdrop:SetBackgroundColor(0, 0, 0, 0)
	else
		self.border:SetTextureAsync("Rift", rarityTextureMap[rarity or "common"])
		self.backdrop:SetBackgroundColor(0, 0, 0)
	end
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
	
	self.border = UICreateFrame("Texture", "", self)
	self.border:SetPoint("TOPLEFT", self, -0.14, -0.14)
	self.border:SetPoint("BOTTOMRIGHT", self, 1.14, 1.14)
	self.border:SetLayer(4)
	
	self.SetRarity = ItemButton_pretty_SetRarity
	self.SetDepressed = ItemButton_pretty_SetDepressed
	
	return self
end
