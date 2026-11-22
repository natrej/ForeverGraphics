local _, ns = ...

local FPSOverlay = {}
ns.FPSOverlay = FPSOverlay

local frame = nil
local samples = {}
local SAMPLE_WINDOW = 5.0
local elapsedAccum = 0
local UPDATE_INTERVAL = 0.25

-- Before/after delta state
local deltaPending = nil

function FPSOverlay:Create()
    if frame then return frame end

    local f = CreateFrame("Frame", "ForeverOpticsFPSOverlay", UIParent, "BackdropTemplate")
    f:SetSize(215, 76)
    f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -220, -24)
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local db = ns.Engine:GetDB()
        local point, _, relPoint, x, y = self:GetPoint()
        db.fpsPos = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    ns.Widgets.ApplyBackdrop(f, { 0.05, 0.06, 0.09, 0.90 }, ns.Widgets.COLORS.borderGold)

    local header = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetPoint("TOPLEFT", 8, -6)
    header:SetText("ForeverOptics FPS")
    header:SetTextColor(1.0, 0.82, 0.28)

    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", -5, -4)
    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    closeTxt:SetPoint("CENTER")
    closeTxt:SetText("x")
    closeTxt:SetTextColor(0.75, 0.78, 0.85)
    closeBtn:SetScript("OnClick", function()
        FPSOverlay:SetShown(false)
    end)

    local fpsLine = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fpsLine:SetPoint("TOPLEFT", 8, -22)
    fpsLine:SetJustifyH("LEFT")
    f.fpsLine = fpsLine

    local statsLine = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statsLine:SetPoint("TOPLEFT", 8, -40)
    statsLine:SetJustifyH("LEFT")
    statsLine:SetTextColor(0.72, 0.76, 0.84)
    f.statsLine = statsLine

    local deltaLine = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    deltaLine:SetPoint("TOPLEFT", 8, -56)
    deltaLine:SetPoint("RIGHT", -8, 0)
    deltaLine:SetJustifyH("LEFT")
    deltaLine:SetText("Drag to move | Adjust any CVar to measure")
    deltaLine:SetTextColor(0.55, 0.62, 0.72)
    f.deltaLine = deltaLine

    -- Restore saved position
    local db = ns.Engine:GetDB()
    if db.fpsPos and db.fpsPos.point then
        f:ClearAllPoints()
        f:SetPoint(db.fpsPos.point, UIParent, db.fpsPos.relPoint or db.fpsPos.point, db.fpsPos.x or 0, db.fpsPos.y or 0)
    end

    f:SetScript("OnUpdate", function(_, dt)
        local now = GetTime and GetTime() or 0
        local fps = GetFramerate and GetFramerate() or 0
        if fps > 0 then
            table.insert(samples, { t = now, fps = fps })
        end
        -- Trim rolling window
        while #samples > 0 and (now - samples[1].t) > SAMPLE_WINDOW do
            table.remove(samples, 1)
        end

        elapsedAccum = elapsedAccum + dt
        if elapsedAccum < UPDATE_INTERVAL then return end
        elapsedAccum = 0

        local sum, minFps, count = 0, 99999, #samples
        for i = 1, count do
            local v = samples[i].fps
            sum = sum + v
            if v < minFps then minFps = v end
        end
        local avgFps = (count > 0) and (sum / count) or fps
        if count == 0 then minFps = fps end

        local frameMs = (fps > 0) and (1000.0 / fps) or 0
        local fpsColor = "|cff66bb6a"
        if fps < 30 then
            fpsColor = "|cffef5350"
        elseif fps < 55 then
            fpsColor = "|cffffca28"
        end

        local _, _, homeMs, worldMs = 0, 0, 0, 0
        if GetNetStats then
            _, _, homeMs, worldMs = GetNetStats()
        end

        fpsLine:SetText(string.format("%s%.1f FPS|r  |cff90a4ae(%.1f ms)|r", fpsColor, fps, frameMs))
        statsLine:SetText(string.format("Avg: %.1f  Min: %.1f  Ping: %dms", avgFps, minFps, worldMs or homeMs or 0))
    end)

    frame = f
    if db.settings.showFPSOverlay then
        f:Show()
    else
        f:Hide()
    end
    return f
end

function FPSOverlay:GetRollingAverageFPS()
    if #samples == 0 then
        return GetFramerate and GetFramerate() or 0
    end
    local sum = 0
    for i = 1, #samples do
        sum = sum + samples[i].fps
    end
    return sum / #samples
end

function FPSOverlay:BeginDeltaSample(label, oldVal, newVal)
    local db = ns.Engine:GetDB()
    if not db.settings.measureFPSDelta then return end
    if not (C_Timer and C_Timer.After) then return end

    local beforeFps = self:GetRollingAverageFPS()
    if beforeFps <= 0 then return end

    local token = {}
    deltaPending = token

    if frame and frame:IsShown() then
        frame.deltaLine:SetText("|cffffd54fMeasuring FPS impact...|r")
    end

    -- Wait 2 seconds for frame rate to settle after CVar change
    C_Timer.After(2.0, function()
        if deltaPending ~= token then return end
        local afterFps = GetFramerate and GetFramerate() or 0
        if afterFps <= 0 then return end
        local diff = afterFps - beforeFps
        local pct = (beforeFps > 0) and ((diff / beforeFps) * 100) or 0
        local sign = diff >= 0 and "+" or ""
        local color = diff >= 0 and "|cff66bb6a" or "|cffef5350"
        local summary = string.format(
            "%s: %.0f -> %.0f FPS (%s%s%.1f%%|r)",
            tostring(label), beforeFps, afterFps, color, sign, pct
        )
        if frame and frame:IsShown() then
            frame.deltaLine:SetText(summary)
        end
    end)
end

function FPSOverlay:SetShown(shown)
    local db = ns.Engine:GetDB()
    db.settings.showFPSOverlay = shown and true or false
    local f = self:Create()
    if db.settings.showFPSOverlay then
        f:Show()
    else
        f:Hide()
    end
end

function FPSOverlay:Toggle()
    local db = ns.Engine:GetDB()
    self:SetShown(not db.settings.showFPSOverlay)
end
