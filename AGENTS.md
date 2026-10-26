# AGENTS.md

Panduan kerja AI agent untuk **VEILBOUND: Crown of the Shattered Aether**.
Tidak ada README: mulai dari sini, lalu `TECH_SPEC.md`, `TASKS.md`, `GDD.md`, `PRD.md`, `AI_ASSET_LOG.md`.

## 0. Fakta repo yang mudah salah diasumsikan

- Engine **Godot 4.7.2**, renderer **Compatibility (OpenGL 3.3)** sesuai `project.godot`. Klaim "Forward+" di `GDD.md` dan dokumen lama sudah usang.
- Target performa nyata: **60 FPS @1152×648 di Intel UHD 620 / 8 GB** (baseline terukur 60.05 avg, 55.62 min), bukan RTX 3060. Hindari efek/post-process berat.
- Deadline vertical slice: **21 November 2026**, Windows, scope kecil. Fitur baru yang tidak menambah kualitas slice ditolak.
- **Hampir seluruh repo belum di-track git**: baseline commit hanya 21 file, sementara kode/aset produksi berstatus untracked. Jangan pernah `git clean`, `git reset --hard`, atau `git checkout .`.
- File `*.gd.uid` (Godot 4.7) harus dipertahankan; jangan hapus/di-generate ulang manual.
- `TASKS.md` adalah tracker aktif (checkbox Phase 2.3–2.6 terbaru), tetapi bagian **Phase 0 dan Phase 3 masih sisa era Unreal** (install UE5, World Partition, Nanite, HLOD, prompt C++). Abaikan itu; `TASKS (1).md` adalah salinan lama versi Godot. Jangan port item Unreal.
- `PRD (1).md` duplikat lama → pakai `PRD.md`.

## 1. Perintah (Godot TIDAK ada di PATH)

```powershell
$godot = 'C:\Users\wired\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'

# Cek project load tanpa error
& $godot --headless --path E:\gamefurr --quit

# Satu suite uji (script `extends SceneTree`; exit code != 0 bila ada yang gagal)
& $godot --headless --path E:\gamefurr --script res://tests/test_phase_2_6_animation_gate.gd

# Semua suite assertion
Get-ChildItem E:\gamefurr\tests -Filter 'test_phase_*.gd' | ForEach-Object {
  & $godot --headless --path E:\gamefurr --script ('res://tests/' + $_.Name)
}

# Capture screenshot: butuh window/GPU nyata, TIDAK bisa --headless.
# Script menulis PNG ke root res:// (dan file .import baru).
& $godot --path E:\gamefurr --script res://tests/capture_phase_2_6_animation_frames.gd
```

- **Tidak ada GUT** (`addons/` kosong) dan **tidak ada `export_presets.cfg`**. Perintah GUT dan `--export-release` dari dokumen lama pasti gagal; build Windows belum pernah diverifikasi.
- Headless mencetak `Failed to read the root certificate store`; itu error host, bukan kegagalan project.

## 2. Test yang ada

- Hanya `tests/test_phase_*.gd` yang berisi assertion (`[PASS]`/`[FAIL]`, ringkasan `passed=`/`Total=`, `quit(0/1)`).
- `tests/inspect_*.gd` dan `diagnose_*.gd` adalah probe sekali pakai (cetak info, tanpa assertion). `tests/capture_*.gd` menulis screenshot ke root `res://`.
- Suite meng-instantiates `res://main.tscn` yang asli, jadi nama node dan path di `main.tscn`/HUD adalah kontrak test. Jangan rename node produksi tanpa memperbarui suite.
- Status saat ini: `2_3` 13/13, `2_4_presentation` 22/22, `2_5_runtime` 15/15, `2_6_animation_gate` 21/21 hijau. Suite lama `1_6` (3 gagal), `1_6_1` (1), `2_2` (1) sudah merah di working tree: anggap regresi lama, jangan "dihijaukan" dengan melemahkan test.
- PNG di root (`screenshot_phase_*.png`) adalah bukti yang dirujuk laporan `PHASE_2_*.md`; regenerasi akan menimpanya.

## 3. Arsitektur yang sebenarnya

