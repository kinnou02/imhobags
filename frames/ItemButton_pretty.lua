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
	common =		"img://../../art/project/UI/texture/global/icons/icon_border.dds",
	epic =			"img://../../art/project/UI/texture/global/icons/icon_border_epic.dds",
	quest =			"img://../../art/project/UI/texture/global/icons/icon_border_quest.dds",
	rare =			"img://../../art/project/UI/texture/global/icons/icon_border_rare.dds",
	relic =			"img://../../art/project/UI/texture/global/icons/icon_border_relic.dds",
	sellable =		"img://../../art/project/UI/texture/global/icons/icon_border_disabled.dds",
	transcendant =	"img://../../art/project/UI/texture/global/icons/icon_border_relic.dds",
	uncommon =		"img://../../art/project/UI/texture/global/icons/icon_border_uncommon.dds",
}
-- preload external textures
for i, v in ipairs({ "common", "epic", "quest", "rare", "relic", "sellable", "transcendant", "uncommon" }) do
	local tex = UICreateFrame("Texture", "", Ux.Context)
--	tex:SetTexture("ImhoBags", "textures/ItemButton/common.png")
	tex:SetTexture("Rift", rarityTextureMap[v])
	tex:SetVisible(false)
--	log(tex:GetWidth(), tex:GetHeight())
end

-- Public methods
-- ============================================================================

local function ItemButton_pretty_SetRarity(self, rarity)
--	self.border:SetTextureAsync("ImhoBags", "textures/ItemButton/" .. (rarity or "common") .. ".png")
	self.border:SetTextureAsync("Rift", rarityTextureMap[rarity or "common"])
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
--	self.border:SetPoint("CENTER", self, "CENTER")
	self.border:SetPoint("TOPLEFT", self, -0.14, -0.14)
	self.border:SetPoint("BOTTOMRIGHT", self, 1.14, 1.14)
	self.border:SetLayer(4)
	
	self.SetRarity = ItemButton_pretty_SetRarity
	self.SetDepressed = ItemButton_pretty_SetDepressed
	
	return self
end
