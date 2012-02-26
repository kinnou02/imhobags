-- Make sure to save this file in UTF-8 encoding

if(Inspect.System.Language() ~= "English" ) then
	return
end

setfenv(1, ImhoBags)
L =
{
	-- Category translation
	-- [english] = translated
	-- Although categories can have multiple words (e.g. "weapon sword onehand")
	-- only the first word is used for grouping/sorting and needs to be translated.
	-- Should match the names in the auction house.
	CategoryNames = {
		armor = "Armor",
		consumable = "Consumables",
		container = "Containers",
		crafting = "Crafting",
		misc = "Miscellaneous",
		planar = "Planar",
		weapon = "Weapons",
	},
}
