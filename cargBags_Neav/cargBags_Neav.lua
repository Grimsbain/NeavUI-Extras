local addon, ns = ...
local cargBags = ns.cargBags

cargBags_Neav = CreateFrame("Frame", "cargBags_Neav", UIParent)
cargBags_Neav:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)
cargBags_Neav:RegisterEvent("ADDON_LOADED")

local cbNeav = cargBags:GetImplementation("Neav")

do  --Replacement for UIDropDownMenu

    local frameHeight = 14
    local defaultWidth = 120
    local frameInset = 16

    local f = cbNeavCatDropDown or CreateFrame("Frame", "cbNeavCatDropDown", UIParent)
    f.ActiveButtons = 0
    f.Buttons = {}

    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetSize(defaultWidth+frameInset,32)
    f:SetClampedToScreen(true)

    local inset = 1
    f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = inset, right = inset, top = inset, bottom = inset }})
    local colors = ns.options.colors.background
    f:SetBackdropColor(unpack(colors))
    f:SetBackdropBorderColor(0, 0, 0)

    function f:CreateButton()

        local button = CreateFrame("Button", nil, self)
        button:SetWidth(defaultWidth)
        button:SetHeight(frameHeight)

        local fstr = button:CreateFontString()
        fstr:SetJustifyH("LEFT")
        fstr:SetJustifyV("MIDDLE")
        fstr:SetFont(unpack(ns.options.fonts.dropdown))
        fstr:SetPoint("LEFT", button, "LEFT", 0, 0)
        button.Text = fstr

        function button:SetText(str)
            button.Text:SetText(str)
        end

        button:SetText("test")

        local ntex = button:CreateTexture()
        ntex:SetColorTexture(1,1,1,0)
        ntex:SetAllPoints()
        button:SetNormalTexture(ntex)

        local htex = button:CreateTexture()
        htex:SetColorTexture(1,1,1,0.2)
        htex:SetAllPoints()
        button:SetHighlightTexture(htex)

        local ptex = button:CreateTexture()
        ptex:SetColorTexture(1,1,1,0.4)
        ptex:SetAllPoints()
        button:SetPushedTexture(ptex)

        return button

    end

    function f:AddButton(text, value, func)

        local bID = self.ActiveButtons+1

        local btn = self.Buttons[bID] or self:CreateButton()

        btn:SetText(text or "")
        btn.value = value
        btn.func = func or function() end

        btn:SetScript("OnClick", function(self, ...) self:func(...) self:GetParent():Hide() end)

        btn:ClearAllPoints()
        if bID == 1 then
            btn:SetPoint("TOP", self, "TOP", 0, -(frameInset/2))
        else
            btn:SetPoint("TOP", self.Buttons[bID-1], "BOTTOM", 0, 0)
        end

        self.Buttons[bID] = btn
        self.ActiveButtons = bID

        self:UpdateSize()

    end

    function f:UpdatePosition(frame, point, relativepoint, ofsX, ofsY)

        point, relativepoint, ofsX, ofsY = point or "TOPLEFT", relativepoint or "BOTTOMLEFT", ofsX or 0, ofsY or 0

        self:ClearAllPoints()
        self:SetPoint(point, frame, relativepoint, ofsX, ofsY)

    end

    function f:UpdateSize()

        local maxButtons = self.ActiveButtons
        local maxwidth = defaultWidth

        for i=1,maxButtons do

            local width = self.Buttons[i].Text:GetWidth()
            if width > maxwidth then maxwidth = width end

        end

        for i=1,maxButtons do
            self.Buttons[i]:SetWidth(maxwidth)
        end

        local height = maxButtons * frameHeight

        self:SetSize(maxwidth+frameInset, height+frameInset)

    end

    function f:Toggle(frame, point, relativepoint, ofsX, ofsY)
        cbNeav:CatDropDownInit()
        self:UpdatePosition(frame, point, relativepoint, ofsX, ofsY)
        self:Show()
    end

    tinsert(UISpecialFrames,f:GetName())

end

---------------------------------------------
---------------------------------------------
local L = cBneavL
cB_Bags = {}
cB_BagHidden = {}
cB_CustomBags = {}

-- Those are default values only, change them ingame via "/cbneav":
local optDefaults = {
                    NewItems = true,
                    Restack = true,
                    TradeGoods = true,
                    Armor = true,
                    Gem = true,
                    CoolStuff = false,
                    Junk = true,
                    ItemSets = true,
                    Consumables = true,
                    Quest = true,
                    Fishing = true,
                    BankBlack = true,
                    scale = 1,
                    FilterBank = true,
                    CompressEmpty = true,
                    Unlocked = true,
                    SortBags = true,
                    SortBank = true,
                    BankCustomBags = true,
                    SellJunk = true,
                    }

-- Those are internal settings, don"t touch them at all:
local defaults = {}

