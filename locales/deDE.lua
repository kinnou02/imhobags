local private = select(2, ...)

if(Inspect.System.Language() ~= "German" ) then
	return
end

setfenv(1, private)
L = { }
L.CategoryName = {
	armor = "Rüstungen",
	["armor costume"] = "Kostüme",
	["artifact bounty"] = "Sammlerstücke", -- Needs review
	["artifact fishing"] = "Collectibles", -- Requires localization
	["artifact normal"] = "Sammlerstücke", -- Needs review
	["artifact other"] = "Sammlerstücke", -- Needs review
	["artifact twisted"] = "Sammlerstücke", -- Needs review
	["artifact unstable"] = "Sammlerstücke", -- Needs review
	consumable = "Verbrauchsgüter",
	["consumable enchantment"] = "Enchantments", -- Requires localization
	container = "Behälter",
	crafting = "Handwerk",
	["crafting ingredient drop"] = "Beuteobjekte",
	["crafting ingredient reagent"] = "Reagenzien",
	["crafting ingredient rift"] = "Risse",
	["crafting material butchering"] = "Leder", -- Needs review
	["crafting material cloth"] = "Stoff",
	["crafting material component"] = "Runenkomponenten",
	["crafting material fish"] = "Fisch",
	["crafting material gem"] = "Edelsteine",
	["crafting material meat"] = "Fleisch",
	["crafting material metal"] = "Metall",
	["crafting material plant"] = "Pflanzen",
	["crafting material wood"] = "Holz",
	["crafting recipe dream weaver"] = "Dream Weaving", -- Requires localization
	dimension = "Dimension",
	empty = "Leer",
	lootable = "Plünderbar",
	misc = "Verschiedenes",
	["misc collectible"] = "Sammlerstücke",
	["misc mount"] = "Sammelobjekte",
	["misc pet"] = "Sammelobjekte",
	["misc quest"] = "Quest",
	planar = "Ebenenobjekte",
	sellable = "Plunder",
	wardrobe = "Garderobenset %i",
	weapon = "Waffen",
}
L.Currency = {
	gold = "Gold",
	platinum = "Platin",
	silver = "Silber",
}
L.Rarity = {
	common = "Gewöhnlich",
	epic = "Episch",
	junk = "Plunder",
	quest = "Quest",
	rare = "Selten",
	relic = "Relikt",
	uncommon = "Ungewöhnlich",
}
L.SlashMessage = {
	configOptions = [=[Verfügbare Konfigurationsoptionen:
* autoOpen yes/no
	Bestimmt, ob die Gegenstandsfenster zusammen mit den Inventar- oder Bankfenstern
	von Trion geöffnet werden.
* condensed yes/no
	Bestimmt, ob mehrere volle Stapel des gleichen Gegenstandtyps in einen Button
	zusammengefasst werden sollen um das Fenster kleiner zu halten.
* enhanceTooltips yes/no
	Bestimmt, ob bei Gegenstands-Tooltips zusätzlich angezeigt werden soll,
	welche deiner Charaktere den angezeigten Gegenstand bereits besitzen.
* itemButtonSkin pretty/simple
	Bestimmt, wie die Item-Buttons dargestellt werden. "simple" hat kaum visuelle
	Effekte, "pretty" versucht möglichst die Buttons von Trion nachzuahmen. Benötigt
	ein /reloadui bevor es wirksam wird. "simple" kann bei sehr geringer UI-Skalierung
	besser aussehen.
* showEmptySlots yes/no
	Bestimmt, ob die Anzahl der freien Taschenplätze über der Taschenleiste angezeigt wird.]=],
	unknownChar = "Keine Daten für Charakter \"%s\" verfügbar.",
	unknownLocation = [=[Unbekannter Ort "%s".
"location" muss eines der folgenden sein:
	* Rucksack: "inventory", "inv" oder "i"
	* Bank: "bank" oder "b"
	* Ausrüstung: "equipment" oder "e"
	* Quest: "quest" oder "q"
	* Währungen: "currency" oder "c"
	* Standardmäßig "inventory" wenn ausgelassen]=],
	usage = [=[Richtige Benutzung:
/imhobags character [location]
	"character" muss der volle Name eines deiner Charaktere auf dem gleichen Shard
		sein (Groß-/Kleinschreibung beachten). Oder gib "player" für deinen jetzigen Charakter an.
	"location" muss eines der folgenden sein:
		* Rucksack: "inventory", "inv" oder "i"
		* Bank: "bank" oder "b"
		* Ausrüstung: "equipment" oder "e"
		* Quest: "quest" oder "q"
		* Währungen: "currency" oder "c"
		* Standardmäßig "inventory" wenn ausgelassen
/imhobags search
	Öffnet das Suchfenster
/imhobags config
	Öffnet das Einstellungsfenster
/imhobags config [value]
	Setzt eine Einstellung oder gibt ihren aktuellen Wert aus.
/imhobags config help
	Listet alle Einstellungen mit detaillierter Beschreibung auf.
/imhobags config list
 	Listet alle Einstellungen mit ihren aktuellen Werten auf.]=],
}
L.TooltipEnhancer = {
	bank = "(Bank %i)",
	currency = "(Währungen %i)",
	equipment = "(Angezogen %i)",
	inventory = "(Taschen %i)",
	mail = "(Post %i)",
	quest = "(Quest %i)",
	wardrobe = "(Kostüm %i)",
}
L.Ux = {
	bankVault = "Tresor %i", -- Needs review
	cashOnDelivery = "Nachnahmesumme",
	defiant = "Skeptiker",
	guardian = "Wächter",
	guildVault = "Tresor %i",
	search = "<Suchtext eingeben>",
	ConfigWindow = {
		autoOpen = "Wähle, ob die ImhoBags Bank- und Inventarfenster automatisch geöffnet und geschlossen werden sollen wenn die dazugehörigen Trion Fenster geschlossen beziehungsweise geöffnet werden.",
		condensed = "Wähle, ob volle Stapel des gleichen Gegenstandtyps in einem Button zusammengefasst werden um Platz zu sparen, oder ob jeder Stapel separat für sich angezeigt wird.",
		enhanceTooltips = "Wähle, ob bei den Gegenstands-Tooltips zusätzlich angezeigt werden soll, welche deiner Charaktere den angezeigten Gegenstand bereits besitzen.",
		itemButtonSkin = "Wähle wie Gegnstandbuttons dargestellt werden sollen. Die linke Option benötigt mehr Ressourcen als die Rechte, allerdings sieht sie nicht so gut aus. Wenn du mit sehr niedriger UI Skalierung spielst könnte die rechte Option eventuell besser aussehen. Es wird ein /reloadui benötigt damit diese Änderung wirksam wird.",
		setCategorySort = "Click the image below to open the 'Set Category Sort Order' window.  This feature will allow you to customize how categories are sorted within the imhobags inventory windows.", -- Requires localization
		showBoundIcon = "Zeige ein kleines Symbol über seelen- und accountgebundenen Gegenständen an. Ein blaues Symbol markiert seelengebundene, ein rot/blau gefärbtes accountgebundene Gegenstände.",
		showEmptySlots = "Wähle, ob über der Taschenleiste ein Zähler angezeigt werden soll, auf dem die Anzahl der verbleibenden freien Taschenplätze im Inventar zu sehen ist.",
		showTooltips = "Zeige Slash-Befehle",
		title = "Einstellungen für Imhothar's Bags",
		updateItemsTimerInterval = "The following (advanced) setting allows you to select the number of seconds the addon waits (after an inventory change) before updating the window.  When this value is greater than zero, imhobags will update immediately on the first inventory change and then will not update again until # seconds has elapsed without any other inventory changes.   (This setting is especially useful for players who move large amounts of items from one window to another and are frustrated by categories shifting between moves.)  \\n[Default = 0]", -- Requires localization
		onebag = {
			description = "Falls du die \"all-in-one\" Ansicht (in der Gegenstände weder sortiert, noch gruppiert werden) vorziehst, so kannst du ImhoBags mit den folgenden Optionen einstellen, dass es sich genau so verhält:",
		},
		sections = {
			appearance = "Aussehen",
			behavior = "Verhalten",
			extras = "Extras",
			onebag = "Hilfe: One Bag",
			titleBar = "Hilfe: Titelleiste",
		},
		titleBar = {
			arrangementDescription = "Öffnet ein Menü zum Einstellen der Sortier- und Gruppierungsmethode.",
			arrangementLabel = "Anordnung",
			charsDescription = "Öffnet ein Menü zum Auswählen des Charakters, dessen Gegenstände im aktuellen Fenster angezeigt werden. Nur außerhalb der Gildenbank sichtbar.",
			charsLabel = "Charaktere",
			coinsDescription = "Öffnet eine Übersicht mit dem Geld aller Charaktere und bekannter Gilden.",
			coinsLabel = "Geld",
			description = "Die Titelleiste enthält Optionen, mit denen man das Aussehen von Gegenständen anpassen kann. Die meisten Schaltflächen sind standardmäßig versteckt. Um sie sichtbar zu machen muss man nur mit dem Mauszeiger über die obere Gegend fahren. Diese Einstellungen werden für jedes Fenster separat gespeichert, d.h. es ist möglich für jeden Charakter und jedes Fenster ein eigenes Aussehen festzulegen.",
			emptyDescription = "Zeigt die Anzahl der leeren Plätze im aktuellen Ort an. Ein Klick darauf wechselt die Anzeige von leeren Gegenstandsplätzen im Fenster um.",
			emptyLabel = "Leere Plätze",
			guildsDescription = "Öffnet ein Menü zum Auswählen der Gilde, deren Gegenstände im aktuellen Fenster angezeigt werden. Nur in der Gildenbank sichtbar.",
			guildsLabel = "Gilden",
			layoutBagsDescription = "Gegenstände werden anhand der Tasche gruppiert, in der die abgelegt sind.",
			layoutBagsLabel = "Taschen",
			layoutDefaultDescription = "Gegenstände werden anhand ihrer Kategorie im Auktionshaus in Gruppen zusammengefasst. Bitte beachte, dass das Spiel für manche Gegenstände keine Kategorieinformationen liefert. Diese werden dann in \"%s\" abgelegt.",
			layoutDefaultLabel = "Kategorie",
			layoutDescription = "In der unteren Zeile des Gestaltungsmenüs wählt man auf welche Weise Gegenstände gruppiert werden:",
			layoutOnebagDescription = "Alle Gegenstände werden in eine große Tasche zusammengelegt.",
			layoutOnebagLabel = "Onebag",
			locationDescription = "Dieses Symbol zeigt den Ort (Inventar, Bank, usw.) des aktuellen Fensters an. Bewege den Mauszeiger darüber um alle verfügbaren Orte anzuzeigen.",
			locationLabel = "Ort",
			searchDescription = "Die dunkle Fläche dient als Texteingabe. Alle Gegenstände, die den eingegebenen Text im Namen enthalten, werden hervorgehoben. Ein Klick auf das Symbol öffnet ein Suchfenster mit den Gegenständen aller Charaktere und Gilden.",
			searchLabel = "Suche",
			sizeDescription = "Öffnet ein Menü zum Auswählen der Größe von Gegenständen.",
			sizeLabel = "Größe",
			sortDescription = "In der oberen Hälfte des Gestaltungsmenüs wählt man die Sortiermethode der Gegenstände aus:",
			sortIconDescription = "Sortiert Gegenstände anhand der Dateinamen ihrer Bilder. Diese Methode hat die Chance ähnliche Gegenstände näher beisammen zu gruppieren.",
			sortIconLabel = "Bild",
			sortNameDescription = "Sortiert Gegenstände von Links nach Rechts anhand ihres Namens. Die Reihenfolge hängt vom Sortieralgorithmus der Spielsprache ab.",
			sortNameLabel = "Alphabetisch",
			sortNoneDescription = "Gegenstände werden überhaupt nicht sortiert, sondern erscheinen in der gleichen Reihenfolge, in der sie in den Standardfenstern des Spiels abgelegt sind.",
			sortNoneLabel = "Keine",
			sortRarityDescription = "Sortiert Gegenstände von Links nach Rechts anhand ihrerer Seltenheit in folgender Reihenfolge: %s.",
			sortRarityLabel = "Seltenheit",
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
		icon = "Bild",
		name = "Name",
		rarity = "Seltenheit",
	},
	Tooltip = {
		character = "Character auswählen",
		config = "Einstellungen",
		guild = "Gilde auswählen",
		guildvault = "Gildentresor",
		size = "Größe",
		sorting = "Sortierung",
		vault = "Tresor", -- Needs review
	},
	WindowTitle = {
		bank = "Bank",
		CategorySort = "Category Sort", -- Requires localization
		currency = "Währungen",
		equipment = "Ausgerüstet",
		inventory = "Rucksack",
		mail = "Postfach",
		quest = "Quest",
		search = "Datenbank Durchsuchen",
		wardrobe = "Garderobe",
	},
}

