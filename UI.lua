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

local BRACKET        = 10
local HEADER_H       = 22
local TAB_H          = 22
local FRAME_W        = 580
local FRAME_H        = 510
local FRAME_PAD      = 10
local ICON_STRIP_W   = 80     -- right-side column holding scope toggle + macro icons
local ICON_STRIP_GAP = 4      -- gap between source/editor content and the icon strip
-- Distance from frame's right edge where the content area (editor, name row,
-- save row, mode hint) must stop. Using a BOTTOMRIGHT/-RIGHT_INSET anchor
-- means content grows with the frame on resize while still leaving room for
-- the icon strip.
local RIGHT_INSET    = ICON_STRIP_W + ICON_STRIP_GAP + FRAME_PAD
local DEFAULT_ICON   = "INV_Misc_QuestionMark"

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
local iconStripPool = {}

-- Right edge x for source-panel content (chips + preset rows) and editor
-- section — leaves room for the icon strip on the right.
local CONTENT_RIGHT_EDGE = FRAME_W - ICON_STRIP_W - ICON_STRIP_GAP

-- State for the editor + save controls.
--   scope           : "global" | "char" — which scope new saves go into
--   editingAbsSlot  : absolute slot of the macro currently loaded in the
--                     editor (nil = Save creates new, non-nil = Save overwrites)
--   chosenIcon      : icon to save with the macro. Taken from the macro when
--                     loaded, picked via the icon popup, or DEFAULT on new.
local state = {
    scope = "global",
    editingAbsSlot = nil,
    chosenIcon = DEFAULT_ICON,
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

local function addCorners(f, resizeHost)
    for _, point in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
        local host = (point == "BOTTOMRIGHT" and resizeHost) or f
        local h = host:CreateTexture(nil, "OVERLAY")
        h:SetColorTexture(unpack(C_GREEN))
        h:SetPoint(point, host, point, 0, 0)
        h:SetSize(BRACKET, 2)
        local v = host:CreateTexture(nil, "OVERLAY")
        v:SetColorTexture(unpack(C_GREEN))
        v:SetPoint(point, host, point, 0, 0)
        v:SetSize(2, BRACKET)
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
-- The editor (multi-line EditBox inside a ScrollFrame)
-- ============================================================
local editBox, editScroll, charCount, nameEdit, iconPickerBtn
local scopeButtons = {}          -- { [scope] = button } — scope toggle at top of icon strip
local flashStatus                -- set inside buildEditorPanel, used by refreshIconList etc.

-- Measurement FontString for chip widths (unanchored so GetStringWidth returns
-- intrinsic text width, not a width-constrained wrap).
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
    local w = math.max(44, math.ceil(_measureFS:GetStringWidth()) + 20)
    _widthCache[label] = w
    return w
end

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
-- Chip (clickable snippet button)
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

local function layoutChips(startIndex, items, topY, parentRightEdge, color)
    local x = FRAME_PAD
    local y = topY
    local rowH = 22
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
-- Preset row (class tabs)
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

local SOURCE_TOP = HEADER_H + TAB_H * 2 + 6

local function hideAllChips()
    for _, c in ipairs(chipPool) do c:Hide() end
    for _, r in ipairs(presetRowPool) do r:Hide() end
end

-- Returns the current content right-edge x (in pixels from frame's left).
-- Re-evaluated on each render so chips + preset rows reflow on resize.
local function contentRightEdge()
    local fw = frame and frame:GetWidth() or FRAME_W
    return fw - ICON_STRIP_W - ICON_STRIP_GAP
end

local function renderGeneralSource()
    hideAllChips()
    local header1 = frame.sourceHeader1
    header1:SetText("Conditionals")
    header1:Show()
    header1:ClearAllPoints()
    header1:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PAD, -(SOURCE_TOP + 2))

    local y = -(SOURCE_TOP + 18)
    local rightEdge = contentRightEdge()
    local nextIdx = 1
    y, nextIdx = layoutChips(nextIdx, ns.CONDITIONALS, y, rightEdge, C_GREEN)

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
        -- Preset row ends at the current content right edge (before the icon
        -- strip). Uses -RIGHT_INSET so it tracks the frame on resize.
        row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -RIGHT_INSET, y)
        row:SetHeight(22)
        row.nameText:SetText(preset.name)
        row.hintText:SetText(preset.hint or "")
        row:SetScript("OnClick", function()
            if nameEdit then nameEdit:SetText(preset.name) end
            if editBox then
                editBox:SetText(preset.body or "")
                editBox:SetCursorPosition(#(preset.body or ""))
                updateCharCount()
            end
            -- Loading a preset = new-macro intent. Clear edit target and reset
            -- the chosen icon to the default ? (user can pick one before save).
            state.editingAbsSlot = nil
            state.chosenIcon = DEFAULT_ICON
            if frame.updateModeHint then frame.updateModeHint() end
            if frame.updateCurrentIconBtn then frame.updateCurrentIconBtn() end
            if frame.refreshIconList then frame.refreshIconList() end
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
-- Icon picker popup (opened from the name-row "current icon" button)
-- ============================================================
local iconPicker
local function ensureIconPicker()
    if iconPicker then return iconPicker end
    iconPicker = CreateFrame("Frame", "WICKSMACROBUILDERIconPicker", UIParent)
    iconPicker:SetSize(336, 420)
    iconPicker:SetPoint("CENTER")
    iconPicker:SetFrameStrata("TOOLTIP")
    iconPicker:SetMovable(true)
    iconPicker:EnableMouse(true)
    iconPicker:RegisterForDrag("LeftButton")
    iconPicker:SetScript("OnDragStart", iconPicker.StartMoving)
    iconPicker:SetScript("OnDragStop", iconPicker.StopMovingOrSizing)

    local bg = newTex(iconPicker, "BACKGROUND", C_BG); bg:SetAllPoints()
    addBorder(iconPicker)

    -- Header
    local h = newTex(iconPicker, "ARTWORK", C_HEADER_BG)
    h:SetPoint("TOPLEFT", 1, -1); h:SetPoint("TOPRIGHT", -1, -1); h:SetHeight(HEADER_H)
    local t = newText(iconPicker, 12, C_TEXT_NORMAL)
    t:SetPoint("LEFT", iconPicker, "TOPLEFT", 10, -HEADER_H/2)
    t:SetText("Choose Icon")

    local closeBtn = CreateFrame("Button", nil, iconPicker)
    closeBtn:SetSize(HEADER_H-4, HEADER_H-4)
    closeBtn:SetPoint("RIGHT", iconPicker, "TOPRIGHT", -4, -HEADER_H/2)
    local closeText = newText(closeBtn, 14, C_TEXT_NORMAL); closeText:SetPoint("CENTER"); closeText:SetText("×")
    closeBtn:SetScript("OnClick", function() iconPicker:Hide() end)

    iconPicker:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then self:Hide() end
    end)
    iconPicker:EnableKeyboard(true)

    -- Scrollable icon grid
    local scroll = CreateFrame("ScrollFrame", nil, iconPicker, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -(HEADER_H + 6))
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(300, 1)   -- width will track scroll, height set after populate
    scroll:SetScrollChild(child)

    local icons = {}
    if GetMacroIcons then GetMacroIcons(icons) end
    if GetMacroItemIcons then GetMacroItemIcons(icons) end

    local COLS = 8
    local ICON_SIZE = 32
    local PAD = 2
    local rows = math.ceil(#icons / COLS)
    child:SetHeight(math.max(1, rows * (ICON_SIZE + PAD) + PAD))

    for i, iconRef in ipairs(icons) do
        local col = (i-1) % COLS
        local row = math.floor((i-1) / COLS)
        local b = CreateFrame("Button", nil, child)
        b:SetSize(ICON_SIZE, ICON_SIZE)
        b:SetPoint("TOPLEFT", PAD + col * (ICON_SIZE + PAD), -PAD - row * (ICON_SIZE + PAD))
        local tex = b:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        -- iconRef is a fileID (number) in modern clients, bare name in older.
        -- SetTexture accepts both. For bare-name strings we prepend the path.
        if type(iconRef) == "number" then
            tex:SetTexture(iconRef)
        else
            tex:SetTexture("Interface\\Icons\\" .. iconRef)
        end
        b.iconRef = iconRef
        b:SetScript("OnClick", function(self)
            state.chosenIcon = self.iconRef
            if frame and frame.updateCurrentIconBtn then frame.updateCurrentIconBtn() end
            iconPicker:Hide()
        end)
        b:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(unpack(C_GREEN))  -- no-op if no backdrop; harmless
        end)
    end

    iconPicker:Hide()
    return iconPicker
end

local function setIconTextureOn(tex, iconRef)
    if type(iconRef) == "number" then
        tex:SetTexture(iconRef)
    elseif type(iconRef) == "string" and iconRef ~= "" then
        if iconRef:find("\\") or iconRef:find("/") then
            tex:SetTexture(iconRef)
        else
            tex:SetTexture("Interface\\Icons\\" .. iconRef)
        end
    else
        tex:SetTexture("Interface\\Icons\\" .. DEFAULT_ICON)
    end
end

-- ============================================================
-- Icon strip (right side of frame below tab strip)
-- ============================================================
-- Populated lazily; refreshIconList enumerates existing macros in the current
-- scope and creates / reuses buttons to show them. Each button:
--   • shows the macro's stored icon (fileID or texture name)
--   • Click   → load macro into editor (sets editingAbsSlot, chosenIcon)
--   • Drag    → PickupMacro(absSlot) so you can drop onto an action bar
local iconStripScroll, iconStripChild
local ICON_CELL = 40
local ICON_GAP  = 4

local refreshIconList  -- forward decl

local function getIconStripBtn(i)
    if iconStripPool[i] then return iconStripPool[i] end
    local b = CreateFrame("Button", nil, iconStripChild)
    b:SetSize(ICON_CELL, ICON_CELL)
    b:RegisterForClicks("LeftButtonUp")
    b:RegisterForDrag("LeftButton")

    local bg = newTex(b, "BACKGROUND", C_INPUT_BG); bg:SetAllPoints()
    addInnerBorder(b)

    local tex = b:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT", 2, -2); tex:SetPoint("BOTTOMRIGHT", -2, 2)
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.tex = tex

    -- Fel-green selection highlight (shown when this is the loaded macro).
    local hl = newTex(b, "OVERLAY")
    hl:SetColorTexture(C_GREEN[1], C_GREEN[2], C_GREEN[3], 0.25)
    hl:SetPoint("TOPLEFT", 1, -1); hl:SetPoint("BOTTOMRIGHT", -1, 1)
    hl:Hide()
    b.highlight = hl

    b:SetScript("OnClick", function(self)
        if not self.absSlot then return end
        local abs, name, icon, body = ns.MacroAPI:GetByBrowse(state.scope, self.browseIndex)
        if not abs then return end
        if nameEdit then nameEdit:SetText(name) end
        if editBox then
            editBox:SetText(body or "")
            editBox:SetCursorPosition(#(body or ""))
            updateCharCount()
        end
        state.editingAbsSlot = abs
        state.chosenIcon = icon or DEFAULT_ICON
        if frame.updateModeHint then frame.updateModeHint() end
        if frame.updateCurrentIconBtn then frame.updateCurrentIconBtn() end
        if refreshIconList then refreshIconList() end
        if flashStatus then flashStatus(("Loaded: %s"):format(name), C_GREEN) end
    end)

    b:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then
            if flashStatus then flashStatus("Cannot drag macros in combat.", C_WARN) end
            return
        end
        if self.absSlot then
            PickupMacro(self.absSlot)
        end
    end)

    b:SetScript("OnEnter", function(self)
        if not self.macroName then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(self.macroName, 1, 0.9, 0.6)
        GameTooltip:AddLine(("Slot %d"):format(self.absSlot or 0), 0.7, 0.7, 0.7)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to load · Drag to action bar", 0.5, 0.8, 0.5)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    iconStripPool[i] = b
    return b
end

refreshIconList = function()
    if not iconStripChild then return end
    local scope = state.scope
    local count = ns.MacroAPI:CountScope(scope)
    local totalH = ICON_GAP + count * (ICON_CELL + ICON_GAP)
    iconStripChild:SetHeight(math.max(1, totalH))

    for i = 1, count do
        local abs, name, icon = ns.MacroAPI:GetByBrowse(scope, i)
        local btn = getIconStripBtn(i)
        btn.absSlot    = abs
        btn.browseIndex = i
        btn.macroName  = name
        setIconTextureOn(btn.tex, icon)
        btn:ClearAllPoints()
        btn:SetPoint("TOP", iconStripChild, "TOP", 0, -(ICON_GAP + (i-1) * (ICON_CELL + ICON_GAP)))
        if state.editingAbsSlot and state.editingAbsSlot == abs then
            btn.highlight:Show()
        else
            btn.highlight:Hide()
        end
        btn:Show()
    end
    for i = count + 1, #iconStripPool do iconStripPool[i]:Hide() end
end

local function buildIconStrip()
    -- Container
    local strip = CreateFrame("Frame", nil, frame)
    strip:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -FRAME_PAD/2, -(HEADER_H + TAB_H*2 + 6))
    strip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -FRAME_PAD/2, FRAME_PAD/2)
    strip:SetWidth(ICON_STRIP_W - FRAME_PAD/2)
    local stripBg = newTex(strip, "BACKGROUND", C_HEADER_BG); stripBg:SetAllPoints()
    addInnerBorder(strip)

    -- Scope toggle: two buttons side-by-side at the top of the strip.
    local SCOPE_BTN_W = math.floor((ICON_STRIP_W - FRAME_PAD/2 - 12 - 4) / 2)
    local SCOPE_BTN_H = 20
    local scopeRow = CreateFrame("Frame", nil, strip)
    scopeRow:SetPoint("TOPLEFT", 6, -6)
    scopeRow:SetPoint("TOPRIGHT", -6, -6)
    scopeRow:SetHeight(SCOPE_BTN_H)

    local function makeScopeBtn(label, scope)
        local b = makeButton(scopeRow, label, SCOPE_BTN_W, SCOPE_BTN_H)
        b.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        b.scope = scope
        b:SetScript("OnClick", function()
            if state.scope == scope then return end
            state.scope = scope
            state.editingAbsSlot = nil
            state.chosenIcon = DEFAULT_ICON
            if frame.updateScopeVisuals then frame.updateScopeVisuals() end
            if frame.updateModeHint then frame.updateModeHint() end
            if frame.updateCurrentIconBtn then frame.updateCurrentIconBtn() end
            refreshIconList()
        end)
        scopeButtons[scope] = b
        return b
    end
    local btnGlobal = makeScopeBtn("Global", "global")
    btnGlobal:SetPoint("LEFT", 0, 0)
    local btnChar   = makeScopeBtn("Char", "char")
    btnChar:SetPoint("LEFT", btnGlobal, "RIGHT", 4, 0)

    -- Scrollable icon list
    iconStripScroll = CreateFrame("ScrollFrame", nil, strip, "UIPanelScrollFrameTemplate")
    iconStripScroll:SetPoint("TOPLEFT", 6, -(SCOPE_BTN_H + 10))
    iconStripScroll:SetPoint("BOTTOMRIGHT", -22, 6)
    iconStripChild = CreateFrame("Frame", nil, iconStripScroll)
    iconStripChild:SetSize(ICON_STRIP_W - FRAME_PAD/2 - 24, 1)
    iconStripScroll:SetScrollChild(iconStripChild)

    local function updateScopeVisuals()
        for scope, btn in pairs(scopeButtons) do
            if state.scope == scope then
                btn.bg:SetColorTexture(C_TAB_BG_SEL[1], C_TAB_BG_SEL[2], C_TAB_BG_SEL[3], 1)
                btn.text:SetTextColor(C_GREEN[1], C_GREEN[2], C_GREEN[3], 1)
            else
                btn.bg:SetColorTexture(C_TAB_BG[1], C_TAB_BG[2], C_TAB_BG[3], 1)
                btn.text:SetTextColor(C_TEXT_NORMAL[1], C_TEXT_NORMAL[2], C_TEXT_NORMAL[3], 1)
            end
        end
    end
    frame.updateScopeVisuals = updateScopeVisuals
    frame.refreshIconList    = refreshIconList
