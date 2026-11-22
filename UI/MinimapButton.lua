local _, ns = ...

local MinimapBtn = {}
ns.MinimapBtn = MinimapBtn

local button = nil
local MINIMAP_RADIUS = 80

local function UpdateButtonPosition(angleDeg)
    if not button then return end
    local rad = math.rad(angleDeg or 220)
    local x = math.cos(rad) * MINIMAP_RADIUS
    local y = math.sin(rad) * MINIMAP_RADIUS
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function OpenQuickMenu(anchor)
    local options = {
        { value = "open",        label = "Open ForeverOptics Panel" },
        { value = "fps",         label = "Toggle FPS Overlay" },
        { value = "performance", label = "Preset: Performance" },
        { value = "balanced",    label = "Preset: Balanced" },
        { value = "blizzard_max",label = "Preset: Blizzard 10" },
        { value = "beyond_ultra",label = "Preset: Beyond Ultra" },
        { value = "classic_look",label = "Preset: Classic Look" },
        { value = "handheld",    label = "Preset: Handheld / Deck" },
    }
    for slotIdx = 1, 2 do
        local slot = ns.Engine:GetCustomSlot(slotIdx)
        if slot then
            table.insert(options, {
                value = "slot_" .. slotIdx,
                label = string.format("Load Slot %d (%d CVars)", slotIdx, slot.count or 0),
            })
        end
    end
    table.insert(options, { value = "hdr",         label = "Open HDR10 Calibration" })
    table.insert(options, { value = "explorer",    label = "Open Live CVar Explorer" })
    table.insert(options, { value = "undo",        label = "Undo Last Preset" })
    table.insert(options, { value = "restart",     label = "Restart Graphics Engine" })
    table.insert(options, { value = "hide_minimap",label = "|cffff8a65Hide Minimap Icon|r" })

    ns.Widgets.ShowDropdownMenu(anchor, options, nil, function(choice)
        if choice == "open" then
            ns.MainFrame:Toggle()
        elseif choice == "fps" then
            ns.FPSOverlay:Toggle()
        elseif choice == "hdr" then
            ns.MainFrame:ShowTab("hdr")
        elseif choice == "explorer" then
            ns.MainFrame:ShowTab("explorer")
        elseif choice == "undo" then
            ns.Engine:UndoLastPreset()
        elseif choice == "restart" then
            ns.Engine:RestartGraphics()
        elseif choice == "hide_minimap" then
            MinimapBtn:SetShown(false)
            ns.Print("Minimap icon hidden. Re-enable anytime in |cffffd54f/fo|r or Options -> AddOns -> ForeverOptics.")
        elseif choice == "slot_1" then
            ns.Engine:LoadCustomSlot(1)
        elseif choice == "slot_2" then
            ns.Engine:LoadCustomSlot(2)
        else
            ns.Engine:ApplyPreset(choice)
        end
    end)
end

function MinimapBtn:Create()
    if button or not Minimap then return button end

    local btn = CreateFrame("Button", "ForeverOpticsMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetPoint("CENTER")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_03")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    btn:SetScript("OnClick", function(self, mouseBtn)
        if mouseBtn == "RightButton" then
            OpenQuickMenu(self)
        else
            ns.MainFrame:Toggle()
        end
    end)

    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            local angle = math.deg(math.atan2(cy - my, cx - mx))
            ns.Engine:GetDB().settings.minimapAngle = angle
            UpdateButtonPosition(angle)
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("ForeverOptics by " .. ns.ADDON_AUTHOR, 1, 0.82, 0.28)
        GameTooltip:AddLine("Left-Click: Open Graphics Control Panel", 0.9, 0.92, 0.95)
        GameTooltip:AddLine("Right-Click: Quick Presets & Tools", 0.9, 0.92, 0.95)
        GameTooltip:AddLine("Drag: Move around Minimap", 0.65, 0.70, 0.78)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        ns.Widgets.HideTooltip()
    end)

    button = btn
    local db = ns.Engine:GetDB()
    UpdateButtonPosition(db.settings.minimapAngle)
    self:SetShown(db.settings.showMinimapButton)
    return btn