local ItemSetCaption = "Item" --(IsAddOnLoaded("ItemRack") and "ItemRack ") or (IsAddOnLoaded("Outfitter") and "Outfitter ") or "Item "
local bankOpenState = false

function cbNeav:ShowBags(...)
    local bags = {...}
    for i = 1, #bags do
        local bag = bags[i]
        if not cB_BagHidden[bag.name] then
            bag:Show()
        end
    end
end
function cbNeav:HideBags(...)
    local bags = {...}
    for i = 1, #bags do
        local bag = bags[i]
        bag:Hide()
    end
end

local LoadDefaults = function()
    cBneav = cBneav or {}
    for k,v in pairs(defaults) do
        if ( type(cBneav[k]) == "nil" ) then cBneav[k] = v end
    end
    cBneavCfg = cBneavCfg or {}
    for k,v in pairs(optDefaults) do
        if( type(cBneavCfg[k]) == "nil" ) then cBneavCfg[k] = v end
    end
end

function cargBags_Neav:ADDON_LOADED(event, addon)

    if (addon ~= "cargBags_Neav") then return end
    self:UnregisterEvent(event)

    LoadDefaults()

    cB_filterEnabled["Armor"] = cBneavCfg.Armor
    cB_filterEnabled["Gem"] = cBneavCfg.Gem
    cB_filterEnabled["TradeGoods"] = cBneavCfg.TradeGoods
    cB_filterEnabled["Junk"] = cBneavCfg.Junk
    cB_filterEnabled["ItemSets"] = cBneavCfg.ItemSets
    cB_filterEnabled["Consumables"] = cBneavCfg.Consumables
    cB_filterEnabled["Quest"] = cBneavCfg.Quest
    cB_filterEnabled["Fishing"] = cBneavCfg.Fishing
    cBneav.BankCustomBags = cBneavCfg.BankCustomBags
    cBneav.BagPos = true

    -----------------
    -- Frame Spawns
    -----------------
    local C = cbNeav:GetContainerClass()

    -- Bank Bags
    cB_Bags.bankSets        = C:New("cBneav_BankSets")

    if cBneav.BankCustomBags then
        for _,v in ipairs(cB_CustomBags) do
            cB_Bags["Bank"..v.name] = C:New("Bank"..v.name)
            cB_existsBankBag[v.name] = true
        end
    end

    cB_Bags.bankArmor           = C:New("cBneav_BankArmor")
    cB_Bags.bankGem             = C:New("cBneav_BankGem")
    cB_Bags.bankConsumables     = C:New("cBneav_BankCons")
    cB_Bags.bankArtifactPower   = C:New("cBneav_BankArtifactPower")
    cB_Bags.bankBattlePet       = C:New("cBneav_BankPet")
    cB_Bags.bankQuest           = C:New("cBneav_BankQuest")
    cB_Bags.bankTrade           = C:New("cBneav_BankTrade")
    cB_Bags.bankFishing         = C:New("cBneav_BankFishing")
    cB_Bags.bankReagent         = C:New("cBneav_BankReagent")
    cB_Bags.bank                = C:New("cBneav_Bank")

    cB_Bags.bankSets            :SetMultipleFilters(true, cB_Filters.fBank, cB_Filters.fBankFilter, cB_Filters.fItemSets)
    cB_Bags.bankArmor           :SetExtendedFilter(cB_Filters.fItemClass, "BankArmor")
    cB_Bags.bankGem             :SetExtendedFilter(cB_Filters.fItemClass, "BankGem")
    cB_Bags.bankConsumables     :SetExtendedFilter(cB_Filters.fItemClass, "BankConsumables")
    cB_Bags.bankArtifactPower   :SetExtendedFilter(cB_Filters.fItemClass, "BankArtifactPower")
    cB_Bags.bankBattlePet       :SetExtendedFilter(cB_Filters.fItemClass, "BankBattlePet")
    cB_Bags.bankQuest           :SetExtendedFilter(cB_Filters.fItemClass, "BankQuest")
    cB_Bags.bankTrade           :SetExtendedFilter(cB_Filters.fItemClass, "BankTradeGoods")
    cB_Bags.bankFishing         :SetExtendedFilter(cB_Filters.fItemClass, "BankFishing")
    cB_Bags.bankReagent         :SetMultipleFilters(true, cB_Filters.fBankReagent, cB_Filters.fHideEmpty)
    cB_Bags.bank                :SetMultipleFilters(true, cB_Filters.fBank, cB_Filters.fHideEmpty)
    if cBneav.BankCustomBags then
        for _,v in ipairs(cB_CustomBags) do cB_Bags["Bank"..v.name]:SetExtendedFilter(cB_Filters.fItemClass, "Bank"..v.name) end
    end

    -- Inventory Bags
    cB_Bags.key         = C:New("cBneav_Keyring")
    cB_Bags.bagItemSets = C:New("cBneav_ItemSets")
    cB_Bags.bagStuff    = C:New("cBneav_Stuff")

    for _,v in ipairs(cB_CustomBags) do
        if (v.prio > 0) then
            cB_Bags[v.name] = C:New(v.name, { isCustomBag = true } )
            v.active = true
            cB_filterEnabled[v.name] = true
        end
    end

    cB_Bags.bagJunk     = C:New("cBneav_Junk")
    cB_Bags.bagNew      = C:New("cBneav_NewItems")

    for _,v in ipairs(cB_CustomBags) do
        if (v.prio <= 0) then
            cB_Bags[v.name] = C:New(v.name, { isCustomBag = true } )
            v.active = true
            cB_filterEnabled[v.name] = true
        end
    end

    cB_Bags.bagFishing      = C:New("cBneav_Fishing")
    cB_Bags.armor           = C:New("cBneav_Armor")
    cB_Bags.gem             = C:New("cBneav_Gem")
    cB_Bags.quest           = C:New("cBneav_Quest")
    cB_Bags.consumables     = C:New("cBneav_Consumables")
    cB_Bags.artifactpower   = C:New("cBneav_ArtifactPower")
    cB_Bags.battlepet       = C:New("cBneav_BattlePet")
    cB_Bags.tradegoods      = C:New("cBneav_TradeGoods")
    cB_Bags.main            = C:New("cBneav_Bag")

    cB_Bags.key             :SetExtendedFilter(cB_Filters.fItemClass, "Keyring")
    cB_Bags.bagItemSets     :SetFilter(cB_Filters.fItemSets, true)
    cB_Bags.bagStuff        :SetExtendedFilter(cB_Filters.fItemClass, "Stuff")
    cB_Bags.bagJunk         :SetExtendedFilter(cB_Filters.fItemClass, "Junk")
    cB_Bags.bagFishing      :SetExtendedFilter(cB_Filters.fItemClass, "Fishing")
    cB_Bags.bagNew          :SetFilter(cB_Filters.fNewItems, true)
    cB_Bags.armor           :SetExtendedFilter(cB_Filters.fItemClass, "Armor")
    cB_Bags.gem             :SetExtendedFilter(cB_Filters.fItemClass, "Gem")
    cB_Bags.quest           :SetExtendedFilter(cB_Filters.fItemClass, "Quest")
    cB_Bags.consumables     :SetExtendedFilter(cB_Filters.fItemClass, "Consumables")
    cB_Bags.artifactpower   :SetExtendedFilter(cB_Filters.fItemClass, "ArtifactPower")
    cB_Bags.battlepet       :SetExtendedFilter(cB_Filters.fItemClass, "BattlePet")
    cB_Bags.tradegoods      :SetExtendedFilter(cB_Filters.fItemClass, "TradeGoods")
    cB_Bags.main            :SetMultipleFilters(true, cB_Filters.fBags, cB_Filters.fHideEmpty)

    for _,v in pairs(cB_CustomBags) do
        cB_Bags[v.name]:SetExtendedFilter(cB_Filters.fItemClass, v.name)
    end

    cB_Bags.main:SetPoint("BOTTOMRIGHT", -53, 107)
    cB_Bags.bank:SetPoint("TOPLEFT", 20, -20)
    cB_Bags.main:RegisterForDrag("LeftButton")
    cB_Bags.bank:RegisterForDrag("LeftButton")

    cbNeav:CreateAnchors()
    cbNeav:Init()
    cbNeav:ToggleBagPosButtons()
