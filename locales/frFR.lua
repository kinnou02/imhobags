local private = select(2, ...)

if(Inspect.System.Language() ~= "French" ) then
	return
end

setfenv(1, private)
L = { }
L.CategoryName = {
	armor = "Armure",
	["armor costume"] = "Costumes",
	["artifact bounty"] = "Collectionnables", -- Needs review
	["artifact fishing"] = "Collectibles", -- Requires localization
	["artifact normal"] = "Collectionnables", -- Needs review
	["artifact other"] = "Collectionnables", -- Needs review
	["artifact twisted"] = "Collectionnables", -- Needs review
	["artifact unstable"] = "Collectionnables", -- Needs review
	consumable = "Consommables",
	["consumable enchantment"] = "Enchantments", -- Requires localization
	container = "Conteneurs",
	crafting = "Artisanat",
	["crafting ingredient drop"] = "Compo. d'artisan",
	["crafting ingredient reagent"] = "Ingredients d'artisan",
	["crafting ingredient rift"] = "Compo. Failles",
	["crafting material butchering"] = "Cuirs", -- Needs review
	["crafting material cloth"] = "Tissus",
	["crafting material component"] = "Compo. Runes",
	["crafting material fish"] = "Poissons",
	["crafting material gem"] = "Gemmes",
	["crafting material meat"] = "Viandes",
	["crafting material metal"] = "Métaux",
	["crafting material plant"] = "Plantes",
	["crafting material wood"] = "Bois",
	["crafting recipe dream weaver"] = "Dream Weaving", -- Requires localization
	dimension = "Dimension",
	empty = "Vide",
	lootable = "Ramassable",
	misc = "Divers",
	["misc collectible"] = "Collectionnables",
	["misc mount"] = "Collectionnables",
	["misc pet"] = "compagnons",
	["misc quest"] = "Quêtes",
	planar = "Planaires",
	sellable = "sans valeur",
	wardrobe = "Garde-robe %i",
	weapon = "Armes",
}
L.Currency = {
	gold = "Or",
	platinum = "Platine",
	silver = "Argent",
}
L.Rarity = {
	common = "commun",
	epic = "épique",
	junk = "sans valeur",
	quest = "quête",
	rare = "rare",
	relic = "relique",
	uncommon = "peu commun",
}
L.SlashMessage = {
	configOptions = [=[Options de configuration

Options disponibles
   *Ouverture automatique oui/non
    Détermine si l'inventaire ou banque s'ouvre et se ferme en même temps que la fenêtre native
  *Condensé oui/non
    Détermine si de multiples tas d'un même item sont rassemblés pour gagner de la place à l'écran
 * Infobulle améliorée
    Détermine si les infobulles sont étendues à des informations additionnelles affichant les quantités d'un item détenus par vos autres personnage
  *Skin d'item  basique/amélioré
   Détermine l'affichage des items . "basique" est sans effets visuel, "amélioré" est plus proche de l'affichage Trion . Requiert un /reloadui pour prendre les changements en compte . "basique" peut rendre mieux sur des interfaces à basse echelle
  *Voir les emplacements vides oui/non
     Détermine si les emplacements vides des sacs est affiché par dessus la barre de sacs Trion]=],
	unknownChar = "Personnage inconnu",
	unknownLocation = [=[Emplacement invalide
  "emplacement" doit correspondre à:
    *Sac à dos:"inventaire", "inv" ou "i"
    *Banque: "banque" ou "b"
    *Devises: "devises" ou "d"
    *Equipement: "equipement" ou "e"
    *Quête : "quête" ou "q"
     Par défaut "inventaire" si oublié]=],
	usage = [=[Utilisation:
  /imhobags personnage [emplacement]
   "personnage" doit être le nom complet d'un de vos personnages
   "emplacement" doit être:  
        *Sac à dos: "inventaire", "inv" ou "i"
        *Banque: "banque" ou "b"
        *Monnaies : "monnaies" ou "c"
        *Equipement : "Equipement" ou "e"
        *Quête: "Quête" ou "q"
        *Par défaut si aucun paramètre cela reviendra à "inventaire"
/imhobags recherche
     Ouvre la fenêtre de recherche
/imhobags config
     Ouvre la fenêtre de configuration
/imhobags config [valeur]
      Rêgle ou appelle une option de configuration
/imhobags Config aide
      Liste toutes les options disponibles avec descriptions détaillées
/imhobags config liste
      Liste toutes les options des options de configuration

Ce message s'affiche si /imhobags  est utilisé incorrectement]=],
}
L.TooltipEnhancer = {
	bank = "(banque %i)",
	currency = "(Devises %i)",
	equipment = "(équipé %i)",
	inventory = "(sacs %i)",
	mail = "(courrier %i)",
	quest = "(quête %i)",
	wardrobe = "(garde-robe %i)",
}
L.Ux = {
	bankVault = "Coffre %i", -- Needs review
	cashOnDelivery = "Paiement à la livraison",
	defiant = "Renégat",
	guardian = "Gardien",
	guildVault = "Banque %i",
	search = "<entrer le texte recherché>",
	ConfigWindow = {
		autoOpen = "Détermine si l'inventaire imhobags ou la fénêtre de banque s'ouvre automatiquement lorsque les fenêtres respectives de Trion sont ouvertes ou fermées.",
		condensed = "Détermine si de multiples piles d'un même objets sont réunis en une pile ou affichés séparément.",
		enhanceTooltips = "Détermine si vous voulez que les infobulles affichent des données additionnelles montrant lesquels de vos personnages détiennent également l'item affiché",
		itemButtonSkin = "Détermine comment les boutons d'items sont rendus . l'option de gauche requiert plus de ressources que celle de droite mais donne un plus bel affichage . Si vous jouez avec un affichage d'interface très bas le règlage de droite sera peut-être plus adapté . A noter que pour prendre en charge les changements vous devrez faire un /reloadui.",
		setCategorySort = "Click the image below to open the 'Set Category Sort Order' window.  This feature will allow you to customize how categories are sorted within the imhobags inventory windows.", -- Requires localization
		showBoundIcon = "Place un petit indicateur pour les objets liés à l'âme ou au compte . Un indicateur bleu indique un objet lié à l'âme, teinté de rouge signifie lié au compte",
		showEmptySlots = "Détermine si vous voulez afficher le comptage d'emplacements vides par dessus l'affichage des sacs.",
		showTooltips = "Voir les commandes Slash",
		title = "Configuration de imhothar's Bags",
		updateItemsTimerInterval = "The following (advanced) setting allows you to select the number of seconds the addon waits (after an inventory change) before updating the window.  When this value is greater than zero, imhobags will update immediately on the first inventory change and then will not update again until # seconds has elapsed without any other inventory changes.   (This setting is especially useful for players who move large amounts of items from one window to another and are frustrated by categories shifting between moves.)  \\n[Default = 0]", -- Requires localization
		onebag = {
			description = "Si vous préférez l'affichage du \"tout-en-un\" sans aucune sorte de rangement ou de tri, alors l'option suivante permet à imhobags de réagir de la sorte: ",
		},
		sections = {
			appearance = "Apparence",
			behavior = "Comportement",
			extras = "plus",
			onebag = "Aide: un sac",
			titleBar = "Aide: Barre de titre",
		},
		titleBar = {
			arrangementDescription = "Affiche un menu ou vous pouvez régler le rangement et le regroupement des objets.",
			arrangementLabel = "Rangement",
			charsDescription = "Ouvre un menu vous permettant de choisir de quel personnage les objets seront affichés . ne fonctionne pas en banque de guilde. ",
			charsLabel = "Personnages",
			coinsDescription = "Ouvre un aperçu de tout l'agent de vos personnages connus et guildes connues.",
			coinsLabel = "Argent",
			description = "La barre de titre détient des options qui vous permettent d'améliorer l'apparence des objets . La plupart des boutons sont cachés par défaut . Pour les afficher il suffit de passer le curseur de la souris sur le haut de la fenêtre . Ces options sont sauvegardées séparément pour chaque fenêtre et chaque personnage, permettant d'avoir différentes apparences et comportements éventuels.",
			emptyDescription = "Montre le nombre d'emplacements vides . Cliquer sur le symbole permute l'affichage des emplacements vides ou non dans la fenêtre.",
			emptyLabel = "emplacements vides",
			guildsDescription = "Ouvre un menu vous permettant de choisir quels Items de guilde sont affichés dans la fenêtre active . Ne fonctionne qu'en banque de guilde.",
			guildsLabel = "Guildes",
			layoutBagsDescription = "Grouper les objets en fonction du sac dans lequel ils sont.",
			layoutBagsLabel = "Sacs",
			layoutDefaultDescription = "Les objets sont regroupés par catégorie similaire à ce qu'il en est dans l’hôtel des ventes . Notez que le jeu ne fournit pas d'information de catégorie pour certains objets ( comme les objets d'événements de monde) . Dans ce cas ils sont regroupés dans  '%s' ",
			layoutDefaultLabel = "Catégorie",
			layoutDescription = "Dans la ligne du bas du menu de rangement vous pouvez choisir comment les objets sont groupés:",
			layoutOnebagDescription = "Tous les objets regroupés dans un seul gros sac",
			layoutOnebagLabel = "Un sac",
			locationDescription = "Cet icone montre l'emplacement de la fenêtre courante ( inventaire, banque, etc.) . Placez le curseur ici pour montrer les emplacements disponibles.",
			locationLabel = "Emplacement",
			searchDescription = "La zone sombre est une saisie de texte fonctionnant comme un filtre, les objets en surbrillance dans la fenêtre sont les correspondances au texte entré . En cliquant sur l'icone souvre une fenêtre séparée ou vous pouvez effectuer des recherches de tous les objets détenus par vos personnages connus et guildes connues .",
			searchLabel = "Rechercher",
			sizeDescription = "Affiche un menu ou vous pouvez régler la taille des objets",
			sizeLabel = "Taille",
			sortDescription = "Dans la ligne du haut du menu de rangement vous pouvez sélectionner comment les objets sont rangés:",
			sortIconDescription = "Ranger les objets par le nom de fichier de leur texture d’icône en jeu. Cela a une chance de grouper les objets similaires.",
			sortIconLabel = "Icône",
			sortNameDescription = "Ranger les objets alphabétiquement de la gauche vers la droite . L'ordre dépend de l’algorithme de rangement implémenté dans la traduction interne du jeu.",
			sortNameLabel = "Alphabétiquement",
			sortNoneDescription = "Ne correspond à aucun rangement. Les objets sont affichés de la gauche vers la droite comme dans le sac du jeu sans aucune sorte de triage.",
			sortNoneLabel = "Aucun",
			sortRarityDescription = "Ranger les objets en fonction de leur rareté de la gauche vers la droite dans l'ordre: %s.",
			sortRarityLabel = "Rareté",
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
		icon = "Icone",
		name = "Nom",
		rarity = "Rareté",
	},
	Tooltip = {
		character = "Sélectionner le personnage",
		config = "Configuration",
		guild = "Sélectionner la guilde",
		guildvault = "Banque de guilde",
		size = "Taille",
		sorting = "Trier",
		vault = "Coffre", -- Needs review
	},
	WindowTitle = {
		bank = "Banque",
		CategorySort = "Category Sort", -- Requires localization
		currency = "Devises",
		equipment = "Equipé",
		inventory = "Sac à dos",
		mail = "Boîte de réception",
		quest = "Quête",
		search = "Rechercher dans la base de données",
		wardrobe = "Garde-robe",
	},
}

