﻿local addon = (...).data

-- Make sure to save this file in UTF-8 encoding

setfenv(1, addon)
-- English is loaded if no other is present
if(L ~= nil) then
	return
end

L =
{
	-- Category translation
	-- [english] = translated
	-- Although categories can have multiple words (e.g. "weapon sword onehand")
	-- only the first word is used for grouping/sorting and needs to be translated.
	-- Should match the headings in the auction house.
	CategoryNames = {
		armor = "Armor",
		consumable = "Consumables",
		container = "Containers",
		crafting = "Crafting",
		misc = "Miscellaneous",
		planar = "Planar",
		weapon = "Weapons",
		-- Used for the collapsible group with sellable items
		sellable = "Junk",
		-- Special case for collectibles (e.g. artifacts)
		["misc collectible"] = "Collectible",
	},
	
	-- Titles for various windows
	WindowTitles = {
		inventory = "BACKPACK",
		bank = "BANK",
	}
}
