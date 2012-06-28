local Addon, private = ...

-- Builtins
local strmatch = string.match

-- Globals
local InspectCurrencyCategoryDetail = Inspect.Currency.Category.Detail

local shortCategoryCache = { } -- Used for avoiding string.match on known categories

setfenv(1, private)
Group = Group or { }
Group.Default = { }

-- Public methods
-- ============================================================================

-- Use the localization of the first category word of an item as group key.
function Group.Default.GetLocalizedShortCategory(type)
	local name = type.category or "misc"
	local localized = L.CategoryName[name]
	if(localized) then
		return localized
	else
		local category = shortCategoryCache[name]
		if(category == nil) then
			category = strmatch(name, "(%w+)")
			category = L.CategoryName[category]
			if(not category) then
				log("UNLOCALIZED CATEGORY: " .. name)
			end
			shortCategoryCache[name] = category
		end
		return category
	end
end

--[[
Use the localization of the first category word of an item as group key.
The junk rarity is represented by its own category.
]]
function Group.Default.GetLocalizedShortCategoryWithJunk(type)
	if(type.rarity and type.rarity == "sellable") then
		return L.CategoryName.sellable
	else
		return Group.Default.GetLocalizedShortCategory(type)
	end
end

function Group.Default.GetLocalizedShortCategoryWithJunkAndLootable(item)
	if(item.lootable) then
		return L.CategoryName.lootable
	else
		return Group.Default.GetLocalizedShortCategoryWithJunk(item)
	end
end

function Group.Default.GetCurrencyGroup(item)
	return InspectCurrencyCategoryDetail(item.category).name or L.CategoryName.misc
end

-- Use the mail subject as group. Works only for MailMatrix items
function Group.Default.GetMail(type)
	return type.ImhoBags_mail
end

-- Sort simply by category key
function Group.Default.SortByCategoryKey(cat1, cat2, keys)
	return keys[cat1] < keys[cat2]
end

-- Sort by the category name but put the sellable junk category at the end
function Group.Default.SortByCategoryNameWithJunk(cat1, cat2, keys)
	local key1 = keys[cat1]
	local key2 = keys[cat2]
	if(key1 == L.CategoryName.sellable) then
		return false
	elseif(key2 == L.CategoryName.sellable) then
		return true
	else
		return key1 < key2
	end
end

