local private = select(2, ...)

if(Inspect.System.Language() ~= "Russian" ) then
	return
end

setfenv(1, private)
L = { }
L.CategoryName = {
	armor = "Доспехи",
	["armor costume"] = "Гардероб", -- Needs review
	["artifact bounty"] = "Collectibles", -- Requires localization
	["artifact fishing"] = "Collectibles", -- Requires localization
	["artifact normal"] = "Collectibles", -- Requires localization
	["artifact other"] = "Collectibles", -- Requires localization
	["artifact twisted"] = "Collectibles", -- Requires localization
	["artifact unstable"] = "Collectibles", -- Requires localization
	consumable = "Расходники",
	["consumable enchantment"] = "Enchantments", -- Requires localization
	container = "Ёмкости", -- Needs review
	crafting = "Создание предметов",
	["crafting ingredient drop"] = "Выпадающие", -- Needs review
	["crafting ingredient reagent"] = "Реагенты", -- Needs review
	["crafting ingredient rift"] = "Планарные предметы", -- Needs review
	["crafting material butchering"] = "Кожа", -- Needs review
	["crafting material cloth"] = "Ткань",
	["crafting material component"] = "Компоненты рун",
	["crafting material fish"] = "Рыба",
	["crafting material gem"] = "Камни",
	["crafting material meat"] = "Мясо",
	["crafting material metal"] = "Металлы",
	["crafting material plant"] = "Растения", -- Needs review
	["crafting material wood"] = "Древесина", -- Needs review
	["crafting recipe dream weaver"] = "Dream Weaving", -- Requires localization
	dimension = "Измерение", -- Needs review
	empty = "Пусто", -- Needs review
	lootable = "Контейнеры", -- Needs review
	misc = "Разное",
	["misc collectible"] = "Коллекции", -- Needs review
	["misc mount"] = "Скакуны", -- Needs review
	["misc pet"] = "Спутники", -- Needs review
	["misc quest"] = "Задания", -- Needs review
	planar = "Планарные",
	sellable = "Мусор",
	wardrobe = "Набор гардероба %i", -- Needs review
	weapon = "Оружие",
}
L.Currency = {
	gold = "золото",
	platinum = "платина",
	silver = "серебро",
}
L.Rarity = {
	common = "обычный", -- Needs review
	epic = "эпический", -- Needs review
	junk = "мусор", -- Needs review
	quest = "задание", -- Needs review
	rare = "редкий", -- Needs review
	relic = "реликвия", -- Needs review
	uncommon = "необычный", -- Needs review
}
L.SlashMessage = {
	configOptions = [=[Доступные настройки:
* autoOpen yes/no
	При открытии инвентаря или банка, будет открываться окно аддона.
* condensed yes/no
	Настраивает отображение нескольких полных стэков вещей в одной
	иконке для экономии места на экране.
* enhanceTooltips yes/no
	Настраивает отображение дополнительных подсказок, показывающих,
	у каких еще персонажей данного аккаунта есть такие вещи.
* itemButtonSkin pretty/simple
	Настраивает отображение иконок. "simple" менее красивые иконки,
	"pretty" выглядят как оригинальные иконки Trion. После активации
	необходима перезагрузка через /reloadui. "simple" может выглядеть
	лучше при низком разрешении.
* packGroups yes/no
	Опция "yes" повышает приоритет для понижения занимаемого места на
	экране при сортировке предметов в ущерб правильной сортировке.
	Несколько групп будут при возможности находиться на одной строке.
* showEmptySlots yes/no
	Настройка отображения количества пустых ячеек в сумках.]=], -- Needs review
	unknownChar = "Нет доступной информации о \"%s\".", -- Needs review
	unknownLocation = [=[Неизвестная ёмкость "%s".
"location" должно быть одно из: 
	* Рюкзак: "inventory", "inv" or "i"
	* Банк: "bank" or "b"
	* Валюта: "currency" or "c"
	* Экипировка: "equipment" or "e"
	* Задания: "quest" or "q"
	* по умолчанию "inventory"]=], -- Needs review
	usage = [=[Перечень команд:
/imhobags character location
	"character" имя персонажа должно быть написано полностью с учётом регистра, или же просто "player"
	"location" должно быть одно из: 
		* Рюкзак: "inventory", "inv" or "i"
		* Банк: "bank" or "b"
		* Валюта: "currency" or "c"
		* Экипировка: "equipment" or "e"
		* Задания: "quest" or "q"
		* по умолчанию "inventory"
/imhobags search
	Открывает окно поиска.
/imhobags config
	Открывает окно настроек.
/imhobags config [value]
	Задает или показывает заданную настройку.
/imhobags config help
	Показывает все возможные опции с детальным описанием.
/imhobags config list
	Отображает значения всех настроек.]=], -- Needs review
}
L.TooltipEnhancer = {
	bank = "(банк %i)",
	currency = "валюта %i", -- Needs review
	equipment = "(экипировка %i)",
	inventory = "(сумка %i)",
	mail = "(Почта %i)",
	quest = "задания %i", -- Needs review
	wardrobe = "(Гардероб %i)",
}
L.Ux = {
	bankVault = "Хранилище %i", -- Needs review
	cashOnDelivery = "Наложенным платежом", -- Needs review
	defiant = "Отступник",
	guardian = "Хранитель",
	guildVault = "Банк гильдии %i", -- Needs review
	search = "<Введите фразу для поиска>",
	ConfigWindow = {
		autoOpen = "При открытии инвентаря или банка, будет открываться окно аддона.",
		condensed = "Настраивает отображение нескольких полных стэков вещей в одной\009иконке для экономии места на экране.", -- Needs review
		enhanceTooltips = "Настраивает отображение дополнительных подсказок, показывающих, у каких еще персонажей данного аккаунта есть такие вещи.", -- Needs review
		itemButtonSkin = "Настраивает отображение иконок. Левая опция потребляет больше ресурсов, но выглядит лучше. Если используется низкое разрешение экрана, правая опция может выглядеть лучше. Необходима перезагрузка с помощью команды /reloadui.", -- Needs review
		setCategorySort = "Click the image below to open the 'Set Category Sort Order' window.  This feature will allow you to customize how categories are sorted within the imhobags inventory windows.", -- Requires localization
		showBoundIcon = "Отображает маленький индикатор над иконками предметов с привязкой. Синий индикатор - привязка души, красный - привязка к аккаунту.", -- Needs review
		showEmptySlots = "Настройка отображения количества пустого места в сумках.",
		showTooltips = "Показать команды чата",
		title = "Настройки аддона Imhothar's Bags",
		updateItemsTimerInterval = "The following (advanced) setting allows you to select the number of seconds the addon waits (after an inventory change) before updating the window.  When this value is greater than zero, imhobags will update immediately on the first inventory change and then will not update again until # seconds has elapsed without any other inventory changes.   (This setting is especially useful for players who move large amounts of items from one window to another and are frustrated by categories shifting between moves.)  \\n[Default = 0]", -- Requires localization
		onebag = {
			description = "Если Вы предпочитаете отображение в категории \\\\\\\"Все в одном\\\\\\\" без группирования и сортировки, то следующие опции помогут настроить ImhoBags именно таким образом:", -- Needs review
		},
		sections = {
			appearance = "Внешний вид",
			behavior = "Поведение",
			extras = "Дополнительно",
			onebag = "Помощь: Общая сумка", -- Needs review
			titleBar = "Помощь: Заголовок окна", -- Needs review
		},
		titleBar = {
			arrangementDescription = "Открывает меню с выбором персонажей, чьи веши будут показаны в данном окне. Не показывается в банке гильдии.", -- Needs review
			arrangementLabel = "Сортировка", -- Needs review
			charsDescription = "Открывает меню с выбором персонажей, чьи веши будут показаны в данном окне. Не показывается в банке гильдии.", -- Needs review
			charsLabel = "Персонажи", -- Needs review
			coinsDescription = "Открывает обзор всей валюты ваших персонажей и знакомых гильдий.", -- Needs review
			coinsLabel = "Валюта", -- Needs review
			description = "Заголовок окна содержит опции настройки внешнего вида вещей. Большинство иконок скрыто по умолчанию. Чтобы сделать их видимыми, просто перетяните курсор к верхней части окна. Эти настройки сохраняются отдельно для каждого окна и персонажа, давая возможность настроить разные отображения и поведение в каждом окне ImhoBags.", -- Needs review
			emptyDescription = "Показывает количество пустых ячеек. Нажмите на символ, чтобы показать пустые ячейки внутри окна.", -- Needs review
			emptyLabel = "Количетсво пустых ячеек", -- Needs review
			guildsDescription = "Открывает меню с выбором гильдии, чьи предметы будут показаны в данном окне. Показывается только в банке гильдии.", -- Needs review
			guildsLabel = "Гильдии", -- Needs review
			layoutBagsDescription = "Группирует предметы по сумкам, в которых они находятся.", -- Needs review
			layoutBagsLabel = "Сумки", -- Needs review
			layoutDefaultDescription = "Сортирует предметы по категориям, как они отображаются на аукционе. Не все предметы в игре имеют категорию (особенно предметы с мировых событий). В таком случае они отображаются в '%s'.", -- Needs review
			layoutDefaultLabel = "Категории", -- Needs review
			layoutDescription = "В нижней строке сортировки можно выбрать группирование:", -- Needs review
			layoutOnebagDescription = "Все предметы будут отображаться в одной большой общей сумке.", -- Needs review
			layoutOnebagLabel = "Общая сумка", -- Needs review
			locationDescription = "Эта иконка отображает принадлежность данного окна (инвентарь, банк, и т.д.). Наведите курсор сюда, чтобы показать возможные варианты.", -- Needs review
			locationLabel = "Принадлежность", -- Needs review
			searchDescription = "Показывает меню, в котором можно настроить размеры иконок.", -- Needs review
			searchLabel = "Поиск", -- Needs review
			sizeDescription = "Показывает меню, в котором можно настроить размеры иконок.", -- Needs review
			sizeLabel = "Размеры иконок", -- Needs review
			sortDescription = "В верхней строке можно выбрать вид сортировки:", -- Needs review
			sortIconDescription = "Сортирует предметы по имени файла их текстуры. Есть шанс правильной сортировки одинаковых предметов.", -- Needs review
			sortIconLabel = "По иконке", -- Needs review
			sortNameDescription = "Сортирует предметы по алфавиту. Порядок сортировки зависит от локализации.", -- Needs review
			sortNameLabel = "По алфавиту", -- Needs review
			sortNoneDescription = "Отменяет сортировку. Предметы отображаются в том же порядке, что и в игровых сумках.", -- Needs review
			sortNoneLabel = "Без сортировки", -- Needs review
			sortRarityDescription = "Сортирует предметы по их редкости в следующем порядке: %s.", -- Needs review
			sortRarityLabel = "По редкости", -- Needs review
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
		icon = "По иконке",
		name = "По имени",
		rarity = "По редкости",
	},
	Tooltip = {
		character = "Выбрать персонажа", -- Needs review
		config = "Настройки",
		guild = "Выбрать гильдию", -- Needs review
		guildvault = "Банк гильдии",
		size = "Размер",
		sorting = "сортировка",
		vault = "Хранилище", -- Needs review
	},
	WindowTitle = {
		bank = "Банк",
		CategorySort = "Category Sort", -- Requires localization
		currency = "Валюта", -- Needs review
		equipment = "Надето", -- Needs review
		inventory = "Рюкзак",
		mail = "Входящие",
		quest = "Задания", -- Needs review
		search = "Поиск", -- Needs review
		wardrobe = "Гардероб", -- Needs review
	},
}

