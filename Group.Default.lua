local Addon, private = ...

-- Upvalue
local InspectCurrencyCategoryDetail = Inspect.Currency.Category.Detail
local strmatch = string.match
local sort = table.sort

local shortCategoryCache = { } -- Used for avoiding string.match on known categories

setfenv(1, private)
Group = Group or { }
Group.Default = { }

-- Public methods
-- ============================================================================

-- Use the localization of the first category word of an item as group key.
function Group.Default.GetLocalizedShortCategory(item)
	--dump(item)												-- for debugging
	local name = item.category or "misc"
	local localized = L.CategoryName[name]
	if(localized) then
		-- Trion insists on categorizing Dream Ribbons as Cloth.  This was changed at some point after the release of the 
		-- Dreamweaver, so I'm not sure if it's a bug or not.
		if (localized == 'Cloth' and item.name == 'Dream Ribbon' or item.name == 'Dream Bolt') then
			return L.CategoryName["crafting recipe dream weaver"]
		end
		return localized
	else
		local category = shortCategoryCache[name]
		if(category == nil) then
			category = strmatch(name, "(%w+)")
			category = L.CategoryName[category]
			if(not category) then
				log("UNLOCALIZED CATEGORY: " .. name)
				category = L.CategoryName.misc
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
function Group.Default.GetLocalizedShortCategoryWithJunk(item)
	if(item.rarity and item.rarity == "sellable") then
		return L.CategoryName.sellable
	else
		return Group.Default.GetLocalizedShortCategory(item)
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

function Group.Default.SortCategoryNames(names, categoryOrderList)
	local namesSorted = { }
	local i, lastElement, nextElement = 1, 1, 1
	
	if (names == nil or #names < 1) then
		return names
	end
	
	-- This occurs if the user has never used the category sort window on this character.
	if (categoryOrderList == nil) then
		log("Group.Default.SortCategoryNames() -- categoryOrderList is nil.  Sorting alphabetically...")
		sort(names)
		return names
	end

	---------------------
	-- Overview:
	-- 
	-- The addon provides a UI for users to optionally select a custom order for how categories are sorted in the default
	-- view.  This is saved in a table with the keys being the category names and the values being the position in the custom
	-- sort order (ex: categoryOrderList = { "pigs" = 1, "cats" = 2, "dogs" = 3 } ).   Group.Default.SortCategoryNames() takes 
	-- an unsorted table of categories (ex: names = { "dogs", "pigs", "donkeys", "cats", "mice" }), places the custom ordered 
	-- categories first using the positions indicated while removing them from the given table, sorts what's left of the original 
	-- table alphabetically and then adds it to the end of the new 'sorted' table, goes through the new table and removes any nil 
	-- entries (which can happen if the provided list did not contain all of the categories in the categoryOrderList provided) and then 
	-- returns the sorted table.  So, using the examples above, the return table would be { "pigs", "cats", "dogs", "donkeys", "mice" }
	---------------------
	
	--print("DEBUG: names provided:")
	--dump(names)
	--print("DEBUG: categoryOrderList provided:")
	--dump(categoryOrderList)
	
	---------------------
	-- Step 1:  Iterate through the provided names searching for any that exist in "categoryOrderList".  If so, add it
	--          to "namesSorted" and remove it from the original "names".  Also, keep track of the highest 'lastElement' used.
	--          Since it is possible for the player not to have items for each specified category there could be nil values
	--          in the table (thus the reason for maintaining 'lastElement' to keep everything properly ordered.)
	while i <= #names do
		local categoryName = names[i]
		if (categoryOrderList[categoryName] ~= nil) then
			local categoryOrder = categoryOrderList[categoryName]
			--print("DEBUG:  categoryOrderList[" ..  categoryName .. "] found! (" .. categoryName .. " -> " .. categoryOrder .. ")")
			namesSorted[categoryOrder] = categoryName
			if (lastElement < categoryOrder) then lastElement = categoryOrder end
	    table.remove(names, i)
		else
			i = i + 1
		end
	end
	nextElement = lastElement + 1
	--print("DEBUG: Initial namesSorted:")
	--dump(namesSorted)

	---------------------
	-- Step 2.  Sort the remaining (unspecified) names alphabetically
	sort(names)
	--print("DEBUG: names after pruning/sorting:")
	--dump(names)
	
	---------------------
	-- Step 3.  Add what's left of the "names" list (sorted) to the end of the "sortedNames" table.  Begin adding values at 
	--          "nextElement" to ensure that everything stays in the correct order.
	for i = 1, #names do
		if (names[i] ~= nill) then
			namesSorted[nextElement] = names[i]
			nextElement = nextElement + 1
		end
	end
	--print("DEBUG: namesSorted after colation:")
	--dump(namesSorted)
	
	---------------------
	-- Step 4. Iterate through the final sorted table (serving as a vector, in this case) to remove any nil values.  While
	--         nil values in a table isn't really a concern for LUA, a great deal of this addon assumes that there are no
	--         nil values in 'names'.  So, it's just easier to deal with it here.
	names = namesSorted
	namesSorted = { }
	
	---------------------
	-- Step 4. Iterate through the final sorted table (serving as a vector, in this case) to remove any nil values.  While
	--         nil values in a table isn't really a concern for LUA, a great deal of this addon assumes that there are no
	--         nil values in 'names'.  So, it's just easier to deal with it here.
	for i = 1, nextElement do
		if (names[i] ~= nil) then
			namesSorted[#namesSorted + 1] = names[i]
		end
	end
	
	--print("DEBUG: namesSorted after deflation (what will be returned):")
	--dump(namesSorted)
	
	---------------------
	-- Step 5.  Return the custom sorted table
	return namesSorted
end

-- Sort simply by category key **(UNUSED)**
function Group.Default.SortByCategoryKey(cat1, cat2, keys)
	return keys[cat1] < keys[cat2]
end

-- Sort by the category name but put the sellable junk category at the end **(UNUSED)**
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

