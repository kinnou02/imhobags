local private = select(2, ...)

if(Inspect.System.Language() ~= "Korean" ) then
	return
end

setfenv(1, private)
L = { }
L.CategoryName = {
	armor = "갑옷", -- Needs review
	["armor costume"] = "Costumes", -- Requires localization
	["artifact bounty"] = "Collectibles", -- Requires localization
	["artifact fishing"] = "Collectibles", -- Requires localization
	["artifact normal"] = "소장", -- Needs review
	["artifact other"] = "소장", -- Needs review
	["artifact twisted"] = "소장", -- Needs review
	["artifact unstable"] = "소장", -- Needs review
	consumable = "소모품", -- Needs review
	["consumable enchantment"] = "Enchantments", -- Requires localization
	container = "가방", -- Needs review
	crafting = "제작", -- Needs review
	["crafting ingredient drop"] = "Drops", -- Requires localization
	["crafting ingredient reagent"] = "Reagents", -- Requires localization
	["crafting ingredient rift"] = "Rifts", -- Requires localization
	["crafting material butchering"] = "Leather", -- Requires localization
	["crafting material cloth"] = "Cloth", -- Requires localization
	["crafting material component"] = "Rune Components", -- Requires localization
	["crafting material fish"] = "Fish", -- Requires localization
	["crafting material gem"] = "Gems", -- Requires localization
	["crafting material meat"] = "Meat", -- Requires localization
	["crafting material metal"] = "Metal", -- Requires localization
	["crafting material plant"] = "Plants", -- Requires localization
	["crafting material wood"] = "Wood", -- Requires localization
	["crafting recipe dream weaver"] = "Dream Weaving", -- Requires localization
	dimension = "Dimension", -- Requires localization
	empty = "Empty", -- Requires localization
	lootable = "Lootable", -- Requires localization
	misc = "Miscellaneous", -- Needs review
	["misc collectible"] = "소장", -- Needs review
	["misc mount"] = "Collectibles", -- Requires localization
	["misc pet"] = "Collectibles", -- Requires localization
	["misc quest"] = "Quest", -- Requires localization
	planar = "평면", -- Needs review
	sellable = "정크", -- Needs review
	wardrobe = "옷장 %i", -- Needs review
	weapon = "무기", -- Needs review
}
L.Currency = {
	gold = "금", -- Needs review
	platinum = "백금", -- Needs review
	silver = "은화", -- Needs review
}
L.Rarity = {
	common = "common", -- Requires localization
	epic = "epic", -- Requires localization
	junk = "junk", -- Requires localization
	quest = "quest", -- Requires localization
	rare = "rare", -- Requires localization
	relic = "relic", -- Requires localization
	uncommon = "uncommon", -- Requires localization
}
L.SlashMessage = {
	configOptions = [=[Available config options:
* autoOpen yes/no
	Controls whether the inventory or bank windows open/close automatically
	together with the respective native frames.
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
	the Trion bags bar.]=], -- Requires localization
	unknownChar = "No data available for character \"%s\".", -- Requires localization
	unknownLocation = [=[Unknown location "%s".
"location" must be one of: 
	* Backpack: "inventory", "inv" or "i"
	* Bank: "bank" or "b"
	* Currencies: "currency" or "c"
	* Equipment: "equipment" or "e"
	* Quest: "quest" or "q"
	* defaults to "inventory" if omitted
]=], -- Requires localization
	usage = [=[Correct usage:
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
	Opens the search window
/imhobags config
	Opens the configuration window.
/imhobags config [value]
	Set or get a configuration option.
/imhobags config help
	Lists all available options with detailed descriptions.
/imhobags config list
	Displayes the current values of all config options.
]=], -- Requires localization
}
L.TooltipEnhancer = {
	bank = "(은행 %i)", -- Needs review
	currency = "(currencies %i)", -- Requires localization
	equipment = "(장비 %i)", -- Needs review
	inventory = "(가방 %i)", -- Needs review
	mail = "(우편 %i)", -- Needs review
	quest = "(quest %i)", -- Requires localization
	wardrobe = "(옷장 %i)", -- Needs review
}
L.Ux = {
	bankVault = "Vault %i", -- Requires localization
	cashOnDelivery = "배달시 현금 결제", -- Needs review
	defiant = "Defiant", -- Requires localization
	guardian = "Guardian", -- Requires localization
	guildVault = "Vault %i", -- Requires localization
	search = "검색", -- Needs review
	ConfigWindow = {
		autoOpen = "Choose whether the ImhoBags inventory or bank windows should automatically open and close when the respective Trion windows are opened and closed.", -- Requires localization
		condensed = "Choose whether multiple full stacks of the same item are condensed into one button or whether each stack is displayed separately.", -- Requires localization
		enhanceTooltips = "Choose whether you want item tooltips to be extended with additional information showing you which of your characters already own the displayed item.", -- Requires localization
		itemButtonSkin = "Choose how item buttons should be rendered. The left option requires more resources than the right one but looks better. If you play with a very low UI scale the right button skin might look better. Note that changes to this option require a /reloadui before becoming effective.", -- Requires localization
		setCategorySort = "Click the image below to open the 'Set Category Sort Order' window.  This feature will allow you to customize how categories are sorted within the imhobags inventory windows.", -- Requires localization
		showBoundIcon = "Display a small indicator over the icons of soul- and account-bound items. A blue icon indicates soul-bound items, the red/blue tinted account-bound ones.", -- Requires localization
		showEmptySlots = "Choose whether you want a counter displayed on top of your bags bar showing how many empty item slots remain in your backpack.", -- Requires localization
		showTooltips = "Show slash commands", -- Requires localization
		title = "Configuration for Imhothar's Bags", -- Requires localization
		updateItemsTimerInterval = "The following (advanced) setting allows you to select the number of seconds the addon waits (after an inventory change) before updating the window.  When this value is greater than zero, imhobags will update immediately on the first inventory change and then will not update again until # seconds has elapsed without any other inventory changes.   (This setting is especially useful for players who move large amounts of items from one window to another and are frustrated by categories shifting between moves.)  \\n[Default = 0]", -- Requires localization
		onebag = {
			description = "If you prefer the \\\"all-in-one\\\" display without any grouping or sorting, then the following options make ImhoBags behave exactly like that:", -- Requires localization
		},
		sections = {
			appearance = "Appearance", -- Requires localization
			behavior = "Behavior", -- Requires localization
			extras = "Extras", -- Requires localization
			onebag = "Help: One Bag", -- Requires localization
			titleBar = "Help: Title Bar", -- Requires localization
		},
		titleBar = {
			arrangementDescription = "Shows a menu where you can change the sorting and grouping of items.", -- Requires localization
			arrangementLabel = "Arrangement", -- Requires localization
			charsDescription = "Opens a menu allowing you to chose which character's items are displayed in the current window. Not shown in the Guild Bank window.", -- Requires localization
			charsLabel = "Characters", -- Requires localization
			coinsDescription = "Opens an overview of the money of all your characters and known guilds.", -- Requires localization
			coinsLabel = "Money", -- Requires localization
			description = "The title bar contains options with which you can customize the appearance of items. Most of the buttons are hidden by default. To make them visible simply move your cursor over the top area. These options are saved separately for each item window and character, making it possible to have different appearances and behavior in every ImhoBags item window.", -- Requires localization
			emptyDescription = "Shows the number of empty slots in this location. Clicking the symbol toggles the display of empty item slots inside the window.", -- Requires localization
			emptyLabel = "Empty Slots", -- Requires localization
			guildsDescription = "Opens a menu allowing you to chose which guild's items are displayed in the current window. Only shown in the Guild Bank window.", -- Requires localization
			guildsLabel = "Guilds", -- Requires localization
			layoutBagsDescription = "Groups items by the bag they are placed in.", -- Requires localization
			layoutBagsLabel = "Bags", -- Requires localization
			layoutDefaultDescription = "Items are grouped by their category similar to how they are in the auction house. Note that the game doesn't provide category information for some items (especially world event items). In that case they are grouped under '%s'.", -- Requires localization
			layoutDefaultLabel = "Category", -- Requires localization
			layoutDescription = "In the lower row of the arrangement menu you can select how items are grouped:", -- Requires localization
			layoutOnebagDescription = "All items are thrown in one big bag.", -- Requires localization
			layoutOnebagLabel = "Onebag", -- Requires localization
			locationDescription = "This icon shows the location of the current window (inventory, bank, etc.). Move the cursor here to show the other available locations.", -- Requires localization
			locationLabel = "Location", -- Requires localization
			searchDescription = "The dark area is a text box functioning as a filter, highlighting items in the window matching the entered text. Clicking the icon opens a separate window where you can search all items owned by all your characters and known guilds.", -- Requires localization
			searchLabel = "Search", -- Requires localization
			sizeDescription = "Shows a menu where you can change the item size.", -- Requires localization
			sizeLabel = "Size", -- Requires localization
			sortDescription = "In the upper row of the arrangement menu you can select how items are sorted:", -- Requires localization
			sortIconDescription = "Sorts items by the file name of their in-game icon texture. This has the chance of grouping similar items together.", -- Requires localization
			sortIconLabel = "Icon", -- Requires localization
			sortNameDescription = "Sorts items from left to right alphabetically. The order depends on the sort algorithm implemented by the game's localization.", -- Requires localization
			sortNameLabel = "Alphabetically", -- Requires localization
			sortNoneDescription = "Does not apply any sorting. The items are displayed from left to right in the same order as they appear in the game's default bag windows.", -- Requires localization
			sortNoneLabel = "None", -- Requires localization
			sortRarityDescription = "Sorts items by their rarity from left to right in the order: %s.", -- Requires localization
			sortRarityLabel = "Rarity", -- Requires localization
		},
	},
	PopupWindow = {
		cancel = "CANCEL", -- Requires localization
		ok = "OK", -- Requires localization
	},
	SetCategorySortWindow = {
		addingToCatListMsg1 = "Adding category '%s' to the end of the sort order.", -- Requires localization
		catSortOrderNotValidMsg1 = "The value provided for category\\n '%s' (%s) is not valid.\\n\\nPlease choose a number between 1 and %d.", -- Requires localization
		catSortOrderNotValidMsg2 = "The value provided for category\\n '%s' (%s) has already been used.\\n\\nPlease choose a unique number between 1 and %d\\nfor each category.", -- Requires localization
		instructions = "Choose your preferred sorting order for\\nitem categories.", -- Requires localization
		savedCatListNotValidMsg1 = "Saved category list is smaller (%d) than the number of default categories defined by the addon (%d).", -- Requires localization
		savedCatListNotValidMsg2 = "\"Saved category list is larger (%d) than the number of default categories defined by the addon (%d).\"", -- Requires localization
	},
	SortOption = {
		icon = "Icon", -- Requires localization
		name = "Name", -- Requires localization
		rarity = "Rarity", -- Requires localization
	},
	Tooltip = {
		character = "Select Character", -- Requires localization
		config = "Configuration", -- Requires localization
		guild = "Select Guild", -- Requires localization
		guildvault = "Guild Vault", -- Requires localization
		size = "Size", -- Requires localization
		sorting = "Sorting", -- Requires localization
		vault = "Vault", -- Requires localization
	},
	WindowTitle = {
		bank = "은행", -- Needs review
		CategorySort = "Category Sort", -- Requires localization
		currency = "소지금", -- Needs review
		equipment = "장비", -- Needs review
		inventory = "배낭", -- Needs review
		mail = "받은 편지함", -- Needs review
		quest = "Quest", -- Requires localization
		search = "데이터베이스 검색", -- Needs review
		wardrobe = "Wardrobe", -- Requires localization
	},
}