end

function cbNeav:CreateAnchors()
    -----------------------------------------------
    -- Store the anchoring order:
    -- read: "tar" is anchored to "src" in the direction denoted by "dir".
    -----------------------------------------------
    local function CreateAnchorInfo(src, tar, dir)
        tar.AnchorTo = src
        tar.AnchorDir = dir
        if src then
            if not src.AnchorTargets then src.AnchorTargets = {} end
            src.AnchorTargets[tar] = true
        end
    end

    -- neccessary if this function is used to update the anchors:
    for k,_ in pairs(cB_Bags) do
        if not ((k == "main") or (k == "bank")) then cB_Bags[k]:ClearAllPoints() end
        cB_Bags[k].AnchorTo = nil
        cB_Bags[k].AnchorDir = nil
        cB_Bags[k].AnchorTargets = nil
    end

    -- Main Anchors:
    CreateAnchorInfo(nil, cB_Bags.main, "Bottom")
    CreateAnchorInfo(nil, cB_Bags.bank, "Bottom")

    -- Bank Anchors:
    CreateAnchorInfo(cB_Bags.bank, cB_Bags.bankReagent, "Right")
    CreateAnchorInfo(cB_Bags.bankReagent, cB_Bags.bankTrade, "Bottom")


    CreateAnchorInfo(cB_Bags.bank, cB_Bags.bankArmor, "Bottom")
    CreateAnchorInfo(cB_Bags.bankArmor, cB_Bags.bankSets, "Bottom")
    CreateAnchorInfo(cB_Bags.bankSets, cB_Bags.bankConsumables, "Bottom")
    CreateAnchorInfo(cB_Bags.bankConsumables, cB_Bags.bankFishing, "Bottom")
    CreateAnchorInfo(cB_Bags.bankFishing, cB_Bags.bankQuest, "Bottom")
    CreateAnchorInfo(cB_Bags.bankQuest, cB_Bags.bankArtifactPower, "Bottom")
    CreateAnchorInfo(cB_Bags.bankArtifactPower, cB_Bags.bankBattlePet, "Bottom")

    -- Bank Custom Container Anchors:
    if cBneav.BankCustomBags then
        local ref = { [0] = 0, [1] = 0 }
        for _,v in ipairs(cB_CustomBags) do
            if v.active then
                --local c = v.col
                local c = 1
                if ref[c] == 0 then ref[c] = (c == 0) and cB_Bags.bankBattlePet or cB_Bags.bankTrade end
                CreateAnchorInfo(ref[c], cB_Bags["Bank"..v.name], "Bottom")
                ref[c] = cB_Bags["Bank"..v.name]
            end
        end
    end

    -- Bag Anchors:
    CreateAnchorInfo(cB_Bags.main,          cB_Bags.key,            "Bottom")

    CreateAnchorInfo(cB_Bags.main,          cB_Bags.bagItemSets,    "Left")
    CreateAnchorInfo(cB_Bags.bagItemSets,   cB_Bags.armor,          "Top")
    CreateAnchorInfo(cB_Bags.armor,         cB_Bags.gem,            "Top")
    CreateAnchorInfo(cB_Bags.gem,           cB_Bags.artifactpower,  "Top")
    CreateAnchorInfo(cB_Bags.artifactpower, cB_Bags.battlepet,      "Top")
    CreateAnchorInfo(cB_Bags.battlepet,     cB_Bags.bagFishing,     "Top")
    CreateAnchorInfo(cB_Bags.bagFishing,    cB_Bags.bagStuff,       "Top")

    CreateAnchorInfo(cB_Bags.main,          cB_Bags.tradegoods,     "Top")
    CreateAnchorInfo(cB_Bags.tradegoods,    cB_Bags.consumables,    "Top")
    CreateAnchorInfo(cB_Bags.consumables,   cB_Bags.quest,          "Top")
    CreateAnchorInfo(cB_Bags.quest,         cB_Bags.bagJunk,        "Top")
    CreateAnchorInfo(cB_Bags.bagJunk,       cB_Bags.bagNew,         "Top")

    -- Custom Container Anchors:
    local ref = { [0] = 0, [1] = 0 }
    for _,v in ipairs(cB_CustomBags) do
        if v.active then
            local c = v.col
            if ref[c] == 0 then ref[c] = (c == 0) and cB_Bags.bagStuff or cB_Bags.bagNew end
            CreateAnchorInfo(ref[c], cB_Bags[v.name], "Top")
            ref[c] = cB_Bags[v.name]
        end
    end

    -- Finally update all anchors:
    for _,v in pairs(cB_Bags) do cbNeav:UpdateAnchors(v) end
