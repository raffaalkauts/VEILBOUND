# GAME DESIGN DOCUMENT
## VEILBOUND: Crown of the Shattered Aether
*Open-world action RPG, souls-like difficulty, anime art direction · Engine: Godot 4.x*

> Working title. Semua nama, lore, dan karakter di dokumen ini ORIGINAL. Referensi ke Elden Ring hanya pada level genre/mekanik (tidak bisa di-IP), bukan nama/aset/lore.

---

## 1. High Concept

Seorang **Hollow-born** (karakter yang lahir tanpa "Aether Thread") bangkit di dunia yang langitnya pecah. **Aether Crown**, sumber seluruh kehidupan, hancur menjadi 8 **Shards**. Tiap Shard dipegang demigod/penguasa regional yang gila oleh kekuatannya. Pemain menjelajahi dunia terbuka luas, mengalahkan para penguasa, dan memutuskan nasib dunia lewat salah satu dari beberapa ending.

**Elevator pitch:** "Dark-fantasy open world yang brutal dan misterius, dengan visual, karakter, dan boss ala anime kelas film."

## 2. Design Pillars

1. **Freedom of Exploration**: tidak ada quest marker wajib; dunia mengajarkan lewat landmark, NPC samar, dan rasa penasaran.
2. **Fair but Brutal Combat**: mati karena skill issue, bukan karena RNG. Setiap boss punya tell yang jelas.
3. **Anime Spectacle**: boss fight terasa seperti episode klimaks anime (cinematic phase transition, OST vokal, VFX flashy).
4. **Mysterious Lore**: cerita dibangun dari item description, environment, dan dialog tidak langsung.
5. **Build Expression**: puluhan playstyle (katana, sihir, summoner, dual-blade, dll.) viable.

## 3. Setting & Lore

### 3.1 Dunia: **Aetheria**
Benua terapung-patah. Langit berwarna aurora permanen; tanah penuh kristal Aether.

### 3.2 Regions (8 + 1 final)
| # | Region | Tema | Penguasa (Shard Bearer) |
|---|--------|------|--------------------------|
| 1 | **Hollowmere Basin** (starting zone) | Rawa berkabut, desa terbengkalai | Garran, the Rusted Warden |
| 2 | **Sakuraveil Highlands** | Hutan sakura abadi, kuil | Lady Mizuhara, Blade of Falling Petals |
| 3 | **Ironbloom Citadel** | Kota industri-gothic, steampunk | Count Veyrath, the Clockwork Saint |
| 4 | **Crimson Dune Sea** | Gurun merah, bangkai kapal langit | Sahrazi, Queen of Mirage |
| 5 | **Frostlight Abyss** | Gua es raksasa, kristal bercahaya | Yuki-no-Kami, the Silent Frost |
| 6 | **Verdant Maw** | Hutan raksasa hidup/parasit | Thornmother Elowen |
| 7 | **Stormspire Archipelago** | Pulau-pulau di badai petir | Raijin Kaito, Storm Tyrant |
| 8 | **Sunken Celestia** | Kota langit tenggelam di danau cahaya | The Hollow King (twist) |
| 9 | **Crown's Heart** (final) | Pecahan langit, gravitasi aneh | Final Boss (tergantung ending) |

### 3.3 Cerita (Spoiler-light)
- Protagonis = Hollow-born, dianggap "cacat" oleh dunia.
- Mentor misterius: **Kuro**, seorang kucing/spirit penjaga yang bicara dengan teka-teki.
- Rival: **Sera**, seorang Shard Seeker yang awalnya sekutu, bisa jadi musuh.
- 4 Ending: Restore Crown, Shatter Forever, Merge with Aether, Hollow Dawn (secret).

## 4. Core Gameplay Loop

```
Explore → Find Lantern (checkpoint) → Fight enemies → Earn Aether Motes
→ Level up / upgrade gear → Discover Dungeon → Defeat Boss → Gain Shard
→ Unlock new region/ability → Repeat
```

## 5. Combat System

### 5.1 Basic
- **Stamina-based**: serangan, dodge, block, sprint memakai stamina.
- **Light / Heavy attack**, **Jump attack**, **Guard Counter**.
- **Dodge roll** (i-frames) + **Perfect Dodge** (slow-mo "Flash Step", gaya anime).
- **Parry** (timing ketat, buka riposte).
- **Posture/Break system**: musuh bisa di-stagger lalu di-**Critical Strike**.

