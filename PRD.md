# PRODUCT REQUIREMENTS DOCUMENT (PRD)
## VEILBOUND: Crown of the Shattered Aether

| Field | Value |
|-------|-------|
| Version | 0.1 (Draft) |
| Genre | Open-world Action RPG, souls-like |
| Platform | PC (Steam) → Console later |
| Engine | Unreal Engine 5 |
| Art style | Anime cel-shaded 3D |
| Status | Pre-production |

---

## 1. Problem & Opportunity

**Problem:** Gamer yang suka Elden Ring/souls-like tapi suka estetika anime belum punya pilihan open-world yang kuat. Genre anime-RPG didominasi gacha/live-service.

**Opportunity:** Game **premium, single-player-first, tanpa gacha**, dengan combat berat + visual anime = niche besar yang underserved.

## 2. Goals & Non-Goals

### Goals
- G1: Combat souls-like yang adil, responsif, dan stylish.
- G2: Open world yang mendorong eksplorasi tanpa hand-holding.
- G3: Visual anime konsisten & memukau.
- G4: Pipeline produksi berbasis AI yang menekan biaya & waktu.
- G5: Rilis Early Access/Demo lalu 1.0.

### Non-Goals (v1.0)
- Tidak ada gacha / pay-to-win.
- Tidak ada MMO.
- Tidak ada PvP ranked (invasi opsional saja).
- Tidak menyalin nama/lore/aset game manapun.

## 3. Target Audience

| Segmen | Deskripsi |
|--------|-----------|
| Primary | 18–32 th, pemain souls-like & fans anime |
| Secondary | Pemain Genshin/Wuthering Waves yang mau game "hardcore" |
| Tertiary | Streamer/speedrunner/modder |

## 4. Scope Tiers

| Tier | Isi | Tujuan |
|------|-----|--------|
| **T0: Prototype** | 1 karakter, 1 arena, 1 boss, combat core | Validasi "feel" |
| **T1: Vertical Slice** | 1 region, 1 legacy dungeon, 3 boss, 5 senjata, UI dasar | Demo/pitch/publisher |
| **T2: Early Access** | 3 region, 3 dungeon, 12 boss, 10 senjata | Revenue & feedback |
| **T3: 1.0** | 8 region, 6+ dungeon, 50+ boss, 18 senjata, 4 ending | Full release |

## 5. Functional Requirements

Prioritas: **P0** wajib, **P1** penting, **P2** nice-to-have.

### 5.1 Combat
| ID | Requirement | Pri |
|----|-------------|-----|
| C-01 | Stamina system (attack/dodge/block/sprint) | P0 |
| C-02 | Light/Heavy attack + combo chain | P0 |
| C-03 | Dodge roll dengan i-frames | P0 |
| C-04 | Lock-on targeting (multi-target switch) | P0 |
| C-05 | Hit detection (weapon trace, hitstop, camera shake) | P0 |
| C-06 | Parry + Riposte | P1 |
| C-07 | Posture/Break + Critical Strike | P1 |
| C-08 | Resonance Arts (skill per senjata) | P1 |
| C-09 | Magic (Aether Weaving) | P1 |
| C-10 | Perfect Dodge slow-mo "Flash Step" | P2 |

### 5.2 Character & Progression
| ID | Requirement | Pri |
|----|-------------|-----|
| P-01 | Character creator anime | P1 |
| P-02 | 8 stat + level up | P0 |
| P-03 | Inventory & equipment (weapon, armor, talisman) | P0 |
| P-04 | Weapon upgrade (+1~+25) | P1 |
| P-05 | Aether Motes drop-on-death & recovery | P0 |
| P-06 | Echo Familiar summon | P2 |

### 5.3 World & Exploration
| ID | Requirement | Pri |
|----|-------------|-----|
| W-01 | World Partition open world streaming | P0 |
| W-02 | Lantern checkpoint + fast travel | P0 |
| W-03 | Windstrider mount (traversal) | P1 |
| W-04 | Day/night + weather | P2 |
| W-05 | Hidden areas & secrets | P1 |
| W-06 | Map system dengan fog-of-war | P1 |

### 5.4 AI (Enemy)
| ID | Requirement | Pri |
|----|-------------|-----|
| A-01 | Enemy BT: patrol, detect, chase, attack, retreat | P0 |
| A-02 | Boss AI: phase, move selection, anti-spam | P0 |
| A-03 | Group AI (flank, aggro share) | P1 |

