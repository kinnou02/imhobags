local Addon, private = ...

-- Make sure to save this file in UTF-8 encoding

if(Inspect.System.Language() ~= "German" ) then
	return
end

setfenv(1, private)
L = {
	-- Category translation
	-- [english] = translated
	-- Although categories can have multiple words (e.g. "weapon sword onehand")
	-- only the first word is used for grouping/sorting and needs to be translated.
	-- Should match the headings in the auction house.
	CategoryNames = {
		armor = "Rüstung",
		consumable = "Verbrauchsgüter",
		container = "Behälter",
		crafting = "Handwerk",
		misc = "Verschiedenes",
		planar = "Ebenenobjekte",
		weapon = "Waffen",
		-- Used for the collapsible group with sellable items
		sellable = "Plunder",
		-- Special case for collectibles (e.g. artifacts)
		["misc collectible"] = "Sammlerstück",
	},
	
	-- Titles for various windows.
	-- They are all caps as in the default Rift containers
	WindowTitles = {
		inventory = "RUCKSACK",
		bank = "BANK",
	},
	
	-- The shortcuts used in the tooltip overview
	TooltipEnhancer = {
		line = "+%s: %i %s", -- 1: character name, 2: item count, 3: detail string
		inventory = "(Taschen %i)",
		bank = "(Bank %i)",
		mail = "(Post %i)",
		equipment = "(Angezogen %i)",
		wardrobe = "(Kostüm %i)",
		total = "= %i",
	},
}
