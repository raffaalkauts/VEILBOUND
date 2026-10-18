# TECH_SPEC.md
## VEILBOUND: Technical Specification (Godot 4.x)

Status: **Draft v0.1**. Review ulang setelah Combat Prototype (Phase 1).

---

## 1. Keputusan Engine

| Aspek | Keputusan | Alasan |
|-------|-----------|--------|
| Engine | Godot 4.x | Ringan (~100 MB), editor visual 3D, file scene/resource berbentuk teks sehingga mudah diedit AI agent, export ke PC/Steam |
| Bahasa | GDScript (typed) | Iterasi cepat; C#/GDExtension hanya untuk bottleneck hasil profiling |
| Renderer | Forward+ | Kualitas terbaik di PC; toon shader tidak butuh fitur berat |
| Physics | Godot Physics 3D (Jolt opsional) | Cukup untuk karakter + hitbox; Jolt bisa dicoba jika butuh stabilitas lebih |

### Trade-off yang diterima
- Tidak ada World Partition: streaming dunia dibuat manual per zona.
- Ekosistem aset lebih kecil dari Unreal: banyak tooling dibuat sendiri / addon komunitas.
- Console export butuh pihak ketiga (mis. W4 Games). Ditunda setelah PC.

---

## 2. Arsitektur Umum

```
Main (autoload: Game, SaveSystem, Audio, EventBus)
 ├─ WorldManager        → load/unload zona (async)
 ├─ Player (CharacterBody3D)
 │    ├─ StateMachine   (Idle, Move, Dodge, Attack, Block, Parry, Stagger, Dead)
 │    ├─ HealthComponent / StaminaComponent / FocusComponent
 │    ├─ Hurtbox (Area3D)
 │    ├─ WeaponSocket → Weapon (Hitbox Area3D)
 │    ├─ LockOnComponent
 │    └─ AnimationTree + AnimationPlayer
 ├─ CameraRig (SpringArm3D + Camera3D)
 └─ UI (CanvasLayer): HUD, BossBar, Menus
```

### Autoload (Singleton)
| Nama | Tugas |
|------|-------|
| `Game` | State global (pause, mode, difficulty) |
| `EventBus` | Signal global (boss_defeated, player_died, lantern_lit) |
| `SaveSystem` | Simpan/muat progres |
| `Audio` | BGM crossfade, SFX pool |

Prinsip: **call down, signal up**; komponen tidak saling mengenal langsung.

---

## 3. Combat Architecture

### 3.1 Komponen
| Komponen | Tanggung jawab |
|----------|----------------|
| `HealthComponent` | HP, damage, heal, signal `died` |
| `StaminaComponent` | consume/regen (regen delay), signal `depleted` |
| `Hitbox` (Area3D) | Mengirim `HitData` saat aktif |
| `Hurtbox` (Area3D) | Menerima `HitData`, meneruskan ke Health/Posture |
| `PostureComponent` | Akumulasi break → stagger → critical |
| `LockOnComponent` | Cari target di radius, switch target, kamera mengikuti |

### 3.2 Damage Pipeline
```
Weapon Hitbox (aktif via animation track)
   → Hurtbox.area_entered
   → HitData { source, damage, type, posture_damage, knockback, hitstop }
   → Defense check (dodge i-frame? block? parry?)
   → HealthComponent.apply(HitData)
   → Feedback: hitstop, camera shake, VFX, SFX
```

### 3.3 Frame Data
- Fase serangan: **startup → active → recovery** diatur oleh call-method track di `AnimationPlayer`.
- I-frame dodge: flag `invulnerable` di-toggle oleh animation track.
- Input buffering: window 0.15–0.2 detik untuk combo.
- Semua angka (damage, durasi, stamina cost) disimpan di Resource, bukan script.

### 3.4 Physics Layer
| Layer | Nama |
|-------|------|
| 1 | World |
| 2 | Player |
| 3 | Enemy |
| 4 | PlayerHitbox |
| 5 | EnemyHitbox |
| 6 | Hurtbox |
| 7 | Interactable |
| 8 | Projectile |

---

## 4. Data-Driven Design (Custom Resource)

```gdscript
# data/weapon_data.gd
class_name WeaponData extends Resource

@export var display_name: String
@export var base_damage: float = 10.0
@export var stamina_cost_light: float = 12.0
@export var stamina_cost_heavy: float = 25.0
@export var posture_damage: float = 15.0
@export var combo_light: Array[StringName] = []
@export var resonance_art: ResonanceArtData
```

```gdscript
# data/boss_move_data.gd
class_name BossMoveData extends Resource

@export var move_name: StringName
@export var animation: StringName
@export var min_range: float
@export var max_range: float
@export var cooldown: float = 3.0
@export var telegraph_time: float = 0.6
@export var weight: float = 1.0
@export var phase_min: int = 1
```

Sumber: `res://data/*.tres`. Balancing = edit Resource, tanpa menyentuh kode.

---

## 5. Enemy & Boss AI

### Enemy biasa
State machine: `Idle → Patrol → Detect → Chase → Attack → Retreat → Stagger → Dead`
Navigasi: `NavigationAgent3D` + NavigationRegion3D per zona.

