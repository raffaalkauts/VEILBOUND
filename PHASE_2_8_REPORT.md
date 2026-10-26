# PHASE 2.8 REPORT — Integration & Visual Acceptance Gate

VEILBOUND: Crown of the Shattered Aether · Godot 4.7.2 · Renderer Compatibility (OpenGL 3.3)
Tanggal: 23 Oktober 2026 · Baseline performa: Intel UHD 620 / 8 GB @ 1152×648

Tidak ada fitur/region/boss baru. Semua perubahan sesuai arah audit-first: tabel defect
beserta bukti, koreksi, dan acceptance test. Tidak ada commit otomatis; working tree
dibiarkan (hampir seluruh produksi tetap untracked sesuai kondisi repo).

---

## 1. Tabel Defect (format wajib fase 2.8)

| # | Defect | Root cause terkonfirmasi | Bukti yang ada | Koreksi yang diterapkan | Acceptance test |
|---|--------|--------------------------|----------------|-------------------------|-----------------|
| 1 | HUD menggambar 228 draw calls ≈ 1,05 ms overhead | UI per-bar/per-angka berdiri sendiri: bar miring menggambar polygon per-grup gradien tiap 10 px, kompas membuat 1 node/label arah, layout rebuild pakai `queue_free` deferred | `diagnose_phase_2_8_hud_toggle.gd` (atribusi full−off), profil draw `compare_phase_2_7.gd` | (a) gradien fill bar miring dibake sekali ke `GradientTexture1D`, digambar 1× `draw_polygon(points, colors, uvs, texture)`; (b) 8 label kompas digabung ke satu canvas item via `draw_string`; (c) `_build_layout` membebaskan child lama **secara sinkron** (defect 2); (d) stylebox ProgressBar ditimpa `StyleBoxEmpty`; `GradientTexture1D` tidak punya properti `height` (lesson) | `compare_phase_2_7.gd`: HUD draw **228 → 70 (−69%)**; capture `screenshot_phase_2_8_hud_{1152x648,1280x720,1920x1080}.png` identik secara desain, gradien lebih halus |
| 2 | Nama panel HUD bentrok saat rebuild runtime | Deferred `queue_free` menahan koordinat nama sehingga child baru di-auto-rename `@PanelContainer@N` — test yang mem-passing nama path jadi flaky | capture runtime + log rename saat probe HUD | `ui/combat_hud.gd::_build_layout` membebaskan layout lama secara sinkron (bukan deferred) | `test_phase_2_4_presentation.gd` 22/22 dan capture 3 resolusi saat rebuild ulang tanpa nama `@PanelContainer@N` |
| 3 | Retarget runtime UAL Soldier menghasilkan pose mendekati T/A-pose (tangan di tinggi bahu, ~71% tinggi kepala) | Formula `target_rest * source_rest⁻¹ * source_pose` mengasumsikan konvensi sumbu local kedua rig identik — ternyata tidak; terbukti dengan sampling proyeksi tangan vs pinggul kedua rig | `diagnose_phase_2_8_soldier_pose.gd` (hands_rel_hip target ±0,21–0,27 · source ±0,29–0,35 @ tinggi bahu); capture Phase 2.6/2.8 "lengan terangkat" | `soldier_enemy.gd::_retarget_ual_animation` ditulis ulang: transfer rotasi **global per sampel** — konstanta `ALIGN` dari basis landmark rest-pose (arah paha kanan-kiri = "kanan", pelvis→head = "up"), fragmen tiga bebannya jadi `tar_global = ALIGN * src_global`, key local back-solved menurut kedalaman chain (leluhur termapping dulu, tulang target antara leluhur termapping memakai rotasi rest) | Probe invarian: **residual ≤ 1,65°** di seluruh chain termapping (`layer_diff.txt`, `rotation_diff.txt`); sampling world-space per state (idle berdiri, walk melangkah, sprint condong_feet mengangkat, attack merendahkan pelvis 0,94→0,72, death collapse pelvis 1,11→0,00); capture visual `screenshot_phase_2_8_soldier_{idle,walk,sprint,attack_mid,hit,death}.png` |
| 4 | Torso/lengan masih condong +10° setelah fix #3 | UAL `root` & `DEF-spine.001` tidak punya rotation track di klip (statis), jadi tidak ikut termapping; rest chain target `RL_BoneRoot −90° × Hip_99 +90° × Waist_98 +10,8°` bocor ke seluruh tulang di atas pinggul. Pengemudi tangan statis pada root dilarang karena rotasi root memutar seluruh pohon posisi (pelvis nyemplung ke −0,23 m) | `layer_diff.txt`: residual root 100°, spine001 23°, spine2+ 9–10°; kembali 0–1,6° setelah perbaikan; eksperimen root-driven memberi pelvis world y=−0,23 | Bone bernama mapping tapi statis ikut didorong menggunakan sampling global per sampel (`DEF-spine.001` → `CC_Base_Waist_98`); **root sengaja tidak dipakai** (rest RL×Hip saling meniadakan) | Residual semua chain termapping ≤1,65°; pose dunia idle/walk/sprint/attack/hit/death masuk akal (tabel di §3) |
| 5 | Crouch/death tidak memindahkan tinggi tubuh | Hanya rotasi yang ditransfer; position track pelvis tidak ada → pelvis tetap 1,17 m padahal bentuk badan krouc | pose probe pra-fix: pelvis 1,17 konstan saat attack/death | Transfer posisi pelvis rescaled (kalibrasi rest→rest, per-key digeser `ALIGN`, local back-solved dari parent rest global) | pelvis: attack 0,94→0,72→0,97; death 1,11→0,82→0,00±; feet flat saat collapse |
| 6 | ID chain spring bertabrakan | `player_secondary_motion.gd` menyusun ID dengan slicing nama bone → `Hair_In[A-E]`, kedua telinga, dan pasangan bust memakai ID sama (config salah satu saling menimpa) | inventaris chain `rig_player.txt` (211 bone); sim 33 chain tetap aktif tapi salah konfigurasi | ID chain kini `group + ":" + nama root bone (prefix trim "Shibahu_")` — unik untuk semua 33 chain; test suite hanya menghitung jumlah chain → aman | `test_phase_2_7_secondary_motion.gd` 24/24; sim audit defleksi + settle semua chain (defect 7) |
| 7 | Bukti secondary motion belum per-node/per-behavior | Audit fasa 2.7 hanya klaim total (satu klip) | `spring_audit.txt` baru | `diagnose_phase_2_8_spring_audit.gd` menjalankan skenario idle→sprint→hard turn→lompat→landing→dodge→serang→settle; 5 grup simulator (hair 17 / ears 2 / tail 1 / clothing 10 / accessories 3) aktif; CPU on/off spring 16,673 vs 16,674 ms/frame (dominasi pacing, bisa diabaikan) | Defleksi tercatat per chain (mis. tail 466 mm saat hard_turn) dan residual 0 mm saat settle |
| 8 | Test 8 `test_phase_2_2.gd` gagal (kuno) | Ekspektasi nama klip legacy ditulis sebelum pustaka `soldier_ual/*` ada (fase 2.6 memilih UAL saat tersedia); antara test dan kode produksi tidak lagi selaras | ekspektasi test vs aturan seleksi `_change_state()` di `soldier_enemy.gd` | Test 8 ditulis ulang mengikuti aturan seleksi produksi (nama klip UAL bila `soldier_ual/idle` exists, selain itu legacy); tanpa skip/delete/regresi | `test_phase_2_2.gd` **10/10** |
| 9 | Validasi input hanya E/Q (fase 2.5) | Suite lama belum menguji MMB/Tab-wheel/F secara end-to-end | gap register fase 2.5 | `tests/test_phase_2_8_integration.gd` 6/6: lock-on MMB acquire/release, siklus target Tab/wheel (soldier → Dummy_Right), F restore checkpoint (HP/stamina end-to-end), penolakan Q cooldown (`COOLDOWN 4.3s` di HUD), penolakan stamina kurang (`STAMINA` di HUD) | suite hijau; capture pendukung `screenshot_phase_2_8_{lockon_reticle,compass_north,compass_east,skill1..4,checkpoint_interact}.png` |
| 10 | Bukti apex serang Soldier belum dikaitkan ke window damage | Window damage konstanta `ATTACK_ACTIVE_START 0.35 / DURATION 0.12` (klip 0,65 s) belum diverifikasi terhadap klip hasil retarget | — | `diagnose_phase_2_8_strike_window.gd`: sampling trajectory ujung senjata (extent forward local −Z, grid 22 sampel) | **Apex t=0,371 s — inside window [0,35–0,47] ✓** tanpa retiming; swing: windup (guar d) → arc → recovery (klip memu kondisi gelap/berhenti di pose guard pada ~0,53 s → catatan kecil: recovery keys berakhir lebih awal, hanya visual hold) |
| 11 | Pose "rubbery" pada telegraph (tampak di capture user): kaki/lengket melar seperti rig rusak | Bukan mesh/skinning rusak — state TELEGRAPH masih memutar klip custom lama `soldier/telegraph` yang hanya menganimasikan upper-body; anggota tubuh tanpa track jatuh ke rest pose bawaan mesh (`anime-girl_running_panic` = pose lari yang bakar), terlihat total saat material telegraph oranye menonjolkan siluet | gambar user (soldier oranye rubbery); grep `_change_state` (baris TELEGRAPH masih `soldier/telegraph`) sementara state lain sudah UAL | Tambah mapping `"telegraph": "Punch_Enter"` (windup tell full-body dari pustaka UAL yang sama, CC0) ke `_build_ual_animation_library` + loop + seleksi `_change_state`; ekspektasi Test 8 mengikuti aturan seleksi produksi | `soldier_ual/telegraph` ada di library (pose probe `ual_ready=true`); capture `screenshot_phase_2_8_soldier_telegraph.png` = pose windup wajar (lengan terkuk, tubuh terpuntir); suite 2.2 10/10, 2.6 21/21, 2.8 6/6, 2.4 22/22, 2.5 15/15 |

