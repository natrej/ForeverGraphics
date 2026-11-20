local _, ns = ...

local Explorer = {}
ns.Explorer = Explorer

local ROW_HEIGHT = 30
local VISIBLE_ROWS = 13

function Explorer:Build(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()

    -- Top filter & tool bar
    local bar = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    bar:SetHeight(34)
    bar:SetPoint("TOPLEFT", 0, 0)
    bar:SetPoint("TOPRIGHT", 0, 0)
    ns.Widgets.ApplyBackdrop(bar, { 0.08, 0.10, 0.14, 0.92 }, ns.Widgets.COLORS.border)

    local filterMode = "graphics" -- "graphics" | "all" | "modified"
    local searchText = ""
    local filteredList = {}

    local btnGfx = ns.Widgets.CreateButton(bar, 108, 22, "Graphics CVars")
    btnGfx:SetPoint("LEFT", 6, 0)
    local btnMod = ns.Widgets.CreateButton(bar, 96, 22, "Modified Only")
    btnMod:SetPoint("LEFT", btnGfx, "RIGHT", 4, 0)
    local btnAll = ns.Widgets.CreateButton(bar, 102, 22, "All Client CVars")
    btnAll:SetPoint("LEFT", btnMod, "RIGHT", 4, 0)

    local btnDiff = ns.Widgets.CreateButton(bar, 82, 22, "Diff Snap", function()
        local diffs = ns.Engine:DiffSnapshot()
        if #diffs > 0 then
            -- Filter view to changed CVars for instant visibility
            local lookup = {}
            for _, d in ipairs(diffs) do
                lookup[string.lower(d.cvar)] = true
            end
            panel:RefreshList(lookup)
        end
    end)
    btnDiff:SetPoint("RIGHT", -6, 0)
    btnDiff.tooltipTitle = "Diff Against Snapshot"
    btnDiff.tooltipText = "Compares all live client CVars against your last Snapshot and lists every CVar that changed."

    local btnSnap = ns.Widgets.CreateButton(bar, 78, 22, "Snapshot", function()
        ns.Engine:TakeSnapshot()
    end)
    btnSnap:SetPoint("RIGHT", btnDiff, "LEFT", -4, 0)
    btnSnap.tooltipTitle = "Take CVar Snapshot"
    btnSnap.tooltipText = "Records the current value of every client CVar so you can tweak a Blizzard option and see which CVars changed."

    local btnRescan = ns.Widgets.CreateButton(bar, 64, 22, "Rescan", function()
        ns.Engine:ScanAllClientCVars(true)
        panel:RefreshList()
    end)
    btnRescan:SetPoint("RIGHT", btnSnap, "LEFT", -4, 0)
    btnRescan.tooltipTitle = "Rescan Client CVars"
    btnRescan.tooltipText = "Re-queries C_Console.GetAllCommands() from the live WoW: Forever client."

    local countLabel = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    countLabel:SetPoint("LEFT", btnAll, "RIGHT", 8, 0)
    countLabel:SetPoint("RIGHT", btnRescan, "LEFT", -6, 0)
    countLabel:SetJustifyH("LEFT")
    countLabel:SetTextColor(0.65, 0.72, 0.82)

    -- Column header row
    local header = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    header:SetHeight(22)
    header:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -4)
    header:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
    ns.Widgets.ApplyBackdrop(header, { 0.11, 0.13, 0.18, 0.95 }, ns.Widgets.COLORS.border)

    local hName = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hName:SetPoint("LEFT", 10, 0)
    hName:SetText("CVar Name & Description")
    hName:SetTextColor(1.0, 0.82, 0.28)

    local hDef = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hDef:SetPoint("RIGHT", -212, 0)
    hDef:SetText("Default")
    hDef:SetTextColor(1.0, 0.82, 0.28)

    local hVal = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hVal:SetPoint("RIGHT", -116, 0)
    hVal:SetText("Live Value")
    hVal:SetTextColor(1.0, 0.82, 0.28)

    -- Virtualized list container
    local listFrame = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    listFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    listFrame:SetPoint("BOTTOMRIGHT", 0, 0)
    ns.Widgets.ApplyBackdrop(listFrame, { 0.06, 0.07, 0.10, 0.92 }, ns.Widgets.COLORS.border)

    -- Scrollbar for virtualized rows
    local scrollBar = CreateFrame("Slider", nil, listFrame, "BackdropTemplate")
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetPoint("TOPRIGHT", -4, -4)
    scrollBar:SetPoint("BOTTOMRIGHT", -4, 4)
    scrollBar:SetWidth(10)
    ns.Widgets.ApplyBackdrop(scrollBar, { 0.05, 0.06, 0.08, 0.9 }, { 0.20, 0.24, 0.30, 0.8 })

    local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumb:SetVertexColor(0.42, 0.50, 0.62, 0.85)
    thumb:SetSize(8, 36)
    scrollBar:SetThumbTexture(thumb)
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValueStep(1)
    scrollBar:SetObeyStepOnDrag(true)
    scrollBar:SetValue(0)

    local rows = {}
    local scrollOffset = 0

    local function RenderRows()
        local total = #filteredList
        for i = 1, VISIBLE_ROWS do
            local row = rows[i]
            local idx = scrollOffset + i
            local entry = filteredList[idx]
            if entry then
                row.entry = entry
                local cvar = entry.command
                local cur = ns.Engine:Get(cvar)
                local def = ns.Engine:GetDefault(cvar)
                local isMod = ns.Engine:IsModified(cvar)
                local isRO = ns.Engine:IsReadOnly(cvar)

                row.nameTxt:SetText(cvar)
                if isMod then
                    row.nameTxt:SetTextColor(1.0, 0.84, 0.30)
                    row.modBar:Show()
                elseif entry.isCurated then
                    row.nameTxt:SetTextColor(0.45, 0.82, 1.0)
                    row.modBar:Hide()
                else
                    row.nameTxt:SetTextColor(0.90, 0.92, 0.95)
                    row.modBar:Hide()
                end

                local helpLine = entry.help or ""
                if #helpLine > 64 then
                    helpLine = string.sub(helpLine, 1, 61) .. "..."
                end
                row.helpTxt:SetText(helpLine)
                row.defTxt:SetText(tostring(def or "-"))

                if not row.editBox:HasFocus() then
                    row.editBox:SetText(tostring(cur or ""))
                end
                row.editBox:SetEnabled(not isRO)
                row.setBtn:SetEnabled(not isRO)
                row.defBtn:SetEnabled((not isRO) and isMod)
                row.defBtn:SetAlpha(((not isRO) and isMod) and 1.0 or 0.35)
                row:Show()
            else
                row.entry = nil
                row:Hide()
            end
        end
    end

    for i = 1, VISIBLE_ROWS do
        local row = CreateFrame("Frame", nil, listFrame, "BackdropTemplate")
        row:SetHeight(ROW_HEIGHT - 2)
        row:SetPoint("TOPLEFT", 6, -4 - (i - 1) * ROW_HEIGHT)
        row:SetPoint("TOPRIGHT", -20, -4 - (i - 1) * ROW_HEIGHT)
        local bgAlpha = (i % 2 == 0) and 0.82 or 0.60
        ns.Widgets.ApplyBackdrop(row, { 0.11, 0.13, 0.17, bgAlpha }, { 0.18, 0.21, 0.28, 0.55 })

        local modBar = row:CreateTexture(nil, "OVERLAY")
        modBar:SetPoint("TOPLEFT", 1, -1)
        modBar:SetPoint("BOTTOMLEFT", 1, 1)
        modBar:SetWidth(3)
        modBar:SetTexture("Interface\\Buttons\\WHITE8X8")
        modBar:SetVertexColor(1.0, 0.82, 0.28, 1.0)
        modBar:Hide()
        row.modBar = modBar

        local nameTxt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameTxt:SetPoint("TOPLEFT", 8, -3)
        nameTxt:SetWidth(285)
        nameTxt:SetJustifyH("LEFT")
        row.nameTxt = nameTxt

        local helpTxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        helpTxt:SetPoint("BOTTOMLEFT", 8, 3)
        helpTxt:SetWidth(390)
        helpTxt:SetJustifyH("LEFT")
        helpTxt:SetTextColor(0.55, 0.60, 0.68)
        row.helpTxt = helpTxt

        local defBtn = ns.Widgets.CreateButton(row, 42, 20, "Def", function()
            if row.entry then
                ns.Engine:ResetCVar(row.entry.command)
                RenderRows()
            end
        end)
        defBtn:SetPoint("RIGHT", -4, 0)
        row.defBtn = defBtn

        local setBtn = ns.Widgets.CreateButton(row, 38, 20, "Set", function()
            if row.entry then
                local val = row.editBox:GetText()
                ns.Engine:Set(row.entry.command, val)
                row.editBox:ClearFocus()
                RenderRows()
            end
        end)
        setBtn:SetPoint("RIGHT", defBtn, "LEFT", -4, 0)
        row.setBtn = setBtn

        local editBox = CreateFrame("EditBox", nil, row, "BackdropTemplate")
        editBox:SetSize(82, 20)
        editBox:SetPoint("RIGHT", setBtn, "LEFT", -4, 0)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject("GameFontHighlightSmall")
        editBox:SetJustifyH("CENTER")
        ns.Widgets.ApplyBackdrop(editBox, ns.Widgets.COLORS.bgInput, ns.Widgets.COLORS.border)
        editBox:SetScript("OnEnterPressed", function(self)
            if row.entry then
                ns.Engine:Set(row.entry.command, self:GetText())
                self:ClearFocus()
                RenderRows()
            end
        end)
        editBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
            RenderRows()
        end)
        row.editBox = editBox

        local defTxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        defTxt:SetPoint("RIGHT", editBox, "LEFT", -10, 0)
        defTxt:SetWidth(68)
        defTxt:SetJustifyH("RIGHT")
        defTxt:SetTextColor(0.60, 0.66, 0.74)
        row.defTxt = defTxt

        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            if not self.entry then return end
            self:SetBackdropColor(0.16, 0.20, 0.27, 0.95)
            local curated = ns.CVAR_BY_NAME[string.lower(self.entry.command)]
            if curated then
                ns.Widgets.ShowCVarTooltip(self, curated, true, ns.Engine:IsReadOnly(self.entry.command))
            else
                ns.Widgets.ShowCVarTooltip(self, {
                    cvar = self.entry.command,
                    label = self.entry.command,
                    desc = self.entry.help,
                }, true, ns.Engine:IsReadOnly(self.entry.command))
            end
        end)
        row:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.11, 0.13, 0.17, bgAlpha)
            ns.Widgets.HideTooltip()
        end)

        rows[i] = row
    end

    scrollBar:SetScript("OnValueChanged", function(_, value)
        scrollOffset = math.floor(value + 0.5)
        RenderRows()
    end)

    listFrame:EnableMouseWheel(true)
    listFrame:SetScript("OnMouseWheel", function(_, delta)
        local minV, maxV = scrollBar:GetMinMaxValues()
        local nextVal = scrollOffset - (delta * 3)
        if nextVal < minV then nextVal = minV end
        if nextVal > maxV then nextVal = maxV end
        scrollBar:SetValue(nextVal)
    end)

    local function UpdateModeButtons()
        btnGfx:SetActive(filterMode == "graphics")
        btnMod:SetActive(filterMode == "modified")
        btnAll:SetActive(filterMode == "all")
    end

    btnGfx:SetScript("OnClick", function()
        filterMode = "graphics"
        UpdateModeButtons()
        panel:RefreshList()
    end)
    btnMod:SetScript("OnClick", function()
        filterMode = "modified"
        UpdateModeButtons()
        panel:RefreshList()
    end)
    btnAll:SetScript("OnClick", function()
        filterMode = "all"
        UpdateModeButtons()
        panel:RefreshList()
    end)

    function panel:SetSearch(text)
        searchText = string.lower(text or "")
        self:RefreshList()
    end

    function panel:RefreshList(onlyLookup)
        local all = ns.Engine:ScanAllClientCVars(false)
        filteredList = {}
        for _, entry in ipairs(all) do
            local include = true
            if onlyLookup then
                include = (onlyLookup[string.lower(entry.command)] == true)
            elseif filterMode == "graphics" then
                include = entry.isGraphics
            elseif filterMode == "modified" then
                include = ns.Engine:IsModified(entry.command)
            end

            if include and searchText ~= "" then
                local hay = string.lower(entry.command .. " " .. (entry.help or ""))
                if not string.find(hay, searchText, 1, true) then
                    include = false
                end
            end

            if include then
                table.insert(filteredList, entry)
            end
        end

        local maxOff = math.max(0, #filteredList - VISIBLE_ROWS)
        if scrollOffset > maxOff then scrollOffset = maxOff end
        scrollBar:SetMinMaxValues(0, maxOff)
        scrollBar:SetValue(scrollOffset)
        if maxOff <= 0 then
            scrollBar:Hide()
        else
            scrollBar:Show()
        end

        if onlyLookup then
            countLabel:SetText(string.format("Diff: %d changed", #filteredList))
        else
            countLabel:SetText(string.format("Showing %d CVars", #filteredList))
        end

        RenderRows()
    end

    UpdateModeButtons()
    panel:RefreshList()
    return panel
end
