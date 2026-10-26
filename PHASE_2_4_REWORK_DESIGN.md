# VEILBOUND Phase 2.4 Rework — Design Handoff

## Subject research

VEILBOUND's interface should echo weathered stone, dark lacquer, worn metal and ritual artifacts already present in the ruins. Fractured Aether is expressed through a restrained mineral-cyan selection cue, while Wound Red remains reserved for health and damage. The mood is mysterious and tense; the environment and combat silhouette remain the focal point. Motion is functional: immediate damage response, compact target acquisition and deliberate skill feedback.

## HUD wireframes

### Option A — Selected: Aether instrument

```text
┌────────────────────────────────────────────────────────┐
│                                                        │
│                         gameplay                       │
│                         target HP                      │
│                                                        │
│  ◈  HP  ━━━━━━━━━━━━━━━━━━━━━                          │
│     SP  ━━━━━━━━━━━━━                                  │
│     [status chips]                     [skill]         │
└────────────────────────────────────────────────────────┘
```

The player status is one compact lower-left instrument. Target status stays separate and only appears while lock-on is valid. This preserves the character, Soldier silhouette and attack wind-up in the center of the screen.

### Option B — Rejected: central radial HUD

```text
┌────────────────────────────────────────────────────────┐
│ HP card                         stamina card           │
│                         gameplay                       │
│                            ◉                           │
│                       radial status                    │
└────────────────────────────────────────────────────────┘
```

The central radial option competes with the reticle, target and weapon contact point. It also scales poorly to ultrawide layouts and makes the combat read less distinctive.

## Tokens and critique

Basalt `#202631`, Worn Ivory `#E4DDCE`, Mist Steel `#93A1AD`, Aether Mineral `#79D8CE`, Wound Red `#B84E55`, and Lantern Brass `#D6A55F` are the semantic palette. The current implementation uses one system-font fallback chain with Rajdhani first when installed. The Aether signature is the angled seal/panel silhouette plus restrained mineral-cyan selection state; decorative glow and fake FP data were removed from the live prototype.

Self-critique: the eye should first read the game world and target, not a HUD card. The only ornament retained is the angled seal because it distinguishes selection and slot state. The empty FP bar was removed because the current prototype has no FP component. The most important correction was making damage trails overlays instead of separate vertical controls.

## Defect register

| Observed defect | Root cause status | Evidence | Correction |
|---|---|---|---|
| HP and stamina appeared doubled/stacked | Confirmed | Runtime capture showed trail and current bars as separate VBox children | Put each trail/current pair in one overlay Control; only one visible current bar per resource |
| Q toggled lock-on and could not cast a skill | Confirmed | `lock_on` was bound to physical Q | Q is `skill_cast`; lock-on uses Middle Mouse |
| E conflicted with checkpoint interaction | Confirmed | `interact` was bound to physical E | Moved interaction to F; E is `skill_next` |
| Player had no selectable skill data | Confirmed | No skill component existed on Player scene | Added four Resource-backed skill definitions and one PlayerSkillComponent |

## Animation inventory

| Character | State/effect | Actual clip or implementation | Source/license | Retarget status | Runtime result |
|---|---|---|---|---|---|
| Protagonist | Basic combo | `attack_1`, `attack_2`, `attack_3` | Existing imported Sketchfab model; provenance retained in project log | Existing native skeleton tracks | Existing Phase 2.4 deformation tests pass |
| Protagonist | Skill animation | Existing `attack_1`, `attack_2`, `attack_3`, `dodge` | Existing project assets | No replacement asset added | Skills reuse the real model and hand attachment |
| Soldier | AI combat | `soldier/telegraph`, `soldier/attack`, `soldier/stagger`, `soldier/death`, imported `Animation` | Existing Soldier asset | Existing native skeleton tracks | Existing Soldier animation tests pass |

No new external animation pack was downloaded during this focused HUD/skill repair; no new license claim is made.