---

## 2. Status Kinerja (§8 — tanpa regresi)

Re-run `tests/compare_phase_2_7.gd` setelah semua perubahan (attribusi: instrument
`--disable-render-loop` + `RenderingServer.force_draw`; GPU render timing vs
end-to-end frame time dipisah di tabulasi):

| Station | baseline (ms) | optimized (ms) | Δ time | draw calls baseline→optimized |
|---|---|---|---|---|
| low_density | 4,06 | 4,05 | +0,1% (paritas) | 70 → 70 |
| entry | 14,96 | 13,12 | **−12,3%** | 351 → 289 |
| dense_buildings | 15,00 | 13,58 | **−9,5%** | 250,9 → 244,9 |
| combat_active | 15,52 | 14,48 | **−6,7%** | 205 → 198 |

- Hasil menang konsisten dengan arah Phase 2.7 (optimized lebih cepat di semua station; di 2.7: −9,1% / −6,5% / −4,3%).
- **Catatan kejujuran**: median absolut sesi ini ~13–15 ms vs laporan 2.7 (~10,4 ms entry/dense). Kondisi sesi berbeda (banyak sesi windowed beruntun; clock/thermal). Konklusi "tanpa regresi" didasarkan pada A/B in-session + arah delta yang konsisten. Kalau diperlukan, ulangi benchmark pada kondisi bersih & dingin untuk memverifikasi absolut.

