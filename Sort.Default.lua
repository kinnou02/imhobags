local Addon, private = ...

-- Locals
local rarityOrder = {
	sellable = 1,
	common = 2,
	uncommon = 3,
	rare = 4,
	epic = 5,
	relic = 6,
	transcendent = 7,
	quest = 8,
	
	empty = 0,
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
	local b1 = type1.bind or "N/A"
	local r2 = type2.rarity or "common"
	local b2 = type2.bind or "N/A"
	local s1 = 1
	local s2 = 0
	
	----
	-- Within each rarity type, place 'bind on pickup' items first, then items that are 'bind to account', then 'bind on equip' items, and then the remainder.
	if (b1 == "pickup") then
		s1 = rarityOrder[r1] + 0.1
	elseif (b1 == "account") then
		s1 = rarityOrder[r1] + 0.2
	elseif (b1 == "equip") then
		s1 = rarityOrder[r1] + 0.3
	else
		s1 = rarityOrder[r1]
	end
	if (b2 == "pickup") then
		s2 = rarityOrder[r2] + 0.1
	elseif (b2 == "account") then
		s2 = rarityOrder[r2] + 0.2
	elseif (b2 == "equip") then
		s2 = rarityOrder[r2] + 0.3
	else
		s2 = rarityOrder[r2]
	end

	if (s1 == s2) then
		return type1.name < type2.name
	end
	
	return s1 > s2
end

-- Sort two item types depending on their slot
function Sort.Default.ByItemSlot(item1, item2)
	return (item1.slot or "") < (item2.slot or "")
end

