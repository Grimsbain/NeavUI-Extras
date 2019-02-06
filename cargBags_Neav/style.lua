local addon, ns = ...
local cargBags = ns.cargBags

local _
local L = cBneavL

local itemSlotSize = ns.options.itemSlotSize
local mediaPath = [[Interface\AddOns\cargBags_Neav\media\]]
local Textures = {
    Background =    mediaPath .. "texture",
    Search =        mediaPath .. "Search",
    BagToggle =     mediaPath .. "BagToggle",
    ResetNew =      mediaPath .. "ResetNew",
    Restack =       mediaPath .. "Restack",
    Config =        mediaPath .. "Config",
    SellJunk =      mediaPath .. "SellJunk",
    Deposit =       mediaPath .. "Deposit",
    TooltipIcon =   mediaPath .. "TooltipIcon",
    Up =            mediaPath .. "Up",
    Down =          mediaPath .. "Down",
    Left =          mediaPath .. "Left",
    Right =         mediaPath .. "Right",
    Border =        mediaPath .. "fer4"
}

--[[!
    Init container.
]]
local cbNeav = cargBags:GetImplementation("Neav")
local MyContainer = cbNeav:GetContainerClass()
local BagFrames, BankFrames =  {}, {}

--[[!
    Gets the number of free slots from a table of bag ids.
    @param bagIDs <table>
    @return free <number>
]]

local function GetNumFreeSlots(bagIDs)
    local free = 0

    for i = 1, #bagIDs do
        local bagID = bagIDs[i]
        free = free + GetContainerNumFreeSlots(bagID)
    end

    return free
end

--[[!
    Gets the first free slot.
    @param bagIDs <table>
    @return bagID <number>, slotID <number>
]]

local function GetFirstFreeSlot(bagIDs)
    for i = 1, #bagIDs do
        local bagID = bagIDs[i]
        local freeSlots = GetContainerNumFreeSlots(bagID)

        for slotID = 1, GetContainerNumSlots(bagID) do
            local link = GetContainerItemLink(bagID, slotID)
            if ( not link ) then
                return bagID, slotID
            end
        end
    end

    return false
end

--[[!
    Sorts a list of items based off of item id, quality, and stack size.
    Has handeling for empty slots and nil values.
]]

local function ItemSort(this, that)
    if ( not this or not that ) then
        return this and true or false
    end

    -- Empty slots last.
    -- Higher quality first.
    -- Group identical item ids.
    -- Full/larger stacks first.

    if ( this.id == -1 or that.id == -1 ) then
        return this.id > that.id
    elseif ( this.quality ~= that.quality ) then
        if ( this.quality and that.quality ) then
            return this.quality > that.quality
        elseif ( not this.quality or not that.quality ) then
            return this.quality and true or false
        else
            return false
        end
    elseif ( this.id ~= that.id ) then
        return this.id > that.id
    else
        return this.count > that.count
    end
end

local QuickSort = function(items) table.sort(items, ItemSort) end

--[[!
    Auto sells grey junk items to the vendor and prints the profit made.
    Disabled for players lower than level 5.
]]

local function SellJunk()
    if ( not cBneavCfg.SellJunk or UnitLevel("player") < 5 ) then
        return
    end

    local profit, item = 0

    for bagID = 0, NUM_BAG_SLOTS do
        for slotID = 1, GetContainerNumSlots(bagID) do
            item = cbNeav:GetItemInfo(bagID, slotID)
            if ( item ) then
                if ( item.quality == 0 and item.sellPrice ~= 0 ) then
                    profit = profit + (item.sellPrice * item.count)
                    UseContainerItem(bagID, slotID)
                end
            end
        end
    end

    if ( profit > 0 ) then
        print(string.format("%s %s", L.VendorTrash, GetMoneyString(profit)))
    end
end

local eventWatcher = CreateFrame("Frame")
eventWatcher:RegisterEvent("MERCHANT_SHOW")
eventWatcher:SetScript("OnEvent", function(self, event, ...)
    if ( event == "MERCHANT_SHOW" ) then
        SellJunk()
    end
end)

--[[!
    Restack items.
]]

local function RestackItems(self)
    if ( self.isBank ) then
        SortBankBags()
        SortReagentBankBags()
    elseif ( self.isBag ) then
        SortBags()
    end
end

--[[!
    Reset new items.
]]