---

## 3. Bukti Sampling World-Space Retargeted Soldier (m, ground = y 0)

| Klip | pelvis_y | head | hands | feet | Interpretasi |
|---|---|---|---|---|---|
| idle | 1,10–1,11 | 1,75 | 1,23–1,24 | 0,11/0,19 | berdiri, tangan dekat pinggul ✓ |
| walk | 1,11↔1,17 | 1,75 | bergantian 1,21–1,32 | 0,17↔0,43 | melangkah, kaki bergantian mengangkat ✓ |
| sprint | 1,09–1,15 | 1,63–1,67 | 1,30–1,47 | 0,25–0,60 | condong depan, kaki angkat dramatis ✓ |
| attack | 0,94→0,72→0,97 | 1,68–1,72 | apex 1,74 | | krouch + angkat senjata ✓ |
| hit | 1,09–1,11 | 1,72–1,75 | 1,20–1,31 | | lag kecil ✓ |
| death | 1,11→0,82→0,00 | 1,76→1,70→1,25–1,29 | | 0,10/0,11 flat | collapse ke tanah; **catatan: kepala masih ~1,25 m di atas pelvis pada akhir klip** (torso tidak sepenuh horizontal) — lihat §5 catatan |

---

## 4. Status Animasi Protagonis (§5) — jujur

- **Capture terskrip** (`tests/capture_phase_2_8_player_states.gd` + tight follow-up): idle, walk, sprint, dodge, combo attack1-3 — stamina nyata terpakai (dodge 100→75, attack 100→88) membuktikan state sebenarnya berjalan, bukan hanya HUD.
- **Hasil**: walk terbaca melangkah, sprint condong depan dengan kaki terangkat ✓; attack1_mid menunjukkan katana terhunus dalam ayunan diagnonal ✓.
- **Limitasi pengambilan bukti**: (a) capture menggunakan kamera dev sendiri, bukan kamera gameplay (framing/format beda); (b) beberapa frame terlambat menangkap pose (combo 2/3 berakhir saat capture — state habis, HUD tetap benar); (c) property introspeksi `is_attacking` error di konteks probe (`Invalid access`) — tidak memengaruhi game, hanya logging; (d) **tidak ada keyboard/mouse manual dilakukan oleh agent** — penilaian estetika ("naturla") menunggu checklist user §6.
- Tidak ada sine-wave hack; retarget runtime Quaternius generik **tetap dimatikan** (`player_animations.tres` tetap otoritatif; item BoneMap 211-bone di TASKS tetap terbuka).

