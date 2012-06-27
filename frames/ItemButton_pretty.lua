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

-- preload external textures
for i, v in ipairs({ "common", "epic", "quest", "rare", "relic", "sellable", "transcendent", "uncommon" }) do
	local tex = UICreateFrame("Texture", "", Ux.Context)
	tex:SetTexture("ImhoBags", "textures/ItemButton/common.png")
	tex:SetVisible(false)
end

-- Public methods
-- ============================================================================

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
	Command.System.Watchdog.Quiet()
	
	local self = Ux.ItemButton_simple.New(parent)
	
	self.backdrop:SetPoint("TOPLEFT", self, "TOPLEFT", 1, 1)
	self.backdrop:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -1, -1)
	
	self.border = UICreateFrame("Texture", "", self)
	self.border:SetPoint("TOPLEFT", self, "TOPLEFT")
	self.border:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
	self.border:SetLayer(4)
	
	self.SetRarity = ItemButton_pretty_SetRarity
	self.SetDepressed = ItemButton_pretty_SetDepressed
	
	return self
end
