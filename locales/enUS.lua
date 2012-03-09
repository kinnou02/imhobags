local Addon, private = ...

local next = next

setfenv(1, private)
-- English is loaded if no other is present
if(next(L) ~= nil) then
	return
end

L = {
	-- Category translation
	-- [english] = translated
	-- Although categories can have multiple words (e.g. "weapon sword onehand")
	-- only the first word is used for grouping/sorting and needs to be translated.
	-- Should match the headings in the auction house.
	CategoryName = {
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
	
	-- The shortcuts used in the tooltip overview
	TooltipEnhancer = {
		line = "+%s: %i %s", -- 1: character name, 2: item count, 3: detail string
		inventory = "(bags %i)",
		bank = "(bank %i)",
		mail = "(mail %i)",
		equipment = "(equipped %i)",
		wardrobe = "(wardrobe %i)",
		total = "= %i",
	},
	
	Currency = {
		platin = "platin",
		gold = "gold",
		silver = "silver",
	},
	
	SlashMessage = {
		usage = [[
Correct usage:
/imhobags character location
	"character" must be either the full name of one of your characters or "player"
	"location" must be one of: 
		* Backpack: "inventory", "inv" or "i"
		* Bank: "bank" or "b"
/imhobags search
	Opens the search window
]],
		unknownChar = [[
No data available for character "%s" (or it is member of the enemy faction).]],

		unknownLocation = [[
Unknown location "%s".
"location" must be one of: 
	* Backpack: "inventory", "inv" or "i"
	* Bank: "bank" or "b"
]],
	},
	
	-- User interface elements
	Ux = {
		-- Titles for various windows
		WindowTitle = {
			inventory = "Backpack",
			bank = "Bank",
		},
		search = "Search",
	},

}
