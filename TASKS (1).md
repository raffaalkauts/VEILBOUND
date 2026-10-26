# TASKS.md
## VEILBOUND: Crown of the Shattered Aether

> Format: `[ ]` todo · `[x]` done. Tag: 🔴 P0 · 🟡 P1 · 🟢 P2.
> Kerjakan **berurutan per phase**. Jangan lompat ke konten sebelum combat terasa enak.

---

## PHASE 0: Foundation (Minggu 1–4)

### Setup
- [x] 🔴 Keputusan engine: **Godot 4.x**
- [ ] 🔴 Install Godot 4.x stable (versi .NET jika pakai C#) + VS Code / Rider
- [ ] 🔴 Setup Git + Git LFS + `.gitignore` Godot
- [ ] 🔴 Setup project folder structure (`res://characters`, `combat`, `world`, `ui`, `audio`, `vfx`)
- [ ] 🔴 Setup Claude Code / AI coding assistant + `AGENTS.md` berisi konvensi proyek (sudah ada draft)
- [ ] 🟡 Setup task board (Notion/Linear/GitHub Projects)
- [ ] 🟡 Setup backup & CI build sederhana

### Dokumentasi
- [ ] 🔴 Finalisasi nama game & cek trademark
- [ ] 🔴 Tulis **Art Bible** (palette, shape language, toon shader ref, moodboard)
- [x] 🔴 Tulis **Tech Spec** (draft: `TECH_SPEC.md`), review setelah prototype
- [x] 🟡 Buat **AI Asset Log** (template: `AI_ASSET_LOG.md`), isi tiap ada aset baru
- [ ] 🟡 Legal check: lisensi tool AI, aturan disclosure Steam

---

## PHASE 1: Combat Prototype (Bulan 2–5) ⚔️

### Character Controller
- [ ] 🔴 Third-person movement (walk/run/sprint)
- [ ] 🔴 Camera + lock-on system
- [ ] 🔴 Dodge roll + i-frames
- [ ] 🔴 Jump & fall
- [ ] 🟡 Slope/stairs handling

### Combat Core
- [ ] 🔴 Stamina component
- [ ] 🔴 Health/damage component + damage types
- [ ] 🔴 Light attack combo (3 hit) + input buffering
- [ ] 🔴 Heavy attack + charge
- [ ] 🔴 Hitbox/Hurtbox detection (Area3D / ShapeCast3D)
- [ ] 🔴 Hitstop, camera shake, hit VFX/SFX
- [ ] 🔴 Block / guard
- [ ] 🟡 Parry + riposte
- [ ] 🟡 Posture/break + critical strike
- [ ] 🟡 Resonance Art #1 (katana skill)
- [ ] 🟢 Perfect-dodge slow-mo

### Animation
- [ ] 🔴 Import/retarget base locomotion (Mixamo / Cascadeur) via Godot BoneMap
- [ ] 🔴 Katana attack set (AI mocap + manual polish)
- [ ] 🔴 AnimationTree + AnimationPlayer call-method tracks (hit window, i-frame, combo)
- [ ] 🟡 Hit react & death anim

### Enemy & Boss Prototype
- [ ] 🔴 Basic enemy (Soldier) dengan Behavior Tree
- [ ] 🔴 Boss #1 prototype (2 phase, 8 moves) di arena kotak
- [ ] 🔴 Boss health bar UI
- [ ] 🟡 Telegraph system (visual/audio tell)

### Playtest Gate ✅
- [ ] 🔴 Playtest 10+ orang → "combat feel" ≥ 4/5
- [ ] 🔴 **GO/NO-GO decision**: lanjut atau iterasi combat

---

## PHASE 2: Art Pipeline & Visual Style (Paralel Bulan 3–6) 🎨

### Toon Shader
- [ ] 🔴 Cel-shading `.gdshader` (lighting ramp)
- [ ] 🔴 Outline post-process
- [ ] 🔴 Skin/hair/cloth material
- [ ] 🟡 Anime VFX kit (impact frame, speed line, smear)

### AI Asset Pipeline
- [ ] 🔴 Train **LoRA** art style (30–100 referensi original/berlisensi)
- [ ] 🔴 Concept art: protagonis, Kuro, Sera, 3 enemy, boss #1
- [ ] 🔴 Pipeline: concept → 3D gen (Meshy/Tripo/Hunyuan) → Blender cleanup → retopo → UV → rig
- [ ] 🟡 Buat 1 checklist QA aset (poly count, texel density, naming)
- [ ] 🟡 AI texture pipeline (Substance/SD)
- [x] 🟢 Prop kit environment (50+ aset: KayKit modular ruins, pillars, arches, gates, trees, cemetery)

### Characters
- [ ] 🔴 Protagonis final (mesh, rig, hair physics)
- [ ] 🟡 Character creator v1 (hair/face/color)
- [ ] 🟡 Armor set #1–#3

---

## PHASE 3: Vertical Slice (Bulan 6–12) 🏰

### World: Hollowmere Basin
- [ ] 🔴 Terrain (Terrain3D addon / heightmap mesh) + zone streaming setup
- [ ] 🔴 Blockout region (landmark, jalur, vertikalitas)
- [ ] 🔴 Environment art pass (foliage, kabut, rawa, bangunan)
- [ ] 🔴 Lantern checkpoint + fast travel
- [ ] 🔴 15 enemy placement + 3 mini dungeon
- [ ] 🟡 Hidden area ×3
- [ ] 🟡 Day/night + weather basic
- [ ] 🟡 Map UI

### Legacy Dungeon #1: Rusted Keep
- [ ] 🔴 Layout (shortcut loop, verticality)
- [ ] 🔴 Art pass interior
- [ ] 🔴 Boss: **Garran, the Rusted Warden** (final polish)
- [ ] 🔴 Cinematic phase transition
- [ ] 🔴 Boss OST (draft)

### Systems
- [ ] 🔴 Inventory + equipment
- [ ] 🔴 Level up + 8 stat
- [ ] 🔴 Aether Motes drop & recovery
- [ ] 🔴 Aether Vial (heal flask)
- [ ] 🔴 Save/Load
- [ ] 🔴 5 weapon types (katana, spear, greatsword, dual blade, staff)
- [ ] 🟡 Weapon upgrade
- [ ] 🟡 Magic: 3 spell
- [ ] 🟡 Windstrider mount (basic)

### Narrative
- [ ] 🔴 Dialog system
- [ ] 🔴 NPC: Kuro, Haruto (smith), Nyx (merchant)
- [ ] 🟡 Item lore (30 item)

### UI/Audio
- [ ] 🔴 HUD, menu, settings
- [ ] 🔴 Controller + KBM
- [ ] 🔴 Main theme + 3 ambient track
- [ ] 🔴 SFX combat set

### Release Assets
- [ ] 🔴 Trailer 90 detik
- [ ] 🔴 Steam page + wishlist push
- [ ] 🟡 Playable demo (60–90 menit)
- [ ] 🟡 Press kit & devlog

### Gate ✅
- [ ] 🔴 Demo playtest 50+ orang
- [ ] 🔴 Pitch publisher / Kickstarter / grant

---

## PHASE 4: Early Access Content (Bulan 12–24) 🌍

- [ ] 🔴 Region 2: Sakuraveil Highlands + Boss Lady Mizuhara
- [ ] 🔴 Region 3: Ironbloom Citadel + Boss Count Veyrath
- [ ] 🔴 Legacy dungeon #2 & #3
- [ ] 🔴 10 weapon class total
- [ ] 🔴 12 boss total
- [ ] 🟡 Sera rival questline
- [ ] 🟡 Echo Familiar (summon) system
- [ ] 🟡 Optimasi performa (visibility ranges, occlusion culling, MultiMesh, profiling)
- [ ] 🟡 Localization EN/ID/JP
- [ ] 🟢 Steam Achievements, Cloud Save
- [ ] 🔴 Early Access launch + patch cadence (tiap 4–6 minggu)

---

## PHASE 5: Full Content & 1.0 (Bulan 24–42) 👑

- [ ] 🔴 Region 4–8 + semua Shard Bearer boss
- [ ] 🔴 Crown's Heart (final area) + final boss
- [ ] 🔴 18 weapon class, 50+ field boss
- [ ] 🔴 4 ending + flag system
- [ ] 🟡 Co-op Echo Link (netcode)
- [ ] 🟡 VA profesional (replace AI placeholder)
- [ ] 🟡 Composer final OST
- [ ] 🟡 New Game+
- [ ] 🔴 Full QA pass, bug bash, balancing
- [ ] 🔴 Console cert (opsional)
- [ ] 🔴 **1.0 Launch**

---

## BACKLOG / POST-LAUNCH
- [ ] 🟢 DLC expansion (region + boss baru)
- [ ] 🟢 Mod support
- [ ] 🟢 Photo mode
- [ ] 🟢 Boss rush mode
- [ ] 🟢 Console port

---

## PROMPT TEMPLATES UNTUK AI (Copy-paste)

**Claude Code: Combat component**
```
Buat Godot 4 GDScript (typed) node "StaminaComponent" (extends Node): max_stamina,
regen_delay, consume()/restore() API, signal stamina_changed(current, max).
Ikuti konvensi di AGENTS.md. Sertakan unit test GUT sederhana.
```

**Claude Code: Boss AI**
```
Implementasi Boss AI di Godot 4 via state machine: Phase 1 (>50% HP) dan Phase 2 (<=50% HP).
Move selector berbobot dengan anti-repeat (tidak boleh move sama >2x).
Setiap move punya telegraph delay, range, cooldown. Data-driven via custom Resource (.tres).
```

**Image gen: Concept character**
```
original anime fantasy swordswoman, silver hair, crimson tattered cloak,
katana, dark fantasy, full body, front/side/back turnaround, white background,
clean line art, cel shading, <LoRA_style:0.8>
```

**3D gen:** upload turnaround → generate → export GLB → Blender cleanup → retopo (≤60k tris hero) → rig.

---

## DEFINITION OF DONE (Per Task)
- [ ] Jalan di build packaged, bukan hanya editor
- [ ] Tidak ada warning/error di log
- [ ] 60 FPS di spec target
- [ ] Dites oleh minimal 1 orang selain developer
- [ ] Aset AI tercatat di AI Asset Log
- [ ] Di-commit dengan pesan jelas
