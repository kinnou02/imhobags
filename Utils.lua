local Addon, private = ...

local floor = math.floor
local format = string.format

local rarityColors = {
	sellable =		{ 0.34375, 0.34375, 0.34375 },
	common =		{    0.98,    0.98,    0.98 },
	uncommon =		{     0.0,   0.797,     0.0 },
	rare =			{   0.148,   0.496,   0.977 },
	epic =			{   0.676,   0.281,    0.98 },
	quest =			{     1.0,     1.0,     0.0 },
	relic =			{     1.0,     0.5,     0.0 },
	transcendant =	{     1.0,     0.5,     0.0 }, -- WTF?
}

setfenv(1, private)
Utils = { }

function Utils.RarityColor(rarity)
	local col = rarityColors[rarity or ""] or rarityColors.common
	return col[1], col[2], col[3]
end

local coinFormat1 = format("%%i %s %%i %s %%i %s", L.Currency.platinum, L.Currency.gold, L.Currency.silver)
local coinFormat2 = format("%%i %s %%i %s", L.Currency.gold, L.Currency.silver)
local coinFormat3 = format("%%i %s", L.Currency.silver)
function Utils.FormatCoin(coin)
	local p, g, s = floor(coin / 10000), floor(coin / 100 % 100), coin % 100
	if(p > 0) then
		return format(coinFormat1, p, g, s)
	elseif(s > 0) then
		return format(coinFormat2, g, s)
	else
		return format(coinFormat3, s)
	end
end
