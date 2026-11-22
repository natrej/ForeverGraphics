local _, ns = ...

local MainFrame = {}
ns.MainFrame = MainFrame

local frame = nil
local activeTabId = "world"
local searchQuery = ""
local tabButtons = {}
local curatedRowsByName = {}
local curatedRowsList = {}
local explorerPanel = nil
local scrollContainer = nil
local hdrBanner = nil
local hdrFooterBtn = nil
local statusLabel = nil
local emptyLabel = nil
local customSlotControls = {}
local minimapCheckbox = nil

local function BuildCuratedList()
    if not scrollContainer then return end
    local content = scrollContainer.content

    -- Clear old dynamically laid out children by hiding cached rows & section headers
    if scrollContainer._headers then
        for _, h in ipairs(scrollContainer._headers) do
            h:Hide()
        end
    else
        scrollContainer._headers = {}
    end

    for _, row in ipairs(curatedRowsList) do
        row:Hide()
    end

    local db = ns.Engine:GetDB()
    local showUnsupported = db.settings.showUnsupported
    local isSearching = (searchQuery ~= "")

    local matchingDefs = {}
    for _, def in ipairs(ns.CVARS) do
        local exists = ns.Engine:Exists(def.cvar)
        if exists or showUnsupported then
            if isSearching then
                local hay = string.lower((def.label or "") .. " " .. (def.cvar or "") .. " " .. (def.desc or "") .. " " .. (def.section or ""))
                if string.find(hay, searchQuery, 1, true) then
                    table.insert(matchingDefs, def)
                end
            elseif def.category == activeTabId then
                table.insert(matchingDefs, def)
            end
        end
    end

    local yOffset = -6
    local headerIdx = 0
    local lastSection = nil

    -- Show HDR calibration status banner at top of HDR tab
    if hdrBanner then
        if (not isSearching) and activeTabId == "hdr" then
            local state, msg = ns.Engine:GetHDRStatus()
            hdrBanner.text:SetText(msg)
            if state == "dark" or state == "conflict" then
                hdrBanner:SetBackdropColor(0.32, 0.12, 0.10, 0.95)
                hdrBanner:SetBackdropBorderColor(0.96, 0.36, 0.36, 1.0)
                hdrBanner.text:SetTextColor(1.0, 0.85, 0.82)
            elseif state == "peak" or state == "reference" then
                hdrBanner:SetBackdropColor(0.10, 0.24, 0.15, 0.95)
                hdrBanner:SetBackdropBorderColor(0.45, 0.85, 0.52, 1.0)
                hdrBanner.text:SetTextColor(0.85, 1.0, 0.88)
            else
                hdrBanner:SetBackdropColor(0.10, 0.13, 0.19, 0.95)
                hdrBanner:SetBackdropBorderColor(0.31, 0.76, 0.97, 0.8)
                hdrBanner.text:SetTextColor(0.85, 0.92, 0.98)
            end
            hdrBanner:ClearAllPoints()
            hdrBanner:SetPoint("TOPLEFT", content, "TOPLEFT", 4, yOffset)
            hdrBanner:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, yOffset)
            hdrBanner:Show()
            yOffset = yOffset - 46
        else
            hdrBanner:Hide()
        end
    end

    if #matchingDefs == 0 then
        if emptyLabel then
            emptyLabel:SetText(isSearching
                and ("No curated graphics CVars matched '" .. searchQuery .. "'. Try the 'All Client CVars' tab to search every CVar in the engine!")
                or "No supported CVars found in this category for your current client build.")
            emptyLabel:Show()
        end
        scrollContainer:UpdateScrollRange(120)
        return
    else
        if emptyLabel then emptyLabel:Hide() end
    end

    for _, def in ipairs(matchingDefs) do
        local sectionKey = isSearching and (string.upper(def.category) .. "  —  " .. (def.section or "General")) or (def.section or "General")
        if sectionKey ~= lastSection then
            lastSection = sectionKey
            headerIdx = headerIdx + 1
            local hdr = scrollContainer._headers[headerIdx]
            if not hdr then
                hdr = ns.Widgets.CreateSectionHeader(content, sectionKey)
                scrollContainer._headers[headerIdx] = hdr
            else
                -- Update existing header text
                for _, region in ipairs({ hdr:GetRegions() }) do
                    if region and region.SetText then
                        region:SetText(sectionKey)
                        break
                    end
                end
            end
            hdr:ClearAllPoints()
            hdr:SetPoint("TOPLEFT", content, "TOPLEFT", 4, yOffset)
            hdr:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, yOffset)
            hdr:Show()
            yOffset = yOffset - 26
        end

        local row = curatedRowsByName[def.cvar]
        if not row then
            row = ns.Widgets.CreateCVarRow(content, def)
            curatedRowsByName[def.cvar] = row
            table.insert(curatedRowsList, row)
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 4, yOffset)
        row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, yOffset)
        row:Refresh()
        row:Show()
        yOffset = yOffset - (row:GetHeight() + 5)
    end

    scrollContainer:UpdateScrollRange(math.abs(yOffset) + 12)
