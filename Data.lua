-- Wick's Macro Builder
-- Data.lua — static content: commands, conditionals, class presets.
-- Edit freely; UI reads these tables on first build.

local _, ns = ...

-- ============================================================
-- Conditional chips — click inserts the snippet into the editor.
-- `insert` is the raw text that gets inserted at the cursor.
-- ============================================================
ns.CONDITIONALS = {
    { label = "@mouseover",     insert = "[@mouseover]",                hint = "Cast on the unit under your cursor." },
    { label = "@focus",         insert = "[@focus]",                    hint = "Cast on your focus target." },
    { label = "@player",        insert = "[@player]",                   hint = "Cast on yourself." },
    { label = "@target",        insert = "[@target]",                   hint = "Cast on your current target." },
    { label = "help",           insert = "[help]",                      hint = "Target must be friendly." },
    { label = "harm",           insert = "[harm]",                      hint = "Target must be hostile." },
    { label = "exists",         insert = "[exists]",                    hint = "Target must exist." },
    { label = "nodead",         insert = "[nodead]",                    hint = "Target must not be dead." },
    { label = "mod:shift",      insert = "[mod:shift]",                 hint = "Only when Shift is held." },
    { label = "mod:ctrl",       insert = "[mod:ctrl]",                  hint = "Only when Ctrl is held." },
    { label = "mod:alt",        insert = "[mod:alt]",                   hint = "Only when Alt is held." },
    { label = "combat",         insert = "[combat]",                    hint = "Only while in combat." },
    { label = "nocombat",       insert = "[nocombat]",                  hint = "Only while out of combat." },
    { label = "stance:1",       insert = "[stance:1]",                  hint = "Warrior: Battle / Druid form 1 (Bear)." },
    { label = "stance:3",       insert = "[stance:3]",                  hint = "Druid form 3 (Cat)." },
    { label = "form:3",         insert = "[form:3]",                    hint = "Druid form 3 (Cat)." },
    { label = "stealth",        insert = "[stealth]",                   hint = "Only while stealthed." },
    { label = "nostealth",      insert = "[nostealth]",                 hint = "Only while not stealthed." },
    { label = "MO+harm",        insert = "[@mouseover,harm,nodead]",    hint = "Cast on hostile unit under cursor." },
    { label = "MO+help",        insert = "[@mouseover,help,nodead]",    hint = "Cast on friendly unit under cursor." },
}

-- ============================================================
-- Command chips — commonly used slash commands. Click inserts.
-- ============================================================
ns.COMMANDS = {
    { label = "#showtooltip",   insert = "#showtooltip",                hint = "Show the next spell/item's tooltip on the macro button." },
    { label = "/cast",          insert = "/cast ",                      hint = "Cast a spell by name." },
    { label = "/castsequence",  insert = "/castsequence reset=combat ", hint = "Cast a sequence of spells, one per press." },
    { label = "/use",           insert = "/use ",                       hint = "Use an item by name. `/use 13` = top trinket, `/use 14` = bottom trinket." },
    { label = "/stopcasting",   insert = "/stopcasting",                hint = "Cancel the current cast immediately." },
    { label = "/cancelaura",    insert = "/cancelaura ",                hint = "Remove a buff from yourself by name." },
    { label = "/cancelform",    insert = "/cancelform",                 hint = "Drop the current druid form / shaman ghost wolf." },
    { label = "/stopattack",    insert = "/stopattack",                 hint = "Stop auto-attacking." },
    { label = "/startattack",   insert = "/startattack",                hint = "Start auto-attacking current target." },
    { label = "/target",        insert = "/target ",                    hint = "Target a unit by name." },
    { label = "/focus",         insert = "/focus",                      hint = "Set current target as focus." },
    { label = "/clearfocus",    insert = "/clearfocus",                 hint = "Clear your focus." },
    { label = "/petattack",     insert = "/petattack",                  hint = "Send pet to attack your target." },
    { label = "/petfollow",     insert = "/petfollow",                  hint = "Recall pet." },
    { label = "/dismount",      insert = "/dismount",                   hint = "Dismount from your current mount." },
    { label = "/equip",         insert = "/equip ",                     hint = "Equip an item by name." },
    { label = "/stopmacro",     insert = "/stopmacro",                  hint = "Halt the rest of the macro on this press." },
    { label = "/run",           insert = "/run ",                       hint = "Run a Lua snippet." },
}

