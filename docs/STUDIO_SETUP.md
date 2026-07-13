# Cara Masukin Jejak Nusantara ke Roblox Studio

Repo: https://github.com/zeroknowledge0x/tugas-jejak-nusantara

Ada **2 cara**. Pilih yang gampang buat lo.

---

## Cara A — Paling cepat (download place siap buka)

### 1. Download file place
Buka salah satu:
- https://github.com/zeroknowledge0x/tugas-jejak-nusantara/blob/main/places/JejakNusantara.rbxlx
- Klik **Download raw file** / **Download**

### 2. Buka di Roblox Studio
1. Install / buka **Roblox Studio** (login akun Roblox lo)
2. **File → Open from File...**
3. Pilih `JejakNusantara.rbxlx`
4. Tunggu place load

### 3. Play test
1. Tekan **Play** (tombol ▶ di atas) atau `F5`
2. Buka **View → Output** (wajib, biar kelihatan error)
3. Yang harus kelihatan:
   - **tidak ada** error merah `require` / `Infinite yield`
   - UI HUD muncul (MISI / KEMAMPUAN / PROGRES AREA)
4. Tekan **Stop** (■) kalau sudah

### 4. Publish ke Roblox (biar bisa dimainin dari web)
1. **File → Publish to Roblox As...**
2. Buat experience baru, nama misal `Jejak Nusantara`
3. Setelah publish: **Home → Game Settings → Security**
   - nyalakan **Enable Studio Access to API Services** kalau mau test DataStore
4. **File → Publish to Roblox** lagi
5. Buka game dari website Roblox / Create dashboard

---

## Cara B — Developer mode (Rojo, recommended buat edit kode)

Pakai ini kalau lo mau edit source di VS Code / Cursor terus sync ke Studio.

### 1. Clone repo
```bash
git clone https://github.com/zeroknowledge0x/tugas-jejak-nusantara.git
cd tugas-jejak-nusantara
```

### 2. Install Rojo
- Download Rojo CLI: https://github.com/rojo-rbx/rojo/releases
- Install plugin Rojo di Roblox Studio (Toolbox → cari **Rojo** by rojo-rbx)

### 3. Build place (opsional, sekali)
```bash
# Linux/mac (kalau punya tooling/bin)
tooling/bin/rojo build --output places/JejakNusantara.rbxlx

# atau rojo global
rojo build --output places/JejakNusantara.rbxlx
```

### 4. Live sync
```bash
rojo serve
```
Lalu di Studio: buka place kosong / place dari Cara A → plugin **Rojo → Connect → localhost**

### 5. Struktur yang harus ada di Explorer
```
ReplicatedStorage
  JN
    Modules
      Game
      Types
      Data
      Systems
      UI
      Util
ServerScriptService
  GameServer          ← class: Script
StarterPlayer
  StarterPlayerScripts
    GameClient        ← class: LocalScript
```

---

## Checklist “ini jalan” di Studio

| Cek | OK kalau |
|---|---|
| Output bersih | Tidak error `attempt to index nil` / `not a valid member` |
| GameServer jalan | Ada Script (bukan ModuleScript) di ServerScriptService |
| GameClient jalan | LocalScript di StarterPlayerScripts |
| UI | Label MISI / KEMAMPUAN / PROGRES AREA muncul |
| Play solo | Tidak infinite yield di `WaitForChild("JN")` |

Kalau error `Infinite yield possible on WaitForChild("JN")`:
- berarti tree Rojo belum masuk place — pakai ulang **Cara A** (buka `.rbxlx` yang di folder `places/`)

---

## Catatan penting (baca)

1. **World 3D belum diisi** — ini framework + sistem + UI + logic + content data. Map/building/NPC model 3D masih perlu ditaruh di Studio (Workspace).
2. **Audio/image asset** masih placeholder — ganti ID di Data / AudioManager nanti.
3. Game **logic** (skill, quest, journal, mini-game scoring, ending, dialogue effects) sudah diimplement & di-test headless (45 checks + studio readiness).
4. Verify lokal (kalau edit kode):
   ```bash
   bash tooling/verify.sh
   ```

---

## Troubleshooting cepat

**Error: ModuleScript GameServer never runs**  
→ Pastikan file entry = Script / LocalScript, bukan ModuleScript. Place di `places/` sudah benar.

**UI tidak muncul**  
→ Pastikan Play (bukan Run server-only). Client script cuma jalan di Play.

**DataStore warning**  
→ Normal di Studio tanpa API Services. SaveSystem punya fallback; nyalakan API Services di Game Settings kalau perlu.

**Mau re-build place setelah edit**  
```bash
rojo build --output places/JejakNusantara.rbxlx
```
Lalu buka file itu lagi di Studio.