local function ResetNewItems(self)
    cB_KnownItems = cB_KnownItems or {}

    if ( not cBneav.clean ) then
        for item, itemCount in next, cB_KnownItems do
            if ( type(item) == "string" ) then
                cB_KnownItems[item] = nil
            end
        end
        cBneav.clean = true
    end

    for bagID = 0, NUM_BAG_SLOTS do
        local bagSize = GetContainerNumSlots(bagID)

        if ( bagSize > 0 ) then
            for slotID = 1, bagSize do
                local item = cbNeav:GetItemInfo(bagID, slotID)

                if ( item.id ) then
                    if ( cB_KnownItems[item.id] ) then
                        cB_KnownItems[item.id] = cB_KnownItems[item.id] + (item.stackCount and item.stackCount or 0)
                    else
                        cB_KnownItems[item.id] = item.stackCount and item.stackCount or 0
                    end
                end
            end
        end
    end
    cbNeav:UpdateBags()
end

function cbNeavResetNew()
    ResetNewItems()
end

--[[!
    Update container dimensions.
]]

local function UpdateDimensions(self)
    local height = 0

    -- Bag button space.
    if ( self.BagBar and self.BagBar:IsShown() ) then
        height = height + 40
    end

    -- Additional info display space.
    if ( self.Space ) then
        height = height + 16
    end

    -- Bag Frame Toggle
    if ( self.bagToggle ) then
        local fontHeight = ns.options.fonts.standard[2] + 8
        local extraHeight = self.isBag and fontHeight or 0
        height = height + 24 + extraHeight
    end

    -- Space for captions.
    if ( self.Caption ) then
        local fontHeight = ns.options.fonts.standard[2] + 12
        height = height + fontHeight
    end

    self:SetSize(self.ContainerWidth, self.ContainerHeight + height)
end

local function SetFrameMovable(self)
    self:SetMovable(true)
    self:SetUserPlaced(true)
    self:RegisterForClicks("LeftButton", "RightButton")

    self:SetScript("OnDragStart", function(self)
        if ( IsShiftKeyDown() and IsAltKeyDown() and cBneavCfg.Unlocked ) then
            self:StartMoving()
        end
    end)

    self:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
end

local function IconButton_OnEnter(self)
    local r, g, b = GetClassColor(select(2, UnitClass("player")))
    self.icon:SetVertexColor(r, g, b)

    if ( self.tooltipText ) then
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end
end

local function IconButton_OnLeave(self)
    if ( self.tag == "SellJunk" ) then
        if ( cBneavCfg.SellJunk ) then
            self.icon:SetVertexColor(0.8, 0.8, 0.8)
        else
            self.icon:SetVertexColor(0.4, 0.4, 0.4)
        end
    else
        self.icon:SetVertexColor(0.8, 0.8, 0.8)
    end

    if ( GameTooltip:GetOwner() == self ) then
        GameTooltip:Hide()
    end
end

local function CreateMoverButton(parent, texture, tag)
    local button = CreateFrame("Button", "$parent"..tag, parent)
    button:SetWidth(17)
    button:SetHeight(17)

    button.icon = button:CreateTexture("$parentIcon", "ARTWORK")
    button.icon:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -1)
    button.icon:SetWidth(16)
    button.icon:SetHeight(16)
    button.icon:SetTexture(texture)
    button.icon:SetVertexColor(0.8, 0.8, 0.8)

    button.tag = tag
    button:SetScript("OnEnter", function() IconButton_OnEnter(button) end)
    button:SetScript("OnLeave", function() IconButton_OnLeave(button) end)

    return button
end

local function CreateIconButton(name, parent, texture, point, hint, isBag)
    local button = CreateFrame("Button", name.."Button", parent)
    button:SetWidth(17)
    button:SetHeight(17)

    button.tag = name
    button.tooltipText = hint
    button:SetScript("OnEnter", function() IconButton_OnEnter(button) end)
    button:SetScript("OnLeave", function() IconButton_OnLeave(button) end)

    button.icon = button:CreateTexture("$parentIcon", "ARTWORK")
    button.icon:SetPoint(point, button, point, point == "BOTTOMLEFT" and 2 or -2, 2)
    button.icon:SetWidth(16)
    button.icon:SetHeight(16)
    button.icon:SetTexture(texture)

    if ( texture == [[Interface\ContainerFrame\Bags]] ) then
        button.icon:SetTexCoord(0.12109375, 0.23046875, 0.7265625, 0.9296875)
    end

    if ( name == "SellJunk" ) then
        if ( cBneavCfg.SellJunk ) then
            button.icon:SetVertexColor(0.8, 0.8, 0.8)
        else
            button.icon:SetVertexColor(0.4, 0.4, 0.4)
        end
    else
        button.icon:SetVertexColor(0.8, 0.8, 0.8)
    end

    return button
