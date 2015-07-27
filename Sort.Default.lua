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
	ascended = 8,
	quest = 9,

	
	empty = 0,
}


setfenv(1, private)
Sort = Sort or { }
Sort.Default = { }
local equipSlotCache = { }

-- Private methods
-- ============================================================================
local function getEquipSlot(item)
	-- This function returns the slot that items are equipped on the player.  For example, a chest armor piece will return "chest".
	-- It is important to note that, as of the writing of this function, only the feet, head, chest, shoulders, hands, legs, and
	-- waist slots use different categories based upon the material of the item.  Therefore, those are the only ones that 
	-- require special treatment.
	--
	-- The equipSlotCache table is used for efficiency.

	local category = item and item.category or L.CategoryName.misc
	local equipSlot = equipSlotCache[category]
	if(equipSlot == nil) then
		if (string.find(category,"feet")) then
			equipSlot = "feet"
		elseif (string.find(category,"head")) then
			equipSlot = "head"			
		elseif (string.find(category,"chest")) then
			equipSlot = "chest"		
		elseif (string.find(category,"shoulders")) then
			equipSlot = "shoulders"		
		elseif (string.find(category,"hands")) then
			equipSlot = "hands"		
		elseif (string.find(category,"waist")) then
			equipSlot = "waist"							
		elseif (string.find(category,"legs")) then
			equipSlot = "legs"													
		end
		if(not equipSlot) then
			equipSlot = category
		end
		--print("DEBUG: ", category, " == ", equipSlot)
		equipSlotCache[category] = equipSlot
	end
	
	return equipSlot
end



-- Public methods
-- ============================================================================

-- Sort two item types depending on their item name
function Sort.Default.ByItemName(type1, type2)
	return (type1 and type1.name or "") < (type2 and type2.name or "")
end

-- Sort two item types depending on their icon path
function Sort.Default.ByItemIcon(type1, type2)
	return (type1 and type1.icon or "") < (type2 and type2.icon or "")
end

-- Sort two item types depending on their item rarity
function Sort.Default.ByItemRarity(type1, type2)
	local r1 = type1 and type1.rarity or "common"
	local b1 = type1 and type1.bind or "N/A"
	local r2 = type2 and type2.rarity or "common"
	local b2 = type2 and type2.bind or "N/A"
	local s1 = 1
	local s2 = 0
	
	----
	-- If item is armor or weapons, and the item is rare or better, sort by armor/weapon category (equip. slot position) first.
	if  rarityOrder[r1] ~= nil and rarityOrder[r2] ~= nil  then
		if (rarityOrder[r1] > 4 and rarityOrder[r2] > 4) then
			local Category1 = Group.Default.GetLocalizedShortCategory(type1)
			local Category2 = Group.Default.GetLocalizedShortCategory(type2)
			if (Category1 == "Armor" and Category2 == "Armor" or Category1 == "Weapons" and Category2 == "Weapons") then
				local equipSlot1 = getEquipSlot(type1)
				local equipSlot2 = getEquipSlot(type2)
				if (equipSlot1 ~= equipSlot2) then
					return equipSlot1 > equipSlot2
				end
			end
		end
	end
	
	
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
		return (type1 and type1.name or "") < (type2 and type2.name or "")
	end
	
	return s1 > s2
end

-- Sort two item types depending on their inventory slot
function Sort.Default.ByItemSlot(item1, item2)
	return (item1 and item1.slot or "") < (item2 and item2.slot or "")
end

