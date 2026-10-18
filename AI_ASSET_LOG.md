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
| A-0001 | | | | | | | | RAW | | |
| A-0002 | | | | | | | | RAW | | |

## 6. Template Entri Detail (copy per aset penting)

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