end

function MainFrame:UpdateHeaderAndFooterStatus()
    if not frame then return end
    local db = ns.Engine:GetDB()
    local modCount = 0
    for _, def in ipairs(ns.CVARS) do
        if ns.Engine:Exists(def.cvar) and ns.Engine:IsModified(def.cvar) then
            modCount = modCount + 1
        end
    end
    local overrideCount = 0
    for _ in pairs(db.overrides) do
        overrideCount = overrideCount + 1
    end
    if statusLabel then
        statusLabel:SetText(string.format("Modified: |cffffd54f%d|r  |  Protected: |cff4fc3f7%d|r", modCount, overrideCount))
    end

    if hdrFooterBtn then
        local state = ns.Engine:GetHDRStatus()
        if state == "peak" or state == "reference" then
            hdrFooterBtn:SetText("|cff66bb6aHDR10: ON|r")
        elseif state == "dark" or state == "conflict" then
            hdrFooterBtn:SetText("|cffef5350HDR10: FIX|r")
        else
            hdrFooterBtn:SetText("|cff90a4aeHDR10: OFF|r")
        end
    end

    if minimapCheckbox then
        minimapCheckbox:SetChecked(db.settings.showMinimapButton)
    end

    for slotIdx = 1, 2 do
        local ctrl = customSlotControls[slotIdx]
        if ctrl then
            local slot = ns.Engine:GetCustomSlot(slotIdx)
            if slot then
                ctrl.loadBtn:SetText("|cff66bb6aLoad Slot " .. slotIdx .. "|r")
                ctrl.loadBtn:SetEnabled(true)
                ctrl.loadBtn:SetAlpha(1.0)
                ctrl.loadBtn.tooltipTitle = "Load Custom Slot " .. slotIdx
                ctrl.loadBtn.tooltipText = string.format(
                    "Saved %s (%d CVars). Click to apply all saved settings from Slot %d (supports Undo).",
                    tostring(slot.savedAt or "previously"), slot.count or 0, slotIdx
                )
                ctrl.clearBtn:SetEnabled(true)
                ctrl.clearBtn:SetAlpha(1.0)
            else
                ctrl.loadBtn:SetText("|cff8892a4Slot " .. slotIdx .. " (Empty)|r")
                ctrl.loadBtn:SetEnabled(false)
                ctrl.loadBtn:SetAlpha(0.55)
                ctrl.loadBtn.tooltipTitle = "Custom Slot " .. slotIdx .. " (Empty)"
                ctrl.loadBtn.tooltipText = "Click 'Save " .. slotIdx .. "' to store your current graphics settings in this slot."
                ctrl.clearBtn:SetEnabled(false)
                ctrl.clearBtn:SetAlpha(0.35)
            end
        end
    end
end

function MainFrame:SelectTab(tabId)
    activeTabId = tabId
    ns.Widgets.CloseDropdownMenu()

    for id, btn in pairs(tabButtons) do
        btn:SetActive(id == tabId)
    end

    if tabId == "explorer" then
        if scrollContainer then scrollContainer:Hide() end
        if explorerPanel then
            explorerPanel:Show()
            explorerPanel:SetSearch(searchQuery)
        end
    else
        if explorerPanel then explorerPanel:Hide() end
        if scrollContainer then
            scrollContainer:Show()
            scrollContainer:ResetScroll()
            BuildCuratedList()
        end
    end
    self:UpdateHeaderAndFooterStatus()
end

function MainFrame:RefreshAll()
    if not frame or not frame:IsShown() then return end
    if activeTabId == "explorer" then
        if explorerPanel then explorerPanel:RefreshList() end
    else
        BuildCuratedList()
    end
    self:UpdateHeaderAndFooterStatus()
end