### Boss
- State machine fase: `Phase1 → Transition (cinematic) → Phase2`
- **Move selector berbobot** (weight) dengan anti-repeat (maks 2× berturut-turut)
- Telegraph wajib sebelum damage aktif
- Trigger fase berdasarkan HP threshold (default 50%)
- Semua move dari `BossMoveData` Resource

---

## 6. World & Streaming

| Aspek | Pendekatan |
|-------|------------|
| Struktur | Satu scene per zona (`world/zones/hollowmere_01.tscn`) |
| Loading | `ResourceLoader.load_threaded_request` + preload zona tetangga |
| Unload | Free zona jauh berdasarkan jarak player |
| LOD | Visibility Range pada MeshInstance3D |
| Culling | Occlusion culling (baked) + frustum |
| Vegetasi | MultiMeshInstance3D |
| Terrain | Terrain3D addon (evaluasi di Phase 3) |
| Kabut/jarak | Fog + distance fade untuk menyamarkan streaming |

Target awal: zona ±1×1 km, transisi tanpa loading screen via zona tumpang tindih.

---

## 7. Rendering (Anime Cel-Shaded)

### Toon shader (sketsa awal, perlu di-tune)
```glsl
shader_type spatial;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color;
uniform sampler2D ramp : source_color, filter_nearest;

void fragment() {
    ALBEDO = albedo_color.rgb * texture(albedo_tex, UV).rgb;
}

void light() {
    float ndl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
    vec3 band = texture(ramp, vec2(ndl, 0.5)).rgb;
    DIFFUSE_LIGHT += band * LIGHT_COLOR;
}
```

- **Outline**: pass inverted-hull (mesh kedua, cull front) untuk karakter; post-process edge detection untuk environment (opsional).
- **VFX anime**: impact frame (white flash 1–2 frame), speed line (quad shader), smear (mesh stretch), hitstop.
- Rambut/kain: SpringBoneSimulator3D / jiggle bone.

---

## 8. Input

| Aksi | KBM | Gamepad |
|------|-----|---------|
| Move | WASD | Left stick |
| Camera | Mouse | Right stick |
| Light attack | LMB | R1 |
| Heavy attack | Shift+LMB / hold | R2 |
| Dodge | Space | B / Circle |
| Block / Parry | RMB | L1 |
| Lock-on | Q / MMB | R3 |
| Use Vial | R | Y / Triangle |
| Interact | E | A / Cross |

Semua aksi lewat **Input Map** (remappable di Settings).

---

## 9. Save System

- Format: JSON di `user://saves/slot_N.json` (versi + checksum)
- Disimpan: stat, inventory, equipment, lantern aktif, boss defeated flag, quest flag, posisi terakhir, waktu main
- Auto-save di lantern, saat boss defeated, dan saat keluar
- `save_version` + migrasi untuk kompatibilitas patch
- Steam Cloud: sinkronkan folder `saves/`

---

## 10. Performance Budget (Target PC Mid-range)

| Metrik | Target |
|--------|--------|
| FPS | 60 @ 1080p (RTX 3060, 16 GB RAM) |
| Draw call | < 2.500 |
| Triangle di layar | < 3 juta |
| Karakter hero | ≤ 60k tris |
| Enemy biasa | ≤ 20k tris |
| Boss | ≤ 80k tris |
| Textur | 2K hero, 1K environment (compress VRAM) |
| Frame time combat | < 16.6 ms stabil |
| Memori | < 6 GB |

Profiling: Godot Profiler + Monitors + Visual Profiler, cek tiap akhir milestone.

---

## 11. Networking (Fase Akhir, Opsional)

- Co-op "Echo Link": High-level Multiplayer API (ENet) atau GodotSteam P2P
- Host-authoritative untuk damage dan state boss
- Tidak diprioritaskan sebelum T2 (Early Access)

---

## 12. Testing & Build

| Aspek | Tool |
|-------|------|
| Unit test | GUT |
| Playtest | Build export + feedback form |
| Profiling | Godot built-in profiler |
| CI | GitHub Actions + `godot --headless --export-release` |
| Export | Windows (utama), Linux (opsional) |
| Distribusi | Steam (Steamworks via GodotSteam) |

---

## 13. Addon / Dependency (Dicatat Setiap Tambahan)

| Addon | Fungsi | Lisensi | Status |
|-------|--------|---------|--------|
| GUT | Unit test | MIT | Direncanakan |
| Terrain3D | Terrain besar | MIT | Evaluasi |
| LimboAI | Behavior tree | MIT | Evaluasi |
| GodotSteam | Steam integration | MIT | Fase rilis |
| Phantom Camera | Kamera sinematik | MIT | Evaluasi |

> Cek ulang lisensi dan kompatibilitas versi Godot sebelum dipakai.

---

## 14. Risiko Teknis

| Risiko | Mitigasi |
|--------|----------|
| Streaming dunia tersendat | Prototype zona awal, overlap + fog, profiling dini |
| Animasi combat kaku (AI mocap) | Polish manual, pakai Cascadeur |
| Toon shader tidak konsisten di semua material | Satu master shader + instance |
| Netcode kompleks | Tunda ke akhir, desain single-player dulu |
| Ketergantungan addon yang tidak terawat | Pilih yang aktif, vendor ke repo bila perlu |