### 5.5 Narrative & Quest
| ID | Requirement | Pri |
|----|-------------|-----|
| N-01 | Dialog system (branching ringan) | P0 |
| N-02 | NPC questline (6+ main NPC) | P1 |
| N-03 | Item description lore | P0 |
| N-04 | 4 ending + flag tracker | P1 |

### 5.6 UI/UX
| ID | Requirement | Pri |
|----|-------------|-----|
| U-01 | HUD (HP, FP, stamina, flask) | P0 |
| U-02 | Menu inventory/equipment/stat | P0 |
| U-03 | Boss health bar + name card | P0 |
| U-04 | Settings (graphics, audio, controls, accessibility) | P0 |
| U-05 | Controller + KBM support | P0 |

### 5.7 Online (Opsional)
| ID | Requirement | Pri |
|----|-------------|-----|
| O-01 | Co-op summon (Echo Link) | P2 |
| O-02 | Message/ghost system | P2 |

## 6. Non-Functional Requirements

| Area | Target |
|------|--------|
| Performance | 60 FPS @1080p (RTX 3060 / 16GB RAM) |
| Load time | < 15 dtk fast travel |
| Input latency | < 80 ms |
| Stability | Crash-free session ≥ 99% |
| Install size | ≤ 60 GB |
| Accessibility | Remap, subtitle, colorblind, difficulty aid opsional |
| Localization | EN, ID, JP (subtitle) |

## 7. Art & Audio Requirements

- Art Bible wajib sebelum produksi massal (palette, shape language, toon shader spec).
- Seluruh aset AI melewati: **generate → cleanup → style check → engine integrate**.
- OST minimal: 1 tema utama, 1 per region, 1 per legacy boss.

## 8. AI Usage Policy (Internal)

1. Catat tool, versi, prompt, seed per aset.
2. Hanya tool dengan lisensi komersial jelas.
3. Dilarang meniru seniman/IP spesifik.
4. Disclose AI di halaman Steam.
5. Aset hero (karakter utama, boss besar) wajib polish manual.

## 9. Success Metrics (KPI)

| Metric | Target |
|--------|--------|
| Playtest "combat feel" rating | ≥ 4/5 |
| Demo → wishlist conversion | ≥ 10% |
| Wishlist pre-launch | 50k+ |
| Steam review | ≥ 80% positive |
| D1 retention demo | ≥ 40% |
| Completion rate boss 1 | 60–75% (tantangan fair) |

## 10. Milestones

| Milestone | Durasi (estimasi tim kecil) | Output |
|-----------|-----------------------------|--------|
| M0 Pre-production | 2–3 bln | GDD, Art Bible, tech proto |
| M1 Combat Prototype | 3 bln | T0 |
| M2 Vertical Slice | 6 bln | T1 + trailer |
| M3 Early Access | 12 bln | T2 |
| M4 1.0 Release | 12–18 bln | T3 |

> Total realistis: **3–4 tahun** untuk tim kecil. Solo bisa lebih lama; scope harus dipangkas.

## 11. Team & Resources

| Role | Solo+AI | Tim kecil (5–10) |
|------|---------|------------------|
| Game Designer | ✔ | 1 |
| Programmer | ✔ (AI-assisted) | 2–3 |
| Technical Artist | ✔ | 1 |
| 3D/Concept Artist | AI + cleanup | 2 |
| Animator | AI mocap + polish | 1 |
| Composer/Audio | AI draft | 1 |
| QA/Producer | self | 1 |

## 12. Risks

| Risk | Impact | Mitigasi |
|------|--------|----------|
| Scope creep | Tinggi | Tier-based scope, cut list |
| Combat tidak fun | Tinggi | Prototype & playtest awal |
| AI asset inconsistency | Sedang | LoRA, art bible |
| Isu hukum AI/IP | Tinggi | Konten original, dokumentasi |
| Funding | Tinggi | Demo, Kickstarter, publisher |
| Performance open world | Sedang | Profiling tiap milestone |

## 13. Open Questions
- Single-player only atau co-op di 1.0?
- Budget & pendanaan?
- Target console (PS5/Xbox) atau PC dulu?
- Nama final game & branding?