end



function MyContainer:OnCreate(name, settings)
    self:EnableMouse(true)
    self:SetFrameStrata("HIGH")
    tinsert(UISpecialFrames, self:GetName()) -- Close on "Esc"

    self.settings = settings or {}
    self.name = name
    self.isBag = name == "cBneav_Bag"
    self.isBank = name == "cBneav_Bank"
    self.isReagentBank = name == "cBneav_BankReagent"
    self.isBankBags = name:match("Bank")

    table.insert((self.isBankBags and BankFrames or BagFrames), self)

    if ( self.isBag or self.isBank ) then
        SetFrameMovable(self)
    end

    if ( self.isBank or self.isBankBags or self.isReagentBank ) then
        self.Columns = 14
    else
        self.Columns = 8
    end

    self.ContainerWidth = (itemSlotSize + 2) * self.Columns + 2
    self.ContainerHeight = 0
    self.UpdateDimensions = UpdateDimensions
    self:UpdateDimensions()

    -- The frame background
    local backgroundColor = ns.options.colors.background
    local background = CreateFrame("Frame", nil, self)
    background:SetFrameStrata("HIGH")
    background:SetFrameLevel(1)
    background:SetPoint("TOPRIGHT", 4, 4)
    background:SetPoint("BOTTOMLEFT", -4, -4)

    background:SetBackdrop{
        bgFile = Textures.Background,
        edgeFile = Textures.Background,
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    }
    background:SetBackdropColor(unpack(backgroundColor))
    background:SetBackdropBorderColor(0, 0, 0, 1)

    if ( IsAddOnLoaded("!Beautycase") ) then
        background:CreateBeautyBorder(11)
        background:SetBeautyBorderColor(0.40, 0.40, 0.40)
        background:SetBeautyBorderPadding(1)
    end

    -- Bag Caption & Close Button
    local title = L.bagCaptions[self.name] or (self.isBankBags and strsub(self.name, 5)) or self.name
    local caption = background:CreateFontString("$parentCaption", "OVERLAY")
    caption:SetFont(unpack(ns.options.fonts.standard))
    caption:SetText(title)
    caption:SetPoint("TOPLEFT", 7.5, -7.5)
    self.Caption = caption

    if ( self.isBag or self.isBank ) then
        local close = CreateFrame("Button", "$parentClose", self, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", 8, 8)
        close:SetDisabledTexture(mediaPath.."CloseButton\\UI-Panel-MinimizeButton-Disabled")
        close:SetNormalTexture(mediaPath.."CloseButton\\UI-Panel-MinimizeButton-Up")
        close:SetPushedTexture(mediaPath.."CloseButton\\UI-Panel-MinimizeButton-Down")
        close:SetHighlightTexture(mediaPath.."CloseButton\\UI-Panel-MinimizeButton-Highlight", "ADD")
        close:SetScript("OnClick", function(self)
            if ( cbNeav:AtBank() ) then
                CloseBankFrame()
            else
                CloseAllBags()
            end
        end)
    end

    -- Bag Location Movers
    if ( self.settings.isCustomBag ) then
        local function MoveLeftRight(direction)
            local index = -1

            for i=1, #cB_CustomBags do
                local bag = cB_CustomBags[i]
                if ( bag.name == name ) then
                    index = i
                end
            end

            if ( index == -1 ) then
                return
            end

            local newColumn = (cB_CustomBags[index].col + ((direction == "left") and 1 or -1)) % 2
            cB_CustomBags[index].col = newColumn
            cbNeav:CreateAnchors()
        end

        local function MoveUpDown(direction)
            local index = -1

            for i=1, #cB_CustomBags do
                local bag = cB_CustomBags[i]
                if ( bag.name == name ) then
                    index = i
                end
            end

            if ( index == -1 ) then
                return
            end

            local position = index
            local delta = direction == "up" and 1 or -1

            repeat
                position = position + delta
            until ( not cB_CustomBags[position] or cB_CustomBags[position].col == cB_CustomBags[index].col )

            if ( cB_CustomBags[position] ~= nil ) then
                local element = cB_CustomBags[index]
                cB_CustomBags[index] = cB_CustomBags[position]
                cB_CustomBags[position] = element
                cbNeav:CreateAnchors()
            end
        end

        local RightButton = CreateMoverButton(self, Textures.Right, "Right")
        RightButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
        RightButton:SetScript("OnClick", function() MoveLeftRight("right") end)
        self.RightButton = RightButton

        local LeftButton = CreateMoverButton(self, Textures.Left, "Left")
        LeftButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -17, 0)
        LeftButton:SetScript("OnClick", function() MoveLeftRight("left") end)
        self.LeftButton = LeftButton

        local DownButton = CreateMoverButton(self, Textures.Down, "Down")
        DownButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -34, 0)
        DownButton:SetScript("OnClick", function() MoveUpDown("down") end)
        self.DownButton = DownButton

        local UpButton = CreateMoverButton(self, Textures.Up, "Up")
        UpButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -51, 0)
        UpButton:SetScript("OnClick", function() MoveUpDown("up") end)
        self.UpButton = UpButton
    end

    if ( self.isBag or self.isBank ) then
        -- Bag bar for changing bags
        local prevButton = nil
        local bagType = self.isBag and "bags" or "bank"
        local bagStyle = self.isBag and "backpack+bags" or "bank"
        local totalBags = self.isBag and NUM_BAG_SLOTS or 7

        local bagButtons = self:SpawnPlugin("BagBar", bagStyle)
        bagButtons:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -2, 25)
        bagButtons:SetSize(bagButtons:LayoutButtons("grid", totalBags))
        bagButtons.highlightFunction = function(button, match) button:SetAlpha(match and 1 or 0.1) end
        bagButtons.isGlobal = true
        bagButtons:Hide()
        self.BagBar = bagButtons

        -- Bag Buttons Toggle
        self.bagToggle = CreateIconButton("Bags", self, Textures.BagToggle, "BOTTOMRIGHT", "Toggle Bags", self.isBag)
        self.bagToggle:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
        prevButton = self.bagToggle

        self.bagToggle:SetScript("OnClick", function()
            if ( self.BagBar:IsShown() ) then
                self.BagBar:Hide()

                if ( self.currencies ) then
                    self.currencies:Show()
                end
            else
                self.BagBar:Show()

                if ( self.currencies ) then
                    self.currencies:Hide()
                end
            end
            self:UpdateDimensions()
        end)

        -- Reset New Items
        if ( self.isBag and cBneavCfg.NewItems ) then
            self.resetBtn = CreateIconButton("ResetNew", self, Textures.ResetNew, "BOTTOMRIGHT", "Reset New", self.isBag)
            self.resetBtn:SetPoint("BOTTOMRIGHT", prevButton, "BOTTOMLEFT", 0, 0)
            self.resetBtn:SetScript("OnClick", function() ResetNewItems(self) end)
            prevButton = self.resetBtn
        end

        -- Restack Items
        if ( cBneavCfg.Restack ) then
            self.restackBtn = CreateIconButton("Restack", self, Textures.Restack, "BOTTOMRIGHT", "Restack", self.isBag)
            self.restackBtn:SetPoint("BOTTOMRIGHT", prevButton, "BOTTOMLEFT", 0, 0)
            self.restackBtn:SetScript("OnClick", function() RestackItems(self) end)
            prevButton = self.restackBtn
        end

        -- Show Options
        self.optionsBtn = CreateIconButton("Options", self, Textures.Config, "BOTTOMRIGHT", "Options", self.isBag)
        self.optionsBtn:SetPoint("BOTTOMRIGHT", prevButton, "BOTTOMLEFT", 0, 0)
        prevButton = self.optionsBtn
        self.optionsBtn:SetScript("OnClick", function()
            SlashCmdList.CBNEAV("")
            print("Usage: /cbneav |cffffff00command|r")
        end)

        -- Button to toggle Sell Junk:
        if ( self.isBag ) then
            local junkHint = cBneavCfg.SellJunk and "Sell Junk |cffd0d0d0(on)|r" or "Sell Junk |cffd0d0d0(off)|r"

            self.junkBtn = CreateIconButton("SellJunk", self, Textures.SellJunk, "BOTTOMRIGHT", junkHint, self.isBag)
            self.junkBtn:SetPoint("BOTTOMRIGHT", prevButton, "BOTTOMLEFT", 0, 0)
            self.junkBtn:SetScript("OnClick", function()
                cBneavCfg.SellJunk = not cBneavCfg.SellJunk

                if ( cBneavCfg.SellJunk ) then
                    self.junkBtn.tooltipText = "Sell Junk |cffd0d0d0(on)|r"
                else
                    self.junkBtn.tooltipText = "Sell Junk |cffd0d0d0(off)|r"
                end
            end)
            prevButton = self.junkBtn
        end

        -- Button to send reagents to Reagent Bank:
        if ( self.isBank ) then
            self.reagentBtn = CreateIconButton("SendReagents", self, Textures.Deposit, "BOTTOMRIGHT", REAGENTBANK_DEPOSIT, self.isBag)
            self.reagentBtn:SetPoint("BOTTOMRIGHT", prevButton, "BOTTOMLEFT", 0, 0)
            self.reagentBtn:SetScript("OnClick", function()
                DepositReagentBank()
            end)
        end
    end

    -- Item Drop Target
    if ( self.isBag or self.isBank or self.isReagentBank ) then
        local dropSize = itemSlotSize - 1

        self.DropTarget = CreateFrame("Button", self.name.."DropTarget", self, "ItemButtonTemplate")
        self.DropTarget:SetSize(dropSize, dropSize)

        local normalTexture = _G[self.DropTarget:GetName().."NormalTexture"]
        if ( normalTexture ) then
            normalTexture:SetTexture(nil)
        end

        self.DropTarget.bg = CreateFrame("Frame", "$parentBG", self.DropTarget)
        self.DropTarget.bg:SetAllPoints()
        self.DropTarget.bg:SetBackdrop({
            bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
            edgeFile = [[Interface\Buttons\WHITE8x8]],
            tile = false, tileSize = 16, edgeSize = 1,
        })
        self.DropTarget.bg:SetBackdropColor(1, 1, 1, 0.1)
        self.DropTarget.bg:SetBackdropBorderColor(0, 0, 0, 1)

        local DropTargetProcessItem = function()
            if ( GetCursorInfo() ) then
                local bagIDS = self.isBag and {0,1,2,3,4} or self.isBank and {-1,5,6,7,8,9,10,11} or {-3}
                local bagID, slotID = GetFirstFreeSlot(bagIDS)

                if ( bagID and not InCombatLockdown() ) then
                    PickupContainerItem(bagID, slotID)
                end
            end
        end

        self.DropTarget:SetScript("OnMouseUp", DropTargetProcessItem)
        self.DropTarget:SetScript("OnReceiveDrag", DropTargetProcessItem)

        self.EmptySlotCounter = self:CreateFontString("$parentEmptySlotCounter", "OVERLAY")
        self.EmptySlotCounter:SetFont(unpack(ns.options.fonts.standard))
        self.EmptySlotCounter:SetPoint("BOTTOMRIGHT", self.DropTarget, "BOTTOMRIGHT", 1.5, 1.5)
        self.EmptySlotCounter:SetJustifyH("LEFT")

        if ( cBneavCfg.CompressEmpty ) then
            self.DropTarget:Show()
            self.EmptySlotCounter:Show()
        else
            self.DropTarget:Hide()
            self.EmptySlotCounter:Hide()
        end
    end

    if ( self.isBag ) then
        local infoFrame = CreateFrame("Button", nil, self)
        infoFrame:SetPoint("BOTTOMLEFT", 5, -6)
        infoFrame:SetPoint("BOTTOMRIGHT", -86, -6)
        infoFrame:SetHeight(32)

        -- Item Search
        local searchBar = self:SpawnPlugin("SearchBar", infoFrame)

        local searchIcon = background:CreateTexture("$parentSearchIcon", "ARTWORK")
        searchIcon:SetTexture([[Interface\Common\UI-Searchbox-Icon]])
        searchIcon:SetVertexColor(0.8, 0.8, 0.8)
        searchIcon:SetPoint("BOTTOMLEFT", infoFrame, "BOTTOMLEFT", -3, 6)
        searchIcon:SetWidth(16)
        searchIcon:SetHeight(16)

        -- Player Money
        local money = self:SpawnPlugin("TagDisplay", "[money]", self)
        money:SetPoint("TOPRIGHT", self, -30, -2.5)
        money:SetFont(unpack(ns.options.fonts.standard))
        money:SetJustifyH("RIGHT")
        money:SetShadowColor(0, 0, 0, 0)
        self.money = money

        -- Tracked Currencies
        local currencies = self:SpawnPlugin("TagDisplay", "[currencies]", self)
        currencies:SetPoint("BOTTOMLEFT", infoFrame, -0.5, 31.5)
        currencies:SetFont(unpack(ns.options.fonts.standard))
        currencies:SetJustifyH("LEFT")
        currencies:SetShadowColor(0, 0, 0, 0)
        currencies:SetWordWrap(true)
        self.currencies = currencies
    end

    self:SetScale(cBneavCfg.scale)
    return self
