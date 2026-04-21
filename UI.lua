-- Wick's Macro Builder
-- UI.lua — tabbed macro builder with Wick brand chrome.
-- Brand spec: memory/reference_wick_brand_style.md

local _, ns = ...
local UI = {}
ns.UI = UI

-- ============================================================
-- Wick brand palette (locked) — do not drift
-- Fel #4FC778 · Void #0D0A14 · Shadow #171124 · Border #383058 · Text #D4C8A1
-- ============================================================
local C_BG           = { 0.051, 0.039, 0.078, 0.97 }
local C_HEADER_BG    = { 0.090, 0.067, 0.141, 1 }
local C_BORDER       = { 0.220, 0.188, 0.345, 1 }
local C_GREEN        = { 0.310, 0.780, 0.471, 1 }
local C_TEXT_NORMAL  = { 0.831, 0.784, 0.631, 1 }
local C_TEXT_DIM     = { 0.55, 0.52, 0.42, 1 }
local C_TAB_BG       = { 0.07, 0.06, 0.12, 1 }
local C_TAB_BG_SEL   = { 0.14, 0.11, 0.23, 1 }
local C_INPUT_BG     = { 0.12, 0.10, 0.20, 1 }
local C_WARN         = { 0.95, 0.75, 0.30, 1 }
local C_ERROR        = { 0.95, 0.35, 0.35, 1 }

local CLASS_COLORS = RAID_CLASS_COLORS

local BRACKET     = 10
local HEADER_H    = 22
local TAB_H       = 22
local FRAME_W     = 580
local FRAME_H     = 510
local FRAME_PAD   = 10

local SOURCES = {
    "GENERAL",
    "DRUID", "PRIEST", "SHAMAN", "PALADIN", "MAGE",
    "WARLOCK", "WARRIOR", "ROGUE", "HUNTER",
}
local SOURCE_LABELS = {
    GENERAL = "General",
    DRUID   = "Druid",   PRIEST  = "Priest",  SHAMAN  = "Shaman",
    PALADIN = "Paladin", MAGE    = "Mage",    WARLOCK = "Warlock",
    WARRIOR = "Warrior", ROGUE   = "Rogue",   HUNTER  = "Hunter",
}

local frame
local tabs = {}
local selectedSource = "GENERAL"
local chipPool = {}
local presetRowPool = {}

-- State for the editor + save controls.
-- In WoW, macros are a packed list — you can only EDIT an existing macro in
-- place or CREATE a new one (which appends). There is no "reserved slot 5".
-- So state tracks:
--   - scope: which scope (global/per-char) you're browsing + will create in
--   - browseIndex: 1-based index into existing macros of that scope
--   - editingAbsSlot: the absolute slot of the macro currently loaded into
--     the editor. When set, Save calls EditMacro in place. When nil, Save
--     calls CreateMacro (appends new).
local state = {
    scope = "global",
    browseIndex = 1,
    editingAbsSlot = nil,
}

-- ============================================================
-- Chrome helpers
-- ============================================================
local function newTex(parent, layer, c)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    if c then t:SetColorTexture(c[1], c[2], c[3], c[4] or 1) end
    return t
end

local function addBorder(f)
    local t = newTex(f, "BORDER", C_BORDER); t:SetPoint("TOPLEFT");    t:SetPoint("TOPRIGHT");    t:SetHeight(1)
    local b = newTex(f, "BORDER", C_BORDER); b:SetPoint("BOTTOMLEFT"); b:SetPoint("BOTTOMRIGHT"); b:SetHeight(1)
    local l = newTex(f, "BORDER", C_BORDER); l:SetPoint("TOPLEFT");    l:SetPoint("BOTTOMLEFT");  l:SetWidth(1)
    local r = newTex(f, "BORDER", C_BORDER); r:SetPoint("TOPRIGHT");   r:SetPoint("BOTTOMRIGHT"); r:SetWidth(1)
end

local function addInnerBorder(f)
    local t = newTex(f, "BORDER", C_BORDER); t:SetPoint("TOPLEFT");    t:SetPoint("TOPRIGHT");    t:SetHeight(1)
    local b = newTex(f, "BORDER", C_BORDER); b:SetPoint("BOTTOMLEFT"); b:SetPoint("BOTTOMRIGHT"); b:SetHeight(1)
    local l = newTex(f, "BORDER", C_BORDER); l:SetPoint("TOPLEFT");    l:SetPoint("BOTTOMLEFT");  l:SetWidth(1)
    local r = newTex(f, "BORDER", C_BORDER); r:SetPoint("TOPRIGHT");   r:SetPoint("BOTTOMRIGHT"); r:SetWidth(1)
