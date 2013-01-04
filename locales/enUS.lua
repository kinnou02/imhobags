local private = select(2, ...)

--[===[@non-debug@
if(private.L) then
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
		dimension = "Dimension",
		misc = "Miscellaneous",
		["misc quest"] = "Quest",
		planar = "Planar",
		weapon = "Weapons",
		-- Used for the collapsible group with sellable items
		sellable = "Junk",
		-- Special case for collectibles (e.g. artifacts)
		["misc collectible"] = "Collectibles",
		["misc mount"] = "Collectibles",
		["misc pet"] = "Collectibles",
		-- Special case for costumes
		["armor costume"] = "Costumes",
		-- Special case for lootable container items
		lootable = "Lootable",
		-- Special case for empty slots
		empty = "Empty",
		-- Designator for equipped wardrobe sets
		wardrobe = "Wardrobe Set %i",
		-- Crafting material names
		["crafting material cloth"] = "Cloth",
		["crafting material component"] = "Rune Components",
		["crafting material fish"] = "Fish",
		["crafting material gem"] = "Gems",
		["crafting material hide"] = "Leather",
		["crafting material meat"] = "Meat",
		["crafting material metal"] = "Metal",
		["crafting material plant"] = "Plants",
		["crafting material wood"] = "Wood",
		-- Crafting ingredients names
		["crafting ingredient reagent"] = "Reagents",
		["crafting ingredient rift"] = "Rifts",
		["crafting ingredient drop"] = "Drops",
	},
	
	-- The shortcuts used in the tooltip overview
	TooltipEnhancer = {
		bank = "(bank %i)",
		currency = "(currencies %i)",
		equipment = "(equipped %i)",
		inventory = "(bags %i)",
		quest = "(quest %i)",
		mail = "(mail %i)",
		wardrobe = "(wardrobe %i)",
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
		* Currencies: "currency" or "c"
		* Equipment: "equipment" or "e"
		* Quest: "quest" or "q"
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
No data available for character "%s".]],

		unknownLocation = [[
Unknown location "%s".
"location" must be one of: 
	* Backpack: "inventory", "inv" or "i"
	* Bank: "bank" or "b"
	* Currencies: "currency" or "c"
	* Equipment: "equipment" or "e"
	* Quest: "quest" or "q"
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
* showEmptySlots yes/no
	Controls whether the number of empty bag slots is displayed above
	the Trion bags bar.
]],
	},
	
	-- User interface elements
	Ux = {
		-- Titles for various windows
		WindowTitle = {
			bank = "Bank",
			config = "Configuration",
			currency = "Currencies",
			equipment = "Equipped",
			guild = "Guild Vault",
			inventory = "Backpack",
			mail = "Mailbox",
			quest = "Quest",
			search = "Search Database",
			wardrobe = "Wardrobe",
		},
		Tooltip = {
			character = "Character",
			config = "Configuration",
			guild = "Guild",
			guildvault = "Guild Vault",
			size = "Size",
			sorting = "Sorting",
		},
		search = "<Enter search text>",
		cashOnDelivery = "Cash on Delivery",
		guildVault = "Vault %i",
		defiant = "Defiant",
		guardian = "Guardian",
		
		SortOption = {
			name = "A..Z",
			icon = "Icon",
			rarity = "Rarity",
		},
		
		-- All text for the configuration window goes here
		ConfigWindow = {
			title = "Configuration for Imhothar's Bags",
			showTooltips = "Show slash commands",
			appearanceSection = "Appearance",
			behaviorSection = "Behavior",
			extrasSection = "Extras",
			condensed = "Choose whether multiple full stacks of the same item are condensed into one button or whether each stack is displayed separately.",
			itemButtonSkin = "Choose how item buttons should be rendered. The left option requires more resources than the right one but looks better. If you play with a very low UI scale the right button skin might look better. Note that changes to this option require a /reloadui before becoming effective.",
			autoOpen = "Choose whether the ImhoBags inventory or bank windows should automatically open and close when the respective Trion windows are opened and closed.",
			enhanceTooltips = "Choose whether you want item tooltips to be extended with additional information showing you which of your characters already own the displayed item.",
			showEmptySlots = "Choose whether you want a counter displayed on top of your bags bar showing how many empty item slots remain in your backpack.",
			showBoundIcon = "Display a small indicator over the icons of soul- and account-bound items. A blue icon indicates soul-bound items, the red/blue tinted account-bound ones.",
		},
	},
}