-- ============================================================
-- Class presets — each entry is { name, body, hint? }.
-- Bodies use TBC 2.5.5 syntax and respect the 255-char limit.
-- ============================================================
ns.PRESETS = {}

ns.PRESETS.DRUID = {
    { name = "Cat + Dash",
      body = "#showtooltip Dash\n/cancelform [form:1/2/4/5]\n/cast [nostance:3] !Cat Form\n/cast Dash",
      hint = "Shift to Cat if not already, then Dash." },
    { name = "Bear Charge",
      body = "#showtooltip Feral Charge\n/cancelform [form:2/3/4/5]\n/cast [nostance:1] !Dire Bear Form\n/cast Feral Charge",
      hint = "Shift to Bear and Charge in one press." },
    { name = "Powershift (Cat)",
      body = "#showtooltip\n/cancelform\n/cast !Cat Form",
      hint = "Drop and re-enter Cat form to dump energy rounding. Requires ~35 mana." },
    { name = "Travel Swap",
      body = "#showtooltip Travel Form\n/cancelform [form:3]\n/cast [nostance:3] Travel Form",
      hint = "Travel form on press, cancel on second press." },
    { name = "Innervate @mo",
      body = "#showtooltip Innervate\n/cast [@mouseover,help,nodead][] Innervate",
      hint = "Innervate unit under cursor, or self if none." },
    { name = "Rebirth @mo",
      body = "#showtooltip Rebirth\n/cast [@mouseover,dead][] Rebirth",
      hint = "Combat-res mouseover corpse." },
}

ns.PRESETS.PRIEST = {
    { name = "IF+Trink+PoH",
      body = "#showtooltip Prayer of Healing\n/use 13\n/cast Inner Focus\n/cast Prayer of Healing",
      hint = "Pop trinket + Inner Focus + Prayer of Healing in one press." },
    { name = "Shadowfiend",
      body = "#showtooltip Shadowfiend\n/use 13\n/use 14\n/cast Inner Focus\n/cast Shadowfiend",
      hint = "Both trinkets + IF + Shadowfiend. Mind Blast after for big hit." },
    { name = "PW:S @mouseover",
      body = "#showtooltip Power Word: Shield\n/cast [@mouseover,help,nodead][] Power Word: Shield",
      hint = "Shield mouseover, or self if none." },
    { name = "Dispel @mo",
      body = "#showtooltip Dispel Magic\n/cast [mod:shift,@player][@mouseover,help,nodead][] Dispel Magic",
      hint = "Dispel mouseover, Shift for self, fallback target." },
    { name = "Fade + cancel",
      body = "#showtooltip Fade\n/cancelaura Fear\n/cast Fade",
      hint = "Drops Fear debuff then Fade. Add more /cancelaura lines for other dispellables." },
    { name = "SWD self",
      body = "#showtooltip Shadow Word: Death\n/cast [@player] Shadow Word: Death",
      hint = "Self-cast SWD to break a fear/stun." },
}

ns.PRESETS.SHAMAN = {
    { name = "NS + HW",
      body = "#showtooltip Healing Wave\n/cast Nature's Swiftness\n/cast [@mouseover,help,nodead][] Healing Wave",
      hint = "Instant Healing Wave on mouseover or current target." },
    { name = "Purge @mo",
      body = "#showtooltip Purge\n/cast [@mouseover,harm,nodead][] Purge",
      hint = "Purge mouseover or current target." },
    { name = "ES + wpn swap",
      body = "#showtooltip Earth Shock\n/equipslot 16 Gladiator's Shanker\n/cast Earth Shock",
      hint = "Swap to preferred weapon and Earth Shock. Replace item name." },
    { name = "Fire Nova drop",
      body = "#showtooltip Fire Nova Totem\n/cast Fire Nova Totem",
      hint = "Quick-drop Fire Nova Totem. Swap spell for any preferred totem." },
    { name = "Ghost Wolf",
      body = "#showtooltip Ghost Wolf\n/cancelform\n/cast [nostance:1] Ghost Wolf",
      hint = "Ghost Wolf on, or drop form on second press." },
    { name = "Reinc + trink",
      body = "#showtooltip Reincarnation\n/use 13\n/use 14\n/cast Reincarnation",
      hint = "Rez + both trinkets the moment you come up." },
}

