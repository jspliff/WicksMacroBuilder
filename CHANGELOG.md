# Wick's Macro Builder — Changelog

## 0.2.1 — 2026-04-25

### Title bar harmonization

Header now matches the canonical Wick suite spec — taller (32px), two-tone title (`Wick's` in fel-green, `Macro Builder` in cream, FRIZQT 14 outlined), bordered ✕ close button, fel-green underline at the bottom of the header, drag-by-header.

No functional changes.

## 0.2.0 — 2026-04-22

### Icon strip + drag-to-bar + icon picker

Major UX rework. Instead of saving to a numbered slot and then switching to Blizzard's macro UI to drag a macro onto your action bars, you can now drag macros straight from Wick's Macro Builder.

- **Icon strip on the right side** — vertical scrollable column showing every macro in the currently-selected scope, with its real icon and a fel-green highlight on the macro that's loaded in the editor.
- **Drag to action bar** — left-drag any icon in the strip onto any action-bar slot. Uses `PickupMacro` under the hood. Blocked in combat with a status message.
- **Click to load** — left-click an icon in the strip to load that macro into the editor (replaces the old `Load from Slot` button).
- **Icon picker** — click the new `?` button next to the Name field to open a popup grid of every macro-eligible icon (`GetMacroIcons` + `GetMacroItemIcons`). Pick one and it's saved with the macro.
- **Scope toggle moved** into the top of the icon strip (`Global` / `Char` buttons).
- **Removed** the numbered slot picker (`◄ N/M ►`) and the `Load from Slot` button — icon-based interaction replaces both.
- **Responsive layout** — chips, preset rows, editor, name row, save row, and mode hint all reflow when you resize the frame (BOTTOMRIGHT fel-green bracket is still the grip).
- **Delete** now confirms before removing a macro (StaticPopup) and operates on whichever macro is currently loaded.

## 0.1.0 — 2026-04-22

### Initial release

Brand-consistent with the rest of the [Wick suite](https://github.com/Wicksmods/WickSuite).

- Tabbed panel: **General** + 9 class tabs (Druid, Priest, Shaman, Paladin, Mage, Warlock, Warrior, Rogue, Hunter).
- **General tab** — clickable chips for 20 macro conditionals (`@mouseover`, `@focus`, `@player`, `@target`, `help`, `harm`, `exists`, `nodead`, `mod:shift/ctrl/alt`, `combat`, `nocombat`, `stance:1/3`, `form:3`, `stealth`, `nostealth`, and common combos) and 18 slash commands (`#showtooltip`, `/cast`, `/castsequence`, `/use`, `/stopcasting`, `/cancelaura`, `/cancelform`, `/stopattack`, `/startattack`, `/target`, `/focus`, `/clearfocus`, `/petattack`, `/petfollow`, `/dismount`, `/equip`, `/stopmacro`, `/run`).
- **Class tabs** — 6 curated TBC macros per class (54 presets total). Click a preset to load it into the editor.
- **Editor** — multi-line EditBox with live 255-character counter (green → amber → red).
- **Save-to-slot** — scope radios for Global vs Per-Character, browse picker for existing macros, separate Create New / Save Changes states. Mode hint strip tells you whether Save will append a new macro or overwrite the loaded one.
- **Load** loads the browsed macro into the editor; **Delete** removes it.
- Flat dark-purple panel + fel-green L-bracket chrome. Slash command: `/wsmb`.
