local _, ns = ...

local Widgets = {}
ns.Widgets = Widgets

-- Visual palette (Blizzard dark slate + warm gold accents)
Widgets.COLORS = {
    bgDark       = { 0.06, 0.07, 0.09, 0.96 },
    bgPanel      = { 0.09, 0.11, 0.14, 0.94 },
    bgCard       = { 0.12, 0.14, 0.18, 0.88 },
    bgCardHover  = { 0.15, 0.18, 0.23, 0.95 },
    bgInput      = { 0.05, 0.06, 0.08, 1.00 },
    border       = { 0.26, 0.30, 0.38, 0.90 },
    borderGold   = { 0.78, 0.62, 0.26, 0.95 },
    gold         = { 1.00, 0.82, 0.28, 1.00 },
    accent       = { 0.31, 0.76, 0.97, 1.00 },
    text         = { 0.93, 0.94, 0.96, 1.00 },
    textMuted    = { 0.62, 0.66, 0.74, 1.00 },
    textDisabled = { 0.42, 0.45, 0.50, 1.00 },
    green        = { 0.45, 0.85, 0.52, 1.00 },
    orange       = { 1.00, 0.68, 0.25, 1.00 },
    red          = { 0.96, 0.36, 0.36, 1.00 },
}

Widgets.BACKDROP_SOLID = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local IMPACT_COLORS = {
    ["None"]      = "|cff8892a4None|r",
    ["Low"]       = "|cff66bb6aLow|r",
    ["Medium"]    = "|cffffca28Med|r",
    ["High"]      = "|cffff8a65High|r",
    ["Very High"] = "|cffef5350V.High|r",
}

function Widgets.ApplyBackdrop(frame, bg, border)
    frame:SetBackdrop(Widgets.BACKDROP_SOLID)
    bg = bg or Widgets.COLORS.bgPanel
    border = border or Widgets.COLORS.border
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
end

function Widgets.ShowCVarTooltip(anchor, def, isSupported, isReadOnly)
    if not GameTooltip then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT", 8, 0)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(def.label or def.cvar, 1, 0.82, 0.28)
    GameTooltip:AddLine("CVar: |cff4fc3f7" .. def.cvar .. "|r", 0.8, 0.85, 0.92)

    if isSupported then
        local cur = ns.Engine:Get(def.cvar)
        local defaultVal = ns.Engine:GetDefault(def.cvar)
        GameTooltip:AddDoubleLine("Current Value:", tostring(cur), 0.7, 0.74, 0.8, 1, 1, 1)
        GameTooltip:AddDoubleLine("Blizzard Default:", tostring(defaultVal), 0.7, 0.74, 0.8, 0.8, 0.85, 0.9)
        if def.recommended ~= nil then
            GameTooltip:AddDoubleLine("Beyond Ultra Rec:", tostring(def.recommended), 0.7, 0.74, 0.8, 0.45, 0.85, 0.52)
        end
    else
        GameTooltip:AddLine("Not exposed on this client build.", 0.96, 0.36, 0.36)
    end

    if def.impact then
        GameTooltip:AddDoubleLine("FPS Impact:", IMPACT_COLORS[def.impact] or def.impact, 0.7, 0.74, 0.8, 1, 1, 1)
    end

    if def.desc and def.desc ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(def.desc, 0.9, 0.92, 0.95, true)
    end

    if def.warning then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Warning: " .. def.warning, 1.0, 0.62, 0.22, true)
    end

    if def.requiresGxRestart then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Tip: Click 'Restart GX' or type /reload if display change does not apply immediately.", 0.45, 0.78, 0.98, true)
    end

    if isReadOnly then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("This CVar is currently locked/read-only in this client.", 0.96, 0.36, 0.36, true)
    end

    GameTooltip:Show()
end

function Widgets.HideTooltip()
    if GameTooltip then
        GameTooltip:Hide()
    end
end