end

function MinimapBtn:SetShown(shown)
    local db = ns.Engine:GetDB()
    db.settings.showMinimapButton = shown and true or false
    if button then
        if db.settings.showMinimapButton then
            button:Show()
        else
            button:Hide()
        end
    end
    if self.optionsMinimapCB then
        self.optionsMinimapCB:SetChecked(db.settings.showMinimapButton)
    end
    ns.Engine:NotifyListeners(nil, nil, "minimap")
end

function MinimapBtn:Toggle()
    local db = ns.Engine:GetDB()
    self:SetShown(not db.settings.showMinimapButton)
end

-- Register inside Blizzard Options -> AddOns -> ForeverOptics
function MinimapBtn:RegisterOptionsPanel()
    local panel = CreateFrame("Frame", "ForeverOpticsOptionsLauncher")
    panel.name = "ForeverOptics"

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("ForeverOptics by " .. ns.ADDON_AUTHOR .. "  v" .. ns.ADDON_VERSION)
    title:SetTextColor(1.0, 0.82, 0.28)

    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(540)
    desc:SetJustifyH("LEFT")
    desc:SetText("Exposes and controls all hidden graphics CVars in World of Warcraft: Forever, including Beyond Ultra view distances, dense grass, shadow cascades, HDR10 calibration, FPS monitoring, and a live client CVar explorer.")

    local openBtn = ns.Widgets.CreateButton(panel, 220, 30, "Open ForeverOptics Panel", function()
        if HideUIPanel and SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
        end
        ns.MainFrame:Toggle()
    end)
    openBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -18)

    local explorerBtn = ns.Widgets.CreateButton(panel, 220, 30, "Open Live Client CVar Explorer", function()
        if HideUIPanel and SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
        end
        ns.MainFrame:ShowTab("explorer")
    end)
    explorerBtn:SetPoint("LEFT", openBtn, "RIGHT", 12, 0)

    local minimapCB = ns.Widgets.CreateCheckBox(panel, "Show Minimap Icon", function(_, checked)
        MinimapBtn:SetShown(checked)
    end)
    minimapCB:SetPoint("TOPLEFT", openBtn, "BOTTOMLEFT", 0, -18)
    minimapCB:SetChecked(ns.Engine:GetDB().settings.showMinimapButton)
    self.optionsMinimapCB = minimapCB

    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", minimapCB, "BOTTOMLEFT", 0, -16)
    hint:SetText("Slash commands:  |cff4fc3f7/fo|r  |  |cff4fc3f7/fo save 1|r  |  |cff4fc3f7/fo load 1|r  |  |cff4fc3f7/fo minimap|r  |  |cff4fc3f7/fo help|r")
    hint:SetTextColor(0.75, 0.80, 0.88)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "ForeverOptics")
        Settings.RegisterAddOnCategory(category)
        ns.settingsCategory = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

-------------------------------------------------------------------------------
-- BLIZZARD ADDON COMPARTMENT GLOBAL CALLBACKS (referenced in .toc)
-------------------------------------------------------------------------------
function ForeverOptics_OnAddonCompartmentClick(_, mouseButton)
    if mouseButton == "RightButton" then
        ns.FPSOverlay:Toggle()
    else
        ns.MainFrame:Toggle()
    end
end

function ForeverOptics_OnAddonCompartmentEnter(_, menuButtonFrame)
    if not GameTooltip then return end
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("ForeverOptics by " .. ns.ADDON_AUTHOR, 1, 0.82, 0.28)
    GameTooltip:AddLine("Left-Click: Open Hidden Graphics Panel", 0.9, 0.92, 0.95)
    GameTooltip:AddLine("Right-Click: Toggle FPS Overlay", 0.9, 0.92, 0.95)
    GameTooltip:Show()
end

function ForeverOptics_OnAddonCompartmentLeave()
    ns.Widgets.HideTooltip()
end
