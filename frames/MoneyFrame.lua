local Addon, private = ...

local floor = math.floor
local tostring = tostring

local UICreateFrame = UI.CreateFrame

setfenv(1, private)
Ux = Ux or { }
Ux.MoneyFrame = { }

local iconWidth = 18

-- Private methods
-- ============================================================================

local function setCoin(self, coin)
	coin = coin or 0
	
	local p = floor(coin / 10000)
	local g = floor(coin / 100 % 100)
	local s = coin % 100
	
	self.stxt:SetText(tostring(s))
	self.gtxt:SetText(tostring(g))
	self.ptxt:SetText(tostring(p))
	
	local width = iconWidth + 23
	
	if(coin >= 100) then
		width = width + iconWidth + 23
		self.g:SetVisible(true)
		if(coin >= 10000) then
			width = width + iconWidth + self.ptxt:GetFullWidth()
			self.p:SetVisible(true)
		else
			self.p:SetVisible(false)
		end
	else
		self.g:SetVisible(false)
		self.p:SetVisible(false)
	end
	
	self:SetWidth(width)
end

-- Public methods
-- ============================================================================

function Ux.MoneyFrame.New(parent, coin)
	local self = UICreateFrame("Frame", "ImhoBags.Ux.MoneyFrame", parent)
	self:SetHeight(16)
	
	local s = UICreateFrame("Texture", "", self)
	s:SetPoint("TOPRIGHT", self, "TOPRIGHT")
	s:SetWidth(iconWidth)
	s:SetTexture("Rift", "coins_silver.png.dds")
	local stxt = UICreateFrame("Text", "", s)
	stxt:SetPoint("RIGHTCENTER", s, "LEFTCENTER")
	stxt:SetFontSize(13)
	
	local g = UICreateFrame("Texture", "", self)
	g:SetPoint("TOPRIGHT", s, "TOPLEFT", -23, 0)
	g:SetWidth(iconWidth)
	g:SetTexture("Rift", "coins_gold.png.dds")
	local gtxt = UICreateFrame("Text", "", g)
	gtxt:SetPoint("RIGHTCENTER", g, "LEFTCENTER")
	gtxt:SetFontSize(13)
	
	local p = UICreateFrame("Texture", "", self)
	p:SetPoint("TOPRIGHT", g, "TOPLEFT", -23, 0)
	p:SetWidth(iconWidth)
	p:SetTexture("Rift", "coins_platinum.png.dds")
	local ptxt = UICreateFrame("Text", "", p)
	ptxt:SetPoint("RIGHTCENTER", p, "LEFTCENTER")
	ptxt:SetFontSize(13)
	
	
	self.s = s
	self.stxt = stxt
	self.g = g
	self.gtxt = gtxt
	self.p = p
	self.ptxt = ptxt
	
	self.SetCoin = setCoin
	self:SetCoin(coin or 0)
	
	return self
end
