# TASKS.md
## VEILBOUND: Crown of the Shattered Aether

> Format: `[ ]` todo · `[x]` done. Tag: 🔴 P0 · 🟡 P1 · 🟢 P2.
> Kerjakan **berurutan per phase**. Jangan lompat ke konten sebelum combat terasa enak.

---

## PHASE 0: Foundation (Minggu 1–4)

### Setup
- [ ] 🔴 Install Unreal Engine 5.x + Visual Studio / Rider
- [ ] 🔴 Setup Git + Git LFS (atau Perforce) + `.gitignore` UE
- [ ] 🔴 Setup project folder structure (Content/Characters, Combat, World, UI, Audio, VFX)
- [ ] 🔴 Setup Claude Code / AI coding assistant + `CLAUDE.md` berisi konvensi proyek
- [ ] 🟡 Setup task board (Notion/Linear/GitHub Projects)
- [ ] 🟡 Setup backup & CI build sederhana

### Dokumentasi
- [ ] 🔴 Finalisasi nama game & cek trademark
- [ ] 🔴 Tulis **Art Bible** (palette, shape language, toon shader ref, moodboard)
- [ ] 🔴 Tulis **Tech Spec** (arsitektur combat, save, world streaming)
- [ ] 🟡 Buat **AI Asset Log** (tool, prompt, seed, lisensi)
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
- [ ] 🔴 Weapon trace hit detection
- [ ] 🔴 Hitstop, camera shake, hit VFX/SFX
- [ ] 🔴 Block / guard
- [ ] 🟡 Parry + riposte
- [ ] 🟡 Posture/break + critical strike
- [ ] 🟡 Resonance Art #1 (katana skill)
- [ ] 🟢 Perfect-dodge slow-mo

### Animation
- [ ] 🔴 Import/retarget base locomotion (Mixamo / Cascadeur)
- [ ] 🔴 Katana attack set (AI mocap + manual polish)
- [ ] 🔴 Animation Montage + Anim Notify (hit window, i-frame, combo)
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
- [ ] 🔴 Cel-shading material (lighting ramp)
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

### Environment Design & Playable Vertical Slice (Phase 2.3)
- [x] Audit environment assets; integrate free KayKit models and record creator, source, and CC0 license
- [x] Build connected entry, elevated stair approach, ruined combat court, gate landmark, and lantern checkpoint
- [x] Bake navigation mesh; verify player traversal and Soldier obstacle detour, pursuit, and attack
- [x] Verify combat, lock-on, dodge, guard, and checkpoint death recovery
- [x] Capture rendered screenshots and measure Compatibility performance on Intel UHD Graphics 620 / 8 GB (180 frames: 60.05 FPS average, 55.62 minimum, 152 draw calls at 1152×648)

### Phase 2.4: Combat Presentation Polish
- [x] Redesign responsive combat HUD with signal-driven HP, stamina, and lock-on target state
- [x] Repair player animation state priority and verify genuine skeletal deformation
- [x] Attach player katana and Soldier weapon to the discovered animated hand bones
- [x] Synchronize Soldier telegraph, attack active window, recovery, stagger, and death presentation
- [x] Validate runtime presentation captures at 1152×648 and pass targeted regression tests
- [x] Repair duplicate player status bars using a single overlay pair per resource
- [x] Add four stamina-based skills with E selection, Q cast, cooldowns, and Middle Mouse lock-on

### Phase 2.5: Functional HUD, Skills & Animation Audit
- [x] Make the production compass read live gameplay-camera yaw using world -Z as north
- [x] Repair production projectile spawn ordering and timed melee skill hit windows
- [x] Add production-scene InputMap end-to-end validation for E/Q and all four skills
- [x] Inspect selected CC0 Quaternius humanoid clips and verify license/provenance
- [x] Repair Soldier full-body state mapping using inspected CC0 UAL clips and preserve the existing 0.65s attack timing
- [x] Add a production-resource animation preview and Phase 2.6 capture/track regression checks
- [x] Correct protagonist katana forward axis and stabilize jump arm tracks
- [ ] Complete verified humanoid BoneMap retarget to the 211-bone protagonist skeleton
- [ ] Complete manual keyboard/mouse playtest and final visual animation sign-off

## PHASE 3: Vertical Slice (Bulan 6–12) 🏰

### Phase 2.7: Secondary Motion (SpringBoneSimulator3D) & Building-Lag Optimization
- [x] Inventory the real rig chains (player 211-bone, Soldier 102-bone) and document missing loose chains honestly (`rig_player.txt`, `rig_soldier.txt`)
- [x] Replace the procedural bone-overwrite system with native SpringBoneSimulator3D (33 chains, 1 simulator per motion group, per-chain stiffness/drag/gravity/radius, hair/ears/tail/clothing/accessories)
- [x] Wire capsule/sphere collisions, per-group impulses with clamps, reset/death/hit-react hooks; combat timing and katana attachment untouched
- [x] Dev-only spring preview tool using the real production model (`tools/secondary_motion_preview`)
- [x] 24-assertion Phase 2.7 gate suite; migrate Phase 2.1/2.6 suites to native springs
- [x] Build a stable rendering benchmark instrument (`--disable-render-loop` + one forced draw per sample) with an interleaved baseline/optimized A/B on the production scene
- [x] Collapse repeated environment props into spatially chunked MultiMesh batches (16 visuals → 8 draws) while keeping all collision bodies
- [x] Shadow budget: small props stop casting shadows, directional shadow range 100 m → 45 m, atlas 4096 → 2048; measured −9.1% (entry), −6.5% (dense), −4.3% (combat), −7.3% (identical-work control)
- [x] Reduce CombatHUD draw volume (228 → 70 in Phase 2.8: label batching via draw_string, gradient bake ke GradientTexture1D, StyleBoxEmpty; −69%)
- [ ] Reduce protagonist/soldier geometry cost (141k/44k tris; asset-level decision, e.g. LOD or mesh merge)
- [ ] Consider baked occlusion culling for future enclosed interiors (rejected for the open courtyard — measured view pays nothing off)
- [ ] Consider baked skybox / fog tuning for the ~4.0 ms residual scene cost