end

function cbNeav:UpdateAnchors(self)
    if not self.AnchorTargets then return end
    for v,_ in pairs(self.AnchorTargets) do
        local t, u = v.AnchorTo, v.AnchorDir
        if t then
            local h = cB_BagHidden[t.name]
            v:ClearAllPoints()
            if  not h       and u == "Top"      then v:SetPoint("BOTTOM", t, "TOP", 0, 9)
            elseif  h       and u == "Top"      then v:SetPoint("BOTTOM", t, "BOTTOM")
            elseif  not h   and u == "Bottom"   then v:SetPoint("TOP", t, "BOTTOM", 0, -9)
            elseif  h       and u == "Bottom"   then v:SetPoint("TOP", t, "TOP")
            elseif  u == "Left"                 then v:SetPoint("BOTTOMRIGHT", t, "BOTTOMLEFT", -9, 0)
            elseif  u == "Right"                then v:SetPoint("TOPLEFT", t, "TOPRIGHT", 9, 0) end
        end
    end
end

function cbNeav:OnOpen()
    cB_Bags.main:Show()
    cbNeav:ShowBags(cB_Bags.armor, cB_Bags.bagNew, cB_Bags.bagItemSets, cB_Bags.gem, cB_Bags.quest, cB_Bags.consumables, cB_Bags.artifactpower, cB_Bags.battlepet,
                      cB_Bags.tradegoods, cB_Bags.bagStuff, cB_Bags.bagJunk, cB_Bags.bagFishing)
    for _,v in ipairs(cB_CustomBags) do if v.active then cbNeav:ShowBags(cB_Bags[v.name]) end end
end

