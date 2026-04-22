# Wick's Macro Builder — Changelog

## 0.1.0 — 2026-04-22

- (edit this entry with the actual changes)

## 0.1.0 — 2026-04-21

### Initial release

Brand-consistent with the rest of the [Wick suite](https://github.com/jspliff/WickSuite).

- Tabbed panel: **General** + 9 class tabs (Druid, Priest, Shaman, Paladin, Mage, Warlock, Warrior, Rogue, Hunter).
- **General tab** — clickable chips for 20 macro conditionals (`@mouseover`, `@focus`, `@player`, `@target`, `help`, `harm`, `exists`, `nodead`, `mod:shift/ctrl/alt`, `combat`, `nocombat`, `stance:1/3`, `form:3`, `stealth`, `nostealth`, and common combos) and 18 slash commands (`#showtooltip`, `/cast`, `/castsequence`, `/use`, `/stopcasting`, `/cancelaura`, `/cancelform`, `/stopattack`, `/startattack`, `/target`, `/focus`, `/clearfocus`, `/petattack`, `/petfollow`, `/dismount`, `/equip`, `/stopmacro`, `/run`).
- **Class tabs** — 6 curated TBC macros per class (54 presets total). Click a preset to load it into the editor.
- **Editor** — multi-line EditBox with live 255-character counter (green → amber → red).
- **Save-to-slot** — scope radios for Global vs Per-Character, browse picker for existing macros, separate Create New / Save Changes states. Mode hint strip tells you whether Save will append a new macro or overwrite the loaded one.
- **Load** loads the browsed macro into the editor; **Delete** removes it.
- Flat dark-purple panel + fel-green L-bracket chrome. Slash command: `/wsmb`.
