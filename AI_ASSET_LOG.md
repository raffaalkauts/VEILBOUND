# AI_ASSET_LOG.md
## VEILBOUND: Log Aset Hasil AI

Tujuan: bukti asal-usul aset (untuk legal, disclosure Steam, dan konsistensi kualitas).
**Aturan:** setiap aset yang dibuat/dibantu AI wajib dicatat di sini sebelum masuk `res://`.

---

## 1. Kebijakan

1. Hanya pakai tool dengan **lisensi komersial** yang jelas. Simpan screenshot/arsip ToS saat dipakai.
2. Dilarang menyebut nama seniman hidup atau IP/karakter berhak cipta di prompt.
3. Dilarang memasukkan karya orang lain tanpa izin sebagai data training LoRA/referensi img2img.
4. Aset hero (protagonis, boss besar, key art) wajib **cleanup/polish manual**.
5. Simpan **prompt, seed, model/versi** agar bisa direproduksi.
6. Steam: sertakan disclosure penggunaan AI generatif di halaman toko.
7. Review ulang saat tool mengubah ToS atau regulasi berubah.

## 2. Status Aset

| Status | Arti |
|--------|------|
| `RAW` | Output AI mentah |
| `CLEANING` | Sedang dibersihkan (retopo, texture fix, dll.) |
| `APPROVED` | Lolos style check, siap masuk engine |
| `IN-ENGINE` | Sudah di `res://` |
| `REPLACED` | Diganti aset buatan manusia / versi baru |
| `REJECTED` | Tidak dipakai |

## 3. Tool yang Digunakan (Isi & Verifikasi Lisensi)

| Tool | Kegunaan | Versi/Model | Plan | Lisensi komersial? | Tanggal cek ToS | Catatan |
|------|----------|-------------|------|--------------------|-----------------|---------|
| | Concept art | | | ☐ Ya ☐ Tidak | | |
| | 3D generation | | | ☐ Ya ☐ Tidak | | |
| | Texture | | | ☐ Ya ☐ Tidak | | |
| | Musik | | | ☐ Ya ☐ Tidak | | |
| | Voice | | | ☐ Ya ☐ Tidak | | |
| | Kode (Claude Code, dll.) | | | ☐ Ya ☐ Tidak | | |

## 4. LoRA / Model Kustom

| Nama LoRA | Base model | Dataset (sumber & hak) | Jumlah gambar | Tanggal latih | Catatan |
|-----------|------------|------------------------|---------------|---------------|---------|
| | | | | | |

> Dataset LoRA sebaiknya terdiri dari gambar buatan sendiri, komisi seniman dengan izin tertulis, atau aset berlisensi jelas.

## 5. Log Aset

