local Addon, private = ...

local floor = math.floor
local tostring = tostring

local UICreateFrame = UI.CreateFrame

setfenv(1, private)
Ux = Ux or { }
Ux.MoneyFrame = { }

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
	
	local width = 16 + 23
	
	if(coin >= 100) then
		width = width + 16 + 23
		self.g:SetVisible(true)
		if(coin >= 10000) then
			width = width + 16 + self.ptxt:GetFullWidth()
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
	s:SetWidth(16)
	s:SetHeight(16)
	s:SetTexture("ImhoBags", "textures/silver.png")
	local stxt = UICreateFrame("Text", "", s)
	stxt:SetPoint("RIGHTCENTER", s, "LEFTCENTER")
	stxt:SetFontSize(13)
	
	local g = UICreateFrame("Texture", "", self)
	g:SetPoint("TOPRIGHT", s, "TOPLEFT", -23, 0)
	g:SetWidth(16)
	g:SetHeight(16)
	g:SetTexture("ImhoBags", "textures/gold.png")
	local gtxt = UICreateFrame("Text", "", g)
	gtxt:SetPoint("RIGHTCENTER", g, "LEFTCENTER")
	gtxt:SetFontSize(13)
	
	local p = UICreateFrame("Texture", "", self)
	p:SetPoint("TOPRIGHT", g, "TOPLEFT", -23, 0)
	p:SetWidth(16)
	p:SetHeight(16)
	p:SetTexture("ImhoBags", "textures/platinum.png")
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