end

-- ============================================================
-- Editor + save panel (bottom of frame, left of icon strip)
-- ============================================================
local EDITOR_BOTTOM = 10
local SAVE_ROW_H    = 24
local EDITOR_H      = 96
local NAME_ROW_H    = 24

local function buildEditorPanel()
    -- Save row (bottom-most)
    local saveRow = CreateFrame("Frame", nil, frame)
    saveRow:SetHeight(SAVE_ROW_H)
    saveRow:SetPoint("BOTTOMLEFT",  FRAME_PAD, EDITOR_BOTTOM)
    saveRow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -RIGHT_INSET, EDITOR_BOTTOM)

    local saveBtn = makeButton(saveRow, "Save to Slot", 110, SAVE_ROW_H)
    saveBtn.text:SetTextColor(C_GREEN[1], C_GREEN[2], C_GREEN[3], 1)
    saveBtn:SetPoint("RIGHT", 0, 0)

    local deleteBtn = makeButton(saveRow, "Delete", 70, SAVE_ROW_H)
    deleteBtn:SetPoint("RIGHT", saveBtn, "LEFT", -6, 0)

    local newBtn = makeButton(saveRow, "Clear", 60, SAVE_ROW_H)
    newBtn:SetPoint("LEFT", 0, 0)

    -- Editor
    local editFrame = CreateFrame("Frame", nil, frame)
    editFrame:SetHeight(EDITOR_H)
    editFrame:SetPoint("BOTTOMLEFT",  FRAME_PAD, EDITOR_BOTTOM + SAVE_ROW_H + 8)
    editFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -RIGHT_INSET, EDITOR_BOTTOM + SAVE_ROW_H + 8)
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
    editBox:SetWidth(CONTENT_RIGHT_EDGE - 2 * FRAME_PAD - 32)
    editBox:SetHeight(EDITOR_H - 12)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnTextChanged", function() updateCharCount() end)
    editBox:SetTextColor(C_TEXT_NORMAL[1], C_TEXT_NORMAL[2], C_TEXT_NORMAL[3], 1)
    editScroll:SetScrollChild(editBox)

    charCount = newText(frame, 10, C_GREEN, "RIGHT")
    charCount:SetPoint("BOTTOMRIGHT", editFrame, "TOPRIGHT", 0, 2)
    charCount:SetText("0/255")

    -- Name row: Name label + name editbox + current-icon button
    local nameRow = CreateFrame("Frame", nil, frame)
    nameRow:SetHeight(NAME_ROW_H)
    nameRow:SetPoint("BOTTOMLEFT",  FRAME_PAD, EDITOR_BOTTOM + SAVE_ROW_H + EDITOR_H + 12)
    nameRow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -RIGHT_INSET, EDITOR_BOTTOM + SAVE_ROW_H + EDITOR_H + 12)

    local nameLbl = newText(nameRow, 11, C_TEXT_NORMAL); nameLbl:SetPoint("LEFT", 0, 0); nameLbl:SetText("Name:")

    local nameFrame = CreateFrame("Frame", nil, nameRow)
    nameFrame:SetSize(180, NAME_ROW_H - 2)
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

    -- Current-icon button — click to open icon picker.
    iconPickerBtn = CreateFrame("Button", nil, nameRow)
    iconPickerBtn:SetSize(NAME_ROW_H - 2, NAME_ROW_H - 2)
    iconPickerBtn:SetPoint("LEFT", nameFrame, "RIGHT", 6, 0)
    local ipBg = newTex(iconPickerBtn, "BACKGROUND", C_INPUT_BG); ipBg:SetAllPoints()
    addInnerBorder(iconPickerBtn)
    local ipTex = iconPickerBtn:CreateTexture(nil, "ARTWORK")
    ipTex:SetPoint("TOPLEFT", 2, -2); ipTex:SetPoint("BOTTOMRIGHT", -2, 2)
    ipTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    iconPickerBtn.tex = ipTex
    iconPickerBtn:SetScript("OnClick", function()
        ensureIconPicker():Show()
    end)
    iconPickerBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine("Macro icon", 1, 0.9, 0.6)
        GameTooltip:AddLine("Click to choose a different icon.", 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    iconPickerBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local function updateCurrentIconBtn()
        if iconPickerBtn and iconPickerBtn.tex then
            setIconTextureOn(iconPickerBtn.tex, state.chosenIcon or DEFAULT_ICON)
        end
    end
    frame.updateCurrentIconBtn = updateCurrentIconBtn

    -- Status message (right of name row)
    local statusText = newText(nameRow, 10, C_TEXT_DIM, "RIGHT")
    statusText:SetPoint("RIGHT", 0, 0); statusText:SetPoint("LEFT", iconPickerBtn, "RIGHT", 12, 0)
    frame.statusText = statusText

    flashStatus = function(msg, color)
        statusText:SetText(msg or "")
        setTextColor(statusText, color or C_TEXT_DIM)
    end

    -- Mode hint strip (sits just above the save row)
    frame.modeHint = newText(frame, 10, C_TEXT_DIM, "LEFT")
    frame.modeHint:SetPoint("BOTTOMLEFT", FRAME_PAD, EDITOR_BOTTOM + SAVE_ROW_H)
    frame.modeHint:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -RIGHT_INSET, EDITOR_BOTTOM + SAVE_ROW_H)
    frame.modeHint:SetText("No macro loaded — Save creates a new one.")

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
    frame.updateModeHint = updateModeHint

    -- Wire buttons
    newBtn:SetScript("OnClick", function()
        editBox:SetText("")
        nameEdit:SetText("")
        state.editingAbsSlot = nil
        state.chosenIcon = DEFAULT_ICON
        updateCharCount()
        updateModeHint()
        updateCurrentIconBtn()
        if refreshIconList then refreshIconList() end
        flashStatus("Editor cleared. Save will create a new macro.", C_TEXT_DIM)
    end)

    -- Delete requires confirmation so a mis-click doesn't nuke a macro.
    StaticPopupDialogs["WSMB_CONFIRM_DELETE"] = {
        text = "Delete macro '%s'?\n\nThis cannot be undone.",
        button1 = DELETE or "Delete",
        button2 = CANCEL or "Cancel",
        OnAccept = function(self, data)
            if not data or not data.abs then return end
            local deletedName = GetMacroInfo(data.abs)
            local ok, err = ns.MacroAPI:DeleteAt(data.abs)
            if ok then
                if state.editingAbsSlot == data.abs then
                    state.editingAbsSlot = nil
                    state.chosenIcon = DEFAULT_ICON
                    editBox:SetText("")
                    nameEdit:SetText("")
                    updateCharCount()
                end
                updateModeHint()
                updateCurrentIconBtn()
                if refreshIconList then refreshIconList() end
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
        if not state.editingAbsSlot then
            flashStatus("Load a macro from the right strip first.", C_WARN); return
        end
        local abs = state.editingAbsSlot
        local name = GetMacroInfo(abs) or "?"
        local dialog = StaticPopup_Show("WSMB_CONFIRM_DELETE", name)
        if dialog then dialog.data = { abs = abs } end
    end)

    saveBtn:SetScript("OnClick", function()
        local name = nameEdit:GetText() or ""
        local body = editBox:GetText() or ""
        local icon = state.chosenIcon or DEFAULT_ICON

        if state.editingAbsSlot then
            local ok, err = ns.MacroAPI:EditAt(state.editingAbsSlot, name, icon, body)
            if ok then
                WICKSMACROBUILDERDB.lastMacroName = name
                WICKSMACROBUILDERDB.lastBody = body
                WICKSMACROBUILDERDB.lastScope = state.scope
                WICKSMACROBUILDERDB.lastIcon = icon
                if refreshIconList then refreshIconList() end
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
                WICKSMACROBUILDERDB.lastIcon = icon
                state.editingAbsSlot = newAbs
                -- If CreateMacro landed in a different scope than expected, snap.
                local landedScope = ns.MacroAPI:BrowseOfAbs(newAbs)
                if landedScope then state.scope = landedScope end
                updateModeHint()
                if frame.updateScopeVisuals then frame.updateScopeVisuals() end
                if refreshIconList then refreshIconList() end
                flashStatus(("Created new macro at slot %d. Drag the icon on the right onto an action bar."):format(newAbs), C_GREEN)
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
        frame:SetResizeBounds(FRAME_W, FRAME_H)
    elseif frame.SetMinResize then
        frame:SetMinResize(FRAME_W, FRAME_H)
    end
    frame:EnableMouse(true)
    frame:SetFrameStrata("DIALOG")
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScript("OnSizeChanged", function(self)
        WICKSMACROBUILDERDB.width  = self:GetWidth()
        WICKSMACROBUILDERDB.height = self:GetHeight()
        -- editBox width tracks its scroll parent (which now grows with the
        -- frame thanks to the BOTTOMRIGHT/-RIGHT_INSET anchor on editFrame).
        if editBox and editScroll then
            editBox:SetWidth(math.max(40, editScroll:GetWidth()))
        end
        if selectedSource then renderSource() end
    end)
    frame:Hide()

    local bg = newTex(frame, "BACKGROUND", C_BG); bg:SetAllPoints()
    addBorder(frame)

    -- ---- HEADER (slim, plain texture on main frame) ----
    local headerBG = newTex(frame, "BACKGROUND", C_HEADER_BG)
    headerBG:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    headerBG:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    headerBG:SetHeight(HEADER_H)

    -- 1px separator below the header
    local headerSep = newTex(frame, "BORDER", C_BORDER)
    headerSep:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -HEADER_H - 1)
    headerSep:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -HEADER_H - 1)
    headerSep:SetHeight(1)

    -- Title — slim font, two-tone color preserved
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    title:SetText("|cff4FC778Wick's|r |cffD4C8A1Macro Builder|r")
    title:SetPoint("LEFT", frame, "TOPLEFT", 10, -HEADER_H / 2)

    -- Close (×) button — plain text, no border
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(HEADER_H - 4, HEADER_H - 4)
    closeBtn:SetPoint("RIGHT", frame, "TOPRIGHT", -4, -HEADER_H / 2)

    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    closeText:SetText("×")
    closeText:SetTextColor(C_TEXT_NORMAL[1], C_TEXT_NORMAL[2], C_TEXT_NORMAL[3], 1)
    closeText:SetAllPoints()
    closeText:SetJustifyH("CENTER")
    closeText:SetJustifyV("MIDDLE")
    closeBtn:SetScript("OnEnter", function() closeText:SetTextColor(C_GREEN[1], C_GREEN[2], C_GREEN[3], 1) end)
    closeBtn:SetScript("OnLeave", function() closeText:SetTextColor(C_TEXT_NORMAL[1], C_TEXT_NORMAL[2], C_TEXT_NORMAL[3], 1) end)
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

    -- Icon strip on the right (must happen after buildEditorPanel so scope
    -- buttons can reference flashStatus + the frame.update* helpers).
    buildIconStrip()

    -- Restore last state
    state.scope = WICKSMACROBUILDERDB.lastScope or "global"
    state.editingAbsSlot = nil
    state.chosenIcon = WICKSMACROBUILDERDB.lastIcon or DEFAULT_ICON

    -- Initial render
    refreshTabVisuals()
    renderSource()
    if frame.updateScopeVisuals then frame.updateScopeVisuals() end
    frame.updateModeHint()
    frame.updateCurrentIconBtn()
    refreshIconList()
    updateCharCount()

    -- Restore last-edited body into the editor (editingAbsSlot stays nil so
    -- Save creates a new macro — the body is a convenience, not an auto-link).
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
    grip:SetFrameLevel(frame:GetFrameLevel() + 10)   -- above the icon strip

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
    if frame:IsShown() then
        frame:Hide()
    else
        if refreshIconList then refreshIconList() end
        frame:Show()
    end
end
