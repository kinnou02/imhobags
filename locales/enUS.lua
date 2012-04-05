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
		["misc collectible"] = "Collectibles",
		-- Special case for costumes
		["armor costume"] = "Costumes",
		-- Special case for lootable container items
		lootable = "Lootable",
		-- Designators for equipped wardrobe sets
		wardrobeSet1 = "Wardrobe Set 1",
		wardrobeSet2 = "Wardrobe Set 2",
		wardrobeSet3 = "Wardrobe Set 3",
		wardrobeSet4 = "Wardrobe Set 4",
		wardrobeSet5 = "Wardrobe Set 5",
	},
	
	-- The shortcuts used in the tooltip overview
	TooltipEnhancer = {
		line = "+%s: %i %s", -- 1: character name, 2: item count, 3: detail string
		bank = "(bank %i)",
		inventory = "(bags %i)",
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
		* Currencies: "currency" or "c"
		* defaults to "inventory" if omitted
/imhobags search
	Opens the search window.
/imhobags config
	Opens the configuration window.
/imhobags config [value]
	Set or get a configuration option.
/imhobags config help
	Lists all available options with detailed descriptions.
/imhobags config list
	Displayes the current values of all config options.
]],
		unknownChar = [[
No data available for character "%s" (or it is member of the enemy faction).]],

		unknownLocation = [[
Unknown location "%s".
"location" must be one of: 
	* Backpack: "inventory", "inv" or "i"
	* Bank: "bank" or "b"
	* Mailbox: "mail" or "m"
	* Currencies: "currency" or "c"
	* defaults to "inventory" if omitted
]],
		configOptions = [[
Available config options:
* autoOpen yes/no
	Controls whether the inventory or bank windows open/close automatically
	together with the respective Trion frames.
* condensed yes/no
	Controls whether multiple full stacks of the same item are condensed
	into one button to save screen space.
* enhanceTooltips yes/no
	Controls whether item tooltips should be extended with additional information
	showing which of your characters already own the displayed item.
* itemButtonSkin pretty/simple
	Controls how the item buttons are displayed. "simple" lacks nice
	visuals, "pretty" aims to look like Trion item buttons. Requires
	/reloadui before taking effect. "simple" may look better on very
	low UI-scalings.
* packGroups yes/no
	If set to yes reducing screen space has a higher priority than
	correct sorting of groups. Multiple groups are packed together
	per line where possible.
* showEmptySlots yes/no
	Controls whether the number of empty bag slots is displayed above
	the Trion bags bar.
* showEnemyFaction yes/no/account
	Controls whether items of the enemy faction are considered.
	no: Enemy faction characters are completely ignored.
	yes: All items of enemy faction characters are considered.
	account: Only account-bound items of enemy faction characters are considered.
]],
	},
	
	-- User interface elements
	Ux = {
		-- Titles for various windows
		WindowTitle = {
			inventory = "Backpack",
			bank = "Bank",
			currency = "Currencies",
			search = "Search Database",
			mail = "Mailbox",
			equipment = "Equipped",
			wardrobe = "Wardrobe",
		},
		search = "<Enter search text>",
		cashOnDelivery = "Cash on Delivery",
		guildVault = "Vault %i",
		
		-- All text for the configuration window goes here
		ConfigWindow = {
			title = "Configuration for Imhothar's Bags",
			showTooltips = "Show slash commands",
			appearanceSection = "Appearance",
			behaviorSection = "Behavior",
			extrasSection = "Extras",
			condensed = "Choose whether multiple full stacks of the same item are condensed into one button or whether each stack is displayed separately.",
			packGroups = "Choose whether multiple small groups should be packed into one line where possible instead of creating a new line for every single group. The former may result in inconsistent group sorting but can drastically decrease the size of the item windows.",
			itemButtonSkin = "Choose how item buttons should be rendered. The left option requires more resources than the right one but looks better. If you play with a very low UI scale the right button skin might look better. Note that changes to this option require a /reloadui before becoming effective.",
			autoOpen = "Choose whether the ImhoBags inventory or bank windows should automatically open and close when the respective Trion windows are opened and closed.",
			showEnemyFaction = "Choose how items of enemy faction characters are treated. The options are to show all items regardless of character faction, to show only account-bound items of enemy faction characters, or to completely ignore all their items.",
			enhanceTooltips = "Choose whether you want item tooltips to be extended with additional information showing you which of your characters already own the displayed item.",
			showEmptySlots = "Choose whether you want a counter displayed on top of your bags bar showing how many empty item slots remain in your backpack.",
		},
	},
}
