# AGENTS.md
Panduan untuk AI coding agent (Claude Code, dll.) yang mengerjakan **VEILBOUND**.
Baca file ini + `GDD.md`, `PRD.md`, `TECH_SPEC.md`, `TASKS.md` sebelum mulai kerja.

## 1. Proyek Singkat
3D action RPG souls-like, open world, gaya anime cel-shaded. Engine: **Godot 4.x**. Platform awal: PC (Steam).
Semua nama, lore, dan aset harus **ORIGINAL**. Jangan pakai nama/karakter/aset dari Elden Ring atau IP lain.

## 2. Aturan Kerja
1. Kerjakan task **sesuai urutan phase di `TASKS.md`**. Jangan bikin konten (region, boss baru) sebelum gate combat prototype lolos.
2. Satu task = satu perubahan kecil yang bisa dites. Jangan refactor besar tanpa diminta.
3. Jangan tambah fitur di luar scope PRD. Kalau ragu, tulis di bagian "Open Questions" bukan langsung implement.
4. Setelah selesai, centang task di `TASKS.md` dan jelaskan apa yang diubah.
5. Jangan hapus atau timpa file `.tscn`/`.tres` besar tanpa membaca isinya dulu.

## 3. Tech Stack
| Area | Pilihan |
|------|---------|
| Engine | Godot 4.x (Forward+ renderer) |
| Bahasa utama | GDScript (typed). C# / GDExtension hanya untuk bottleneck yang terbukti lewat profiling |
| Testing | GUT (Godot Unit Test) |
| AI/BT | State machine sendiri; addon LimboAI bila perlu behavior tree |
| Terrain | Terrain3D (addon) atau heightmap mesh |
| Version control | Git + Git LFS (aset binary: `.glb`, `.png`, `.ogg`, `.wav`) |

## 4. Struktur Folder
```
res://
├─ characters/    # player, npc, enemy, boss (scene + script + resource)
├─ combat/        # components: health, stamina, hitbox, hurtbox, lock-on
├─ world/         # zona/region scene, lantern, interactables
├─ ui/            # HUD, menu, boss bar
├─ audio/         # bgm, sfx
├─ vfx/           # particles, shader, impact frame
├─ data/          # custom Resource (.tres): weapons, enemies, boss moves, items
├─ shaders/       # .gdshader (toon, outline, dissolve)
├─ addons/
└─ tests/         # GUT tests
```

## 5. Konvensi Kode (GDScript)
- Selalu **static typing**: `var hp: int = 100`, `func take_damage(amount: float) -> void:`
- `snake_case` untuk variabel/fungsi/file, `PascalCase` untuk `class_name` dan nama node.
- Komunikasi antar node pakai **signal** (call down, signal up). Hindari `get_node("../../..")`.
- Logika gameplay dipecah jadi **component node** (HealthComponent, StaminaComponent) bukan satu script raksasa.
- Data (damage, cooldown, stat) di **custom Resource (.tres)**, jangan hardcode di script.
- Hindari logic berat di `_process`; gunakan `_physics_process` untuk gerak/combat.
- Tidak ada magic number: pakai `const` atau Resource.
- Komentar singkat hanya untuk "kenapa", bukan "apa".

## 6. Aturan Combat
- Combat berbasis **frame data**: startup, active, recovery, i-frame; semua dari `AnimationPlayer` call-method track + Resource.
- Hit detection pakai `Area3D`/`ShapeCast3D` (Hitbox vs Hurtbox) dengan layer/mask terpisah.
- Boss move wajib punya **telegraph** jelas (visual atau audio) sebelum damage aktif.
- Tidak ada damage yang tidak bisa dihindari secara fair.
- Setiap perubahan balance masuk ke Resource, bukan script.

## 7. Aturan Aset AI
- Setiap aset hasil AI **wajib dicatat** di `AI_ASSET_LOG.md` (tool, versi, prompt, seed, lisensi, status cleanup).
- Jangan generate dengan prompt yang menyebut seniman hidup atau IP spesifik.
- Format 3D: `.glb`. Hero asset wajib retopo + cleanup manual sebelum masuk `res://`.
- Naming: `type_name_variant` (contoh: `char_sera_cloak_red.glb`).

## 8. Perintah Umum
```bash
# Cek project load tanpa error
godot --headless --path . --quit

# Jalankan test (GUT)
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

# Export release (preset "Windows Desktop" harus dibuat dulu di editor)
godot --headless --path . --export-release "Windows Desktop" build/veilbound.exe
```

## 9. Definition of Done
- Tidak ada error/warning baru di output Godot
- Test GUT relevan lulus
- Jalan di build export, bukan hanya di editor
- Target 60 FPS di spec target (RTX 3060 / 16GB RAM)
- `TASKS.md` dan `AI_ASSET_LOG.md` terupdate

## 10. Jangan Lakukan
- Jangan commit file `.godot/`, `build/`, atau secret/API key
- Jangan ubah GDD/PRD tanpa persetujuan; usulkan perubahan di jawaban
- Jangan pakai library/addon baru tanpa mencatat alasan & lisensinya di `TECH_SPEC.md`
- Jangan tambah dependency C# jika GDScript cukup
