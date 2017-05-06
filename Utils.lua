local Addon, private = ...

local rarityColors = {
	sellable =			{ 0.34375,		0.34375, 	0.34375 	},
	common =			{    0.98,    	0.98,    	0.98 		},
	uncommon =			{     0.0,   	0.797,     	0.0 		},
	rare =				{   0.148,   	0.496,   	0.977 		},
	epic =				{   0.676,   	0.281,    	0.98 		},
	quest =				{     1.0,     	1.0,     	0.0 		},
	relic =				{     1.0,     	0.5,     	0.0 		},
	transcendent =		{     1.0,     	0.0,     	0.0 		},
	ascended =    		{  	 0.93,    	0.51,   	0.93		},
	eternal  =      	{    0.39,    	0.85,   	1      		},
}

setfenv(1, private)
Utils = { }

function Utils.RarityColor(rarity)
	local col = rarityColors[rarity or "common"] or rarityColors.common
	return col[1], col[2], col[3]
end

local coinFormat1 = string.format("%%i %s %%i %s %%i %s", L.Currency.platinum, L.Currency.gold, L.Currency.silver)
local coinFormat2 = string.format("%%i %s %%i %s", L.Currency.gold, L.Currency.silver)
local coinFormat3 = string.format("%%i %s", L.Currency.silver)
function Utils.FormatCoin(coin)
	local p, g, s = math.floor(coin / 10000), math.floor(coin / 100 % 100), coin % 100
	if(p > 0) then
		return string.format(coinFormat1, p, g, s)
	elseif(g > 0) then
		return string.format(coinFormat2, g, s)
	else
		return string.format(coinFormat3, s)
	end
end