ns.PRESETS.PALADIN = {
    { name = "Bubblehearth",
      body = "#showtooltip Divine Shield\n/cast Divine Shield\n/use Hearthstone",
      hint = "Bubble + hearthstone. Stopcasting not needed; queued cast." },
    { name = "Cleanse @mo",
      body = "#showtooltip Cleanse\n/cast [@mouseover,help,nodead][] Cleanse",
      hint = "Cleanse mouseover, fallback current target." },
    { name = "BoP @mo",
      body = "#showtooltip Blessing of Protection\n/cast [@mouseover,help,nodead][] Blessing of Protection",
      hint = "BoP mouseover, fallback current target." },
    { name = "HoW opportunity",
      body = "#showtooltip Hammer of Wrath\n/cast Hammer of Wrath",
      hint = "Simple HoW — bind a key and spam during execute phase." },
    { name = "Righteous Fury",
      body = "#showtooltip Righteous Fury\n/cancelaura Righteous Fury\n/cast [nomounted] Righteous Fury",
      hint = "Toggle Righteous Fury on/off." },
    { name = "LoH @mo",
      body = "#showtooltip Lay on Hands\n/cast [@mouseover,help,nodead][] Lay on Hands",
      hint = "LoH mouseover, fallback current target." },
}

ns.PRESETS.MAGE = {
    { name = "Ice Block cancel",
      body = "#showtooltip Ice Block\n/cancelaura Ice Block\n/cast Ice Block",
      hint = "Press once to block, again to drop block." },
    { name = "CS + Ice Block",
      body = "#showtooltip Cold Snap\n/cast Cold Snap\n/cast Ice Block",
      hint = "Cold Snap then re-use Ice Block immediately." },
    { name = "PoM + Pyroblast",
      body = "#showtooltip Pyroblast\n/cast Presence of Mind\n/cast Pyroblast",
      hint = "Instant Pyro burst opener." },
    { name = "Counter focus",
      body = "#showtooltip Counterspell\n/cast [@focus,exists,harm,nodead][] Counterspell",
      hint = "Counterspell focus target, fallback current target." },
    { name = "Polymorph focus",
      body = "#showtooltip Polymorph\n/cast [@focus,exists,harm,nodead][] Polymorph",
      hint = "Sheep focus target, fallback current target." },
    { name = "Evoc combo",
      body = "#showtooltip Evocation\n/use Mana Emerald\n/use 13\n/cast Evocation",
      hint = "Mana gem + top trinket + Evocation for a full mana reset." },
}

ns.PRESETS.WARLOCK = {
    { name = "Soulshatter",
      body = "#showtooltip Soulshatter\n/cast Soulshatter",
      hint = "Threat drop. Keep Soul Shards on hand." },
    { name = "Fear focus",
      body = "#showtooltip Fear\n/cast [@focus,exists,harm,nodead][] Fear",
      hint = "Fear focus, fallback current target." },
    { name = "Banish focus",
      body = "#showtooltip Banish\n/cast [@focus,exists,harm,nodead][] Banish",
      hint = "Banish focus, fallback current target." },
    { name = "Seduce focus",
      body = "#showtooltip Seduction\n/cast [@focus,exists,harm,nodead][] Seduction(Special Ability)",
      hint = "Succubus Seduction via focus. Adjust pet ability name to locale." },
    { name = "DC + trinket",
      body = "#showtooltip Death Coil\n/use 13\n/cast Death Coil",
      hint = "Pop trinket with Death Coil heal/fear." },
    { name = "Life Tap quick",
      body = "#showtooltip Life Tap\n/cast Life Tap",
      hint = "Simple LT for mana. Drag max-rank Life Tap from spellbook if desired." },
}

