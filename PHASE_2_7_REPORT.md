# Laporan Phase 2.7 — Secondary Motion (SpringBoneSimulator3D) & Optimasi Lag Bangunan

Tanggal: 22 Oktober 2026
Target: Godot 4.7.2, renderer Compatibility, 1152×648, Intel UHD 620 / 8 GB
Status: selesai untuk lingkup ini; sisa pekerjaan dan keputusan yang *tidak* diambil didokumentasikan terbuka di §5.

---

## 1. Ringkasan

1. **Full-body secondary motion** di seluruh rantai rig yang memang longgar kini berjalan lewat native `SpringBoneSimulator3D` (33 chain, 1 simulator per grup gerak), menggantikan sistem tulis-ulang pose prosedural. Animasi berjalan, timing combat, dan attach katana tidak berubah (suite 2.1/2.6/2.7 hijau).
2. **Profiling & optimasi lingkungan** dilakukan dengan instrumen pengukuran baru yang stabil (`--disable-render-loop` + satu `RenderingServer.force_draw` per sampel). Hasil A/B di scene produksi, 2 state diukur bergantian dalam 1 proses, 4 ronde:
   - Stasiun *entry*: **11.41 → 10.37 ms (−9.1%)**, 509 → 447 draw call, 484,7k → 420,8k primitif.
   - Stasiun *dense_buildings*: **11.12 → 10.39 ms (−6.5%)**, 408,9 → 402,7 draw call.
   - Stasiun *combat_active*: **11.46 → 10.97 ms (−4.3%)**, 363 → 356 draw call.
   - Stasiun *low_density* (kontrol, kerja render identik): **5.39 → 4.99 ms (−7.3%)** — efek penghematan anggaran shadow.
   - Semua stasiun kini berada di ≥ 83–96 fps GPU-bound; target 60 FPS @1152×648 tercukupi dengan headroom.
3. Tidak ada error baru di proyek, tidak ada aset baru, tidak ada commit otomatis.

---

## 2. Bagian A — Secondary Motion

### 2.1 Inventaris chain (dari data skeleton asli)

Sumber: `.godot/phase_2_7/rig_player.txt` (211 bone) dan `rig_soldier.txt` (102 bone), diekstrak dari model produksi.

| Grup | Jumlah chain | Bone (contoh nama rig) |
|---|---|---|
| Hair | 17 | `Shibahu_Hair[A-K]1_`, `Shibahu_Hair_In[A-E]1_`, `Shibahu_Ahoge1..5` (ringkasan: 16 strand + ahoge) |
| Ears | 2 | `Shibahu_Ear_Left/Right1..5` |
| Tail | 1 | `Shibahu_Tail1..7` |
| Clothing | 10 | `Shibahu_Jacket[A-I]1..4` (9 tepi jaket) + `Shibahu_Belt1..3` |
| Accessories | 3 | `Shibahu_Dogtag1..4` + `Shibahu_Bust_Left/Right1..2` |
| **Total** | **33** | |

Catatan rig yang **hilang** (didokumentasikan jujur, tidak dipalsukan): Soldier (102 bone) tidak punya rantai kain/rambut longgar sama sekali — tidak ada yang bisa disimulasikan di sana; torso protagonis hanya memiliki tepi jaket (9 chain) longgar, tidak ada rantai skirt/apron terpisah.

### 2.2 Arsitektur

- **1 simulator per grup gerak** (5 grup), **1 setting per chain** (33 setting) → tidak ada bone yang dimiliki dua solver; preview group-toggle trivial.
- Simulator ditambahkan ke `Skeleton3D` **dari `PlayerCharacterModel._enter_tree`**: `Skeleton3D` mengunci daftar modifier saat `POST_ENTER_TREE`, penambahan runtime setelah itu diabaikan oleh engine.
- Sampling pose di dalam `Skeleton3D.skeleton_updated` / pengait `SpringBoneSimulator3D.modification_processed`; setelah frame selesai engine mengembalikan pose authored, jadi tidak ada konflik dengan `AnimationPlayer`.
- Kolisi per grup: sphere kepala (`SpringBoneCollisionSphere3D`) + capsule badan (`Capsule3D`); radius dalam metre, offset bone-local cm; variasi stiffness/drag per-chain deterministik.
- Impuls dikelompokkan per grup (serang/dash/lompat/landing/kena-hit) dengan clamp sehingga tidak ada exaggeration berlebihan; `reset()`, `set_group_enabled()`, solo-chain tersedia (test & preview memakainya).
- Death/respawn dan hit-react kini mereset spring agar tidak membawa pose kotor.

