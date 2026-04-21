-- Wick's Macro Builder
-- Core.lua — namespace, saved variables, event dispatch, macro API wrappers.

local ADDON, ns = ...
_G.WICKSMACROBUILDER = ns

ns.version = "0.1.0"

-- ============================================================
-- Saved variables
-- ============================================================
local DEFAULTS = {
    lastScope = "global",       -- "global" | "char"
    lastMacroName = "",
    lastIcon = "INV_Misc_QuestionMark",
    lastBody = "",
}

-- ============================================================
-- Event dispatcher — modules register here, no per-module frame.
-- ============================================================
local events = {}
function ns:On(event, fn)
    events[event] = events[event] or {}
    table.insert(events[event], fn)
end

local frame = CreateFrame("Frame", "WICKSMACROBUILDEREventFrame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, ...)
    if events[event] then
        for _, fn in ipairs(events[event]) do fn(...) end
    end
end)

ns:On("ADDON_LOADED", function(loaded)
    if loaded ~= ADDON then return end
    WICKSMACROBUILDERDB = WICKSMACROBUILDERDB or {}
    for k, v in pairs(DEFAULTS) do
        if WICKSMACROBUILDERDB[k] == nil then WICKSMACROBUILDERDB[k] = v end
    end
    if ns.UI and ns.UI.Build then ns.UI:Build() end
end)

-- ============================================================
-- Macro-API wrappers
-- ============================================================
-- TBC Classic: GetNumMacros() returns (numGlobal, numPerChar).
-- Global slots are 1..MAX_ACCOUNT_MACROS (36).
-- Per-character slots are MAX_ACCOUNT_MACROS+1 .. MAX_ACCOUNT_MACROS+MAX_CHARACTER_MACROS
--   (i.e. usually 37..54, though the constant in some clients is 120+).
-- GetMacroInfo(slot) → name, icon (texture path or fileID), body, isLocal.
-- CreateMacro(name, icon, body, perChar) → slot, or nil if out of space.
-- EditMacro(slot, name, icon, body) → nothing; replaces in place.
-- DeleteMacro(slot) → nothing.
-- Editing macros is blocked in combat (InCombatLockdown()).

local MAX_GLOBAL = _G.MAX_ACCOUNT_MACROS or 36
local MAX_PER_CHAR = _G.MAX_CHARACTER_MACROS or 18

-- Global slot range: 1..MAX_GLOBAL
-- Per-char slot range: (MAX_GLOBAL+1) .. (MAX_GLOBAL+MAX_PER_CHAR) in TBC 2.5.5
local PC_OFFSET = MAX_GLOBAL

ns.MacroAPI = {}
local M = ns.MacroAPI

function M:MaxGlobal() return MAX_GLOBAL end
function M:MaxPerChar() return MAX_PER_CHAR end

-- Macros live in a PACKED LIST in WoW's internal model. Global scope uses
-- absolute slots 1..numGlobal (not 1..MAX_GLOBAL — empty slots don't exist).
-- Per-character scope uses absolute slots (MAX_GLOBAL+1)..(MAX_GLOBAL+numPerChar).
-- GetMacroInfo(slot) returns nil if slot > count-in-that-scope.
-- CreateMacro APPENDS to the end of the chosen scope's list.
-- DeleteMacro shifts higher slots down by one.
-- So "saving to slot 5" is nonsense — you can only edit existing macros in
-- place or create a new one that appends.

-- Returns numGlobal, numPerChar (counts of existing macros, not maxes).
function M:Counts()
    local g, pc = GetNumMacros()
    return g or 0, pc or 0
end

function M:CountScope(scope)
    local g, pc = self:Counts()
    if scope == "char" then return pc end
    return g
end

-- Returns the absolute slot for the Nth macro (1-based) in the given scope,
-- or nil if out of range.
function M:AbsByBrowse(scope, browseIndex)
    local count = self:CountScope(scope)
    if browseIndex < 1 or browseIndex > count then return nil end
    if scope == "char" then
        return MAX_GLOBAL + browseIndex
    end
    return browseIndex
end

-- Returns absSlot, name, icon, body for the Nth macro in scope, or nil.
function M:GetByBrowse(scope, browseIndex)
    local abs = self:AbsByBrowse(scope, browseIndex)
    if not abs then return nil end
    local name, icon, body = GetMacroInfo(abs)
    if not name then return nil end
    return abs, name, icon, body
end

-- Converts an absolute slot back to a (scope, browseIndex). Returns nil if invalid.
function M:BrowseOfAbs(absSlot)
    if not absSlot then return nil end
    if absSlot <= MAX_GLOBAL then
        return "global", absSlot
    else
        return "char", absSlot - MAX_GLOBAL
    end
end

-- Create a new macro at the end of scope's list. Returns newAbsSlot or (nil, err).
function M:CreateNew(scope, name, icon, body)
    if InCombatLockdown() then return nil, "Cannot edit macros in combat." end
    if not name or name == "" then return nil, "Macro name is required." end
    if not body or body == "" then return nil, "Macro body is empty." end
    if #body > 255 then return nil, ("Macro body exceeds 255 characters (%d)."):format(#body) end
    -- Pass a boolean for isPerCharacter (not 1/nil) — TBC Classic's Lua-to-C
    -- binding for CreateMacro treats integer 1 as false here, silently saving
    -- per-character macros into the global scope.
    local perChar = (scope == "char") and true or nil
    local iconArg = icon or "INV_Misc_QuestionMark"
    local newSlot = CreateMacro(name, iconArg, body, perChar)
    if not newSlot then return nil, "No empty slots available in this scope." end
    return newSlot
end

-- Edit an existing macro in place at absSlot. Returns (ok, err?).
function M:EditAt(absSlot, name, icon, body)
    if InCombatLockdown() then return false, "Cannot edit macros in combat." end
    if not GetMacroInfo(absSlot) then return false, "Target macro no longer exists." end
    if not name or name == "" then return false, "Macro name is required." end
    if not body or body == "" then return false, "Macro body is empty." end
    if #body > 255 then return false, ("Macro body exceeds 255 characters (%d)."):format(#body) end
    EditMacro(absSlot, name, icon or "INV_Misc_QuestionMark", body)
    return true
end

-- Delete a macro at absSlot. Returns (ok, err?).
function M:DeleteAt(absSlot)
    if InCombatLockdown() then return false, "Cannot edit macros in combat." end
    if not GetMacroInfo(absSlot) then return false, "Target macro no longer exists." end
    DeleteMacro(absSlot)
    return true
end

-- ============================================================
-- Slash command
-- ============================================================
SLASH_WSMB1 = "/wsmb"
SlashCmdList["WSMB"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "reset" then
        WICKSMACROBUILDERDB = nil
        print("|cff4FC778Wick's Macro Builder|r: settings reset. /reload to apply.")
        return
    end
    if ns.UI and ns.UI.Toggle then ns.UI:Toggle() end
end