end

-- Fel-green L-brackets, 10px arms, 2px thick, flush to corners.
-- If resizeButton is provided, the BOTTOMRIGHT bracket is parented to it so
-- the bracket itself acts as the resize grip.
local function addCorners(f, resizeButton)
    for _, p in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
        local host = (p == "BOTTOMRIGHT" and resizeButton) or f
        local h = host:CreateTexture(nil, "OVERLAY"); h:SetColorTexture(unpack(C_GREEN))
        h:SetPoint(p, host, p, 0, 0); h:SetSize(BRACKET, 2)
        local v = host:CreateTexture(nil, "OVERLAY"); v:SetColorTexture(unpack(C_GREEN))
        v:SetPoint(p, host, p, 0, 0); v:SetSize(2, BRACKET)
    end
end

local function newText(parent, size, color, justify)
    local t = parent:CreateFontString(nil, "OVERLAY")
    t:SetFont("Fonts\\FRIZQT__.TTF", size or 11, "")
    local c = color or C_TEXT_NORMAL
    t:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    if justify then t:SetJustifyH(justify) end
    return t
end

local function setTextColor(fs, c) fs:SetTextColor(c[1], c[2], c[3], c[4] or 1) end

-- Bordered button with label
local function makeButton(parent, label, width, height)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width or 80, height or 22)
    local bg = newTex(b, "BACKGROUND", C_TAB_BG); bg:SetAllPoints(); b.bg = bg
    addInnerBorder(b)
    local t = newText(b, 11, C_TEXT_NORMAL)
    t:SetPoint("CENTER"); t:SetText(label); b.text = t
    b:SetScript("OnEnter", function(self) self.bg:SetColorTexture(C_TAB_BG_SEL[1], C_TAB_BG_SEL[2], C_TAB_BG_SEL[3], 1) end)
    b:SetScript("OnLeave", function(self) self.bg:SetColorTexture(C_TAB_BG[1], C_TAB_BG[2], C_TAB_BG[3], 1) end)
    return b
end

-- ============================================================
-- Chip width measurement
-- ------------------------------------------------------------
-- A chip's FontString is anchored LEFT+RIGHT inside the chip — calling
-- GetStringWidth on it can return a clamped/zero value on first render
-- (before WoW has finalized the parent frame's width), which produces
-- overlapping chips. Use a dedicated unanchored FontString so widths
-- are always the intrinsic text width.
-- ============================================================
local _measureFS
local _widthCache = {}
local function measureChipWidth(label)
    if _widthCache[label] then return _widthCache[label] end
    if not _measureFS then
        _measureFS = UIParent:CreateFontString(nil, "OVERLAY")
        _measureFS:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        _measureFS:SetWordWrap(false)
        _measureFS:Hide()
    end
    _measureFS:SetText(label)
    -- Bigger pad (+20) than strict (text+12 = text + LEFT inset + RIGHT inset)
    -- to absorb any rendering discrepancy between measureFS and chip.text.
    local w = math.max(44, math.ceil(_measureFS:GetStringWidth()) + 20)
    _widthCache[label] = w
    return w
end

-- ============================================================
-- The editor (multi-line EditBox inside a ScrollFrame)
-- ============================================================
local editBox, editScroll, charCount, nameEdit, slotLabel, scopeCbs

local function updateCharCount()
    if not editBox or not charCount then return end
    local n = #(editBox:GetText() or "")
    charCount:SetText(("%d/255"):format(n))
    if n > 255 then
        setTextColor(charCount, C_ERROR)
    elseif n > 200 then
        setTextColor(charCount, C_WARN)
    else
        setTextColor(charCount, C_GREEN)
    end
end

local function insertAtCursor(text)
    if not editBox then return end
    editBox:SetFocus()
    editBox:Insert(text)
    updateCharCount()
end

-- ============================================================
-- Chip (small clickable button that inserts a snippet)
-- ============================================================
local function getChip(i)
    if chipPool[i] then return chipPool[i] end
    local b = CreateFrame("Button", nil, frame)
    b:SetHeight(20)
    local bg = newTex(b, "BACKGROUND", C_INPUT_BG); bg:SetAllPoints(); b.bg = bg
    addInnerBorder(b)
    local t = newText(b, 10, C_GREEN); t:SetPoint("CENTER")
    t:SetWordWrap(false)
    b.text = t
    b:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(C_TAB_BG_SEL[1], C_TAB_BG_SEL[2], C_TAB_BG_SEL[3], 1)
        if self.hint then
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
            GameTooltip:AddLine(self.label or "", 1, 0.9, 0.6)
            GameTooltip:AddLine(self.hint, 0.9, 0.9, 0.9, true)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Click to insert: " .. (self.insert or ""), 0.5, 0.8, 0.5, true)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(C_INPUT_BG[1], C_INPUT_BG[2], C_INPUT_BG[3], 1)
        GameTooltip:Hide()
    end)
    chipPool[i] = b
    return b
