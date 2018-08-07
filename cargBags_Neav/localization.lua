cBneavL = {}
local gl = GetLocale()

cBneavL.Search = SEARCH
cBneavL.Armor = GetItemClassInfo(4)
cBneavL.BattlePet = GetItemClassInfo(17)
cBneavL.Consumables = GetItemClassInfo(0)
cBneavL.Gem = GetItemClassInfo(3)
cBneavL.Quest = GetItemClassInfo(12)
cBneavL.Trades = GetItemClassInfo(7)
cBneavL.Weapon = GetItemClassInfo(2)
cBneavL.Recipe = GetItemClassInfo(9)
cBneavL.ItemEnhancement = GetItemClassInfo(8)
cBneavL.ArtifactPower = ARTIFACT_POWER
cBneavL.bagCaptions = {
	["cBneav_Bank"] 			    = BANK,
	["cBneav_BankReagent"]	        = REAGENT_BANK,
	["cBneav_BankSets"]		        = LOOT_JOURNAL_ITEM_SETS,
	["cBneav_BankArmor"]		    = BAG_FILTER_EQUIPMENT,
	["cBneav_BankGem"]		        = AUCTION_CATEGORY_GEMS,
	["cBneav_BankQuest"]		    = AUCTION_CATEGORY_QUEST_ITEMS,
	["cBneav_BankTrade"]		    = BAG_FILTER_TRADE_GOODS,
    ["cBneav_BankPet"]		        = AUCTION_CATEGORY_BATTLE_PETS,
	["cBneav_BankCons"]		        = BAG_FILTER_CONSUMABLES,
	["cBneav_BankArtifactPower"]	= ARTIFACT_POWER,
    ["cBneav_BankFishing"]          = PROFESSIONS_FISHING,
	["cBneav_Junk"]			        = BAG_FILTER_JUNK,
	["cBneav_ItemSets"]		        = LOOT_JOURNAL_ITEM_SETS,
	["cBneav_Armor"]			    = BAG_FILTER_EQUIPMENT,
	["cBneav_Gem"]			        = AUCTION_CATEGORY_GEMS,
	["cBneav_Quest"]			    = AUCTION_CATEGORY_QUEST_ITEMS,
	["cBneav_Consumables"]	        = BAG_FILTER_CONSUMABLES,
	["cBneav_ArtifactPower"]	    = ARTIFACT_POWER,
	["cBneav_TradeGoods"]	        = BAG_FILTER_TRADE_GOODS,
	["cBneav_BattlePet"]		    = AUCTION_CATEGORY_BATTLE_PETS,
	["cBneav_Bag"]			        = INVENTORY_TOOLTIP,
	["cBneav_Keyring"]		        = KEYRING,
    ["cBneav_Fishing"]              = PROFESSIONS_FISHING,
}

if gl == "deDE" then
	cBneavL.MarkAsNew = "Als neu markieren"
	cBneavL.MarkAsKnown = "Als bekannt markieren"
	cBneavL.bagCaptions.cBneav_Stuff = "Cooles Zeugs"
	cBneavL.bagCaptions.cBneav_NewItems = "Neue Items"
elseif gl == "ruRU" then
	cBneavL.MarkAsNew = "Перенести в Новые предметы"
	cBneavL.MarkAsKnown = "Перенести в Известные предметы"
	cBneavL.bagCaptions.cBneav_Stuff = "Разное"
	cBneavL.bagCaptions.cBneav_NewItems = "Новые предметы"
elseif gl == "zhTW" then
	cBneavL.MarkAsNew = "Mark as New"
	cBneavL.MarkAsKnown = "Mark as Known"
	cBneavL.bagCaptions.cBneav_Stuff = "施法材料"
	cBneavL.bagCaptions.cBneav_NewItems = "新增"
elseif gl == "zhCN" then
	cBneavL.MarkAsNew = "Mark as New"
	cBneavL.MarkAsKnown = "Mark as Known"
	cBneavL.bagCaptions.cBneav_Stuff = "施法材料"
	cBneavL.bagCaptions.cBneav_NewItems = "新增"
elseif gl == "koKR" then
	cBneavL.MarkAsNew = "Mark as New"
	cBneavL.MarkAsKnown = "Mark as Known"
	cBneavL.bagCaptions.cBneav_Stuff = "지정"
	cBneavL.bagCaptions.cBneav_NewItems = "신규"
elseif gl == "frFR" then
	cBneavL.MarkAsNew = "Marquer comme Neuf"
	cBneavL.MarkAsKnown = "Marquer comme Connu"
	cBneavL.bagCaptions.cBneav_Stuff = "Divers"
	cBneavL.bagCaptions.cBneav_NewItems = "Nouveaux Objets"
elseif gl == "itIT" then
    cBneavL.MarkAsNew = "Segna come Nuovo"
    cBneavL.MarkAsKnown = "Segna come Conosciuto"
	cBneavL.bagCaptions.cBneav_Stuff = "Cose Interessanti"
	cBneavL.bagCaptions.cBneav_NewItems = "Oggetti Nuovi"
else
	cBneavL.MarkAsNew = "Mark as New"
	cBneavL.MarkAsKnown = "Mark as Known"
	cBneavL.bagCaptions.cBneav_Stuff = "Cool Stuff"
	cBneavL.bagCaptions.cBneav_NewItems = "New Items"
end