function cbNeav:OnClose()
    cbNeav:HideBags(cB_Bags.main, cB_Bags.armor, cB_Bags.bagNew, cB_Bags.bagItemSets, cB_Bags.gem, cB_Bags.quest, cB_Bags.consumables, cB_Bags.artifactpower, cB_Bags.battlepet,
                      cB_Bags.tradegoods, cB_Bags.bagStuff, cB_Bags.bagJunk, cB_Bags.bagFishing)
    for _,v in ipairs(cB_CustomBags) do if v.active then cbNeav:HideBags(cB_Bags[v.name]) end end
end

function cbNeav:OnBankOpened()
    cbNeav:UpdateBags()
    cB_Bags.bank:Show()
    cbNeav:ShowBags(cB_Bags.bankSets, cB_Bags.bankReagent, cB_Bags.bankArmor, cB_Bags.bankGem, cB_Bags.bankQuest, cB_Bags.bankTrade, cB_Bags.bankConsumables, cB_Bags.bankArtifactPower, cB_Bags.bankBattlePet, cB_Bags.bankFishing)
    if cBneav.BankCustomBags then
        for _,v in ipairs(cB_CustomBags) do if v.active then cbNeav:ShowBags(cB_Bags["Bank"..v.name]) end end
    end
end

function cbNeav:OnBankClosed()
    cbNeav:HideBags(cB_Bags.bank, cB_Bags.bankSets, cB_Bags.bankReagent, cB_Bags.bankArmor, cB_Bags.bankGem, cB_Bags.bankQuest, cB_Bags.bankTrade, cB_Bags.bankConsumables, cB_Bags.bankArtifactPower, cB_Bags.bankBattlePet, cB_Bags.bankFishing)
    if cBneav.BankCustomBags then
        for _,v in ipairs(cB_CustomBags) do if v.active then cbNeav:HideBags(cB_Bags["Bank"..v.name]) end end
    end
end

function cbNeav:ToggleBagPosButtons()
    for _,v in ipairs(cB_CustomBags) do
        if v.active then
            local b = cB_Bags[v.name]

            if cBneav.BagPos then
                b.rightBtn:Hide()
                b.leftBtn:Hide()
                b.downBtn:Hide()
                b.upBtn:Hide()
            else
                b.rightBtn:Show()
                b.leftBtn:Show()
                b.downBtn:Show()
                b.upBtn:Show()
            end
        end
    end
    cBneav.BagPos = not cBneav.BagPos
end

local SetFrameMovable = function(f, v)
    f:SetMovable(true)
    f:SetUserPlaced(true)
    f:RegisterForClicks("LeftButton", "RightButton")
    if v then
        f:SetScript("OnMouseDown", function()
            f:ClearAllPoints()
            f:StartMoving()
        end)
        f:SetScript("OnMouseUp",  f.StopMovingOrSizing)
    else
        f:SetScript("OnMouseDown", nil)
        f:SetScript("OnMouseUp", nil)
    end
end

local DropDownInitialized
function cbNeav:CatDropDownInit()
    if DropDownInitialized then return end
    DropDownInitialized = true
    local info = {}

    local function AddInfoItem(type)
        local caption = "cBneav_"..type
        local t = L.bagCaptions[caption] or L[type]
        info.text = t and t or type
        info.value = type

        if (type == "-------------") or (type == CANCEL) then
            info.func = nil
        else
            info.func = function(self) cbNeav:CatDropDownOnClick(self, type) end
        end

        cbNeavCatDropDown:AddButton(info.text, type, info.func)
    end

    AddInfoItem("MarkAsNew")
    AddInfoItem("MarkAsKnown")
    AddInfoItem("-------------")
    AddInfoItem("Armor")
    AddInfoItem("BattlePet")
    AddInfoItem("Consumables")
    AddInfoItem("Quest")
    AddInfoItem("TradeGoods")
    AddInfoItem("Gem")
    if ns.options.filterArtifactPower then AddInfoItem("ArtifactPower") end
    AddInfoItem("Stuff")
    AddInfoItem("Fishing")
    AddInfoItem("Junk")
    AddInfoItem("Bag")
    for _,v in ipairs(cB_CustomBags) do
        if v.active then AddInfoItem(v.name) end
    end
    AddInfoItem("-------------")
    AddInfoItem(CANCEL)

    hooksecurefunc(NeavcBneav_Bag, "Hide", function() cbNeavCatDropDown:Hide() end)
end

function cbNeav:CatDropDownOnClick(self, type)
    local value = self.value
    local itemName = cbNeavCatDropDown.itemName
    local itemID = cbNeavCatDropDown.itemID

    if (type == "MarkAsNew") then
        cB_KnownItems[itemID] = nil
    elseif (type == "MarkAsKnown") then
        cB_KnownItems[itemID] = GetItemCount(itemID)
    else
        cBneav_CatInfo[itemID] = value
        if (itemID ~= nil) then cB_ItemClass[itemID] = nil end
    end
    cbNeav:UpdateBags()