### 2.3 Perilaku terverifikasi (bukti jendela, bukan headless-only)

- `tests/capture_phase_2_7_secondary_motion.gd` → 12 PNG `screenshot_phase_2_7_*.png`: idle depan/belia, sprint belakang/samping, walk samping, serangan, guard, dodge, jump, close-up chain tail/hair/clothing/ears.
- Penilaian visual: ekor bergoyang alami di belakang, rambut bob jarang terdistorsi liar, telinga tegak, tepi jaket bergoyang halus. Ujung ekor mendekati kaki saat sprint, tapi tidak menembus mesh; untuk slice ini parameter cukup.

### 2.4 Bukti otomatis

- `tests/test_phase_2_7_secondary_motion.gd` — **24/24** (inventaris chain, tanpa duplikasi bone, simulasi parent, kolisi, settle, respon impuls, reset, katana, preview toggle).
- `tests/test_phase_2_1.gd` — **14/14**; `tests/test_phase_2_6_animation_gate.gd` — **21/21** (dua-duanya sudah dimigrasi menerima solusi native spring, bukan dibenarkan).
- `tools/secondary_motion_preview.gd/.tscn` — pratinjau dev-only dengan model sprint produksi asli (toggle grup 1–5, solo chain C, animasi A, reset R, impuls P, orbit/zoom). Bukan scene produksi.

---

## 3. Bagian C — Profil & Optimasi "Building Lag"

### 3.1 Temuan instrumen (sangat penting untuk review)

Pengukuran pertama memakai `await process_frame` dengan vsync off memberi angka yang **tidak bisa dipercaya**: `process_frame` hanya menunggu submisi CPU, bukan selesainya render GPU, sehingga frame time bisa jadi 4–40 ms tergantung seberapa dalam queue driver dan suhu GPU. Bukti: `tests/diagnose_phase_2_7_focus.gd` menunjukkan 135 fps "normal" vs **57,5 fps saat `RenderingServer.force_draw`** (benar) di stasiun yang sama, dan 778 fps "normal" vs 93 fps benar pada `--disable-render-loop`.

Instrumen final (semua angka di laporan ini): jalankan engine dengan `--disable-render-loop`, lalu **satu `RenderingServer.force_draw(false)` per sampel**. Dengan itu, setiap sampel = tepat satu draw GPU penuh. Uji kestabilan: rata-rata 2 ronde identik dalam batas ±0,5%.

### 3.2 Rute & stasiun (`tests/compare_phase_2_7.gd`)

4 stasiun di SCENE `main.tscn` asli (bukan scene replika):
1. `low_density` — dinding entry, melihat keluar; **kontrol** (aktor tak terlihat).
2. `entry` — dari pintu entry melintasi seluruh reruntuhan (baseline 509 draw, 484,7k primitif; stasiun paling berat).
3. `dense_buildings` — di dalam courtyard menghadap gerbang, wall, crypt, pohon.
4. `combat_active` — pertarungan jarak dekat vs Soldier PAKAI state machine live (`CHASE`).

Prosedur: prewarm 2 state × 4 stasiun (shader compiled), 4 ronde dengan **urutan interleave (baseline dulu / optimized dulu berselang)**, tiap pengukuran 25 warmup + 120 sampel forced draw. Total ≈ 5.000 frame rute hidup; rute penuh ~60–70 detik per proses. AI Soldier dibekukan (`set_physics_process(false)`) supaya posisi musuh tidak mengacaukan culling; HUD tetap hidup.

### 3.3 Hasil A/B (rata-rata 4 ronde; `.godot/phase_2_7/compare.json`)

Baseline = state render pra-optimasi yang direkonstruksi runtime lewat `DarkRuinsEnvironment.set_optimized_rendering(false)` + shadow config lama; Optimized = state produksi baru. Dimensi waktu **GPU** per frame (ms).

