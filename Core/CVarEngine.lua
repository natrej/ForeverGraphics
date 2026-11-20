local _, ns = ...

local Engine = {}
ns.Engine = Engine

Engine.pendingQueue = {}
Engine.listeners = {}
Engine.snapshot = nil
Engine.isApplyingInternal = false
Engine.cachedClientCVars = nil

-- Graphics-related CVar name patterns for supplementing Enum.ConsoleCategory.Graphics
local GRAPHICS_KEYWORDS = {
    "^gx", "graphics", "shadow", "water", "reflection", "ripple", "refraction",
    "fog", "volumefog", "sunshaft", "skycloud", "weather", "groundeffect",
    "terrain", "farclip", "horizon", "wmo", "lod", "doodad", "entity",
    "particle", "spellclutter", "spellvisual", "physics", "bodyquota",
    "outline", "resample", "renderscale", "renderformat", "ffx", "msaa",
    "ssao", "gi", "light", "bloom", "glow", "brightness", "contrast", "gamma",
    "hdr", "colorblind", "texture", "mip", "vrs", "fps", "vsync", "triplebuffer",
    "lowlatency", "camera", "projected", "clustered", "softtarget", "violence",
    "depth", "compute", "aniso", "antialias", "shader", "rt", "raytrac",
}

local function ChatPrint(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff4fc3f7[Forever Graphics]|r " .. tostring(msg))
    end
end
ns.Print = ChatPrint

local function RawGetCVar(cvar)
    if C_CVar and C_CVar.GetCVar then
        local ok, val = pcall(C_CVar.GetCVar, cvar)
        if ok then return val end
    elseif GetCVar then
        local ok, val = pcall(GetCVar, cvar)
        if ok then return val end
    end
    return nil
end

local function RawGetCVarDefault(cvar)
    if C_CVar and C_CVar.GetCVarDefault then
        local ok, val = pcall(C_CVar.GetCVarDefault, cvar)
        if ok then return val end
    elseif GetCVarDefault then
        local ok, val = pcall(GetCVarDefault, cvar)
        if ok then return val end
    end
    return nil
end

local function RawSetCVar(cvar, value)
    local strVal = tostring(value)
    if C_CVar and C_CVar.SetCVar then
        local ok, res = pcall(C_CVar.SetCVar, cvar, strVal)
        return ok and (res ~= false)
    elseif SetCVar then
        local ok, res = pcall(SetCVar, cvar, strVal)
        return ok and (res ~= false)
    end
    return false
end

local function RawGetCVarInfo(cvar)
    if C_CVar and C_CVar.GetCVarInfo then
        local ok, value, defaultValue, isServerAccount, isServerChar, isLockedFromUser, isSecure, isReadOnly =
            pcall(C_CVar.GetCVarInfo, cvar)
        if ok and value ~= nil then
            return {
                value = value,
                defaultValue = defaultValue,
                isLockedFromUser = isLockedFromUser,
                isSecure = isSecure,
                isReadOnly = isReadOnly,
            }
        end
    end
    local val = RawGetCVar(cvar)
    if val ~= nil then
        return {
            value = val,
            defaultValue = RawGetCVarDefault(cvar),
            isLockedFromUser = false,
            isSecure = false,
            isReadOnly = false,
        }
    end
    return nil
end

function Engine:ValuesEqual(a, b)
    if a == b then return true end
    if a == nil or b == nil then return false end
    local na, nb = tonumber(a), tonumber(b)
    if na and nb then
        return math.abs(na - nb) < 0.0005
    end
    return string.lower(tostring(a)) == string.lower(tostring(b))
end

function Engine:FormatValue(val, decimals)
    local n = tonumber(val)
    if not n then
        return tostring(val or "")
    end
    if decimals and decimals > 0 then
        return string.format("%." .. decimals .. "f", n)
    end
    if math.abs(n - math.floor(n + 0.5)) < 0.0005 then
        return tostring(math.floor(n + 0.5))
    end
    return string.format("%.2f", n)
end

function Engine:Exists(cvar)
    return RawGetCVar(cvar) ~= nil
end

function Engine:Get(cvar)
    return RawGetCVar(cvar)
end

function Engine:GetDefault(cvar)
    return RawGetCVarDefault(cvar)
end

function Engine:GetInfo(cvar)
    return RawGetCVarInfo(cvar)
end

function Engine:IsReadOnly(cvar)
    local info = RawGetCVarInfo(cvar)
    if not info then return true end
    return (info.isReadOnly == true) or (info.isLockedFromUser == true)
end

function Engine:IsModified(cvar)
    local cur = self:Get(cvar)
    local def = self:GetDefault(cvar)
    if cur == nil or def == nil then return false end
    return not self:ValuesEqual(cur, def)
end

function Engine:IsOverriddenByAddon(cvar)
    local db = self:GetDB()
    return db.overrides[cvar] ~= nil
end

function Engine:GetDB()
    if type(ForeverGraphicsDB) ~= "table" then
        ForeverGraphicsDB = {}
    end
    local db = ForeverGraphicsDB
    if type(db.overrides) ~= "table" then db.overrides = {} end
    if type(db.backup) ~= "table" then db.backup = {} end
    if type(db.settings) ~= "table" then
        db.settings = {
            reapplyOnLogin = true,
            protectValues = true,
            showUnsupported = false,
            showFPSOverlay = false,
            measureFPSDelta = true,
            showMinimapButton = true,
            minimapAngle = 220,
        }
    end
    -- Fill any missing keys on upgrade
    if db.settings.reapplyOnLogin == nil then db.settings.reapplyOnLogin = true end
    if db.settings.protectValues == nil then db.settings.protectValues = true end
    if db.settings.showUnsupported == nil then db.settings.showUnsupported = false end
    if db.settings.showFPSOverlay == nil then db.settings.showFPSOverlay = false end
    if db.settings.measureFPSDelta == nil then db.settings.measureFPSDelta = true end
    if db.settings.showMinimapButton == nil then db.settings.showMinimapButton = true end
    if db.settings.minimapAngle == nil then db.settings.minimapAngle = 220 end
    return db
end

function Engine:BackupCVar(cvar)
    local db = self:GetDB()
    if db.backup[cvar] == nil then
        local cur = self:Get(cvar)
        if cur ~= nil then
            db.backup[cvar] = tostring(cur)
        end
    end
end

function Engine:RegisterListener(fn)
    table.insert(self.listeners, fn)
end

function Engine:NotifyListeners(cvar, newVal, reason)
    for _, fn in ipairs(self.listeners) do
        pcall(fn, cvar, newVal, reason)
    end
end

-- Enforces known WoW: Forever crash safety caps
function Engine:ApplySafetyCaps(cvar, value, silent)
    local cap = ns.SAFETY_CAPS[string.lower(cvar)]
    if cap then
        local num = tonumber(value)
        if num and cap.max and num > cap.max then
            if not silent then
                ChatPrint("|cffff9800Safety cap:|r " .. cap.reason)
            end
            return tostring(cap.max), true
        end
        if num and cap.min and num < cap.min then
            if not silent then
                ChatPrint("|cffff9800Safety cap:|r " .. cap.reason)
            end
            return tostring(cap.min), true
        end
    end
    return tostring(value), false
end

-- Set a CVar safely with combat queueing, backup, mutual exclusion, and clamp detection
function Engine:Set(cvar, value, opts)
    opts = opts or {}
    local silent = opts.silent == true
    local trackOverride = (opts.trackOverride ~= false)
    local skipCompanion = opts.skipCompanion == true

    if not self:Exists(cvar) then
        if not silent then
            ChatPrint("|cffff5252Unsupported:|r CVar '" .. tostring(cvar) .. "' does not exist in this client build.")
        end
        return false, "unsupported"
    end

    if self:IsReadOnly(cvar) then
        if not silent then
            ChatPrint("|cffff9800Locked:|r CVar '" .. tostring(cvar) .. "' is read-only or locked by the client.")
        end
        return false, "readonly"
    end

    local safeVal = self:ApplySafetyCaps(cvar, value, silent)

    -- Backup pre-addon value before first modification
    self:BackupCVar(cvar)

    -- Combat lockdown deferral
    if InCombatLockdown and InCombatLockdown() then
        self.pendingQueue[cvar] = {
            value = safeVal,
            trackOverride = trackOverride,
            silent = silent,
        }
        if trackOverride then
            self:GetDB().overrides[cvar] = safeVal
        end
        if not silent then
            ChatPrint("|cffffd54fQueued (In Combat):|r " .. cvar .. " = " .. safeVal .. " will apply when combat ends.")
        end
        self:NotifyListeners(cvar, safeVal, "queued")
        return true, "queued"
    end

    local oldVal = self:Get(cvar)

    -- Notify FPS delta tracker before change
    if not silent and ns.FPSOverlay and ns.FPSOverlay.BeginDeltaSample then
        local def = ns.CVAR_BY_NAME[string.lower(cvar)]
        local displayName = def and def.label or cvar
        ns.FPSOverlay:BeginDeltaSample(displayName, oldVal, safeVal)
    end

    self.isApplyingInternal = true
    local ok = RawSetCVar(cvar, safeVal)
    self.isApplyingInternal = false

    local actualVal = self:Get(cvar)
    local db = self:GetDB()

    if trackOverride then
        db.overrides[cvar] = actualVal or safeVal
    end

    -- Detect client clamping / refusal
    if ok and actualVal ~= nil and not self:ValuesEqual(actualVal, safeVal) then
        if not silent then
            ChatPrint(string.format(
                "|cffffd54fClient clamped:|r %s requested %s -> applied %s",
                cvar, tostring(safeVal), tostring(actualVal)
            ))
        end
    elseif not ok and not silent then
        ChatPrint("|cffff5252Failed:|r Could not set CVar '" .. cvar .. "'.")
    end

    -- Handle mutual exclusion & HDR safety pairing
    if not skipCompanion then
        local def = ns.CVAR_BY_NAME[string.lower(cvar)]
        if def and def.exclusiveWith and self:ValuesEqual(actualVal, "1") then
            if self:Exists(def.exclusiveWith) and not self:ValuesEqual(self:Get(def.exclusiveWith), "0") then
                self:Set(def.exclusiveWith, "0", { silent = true, trackOverride = trackOverride, skipCompanion = true })
            end
        end

        -- Prevent pitch-black HDR screen if HDROutput=1 and neither brightness mode is active
        if string.lower(cvar) == "hdroutput" and self:ValuesEqual(actualVal, "1") then
            local peakOn = self:Exists("useHDRPeakBrightness") and self:ValuesEqual(self:Get("useHDRPeakBrightness"), "1")
            local refOn = self:Exists("useHDRBrightness") and self:ValuesEqual(self:Get("useHDRBrightness"), "1")
            if not peakOn and not refOn and self:Exists("useHDRPeakBrightness") then
                self:Set("useHDRPeakBrightness", "1", { silent = true, trackOverride = trackOverride, skipCompanion = true })
                if not silent then
                    ChatPrint("|cff81c784HDR Safety:|r Automatically enabled Peak Brightness mode so the screen does not darken.")
                end
            end
        end
    end

    self:NotifyListeners(cvar, actualVal, "set")
    return ok, actualVal
end

function Engine:ResetCVar(cvar, silent)
    if not self:Exists(cvar) then return false end
    local defVal = self:GetDefault(cvar)
    if defVal == nil then return false end

    local db = self:GetDB()
    db.overrides[cvar] = nil

    local ok, res = self:Set(cvar, defVal, { silent = silent, trackOverride = false })
    self:NotifyListeners(cvar, self:Get(cvar), "reset")
    return ok, res
end

function Engine:ResetAllToBlizzardDefault()
    local db = self:GetDB()
    local count = 0
    local resetSet = {}

    for _, def in ipairs(ns.CVARS) do
        if self:Exists(def.cvar) and self:IsModified(def.cvar) then
            self:ResetCVar(def.cvar, true)
            resetSet[def.cvar] = true
            count = count + 1
        end
    end

    for cvar in pairs(db.overrides) do
        if not resetSet[cvar] and self:Exists(cvar) then
            self:ResetCVar(cvar, true)
            count = count + 1
        end
    end

    db.overrides = {}
    ChatPrint("Reset " .. count .. " graphics CVar(s) to Blizzard defaults.")
    self:NotifyListeners(nil, nil, "reset_all")
end

function Engine:RestoreBackup()
    local db = self:GetDB()
    local count = 0
    for cvar, origVal in pairs(db.backup) do
        if self:Exists(cvar) then
            self:Set(cvar, origVal, { silent = true, trackOverride = false })
            count = count + 1
        end
    end
    db.overrides = {}
    ChatPrint("Restored " .. count .. " pre-addon CVar value(s) from backup.")
    self:NotifyListeners(nil, nil, "restore_backup")
end

function Engine:ApplyPreset(presetId)
    local preset = nil
    for _, p in ipairs(ns.PRESETS) do
        if p.id == presetId then
            preset = p
            break
        end
    end
    if not preset then
        ChatPrint("|cffff5252Unknown preset:|r " .. tostring(presetId))
        return false
    end

    local db = self:GetDB()
    -- Capture undo snapshot before applying preset
    local undo = {}
    for cvar in pairs(preset.values) do
        if self:Exists(cvar) then
            undo[cvar] = self:Get(cvar)
        end
    end
    db.lastUndo = {
        presetLabel = preset.label,
        values = undo,
    }

    local applied, skipped = 0, 0
    for cvar, val in pairs(preset.values) do
        if self:Exists(cvar) and not self:IsReadOnly(cvar) then
            self:Set(cvar, val, { silent = true, trackOverride = true })
            applied = applied + 1
        else
            skipped = skipped + 1
        end
    end

    ChatPrint(string.format(
        "Applied preset |cffffd54f%s|r (%d applied%s). Use Undo Preset to revert.",
        preset.label,
        applied,
        skipped > 0 and (", " .. skipped .. " unavailable on this build") or ""
    ))
    self:NotifyListeners(nil, nil, "preset")
    return true
end

function Engine:UndoLastPreset()
    local db = self:GetDB()
    if not db.lastUndo or not db.lastUndo.values then
        ChatPrint("No previous preset action to undo.")
        return false
    end

    local count = 0
    for cvar, val in pairs(db.lastUndo.values) do
        if self:Exists(cvar) then
            self:Set(cvar, val, { silent = true, trackOverride = true })
            count = count + 1
        end
    end

    local label = db.lastUndo.presetLabel or "preset"
    db.lastUndo = nil
    ChatPrint("Undid " .. label .. " (" .. count .. " CVar(s) restored).")
    self:NotifyListeners(nil, nil, "undo")
    return true
end

function Engine:ReapplySaved(silent)
    local db = self:GetDB()
    local count = 0
    for cvar, val in pairs(db.overrides) do
        if self:Exists(cvar) and not self:IsReadOnly(cvar) then
            local cur = self:Get(cvar)
            if not self:ValuesEqual(cur, val) then
                self:Set(cvar, val, { silent = true, trackOverride = true, skipCompanion = true })
                count = count + 1
            end
        end
    end
    if not silent then
        ChatPrint("Re-applied " .. count .. " saved graphics override(s).")
    elseif count > 0 then
        ChatPrint("Restored " .. count .. " protected graphics setting(s) on login.")
    end
    self:NotifyListeners(nil, nil, "reapply")
    return count
end

function Engine:FlushCombatQueue()
    local count = 0
    local queue = self.pendingQueue
    self.pendingQueue = {}
    for cvar, entry in pairs(queue) do
        self:Set(cvar, entry.value, {
            silent = true,
            trackOverride = entry.trackOverride,
        })
        count = count + 1
    end
    if count > 0 then
        ChatPrint("Combat ended: applied " .. count .. " queued graphics setting(s).")
        self:NotifyListeners(nil, nil, "flush_queue")
    end
end

function Engine:OnExternalCVarUpdate(cvarName, newValue)
    if self.isApplyingInternal or not cvarName then return end
    local db = self:GetDB()
    -- Case-insensitive lookup in saved overrides
    local matchedKey, desiredVal = nil, nil
    local lowerName = string.lower(cvarName)
    for k, v in pairs(db.overrides) do
        if string.lower(k) == lowerName then
            matchedKey = k
            desiredVal = v
            break
        end
    end

    if matchedKey and db.settings.protectValues and not self:ValuesEqual(newValue, desiredVal) then
        -- Defer slightly so Blizzard's own graphics menu commit finishes cleanly
        if C_Timer and C_Timer.After then
            C_Timer.After(0.15, function()
                if db.settings.protectValues and db.overrides[matchedKey] ~= nil then
                    if not Engine:ValuesEqual(Engine:Get(matchedKey), db.overrides[matchedKey]) then
                        Engine:Set(matchedKey, db.overrides[matchedKey], { silent = true, trackOverride = true })
                    end
                end
            end)
        end
    else
        self:NotifyListeners(cvarName, newValue, "external")
    end
end

function Engine:RestartGraphics()
    if InCombatLockdown and InCombatLockdown() then
        ChatPrint("|cffff9800Cannot restart graphics engine during combat.|r")
        return false
    end
    if RestartGx then
        local ok = pcall(RestartGx)
        if ok then
            ChatPrint("Graphics engine restarted.")
            return true
        end
    end
    ChatPrint("To apply display/HDR changes, type |cffffd54f/console gxRestart|r or |cffffd54f/reload|r in chat.")
    return false
end

-------------------------------------------------------------------------------
-- LIVE CLIENT CVar DISCOVERY (C_Console.GetAllCommands)
-------------------------------------------------------------------------------
local function MatchesGraphicsKeyword(name)
    local lower = string.lower(name)
    for _, pat in ipairs(GRAPHICS_KEYWORDS) do
        if string.find(lower, pat) then
            return true
        end
    end
    return false
end

function Engine:ScanAllClientCVars(forceRefresh)
    if self.cachedClientCVars and not forceRefresh then
        return self.cachedClientCVars
    end

    local results = {}
    local seen = {}
    local cvarCommandType = (Enum and Enum.ConsoleCommandType and Enum.ConsoleCommandType.Cvar) or 0
    local graphicsCategory = (Enum and Enum.ConsoleCategory and Enum.ConsoleCategory.Graphics) or 1

    if C_Console and C_Console.GetAllCommands then
        local ok, commands = pcall(C_Console.GetAllCommands)
        if ok and type(commands) == "table" then
            for _, info in ipairs(commands) do
                if info and info.command and info.commandType == cvarCommandType then
                    local lower = string.lower(info.command)
                    if not seen[lower] then
                        seen[lower] = true
                        local isGfx = (info.category == graphicsCategory)
                            or (ns.CVAR_BY_NAME[lower] ~= nil)
                            or MatchesGraphicsKeyword(info.command)
                        table.insert(results, {
                            command = info.command,
                            help = (info.help and info.help ~= "") and info.help or "No client description provided.",
                            category = info.category or 0,
                            isGraphics = isGfx,
                            isCurated = (ns.CVAR_BY_NAME[lower] ~= nil),
                        })
                    end
                end
            end
        end
    end

    -- Fallback: ensure all curated CVars that exist are included even if C_Console is unavailable
    for _, def in ipairs(ns.CVARS) do
        local lower = string.lower(def.cvar)
        if not seen[lower] and self:Exists(def.cvar) then
            seen[lower] = true
            table.insert(results, {
                command = def.cvar,
                help = def.desc or "",
                category = graphicsCategory,
                isGraphics = true,
                isCurated = true,
            })
        end
    end

    table.sort(results, function(a, b)
        return string.lower(a.command) < string.lower(b.command)
    end)

    self.cachedClientCVars = results
    return results
end

-- Snapshot & Diff utility to discover which CVars a Blizzard menu option touches
function Engine:TakeSnapshot()
    local all = self:ScanAllClientCVars(false)
    local snap = {}
    local count = 0
    for _, entry in ipairs(all) do
        local val = self:Get(entry.command)
        if val ~= nil then
            snap[entry.command] = tostring(val)
            count = count + 1
        end
    end
    self.snapshot = snap
    ChatPrint("Captured snapshot of " .. count .. " client CVars. Change a setting and click Diff Snapshot (or /fg diff).")
    return count
end

function Engine:DiffSnapshot()
    if not self.snapshot then
        ChatPrint("No snapshot taken yet. Click Snapshot first (or run /fg snap).")
        return {}
    end
    local diffs = {}
    for cvar, oldVal in pairs(self.snapshot) do
        local curVal = self:Get(cvar)
        if curVal ~= nil and not self:ValuesEqual(oldVal, curVal) then
            table.insert(diffs, {
                cvar = cvar,
                oldVal = oldVal,
                newVal = tostring(curVal),
            })
        end
    end
    table.sort(diffs, function(a, b)
        return string.lower(a.cvar) < string.lower(b.cvar)
    end)
    if #diffs == 0 then
        ChatPrint("Snapshot diff: no CVars changed since snapshot.")
    else
        ChatPrint("Snapshot diff: " .. #diffs .. " CVar(s) changed:")
        for _, d in ipairs(diffs) do
            ChatPrint(string.format("  |cffffd54f%s|r: %s -> |cff81c784%s|r", d.cvar, d.oldVal, d.newVal))
        end
    end
    return diffs
end

function Engine:GetHDRStatus()
    local hdrSupported = self:Exists("HDROutput")
    if not hdrSupported then
        return "unsupported", "Native HDR10 CVars are not exposed on this client/OS."
    end
    local hdrOn = self:ValuesEqual(self:Get("HDROutput"), "1")
    if not hdrOn then
        return "off", "HDR10 Output is OFF (Standard SDR pipeline)."
    end
    local peakOn = self:Exists("useHDRPeakBrightness") and self:ValuesEqual(self:Get("useHDRPeakBrightness"), "1")
    local refOn = self:Exists("useHDRBrightness") and self:ValuesEqual(self:Get("useHDRBrightness"), "1")
    if peakOn and refOn then
        return "conflict", "WARNING: Both Peak Brightness and Manual Paper White are ON! Disable one to avoid conflicts."
    elseif not peakOn and not refOn then
        return "dark", "WARNING: HDR10 is ON with no brightness mode enabled — image will appear very dark!"
    elseif peakOn then
        local peak = self:Get("HDRPeakBrightness") or "?"
        local factor = self:Get("HDRFactor") or "?"
        return "peak", string.format("HDR10 ACTIVE — Peak Brightness Mode (%s nits, Factor %s)", tostring(peak), tostring(factor))
    else
        local ref = self:Get("HDRBrightness") or "?"
        return "reference", string.format("HDR10 ACTIVE — Manual Paper White Mode (%s nits)", tostring(ref))
    end
end
