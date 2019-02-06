local addon, ns = ...
local cargBags = ns.cargBags

local cbNeav = cargBags:NewImplementation("Neav")
cbNeav:RegisterBlizzard()

function cbNeav:UpdateBags()
    for i = -3, 11 do
        cbNeav:UpdateBag(i)
    end
end

local L = cBneavL
cB_Filters = {}
cB_KnownItems = cB_KnownItems or {}
cBneav_CatInfo = {}
cB_ItemClass = {}

cB_existsBankBag = {
    Armor = true,
    Gem = true,
    Quest = true,
    TradeGoods = true,
    Consumables = true,
    BattlePet = true,
    Fishing = true
}

cB_filterEnabled = {
    Armor = true,
    Gem = true,
    Quest = true,
    TradeGoods = true,
    Consumables = true,
    Keyring = true,
    Junk = true,
    Stuff = true,
    ItemSets = true,
    BattlePet = true,
    Fishing = true
}

--------------------
--Basic filters
--------------------
cB_Filters.fBags = function(item)
    return item.bagID >= 0 and item.bagID <= 4
end

cB_Filters.fBank = function(item)
    return item.bagID == -1 or item.bagID >= 5 and item.bagID <= 11
end

cB_Filters.fBankReagent = function(item)
    return item.bagID == -3
end

cB_Filters.fBankFilter = function()
    return cBneavCfg.FilterBank
end

cB_Filters.fHideEmpty = function(item)
    if cBneavCfg.CompressEmpty then
        return item.link ~= nil
    else
        return true
    end
end

------------------------------------
-- General Classification (cached)
------------------------------------
cB_Filters.fItemClass = function(item, container)
    if ( not item.id ) then
        return false
    end

    if ( not cB_ItemClass[item.id] ) then
        cbNeav:ClassifyItem(item)
    end

    local class = cB_ItemClass[item.id]

    local isBankBag = item.bagID == -1 or (item.bagID >= 5 and item.bagID <= 11)

    if ( isBankBag ) then
        bag = (cB_existsBankBag[class] and cBneavCfg.FilterBank and cB_filterEnabled[class]) and "Bank"..class or "Bank"
    else
        bag = (class ~= "NoClass" and cB_filterEnabled[class]) and class or "Bag"
    end

    return bag == container
end

local function CanGoInBag(itemID, bagType)
    local itemFamily = GetItemFamily(itemID) or 0

    if ( itemFamily == 67108872 ) then
        return false
    end

    return bit.band(itemFamily, bagType) > 0
end

function cbNeav:ClassifyItem(item)
    -- User assigned containers.
    local customBag = cBneav_CatInfo[item.id]
    if ( customBag ) then
        cB_ItemClass[item.id] = customBag
        return true
    end

    -- Junk
    if ( item.quality == 0 ) then
        cB_ItemClass[item.id] = "Junk"
        return true
    end

    -- Type based filters.
    if ( item.type ) then
        if      (item.type == L.Armor or item.type == L.Weapon)     then cB_ItemClass[item.id] = "Armor"; return true               -- Weapons and Armor
        elseif  (item.type == L.Gem and item.subclassID == 11)      then cB_ItemClass[item.id] = "Armor"; return true               -- Artifact Relics
        elseif  (item.type == L.Quest)                              then cB_ItemClass[item.id] = "Quest"; return true               -- Quest Items
        elseif  (item.type == L.Trades)                             then cB_ItemClass[item.id] = "TradeGoods"; return true          -- Trade Goods
        elseif  (item.type == L.Gem)                                then cB_ItemClass[item.id] = "TradeGoods"; return true          -- Gems
        elseif  (item.type == L.ItemEnhancement)                    then cB_ItemClass[item.id] = "TradeGoods"; return true          -- Item Enhancement
        elseif  (item.type == L.Recipe)                             then cB_ItemClass[item.id] = "TradeGoods"; return true          -- Recipes
        elseif  (CanGoInBag(item.id, 0x8000))                       then cB_ItemClass[item.id] = "Fishing"; return true             -- Fishing
        elseif  (item.type == L.Consumables)                        then cB_ItemClass[item.id] = "Consumables"; return true         -- Consumables
        elseif  (item.type == L.BattlePet)                          then cB_ItemClass[item.id] = "BattlePet"; return true           -- Battle Pet
        elseif  (item.classID == 15 and item.subclassID == 2)       then cB_ItemClass[item.id] = "BattlePet"; return true           -- Companion Pets
        end
    end

    cB_ItemClass[item.id] = "NoClass"
end

------------------------------------------
-- New Items filter
------------------------------------------
cB_Filters.fNewItems = function(item)
    if ( not cBneavCfg.NewItems ) then
        return false
    end

    if ( not ((item.bagID >= 0) and (item.bagID <= 4)) ) then
        return false
    end

    if ( not item.link ) then
        return false
    end

    if ( not cB_KnownItems[item.id] ) then
        return true
    end

    return GetItemCount(item.id) > cB_KnownItems[item.id]
end

-----------------------------------------
-- Item Set filter
-----------------------------------------

cB_Filters.fItemSets = function(item)
    if ( not cB_filterEnabled["ItemSets"] ) then
        return false
    end

    if ( not item.link ) then
        return false
    end

    if ( not cargBags.itemKeys["setID"](item) ) then
        return false
    end

    return true
end
