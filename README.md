<p align="center"><img src="images/wick-thumb-macro.png" alt="Wick's Macro Builder"></p>

# Wick's Macro Builder

> A clean macro editor for TBC Classic. Build your macro with click-to-insert chips, pick an icon, then drag it straight onto your action bars — no switching to Blizzard's macro window.

Part of the **[Wick suite](https://github.com/Wicksmods/WickSuite)** — precision TBC Classic addons with a shared fel-green-on-deep-purple aesthetic.

<!-- wick:suite-table:start -->
| Addon | GitHub | CurseForge |
|---|---|---|
| **Wick's TBC BIS Tracker** | [repo](https://github.com/Wicksmods/WickidsTBCBISTracker) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-tbc-bis-tracker) |
| **Wick's CD Tracker** | [repo](https://github.com/Wicksmods/WicksCDTracker) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-cd-tracker) |
| **Wick's Trade Hall** | [repo](https://github.com/Wicksmods/WicksTradeHall) | [CurseForge](https://www.curseforge.com/wow/addons/trade-hall) |
| **Wick's Macro Builder** | [repo](https://github.com/Wicksmods/WicksMacroBuilder) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-macro-builder) |
| **Wick's Combat Log** | [repo](https://github.com/Wicksmods/WicksCombatLog) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-combat-log) |
| **Wick's UI** | [repo](https://github.com/Wicksmods/WicksUI) | *(ElvUI plugin — pending)* |
<!-- wick:suite-table:end -->

## Features

- **Drag macros to your action bars from inside the builder.** Right-side icon strip shows every macro in the current scope with its real icon. Click to load into the editor, drag onto any action-bar slot to equip. No more switching to `/macro`.
- **Icon picker** — click the `?` button next to Name to pick any macro-eligible icon (`GetMacroIcons` + `GetMacroItemIcons`). Raid macros stop all looking like identical `?` icons.
- **General tab** — one-click insertion of 20 conditionals (`@mouseover`, `@focus`, `[help]`, `[harm]`, `[mod:shift]`, `[stance:…]`, `[form:…]`, and more) and 18 slash commands (`#showtooltip`, `/cast`, `/castsequence`, `/cancelaura`, `/cancelform`, `/stopcasting`, `/use`, `/petattack`, `/focus`, and the rest). Hover any chip for a plain-English description.
- **Class preset library** — 54 curated TBC-correct macros across all 9 classes (Cat+Dash, IF+Trinket+PoH, NS+Healing Wave, Bubblehearth, Stance-swap + ability, etc.). Click a preset to load it into the editor as a starting point.
- **Live 255-character counter** — green → amber → red as you approach the macro cap.
- **Smart save flow** — click an existing icon to load-and-edit-in-place, or clear and hit **Create New** to append. Mode hint strip tells you which is which.
- **Confirmation before delete** — popup prevents mis-click nukes.
- **Global and Per-Character scope** — toggle at the top of the icon strip.
- **Resizable** — BOTTOMRIGHT fel-green bracket doubles as the grip; chips, presets, and editor reflow.

## Install

- **CurseForge:** [curseforge.com/wow/addons/macro-builder](https://www.curseforge.com/wow/addons/macro-builder)
- **Manual:** download the latest ZIP from [Releases](https://github.com/Wicksmods/WicksMacroBuilder/releases) and extract the `WicksMacroBuilder` folder into `World of Warcraft\_classic_\Interface\AddOns\`.

## Usage

```
/wsmb
```

Opens the builder. Drag the header to move, drag the BOTTOMRIGHT fel-green bracket to resize. Click chips to insert snippets at the cursor; click preset names to load a full macro body; click an icon in the right strip to load an existing macro; drag an icon from the strip onto your action bar.

## Compatibility

- **TBC Classic (Burning Crusade / Anniversary)** — Interface `20505`.

## Brand

Uses the locked Wick palette and 10px/2px fel-green L-bracket chrome. See:
- `UI.lua` — tokens at the top of the file
- `CHANGELOG.md` — version history
- `logo.svg` — logomark source

## License

See `LICENSE` — MIT with a trademark carve-out for the Wick name, logomark, and visual system. Full trademark policy: [WickSuite/TRADEMARK.md](https://github.com/Wicksmods/WickSuite/blob/main/TRADEMARK.md).