end

-- Wraps chips left-to-right in a parent, returns final Y offset used (negative from top).
local function layoutChips(startIndex, items, topY, parentRightEdge, color)
    local x = FRAME_PAD
    local y = topY
    local rowH = 22 -- includes vertical gap
    for i, item in ipairs(items) do
        local chip = getChip(startIndex + i - 1)
        chip.label = item.label
        chip.hint = item.hint
        chip.insert = item.insert
        chip.text:SetText(item.label)
        if color then chip.text:SetTextColor(color[1], color[2], color[3], 1) end
        chip:SetScript("OnClick", function() insertAtCursor(item.insert) end)

        local w = measureChipWidth(item.label)
        chip:SetWidth(w)

        if x + w > parentRightEdge - FRAME_PAD then
            x = FRAME_PAD
            y = y - rowH
        end
        chip:ClearAllPoints()
        chip:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
        chip:Show()
        x = x + w + 4
    end
    return y - rowH, startIndex + #items
end

-- ============================================================
-- Preset row (for class tabs)
-- ============================================================
local function getPresetRow(i)
    if presetRowPool[i] then return presetRowPool[i] end
    local row = CreateFrame("Button", nil, frame)
    row:SetHeight(22)
    local bg = newTex(row, "BACKGROUND", C_INPUT_BG); bg:SetAllPoints(); bg:Hide(); row.bg = bg
    local name = newText(row, 11, C_TEXT_NORMAL, "LEFT")
    name:SetPoint("LEFT", 8, 0); name:SetWidth(160); row.nameText = name
    local hint = newText(row, 10, C_TEXT_DIM, "LEFT")
    hint:SetPoint("LEFT", name, "RIGHT", 12, 0); hint:SetPoint("RIGHT", -8, 0); row.hintText = hint
    row:SetScript("OnEnter", function(self) self.bg:Show() end)
    row:SetScript("OnLeave", function(self) self.bg:Hide() end)
    presetRowPool[i] = row
    return row
end

-- ============================================================
-- Source content — renders the upper panel for the selected tab.
-- Returns the Y offset (negative from frame top) where the upper panel ends.
-- ============================================================
local SOURCE_TOP = HEADER_H + TAB_H * 2 + 6   -- below the 2-row tab strip

local function hideAllChips()
    for _, c in ipairs(chipPool) do c:Hide() end
    for _, r in ipairs(presetRowPool) do r:Hide() end
end

local function renderGeneralSource()
    hideAllChips()
    -- Section 1: Conditionals
    local header1 = frame.sourceHeader1
    header1:SetText("Conditionals")
    header1:Show()
    header1:ClearAllPoints()
    header1:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PAD, -(SOURCE_TOP + 2))

    local y = -(SOURCE_TOP + 18)
    local rightEdge = frame:GetWidth()
    local nextIdx = 1
    y, nextIdx = layoutChips(nextIdx, ns.CONDITIONALS, y, rightEdge, C_GREEN)

    -- Gap + Section 2: Commands
    y = y - 4
    local header2 = frame.sourceHeader2
    header2:SetText("Commands")
    header2:Show()
    header2:ClearAllPoints()
    header2:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PAD, y)
    y = y - 16
    y, nextIdx = layoutChips(nextIdx, ns.COMMANDS, y, rightEdge, C_TEXT_NORMAL)
end

local function renderClassSource(class)
    hideAllChips()
    local header1 = frame.sourceHeader1
    header1:SetText(SOURCE_LABELS[class] .. " presets — click to load")
    header1:Show()
    header1:ClearAllPoints()
    header1:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PAD, -(SOURCE_TOP + 2))
    frame.sourceHeader2:Hide()

    local presets = ns.PRESETS[class] or {}
    local y = -(SOURCE_TOP + 18)
    for i, preset in ipairs(presets) do
        local row = getPresetRow(i)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PAD, y)
        row:SetPoint("RIGHT", frame, "RIGHT", -FRAME_PAD, 0)
        row.nameText:SetText(preset.name)
        row.hintText:SetText(preset.hint or "")
        row:SetScript("OnClick", function()
            if nameEdit then nameEdit:SetText(preset.name) end
            if editBox then
                editBox:SetText(preset.body or "")
                editBox:SetCursorPosition(#(preset.body or ""))
                updateCharCount()
            end
            -- Loading a preset is a NEW-macro intent. Clear any prior edit target
            -- so Save creates a new macro instead of overwriting something else.
            state.editingAbsSlot = nil
            if frame.updateModeHint then frame.updateModeHint() end
            if frame.statusText then
                frame.statusText:SetText("Preset loaded. Save will create a new macro.")
                setTextColor(frame.statusText, C_TEXT_DIM)
            end
        end)
        row:Show()
        y = y - 22
    end

    if #presets == 0 then
        local empty = frame.emptyPresets
        empty:Show()
        empty:ClearAllPoints()
        empty:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PAD, y)
        empty:SetText("(No presets yet for this class.)")
    else
        frame.emptyPresets:Hide()
    end
