local identifier = (...).idlocal addon = (...).data-- Builtinslocal ipairs = ipairslocal pairs = pairslocal pcall = pcalllocal table = tablelocal setmetatable = setmetatablelocal shortCategoryCache = { } -- Used for avoiding string.match on known categoriessetfenv(1, addon)Group = Group or { }Group.Default = { }-- Public methods-- ============================================================================-- Use the localization of the first category word of an item as group key.function Group.Default.GetLocalizedShortCategory(type)	local category = shortCategoryCache[type.category]	if(category == nil) then		category = string.match(item.type.category, "(%w+)")		category = L.CategoryNames[category]		shortCategoryCache[item.type.category] = category	end	return categoryend--[[Use the localization of the first category word of an item as group key.The junk rarity is represented by its own category.]]function Group.Default.GetLocalizedShortCategoryWithJunk(type)	if(type.rarity and type.rarity == "sellable") then		return L.CategoryNames.sellable	else		return Group.Default.LocalizedShortCategory(type)	endend-- Sort simply by category keyfunction Group.Default.SortByCategoryKey(cat1, cat2, keys)	return keys[cat1] < keys[cat2]end-- Sort by the category name but put the sellable junk category at the endfunction Group.Default.SortByCategoryNameWithJunk(cat1, cat2, keys)	local key1 = keys[cat1]	local key2 = keys[cat2]	if(key1 == L.CategoryNames.sellable) then		return false	elseif(key2 == L.CategoryNames.sellable) then		return true	else		return key1 < key2	endend