local private = select(2, ...)

--[===[@non-debug@
if(Inspect.System.Language() ~= "English" ) then
	return
end
--@end-non-debug@]===]

private.L = {
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
		-- Special case for lootable container items
		lootable = "Lootable",
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
		platinum = "Platinum",
		gold = "Gold",
		silver = "Silver",
	},
	
	SlashMessage = {
		usage = [[
Correct usage:
/imhobags character [location]
	"character" must be either the full name of one of your characters or "player"
	"location" must be one of: 
		* Backpack: "inventory", "inv" or "i"
		* Bank: "bank" or "b"
		* Mailbox: "mail" or "m"
		* defaults to "inventory" if omitted
/imhobags search
	Opens the search window
/imhobags config [value]
	Set or get a configuration option.
	Example: /imhobags showEnemyFaction yes
	List of all options: /imhobags config
]],
		unknownChar = [[
No data available for character "%s" (or it is member of the enemy faction).]],

		unknownLocation = [[
Unknown location "%s".
"location" must be one of: 
	* Backpack: "inventory", "inv" or "i"
	* Bank: "bank" or "b"
	* Mailbox: "mail" or "m"
	* defaults to "inventory" if omitted
]],
		configOptions = [[
Available config options:
* showEnemyFaction yes/no/account
	Controls whether items of the enemy faction are considered.
	no: Enemy faction characters are completely ignored.
	yes: All items of enemy faction characters are considered.
	account: Only account-bound items of the enemy faction are considered.
* autoOpen yes/no
	Controls whether the inventory or bank windows open/close automatically
	together with the respective Trion frames.
* itemButtonSkin pretty/simple
	Controls how the item buttons are displayed. "simple" lacks nice
	visuals, "pretty" aims to look like Trion item buttons. Requires
	/reloadui before taking effect. "simple" may look better on very
	low UI-scalings.
* packGroups yes/no
	If set to true reducing screen space has a higher priority than
	correct sorting of groups. Multiple groups are packed together
	per line where possible.
* showEmptySlots yes/no
	Controls whether the number of empty bag slots is displayed above
	the Trion bags bar.
]],
	},
	
	-- User interface elements
	Ux = {
		-- Titles for various windows
		WindowTitle = {
			inventory = "Backpack",
			bank = "Bank",
			search = "Search Database",
			mail = "Mailbox",
		},
		search = "<Enter search text>",
		cashOnDelivery = "Cash on Delivery",
	},
}
