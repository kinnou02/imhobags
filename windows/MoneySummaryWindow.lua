local Addon, private = ...

-- Builtins
local ipairs = ipairs
local max = math.max
local pairs = pairs
local sort = table.sort

-- Globals
local dump = dump
local Inspect = Inspect
local UICreateFrame = UI.CreateFrame
local UIParent = UIParent

-- Locals
local charFrameHeight = 20
local allianceIconWidth = charFrameHeight * 1.5 -- Aspect ratio of image
local padding = 5
local spacing = 10

setfenv(1, private)
Ux = Ux or { }
Ux.MoneySummaryWindow = { }

-- Private methods
-- ============================================================================

local function sortOutCharacters(chars)
	local names = { }
	local coins = { }
	local playerTotal = 0
	local enemyTotal = 0
	
	local player = chars[PlayerFaction]
	local enemy = chars[EnemyFaction]
	
	for name, coin in pairs(player) do
		names[#names + 1] = name
	end
	for name, coin in pairs(enemy) do
		names[#names + 1] = name
	end
	sort(names)
	
	for i, name in ipairs(names) do
		if(player[name]) then
			coins[i] = player[name]
			playerTotal = playerTotal + coins[i]
		else
			coins[i] = enemy[name]
			enemyTotal = enemyTotal + coins[i]
		end
	end
	
	return names, coins, playerTotal, enemyTotal
end

local function createEntryFrame(self, text)
	local frame = UICreateFrame("Frame", "", self)
	
	frame.name = UICreateFrame("Text", "", frame)
	frame.name:SetPoint("LEFTCENTER", frame, "LEFTCENTER")
	frame.name:SetFontSize(14)
	frame.name:SetText(text)
	
	frame.coin = Ux.MoneyFrame.New(frame)
	frame.coin:SetPoint("RIGHTCENTER", frame, "RIGHTCENTER")
	
	frame:SetHeight(charFrameHeight)
	return frame
end

local function createCharFrame(self)
	local frame = createEntryFrame(self, "")
	
	if(#self.charFrames == 0) then
		frame:SetPoint("TOPLEFT", self, "TOPLEFT", padding, padding)
		frame:SetPoint("TOPRIGHT", self, "TOPRIGHT", -padding, padding)
	else
		frame:SetPoint("TOPLEFT", self.charFrames[#self.charFrames], "BOTTOMLEFT")
		frame:SetPoint("TOPRIGHT", self.charFrames[#self.charFrames], "BOTTOMRIGHT")
	end
	
	return frame
end

local function fillCharacterFrames(self, names, coins, playerTotal, enemyTotal)
	local nameWidth = 0
	local coinWidth = 0
	local height = 2 * padding
	for i, name in ipairs(names) do
		if(not self.charFrames[i]) then
			self.charFrames[i] = createCharFrame(self)
		end
		local char = self.charFrames[i]
		
		char.name:SetText(name)
		char.coin:SetCoin(coins[i])
		
		nameWidth = max(nameWidth, char.name:GetWidth())
		coinWidth = max(coinWidth, char.coin:GetWidth())
		height = height + char:GetHeight()
	end
	
	self.separator1:SetPoint("TOPLEFT", self.charFrames[#self.charFrames], "BOTTOMLEFT")
	self.separator1:SetPoint("TOPRIGHT", self.charFrames[#self.charFrames], "BOTTOMRIGHT")
	self.playerTotalFrame.coin:SetCoin(playerTotal)
	nameWidth = max(nameWidth, self.playerTotalFrame.name:GetHeight())
	coinWidth = max(coinWidth, self.playerTotalFrame.coin:GetWidth())
	height = height + self.playerTotalFrame:GetHeight()
	
	if(enemyTotal > 0) then
		self.enemyTotalFrame.coin:SetCoin(enemyTotal)
		self.totalFrame.coin:SetCoin(enemyTotal + playerTotal)
		self.enemyTotalFrame:SetVisible(true)
		nameWidth = max(nameWidth, self.enemyTotalFrame.name:GetHeight())
		coinWidth = max(coinWidth, self.enemyTotalFrame.coin:GetWidth())
		nameWidth = max(nameWidth, self.totalFrame.name:GetWidth())
		coinWidth = max(coinWidth, self.totalFrame.coin:GetWidth())
		height = height + self.enemyTotalFrame:GetHeight() + self.separator2:GetHeight() + self.totalFrame:GetHeight()
	else
		self.enemyTotalFrame:SetVisible(false)
		self.totalFrame:SetVisible(false)
	end
	
	self:SetWidth(nameWidth + spacing + coinWidth + 2 * padding)
	self:SetHeight(height)
end

local function createSeparator(self)
	local sep = UICreateFrame("Texture", "", self)
	sep:SetTexture("ImhoBags", "textures/hr1.png")
	sep:SetHeight(6)
	return sep
end

-- Public methods
-- ============================================================================

local function MoneySummaryWindow_ShowAtCursor(self)
	if(not self:GetVisible()) then
		fillCharacterFrames(self, sortOutCharacters(ItemDB.GetCharactersCoin()))
	end
	
	-- Position at cursor
	local mouse = Inspect.Mouse()
	local width, height = self:GetWidth(), self:GetHeight()
	local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
	
	local anchor = mouse.y - height < 0 and "TOP" or "BOTTOM"
	anchor = anchor .. (mouse.x + width > screenWidth and "RIGHT" or "LEFT")
	self:ClearPoint("TOPLEFT")
	self:ClearPoint("TOPRIGHT")
	self:ClearPoint("BOTTOMLEFT")
	self:ClearPoint("BOTTOMRIGHT")
	self:SetPoint(anchor, UIParent, "TOPLEFT", mouse.x, mouse.y)
	self:SetVisible(true)
end

function Ux.MoneySummaryWindow()
	local self = UICreateFrame("Frame", "Money Summary Window", Ux.TooltipContext)

	self:SetVisible(false)
	self:SetBackgroundColor(0, 0, 0, 0.75)
	
	self.charFrames = { }
	self.separator1 = createSeparator(self)
	self.playerTotalFrame = createEntryFrame(self, L.Ux[PlayerFaction])
	self.enemyTotalFrame = createEntryFrame(self.playerTotalFrame, L.Ux[EnemyFaction])
	self.separator2 = createSeparator(self.enemyTotalFrame)
	self.totalFrame = createEntryFrame(self.separator2, "=")
	
	self.playerTotalFrame:SetPoint("TOPLEFT", self.separator1, "BOTTOMLEFT")
	self.playerTotalFrame:SetPoint("TOPRIGHT", self.separator1, "BOTTOMRIGHT")
	self.enemyTotalFrame:SetPoint("TOPLEFT", self.playerTotalFrame, "BOTTOMLEFT")
	self.enemyTotalFrame:SetPoint("TOPRIGHT", self.playerTotalFrame, "BOTTOMRIGHT")
	self.separator2:SetPoint("TOPLEFT", self.enemyTotalFrame, "BOTTOMLEFT")
	self.separator2:SetPoint("TOPRIGHT", self.enemyTotalFrame, "BOTTOMRIGHT")
	self.totalFrame:SetPoint("TOPLEFT", self.separator2, "BOTTOMLEFT")
	self.totalFrame:SetPoint("TOPRIGHT", self.separator2, "BOTTOMRIGHT")
	
	self.ShowAtCursor = MoneySummaryWindow_ShowAtCursor
	
	Ux.MoneySummaryWindow = self
end