end

local function renderSource()
    if selectedSource == "GENERAL" then
        frame.emptyPresets:Hide()
        renderGeneralSource()
    else
        renderClassSource(selectedSource)
    end
end

-- ============================================================
-- Tab strip
-- ============================================================
local function makeTab(source)
    local btn = CreateFrame("Button", nil, frame)
    btn:SetSize(108, TAB_H)
    local bg = newTex(btn, "BACKGROUND", C_TAB_BG); bg:SetAllPoints(); btn.bg = bg

    local color
    if source == "GENERAL" then
        color = C_GREEN
    else
        local cc = CLASS_COLORS[source]
        color = cc and { cc.r, cc.g, cc.b, 1 } or C_TEXT_NORMAL
    end
    local t = newText(btn, 11, color); t:SetPoint("CENTER"); t:SetText(SOURCE_LABELS[source])
    btn.text = t

    local indicator = newTex(btn, "OVERLAY", C_GREEN)
    indicator:SetPoint("BOTTOMLEFT"); indicator:SetPoint("BOTTOMRIGHT"); indicator:SetHeight(2)
    indicator:Hide(); btn.indicator = indicator

    btn.source = source
    btn:SetScript("OnClick", function()
        selectedSource = source
        UI:Refresh()
    end)
    return btn
end

local function refreshTabVisuals()
    for _, tab in ipairs(tabs) do
        if tab.source == selectedSource then
            tab.indicator:Show()
            tab.bg:SetColorTexture(C_TAB_BG_SEL[1], C_TAB_BG_SEL[2], C_TAB_BG_SEL[3], 1)
        else
            tab.indicator:Hide()
            tab.bg:SetColorTexture(C_TAB_BG[1], C_TAB_BG[2], C_TAB_BG[3], 1)
        end
    end
end

-- ============================================================
-- Editor + save panel
-- ============================================================
-- Positioned in the bottom portion of the frame, stacked upward from the bottom.
local EDITOR_BOTTOM = 10        -- gap from frame bottom
local SAVE_ROW_H    = 24
local SLOT_ROW_H    = 24
local EDITOR_H      = 96
local NAME_ROW_H    = 24

