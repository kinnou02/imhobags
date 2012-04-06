local Addon, private = ...

-- Builtins
local debug = debug
local floor = math.floor
local format = string.format
local pcall = pcall
local print = print
local strlen = string.len
local strsplit = string.split
local strsub = string.sub
local tconcat = table.concat

-- Globals
local InspectItemDetail = Inspect.Item.Detail

local rarityColors = {
	sellable =		{ 0.34375, 0.34375, 0.34375 },
	common =		{    0.98,    0.98,    0.98 },
	uncommon =		{     0.0,   0.797,     0.0 },
	rare =			{   0.148,   0.496,   0.977 },
	epic =			{   0.676,   0.281,    0.98 },
	quest =			{     1.0,     1.0,     0.0 },
	relic =			{     1.0,     0.5,     0.0 },
	transcendent =	{     1.0,     0.5,     0.0 }, -- WTF?
}

setfenv(1, private)
Utils = { }

function Utils.RarityColor(rarity)
	local col = rarityColors[rarity or "common"] or rarityColors.common
	return col[1], col[2], col[3]
end

local coinFormat1 = format("%%i %s %%i %s %%i %s", L.Currency.platinum, L.Currency.gold, L.Currency.silver)
local coinFormat2 = format("%%i %s %%i %s", L.Currency.gold, L.Currency.silver)
local coinFormat3 = format("%%i %s", L.Currency.silver)
function Utils.FormatCoin(coin)
	local p, g, s = floor(coin / 10000), floor(coin / 100 % 100), coin % 100
	if(p > 0) then
		return format(coinFormat1, p, g, s)
	elseif(g > 0) then
		return format(coinFormat2, g, s)
	else
		return format(coinFormat3, s)
	end
end

function Utils.FixItemType(itemType)
	-- Temporary fix for invalid item types
	local components = strsplit(itemType, ",")
	for i = 1, #components do
		local c = components[i]
		if(strlen(c) == 24) then
			components[i] = strsub(components[i], -16)
		end
	end
--	log(debug.traceback())
	local itemType2 = tconcat(components, ",")
	if(itemType ~= itemType2) then
		local s, i = pcall(InspectItemDetail, itemType2)
		log(itemType)
		log(itemType2)
		if(not s) then
			print("Error in item processing: ", itemType)
		else
			log("Item error: ", i.name)
		end
	end
	return itemType2
end