### Phase 2.8: Integration & Visual Acceptance Gate
- [x] Audit-first defect register memakai tabel `Defect | Root cause terkonfirmasi | Bukti | Koreksi | Acceptance test` (lihat `PHASE_2_8_REPORT.md`)
- [x] Perbaiki nama-tabrakan rebuild HUD `_build_layout: panel lama dibebaskan sinkron (deferred `queue_free` membuat auto-rename `@PanelContainer@N` saat runtime)
- [x] Audit 33 spring chain per behavior via skenario idle→sprint→hard-turn→jump→landing→dodge→attack (`.godot/phase_2_8/spring_audit.txt`; semua chain membelok dan settle, overhead CPU spring ≈ 0)
- [x] Jadikan ID chain spring unik (group + nama root bone penuh) — slicer lama bertabrakan di Hair_In[A-E], kedua telinga, dan pasangan bust
- [x] Suite integrasi InputMap end-to-end 6/6: lock-on MMB (acquire/release), siklus target Tab/wheel, restore checkpoint F (HP/stamina end-to-end), penolakan cooldown Q + HUD `COOLDOWN`, penolakan stamina kurang + HUD `STAMINA`
- [x] Tulis ulang retarget UAL Soldier sebagai transfer rotasi global per sampel (alignment landmark rest-pose dua rig) — formula lama rest-delta menghasilkan pose mendekati A-pose
- [x] Drive leluhur statis yang termapping (`DEF-spine.001` → `CC_Base_Waist_98`) + transfer posisi pelvis rescaled agar krouch/collapse memindahkan tinggi tubuh
- [x] Perbaiki pose "rubbery" telegraph: klip UAL full-body `Punch_Enter` menggantikan klip custom upper-body-only di state TELEGRAPH (skin tak lagi jatuh ke rest pose "running panic" bawaan mesh)
- [x] Verifikasi invarian retarget ≤1,65° residual di seluruh chain termapping (probe layer/rotation diff), probe pose world-space per state, dan apex serang t=0,371 s di dalam window damage 0,35–0,47 s
- [x] Ulang benchmark A/B Phase 2.7 setelah semua perubahan: optimized menang lagi (entry −12,3%, dense −9,5%, combat −6,7%, low-density paritas; median absolut lebih tinggi ~3 ms vs laporan 2.7 karena kondisi sesi)
- [x] Tulis ulang ekspektasi test 8 Phase 2.2 yang usang agar mengikuti aturan seleksi produksi UAL-vs-legacy (`test_phase_2_2.gd` 10/10)
- [x] Review animasi protagonis lewat capture idle/walk/sprint/dodge/combo dengan input terskrip (bukti visual terbatas; lihat catatan jujur di laporan)
- [ ] Selesaikan playtest manual keyboard/mouse dan sign-off visual final (checklist user di `PHASE_2_8_REPORT.md`)


### World: Hollowmere Basin
- [ ] 🔴 Landscape + World Partition setup
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
- [ ] 🟡 Optimasi performa (LOD, HLOD, Nanite, profiling)
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
Buat UE5 C++ ActorComponent "UStaminaComponent": max stamina, regen delay,
consume/restore API, Blueprint-exposed delegate OnStaminaChanged.
Ikuti konvensi di CLAUDE.md. Sertakan unit test sederhana.
```

**Claude Code: Boss AI**
```
Implementasi Boss AI via StateTree: Phase 1 (>50% HP) dan Phase 2 (<=50% HP).
Move selector berbobot dengan anti-repeat (tidak boleh move sama >2x).
Setiap move punya telegraph delay, range, cooldown. Data-driven via DataAsset.
```

**Image gen: Concept character**
```
original anime fantasy swordswoman, silver hair, crimson tattered cloak,
katana, dark fantasy, full body, front/side/back turnaround, white background,
clean line art, cel shading, <LoRA_style:0.8>
```

**3D gen:** upload turnaround → generate → export FBX → Blender cleanup → retopo (≤60k tris hero) → rig.

---

## DEFINITION OF DONE (Per Task)
- [ ] Jalan di build packaged, bukan hanya editor
- [ ] Tidak ada warning/error di log
- [ ] 60 FPS di spec target
- [ ] Dites oleh minimal 1 orang selain developer
- [ ] Aset AI tercatat di AI Asset Log
- [ ] Di-commit dengan pesan jelas