### 5.2 Resonance Arts (pengganti "Ash of War")
- Skill spesial per senjata, konsumsi **Focus (FP)**.
- Contoh: *Moonlit Draw* (katana), *Stormcall* (spear), *Void Chain* (scythe).
- Bisa di-swap antar senjata tertentu.

### 5.3 Magic: **Aether Weaving**
- 3 school: **Flame/Frost/Lightning Weaving**, **Spirit Weaving** (summon), **Hollow Weaving** (dark/gravity).
- Catalyst: Wand, Staff, Charm.

### 5.4 Echo Familiars (summon)
- Summon spirit allies (1–3) dari Echo Stones. Cost FP besar. Nonaktif di boss tertentu.

### 5.5 Mount: **Windstrider**
- Hewan/rubah-spirit raksasa; double jump, gliding, mounted combat.

### 5.6 Weapon Classes (target 18)
Katana, Odachi, Dual Blades, Longsword, Greatsword, Spear, Halberd, Scythe, Whip-Sword, Fists/Claws, Bow, Crossbow, Hammer, Twin Axes, Rapier, Shield-Blade, Chain Weapon, Staff.

### 5.7 Stats (8)
Vitality, Spirit (FP), Endurance, Strength, Dexterity, Intellect, Faith/Resonance, Luck.

## 6. Progression & Systems

| Element | Nama Original | Fungsi |
|---------|---------------|--------|
| Currency / XP | **Aether Motes** | Level up & beli; hilang saat mati (bisa diambil kembali) |
| Checkpoint | **Lantern of Vigil** | Rest, heal, respawn musuh |
| Healing flask | **Aether Vial** | Heal & FP, jumlah dapat di-upgrade |
| Fast travel | **Lantern Gate** | Antar lantern |
| Upgrade senjata | **Whetstone Forging** | +1 sampai +25 |
| Co-op | **Echo Link** | Summon/invade pemain lain (opsional online) |
| Difficulty aid | **Hollow Mercy** | Opsional: bantuan NPC untuk boss (opsional accessibility) |

## 7. World Design

- Open world ±40–60 km² (target realistis solo/small team: **15–20 km²**), dibagi ke **zona streaming per region** (Godot tidak punya World Partition bawaan).
- **Legacy Dungeons** (6–8): kastil/kuil besar dengan boss besar.
- **Mini Dungeons** (40+): gua, crypt, tower.
- **Field Bosses** (50+), reuse model dengan variasi.
- **Verticality**: tebing, lantai langit, tiang kristal.
- **Hidden areas**: dinding palsu, ilusi, teleporter rahasia.

## 8. Enemy & Boss Design

### 8.1 Enemy Archetypes
Soldier, Beast, Spirit, Mage, Giant, Construct, Parasite, Fallen Knight, Yokai-style (Oni, Kitsune-wraith, Tengu).

### 8.2 Boss Template
- **2 Phase** minimum, Phase 2 dengan cinematic transition.
- 8–12 move set; 3 "signature" attack dengan tell sangat jelas.
- Arena didesain unik (hazard, destructible).
- Setiap boss punya **theme song** (vokal/orchestra).
- Reward: Shard + Resonance Art/weapon unik.

### 8.3 Contoh Boss
**Lady Mizuhara, Blade of Falling Petals**
- Phase 1: Iaido duelist, cepat, counter-focused.
- Phase 2: Arena penuh sakura; ia memanggil 3 "afterimage" clone.
- Weakness: Frost, break posture lewat parry.

## 9. Characters (Anime Style)

| Karakter | Role | Visual | Personality |
|----------|------|--------|-------------|
| **Player (Hollow-born)** | Protagonis customizable | Kustom gender/rambut/mata | Silent protagonist |
| **Kuro** | Guide | Kucing hitam bermata emas | Sarkastik, bijak |
| **Sera** | Rival/Companion | Rambut perak, jubah merah | Tsundere, dedicated |
| **Old Smith Haruto** | Blacksmith hub | Pria tua bertato | Gruff, hangat |
| **Merchant Nyx** | Vendor | Gadis misterius bertopeng | Playful, licik |
| **Priestess Ilia** | Quest giver | Berjubah putih, rapuh | Kind, simpan rahasia |

