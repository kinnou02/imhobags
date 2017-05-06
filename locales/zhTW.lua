local private = select(2, ...)

if(Inspect.System.Language() ~= "Taiwanese" ) then
	return
end

setfenv(1, private)
L = { }
L.CategoryName = {
	armor = "護甲", -- Needs review
	["armor costume"] = "衣服", -- Needs review
	["artifact bounty"] = "Collectibles", -- Requires localization
	["artifact fishing"] = "Collectibles", -- Requires localization
	["artifact normal"] = "Collectibles", -- Requires localization
	["artifact other"] = "Collectibles", -- Requires localization
	["artifact twisted"] = "Collectibles", -- Requires localization
	["artifact unstable"] = "Collectibles", -- Requires localization
	consumable = "消耗品", -- Needs review
	["consumable enchantment"] = "Enchantments", -- Requires localization
	container = "容器", -- Needs review
	crafting = "材料", -- Needs review
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
	lootable = "可拾取", -- Needs review
	misc = "雜項", -- Needs review
	["misc collectible"] = "收藏品", -- Needs review
	["misc mount"] = "收藏品", -- Needs review
	["misc pet"] = "收藏品", -- Needs review
	["misc quest"] = "Quest", -- Requires localization
	planar = "平面", -- Needs review
	sellable = "垃圾", -- Needs review
	wardrobe = "衣櫃間 %i", -- Needs review
	weapon = "武器", -- Needs review
}
L.Currency = {
	gold = "黃金", -- Needs review
	platinum = "白金", -- Needs review
	silver = "銀", -- Needs review
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
	configOptions = [=[可用的配置選項:
* autoOpen yes/no
  控制是否倉庫或銀行窗口打開/關閉自動與Trion框架聯通.
* condensed yes/no
	控制是否在同一物品的多個完整堆疊加為一個格以節省屏幕空間.
* enhanceTooltips yes/no
	控制是否在你已有的顯示項顯示額外添加的提示項信息.
* itemButtonSkin pretty/simple
	控制物品圖標的顯示方式. "simple" 普通的視覺效果, "pretty" 看起來像Trion物品圖標. 要求 /reloadui 生效. "simple" 可能看上去比較低的UI比例.
* packGroups yes/no
	如果設置為yes減少屏幕空間比正常排序的組有較高優先級.多個組可在一行.
* showEmptySlots yes/no
	控制是否Trion背包欄上方顯示背包空格數量.
* showEnemyFaction yes/no/account
	控制是否過濾敵對方的物品.
	no: 完全忽略敵對方名稱.
	yes: 過濾所有敵對方的物品.
	account: 僅過濾賬戶綁定的敵對方物品.
]=], -- Needs review
	unknownChar = "沒有可用的人物數據 \"%s\" (或他是敵對人員).", -- Needs review
	unknownLocation = [=[未知位置 "%s".
"location" 必須是下列之一: 
	* 背包: "inventory", "inv" or "i"
	* 銀行: "bank" or "b"
	* 信箱: "mail" or "m"
	* 貨幣: "currency" or "c"
	* 如果省略默認為 "inventory".
]=], -- Needs review
	usage = [=[Correct usage:
/imhobags character [location]
	"character" 必須是一個你的人物的完整名稱或 "player"
	"location" 必須是下列之一: 
		* 背包: "inventory", "inv" or "i"
		* 銀行: "bank" or "b"
		* 信箱: "mail" or "m"
		* 貨幣: "currency" or "c"
		* 如果省略默認為 "inventory".
/imhobags search
	打開搜索窗口.
/imhobags config
	打開配置窗口.
/imhobags config [value]
	設置或打開一個配置窗口.
/imhobags config help
	列出所有可用選項的詳細説明.
/imhobags config list
	顯示所有配置選項的當前值.
]=], -- Needs review
}
L.TooltipEnhancer = {
	bank = "(銀行 %i)", -- Needs review
	currency = "(currencies %i)", -- Requires localization
	equipment = "(裝備 %i)", -- Needs review
	inventory = "(袋 %i)", -- Needs review
	mail = "(郵件 %i)", -- Needs review
	quest = "(quest %i)", -- Requires localization
	wardrobe = "(衣服 %i)", -- Needs review
}
L.Ux = {
	bankVault = "Vault %i", -- Requires localization
	cashOnDelivery = "貨到付款", -- Needs review
	defiant = "違反者", -- Needs review
	guardian = "管理員", -- Needs review
	guildVault = "倉庫 %i", -- Needs review
	search = "<輸入搜索文本>", -- Needs review
	ConfigWindow = {
		autoOpen = "當Trion窗口打開和關閉時，選擇是否自動打開和關閉ImhoBags倉庫或銀行窗口.", -- Needs review
		condensed = "選擇是否在同一物品的多個完整堆都結成一個格或是否顯示每個.", -- Needs review
		enhanceTooltips = "選擇是否希望在你人物已有顯示項額外增加的提示項的信息.", -- Needs review
		itemButtonSkin = "選擇物品圖標如何顯示. 左邊的選擇比右邊的更耗資源，但比較好看.如果開低UI效果，右邊的可能更好.請注意，此選擇更改后需要重新加載插件 /reloadui.", -- Needs review
		setCategorySort = "Click the image below to open the 'Set Category Sort Order' window.  This feature will allow you to customize how categories are sorted within the imhobags inventory windows.", -- Requires localization
		showBoundIcon = "在靈魂和賬戶綁定物品的圖表上顯示一個小的指示器.藍色圖標表示靈魂綁定物品、紅色/藍色表示賬戶綁定.", -- Needs review
		showEmptySlots = "選擇是否在你的背包欄前面顯示你的背包裏有多少空格槽的計數器.", -- Needs review
		showTooltips = "顯示斜杠命令", -- Needs review
		title = "Configuration for Imhothar's Bags", -- Requires localization
		updateItemsTimerInterval = "The following (advanced) setting allows you to select the number of seconds the addon waits (after an inventory change) before updating the window.  When this value is greater than zero, imhobags will update immediately on the first inventory change and then will not update again until # seconds has elapsed without any other inventory changes.   (This setting is especially useful for players who move large amounts of items from one window to another and are frustrated by categories shifting between moves.)  \\n[Default = 0]", -- Requires localization
		onebag = {
			description = "If you prefer the \\\"all-in-one\\\" display without any grouping or sorting, then the following options make ImhoBags behave exactly like that:", -- Requires localization
		},
		sections = {
			appearance = "外觀", -- Needs review
			behavior = "行為", -- Needs review
			extras = "附加", -- Needs review
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
		icon = "圖標", -- Needs review
		name = "名稱", -- Needs review
		rarity = "罕見", -- Needs review
	},
	Tooltip = {
		character = "人物", -- Needs review
		config = "配置", -- Needs review
		guild = "公會", -- Needs review
		guildvault = "公會倉庫", -- Needs review
		size = "大小", -- Needs review
		sorting = "排序", -- Needs review
		vault = "Vault", -- Requires localization
	},
	WindowTitle = {
		bank = "銀行", -- Needs review
		CategorySort = "Category Sort", -- Requires localization
		currency = "貨幣", -- Needs review
		equipment = "裝備", -- Needs review
		inventory = "背包", -- Needs review
		mail = "信箱", -- Needs review
		quest = "Quest", -- Requires localization
		search = "搜索數據庫", -- Needs review
		wardrobe = "衣服", -- Needs review
	},
}

