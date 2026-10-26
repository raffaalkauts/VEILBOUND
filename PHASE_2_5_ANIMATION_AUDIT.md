# Phase 2.5 Animation Audit

## Confirmed production defect

| Defect | Root cause | Evidence | Correction |
|---|---|---|---|
| Protagonist idle arms held almost horizontally | The generic Quaternius runtime retarget wrote rotation tracks to the correct 211-bone skeleton, but source and fox target rest poses/axes were not compatible with the applied correction formula | `diagnose_animation_pose.gd` showed both hands near shoulder height while the retargeted `idle` played; the same sample without runtime retarget placed both hands clearly below the shoulders | Disabled the unverified runtime retarget path. The existing target-compatible `player_animations.tres` is authoritative again. |
| Animation state could restart or lose equipment state | Visual driver owns priority clips, but skill clips did not explicitly enter combat draw mode | Skill path used `play_skill_animation()` without changing equipment state | Skill animation now enables the real hand attachment before playback and uses the actual clip duration. |
| Soldier combat clips are partial | Soldier asset contains one embedded 14.83-second run clip; custom state clips contain upper-body tracks on the actual 102-bone skeleton | `inspect_user_soldier.gd` and `inspect_soldier_anim_paths.gd` confirm the clip inventory and real track paths | Preserved the Soldier model and state timing; attack track/hand attachment tests remain required. A full compatible melee replacement is still an open visual task. |

## Animation sources

- Protagonist production model: `res://assets/characters/protagonist/imported/anime_fox_girl.glb`, 211 bones.
- Protagonist target-compatible clips: `res://characters/player/visual/player_animations.tres`.
- Quaternius source inspected: `res://assets/animations/quaternius/universal_animation_library_standard.glb`, CC0, license retained beside the asset. It is not applied to the fox rig until a verified humanoid BoneMap/rest-pose retarget is available.
- Soldier model: `res://characters/enemies/soldier/anime-girl_running_panic.glb`, 102 bones, user-provided source.

## Validation

- Idle pose sampled at six points across the complete loop.
- Production capture regenerated for idle, walk, sprint, dodge, attack, guard and Soldier states.
- Manual keyboard/mouse validation remains unavailable because the Windows Computer Use native pipe is not present in this environment.
