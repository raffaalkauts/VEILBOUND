# Phase 2.3 — Environment Design & Playable Vertical Slice

## Hasil

Arena graybox diganti dengan satu area kecil yang terhubung: entry court di elevasi bawah, tangga batu menuju courtyard, encounter court dengan pilar dan rubble sebagai obstacle, gerbang sebagai landmark, serta Aether Lantern sebagai checkpoint. Soldier tetap mengejar dan menyerang melalui navmesh yang sudah dibake ulang.

Prop lingkungan memakai model KayKit yang sudah ada di workspace. [KayKit Dungeon Pack](https://kaylousberg.itch.io/kaykit-dungeon-pack) dan [KayKit Halloween Bits](https://kaylousberg.itch.io/halloween-bits) mencantumkan unduhan gratis, format glTF yang kompatibel dengan Godot, dan lisensi CC0 1.0. Pembuat, sumber, dan subset model yang dipakai tercatat di [AI_ASSET_LOG.md](AI_ASSET_LOG.md).

Collision floor/ramp memakai shape sederhana; collision prop dibuat dari mesh model. NavigationMesh final memiliki 128 polygon. Checkpoint mengisi ulang HP dan stamina saat diaktifkan; setelah mati, pemain kembali ke RespawnPoint dengan state guard/dodge dan velocity dibersihkan.

## Screenshot hasil render Compatibility

- [Overview](screenshot_phase_2_3_vertical_slice_overview.png)
- [Entry dan tangga](screenshot_phase_2_3_vertical_slice_approach.png)
- [Checkpoint](screenshot_phase_2_3_vertical_slice_checkpoint.png)
- [Gerbang](screenshot_phase_2_3_vertical_slice_gate.png)
- [Encounter combat](screenshot_phase_2_3_vertical_slice_combat.png)

Capture dibuat dari scene game yang dirender pada 1152×648.

## Pengukuran performa

| Metrik | Hasil |
|---|---:|
| Engine / renderer | Godot 4.7.2 / Compatibility (OpenGL 3.3) |
| Perangkat | Intel Core i5-8350U, UHD Graphics 620 |
| RAM terdeteksi | 7.92 GB |
| Sampel | 180 rendered frames, sekitar 3 detik |
| FPS rata-rata | 60.05 |
| FPS minimum / maksimum | 55.62 / 63.31 |
| Waktu frame rata-rata | 16.66 ms |
| Waktu frame maksimum | 17.98 ms |
| Render objects / draw calls | 250 / 152 |

Rata-rata mencapai sekitar 60 FPS pada perangkat target. Frame minimum sempat turun ke 55.62 FPS, jadi frame pacing belum konsisten 60 FPS pada setiap frame. Log mentah ada di `.godot/perf_capture.log`.

## Validasi

Semua 11 suite script fase 1.1–2.3 lulus: **167/167 test**, termasuk traversal dari entry sampai encounter court, detour obstacle soldier, combat, lock-on, guard, dodge, dan checkpoint respawn. Project juga berhasil dibuka dengan `--headless --path . --quit` tanpa missing resource.

Workspace ini tidak memiliki GUT (`addons/gut/gut_cmdln.gd`) maupun `export_presets.cfg`; validasi memakai suite script yang tersedia, dan export build belum diverifikasi. Headless Godot mencetak error host `Failed to read the root certificate store`; error ini tidak menghentikan project load atau suite.