-- Styled clean button
function Widgets.CreateButton(parent, width, height, text, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    Widgets.ApplyBackdrop(btn, { 0.14, 0.17, 0.22, 0.95 }, Widgets.COLORS.border)

    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER")
    fs:SetText(text or "")
    fs:SetTextColor(0.94, 0.94, 0.96)
    btn.label = fs

    btn._active = false

    function btn:SetActive(active)
        self._active = active and true or false
        if self._active then
            self:SetBackdropColor(0.24, 0.20, 0.10, 0.98)
            self:SetBackdropBorderColor(0.86, 0.68, 0.26, 1.0)
            self.label:SetTextColor(1.0, 0.86, 0.36)
        else
            self:SetBackdropColor(0.14, 0.17, 0.22, 0.95)
            self:SetBackdropBorderColor(0.26, 0.30, 0.38, 0.90)
            self.label:SetTextColor(0.92, 0.93, 0.96)
        end
    end

    function btn:SetText(t)
        self.label:SetText(t or "")
    end

    btn:SetScript("OnEnter", function(self)
        if not self:IsEnabled() then return end
        if not self._active then
            self:SetBackdropColor(0.20, 0.24, 0.31, 0.98)
            self:SetBackdropBorderColor(0.55, 0.62, 0.74, 1.0)
        end
        if self.tooltipTitle or self.tooltipText then
            GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 4)
            GameTooltip:ClearLines()
            if self.tooltipTitle then
                GameTooltip:AddLine(self.tooltipTitle, 1, 0.82, 0.28)
            end
            if self.tooltipText then
                GameTooltip:AddLine(self.tooltipText, 0.9, 0.92, 0.95, true)
            end
            GameTooltip:Show()
        end
    end)

    btn:SetScript("OnLeave", function(self)
        if not self._active then
            self:SetBackdropColor(0.14, 0.17, 0.22, 0.95)
            self:SetBackdropBorderColor(0.26, 0.30, 0.38, 0.90)
        end
        Widgets.HideTooltip()
    end)

    btn:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() then
            self.label:SetPoint("CENTER", 1, -1)
        end
    end)

    btn:SetScript("OnMouseUp", function(self)
        self.label:SetPoint("CENTER", 0, 0)
    end)

    if onClick then
        btn:SetScript("OnClick", onClick)
    end

    return btn
end

