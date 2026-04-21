<p align="center"><img src="images/wick-thumb-macro-builder.png" alt="Wick's Macro Builder"></p>

# Wick's Macro Builder

> A clean macro editor for TBC Classic with conditional chips, common-command shortcuts, and curated class presets (Druid, Priest, Shaman, Paladin, Mage, Warlock, Warrior, Rogue, Hunter).

Part of the **[Wick suite](https://github.com/jspliff/WickSuite)** — precision TBC Classic addons with a shared fel-green-on-deep-purple aesthetic.

<!-- wick:suite-table:start -->
| Addon | GitHub | CurseForge |
|---|---|---|
| **Wick's TBC BIS Tracker** | [repo](https://github.com/jspliff/WickidsTBCBISTracker) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-tbc-bis-tracker) |
| **Wick's CD Tracker** | [repo](https://github.com/jspliff/WicksCDTracker) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-cd-tracker) |
| **Wick's Trade Hall** | [repo](https://github.com/jspliff/WicksTradeHall) | [CurseForge](https://www.curseforge.com/wow/addons/trade-hall) |
| **Wick's Macro Builder** | [repo](https://github.com/jspliff/WicksMacroBuilder) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-macro-builder) |
<!-- wick:suite-table:end -->

## Features

- **General tab** — one-click insertion of `@mouseover`, `@focus`, `[mod:shift]`, `[help]`, `[harm]`, `[stance:…]`, `[form:…]` and other conditionals.
- **Command chips** — `#showtooltip`, `/cast`, `/castsequence`, `/cancelaura`, `/cancelform`, `/stopcasting`, `/use`, `/petattack` and more.
- **Class preset library** — curated TBC macros for all 9 classes (Cat+Dash, IF+Trinket+PoH, NS+Healing Wave, Bubblehearth, Stance-swap + ability, etc.). Click a preset to load it into the editor.
- **Live 255-character counter** — green → amber → red as you approach the macro cap.
- **Save to slot** — choose Global or Per-Character scope, pick a slot, save.
- **No combat lockdown issues** — the addon only edits macro text; your action bars aren't touched.

## Install

- **CurseForge:** [curseforge.com/wow/addons/macro-builder](https://www.curseforge.com/wow/addons/macro-builder)
- **Manual:** download the latest ZIP from [Releases](https://github.com/jspliff/WicksMacroBuilder/releases) and extract the `WicksMacroBuilder` folder into `World of Warcraft\_classic_\Interface\AddOns\`.

## Usage

```
/wsmb
```

Opens the builder. Drag the header to move. Click chips to insert snippets at the cursor; click preset names to load a full macro body.

## Compatibility

- **TBC Classic (Burning Crusade / Anniversary)** — Interface `20505`.

## Brand

Uses the locked Wick palette and 10px/2px fel-green L-bracket chrome. See:
- `UI.lua` — tokens at the top of the file
- `CHANGELOG.md` — version history
- `logo.svg` — logomark source

## License

See `LICENSE` — MIT with a trademark carve-out for the Wick name, logomark, and visual system. Full trademark policy: [WickSuite/TRADEMARK.md](https://github.com/jspliff/WickSuite/blob/main/TRADEMARK.md).
