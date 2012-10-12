local Addon, private = ...

-- Builtins
local pairs = pairs
local max = math.max
local sort = table.sort

-- Globals
local EventCurrency = Event.Currency
local InspectCurrencyDetail = Inspect.Currency.Detail
local UICreateFrame = UI.CreateFrame

-- Locals
local characterNames = { }
local characterCoins = { }
local playerAllianceCoinTotal = 0
local enemyAllianceCoinTotal = 0

local backgroundHeight = 128

local contentPaddingTop = 3
local contentPaddingLeft = 14

local textColor = { 245 / 255, 240 / 255, 198 / 255 }

setfenv(1, private)
Ux.ItemWindowTemplate = Ux.ItemWindowTemplate or { }

-- Private methods
-- ============================================================================

ImhoEvent.Init[#ImhoEvent.Init + 1] = { function()
	local chars = Item.Storage.GetCharacterCoins()
	local alliances = Item.Storage.GetCharacterAlliances()
	
	for name, coin in pairs(chars) do
		characterNames[#characterNames + 1] = name
		if(alliances[name] == Player.alliance) then
			if(name ~= Player.name) then
				playerAllianceCoinTotal = playerAllianceCoinTotal + coin
			end
		else
			enemyAllianceCoinTotal = enemyAllianceCoinTotal + coin
		end
	end
	sort(characterNames)
	for i = 1, #characterNames do
		local name = characterNames[i]
		characterCoins[i] = chars[name]
	end
end, Addon.identifier, "" }

local function createCharEntry(parent, name, coins, y)
	local text = UICreateFrame("Text", "", parent)
	text:SetText(name)
	text:SetFontColor(textColor[1], textColor[2], textColor[3])
	text:SetPoint("TOPLEFT", parent, "TOPLEFT", contentPaddingLeft, y)
	text:SetFontSize(13)
	
	local coin = Ux.MoneyFrame.New(parent)
	coin:SetCoin(coins)
	coin:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -contentPaddingLeft, y + 3)
	coin:SetFontColor(textColor[1], textColor[2], textColor[3])
	
	return text, coin
end

local function createAllianceEntry(parent, allliance, coins, y)
	local icon = UICreateFrame("Texture", "", parent)
	icon:SetPoint("TOPLEFT", parent, "TOPLEFT", contentPaddingLeft, y - 5)
	icon:SetTextureAsync("Rift", allliance .. ".png.dds")
	icon:SetWidth(40)
	icon:SetHeight(40)
	
	local coin = Ux.MoneyFrame.New(parent)
	coin:SetCoin(coins)
	coin:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -contentPaddingLeft, y + 0)
	coin:SetFontColor(textColor[1], textColor[2], textColor[3])
	
	return text, coin
end

local function createSeparator(parent, y)
	local sep = UICreateFrame("Texture", "", parent)
	sep:SetTexture("Rift", "rollover_divider_alpha.png.dds")
	sep:SetPoint("TOPLEFT", parent, "TOPLEFT", contentPaddingLeft, y)
	sep:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -contentPaddingLeft, y)
	return sep
end

local function createCharFrames(self, background)
	local y = contentPaddingTop
	for i = 1, #characterNames do
		local name, coin = createCharEntry(background, characterNames[i], characterCoins[i], y)
		y = y + name:GetHeight()
		
		self.nameWidth = max(self.nameWidth, name:GetWidth())
		if(characterNames[i] == Player.name) then
			self.playerCoinFrame = coin
		else
			self.coinWidth = max(self.coinWidth, coin:GetWidth())
		end
	end
	
	y = y + createSeparator(background, y - 3):GetHeight()
	
	local name, coin = createAllianceEntry(background, Player.alliance, playerAllianceCoinTotal, y)
	self.playerAllianceCoinFrame = coin
	self.nameWidth = max(self.nameWidth, 20)--name:GetWidth())
	y = y + 20--name:GetHeight()
	local name, coin = createAllianceEntry(background, Player.enemyAlliance, enemyAllianceCoinTotal, y)
	self.enemyAllianceCoinFrame = coin
	self.nameWidth = max(self.nameWidth, 20)--name:GetWidth())
	self.coinWidth = max(self.coinWidth, coin:GetWidth())
	y = y + 20--name:GetHeight()
	
	y = y + createSeparator(background, y - 3):GetHeight() - 5
	
	local name, coin = createCharEntry(background, " =", playerAllianceCoinTotal + enemyAllianceCoinTotal, y)
	self.totalCoinFrame = coin
	self.nameWidth = max(self.nameWidth, name:GetWidth())
	y = y + name:GetHeight()
	
	local bottomOffset = (8 / backgroundHeight) * y
	background:SetHeight(y + bottomOffset)
end

local function setPlayerCoin(self, background)
	local coin = InspectCurrencyDetail("coin").stack
	
	self.playerCoinFrame:SetCoin(coin)
	self.playerAllianceCoinFrame:SetCoin(coin + playerAllianceCoinTotal)
	self.totalCoinFrame:SetCoin(coin + playerAllianceCoinTotal + enemyAllianceCoinTotal)
	
	local width = max(self.coinWidth, self.playerCoinFrame:GetWidth())
	width = max(self.coinWidth, self.playerAllianceCoinFrame:GetWidth())
	width = max(self.coinWidth, self.totalCoinFrame:GetWidth())
	self:SetWidth(3 * contentPaddingLeft + self.nameWidth + width)
end

-- Public methods
-- ============================================================================


function Ux.ItemWindowTemplate.CoinSummary(parent, titleBar)
	local self = UICreateFrame("Mask", "", Ux.TooltipContext)
	self:SetHeight(0)
	
	local background = UICreateFrame("Texture", "", self)
	background:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT")
	background:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
	background:SetTexture("Rift", "dropdown_list.png.dds")
	
	self.nameWidth = 0
	self.coinWidth = 0
	
	function self:SetCallback(callback)
		self.callback = callback
	end
	
	createCharFrames(self, background)
	setPlayerCoin(self, background)

	EventCurrency[#EventCurrency + 1] = { function() setPlayerCoin(self, background) end, Addon.identifier, "" }
	
	Ux.ItemWindowTemplate.FadingPopup.MakeFadeable(self, titleBar, background:GetHeight())
	
	self.ShowForChars = showForChars
	return self
end