-- Styled clean checkbox
function Widgets.CreateCheckBox(parent, labelText, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
    cb:SetSize(18, 18)
    Widgets.ApplyBackdrop(cb, Widgets.COLORS.bgInput, Widgets.COLORS.border)

    local check = cb:CreateTexture(nil, "OVERLAY")
    check:SetPoint("TOPLEFT", 3, -3)
    check:SetPoint("BOTTOMRIGHT", -3, 3)
    check:SetTexture("Interface\\Buttons\\WHITE8X8")
    check:SetVertexColor(0.31, 0.76, 0.97, 1.0)
    cb:SetCheckedTexture(check)
    cb.checkTex = check

    local hl = cb:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture("Interface\\Buttons\\WHITE8X8")
    hl:SetVertexColor(1, 1, 1, 0.12)

    if labelText then
        local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        fs:SetText(labelText)
        fs:SetTextColor(0.90, 0.92, 0.95)
        cb.label = fs
        cb:SetHitRectInsets(0, -(fs:GetStringWidth() + 10), -2, -2)
    end

    if onChange then
        cb:SetScript("OnClick", function(self)
            onChange(self, self:GetChecked() and true or false)
        end)
    end

    return cb
end

-- Custom lightweight scrollable container (template-free, immune to Blizzard scrollbar API changes)
function Widgets.CreateScrollContainer(parent)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Widgets.ApplyBackdrop(container, { 0.07, 0.08, 0.11, 0.92 }, Widgets.COLORS.border)

    local scrollFrame = CreateFrame("ScrollFrame", nil, container)
    scrollFrame:SetPoint("TOPLEFT", 6, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", -18, 6)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    -- Thin custom vertical scrollbar
    local scrollBar = CreateFrame("Slider", nil, container, "BackdropTemplate")
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetPoint("TOPRIGHT", -4, -6)
    scrollBar:SetPoint("BOTTOMRIGHT", -4, 6)
    scrollBar:SetWidth(10)
    Widgets.ApplyBackdrop(scrollBar, { 0.05, 0.06, 0.08, 0.9 }, { 0.20, 0.24, 0.30, 0.8 })

    local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumb:SetVertexColor(0.42, 0.50, 0.62, 0.85)
    thumb:SetSize(8, 36)
    scrollBar:SetThumbTexture(thumb)
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValue(0)

    scrollBar:SetScript("OnValueChanged", function(_, value)
        scrollFrame:SetVerticalScroll(value)
    end)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local cur = scrollBar:GetValue()
        local minV, maxV = scrollBar:GetMinMaxValues()
        local step = 44
        local nextVal = cur - (delta * step)
        if nextVal < minV then nextVal = minV end
        if nextVal > maxV then nextVal = maxV end
        scrollBar:SetValue(nextVal)
    end)

    scrollFrame:SetScript("OnSizeChanged", function(_, w)
        if w and w > 0 then
            content:SetWidth(w)
        end
    end)

    function container:UpdateScrollRange(contentHeight)
        local rawW = scrollFrame:GetWidth() or 0
        local viewW = (rawW > 50) and rawW or 670
        local rawH = scrollFrame:GetHeight() or 0
        local viewH = (rawH > 50) and rawH or 440
        content:SetWidth(viewW)
        content:SetHeight(math.max(contentHeight, viewH))
        local maxScroll = math.max(0, contentHeight - viewH)
        scrollBar:SetMinMaxValues(0, maxScroll)
        if scrollBar:GetValue() > maxScroll then
            scrollBar:SetValue(maxScroll)
        end
        if maxScroll <= 0 then
            scrollBar:Hide()
        else
            scrollBar:Show()
            local thumbH = math.max(24, math.min(viewH * 0.8, (viewH / contentHeight) * viewH))
            thumb:SetHeight(thumbH)
        end
    end

    function container:ResetScroll()
        scrollBar:SetValue(0)
        scrollFrame:SetVerticalScroll(0)
    end

    container.scrollFrame = scrollFrame
    container.scrollBar = scrollBar
    container.content = content
    return container
end

-------------------------------------------------------------------------------
-- SHARED POPUP DROPDOWN MENU (Taint-free, auto-dismissing)
-------------------------------------------------------------------------------
local dropdownMenu = nil

local function GetDropdownMenu()
    if dropdownMenu then return dropdownMenu end
    local menu = CreateFrame("Frame", "ForeverOpticsDropdownMenu", UIParent, "BackdropTemplate")
    menu:SetFrameStrata("TOOLTIP")
    menu:SetClampedToScreen(true)
    Widgets.ApplyBackdrop(menu, { 0.08, 0.10, 0.13, 0.98 }, Widgets.COLORS.borderGold)
    menu:Hide()
    menu.buttons = {}

    -- Click-away catcher frame
    local catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:Hide()
    catcher:SetScript("OnClick", function()
        menu:Hide()
    end)
    menu.catcher = catcher

    menu:SetScript("OnHide", function()
        catcher:Hide()
    end)

    menu:SetScript("OnShow", function()
        catcher:Show()
    end)

    dropdownMenu = menu
    return menu
end

function Widgets.ShowDropdownMenu(anchor, options, currentValue, onSelect)
    local menu = GetDropdownMenu()
    if menu:IsShown() and menu.owner == anchor then
        menu:Hide()
        return
    end
    menu.owner = anchor

    for _, b in ipairs(menu.buttons) do
        b:Hide()
    end

    local rowH = 22
    local width = math.max(anchor:GetWidth() or 200, 210)
    for i, opt in ipairs(options) do
        local btn = menu.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, menu, "BackdropTemplate")
            btn:SetHeight(rowH)
            local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs:SetPoint("LEFT", 8, 0)
            fs:SetPoint("RIGHT", -8, 0)
            fs:SetJustifyH("LEFT")
            btn.label = fs

            local hl = btn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetTexture("Interface\\Buttons\\WHITE8X8")
            hl:SetVertexColor(0.31, 0.76, 0.97, 0.20)
            menu.buttons[i] = btn
        end

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", 4, -4 - (i - 1) * rowH)
        btn:SetWidth(width - 8)
        btn.label:SetText(opt.label)

        local isSelected = ns.Engine:ValuesEqual(currentValue, opt.value)
        if isSelected then
            btn.label:SetTextColor(1.0, 0.84, 0.30)
        else
            btn.label:SetTextColor(0.90, 0.92, 0.95)
        end

        btn:SetScript("OnClick", function()
            menu:Hide()
            if onSelect then
                onSelect(opt.value, opt.label)
            end
        end)
        btn:Show()
    end

    menu:SetSize(width, (#options * rowH) + 8)
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    menu:Show()
end

function Widgets.CloseDropdownMenu()
    if dropdownMenu and dropdownMenu:IsShown() then
        dropdownMenu:Hide()
    end
end

-------------------------------------------------------------------------------
-- SECTION HEADER
-------------------------------------------------------------------------------
function Widgets.CreateSectionHeader(parent, titleText)
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(24)

    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("LEFT", 2, -2)
    fs:SetText(titleText)
    fs:SetTextColor(1.0, 0.82, 0.28)

    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("LEFT", fs, "RIGHT", 8, 0)
    line:SetPoint("RIGHT", -2, 0)
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetVertexColor(0.78, 0.62, 0.26, 0.35)

    return f
end

-------------------------------------------------------------------------------
-- UNIFIED CVAR CONTROL ROW CARD (Slider / Toggle / Dropdown)
-------------------------------------------------------------------------------
function Widgets.CreateCVarRow(parent, def)
    local rowHeight = (def.type == "slider") and 56 or 42
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(rowHeight)
    Widgets.ApplyBackdrop(row, Widgets.COLORS.bgCard, { 0.20, 0.24, 0.31, 0.75 })
    row.def = def

    -- Left modified gold bar indicator
    local modBar = row:CreateTexture(nil, "OVERLAY")
    modBar:SetPoint("TOPLEFT", 1, -1)
    modBar:SetPoint("BOTTOMLEFT", 1, 1)
    modBar:SetWidth(3)
    modBar:SetTexture("Interface\\Buttons\\WHITE8X8")
    modBar:SetVertexColor(1.0, 0.82, 0.28, 1.0)
    modBar:Hide()
    row.modBar = modBar

    -- Title + CVar tag
    local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 10, -7)
    title:SetJustifyH("LEFT")
    title:SetText(def.label)
    title:SetTextColor(0.95, 0.96, 0.98)
    row.title = title

    -- Subline: CVar name + default/recommended comparison + impact badge
    local meta = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    meta:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    meta:SetJustifyH("LEFT")
    meta:SetTextColor(0.58, 0.63, 0.72)
    row.meta = meta

    -- Per-row Default Reset Button (far right)
    local resetBtn = Widgets.CreateButton(row, 48, 20, "Def", function()
        ns.Engine:ResetCVar(def.cvar)
    end)
    resetBtn:SetPoint("TOPRIGHT", -8, -10)
    resetBtn.tooltipTitle = "Reset to Blizzard Default"
    resetBtn.tooltipText = "Restores " .. def.cvar .. " to its client default value."
    row.resetBtn = resetBtn

    -- Hover highlight & tooltip
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.18, 0.24, 0.95)
        Widgets.ShowCVarTooltip(self, def, ns.Engine:Exists(def.cvar), ns.Engine:IsReadOnly(def.cvar))
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.14, 0.18, 0.88)
        Widgets.HideTooltip()
    end)

    -- Control-specific widgets
    if def.type == "slider" then
        -- Exact numeric EditBox
        local editBox = CreateFrame("EditBox", nil, row, "BackdropTemplate")
        editBox:SetSize(64, 20)
        editBox:SetPoint("RIGHT", resetBtn, "LEFT", -6, 0)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject("GameFontHighlightSmall")
        editBox:SetJustifyH("CENTER")
        Widgets.ApplyBackdrop(editBox, Widgets.COLORS.bgInput, Widgets.COLORS.border)
        row.editBox = editBox

        -- Custom horizontal slider
        local slider = CreateFrame("Slider", nil, row, "BackdropTemplate")
        slider:SetOrientation("HORIZONTAL")
        slider:SetSize(195, 14)
        slider:SetPoint("RIGHT", editBox, "LEFT", -10, 0)
        slider:SetMinMaxValues(def.min, def.max)
        slider:SetValueStep(def.step or 1)
        slider:SetObeyStepOnDrag(true)
        Widgets.ApplyBackdrop(slider, { 0.05, 0.06, 0.09, 1.0 }, { 0.25, 0.30, 0.38, 0.9 })

        local fill = slider:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", 1, -1)
        fill:SetPoint("BOTTOMLEFT", 1, 1)
        fill:SetWidth(1)
        fill:SetTexture("Interface\\Buttons\\WHITE8X8")
        fill:SetVertexColor(0.31, 0.76, 0.97, 0.45)
        slider.fill = fill

        local thumb = slider:CreateTexture(nil, "OVERLAY")
        thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
        thumb:SetVertexColor(0.95, 0.80, 0.32, 1.0)
        thumb:SetSize(10, 16)
        slider:SetThumbTexture(thumb)
        row.slider = slider

        local minLbl = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        minLbl:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
        minLbl:SetText(ns.Engine:FormatValue(def.min, def.decimals))
        minLbl:SetTextColor(0.50, 0.55, 0.64)

        local maxLbl = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        maxLbl:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
        maxLbl:SetText(ns.Engine:FormatValue(def.max, def.decimals))
        maxLbl:SetTextColor(0.50, 0.55, 0.64)

        local function UpdateFill(val)
            local range = (def.max - def.min)
            local pct = (range > 0) and math.max(0, math.min(1, (val - def.min) / range)) or 0
            fill:SetWidth(math.max(1, pct * (slider:GetWidth() - 2)))
        end

        slider._updating = false
        slider:SetScript("OnValueChanged", function(self, val, userInput)
            UpdateFill(val)
            if self._updating then return end
            -- Snap to step
            local step = def.step or 1
            local snapped = math.floor((val / step) + 0.5) * step
            local formatted = ns.Engine:FormatValue(snapped, def.decimals)
            editBox:SetText(formatted)
            if userInput then
                self._pendingVal = formatted
            end
        end)

        slider:SetScript("OnMouseUp", function(self)
            if self._pendingVal ~= nil then
                local v = self._pendingVal
                self._pendingVal = nil
                ns.Engine:Set(def.cvar, v)
            end
        end)

        editBox:SetScript("OnEnterPressed", function(self)
            local raw = self:GetText()
            local num = tonumber(raw)
            if num ~= nil then
                ns.Engine:Set(def.cvar, ns.Engine:FormatValue(num, def.decimals))
            else
                row:Refresh()
            end
            self:ClearFocus()
        end)

        editBox:SetScript("OnEscapePressed", function(self)
            row:Refresh()
            self:ClearFocus()
        end)

        row.UpdateFill = UpdateFill

    elseif def.type == "toggle" then
        local cb = Widgets.CreateCheckBox(row, nil, function(_, checked)
            ns.Engine:Set(def.cvar, checked and "1" or "0")
        end)
        cb:SetPoint("RIGHT", resetBtn, "LEFT", -14, 0)
        row.checkbox = cb

        local stateLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        stateLbl:SetPoint("RIGHT", cb, "LEFT", -8, 0)
        row.stateLbl = stateLbl

    elseif def.type == "dropdown" then
        local dd = Widgets.CreateButton(row, 235, 22, "Select...", function(self)
            local cur = ns.Engine:Get(def.cvar)
            Widgets.ShowDropdownMenu(self, def.options, cur, function(val)
                ns.Engine:Set(def.cvar, val)
            end)
        end)
        dd:SetPoint("RIGHT", resetBtn, "LEFT", -8, 0)
        dd.label:ClearAllPoints()
        dd.label:SetPoint("LEFT", 8, 0)
        dd.label:SetPoint("RIGHT", -18, 0)
        dd.label:SetJustifyH("LEFT")

        local arrow = dd:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        arrow:SetPoint("RIGHT", -6, 0)
        arrow:SetText("v")
        arrow:SetTextColor(0.8, 0.7, 0.35)
        row.dropdown = dd
    end

    function row:Refresh()
        local exists = ns.Engine:Exists(def.cvar)
        local readOnly = exists and ns.Engine:IsReadOnly(def.cvar) or false

        -- Dependency grey-out check
        local depDisabled = false
        if def.dependsOn and ns.Engine:Exists(def.dependsOn) then
            local depVal = ns.Engine:Get(def.dependsOn)
            if ns.Engine:ValuesEqual(depVal, "0") then
                depDisabled = true
            end
        end

        local curVal = exists and ns.Engine:Get(def.cvar) or nil
        local defVal = exists and ns.Engine:GetDefault(def.cvar) or nil
        local isModified = exists and ns.Engine:IsModified(def.cvar)
        local isPending = ns.Engine.pendingQueue[def.cvar] ~= nil

        -- Update metadata line
        local impactTxt = def.impact and (" | " .. (IMPACT_COLORS[def.impact] or def.impact)) or ""
        local defTxt = defVal and (" | Def: " .. ns.Engine:FormatValue(defVal, def.decimals)) or ""
        local recTxt = (def.recommended ~= nil) and (" | Rec: |cff66bb6a" .. tostring(def.recommended) .. "|r") or ""
        local pendingTxt = isPending and " |cffffd54f[Queued]|r" or ""
        if not exists then
            meta:SetText("|cff4fc3f7" .. def.cvar .. "|r  |cffef5350[Not in client build]|r")
        else
            meta:SetText("|cff4fc3f7" .. def.cvar .. "|r" .. defTxt .. recTxt .. impactTxt .. pendingTxt)
        end

        if isModified then
            modBar:Show()
            title:SetTextColor(1.0, 0.88, 0.45)
        else
            modBar:Hide()
            title:SetTextColor(0.95, 0.96, 0.98)
        end

        local interactive = exists and (not readOnly) and (not depDisabled)
        row:SetAlpha(interactive and 1.0 or (exists and 0.55 or 0.40))
        resetBtn:SetEnabled(exists and not readOnly and isModified)
        resetBtn:SetAlpha((exists and not readOnly and isModified) and 1.0 or 0.35)

        if def.type == "slider" then
            local num = tonumber(curVal) or def.min
            local clamped = math.max(def.min, math.min(def.max, num))
            row.slider._updating = true
            row.slider:SetValue(clamped)
            row.slider._updating = false
            row.UpdateFill(clamped)
            row.editBox:SetText(exists and ns.Engine:FormatValue(curVal, def.decimals) or "N/A")
            row.slider:SetEnabled(interactive)
            row.editBox:SetEnabled(interactive)
        elseif def.type == "toggle" then
            local isOn = exists and not ns.Engine:ValuesEqual(curVal, "0")
            row.checkbox:SetChecked(isOn)
            row.checkbox:SetEnabled(interactive)
            if not exists then
                row.stateLbl:SetText("N/A")
                row.stateLbl:SetTextColor(0.5, 0.5, 0.5)
            elseif isOn then
                row.stateLbl:SetText("ON")
                row.stateLbl:SetTextColor(0.45, 0.85, 0.52)
            else
                row.stateLbl:SetText("OFF")
                row.stateLbl:SetTextColor(0.62, 0.66, 0.74)
            end
        elseif def.type == "dropdown" then
            row.dropdown:SetEnabled(interactive)
            if not exists then
                row.dropdown:SetText("Unavailable")
            else
                local matchedLabel = nil
                for _, opt in ipairs(def.options) do
                    if ns.Engine:ValuesEqual(curVal, opt.value) then
                        matchedLabel = opt.label
                        break
                    end
                end
                row.dropdown:SetText(matchedLabel or ("Custom (" .. tostring(curVal) .. ")"))
            end
        end
    end

    return row
end
