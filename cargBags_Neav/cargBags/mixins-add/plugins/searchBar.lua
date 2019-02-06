--[[
LICENSE
    cargBags: An inventory framework addon for World of Warcraft

    Copyright (C) 2010  Constantin "Cargor" Schomburg <xconstruct@gmail.com>

    cargBags is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    cargBags is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with cargBags; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

DESCRIPTION:
    Provides a searchbar for your containers.
    If you specify a frame as arg #2, it will serve as a clickable placeholder to open it

DEPENDENCIES
    mixins/textFilter.lua
]]

local addon, ns = ...
local cargBags = ns.cargBags

local function OpenSearch(frame)
    frame:Hide()
    frame.search:Show()
end

local function CloseSearch(frame)
    frame.target:Show()
	frame:SetText("")
	frame:ClearFocus()
    frame:Hide()
end

local function Search_OnEnter(frame)
    frame:ClearFocus()
    if(frame.OnEnterPressed) then frame:OnEnterPressed() end
end

local function Search_OnEscape(frame)
    frame:ClearFocus()
	frame:SetText("")
    if(frame.OnEscapePressed) then frame:OnEscapePressed() end
end

local function ClearButton_OnClick(self)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	local editBox = self:GetParent()
	editBox:SetText("")
	editBox:ClearFocus()
end

cargBags:RegisterPlugin("SearchBar", function(self, target)
    local search = CreateFrame("EditBox", nil, self, "BagSearchBoxTemplate")
    search:SetSize(96, 18)
    search.searchIcon:Hide()

    search:SetScript("OnEscapePressed", Search_OnEscape)
    search:SetScript("OnEnterPressed", Search_OnEnter)

    local clearButton = search.clearButton
    clearButton:SetScript("OnClick", ClearButton_OnClick)

    if ( target ) then
        search:SetAutoFocus(true)
        search:SetAllPoints(target)
        search:Hide()

        target.search, search.target = search, target
        target:RegisterForClicks("anyUp")
        target:SetScript("OnClick", OpenSearch)
        search:SetScript("OnEditFocusLost", CloseSearch)
    end

    self.Search = search
    return search
end)