---

## 5. Keputusan & catatan desain terbuka

1. **Root statis sengaja tidak digerakkan.** `ALIGN` hanya memetakan ROTASI. Rotasi root yang dipasang pada rootJoint akan memutar seluruh pohon posisi (pelvis jatuh ke −0,23 m); karena rest `RL_BoneRoot(−90°) × Hip_99(+90°)` saling meniadakan, invarian berlaku dari pinggul ke atas tanpa menyentuh root (bukti: residual root 100° inert; semua chain turunannya 0–1,65°).
2. **Waist statis ikut didorong.** `DEF-spine.001` → `CC_Base_Waist_98` tanpa track di klip UAL: dilakukan sampling global per sampel (bukan rest) agar invarian tutup.
3. **Recovery klip attack berakhir awal (~0,53 s dari 0,65 s)** — pose membeku di guard sebagai hold. Tidak dianggap defect gate (strike window penuh; window damage aman). Bisa dipoles saat masuk fase konten.
4. **Kepala di akhir klip death belum terlentang sempurna** (1,25 m di atas pelvis di tanah). Chain atasnya invarian; bisa jadi bentuk asli Death01 (badan rebah agak miring). Daftar di "Open Questions" untuk pola kameranya, bukan gate blocker.
5. `.gd.uid` pada semua script baru di-generate lewat scan editor headless (`--import`); tidak ada file produksi yang dihapus.

---

## 6. Checklist playtest manual untuk user (final sign-off visual)

Di lingkungan normal Windows 1152×648 / 1920×1080 (bukan headless/capture):

1. **Protagonis**: berdiri idle 30 s (apakah terhidup natural tanpa jitter?), berjalan W, sprint W+Shift, sudut kiri-kanan, jump+landing, dodge Ctrl berulang, combo LMB 3 hit, guard RMB, periksa jahitan antar state (burst? kaki melekat tanah?).
2. **Soldier**: biarkan Solder mengejar, lihat gedekan telegraph (material oranye) memadai?, ayunan terlihat saat HP saya berkurang (apex di tengah ayunan), recovery, stagger, death collapse.
3. **HUD**: baca HP/stamina/kompas/skill panel di 3 resolusi; pastikan tidak ada panel `@PanelContainer@N` nakal,uckah gradien halus.
4. **Kontrol**: MMB lock-on beserta pengulangan pengambilan/lepaskan, Tab/wheel siklus target, E/Q skill HUD & qeje, F checkpoint.
5. **Secondary motion**: rambut/ekor/telinga/baju saat sprint & hard turn; tak ada chain kaku yang menonjol aneh.
6. **Performa**: rasakan tetap ±60 FPS di 1152×648 pada Intel UHD 620 pada tiga situasi (entry, area dense, combat).

---

## 7. Status Suite (akhir fase)

- test_phase_2_1 14/14 · test_phase_2_2 **10/10** (dibangkitkan dari 2 fail legacy dengan perbaikan ekspektasi) · test_phase_2_3 13/13 · test_phase_2_4_presentation 22/22 · test_phase_2_5_runtime 15/15 · test_phase_2_6_animation_gate 21/21 · test_phase_2_7_secondary_motion 24/24 · test_phase_2_8_integration 6/6 (baru) · test_phase_1_x: 1.1-1.5/1.7 hijau; **1_6 (3 fail) & 1_6_1 (1 fail) tetap merah** = regresi legacy terkenal, tidak melebar, tidak "dihijaukan".
- `git diff --check`: hanya peringatan CRLF lama pada file tracked; tidak ada whitespace/conflict error baru.
- Bukti visual: 7× `screenshot_phase_2_8_soldier_*.png` (termasuk telegraph), 9× `screenshot_phase_2_8_player_*.png`, 3 resolusi HUD, 4 skill, lock-on, kompas, checkpoint.
- Bukti probe: `.godot/phase_2_8/{soldier_pose.txt,spring_audit.txt,layer_diff.txt,rotation_diff.txt,strike_window.txt}` + `compare.json` (dipakai, tidak di-commit).

## 8. Sisa kerja terbuka (bukan defect gate)

- BoneMap retarget 211-bone protag (TASKS item — masih `[ ]`).
- Playtest manual user (§6) & final visual sign-off.
- Recovery keys klip attack bisa ditambah到最后 0,12 s agar tidak hold; pilih bila sempat.
- Poles dop akhir Death01 (torso lebih terlentang) → Phase konten berikutnya.