- `res://main.tscn` adalah satu-satunya scene produksi: `NavigationRegion3D` (collision lantai + `DarkRuinsEnvironment`), `LanternCheckpoint`, `Player`, 4 dummy lock-on, `SoldierEnemy`, `CombatHUD`.
- Player = `PlayerController` (`CharacterBody3D`) + component node: `HealthComponent`, `StaminaComponent`, `DodgeComponent`, `GuardComponent`, `MeleeAttackComponent`, `LockOnComponent`, `PlayerSkillComponent`, `CameraImpulseComponent`, `AudioFeedbackManager`, `CombatFeedbackCoordinator`. Visual: `VisualRoot/PlayerVisualDriver` → `PlayerCharacterModel` (AnimationPlayer, bone attachment katana, spring rambut/bust).
- Soldier = state machine (`Patrol/Chase/Telegraph/Attack/Recovery/Stagger/Dead`) + `NavigationAgent3D`; timing di konstanta atas `soldier_enemy.gd` (`ATTACK_ACTIVE_START`, `ATTACK_ACTIVE_DURATION`, durasi telegraph/recovery).
- **Tidak ada autoload/singleton.** `Game`, `EventBus`, `SaveSystem`, `Audio` di `TECH_SPEC.md` §2 belum diimplementasi — jangan memanggilnya.
- Combat memakai **timer di `_physics_process` komponen**, bukan call-method track `AnimationPlayer`. Jangan migrasi ke anim track tanpa diminta; perubahan timing harus disertai suite terkait.
- Balance masih hardcoded di script: `MeleeAttackComponent.attacks` (combo 3 hit), `PlayerSkillComponent._default_skills()` (4 skill), konstanta `SoldierEnemy`. Hanya ada 3 `.tres` (2 animation library + navmesh). Jangan memulai refactor resource-driven di tengah deadline.
- Hit detection: `direct_space_state.intersect_shape` dengan mask **4** (enemy) + overlap `Area3D`; line-of-sight ray mask **1**. Layer literal: 1 world, 2 player, 4 enemy.
- Retarget runtime generic Quaternius → skeleton fox 211-bone **sengaja dimatikan**; `characters/player/visual/player_animations.tres` otoritatif. Soldier memakai retarget runtime dan klip serangnya sudah di-retime ke 0.65 s — mengganti panjang klip tanpa menyesuaikan konstanta akan merusak gate animasi.
- Input map aktual (`project.godot`, tabel di `TECH_SPEC.md` §8 usang): WASD, Space jump, Shift sprint, **Ctrl dodge**, LMB attack, RMB guard, MMB lock-on, E skill next, Q skill cast, F interact, Tab/wheel target, wheel zoom, H/J debug damage. Mouse wheel terikat ganda (zoom + target).
- `tools/animation_preview.tscn` hanya alat dev (Tab ganti karakter, 1–9 pilih klip), bukan scene produksi.

## 4. Aturan konten & aset

- Semua nama, lore, dan aset **original**; jangan meniru nama/karakter/aset Elden Ring atau IP lain. Identitas: anime dark fantasy, dunia dan protagonis yang khas, bukan medieval generic.
- Setiap aset baru (AI maupun free) wajib dicatat di `AI_ASSET_LOG.md` (tool, versi, prompt, seed, lisensi, status cleanup); simpan file lisensi di folder aset. Format 3D `.glb`, naming `type_name_variant`.
- Jangan ubah `GDD.md`/`PRD.md` tanpa persetujuan; usulkan perubahannya.
- Baca `PHASE_2_3_REPORT.md`, `PHASE_2_4_REWORK_DESIGN.md`, `PHASE_2_5_ANIMATION_AUDIT.md`, `PHASE_2_6_ANIMATION_AUDIT.md` sebelum menyentuh environment, HUD, atau animasi — di situ ada defect register dan keputusan yang sudah terbukti.

## 5. Cara kerja

1. Ikuti urutan phase di `TASKS.md`; jangan bikin region/boss/konten baru sebelum gate combat lolos.
2. Satu task = satu perubahan kecil yang bisa diuji; jangan refactor besar atau ganti arsitektur tanpa diminta.
3. Ragu di luar scope PRD → tulis di "Open Questions", jangan implementasi.
4. Baca isi `.tscn`/`.tres` besar sebelum menimpa; jangan hapus file yang tidak kamu buat.
5. GDScript typed, `snake_case` untuk file/fungsi, `PascalCase` untuk `class_name`; komunikasi antar node lewat signal.
6. Setelah selesai: centang item di `TASKS.md`, update `AI_ASSET_LOG.md` bila ada aset, dan jelaskan perubahan.

## 6. Definition of Done

- Load project bersih (perintah §1) tanpa error/warning baru.
- Suite phase yang relevan hijau; regresi lama tidak bertambah.
- Tetap ~60 FPS di 1152×648 pada Intel UHD 620.
- Jangan commit `.godot/`, `build/`, screenshot capture baru, atau secret/API key.