| ID | Nama File | Tipe | Tool & Versi | Prompt (ringkas) | Seed | Input referensi | Cleanup manual | Status | Tanggal | Pemeriksa |
|----|-----------|------|--------------|------------------|------|-----------------|----------------|--------|---------|-----------|
| A-0001 | player_character_model_placeholder.tscn | 3D Prototype | Godot Engine 4.7.2 | Female fox kitsune anime protagonist | N/A | GDD Sec 9, VEILBOUND Art Bible | Assembled native modular geometry & materials | REPLACED | 2026-10-18 | Senior Gameplay Engineer |
| A-0002 | fox_girl_character.glb | 3D Hero Character | VRoid Studio / 3D Model | Stylized Anime Fox Girl (Kitsune) | N/A | GDD Sec 9, Hollow-born Protagonist | Converted VRM to GLB container, verified 213-bone humanoid armature with fox ears & tail, 8 PBR mesh parts (60,907 tris), calibrated textures & weapon rig | REPLACED | 2026-10-18 | Senior Gameplay Engineer |
| A-0003 | anime_fox_girl.glb | 3D Hero Character | Sketchfab / darknessvoid403 | Stylized Anime Fox Girl (Shibahu) | N/A | Sketchfab 3D Model | Real 3D model, 211 bones, 141k tris, PBR textures, bone attachments on right hand and hip, 12 complete skeletal animations | IN-ENGINE | 2026-10-18 | Senior Gameplay Engineer |
| A-0004 | anime-girl_running_panic.glb | 3D Enemy Character | Sketchfab 3D Model | Anime Girl Runner / Soldier Melee | N/A | User provided Soldier Asset | Rigged 3D model, 102 bones, 43k tris, embedded running cycle + state-driven animations (idle, telegraph, attack, stagger, death), weapon bone attachment | IN-ENGINE | 2026-10-18 | Senior Gameplay Engineer |
| A-0005 | KayKit Dungeon Pack (formerly Dungeon Remastered) | 3D Environment (Ruins) | Kay Lousberg (kaylousberg.com) | Modular dark fantasy dungeon & ruins kit | N/A | [Official free download](https://kaylousberg.itch.io/kaykit-dungeon-pack) | 70 GLB models from the free 1.1 pack are present locally; this slice uses selected pillars, arches, cracked walls, stairs, rubble, torches, barrels, crates, and floor slabs; glTF/GLB, Godot compatibility, and CC0 1.0 stated by creator | IN-ENGINE | 2026-10-21 | Senior Gameplay Engineer |
| A-0006 | KayKit Halloween Bits | 3D Environment (Sanctuary & Cemetery) | Kay Lousberg (kaylousberg.com) | Gothic cemetery & shrine props | N/A | [Official free download](https://kaylousberg.itch.io/halloween-bits) | Imported glTF models (shrine, standing/post lanterns, gnarled dead trees, grand arch gate, crypt, fences, gravestones); creator offers a free 60+ model download with GLTF and CC0 1.0 | IN-ENGINE | 2026-10-21 | Senior Gameplay Engineer |

## 6. Template Entri Detail (copy per aset penting)

### A-0001: player_character_model_placeholder.tscn
- Tipe: 3D Temporary Visual Prototype (Archived)
- Tool & versi: Godot Engine v4.7.2 Standard
- Tanggal: 2026-10-18
- Deskripsi: Initial procedural primitive geometry prototype (spheres, capsules, cylinders) used for early Phase 2.1 scaffolding.
- File final: res://characters/player/visual/player_character_model_placeholder.tscn
- Lisensi/ToS yang berlaku: Project Proprietary / MIT Compatible (Native Godot geometry)
- Style check (sesuai Art Bible?): ☑ Ya ☐ Tidak
- Status: REPLACED (retained for comparison as requested)
- Catatan: Replaced by genuine modeled 3D asset A-0002.

### A-0002: fox_girl_character.glb
- Tipe: 3D Hero Character Mesh & Rig
- Tool & versi: VRoid Studio / Open Source 3D Model
- Creator / Source: Open source repository `anjaydo/vroid-ai-companion` (Fox Loli.vrm)
- Original Source URL: https://github.com/anjaydo/vroid-ai-companion/raw/main/Fox%20Loli.vrm
- Tanggal akuisisi: 2026-10-18
- Lisensi/ToS yang berlaku: MIT License (free to use, copy, modify, merge, publish, distribute, sublicense, and sell copies). Creative Commons / VRoid Standard Free Distribution compatible.
- Lisensi komersial diizinkan: Ya
- Modifikasi diizinkan: Ya
- Attribution requirements: None required under MIT terms, provenance documented herein.
- File sumber: `res://assets/characters/protagonist/source/fox_girl_character.vrm` (19.27 MB, glTF 2.0 binary container)
- File imported: `res://assets/characters/protagonist/imported/fox_girl_character.glb` (20.2 MB)
- Textures: 8 extracted PBR diffuse/normal texture maps under `res://assets/characters/protagonist/imported/` (`tex_lapan_c_head.png`, `tex_lapan_c_body.png`, `tex_lapan_c_cloth.png`, `tex_lapan_c_cloth_under.png`, `tex_lapan_c_hair_front.png`, `tex_lapan_c_hair_back.png`, `tex_lapan_c_face_efect_a.png`)
- Spesifikasi geometri:
  - Total Triangles: 60,907 (perfectly within the ≤65k budget for Intel UHD 620 target)
  - Total Vertices: 48,565
  - Height: 1.53m (fits cleanly within the 1.8m capsule collider, feet at y=0.001)
  - Armature: 213 bones (`00_lapan_Armature/Skeleton3D`) including articulated fox ears (`ear_a.001.L/R` to `.003`), 12-bone fox tail (`tail.001` - `tail.012`), hair strands, and complete humanoid limb/torso hierarchy.
  - Mesh partitions: `body`, `lapan_body_base`, `lapan_body_tail`, `lapan_cloth_blouse`, `lapan_cloth_bustier`, `lapan_cloth_pants`, `lapan_cloth_sneaker`, `lapan_hair`.
- Integrasi ke Game:
  - Scene target: `res://characters/player/visual/player_character_model.tscn`
  - Facing direction: Calibrated with 180° Y rotation to face standard Godot forward (-Z).
  - Equipment: Katana mounted to right hand with combat draw/sheathe toggle; Scabbard and sheathed hilt mounted to left hip.
  - Animation: Driven by AnimationPlayer with 12 locomotion/combat state clips + secondary dynamic bone articulation on fox tail and ears.
- Style check (sesuai Art Bible?): ☑ Ya ☐ Tidak (Matches anime fox-girl / kitsune Hollow-born protagonist)
- Status: REPLACED
- Catatan: Replaced by exact Sketchfab candidate A-0003.

### A-0003: anime_fox_girl.glb
- Tipe: 3D Hero Character Mesh & Rig
- Creator / Source: darknessvoid403 / Sketchfab (`anime_fox_girl.glb`)
- Tanggal akuisisi: 2026-10-18
- File sumber: `res://assets/characters/protagonist/source/anime_fox_girl.glb` (16.89 MB)
- File imported: `res://assets/characters/protagonist/imported/anime_fox_girl.glb`
- Spesifikasi geometri:
  - Total Triangles: 141,564
  - Total Vertices: 99,121
  - Armature: 211 bones (`Skeleton3D`), including full humanoid skeleton, fox ears (`Shibahu_Ear_Left1`–`5`, `Shibahu_Ear_Right1`–`5`), 7-bone bushy tail (`Shibahu_Tail1`–`7`), and complete facial/hair joints.
  - Textures: 14 extracted PBR texture maps with diffuse, normal, and roughness.
  - Calibration: Unit scale 1.0 (internal GLB scale 0.01 calibrated to 1.35m head height), centered with X=0.54m offset, rotated 180° Y to align with Godot forward (-Z).
- Integrasi ke Game:
  - Scene: `res://characters/player/visual/player_character_model.tscn`
  - Equipment: `BoneAttachment3D` on `Shibahu_RightHand_0167_217` for drawn katana; `BoneAttachment3D` on `Shibahu_Hips_00_245` for sheathed scabbard and hilt.
  - Animation: Driven by AnimationPlayer with 12 complete skeletal animation clips in `res://characters/player/visual/player_animations.tres` (`idle`, `walk`, `sprint`, `jump`, `fall`, `dodge`, `attack_1`, `attack_2`, `attack_3`, `guard`, `hit_react`, `death`).
- Status: IN-ENGINE

### A-0005: KayKit Dungeon Pack environment subset
- Tipe: 3D Environment Kit
- Creator: Kay Lousberg
- Sumber resmi / unduhan gratis: https://kaylousberg.itch.io/kaykit-dungeon-pack
- Lisensi: CC0 1.0 Universal; halaman kreator menyatakan versi gratis dapat dipakai untuk proyek komersial tanpa atribusi.
- Kompatibilitas: Paket gratis 1.1 berisi FBX, GLTF, dan OBJ; halaman resmi menyebut Godot sebagai engine yang didukung. File GLB yang digunakan berada di `res://assets/environment/ruins/`.
- Isi terpakai: pilar, kolom, dinding retak/berlubang, gerbang, tangga lebar, rubble, crates, barrel, torch, dan lantai batu.
- Integrasi: scene `res://world/dark_ruins_environment.tscn`; lantai batu diinstansiasi melalui `res://world/floor_tile_field.gd`; collision dibuat dari mesh untuk bagian yang diberi grup `environment_solid`.
- Verifikasi sumber dan lisensi: 2026-10-21; halaman sumber menampilkan unduhan gratis dan lisensi CC0.
- Status: IN-ENGINE

### A-0006: KayKit Halloween Bits environment subset
- Tipe: 3D Environment Props
- Creator: Kay Lousberg
- Sumber resmi / unduhan gratis: https://kaylousberg.itch.io/halloween-bits
- Lisensi: CC0 1.0 Universal; kreator menyatakan gratis untuk penggunaan komersial dan tanpa atribusi.
- Kompatibilitas: Unduhan gratis mencakup 60+ model; format yang ditawarkan termasuk OBJ, FBX, dan GLTF, serta halaman resmi menyebut Godot.
- Isi terpakai: shrine candles, lantern, arch gate, crypt, dead trees, fences, dan gravestones. File glTF sumber berada di `res://assets/environment/cemetery/`.
- Integrasi: scene `res://world/dark_ruins_environment.tscn` dan `res://world/lantern_checkpoint.tscn`.
- Verifikasi sumber dan lisensi: 2026-10-21; halaman sumber menampilkan unduhan gratis dan lisensi CC0.
- Status: IN-ENGINE

### A-0004: anime-girl_running_panic.glb
- Tipe: 3D Melee Enemy Character Mesh & Rig
- Creator / Source: User-provided Sketchfab model (`anime-girl_running_panic.glb`)
- Tanggal akuisisi: 2026-10-18
- File imported: `res://characters/enemies/soldier/anime-girl_running_panic.glb` (7.46 MB)
- Spesifikasi geometri:
  - Total Triangles: 43,787 (36,615 in Object_7, 7,172 in Object_8)
  - Total Height: 1.68m (fitting cleanly in the 1.8m capsule)
  - Armature: 102 bones (`Skeleton3D`), Character Creator standard hierarchy.
  - Textures: PBR diffuse/normal maps (`anime-girl_running_panic_0.png`, `anime-girl_running_panic_1.png`).
- Integrasi ke Game:
  - Scene: `res://characters/enemies/soldier/soldier_enemy.tscn`
  - Equipment: `BoneAttachment3D` on right hand `CC_Base_R_Hand_88` holding stylized soldier blade.
  - Animation: Embedded running animation `Animation` for patrol/chase, plus state-driven animations (`soldier/idle`, `soldier/telegraph`, `soldier/attack`, `soldier/stagger`, `soldier/death`) in `res://characters/enemies/soldier/soldier_animations.tres`.
- Status: IN-ENGINE


```
### A-XXXX: <nama aset>
- Tipe: concept / 3D / texture / audio / voice / code
- Tool & versi:
- Tanggal generate:
- Prompt lengkap:
- Negative prompt:
- Seed / parameter:
- Referensi input (jika ada, dan sumber haknya):
- Output mentah: <path>
- Perubahan manual (retopo, repaint, rig, dll.):
- File final: res://...
- Lisensi/ToS yang berlaku:
- Style check (sesuai Art Bible?): ☐ Ya ☐ Tidak
- Cek kemiripan IP lain (reverse image search): ☐ Selesai
- Status:
- Catatan:
```

### A-0007: Quaternius Universal Animation Library Standard
- Tipe: Retargetable humanoid animation source
- Creator / Source: Quaternius, https://quaternius.com/packs/universalanimationlibrary.html
- File lokal: `res://assets/animations/quaternius/universal_animation_library_standard.glb`
- Lisensi: CC0 1.0 Universal; license file retained at `res://assets/animations/quaternius/LICENSE.txt`.
- Clip yang dipakai sebagai sumber retarget: `Idle`, `Walk`, `Sprint`, `Jump`, `Roll`, `Sword_Attack`, `Sword_Idle`, `Hit_Chest`, `Death01`.
- Integrasi: clip diperiksa dan dipakai sebagai sumber runtime retarget khusus untuk rig Soldier 102-bone (`Idle`, `Walk`, `Sprint`, `Sword_Attack`, `Hit_Chest`, `Death01`) dengan mapping CC_Base eksplisit dan tanpa root-motion translation. Runtime retarget generik tetap dinonaktifkan untuk protagonist karena rest-pose/axis mismatch terukur menghasilkan arms-out pose pada skeleton 211-bone; protagonist tetap memakai library target-compatible.
- Status: INSPECTED / APPLIED TO SOLDIER; NOT APPLIED TO PROTAGONIST

## 7. Checklist Sebelum Aset Masuk Engine

- [ ] Tercatat di log (tool, prompt, seed)
- [ ] Lisensi tool mengizinkan penggunaan komersial
- [ ] Tidak menyerupai IP/karakter yang sudah ada (reverse image search)
- [ ] Sesuai Art Bible (palette, shape language)
- [ ] Mesh: retopo, poly count sesuai budget, UV rapi, nama file sesuai konvensi
- [ ] Texture: resolusi sesuai budget, tidak ada watermark/artefak teks
- [ ] Rig & skin weight dites dengan animasi
- [ ] Format `.glb` (3D) / `.png` / `.ogg`
- [ ] Review oleh minimal 1 orang selain pembuat

## 8. Daftar Disclosure Steam (Diisi Menjelang Rilis)

| Kategori | Dibuat dengan AI? | Pre-generated / live-generated | Catatan |
|----------|-------------------|--------------------------------|---------|
| Art | | | |
| Audio / Musik | | | |
| Voice | | | |
| Kode | | | |
| Teks / Lore | | | |
