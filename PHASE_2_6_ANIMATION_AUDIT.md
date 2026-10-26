# Phase 2.6 Animation Quality Gate Audit

Date: 2026-10-22  
Production scene: `res://main.tscn`  
Renderer/runtime capture: Godot 4.7.2 Compatibility, Intel UHD Graphics 620, 1152x648

## Confirmed defect register

| Defect | Confirmed root cause | File/function | Correction | Runtime proof |
|---|---|---|---|---|
| Protagonist previously held an arms-out/T-pose | Generic runtime UAL retarget applied source rest correction to the 211-bone fox rig; source/destination rests were incompatible | `player_character_model.gd`, `_retarget_quaternius_clips()` | Runtime generic retarget remains disabled; target-compatible `player_animations.tres` is authoritative | `diagnose_animation_pose.gd` samples six idle positions; both hands remain below shoulders. Production captures show no idle T-pose |
| Soldier combat showed a running leg pose | Imported running clip had full-body tracks, but custom `soldier/idle`, `telegraph`, `attack`, `stagger`, and `death` only animated upper-body bones | `soldier_animations.tres`, `soldier_enemy.gd::_change_state()` | Added a per-Soldier runtime retarget library from the inspected CC0 UAL Standard source and mapped locomotion/combat states to it; attack is retimed to the existing 0.65s combat window | Phase 2.6 capture shows Soldier states using full-body retargeted clips; phase 2.4 presentation regression is 22/22 |
| Attack timing could drift after replacing the Soldier clip | Retargeted UAL Sword_Attack is 1.533s while existing active window is 0.35s and old state duration is 0.65s | `soldier_enemy.gd::_process_attack()` | Retimed copied attack keys to 0.65s; existing active damage constants remain unchanged | Soldier active-window and state-exit tests pass |
| Held katana blade pointed down | Runtime attachment used a +90 degree X offset even though the mesh blade axis is local +Y | `player_character_model.gd::_setup_bone_attachments()` | Calibrated the local grip rotation so the blade axis aligns to gameplay forward `-Z` | Diagnostic forward dot is `1.0` |
| Jump made both arms swing forward/back | The target-compatible `jump` clip contained changing right/left upper-arm tracks | `player_animations.tres`, `Animation_0i4p1` | Stabilized both arm tracks to the idle combat-ready quaternion while preserving spine/leg jump motion | Phase 2.6 gate confirms both arm tracks are constant |
| Rig looked stiff during movement | The controller only applied procedural secondary motion to one tail bone and two ear bones; the real hair and bust chains were never driven | `player_character_model.gd::update_secondary_motion()` | Added damped spring response to verified hair roots and bust chains, driven by acceleration/air-state changes and bounded to small local offsets | Phase 2.6 gate confirms the bust spring moves the real skeleton; production capture remains at 1152x648 |

## Actual production resources

- Protagonist: `assets/characters/protagonist/imported/anime_fox_girl.glb`, 211-bone `Skeleton3D`; target-compatible clips in `characters/player/visual/player_animations.tres`.
- Protagonist hand attachment: `Shibahu_RightHand_0167_217`; hip/scabbard attachment: `Shibahu_Hips_00_245`.
- Soldier: `characters/enemies/soldier/anime-girl_running_panic.glb`, 102-bone `Skeleton3D`; weapon hand `CC_Base_R_Hand_88`.
- Soldier UAL mapping uses the actual CC_Base clavicle, upperarm, forearm, hand, spine, pelvis, thigh, calf and foot bones. Unmapped facial/twist/finger bones are intentionally left untouched.

## Clips and provenance

| Character/state | Runtime clip | Source/license | Status |
|---|---|---|---|
| Protagonist idle/walk/sprint/dodge/attacks/guard | target-compatible `idle`, `walk`, `sprint`, `dodge`, `attack_1..3`, `guard` | Existing project resource; no external retarget applied | Active |
| Soldier idle/walk/sprint | UAL Standard `Idle`, `Walk`, `Sprint` retargeted at runtime | Quaternius Universal Animation Library, CC0; local `LICENSE.txt` | Active, visually needs final manual review |
| Soldier attack | UAL Standard `Sword_Attack`, retimed to 0.65s | Quaternius Universal Animation Library, CC0; local `LICENSE.txt` | Active, visually needs final manual review |
| Soldier hit/death | UAL Standard `Hit_Chest`, `Death01` | Quaternius Universal Animation Library, CC0; local `LICENSE.txt` | Active, visually needs final manual review |

Universal Animation Library 2 was researched but is not present in the repository. No unverified download or invented clip name was added. The local UAL Standard pack is the only external animation source actually inspected and integrated in this pass.

## Preview and evidence

Development-only preview: `tools/animation_preview.tscn`. Open it separately from the production scene. `Tab` switches between the real protagonist and Soldier resources, `1-9` selects available clips, `Space` pauses, and Left/Right scrubs.

Production capture script: `tests/capture_phase_2_6_animation_frames.gd`. It captures the real `main.tscn` player and Soldier resources, not a mock scene. Captures were written as `screenshot_phase_2_6_*.png` at 1152x648.

## Remaining limitation

The automated production capture confirms track resolution, state selection and full-body retarget tracks, but it is not a substitute for a human judging combat weight, foot contact and weapon grip during continuous motion. Native keyboard/mouse playtest was not completed because the Windows computer-control pipe was unavailable. Phase 2.6 therefore remains open for manual sign-off, and UAL2 integration remains unverified until its archive is available locally.