| Stasiun | Baseline avg | Optimized avg | Δ | Med (B→O) | p95 (B→O) | 1%low fps (B→O) | Draws (B→O) | Prims (B→O) |
|---|---|---|---|---|---|---|---|---|
| low_density (kontrol) | 5.39 | 4.99 | **−7.3%** | 5.36→4.90 | 5.82→5.56 | 162.8→161.4 | 228→228 (identik) | 1,826→1,826 |
| entry | 11.41 | 10.37 | **−9.1%** | 11.36→10.34 | 12.01→10.94 | 71.0→86.2 | 509→447 (−12.2%) | 484,716→420,836 (−13.2%) |
| dense_buildings | 11.12 | 10.39 | **−6.5%** | 11.08→10.36 | 11.58→10.86 | 81.7→88.1 | 408.9→402.7 | 378,345→394,391 (+4.2%) |
| combat_active | 11.46 | 10.97 | **−4.3%** | 11.45→10.94 | 12.01→11.41 | 78.0→83.3 | 363→356 | 308,132→347,405 (+12.7%) |

Pembacaan:
- Draw call dan frame time turun real di semua stasiun yang memuat set dressing; kontrol `low_density` pun turun karena penghematan anggaran shadow (atlas lebih kecil dan frustum shadow lebih pendek lebih murah, walau pengaruhnya tak terlihat di draw call).
- Kenaikan kecil prims di `dense`/`combat` adalah **trade-off batching** (MultiMesh punya AABB lebih besar; instance di dalamnya tidak di-cull per-instance). Tidak masalah karena draw call dan waktu frame turun.
- **Stabil**: baseline/optimized terulang 4×; pembacaan tiap ronde aman dalam ±1%.

### 3.4 Atribusi biaya di stasiun `entry` (probe `tests/diagnose_phase_2_7_toggle.gd`)

Dari kondisi optimized, keluarkan satu sistem pada satu waktu (rata-rata 2 ronde):

| State | avg ms | Δ dari state sebelumnya |
|---|---|---|
| entry_full (optimized) | 10.26 | — |
| + HUD off | 9.21 | −1.05 ms (‑228 draw) |
| + visual player off | 7.34 | −1.87 ms |
| + Soldier off | 6.92 | −0.42 ms |
| + Environment off | 4.48 | −2.44 ms |
| + directional shadow off | 4.04 | −0.44 ms |

Pesan untuk direksi: biaya lingkungan **setelah** optimasi ini tinggal 2.44 ms; biaya HUD (1.05 ms, 228 draw) dan geometri karakter (1.87 ms, 141k tris) keduanya **di luar lingkup "bangunan"** dan didokumentasikan sebagai sisa biaya tertinggi (§5).

### 3.5 Perubahan yang diimplementasikan

1. **`world/dark_ruins_environment.gd`** (ditulis ulang, tetap dijelaskan dalam header):
   - **Batching MultiMesh per chunk**: mesh duplikat (wall/pillar/fence/torch/post lantern/barrier) yang identik (mesh path + signature material + chunk `z < 6 m` entry atau courtyard + `cast_shadow`) digabung menjadi `MultiMeshInstance3D` — **16 visual → 8 batch**, 32 collision body & navmesh tetap utuh (visual asli disembunyikan, kolisi tidak disentuh).
   - **Shadow hemat**: token `_SHADOWLESS_PROP_TOKENS` (gravestone, fence, barrel, crates, rubble, stairs, torch, lantern, column) tidak lagi mengirim bayangan; kontribusinya tidak terbaca pada jarak kamera gameplay. Wall/pillar/gerbang/crypt/pohon tetap melempar shadow.
   - `set_optimized_rendering(bool)` (publik) untuk rekonstruksi baseline saat benchmark).
2. **`main.tscn`**: `DirectionalLight3D` → `directional_shadow_max_distance = 45.0` (dari default 100), `shadow_bias = 0.05`, `shadow_normal_bias = 1.0`. Mode tetap PSSM 4.
3. **`project.godot`**: `lights_and_shadows/directional_shadow/size` 4096 → **2048**, `soft_shadow_filter_quality` → 0.

### 3.6 Yang dicoba tapi diambil keputusan jujur (tidak diadopsi)

- **Orthogonal single-split** shadow: diuji A/B first-hand; selisih vs PSSM-4 @2048 dalam batas noise (<1%), bayangan dekat jauh lebih kasar. Ditolak, PSSM 4 + range 45 m dipertahankan.
- **Occlusion culling (bake)**: tidak diterapkan — courtyard terbuka; pandangan entry memotong area dalam sedang terlihat langsung lewat gerbang, penghalang visual tak banyak yang menutup lini pandangan. Potensi kecil dan berisiko paket bake.
- **LOD/visibility range** untuk set dressing: setiap prop berada di <25 m dari semua view; culling frustum sudah efektif. Tidak ada pengukuran yang menunjukkan keuntungan.
- **Soft shadow/PCF bed**: 0 (sudah produksi) vs nilai lain tidak cukup terukur di Compatibility; disentuh di project.godot hanya untuk aman di UHD.