function MainFrame:Create()
    if frame then return frame end

    local f = CreateFrame("Frame", "ForeverOpticsMainFrame", UIParent, "BackdropTemplate")
    f:SetSize(880, 640)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local db = ns.Engine:GetDB()
        local point, _, relPoint, x, y = self:GetPoint()
        db.windowPos = { point = point, relPoint = relPoint, x = x, y = y }
    end)
    f:SetScript("OnShow", function()
        MainFrame:RefreshAll()
    end)
    f:SetScript("OnHide", function()
        ns.Widgets.CloseDropdownMenu()
    end)

    ns.Widgets.ApplyBackdrop(f, ns.Widgets.COLORS.bgDark, ns.Widgets.COLORS.borderGold)

    -- Register Escape-to-close
    if UISpecialFrames then
        local exists = false
        for _, name in ipairs(UISpecialFrames) do
            if name == "ForeverOpticsMainFrame" then
                exists = true
                break
            end
        end
        if not exists then
            table.insert(UISpecialFrames, "ForeverOpticsMainFrame")
        end
    end

    -- Restore saved window position
    local db = ns.Engine:GetDB()
    if db.windowPos and db.windowPos.point then
        f:ClearAllPoints()
        f:SetPoint(db.windowPos.point, UIParent, db.windowPos.relPoint or db.windowPos.point, db.windowPos.x or 0, db.windowPos.y or 0)
    end

    ---------------------------------------------------------------------------
    -- TOP TITLE BAR
    ---------------------------------------------------------------------------
    local titleBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    titleBar:SetHeight(40)
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    ns.Widgets.ApplyBackdrop(titleBar, { 0.08, 0.10, 0.14, 0.98 }, { 0.25, 0.28, 0.36, 0.8 })

    local icon = titleBar:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("LEFT", 12, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_03")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local titleTxt = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleTxt:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    titleTxt:SetText("ForeverOptics")
    titleTxt:SetTextColor(1.0, 0.82, 0.28)

    local verTxt = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    verTxt:SetPoint("LEFT", titleTxt, "RIGHT", 8, -1)
    verTxt:SetText("by " .. ns.ADDON_AUTHOR .. "  |  v" .. ns.ADDON_VERSION .. "  |cff4fc3f7WoW: Forever 1.60.1|r")
    verTxt:SetTextColor(0.68, 0.74, 0.84)

    local closeBtn = ns.Widgets.CreateButton(titleBar, 26, 24, "X", function()
        f:Hide()
    end)
    closeBtn:SetPoint("RIGHT", -8, 0)

    local fpsBtn = ns.Widgets.CreateButton(titleBar, 88, 24, "FPS Overlay", function()
        ns.FPSOverlay:Toggle()
    end)
    fpsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)
    fpsBtn.tooltipTitle = "Toggle FPS Overlay"
    fpsBtn.tooltipText = "Shows a movable live FPS, frame time, ping, and before/after CVar FPS impact meter."

    -- Global cross-tab Search Box
    local searchBox = CreateFrame("EditBox", nil, titleBar, "BackdropTemplate")
    searchBox:SetSize(210, 24)
    searchBox:SetPoint("RIGHT", fpsBtn, "LEFT", -8, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject("GameFontHighlightSmall")
    searchBox:SetTextInsets(8, 22, 0, 0)
    ns.Widgets.ApplyBackdrop(searchBox, ns.Widgets.COLORS.bgInput, ns.Widgets.COLORS.border)

    local placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    placeholder:SetPoint("LEFT", 8, 0)
    placeholder:SetText("Search all settings / CVars...")

    local clearSearchBtn = CreateFrame("Button", nil, searchBox)
    clearSearchBtn:SetSize(18, 18)
    clearSearchBtn:SetPoint("RIGHT", -3, 0)
    local clearTxt = clearSearchBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    clearTxt:SetPoint("CENTER")
    clearTxt:SetText("x")
    clearTxt:SetTextColor(0.7, 0.72, 0.78)
    clearSearchBtn:Hide()
    clearSearchBtn:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
    end)

    searchBox:SetScript("OnTextChanged", function(self)
        local txt = self:GetText() or ""
        searchQuery = string.lower(txt)
        if txt == "" then
            placeholder:Show()
            clearSearchBtn:Hide()
        else
            placeholder:Hide()
            clearSearchBtn:Show()
        end
        if activeTabId == "explorer" then
            if explorerPanel then explorerPanel:SetSearch(searchQuery) end
        else
            BuildCuratedList()
        end
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    ---------------------------------------------------------------------------
    -- PRESET & CUSTOM SAVE SLOTS BAR (2 rows)
    ---------------------------------------------------------------------------
    local presetBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    presetBar:SetHeight(64)
    presetBar:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 8, -6)
    presetBar:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", -8, -6)
    ns.Widgets.ApplyBackdrop(presetBar, { 0.09, 0.11, 0.15, 0.92 }, ns.Widgets.COLORS.border)

    -- Row 1: Built-in Presets + Undo / Backup / Reset All
    local pLabel = presetBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pLabel:SetPoint("TOPLEFT", 10, -11)
    pLabel:SetText("Presets:")
    pLabel:SetTextColor(1.0, 0.82, 0.28)

    local prevBtn = pLabel
    for _, preset in ipairs(ns.PRESETS) do
        local w = (preset.id == "handheld") and 98 or 86
        local pBtn = ns.Widgets.CreateButton(presetBar, w, 22, preset.label, function()
            ns.Engine:ApplyPreset(preset.id)
        end)
        pBtn:SetPoint("LEFT", prevBtn, "RIGHT", 5, 0)
        pBtn.tooltipTitle = "Preset: " .. preset.label
        pBtn.tooltipText = preset.desc
        prevBtn = pBtn
    end

    local resetAllBtn = ns.Widgets.CreateButton(presetBar, 68, 22, "Reset All", function()
        ns.Engine:ResetAllToBlizzardDefault()
    end)
    resetAllBtn:SetPoint("TOPRIGHT", -8, -6)
    resetAllBtn.tooltipTitle = "Reset All to Blizzard Defaults"
    resetAllBtn.tooltipText = "Restores every graphics CVar managed by ForeverOptics back to Blizzard's client default."

    local restoreBtn = ns.Widgets.CreateButton(presetBar, 74, 22, "Backup", function()
        ns.Engine:RestoreBackup()
    end)
    restoreBtn:SetPoint("RIGHT", resetAllBtn, "LEFT", -4, 0)
    restoreBtn.tooltipTitle = "Restore Pre-Addon Backup"
    restoreBtn.tooltipText = "Restores the exact CVar values your client had before you changed them with ForeverOptics."

    local undoBtn = ns.Widgets.CreateButton(presetBar, 54, 22, "Undo", function()
        ns.Engine:UndoLastPreset()
    end)
    undoBtn:SetPoint("RIGHT", restoreBtn, "LEFT", -4, 0)
    undoBtn.tooltipTitle = "Undo Last Preset / Slot"
    undoBtn.tooltipText = "Reverts the settings changed by the most recently applied preset or custom save slot."

    -- Subtle divider between Row 1 and Row 2
    local rowDivider = presetBar:CreateTexture(nil, "ARTWORK")
    rowDivider:SetHeight(1)
    rowDivider:SetPoint("TOPLEFT", 8, -33)
    rowDivider:SetPoint("TOPRIGHT", -8, -33)
    rowDivider:SetTexture("Interface\\Buttons\\WHITE8X8")
    rowDivider:SetVertexColor(0.26, 0.30, 0.38, 0.45)

    -- Row 2: 2 Custom Preset Save Slots + Show Minimap Icon Toggle
    local slotLabel = presetBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    slotLabel:SetPoint("TOPLEFT", 10, -43)
    slotLabel:SetText("Save Slots:")
    slotLabel:SetTextColor(0.45, 0.82, 1.0)

    local slotAnchor = slotLabel
    for slotIdx = 1, 2 do
        local gap = (slotIdx == 1) and 8 or 18
        local loadBtn = ns.Widgets.CreateButton(presetBar, 118, 22, "Slot " .. slotIdx .. " (Empty)", function()
            ns.Engine:LoadCustomSlot(slotIdx)
        end)
        loadBtn:SetPoint("LEFT", slotAnchor, "RIGHT", gap, 0)

        local saveBtn = ns.Widgets.CreateButton(presetBar, 54, 22, "Save " .. slotIdx, function()
            ns.Engine:SaveCustomSlot(slotIdx)
        end)
        saveBtn:SetPoint("LEFT", loadBtn, "RIGHT", 4, 0)
        saveBtn.tooltipTitle = "Save to Custom Slot " .. slotIdx
        saveBtn.tooltipText = "Saves all current curated graphics settings and custom CVar overrides into Slot " .. slotIdx .. "."

        local clearBtn = ns.Widgets.CreateButton(presetBar, 22, 22, "x", function()
            ns.Engine:ClearCustomSlot(slotIdx)
        end)
        clearBtn:SetPoint("LEFT", saveBtn, "RIGHT", 3, 0)
        clearBtn.tooltipTitle = "Clear Custom Slot " .. slotIdx
        clearBtn.tooltipText = "Removes the saved preset stored in Slot " .. slotIdx .. "."

        customSlotControls[slotIdx] = {
            loadBtn = loadBtn,
            saveBtn = saveBtn,
            clearBtn = clearBtn,
        }
        slotAnchor = clearBtn
    end

    minimapCheckbox = ns.Widgets.CreateCheckBox(presetBar, "Show Minimap Icon", function(_, checked)
        ns.MinimapBtn:SetShown(checked)
    end)
    minimapCheckbox:SetPoint("TOPRIGHT", -124, -40)
    minimapCheckbox:SetChecked(db.settings.showMinimapButton)

    ---------------------------------------------------------------------------
    -- FOOTER BAR
    ---------------------------------------------------------------------------
    local footer = CreateFrame("Frame", nil, f, "BackdropTemplate")
    footer:SetHeight(38)
    footer:SetPoint("BOTTOMLEFT", 8, 8)
    footer:SetPoint("BOTTOMRIGHT", -8, 8)
    ns.Widgets.ApplyBackdrop(footer, { 0.08, 0.10, 0.14, 0.95 }, ns.Widgets.COLORS.border)

    local cbReapply = ns.Widgets.CreateCheckBox(footer, "Reapply on Login", function(_, checked)
        ns.Engine:GetDB().settings.reapplyOnLogin = checked
    end)
    cbReapply:SetPoint("LEFT", 10, 0)
    cbReapply:SetChecked(db.settings.reapplyOnLogin)

    local cbProtect = ns.Widgets.CreateCheckBox(footer, "Protect Overrides", function(_, checked)
        ns.Engine:GetDB().settings.protectValues = checked
    end)
    cbProtect:SetPoint("LEFT", cbReapply, "RIGHT", 118, 0)
    cbProtect:SetChecked(db.settings.protectValues)

    local cbUnsup = ns.Widgets.CreateCheckBox(footer, "Show Unsupported", function(_, checked)
        ns.Engine:GetDB().settings.showUnsupported = checked
        BuildCuratedList()
    end)
    cbUnsup:SetPoint("LEFT", cbProtect, "RIGHT", 122, 0)
    cbUnsup:SetChecked(db.settings.showUnsupported)

    local restartBtn = ns.Widgets.CreateButton(footer, 80, 22, "Restart GX", function()
        ns.Engine:RestartGraphics()
    end)
    restartBtn:SetPoint("RIGHT", -8, 0)
    restartBtn.tooltipTitle = "Restart Graphics Engine"
    restartBtn.tooltipText = "Applies display pipeline changes such as HDR10 Output or Pixel Color Format without logging out."

    local reapplyNowBtn = ns.Widgets.CreateButton(footer, 84, 22, "Reapply Now", function()
        ns.Engine:ReapplySaved(false)
    end)
    reapplyNowBtn:SetPoint("RIGHT", restartBtn, "LEFT", -5, 0)
    reapplyNowBtn.tooltipTitle = "Reapply All Saved Overrides"
    reapplyNowBtn.tooltipText = "Immediately re-writes all CVars you customized in ForeverOptics."

    hdrFooterBtn = ns.Widgets.CreateButton(footer, 86, 22, "HDR10: OFF", function()
        MainFrame:SelectTab("hdr")
    end)
    hdrFooterBtn:SetPoint("RIGHT", reapplyNowBtn, "LEFT", -5, 0)
    hdrFooterBtn.tooltipTitle = "HDR10 Calibration Status"
    hdrFooterBtn.tooltipText = "Click to open the HDR10 & Display Calibration tab."

    statusLabel = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusLabel:SetPoint("RIGHT", hdrFooterBtn, "LEFT", -10, 0)
    statusLabel:SetJustifyH("RIGHT")

    ---------------------------------------------------------------------------
    -- LEFT CATEGORY SIDEBAR
    ---------------------------------------------------------------------------
    local sidebar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    sidebar:SetWidth(158)
    sidebar:SetPoint("TOPLEFT", presetBar, "BOTTOMLEFT", 0, -6)
    sidebar:SetPoint("BOTTOMLEFT", footer, "TOPLEFT", 0, 6)
    ns.Widgets.ApplyBackdrop(sidebar, { 0.08, 0.09, 0.12, 0.94 }, ns.Widgets.COLORS.border)

    local tabY = -8
    for _, cat in ipairs(ns.CATEGORIES) do
        local tBtn = ns.Widgets.CreateButton(sidebar, 144, 30, cat.title, function()
            MainFrame:SelectTab(cat.id)
        end)
        tBtn:SetPoint("TOPLEFT", 7, tabY)
        tBtn.label:ClearAllPoints()
        tBtn.label:SetPoint("LEFT", 10, 0)
        tBtn.label:SetJustifyH("LEFT")
        tBtn.tooltipTitle = cat.title
        tBtn.tooltipText = cat.description
        tabButtons[cat.id] = tBtn
        tabY = tabY - 34
    end

    -- Separator before Live Client CVar Explorer
    local sep = sidebar:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 10, tabY - 4)
    sep:SetPoint("TOPRIGHT", -10, tabY - 4)
    sep:SetTexture("Interface\\Buttons\\WHITE8X8")
    sep:SetVertexColor(0.78, 0.62, 0.26, 0.45)

    local expBtn = ns.Widgets.CreateButton(sidebar, 144, 34, "|cff4fc3f7All Client CVars|r", function()
        MainFrame:SelectTab("explorer")
    end)
    expBtn:SetPoint("TOPLEFT", 7, tabY - 12)
    expBtn.label:ClearAllPoints()
    expBtn.label:SetPoint("LEFT", 10, 0)
    expBtn.label:SetJustifyH("LEFT")
    expBtn.tooltipTitle = "Live Client CVar Explorer"
    expBtn.tooltipText = "Scans C_Console.GetAllCommands() to expose and edit EVERY hidden graphics and engine CVar in your live WoW: Forever client, plus Snapshot/Diff discovery."
    tabButtons["explorer"] = expBtn

    -- Safety hint at bottom of sidebar
    local safeNote = sidebar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    safeNote:SetPoint("BOTTOMLEFT", 10, 10)
    safeNote:SetPoint("BOTTOMRIGHT", -10, 10)
    safeNote:SetJustifyH("LEFT")
    safeNote:SetText("|cff81c784Safety Guard Active|r\nwaterDetail <= 2\nreflectionMode <= 3\nCombat-safe queue")
    safeNote:SetTextColor(0.58, 0.64, 0.72)

    ---------------------------------------------------------------------------
    -- RIGHT MAIN CONTENT AREA
    ---------------------------------------------------------------------------
    local bodyArea = CreateFrame("Frame", nil, f)
    bodyArea:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 8, 0)
    bodyArea:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", 0, 6)

    scrollContainer = ns.Widgets.CreateScrollContainer(bodyArea)
    scrollContainer:SetAllPoints()

    -- HDR status banner (shown inside scroll content on HDR tab)
    hdrBanner = CreateFrame("Frame", nil, scrollContainer.content, "BackdropTemplate")
    hdrBanner:SetHeight(38)
    ns.Widgets.ApplyBackdrop(hdrBanner, { 0.10, 0.13, 0.19, 0.95 }, ns.Widgets.COLORS.accent)
    local hdrTxt = hdrBanner:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdrTxt:SetPoint("LEFT", 10, 0)
    hdrTxt:SetPoint("RIGHT", -10, 0)
    hdrTxt:SetJustifyH("LEFT")
    hdrBanner.text = hdrTxt
    hdrBanner:Hide()

    emptyLabel = scrollContainer.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyLabel:SetPoint("TOPLEFT", 16, -24)
    emptyLabel:SetPoint("TOPRIGHT", -16, -24)
    emptyLabel:SetJustifyH("LEFT")
    emptyLabel:SetTextColor(0.65, 0.70, 0.78)
    emptyLabel:Hide()

    -- Live Client CVar Explorer panel
    explorerPanel = ns.Explorer:Build(bodyArea)
    explorerPanel:Hide()

    -- Listen to engine updates to keep controls live-synced
    ns.Engine:RegisterListener(function()
        MainFrame:RefreshAll()
    end)

    frame = f
    self:SelectTab("world")
    f:Hide()
    return f
end

function MainFrame:Toggle()
    local f = self:Create()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
        self:RefreshAll()
    end
end

function MainFrame:ShowTab(tabId)
    local f = self:Create()
    f:Show()
    self:SelectTab(tabId or "world")
end