**Character Creator**: preset anime (rambut, wajah, tubuh, aksesori), warna custom.

## 10. Art Direction

- **Style**: Cel-shaded 3D (reference vibe: Genshin Impact × Elden Ring mood × Studio Trigger color pop).
- **Rendering**: Godot 4.x (Forward+), custom toon `.gdshader` (lighting ramp) + outline (inverted hull / post-process).
- **Color**: Warm golden aurora (explore) vs cold desaturated (danger).
- **VFX**: Anime-style impact frames, speed lines, smear frames, slow-mo.
- **UI**: Minimalis, kaligrafi + fantasy glyph.

## 11. Audio

- **Music**: orchestra + choir + J-rock-ish di boss. Aksen instrumen tradisional (koto, shakuhachi).
- **VA**: Multi-bahasa (JP/EN/ID). Dialog AI-VA draft → upgrade ke VA manusia.
- **SFX**: Impact yang berat dan memuaskan, ambient dunia kaya.

## 12. Technical Design

| Area | Pilihan |
|------|---------|
| Engine | **Godot 4.x** (GDScript utama; C# / GDExtension untuk bagian berat) |
| Platform | PC (Steam) dulu; console fase berikut |
| Target FPS | 60 FPS @ 1080p mid-range GPU |
| Networking | High-level Multiplayer API (ENet) / Steam P2P untuk Echo Link (fase akhir) |
| Save | Cloud save via Steam |
| Streaming | Zone/chunk streaming manual (scene per zona, `ResourceLoader.load_threaded_request`), visibility ranges (LOD), occlusion culling |
| AI NPC | Behavior Tree (addon LimboAI) / State Machine + NavigationAgent3D |

## 13. AI-Assisted Production Pipeline

> AI = **akselerator**, bukan pengganti total. Aset hasil AI harus di-review, di-cleanup, dan dicek lisensinya.

| Bidang | Tool Contoh | Catatan |
|--------|-------------|---------|
| Concept art | Midjourney, Flux, SDXL + **LoRA** custom style | Latih LoRA dengan art style sendiri biar konsisten |
| Character 3D | Meshy, Tripo, Hunyuan3D → cleanup di Blender | Retopo + rig manual/AutoRig/Mixamo |
| Environment | Kitbash (Quixel/Fab) + AI texture (Substance AI, Stable Diffusion) | |
| Animasi | Mixamo, Cascadeur, AI mocap (Move.ai, Plask) | Combat anim butuh polish manual |
| Kode | **Claude Code**, Copilot | Gameplay system, tools, refactor |
| Dialog/lore | Claude | Draft lalu edit human |
| Musik | Suno/Udio (draft) → composer final | Cek lisensi komersial |
| Voice | ElevenLabs (placeholder) → VA | |
| QA | AI-driven bot testing, log analysis | |

**Aturan emas:** 1) simpan prompt+seed, 2) cek lisensi komersial tiap tool, 3) jangan prompt "in the style of [seniman hidup]" atau pakai nama IP, 4) Steam wajib disclose penggunaan AI generatif.

## 14. Monetization & Business

- **Model**: Premium (US$30–50), tanpa pay-to-win.
- **DLC**: 1 expansion region + boss baru pasca-launch.
- **Cosmetic**: opsional (outfit).

## 15. Risks (Jujur)

| Risiko | Mitigasi |
|--------|----------|
| Scope AAA terlalu besar | Vertical slice dulu, world 15–20 km² |
| Kualitas aset AI inkonsisten | LoRA + art bible + manual cleanup |
| Combat tidak "enak" | Prototype combat sebelum bikin konten |
| Burnout/tim kecil | Milestone ketat, cut scope agresif |
| Masalah hukum IP/AI | Konten original, dokumentasi pipeline |
| Optimisasi open world | Chunk streaming per zona, visibility ranges, MultiMesh, profiling sejak awal |
| Keterbatasan Godot (tooling open-world, console export) | Scope dibatasi, addon komunitas (Terrain3D), console port via pihak ketiga belakangan |