end

local function StatusMsg(str1, str2, data, name, short)
    local R,G,t = "|cFFFF0000", "|cFF00FF00", ""
    if (data ~= nil) then t = data and G..(short and "on|r" or "enabled|r") or R..(short and "off|r" or "disabled|r") end
    t = (name and "|cFFFFFF00cargBags_Neav:|r " or "")..str1..t..str2
    ChatFrame1:AddMessage(t)
end

local function StatusMsgVal(str1, str2, data, name)
    local G,t = "|cFF00FF00", ""
    if (data ~= nil) then t = G..data.."|r" end
    t = (name and "|cFFFFFF00cargBags_Neav:|r " or "")..str1..t..str2
    ChatFrame1:AddMessage(t)
end

local function HandleSlash(str)
    local str, str2 = strsplit(" ", str, 2)
    local updateBags
    local bagExists

    if ((str == "addbag") or (str == "delbag") or (str == "movebag") or (str == "bagprio") or (str == "orderup") or (str == "orderdn")) and (not str2) then
        StatusMsg("You have to specify a name, e.g. /cbneav "..str.." TestBag.", "", nil, true, false)
        return false
    end

    local numBags, idx = 0, -1
    for i,v in ipairs(cB_CustomBags) do
        numBags = numBags + 1
        if v.name == str2 then idx = i end
    end

    if ((str == "delbag") or (str == "movebag") or (str == "bagprio") or (str == "orderup") or (str == "orderdn")) and (idx == -1) then
        StatusMsg("There is no custom container named |cFF00FF00"..str2, "|r.", nil, true, false)
        return false
    end

    if str == "new" then
        cBneavCfg.NewItems = not cBneavCfg.NewItems
        StatusMsg("The \"New Items\" filter is now ", ".", cBneavCfg.NewItems, true, false)
        updateBags = true
    elseif str == "trade" then
        cBneavCfg.TradeGoods = not cBneavCfg.TradeGoods
        cB_filterEnabled["TradeGoods"] = cBneavCfg.TradeGoods
        StatusMsg("The \"Trade Goods\" filter is now ", ".", cBneavCfg.TradeGoods, true, false)
        updateBags = true
    elseif str == "armor" then
        cBneavCfg.Armor = not cBneavCfg.Armor
        cB_filterEnabled["Armor"] = cBneavCfg.Armor
        StatusMsg("The \"Armor and Weapons\" filter is now ", ".", cBneavCfg.Armor, true, false)
    elseif str == "gem" then
        cBneavCfg.Gem = not cBneavCfg.Gem
        cB_filterEnabled["Gem"] = cBneavCfg.Gem
        StatusMsg("The \"Gem\" filter is now ", ".", cBneavCfg.Gem, true, false)
        updateBags = true
    elseif str == "junk" then
        cBneavCfg.Junk = not cBneavCfg.Junk
        cB_filterEnabled["Junk"] = cBneavCfg.Junk
        StatusMsg("The \"Junk\" filter is now ", ".", cBneavCfg.Junk, true, false)
        updateBags = true
    elseif str == "sets" then
        cBneavCfg.ItemSets = not cBneavCfg.ItemSets
        cB_filterEnabled["ItemSets"] = cBneavCfg.ItemSets
        StatusMsg("The \"ItemSets\" filters are now ", ".", cBneavCfg.ItemSets, true, false)
        updateBags = true
    elseif str == "consumables" then
        cBneavCfg.Consumables = not cBneavCfg.Consumables
        cB_filterEnabled["Consumables"] = cBneavCfg.Consumables
        StatusMsg("The \"Consumables\" filters are now ", ".", cBneavCfg.Consumables, true, false)
        updateBags = true
    elseif str == "quest" then
        cBneavCfg.Quest = not cBneavCfg.Quest
        cB_filterEnabled["Quest"] = cBneavCfg.Quest
        StatusMsg("The \"Quest\" filters are now ", ".", cBneavCfg.Quest, true, false)
        updateBags = true
    elseif str == "fishing" then
        cBneavCfg.Fishing = not cBneavCfg.Fishing
        cB_filterEnabled["Fishing"] = cBneavCfg.Fishing
        StatusMsg("The \"Fishing\" filters are now ", ".", cBneavCfg.Fishing, true, false)
        updateBags = true
    elseif str == "bankbg" then
        cBneavCfg.BankBlack = not cBneavCfg.BankBlack
        StatusMsg("Black background color for the bank is now ", ". Reload your UI for this change to take effect!", cBneavCfg.BankBlack, true, false)
    elseif str == "bankfilter" then
        cBneavCfg.FilterBank = not cBneavCfg.FilterBank
        StatusMsg("Bank filtering is now ", ". Reload your UI for this change to take effect!", cBneavCfg.FilterBank, true, false)
    elseif str == "empty" then
        cBneavCfg.CompressEmpty = not cBneavCfg.CompressEmpty
        if cBneavCfg.CompressEmpty then
            cB_Bags.bank.DropTarget:Show()
            cB_Bags.main.DropTarget:Show()
            cB_Bags.main.EmptySlotCounter:Show()
            cB_Bags.bank.EmptySlotCounter:Show()
        else
            cB_Bags.bank.DropTarget:Hide()
            cB_Bags.main.DropTarget:Hide()
            cB_Bags.main.EmptySlotCounter:Hide()
            cB_Bags.bank.EmptySlotCounter:Hide()
        end
        StatusMsg("Empty bagspace compression is now ", ".", cBneavCfg.CompressEmpty, true, false)
        updateBags = true
    elseif str == "unlock" then
        cBneavCfg.Unlocked = not cBneavCfg.Unlocked
        SetFrameMovable(cB_Bags.main, cBneavCfg.Unlocked)
        SetFrameMovable(cB_Bags.bank, cBneavCfg.Unlocked)
        StatusMsg("Movable bags are now ", ".", cBneavCfg.Unlocked, true, false)
        updateBags = true
    elseif str == "sortbags" then
        cBneavCfg.SortBags = not cBneavCfg.SortBags
        StatusMsg("Auto sorting bags is now ", ". Reload your UI for this change to take effect!", cBneavCfg.SortBags, true, false)
    elseif str == "sortbank" then
        cBneavCfg.SortBank = not cBneavCfg.SortBank
        StatusMsg("Auto sorting bank is now ", ". Reload your UI for this change to take effect!", cBneavCfg.SortBank, true, false)

    elseif str == "scale" then
        local t = tonumber(str2)
        if t then
            cBneavCfg.scale = t
            for _,v in pairs(cB_Bags) do v:SetScale(cBneavCfg.scale) end
            StatusMsgVal("Overall scale has been set to ", ".", cBneavCfg.scale, true)
        else
            StatusMsg("You have to specify a value, e.g. /cbneav scale 0.8.", "", nil, true, false)
        end

    elseif str == "addbag" then
        for k,v in pairs(cB_CustomBags) do
            if v.name==str2 then
                bagExists = true
            end
        end
        if not bagExists then
            local i = numBags + 1
            cB_CustomBags[i] = { name = str2, col = 0, prio = 1, active = false }
            StatusMsg("The new custom container has been created. Reload your UI for this change to take effect!", "", nil, true, false)
        else
            StatusMsg("A custom container with this name already exists.", "", nil, true, false)
        end

    elseif str == "delbag" then
        table.remove(cB_CustomBags, idx)
        for k,v in pairs(cBneav_CatInfo) do
            if v==str2 then
                cBneav_CatInfo[k] = nil
            end
        end
        StatusMsg("The specified custom container has been removed. Reload your UI for this change to take effect!", "", nil, true, false)

    elseif str == "listbags" then
        if numBags == 0 then
            StatusMsgVal("There are ", " custom containers.", 0, true, false)
        else
            StatusMsgVal("There are ", " custom containers:", numBags, true, false)
            for i,v in ipairs(cB_CustomBags) do
                StatusMsg(i..". "..v.name.." (|cFF00FF00"..((v.col == 0) and "right" or "left").."|r column, |cFF00FF00"..((v.prio == 1) and "high" or "low").."|r priority)", "", nil, true, false)
            end
        end

    elseif str == "bagpos" then
        cbNeav:ToggleBagPosButtons()
        StatusMsg("Custom container movers are now ", ".", cBneav.BagPos, true, false)

    -- elseif str == "bagprio" then
        -- local tprio = (cB_CustomBags[idx].prio + 1) % 2
        -- cB_CustomBags[idx].prio = tprio
        -- StatusMsg("The priority of the specified custom container has been set to |cFF00FF00"..((tprio == 1) and "high" or "low").."|r. Reload your UI for this change to take effect!", "", nil, true, false)

    elseif str == "bankbags" then
        cBneavCfg.BankCustomBags = not cBneavCfg.BankCustomBags
        StatusMsg("Display of custom containers in the bank is now ", ". Reload your UI for this change to take effect!", cBneavCfg.BankCustomBags, true, false)

    else
        ChatFrame1:AddMessage("|cFFFFFF00cargBags_Neav:|r")
        StatusMsg("(", ") |cFFFFFF00unlock|r - Toggle unlocked status.", cBneavCfg.Unlocked, false, true)
        StatusMsg("(", ") |cFFFFFF00new|r - Toggle the \"New Items\" filter.", cBneavCfg.NewItems, false, true)
        StatusMsg("(", ") |cFFFFFF00trade|r - Toggle the \"Trade Goods\" filter .", cBneavCfg.TradeGoods, false, true)
        StatusMsg("(", ") |cFFFFFF00armor|r - Toggle the \"Armor and Weapons\" filter .", cBneavCfg.Armor, false, true)
        StatusMsg("(", ") |cFFFFFF00gem|r - Toggle the \"Gem\" filter .", cBneavCfg.Gem, false, true)
        StatusMsg("(", ") |cFFFFFF00junk|r - Toggle the \"Junk\" filter.", cBneavCfg.Junk, false, true)
        StatusMsg("(", ") |cFFFFFF00sets|r - Toggle the \"ItemSets\" filters.", cBneavCfg.ItemSets, false, true)
        StatusMsg("(", ") |cFFFFFF00consumables|r - Toggle the \"Consumables\" filters.", cBneavCfg.Consumables, false, true)
        StatusMsg("(", ") |cFFFFFF00quest|r - Toggle the \"Quest\" filters.", cBneavCfg.Quest, false, true)
        StatusMsg("(", ") |cFFFFFF00fishing|r - Toggle the \"Fishing\" filters.", cBneavCfg.Fishing, false, true)
        StatusMsg("(", ") |cFFFFFF00bankbg|r - Toggle black bank background color.", cBneavCfg.BankBlack, false, true)
        StatusMsg("(", ") |cFFFFFF00bankfilter|r - Toggle bank filtering.", cBneavCfg.FilterBank, false, true)
        StatusMsg("(", ") |cFFFFFF00empty|r - Toggle empty bagspace compression.", cBneavCfg.CompressEmpty, false, true)
        StatusMsg("(", ") |cFFFFFF00sortbags|r - Toggle auto sorting the bags.", cBneavCfg.SortBags, false, true)
        StatusMsg("(", ") |cFFFFFF00sortbank|r - Toggle auto sorting the bank.", cBneavCfg.SortBank, false, true)
        StatusMsgVal("(", ") |cFFFFFF00scale|r [number] - Set the overall scale.", cBneavCfg.scale, false)
        StatusMsg("", " |cFFFFFF00addbag|r [name] - Add a custom container.")
        StatusMsg("", " |cFFFFFF00delbag|r [name] - Remove a custom container.")
        StatusMsg("", " |cFFFFFF00listbags|r - List all custom containers.")
        StatusMsg("", " |cFFFFFF00bagpos|r - Toggle buttons to move custom containers (up, down, left, right).")
        -- StatusMsg("", " |cFFFFFF00bagprio|r [name] - Changes the filter priority of a custom container. High priority prevents items from being classified as junk or new, low priority doesn't.")
        StatusMsg("(", ") |cFFFFFF00bankbags|r - Show custom containers in the bank too.", cBneavCfg.BankCustomBags, false, true)
    end
    if updateBags then
        cbNeav:UpdateBags()
    end
