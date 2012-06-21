local Addon, private = ...

-- Builtins
local ipairs = ipairs
local pairs = pairs
local sort = table.sort

-- Globals
local dump = dump
local UICreateFrame = UI.CreateFrame

-- Locals

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

-- Public methods
-- ============================================================================

local function MoneySummaryWindow_ShowAtCursor(self)
	local names, coins, playerTotal, enemyTotal = sortOutCharacters(ItemDB.GetCharactersCoin())
end

function Ux.MoneySummaryWindow()
	local self = UICreateFrame("Frame", "Money Summary Window", Ux.TooltipContext)
	
	self.ShowAtCursor = MoneySummaryWindow_ShowAtCursor
	
	Ux.MoneySummaryWindow = self
end

Ux.MoneySummaryWindow()