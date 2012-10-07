local Addon, private = ...

-- Locals
local rarityOrder = {
	sellable = 1,
	common = 2,
	uncommon = 3,
	rare = 4,
	epic = 5,
	relic = 6,
	transcendant = 7,
	quest = 8,
}

setfenv(1, private)
Sort = Sort or { }
Sort.Default = { }

-- Public methods
-- ============================================================================

-- Sort two item types depending on their item name
function Sort.Default.ByItemName(type1, type2)
	return type1.name < type2.name
end

-- Sort two item types depending on their icon path
function Sort.Default.ByItemIcon(type1, type2)
	return type1.icon < type2.icon
end

-- Sort two item types depending on their item rarity
function Sort.Default.ByItemRarity(type1, type2)
	local r1 = type1.rarity or "common"
	local r2 = type2.rarity or "common"
	return rarityOrder[r1] > rarityOrder[r2]
end

-- Sort two item types depending on their item name
function Sort.Default.ByItemSlot(item1, item2)
	return (item1.slot or 1) < (item2.slot or 1)
end

