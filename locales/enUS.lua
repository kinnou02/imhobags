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
		["consumable enchantment"] = "Enchantments",
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
		["artifact normal"] = "Collectibles",
		["artifact twisted"] = "Collectibles",
		["artifact unstable"] = "Collectibles",
		["artifact Poison"] = "Collectibles",
		["artifact Burning"] = "Collectibles",
		["artifact Nightmare"] = "Collectibles",
		["artifact other"] = "Collectibles",
		["artifact bounty"] = "Collectibles",
		["artifact fishing"] = "Collectibles",
		["misc collectible"] = "Collectibles",
		["misc pet"] = "Miscellaneous",
		["misc mount"] = "Miscellaneous",
		["misc minion"] = "Minions",
		["misc fishing"] = "Fishing",
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
		["crafting material butchering"] = "Leather",
		["crafting material meat"] = "Meat",
		["crafting material metal"] = "Metal",
		["crafting material plant"] = "Plants",
		["crafting material wood"] = "Wood",
		-- Crafting ingredients names
		["crafting ingredient reagent"] = "Reagents",
		["crafting ingredient rift"] = "Rifts",
		["crafting ingredient drop"] = "Drops",
		-- Dreamweaving
		["crafting recipe dream weaver"] = "Dream Weaving",
		nightmare = "Nightmare Rifts",
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
	
	Rarity = {
		quest = "quest",
		relic = "relic",
		epic = "epic",
		rare = "rare",
		uncommon = "uncommon",
		common = "common",
		junk = "junk",
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
			CategorySort = "Category Sort",
		},
		Tooltip = {
			character = "Character",
			config = "Configuration",
			guild = "Guild",
			guildvault = "Guild Vault",
			vault = "Vault",
			size = "Size",
			sorting = "Sorting",
		},
		search = "<Enter search text>",
		cashOnDelivery = "Cash on Delivery",
		guildVault = "Vault %i",
		bankVault = "Vault %i",
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
			sections = {
				appearance = "Appearance",
				behavior = "Behavior",
				extras = "Extras",
				titleBar = "Help: Title Bar",
				onebag = "Help: One Bag",
			},
			condensed = "Choose whether multiple full stacks of the same item are condensed into one button or whether each stack is displayed separately.",
			itemButtonSkin = "Choose how item buttons should be rendered. The left option requires more resources than the right one but looks better. If you play with a very low UI scale the right button skin might look better. Note that changes to this option require a /reloadui before becoming effective.",
			autoOpen = "Choose whether the ImhoBags inventory or bank windows should automatically open and close when the respective Trion windows are opened and closed.",
			setCategorySort = "Click the image below to open the 'Set Category Sort Order' window.  This feature will allow you to customize how categories are sorted within the imhobags inventory windows.",
			enhanceTooltips = "Choose whether you want item tooltips to be extended with additional information showing you which of your characters already own the displayed item.",
			showEmptySlots = "Choose whether you want a counter displayed on top of your bags bar showing how many empty item slots remain in your backpack.",
			updateItemsTimerInterval = "The following (advanced) setting allows you to select the number of seconds the addon waits (after an inventory change) before updating the window.  When this value is greater than zero, imhobags will update immediately on the first inventory change and then will not update again until # seconds has elapsed without any other inventory changes.   (This setting is especially useful for players who move large amounts of items from one window to another and are frustrated by categories shifting between moves.)  \n[Default = 0]",
			showBoundIcon = "Display a small indicator over the icons of soul- and account-bound items. A blue icon indicates soul-bound items, the red/blue tinted account-bound ones.",
			titleBar = {
				description = "The title bar contains options with which you can customize the appearance of items. Most of the buttons are hidden by default. To make them visible simply move your cursor over the top area. These options are saved separately for each item window and character, making it possible to have different appearances and behavior in every ImhoBags item window.",
				
				charsLabel = "Characters",
				charsDescription = "Opens a menu allowing you to chose which character's items are displayed in the current window. Not shown in the Guild Bank window.",
				guildsLabel = "Guilds",
				guildsDescription = "Opens a menu allowing you to chose which guild's items are displayed in the current window. Only shown in the Guild Bank window.",
				coinsLabel = "Money",
				coinsDescription = "Opens an overview of the money of all your characters and known guilds.",
				searchLabel = "Search",
				searchDescription = "The dark area is a text box functioning as a filter, highlighting items in the window matching the entered text. Clicking the icon opens a separate window where you can search all items owned by all your characters and known guilds.",
				sizeLabel = "Size",
				sizeDescription = "Shows a menu where you can change the item size.",
				arrangementLabel = "Arrangement",
				arrangementDescription = "Shows a menu where you can change the sorting and grouping of items.",
				locationLabel = "Location",
				locationDescription = "This icon shows the location of the current window (inventory, bank, etc.). Move the cursor here to show the other available locations.",
				emptyLabel = "Empty Slots",
				emptyDescription = "Shows the number of empty slots in this location. Clicking the symbol toggles the display of empty item slots inside the window.",
				
				sortDescription = "In the upper row of the arrangement menu you can select how items are sorted:",
				sortNameLabel = "Alphabetically",
				sortNameDescription = "Sorts items from left to right alphabetically. The order depends on the sort algorithm implemented by the game's localization.",
				sortIconLabel = "Icon",
				sortIconDescription = "Sorts items by the file name of their in-game icon texture. This has the chance of grouping similar items together.",
				sortRarityLabel = "Rarity",
				sortRarityDescription = "Sorts items by their rarity from left to right in the order: %s.",
				sortNoneLabel = "None",
				sortNoneDescription = "Does not apply any sorting. The items are displayed from left to right in the same order as they appear in the game's default bag windows.",

				layoutDescription = "In the lower row of the arrangement menu you can select how items are grouped:",
				layoutDefaultLabel = "Category",
				layoutDefaultDescription = "Items are grouped by their category similar to how they are in the auction house. Note that the game doesn't provide category information for some items (especially world event items). In that case they are grouped under '%s'.",
				layoutBagsLabel = "Bags",
				layoutBagsDescription = "Groups items by the bag they are placed in.",
				layoutOnebagLabel = "Onebag",
				layoutOnebagDescription = "All items are thrown in one big bag.",
			},
			onebag = {
				description = "If you prefer the \"all-in-one\" display without any grouping or sorting, then the following options make ImhoBags behave exactly like that:",
			},
		},
		
		-- All text for the SetCategorySortWindow goes here
		SetCategorySortWindow = {    
			instructions = "Choose your preferred sorting order for\nitem categories.",
			catSortOrderNotValidMsg1 = "The value provided for category\n '%s' (%s) is not valid.\n\nPlease choose a number between 1 and %d.",
			catSortOrderNotValidMsg2 = "The value provided for category\n '%s' (%s) has already been used.\n\nPlease choose a unique number between 1 and %d\nfor each category.",
			savedCatListNotValidMsg1 = "Saved category list is smaller (%d) than the number of default categories defined by the addon (%d).",
			savedCatListNotValidMsg2 = "Saved category list is larger (%d) than the number of default categories defined by the addon (%d).",
			addingToCatListMsg1 = "Adding category '%s' to the end of the sort order.",
		},
		
		-- All text for the PopupWindow goes here
		PopupWindow = {
			ok = "OK",
			cancel = "CANCEL",
		},
	},
}
