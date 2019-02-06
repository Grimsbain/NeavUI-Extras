local addon, ns = ...
local cargBags = ns.cargBags

local floor = math.floor

local function DisableInCombat(self)
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:SetScript("OnEvent", function(self, event, ...)
        if ( event == "PLAYER_REGEN_ENABLED" ) then
            self:Enable()
        else
            self:Disable()
        end
    end)
end

local function CreateCheckBox(name, parent, label, tooltip, relativeTo, x, y, disableInCombat)
    local checkBox = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    checkBox:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", x, y)
    checkBox.Text:SetText(label)

    if ( tooltip ) then
        checkBox.tooltipText = tooltip
    end

    if ( disableInCombat ) then
        DisableInCombat(checkBox)
    end

    return checkBox
end

local function CreateSlider(name, parent, label, relativeTo, x, y, cvar, nDB, fromatString, defaultValue, minValue, maxValue, step, disableInCombat)
    local value
    if ( cvar ) then
        value = BlizzardOptionsPanel_GetCVarSafe(cvar)
    else
        value = nDB
    end

    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetWidth(180)
    slider:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", x, y)
    slider.textLow = _G[name.."Low"]
    slider.textHigh = _G[name.."High"]
    slider.text = _G[name.."Text"]

    slider:SetMinMaxValues(minValue, maxValue)
    slider.minValue, slider.maxValue = slider:GetMinMaxValues()
    slider:SetValue(value)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    slider.text:SetFormattedText(fromatString, defaultValue)
    slider.text:ClearAllPoints()
    slider.text:SetPoint("BOTTOMRIGHT", slider, "TOPRIGHT")

    slider.textHigh:Hide()

    slider.textLow:ClearAllPoints()
    slider.textLow:SetPoint("BOTTOMLEFT", slider, "TOPLEFT")
    slider.textLow:SetPoint("BOTTOMRIGHT", slider.text, "BOTTOMLEFT", -4, 0)
    slider.textLow:SetText(label)
    slider.textLow:SetJustifyH("LEFT")

    if ( disableInCombat ) then
        LockInCombat(slider)
    end

    return slider
end

local Options = CreateFrame("Frame", "cbNeavOptions", InterfaceOptionsFramePanelContainer)
Options.name = GetAddOnMetadata(addon, "Title")
Options.version = GetAddOnMetadata(addon, "Version")
InterfaceOptions_AddCategory(Options)

Options:Hide()
Options:SetScript("OnShow", function()
    local panelWidth = Options:GetWidth()/2

    local LeftSide = CreateFrame("Frame", "LeftSide", Options)
    LeftSide:SetHeight(Options:GetHeight())
    LeftSide:SetWidth(panelWidth)
    LeftSide:SetPoint("TOPLEFT", Options)

    local RightSide = CreateFrame("Frame", "RightSide", Options)
    RightSide:SetHeight(Options:GetHeight())
    RightSide:SetWidth(panelWidth)
    RightSide:SetPoint("TOPRIGHT", Options)

    -- Left Side --

    local BagOptions = Options:CreateFontString("BagOptions", "ARTWORK", "GameFontNormalLarge")
    BagOptions:SetPoint("TOPLEFT", LeftSide, 16, -16)
    BagOptions:SetText("Bag Options")

    local currentScale = cBneavCfg.scale or 1
    local bagScale = CreateSlider("bagScale", LeftSide, "Scale", BagOptions, 0, -30, nil, cBneavCfg.scale, "%.2f", currentScale, 0.50, 1.5, 0.05, false)
    bagScale:SetScript("OnValueChanged", function(self, value)
        bagScale.text:SetFormattedText("%.2f", value)
        cBneavCfg.scale = value
        for _,v in pairs(cB_Bags) do v:SetScale(cBneavCfg.scale) end
    end)

    local bagLock = CreateCheckBox("bagLock", LeftSide, "Locked", nil, bagScale, 0, -6, false)
    bagLock:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        cBneavCfg.Unlocked = not cBneavCfg.Unlocked
    end)

    local AddonTitle = Options:CreateFontString("$parentTitle", "ARTWORK", "GameFontNormalLarge")
    AddonTitle:SetPoint("BOTTOMRIGHT", -16, 16)
    AddonTitle:SetText(Options.name.." "..Options.version)

    function Options:Refresh()
        bagLock:SetChecked(not cBneavCfg.Unlocked)
    end

    Options:Refresh()
    Options:SetScript("OnShow", nil)
end)