end

--[[!
    Updates the bags when the contents change.
]]

local buttonIDs = {}

function MyContainer:OnContentsChanged()
    local col, row = 0, 0
    local yPosOffs = self.Caption and 20 or 0
    local isEmpty = true

    local name = self.name
    local isBankBags = self.isBankBags
    local isBank = self.isBank
    local isReagentBank = self.isReagentBank

    -- Setup Button IDs
    for i=1, #self.buttons do
        local button = self.buttons[i]
        local item = cbNeav:GetItemInfo(button.bagID, button.slotID)

        if ( item.link ) then
            buttonIDs[i] = {
                frame = button,
                id = item.id,
                quality = item.quality,
                count = item.count
            }
        else
            buttonIDs[i] = {
                frame = button,
                id = -1,
                quality = -2,
                count = -1
            }
        end
    end

    -- Sort Buttons
    if ( ((isBank or isReagentBank) and cBneavCfg.SortBank) or (not (isBank or isReagentBank) and cBneavCfg.SortBags) ) then
        QuickSort(buttonIDs)
    end

    -- Layout Buttons
    for i=1, #buttonIDs do
        local button = buttonIDs[i].frame
        button:ClearAllPoints()

        local xPos = col * (itemSlotSize + 2) + 2
        local yPos = (-1 * row * (itemSlotSize + 2)) - yPosOffs

        button:SetPoint("TOPLEFT", self, "TOPLEFT", xPos, yPos)
        if ( col >= self.Columns-1 ) then
            col = 0
            row = row + 1
        else
            col = col + 1
        end
        isEmpty = false
    end
    wipe(buttonIDs)

    -- Drop Target
    if ( cBneavCfg.CompressEmpty ) then
        local xPos = col * (itemSlotSize + 2) + 2
        local yPos = (-1 * row * (itemSlotSize + 2)) - yPosOffs

        local dropTarget = self.DropTarget
        if ( dropTarget ) then
            dropTarget:ClearAllPoints()
            dropTarget:SetPoint("TOPLEFT", self, "TOPLEFT", xPos, yPos)

            if ( col >= self.Columns-1 ) then
                col = 0
                row = row + 1
            else
                col = col + 1
            end
        end

        cB_Bags.main.EmptySlotCounter:SetText(GetNumFreeSlots({0, 1, 2, 3, 4}))
        cB_Bags.bank.EmptySlotCounter:SetText(GetNumFreeSlots({-1, 5, 6, 7, 8, 9, 10, 11}))
        cB_Bags.bankReagent.EmptySlotCounter:SetText(GetNumFreeSlots({-3}))
    end

    -- Update container size.
    self.ContainerHeight = (row + (col > 0 and 1 or 0)) * (itemSlotSize + 2)
    self.ContainerWidth = (itemSlotSize + 2) * self.Columns + 2
    self:UpdateDimensions()

    -- Bag Visibility
    local isParentBag = name == "cBneav_Bag" or name == "cBneav_Bank" or name == "cBneav_BankReagent"
    local bankShown = cB_Bags.bank:IsShown()

    if ( not isBankBags and cB_Bags.main:IsShown() and not isParentBag or (isBankBags and bankShown) ) then
        if ( isEmpty ) then
            self:Hide()
            if ( bankShown ) then
                cB_Bags.bank:Show()
            end
        else
            self:Show()
        end
    end

    cB_BagHidden[name] = not isParentBag and isEmpty or false
    cbNeav:UpdateAnchors(self)
end

------------------------------------------
-- MyButton specific
------------------------------------------
local MyButton = cbNeav:GetItemButtonClass()
MyButton:Scaffold("Default")

function MyButton:OnAdd()
    self:SetScript("OnMouseUp", function(self, mouseButton)
        if ( mouseButton == "RightButton" and IsAltKeyDown() and IsControlKeyDown() ) then
            local item = GetContainerItemID(self.bagID, self.slotID)
            if ( item ) then
                cbNeavCatDropDown.itemName = GetItemInfo(item)
                cbNeavCatDropDown.itemID = item
                cbNeavCatDropDown:Toggle(self, nil, nil, 0, 0)
            end
        end
    end)
end

------------------------------------------
-- BagButton specific
------------------------------------------
local BagButton = cbNeav:GetClass("BagButton", true, "BagButton")

function BagButton:OnCreate()
    self:GetCheckedTexture():SetVertexColor(1, 0.8, 0, 0.8)
end