### 3.7 Sisa biaya di luar lingkup "bangunan" (dokumentasi, belum dioptimasi)

- **HUD**: 228 draw call, ~1.05 ms — diduga kuat SystemFont (glyph texture terpisah). Perbaikan alami: memuat satuat assembly font yang di-bundle; di luar lingkup fase ini karena menyentuh tampilan UI.
- **Geometri karakter**: player 141.564 tris (31 mesh opaque; hanya 364 tris transparan → tidak bisa dihemat lewat matikan bayangan rambut), soldier 43.787 tris.
- **Residual scene** (sky + fog + lantai + lampu) = 4.04 ms setelah HUD/player/soldier/environment/shadow dimatikan; skybox bake/fog halus bisa mengecilkan bagian ini bila anggaran ketat.

### 3.8 Bukti visual

- `screenshot_phase_2_7_env_entry.png`, `env_dense.png`, `env_courtyard.png`, `env_gate.png` (dengan batching PSSM2048/45) — semua prop tampil, bayangan terbaca, tidak ada prop menghilang.
- `screenshot_phase_2_7_*` karakter/chain tetap valid (tidak menyentuh aset).

---

## 4. Validasi

| Check | Hasil |
|---|---|
| `--headless --quit` load project | bersih, exit 0 |
| test_phase_2_1 / 2_3 / 2_4_presentation / 2_5_runtime | 14/14, 13/13, 22/22, 15/15 |
| test_phase_2_6_animation_gate | 21/21 |
| test_phase_2_7_secondary_motion | 24/24 |
| test_phase_2_2 (regresi lama) | 9/10 — **sama seperti sebelum pekerjaan ini** (tidak ditambah/dibuang) |
| `git diff --check` | aman (0 whitespace error) |
| Commit | tidak dilakukan (sengaja) |
| `.uid` baru | dibuat oleh editor scan (bukan manual) |
| Kinerja | ≥ 96 fps (entry) GPU-bound via force-draw; target 60 FPS aman dengan vsync on |

---

## 5. Sisa pekerjaan & Open Questions

1. **HUD draw volume** (228 draw ≈ 1.05 ms di stasiun entry) — kandidat lanjutan pengurangan (bundled font / satu bentuk drawing). Di luar lingkup fase ini; butuh keputusan desain UI.
2. **Geometri karakter** (player 141k tris): butuh keputusan aset (LOD/mesh merge) — bukan pekerjaan code render.
3. **Skybox bake / fog tuning** untuk membongkar bagian dari 4.04 ms residual; pengukuran perlu diulang bila ingin maju.
4. Occlusion culling bake tetap tersedia sebagai opsi kecil bila area berikutnya lebih tertutup (ruang interior); jangan dipaksa di courtyard terbuka.
5. `tests/benchmark_phase_2_7.gd` versi `await process_frame` terbukti tidak stabil di mesin ini; `compare_phase_2_7.gd` yang memakai force-draw adalah instrumen otoritatif. `benchmark_baseline.json` (19,66 ms entry) boleh dibaca sebagai referensi kasar era pra-optimasi; `benchmark_optimized.json` **jangan** dipakai (mesin throttled; instrumen lama).

## 6. Jejak perubahan (fase ini)

- `world/dark_ruins_environment.gd` — batching MultiMesh per chunk, shadow token, toggle `set_optimized_rendering`.
- `main.tscn` — konfigurasi DirectionalLight3D shadow.
- `project.godot` — ukuran directional shadow atlas + soft filter.
- `tests/test_phase_2_7_secondary_motion.gd` (24 asersi), update `test_phase_2_1.gd`, `test_phase_2_6_animation_gate.gd`.
- `tests/compare_phase_2_7.gd` — instrumen A/B otoritatif.
- `tests/benchmark_phase_2_7.gd`, `diagnose_phase_2_7_{focus,shadow,toggle}.gd`, `capture_phase_2_7_environment.gd`, `tools/secondary_motion_preview.{gd,tscn}`.
- `characters/player/visual/player_secondary_motion.gd` + `player_character_model.gd` (loop spring, hooks).
- PNG di `res://screenshot_phase_2_7_*`.
