local addonName, ns = ...

local eventFrame = CreateFrame("Frame", "ForeverGraphicsEventFrame")

local function SafeRegisterEvent(f, event)
    pcall(f.RegisterEvent, f, event)
end

SafeRegisterEvent(eventFrame, "ADDON_LOADED")
SafeRegisterEvent(eventFrame, "PLAYER_ENTERING_WORLD")
SafeRegisterEvent(eventFrame, "PLAYER_REGEN_ENABLED")
SafeRegisterEvent(eventFrame, "CVAR_UPDATE")

local loginApplied = false

eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 ~= addonName then return end
        ns.Engine:GetDB()
        ns.FPSOverlay:Create()
        ns.MinimapBtn:Create()
        ns.MinimapBtn:RegisterOptionsPanel()
        ns.Print("Loaded v" .. ns.ADDON_VERSION .. ". Type |cffffd54f/fg|r or click the minimap spyglass to open.")

    elseif event == "PLAYER_ENTERING_WORLD" then
        local db = ns.Engine:GetDB()
        if db.settings.reapplyOnLogin and not loginApplied then
            loginApplied = true
            -- Delay slightly so server-synced CVars finish loading before we re-apply overrides
            if C_Timer and C_Timer.After then
                C_Timer.After(2.0, function()
                    if ns.Engine:GetDB().settings.reapplyOnLogin then
                        ns.Engine:ReapplySaved(true)
                    end
                end)
            else
                ns.Engine:ReapplySaved(true)
            end
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.Engine:FlushCombatQueue()

    elseif event == "CVAR_UPDATE" then
        ns.Engine:OnExternalCVarUpdate(arg1, arg2)
    end
end)

-------------------------------------------------------------------------------
-- SLASH COMMANDS: /fg and /forevergraphics
-------------------------------------------------------------------------------
local function PrintHelp()
    ns.Print("Commands:")
    ns.Print("  |cffffd54f/fg|r — Toggle main hidden graphics panel")
    ns.Print("  |cffffd54f/fg explorer|r — Open Live Client CVar Explorer (all engine CVars)")
    ns.Print("  |cffffd54f/fg hdr|r — Open HDR10 & Display Calibration tab")
    ns.Print("  |cffffd54f/fg preset <name>|r — Apply preset (performance, balanced, blizzard_max, beyond_ultra, classic_look, handheld)")
    ns.Print("  |cffffd54f/fg undo|r — Undo last applied preset")
    ns.Print("  |cffffd54f/fg apply|r — Re-apply all saved CVar overrides now")
    ns.Print("  |cffffd54f/fg backup|r — Restore original pre-addon CVar values")
    ns.Print("  |cffffd54f/fg reset|r — Reset all managed CVars to Blizzard defaults")
    ns.Print("  |cffffd54f/fg fps|r — Toggle live FPS & frame-time overlay")
    ns.Print("  |cffffd54f/fg minimap|r — Show/hide minimap button")
    ns.Print("  |cffffd54f/fg restart|r — Restart graphics engine")
    ns.Print("  |cffffd54f/fg get <cvar>|r — Print current and default value of a CVar")
    ns.Print("  |cffffd54f/fg set <cvar> <val>|r — Safely set any CVar (with crash caps & combat queue)")
    ns.Print("  |cffffd54f/fg scan [word]|r — List matching client graphics CVars")
    ns.Print("  |cffffd54f/fg snap|r / |cffffd54f/fg diff|r — Snapshot & diff all client CVars")
end

local function Trim(s)
    return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

SLASH_FOREVERGRAPHICS1 = "/fg"
SLASH_FOREVERGRAPHICS2 = "/forevergraphics"

SlashCmdList["FOREVERGRAPHICS"] = function(msg)
    local cleaned = Trim(msg)
    if cleaned == "" then
        ns.MainFrame:Toggle()
        return
    end

    local cmd, rest = cleaned:match("^(%S+)%s*(.*)$")
    cmd = string.lower(cmd or "")
    rest = Trim(rest)

    if cmd == "help" or cmd == "?" then
        PrintHelp()
    elseif cmd == "explorer" or cmd == "all" then
        ns.MainFrame:ShowTab("explorer")
    elseif cmd == "hdr" then
        ns.MainFrame:ShowTab("hdr")
    elseif cmd == "fps" then
        ns.FPSOverlay:Toggle()
    elseif cmd == "minimap" then
        ns.MinimapBtn:Toggle()
    elseif cmd == "apply" or cmd == "reapply" then
        ns.Engine:ReapplySaved(false)
    elseif cmd == "undo" then
        ns.Engine:UndoLastPreset()
    elseif cmd == "reset" then
        ns.Engine:ResetAllToBlizzardDefault()
    elseif cmd == "backup" or cmd == "restore" then
        ns.Engine:RestoreBackup()
    elseif cmd == "restart" or cmd == "gx" then
        ns.Engine:RestartGraphics()
    elseif cmd == "snap" or cmd == "snapshot" then
        ns.Engine:TakeSnapshot()
    elseif cmd == "diff" then
        ns.Engine:DiffSnapshot()
    elseif cmd == "preset" then
        if rest == "" then
            ns.Print("Usage: /fg preset <performance|balanced|blizzard_max|beyond_ultra|classic_look|handheld>")
        else
            ns.Engine:ApplyPreset(string.lower(rest))
        end
    elseif cmd == "get" then
        if rest == "" then
            ns.Print("Usage: /fg get <cvar>")
        elseif not ns.Engine:Exists(rest) then
            ns.Print("|cffff5252Not found:|r CVar '" .. rest .. "' does not exist on this client.")
        else
            ns.Print(string.format(
                "|cff4fc3f7%s|r = |cffffd54f%s|r  (Default: %s)",
                rest, tostring(ns.Engine:Get(rest)), tostring(ns.Engine:GetDefault(rest))
            ))
        end
    elseif cmd == "set" then
        local cvar, val = rest:match("^(%S+)%s+(.+)$")
        if not cvar or not val then
            ns.Print("Usage: /fg set <cvar> <value>")
        else
            local ok, actual = ns.Engine:Set(cvar, val)
            if ok and actual ~= "queued" then
                ns.Print(string.format("Set |cff4fc3f7%s|r = |cff66bb6a%s|r", cvar, tostring(actual)))
            end
        end
    elseif cmd == "scan" then
        local needle = string.lower(rest)
        local all = ns.Engine:ScanAllClientCVars(false)
        local matches = {}
        for _, entry in ipairs(all) do
            if entry.isGraphics or needle ~= "" then
                if needle == "" or string.find(string.lower(entry.command .. " " .. (entry.help or "")), needle, 1, true) then
                    table.insert(matches, entry)
                end
            end
        end
        ns.Print(string.format("Found %d matching CVar(s)%s:", #matches, #matches > 25 and " (showing first 25; use /fg explorer for full list)" or ""))
        for i = 1, math.min(25, #matches) do
            local e = matches[i]
            ns.Print(string.format("  |cff4fc3f7%s|r = %s (def: %s)", e.command, tostring(ns.Engine:Get(e.command)), tostring(ns.Engine:GetDefault(e.command))))
        end
    else
        ns.Print("Unknown subcommand '" .. cmd .. "'. Type |cffffd54f/fg help|r for all commands.")
    end
end