ns.PRESETS.WARRIOR = {
    { name = "Battle + OP",
      body = "#showtooltip Overpower\n/cast [nostance:1] Battle Stance\n/cast Overpower",
      hint = "Swap to Battle Stance and Overpower." },
    { name = "Zerker+Intercept",
      body = "#showtooltip Intercept\n/cast [nostance:3] Berserker Stance\n/cast Intercept",
      hint = "Swap to Berserker Stance and Intercept." },
    { name = "Def+Shield Wall",
      body = "#showtooltip Shield Wall\n/cast [nostance:2] Defensive Stance\n/cast Shield Wall",
      hint = "Swap to Defensive Stance and Shield Wall." },
    { name = "Charge+Hamstring",
      body = "#showtooltip Charge\n/castsequence reset=4 Charge, Hamstring",
      hint = "Charge then Hamstring on next press (4s reset)." },
    { name = "Pummel (Zerker)",
      body = "#showtooltip Pummel\n/cast [nostance:3] Berserker Stance\n/cast Pummel",
      hint = "Swap to Berserker Stance and Pummel in one press." },
    { name = "Intervene focus",
      body = "#showtooltip Intervene\n/cast [@focus,help,exists,nodead][] Intervene",
      hint = "Intervene focus, fallback current friendly target." },
}

ns.PRESETS.ROGUE = {
    { name = "Stealth + PP",
      body = "#showtooltip Pick Pocket\n/cast [nostealth] Stealth\n/cast Pick Pocket",
      hint = "Stealth if not already, then Pick Pocket." },
    { name = "Sap focus",
      body = "#showtooltip Sap\n/cast [@focus,exists,harm,nodead][] Sap",
      hint = "Sap focus target, fallback current target." },
    { name = "Cheap Shot focus",
      body = "#showtooltip Cheap Shot\n/cast [@focus,exists,harm,nodead][] Cheap Shot",
      hint = "Cheap Shot focus, fallback current target." },
    { name = "Vanish + Prep",
      body = "#showtooltip Vanish\n/cast Vanish\n/cast Preparation",
      hint = "Vanish then Preparation to reset cooldowns." },
    { name = "Kick + trinket",
      body = "#showtooltip Kick\n/use 13\n/cast Kick",
      hint = "Kick with trinket pop (e.g. PvP silence trinket)." },
    { name = "Blade Flurry",
      body = "#showtooltip Blade Flurry\n/cancelaura Blade Flurry\n/cast Blade Flurry",
      hint = "Toggle Blade Flurry on/off." },
}

ns.PRESETS.HUNTER = {
    { name = "MD focus",
      body = "#showtooltip Misdirection\n/cast [@focus,help,exists,nodead][] Misdirection",
      hint = "Misdirection to focus, fallback current friendly target." },
    { name = "FD + Freeze Trap",
      body = "#showtooltip Freezing Trap\n/cast Feign Death\n/cast Freezing Trap",
      hint = "Feign Death then drop Freezing Trap at your feet." },
    { name = "Hawk/Viper swap",
      body = "#showtooltip\n/cast [mod:shift] Aspect of the Viper; Aspect of the Hawk",
      hint = "Hawk by default, Shift for Viper." },
    { name = "Pet atk + Growl",
      body = "#showtooltip\n/petattack\n/cast [pet] Growl",
      hint = "Send pet + force taunt." },
    { name = "Rapid Fire+trink",
      body = "#showtooltip Rapid Fire\n/use 13\n/use 14\n/cast Rapid Fire",
      hint = "Haste burst: both trinkets + Rapid Fire." },
    { name = "Flare + HM",
      body = "#showtooltip Flare\n/cast Flare\n/cast Hunter's Mark",
      hint = "Reveal stealth + Hunter's Mark for easier tab-target." },
}
