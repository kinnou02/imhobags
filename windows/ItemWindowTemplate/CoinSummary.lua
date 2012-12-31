local Addon, private = ...

-- Upvalue
local max = math.max

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
	table.sort(characterNames)
	for i = 1, #characterNames do
		local name = characterNames[i]
		characterCoins[i] = chars[name]
	end
end, Addon.identifier, "" }

local function createCharEntry(parent, name, coins, y)
	local text = UI.CreateFrame("Text", "", parent)
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
	local icon = UI.CreateFrame("Texture", "", parent)
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
	local sep = UI.CreateFrame("Texture", "", parent)
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
	local coin = Inspect.Currency.Detail("coin").stack
	
	self.playerCoinFrame:SetCoin(coin)
	self.playerAllianceCoinFrame:SetCoin(coin + playerAllianceCoinTotal)
	self.totalCoinFrame:SetCoin(coin + playerAllianceCoinTotal + enemyAllianceCoinTotal)
	
	local width = max(self.coinWidth, self.playerCoinFrame:GetWidth())
	width = max(self.coinWidth, self.playerAllianceCoinFrame:GetWidth())
	width = max(self.coinWidth, self.totalCoinFrame:GetWidth())
	self:SetWidth(3 * contentPaddingLeft + self.nameWidth + width)
end

local function updateGuildList(self, guilds)
	local names = { }
	for name in pairs(guilds) do
		names[#names + 1] = name
	end
	table.sort(names)
	
	local y = contentPaddingTop
	self.nameWidth = 0
	self.coinWidth = 0
	for i = 1, #names do
		self.guildNames[i]:SetText(names[i])
		self.guildCoins[i]:SetCoin(guilds[names[i]])
		self.guildNames[i]:SetVisible(true)
		self.guildCoins[i]:SetVisible(true)
		self.nameWidth = max(self.nameWidth, self.guildNames[i]:GetWidth())
		self.coinWidth = max(self.coinWidth, self.guildCoins[i]:GetWidth())
		y = y + self.guildNames[i]:GetHeight()
	end
	for i = #names + 1, #self.guildNames do
		self.guildNames[i]:SetVisible(false)
		self.guildCoins[i]:SetVisible(false)
	end
	self:SetWidth(3 * contentPaddingLeft + self.nameWidth + self.coinWidth)
	
	local bottomOffset = (8 / backgroundHeight) * y
	self.background:SetHeight(y + bottomOffset)
end

local function createGuildFrames(self, background)
	local count = 1 -- Reserve one for the player's guild
	local guilds = Item.Storage.GetGuildCoins()
	for name, coin in pairs(guilds) do
		count = count + 1
	end
	
	local y = contentPaddingTop
	self.guildNames = { }
	self.guildCoins = { }
	for i = 1, count do
		local name, coin = createCharEntry(background, "", 0, y)
		name:SetVisible(false)
		coin:SetVisible(false)
		self.guildNames[i] = name
		self.guildCoins[i] = coin
		y = y + name:GetHeight()
	end
	
	if(Inspect.Interaction("guildbank")) then
		guilds[Player.guild] = Inspect.Guild.Bank.Coin()
	end
	updateGuildList(self, guilds)
end

local function eventGuildBankCoin(self, coin)
	local guilds = Item.Storage.GetGuildCoins()
	guilds[Player.guild] = coin
	updateGuildList(self, guilds)
end

local function eventInteraction(self, interaction, status)
	if(interaction == "guildbank" and status) then
		local guilds = Item.Storage.GetGuildCoins()
		guilds[Player.guild] = Inspect.Guild.Bank.Coin()
		updateGuildList(self, guilds)
	end
end

-- Public methods
-- ============================================================================

function Ux.ItemWindowTemplate.CoinSummary(parent, titleBar, location)
	local self = UI.CreateFrame("Mask", "", Ux.TooltipContext)
	self:SetHeight(0)
	
	local background = UI.CreateFrame("Texture", "", self)
	background:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT")
	background:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
	background:SetTexture("Rift", "dropdown_list.png.dds")
	self.background = background
	
	self.nameWidth = 0
	self.coinWidth = 0
	self.names = { }
	self.coins = { }
	
	function self:SetCallback(callback)
		self.callback = callback
	end
	
	if(location ~= "guildbank") then
		ImhoEvent.Init[#ImhoEvent.Init + 1] = { function()
			createCharFrames(self, background)
			setPlayerCoin(self, background)
			Event.Currency[#Event.Currency + 1] = { function() setPlayerCoin(self, background) end, Addon.identifier, "" }
			Ux.ItemWindowTemplate.FadingPopup.MakeFadeable(self, titleBar, background:GetHeight())
		end, Addon.identifier, "" }
	else
		ImhoEvent.Init[#ImhoEvent.Init + 1] = { function()
			createGuildFrames(self, background)
			Event.Interaction[#Event.Interaction + 1] = { function(...) eventInteraction(self, ...) end, Addon.identifier, "" }
			Event.Guild.Bank.Coin[#Event.Guild.Bank.Coin + 1] = { function(coin) eventGuildBankCoin(self, coin) end, Addon.identifier, "" }
			Ux.ItemWindowTemplate.FadingPopup.MakeFadeable(self, titleBar, background:GetHeight())
		end, Addon.identifier, "" }
	end

	return self
end