end

SLASH_CBNEAV1 = "/cbneav"
SlashCmdList.CBNEAV = HandleSlash

local buttonCollector = {}
local Event =  CreateFrame("Frame", nil)
Event:RegisterEvent("PLAYER_ENTERING_WORLD")
Event:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        for bagID = -3, 11 do
            local slots = GetContainerNumSlots(bagID)
            for slotID=1,slots do
                local button = cbNeav.buttonClass:New(bagID, slotID)
                buttonCollector[#buttonCollector+1] = button
                cbNeav:SetButton(bagID, slotID, nil)
            end
        end
        for i,button in pairs(buttonCollector) do
            if button.container then
                button.container:RemoveButton(button)
            end
            button:Free()
        end
        cbNeav:UpdateBags()

        if IsReagentBankUnlocked() then
            NeavcBneav_Bank.reagentBtn:Show()
        else
            NeavcBneav_Bank.reagentBtn:Hide()
            local buyReagent = CreateFrame("Button", nil, NeavcBneav_BankReagent, "UIPanelButtonTemplate")
            buyReagent:SetText(BANKSLOTPURCHASE)
            buyReagent:SetWidth(buyReagent:GetTextWidth() + 20)
            buyReagent:SetPoint("CENTER", NeavcBneav_BankReagent, 0, 0)
            buyReagent:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(REAGENT_BANK_HELP, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            buyReagent:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            buyReagent:SetScript("OnClick", function()
                StaticPopup_Show("CONFIRM_BUY_REAGENTBANK_TAB")
            end)
            buyReagent:SetScript("OnEvent", function(...)
                buyReagent:UnregisterEvent("REAGENTBANK_PURCHASED")
                NeavcBneav_Bank.reagentBtn:Show()
                buyReagent:Hide()
            end)
            if Aurora then
                local F = Aurora[1]
                F.Reskin(buyReagent)
            end
            buyReagent:RegisterEvent("REAGENTBANK_PURCHASED")
        end

        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

function cargBags_Neav:ResetItemClass()
    for k,v in pairs(cB_ItemClass) do
        if v == "NoClass" then
            cB_ItemClass[k] = nil
        end
    end
    cbNeav:UpdateBags()
end
