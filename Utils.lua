local rarityColors = {
	sellable =	{ 0.34375, 0.34375, 0.34375 },
	common =	{    0.98,    0.98,    0.98 },
	uncommon =	{     0.0,   0.797,     0.0 },
	rare =		{   0.148,   0.496,   0.977 },
	epic =		{   0.676,   0.281,    0.98 },
	quest =		{     1.0,     1.0,     0.0 },
	relic =		{     1.0,     0.5,     0.0 },
}

setfenv(1, ImhoBags)
Utils = { }

function Utils.RarityColor(rarity)
	local col = rarityColors[rarity or ""] or rarityColors.common
	return col[1], col[2], col[3]
end