local function buildEditorPanel()
    -- Save row (bottom-most)
    local saveRow = CreateFrame("Frame", nil, frame)
    saveRow:SetHeight(SAVE_ROW_H)
    saveRow:SetPoint("BOTTOMLEFT",  FRAME_PAD, EDITOR_BOTTOM)
    saveRow:SetPoint("BOTTOMRIGHT", -FRAME_PAD, EDITOR_BOTTOM)

    local saveBtn = makeButton(saveRow, "Save to Slot", 100, SAVE_ROW_H)
    saveBtn.text:SetTextColor(C_GREEN[1], C_GREEN[2], C_GREEN[3], 1)
    saveBtn:SetPoint("RIGHT", 0, 0)

    local deleteBtn = makeButton(saveRow, "Delete", 70, SAVE_ROW_H)
    deleteBtn:SetPoint("RIGHT", saveBtn, "LEFT", -6, 0)

    local loadBtn = makeButton(saveRow, "Load from Slot", 110, SAVE_ROW_H)
    loadBtn:SetPoint("RIGHT", deleteBtn, "LEFT", -6, 0)

    local newBtn = makeButton(saveRow, "Clear", 60, SAVE_ROW_H)
    newBtn:SetPoint("LEFT", 0, 0)

    -- Slot/scope row (above save row)
    local slotRow = CreateFrame("Frame", nil, frame)
    slotRow:SetHeight(SLOT_ROW_H)
    slotRow:SetPoint("BOTTOMLEFT",  FRAME_PAD, EDITOR_BOTTOM + SAVE_ROW_H + 4)
    slotRow:SetPoint("BOTTOMRIGHT", -FRAME_PAD, EDITOR_BOTTOM + SAVE_ROW_H + 4)

    local function makeRadio(parent, label, scope)
        local r = CreateFrame("Button", nil, parent)
        r:SetSize(16, 16)
        local bg = newTex(r, "BACKGROUND", C_INPUT_BG); bg:SetAllPoints()
        addInnerBorder(r)
        local dot = newTex(r, "ARTWORK", C_GREEN)
        dot:SetPoint("TOPLEFT", 3, -3); dot:SetPoint("BOTTOMRIGHT", -3, 3); dot:Hide()
        r.dot = dot
        r.scope = scope
        local t = newText(parent, 11, C_TEXT_NORMAL); t:SetPoint("LEFT", r, "RIGHT", 4, 0); t:SetText(label)
        r.label = t
        return r
    end

    local radioGlobal = makeRadio(slotRow, "Global", "global")
    radioGlobal:SetPoint("LEFT", 0, 0)
    local radioChar = makeRadio(slotRow, "Per-Character", "char")
    radioChar:SetPoint("LEFT", radioGlobal.label, "RIGHT", 14, 0)

    scopeCbs = { radioGlobal, radioChar }

    -- Slot prev/current/next widget
    local slotBtn = CreateFrame("Frame", nil, slotRow)
    slotBtn:SetSize(180, SLOT_ROW_H)
    slotBtn:SetPoint("LEFT", radioChar.label, "RIGHT", 24, 0)

    local slotPrev = makeButton(slotBtn, "◄", 20, SLOT_ROW_H)
    slotPrev:SetPoint("LEFT", 0, 0)

    slotLabel = CreateFrame("Frame", nil, slotBtn)
    slotLabel:SetSize(140, SLOT_ROW_H)
    slotLabel:SetPoint("LEFT", slotPrev, "RIGHT", 4, 0)
    local slLabBg = newTex(slotLabel, "BACKGROUND", C_INPUT_BG); slLabBg:SetAllPoints()
    addInnerBorder(slotLabel)
    local slText = newText(slotLabel, 11, C_TEXT_NORMAL); slText:SetPoint("CENTER"); slText:SetText("1: (empty)")
    slotLabel.text = slText

    local slotNext = makeButton(slotBtn, "►", 20, SLOT_ROW_H)
    slotNext:SetPoint("LEFT", slotLabel, "RIGHT", 4, 0)

    local function updatePickerLabel()
        local count = ns.MacroAPI:CountScope(state.scope)
        if count == 0 then
            slText:SetText("(no macros in this scope)")
            return
        end
        if state.browseIndex < 1 then state.browseIndex = 1 end
        if state.browseIndex > count then state.browseIndex = count end
        local _, name = ns.MacroAPI:GetByBrowse(state.scope, state.browseIndex)
        slText:SetText(("%d/%d: %s"):format(state.browseIndex, count, name or "?"))
    end

    local function updateModeHint()
        if not frame.modeHint then return end
        if state.editingAbsSlot then
            local name = GetMacroInfo(state.editingAbsSlot)
            frame.modeHint:SetText(("Editing slot %d — Save overwrites."):format(state.editingAbsSlot))
            setTextColor(frame.modeHint, C_GREEN)
            saveBtn.text:SetText("Save Changes")
        else
            frame.modeHint:SetText("No macro loaded — Save creates a new one.")
            setTextColor(frame.modeHint, C_TEXT_DIM)
            saveBtn.text:SetText("Create New")
        end
    end

    local function updateScopeVisuals()
        for _, r in ipairs(scopeCbs) do
            if r.scope == state.scope then r.dot:Show() else r.dot:Hide() end
        end
        updatePickerLabel()
    end

    local function onScopeChange(newScope)
        state.scope = newScope
        state.browseIndex = 1
        -- Toggling scope is a "I want my next save to go here" intent. Any
        -- stale edit target from the other scope should be dropped so Save
        -- falls back to Create New in the new scope.
        state.editingAbsSlot = nil
        updateScopeVisuals()
        updateModeHint()
    end
    radioGlobal:SetScript("OnClick", function() onScopeChange("global") end)
    radioChar:SetScript("OnClick", function() onScopeChange("char") end)
    slotPrev:SetScript("OnClick", function()
        local count = ns.MacroAPI:CountScope(state.scope)
        if count == 0 then return end
        state.browseIndex = state.browseIndex - 1
        if state.browseIndex < 1 then state.browseIndex = count end
        updatePickerLabel()
    end)
    slotNext:SetScript("OnClick", function()
        local count = ns.MacroAPI:CountScope(state.scope)
        if count == 0 then return end
        state.browseIndex = state.browseIndex + 1
        if state.browseIndex > count then state.browseIndex = 1 end
        updatePickerLabel()
    end)

    frame.updatePickerLabel = updatePickerLabel
    frame.updateModeHint = updateModeHint
    frame.updateScopeVisuals = updateScopeVisuals

    -- Editor (above slot row)
    local editFrame = CreateFrame("Frame", nil, frame)
    editFrame:SetHeight(EDITOR_H)
    editFrame:SetPoint("BOTTOMLEFT",  FRAME_PAD, EDITOR_BOTTOM + SAVE_ROW_H + SLOT_ROW_H + 8)
    editFrame:SetPoint("BOTTOMRIGHT", -FRAME_PAD, EDITOR_BOTTOM + SAVE_ROW_H + SLOT_ROW_H + 8)
    local eBg = newTex(editFrame, "BACKGROUND", C_INPUT_BG); eBg:SetAllPoints()
    addInnerBorder(editFrame)

    editScroll = CreateFrame("ScrollFrame", "WICKSMACROBUILDEREditorScroll", editFrame, "UIPanelScrollFrameTemplate")
    editScroll:SetPoint("TOPLEFT", 6, -6)
    editScroll:SetPoint("BOTTOMRIGHT", -24, 6)

    editBox = CreateFrame("EditBox", nil, editScroll)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(255)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetTextInsets(0, 0, 0, 0)
    editBox:SetWidth(frame:GetWidth() - 2 * FRAME_PAD - 32)
    editBox:SetHeight(EDITOR_H - 12)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnTextChanged", function() updateCharCount() end)
    editBox:SetTextColor(C_TEXT_NORMAL[1], C_TEXT_NORMAL[2], C_TEXT_NORMAL[3], 1)
    editScroll:SetScrollChild(editBox)

    charCount = newText(frame, 10, C_GREEN, "RIGHT")
    charCount:SetPoint("BOTTOMRIGHT", editFrame, "TOPRIGHT", 0, 2)
    charCount:SetText("0/255")

    -- Name row (above editor)
    local nameRow = CreateFrame("Frame", nil, frame)
    nameRow:SetHeight(NAME_ROW_H)
    nameRow:SetPoint("BOTTOMLEFT",  FRAME_PAD, EDITOR_BOTTOM + SAVE_ROW_H + SLOT_ROW_H + EDITOR_H + 12)
    nameRow:SetPoint("BOTTOMRIGHT", -FRAME_PAD, EDITOR_BOTTOM + SAVE_ROW_H + SLOT_ROW_H + EDITOR_H + 12)

    local nameLbl = newText(nameRow, 11, C_TEXT_NORMAL); nameLbl:SetPoint("LEFT", 0, 0); nameLbl:SetText("Name:")

    local nameFrame = CreateFrame("Frame", nil, nameRow)
    nameFrame:SetSize(200, NAME_ROW_H - 2)
    nameFrame:SetPoint("LEFT", nameLbl, "RIGHT", 6, 0)
    local nBg = newTex(nameFrame, "BACKGROUND", C_INPUT_BG); nBg:SetAllPoints()
    addInnerBorder(nameFrame)

    nameEdit = CreateFrame("EditBox", nil, nameFrame)
    nameEdit:SetPoint("TOPLEFT", 6, -2); nameEdit:SetPoint("BOTTOMRIGHT", -6, 2)
    nameEdit:SetAutoFocus(false)
    nameEdit:SetFontObject("ChatFontNormal")
    nameEdit:SetMaxLetters(16)
    nameEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    nameEdit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    nameEdit:SetTextColor(C_TEXT_NORMAL[1], C_TEXT_NORMAL[2], C_TEXT_NORMAL[3], 1)

    -- Status message (right of name row)
    local statusText = newText(nameRow, 10, C_TEXT_DIM, "RIGHT")
    statusText:SetPoint("RIGHT", 0, 0); statusText:SetPoint("LEFT", nameFrame, "RIGHT", 12, 0)
    frame.statusText = statusText

    local function flashStatus(msg, color)
        statusText:SetText(msg or "")
        setTextColor(statusText, color or C_TEXT_DIM)
    end

    -- Wire buttons
    newBtn:SetScript("OnClick", function()
        editBox:SetText("")
        nameEdit:SetText("")
        state.editingAbsSlot = nil
        updateCharCount()
        updateModeHint()
        flashStatus("Editor cleared. Save will create a new macro.", C_TEXT_DIM)
    end)

    loadBtn:SetScript("OnClick", function()
        local abs, name, icon, body = ns.MacroAPI:GetByBrowse(state.scope, state.browseIndex)
        if not abs then
            flashStatus("Nothing to load in this scope.", C_WARN); return
        end
        nameEdit:SetText(name)
        editBox:SetText(body or "")
        editBox:SetCursorPosition(#(body or ""))
        WICKSMACROBUILDERDB.lastIcon = icon or "INV_Misc_QuestionMark"
        state.editingAbsSlot = abs
        updateCharCount()
        updateModeHint()
        flashStatus(("Loaded: %s (slot %d)"):format(name, abs), C_GREEN)
    end)

    -- Delete requires confirmation via StaticPopup so a mis-click doesn't
    -- nuke a macro. Popup body substitutes %s with the macro name.
    StaticPopupDialogs["WSMB_CONFIRM_DELETE"] = {
        text = "Delete macro '%s'?\n\nThis cannot be undone.",
        button1 = DELETE or "Delete",
        button2 = CANCEL or "Cancel",
        OnAccept = function(self, data)
            if not data or not data.abs then return end
            local deletedName = GetMacroInfo(data.abs)
            local ok, err = ns.MacroAPI:DeleteAt(data.abs)
            if ok then
                if state.editingAbsSlot == data.abs then state.editingAbsSlot = nil end
                local count = ns.MacroAPI:CountScope(state.scope)
                if state.browseIndex > count then state.browseIndex = math.max(1, count) end
                updatePickerLabel()
                updateModeHint()
                flashStatus(("Deleted: %s"):format(deletedName or "?"), C_WARN)
            else
                flashStatus(err or "Delete failed.", C_ERROR)
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    deleteBtn:SetScript("OnClick", function()
        local abs = ns.MacroAPI:AbsByBrowse(state.scope, state.browseIndex)
        if not abs then flashStatus("Nothing to delete.", C_WARN); return end
        local name = GetMacroInfo(abs) or "?"
        local dialog = StaticPopup_Show("WSMB_CONFIRM_DELETE", name)
        if dialog then dialog.data = { abs = abs } end
    end)

    saveBtn:SetScript("OnClick", function()
        local name = nameEdit:GetText() or ""
        local body = editBox:GetText() or ""
        local icon = WICKSMACROBUILDERDB.lastIcon or "INV_Misc_QuestionMark"

        if state.editingAbsSlot then
            local ok, err = ns.MacroAPI:EditAt(state.editingAbsSlot, name, icon, body)
            if ok then
                WICKSMACROBUILDERDB.lastMacroName = name
                WICKSMACROBUILDERDB.lastBody = body
                WICKSMACROBUILDERDB.lastScope = state.scope
                updatePickerLabel()
                flashStatus(("Saved changes to slot %d."):format(state.editingAbsSlot), C_GREEN)
            else
                flashStatus(err or "Save failed.", C_ERROR)
            end
        else
            local newAbs, err = ns.MacroAPI:CreateNew(state.scope, name, icon, body)
            if newAbs then
                WICKSMACROBUILDERDB.lastMacroName = name
                WICKSMACROBUILDERDB.lastBody = body
                WICKSMACROBUILDERDB.lastScope = state.scope
                state.editingAbsSlot = newAbs
                local landedScope, landedBrowse = ns.MacroAPI:BrowseOfAbs(newAbs)
                if landedScope then
                    state.scope = landedScope
                    state.browseIndex = landedBrowse
                    updateScopeVisuals()
                end
                updatePickerLabel()
                updateModeHint()
                flashStatus(("Created new macro at slot %d."):format(newAbs), C_GREEN)
            else
                flashStatus(err or "Save failed.", C_ERROR)
            end
        end
    end)

    frame.nameEdit = nameEdit
    frame.editBox = editBox
end

-- ============================================================
-- Build — called once on ADDON_LOADED
-- ============================================================
function UI:Build()
    if frame then return end
    frame = CreateFrame("Frame", "WICKSMACROBUILDERFrame", UIParent)
    local savedW = WICKSMACROBUILDERDB and WICKSMACROBUILDERDB.width  or FRAME_W
    local savedH = WICKSMACROBUILDERDB and WICKSMACROBUILDERDB.height or FRAME_H
    frame:SetSize(savedW, savedH)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(FRAME_W, FRAME_H)        -- modern API (10.x)
    elseif frame.SetMinResize then
        frame:SetMinResize(FRAME_W, FRAME_H)            -- classic API
    end
    frame:EnableMouse(true)
    frame:SetFrameStrata("DIALOG")
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScript("OnSizeChanged", function(self)
        WICKSMACROBUILDERDB.width  = self:GetWidth()
        WICKSMACROBUILDERDB.height = self:GetHeight()
        if editBox then
            editBox:SetWidth(self:GetWidth() - 2 * FRAME_PAD - 32)
        end
        if selectedSource then renderSource() end
    end)
    frame:Hide()

    local bg = newTex(frame, "BACKGROUND", C_BG); bg:SetAllPoints()
    addBorder(frame)

    -- Header
    local header = newTex(frame, "ARTWORK", C_HEADER_BG)
    header:SetPoint("TOPLEFT",  1, -1); header:SetPoint("TOPRIGHT", -1, -1); header:SetHeight(HEADER_H)
    local headerSep = newTex(frame, "ARTWORK", C_BORDER)
    headerSep:SetPoint("TOPLEFT",  1, -HEADER_H - 1); headerSep:SetPoint("TOPRIGHT", -1, -HEADER_H - 1); headerSep:SetHeight(1)

    local title = newText(frame, 12, C_TEXT_NORMAL); title:SetPoint("LEFT", frame, "TOPLEFT", 10, -HEADER_H / 2)
    title:SetText("Wick's Macro Builder")

    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(HEADER_H - 4, HEADER_H - 4)
    closeBtn:SetPoint("RIGHT", frame, "TOPRIGHT", -4, -HEADER_H / 2)
    local closeText = newText(closeBtn, 14, C_TEXT_NORMAL); closeText:SetPoint("CENTER"); closeText:SetText("×")
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Tab strip: 10 tabs, 5 per row
    for i, source in ipairs(SOURCES) do
        local tab = makeTab(source)
        local col = (i - 1) % 5
        local rowIdx = math.floor((i - 1) / 5)
        tab:SetPoint("TOPLEFT", 4 + col * 114, -(HEADER_H + 2 + rowIdx * (TAB_H + 2)))
        tabs[#tabs + 1] = tab
    end

    -- Separator below tab strip
    local tabSep = newTex(frame, "ARTWORK", C_BORDER)
    tabSep:SetPoint("TOPLEFT",  1, -(HEADER_H + TAB_H * 2 + 4))
    tabSep:SetPoint("TOPRIGHT", -1, -(HEADER_H + TAB_H * 2 + 4))
    tabSep:SetHeight(1)

    -- Source panel headers
    frame.sourceHeader1 = newText(frame, 11, C_GREEN, "LEFT")
    frame.sourceHeader2 = newText(frame, 11, C_GREEN, "LEFT")
    frame.emptyPresets  = newText(frame, 10, C_TEXT_DIM, "LEFT")
    frame.emptyPresets:Hide()

    -- Editor + save panel at bottom
    buildEditorPanel()

    -- Mode hint strip (sits just above the slot/scope row, below the editor)
    frame.modeHint = newText(frame, 10, C_TEXT_DIM, "LEFT")
    frame.modeHint:SetPoint("BOTTOMLEFT", FRAME_PAD, EDITOR_BOTTOM + SAVE_ROW_H + SLOT_ROW_H)
    frame.modeHint:SetPoint("BOTTOMRIGHT", -FRAME_PAD, EDITOR_BOTTOM + SAVE_ROW_H + SLOT_ROW_H)
    frame.modeHint:SetText("No macro loaded — Save creates a new one.")

    -- Restore last scope before first render (affects picker label).
    state.scope = WICKSMACROBUILDERDB.lastScope or "global"
    state.browseIndex = 1
    state.editingAbsSlot = nil

    -- Initial render
    refreshTabVisuals()
    renderSource()
    frame.updateScopeVisuals()
    frame.updateModeHint()
    updateCharCount()

    -- Restore last-edited body into the editor as a convenience; Save will
    -- create a new macro (editingAbsSlot is nil on fresh load).
    if WICKSMACROBUILDERDB.lastMacroName then frame.nameEdit:SetText(WICKSMACROBUILDERDB.lastMacroName) end
    if WICKSMACROBUILDERDB.lastBody then
        frame.editBox:SetText(WICKSMACROBUILDERDB.lastBody)
        updateCharCount()
    end

    -- BOTTOMRIGHT resize grip. The fel-green L-bracket is parented to this
    -- button (see addCorners below) so the bracket itself is the grip.
    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(BRACKET + 2, BRACKET + 2)
    grip:SetPoint("BOTTOMRIGHT", 0, 0)
    grip:EnableMouse(true)
    grip:SetScript("OnMouseDown", function(_, btn)
        if btn == "LeftButton" then frame:StartSizing("BOTTOMRIGHT") end
    end)
    grip:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)

    addCorners(frame, grip)

    self.frame = frame
end

function UI:Refresh()
    if not frame then return end
    refreshTabVisuals()
    renderSource()
end

function UI:Toggle()
    if not frame then self:Build() end
    if frame:IsShown() then frame:Hide() else
        if frame.updatePickerLabel then frame.updatePickerLabel() end
        frame:Show()
    end
end
