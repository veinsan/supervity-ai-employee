# CONTEXT.md — Supervity Autopilot Asia Hackathon 2026
### Track 5 · HR & People Ops — "The Onboarding and Retention AI Employee"

> File ini adalah single source of truth lokal untuk project. Ditaruh di root folder
> (`C:\Users\riant\Downloads\supervity\CONTEXT.md`). Tujuannya supaya siapapun (manusia atau AI
> assistant yang bantu ngoding/ngedesain) yang buka project ini langsung paham: lomba apa, tujuannya
> apa, aturan mainnya apa, data yang dipegang seperti apa, dan apa yang wajib ada di submission.
>
> **Catatan penting:** Discord resmi hackathon adalah *single source of truth* yang sebenarnya. Kalau
> ada pengumuman live di Discord yang beda dari file ini, **Discord yang menang** (dokumen rules resmi
> sendiri bilang begitu). File ini disusun dari: `Autopilot_Asia_Round1_Rules_final.md` (aturan resmi
> Round 1), `ProblemStatement__Onboarding_and_Retention.md` (problem statement Track 5),
> `Autopilot_Asia_Hackathon_Workshop_Day_2.md` (materi workshop Day 2), transkrip Discord
> (`#hackathons-and-events` dan `#hackathon-discussions`), serta isi dataset asli
# (`hr_enterprise_export.xlsx` + 6 CSV turunannya).

---

## 1. Ringkasan Event

**Nama:** Supervity Autopilot Asia Hackathon 2026
**Diselenggarakan oleh:** Supervity AI
**Cakupan:** Terbuka untuk seluruh APAC (Malaysia, India, Singapura, Indonesia, Filipina, Thailand,
Australia, dan negara APAC lain)
**Biaya:** Gratis
**Format:** Dua ronde — sprint online (Round 1) lalu babak final tatap muka di Malaysia (Round 2)
**Peserta terdaftar diperkirakan:** 2.000+ peserta, ~1.000 entrants aktual di Round 1
**Total hadiah:** USD 5.000 (~MYR 19.800), dibagi rata ke 5 track
**Platform build:** Supervity Auto (`https://auto.supervity.ai/marketplace`) — **no-code** di Round 1
**Slogan resmi:** *"Not apps. Not agents. AI Employees run the Autos."*

### Tujuan inti lomba
Peserta membangun **AI Employee** nyata (bukan chatbot, bukan demo prompt, bukan mock) yang:
- benar-benar berjalan di atas sistem nyata (integrasi live),
- menegakkan business logic yang didefinisikan tim sendiri (bukan modul siap pakai),
- menangani exception dengan **eskalasi ke manusia**, bukan crash atau ngarang nilai.

Ini **bukan** kompetisi prompt engineering. Setiap submission wajib "live, working" — dijalankan ulang
oleh juri di atas dataset tersembunyi (hidden/unseen dataset) yang berbeda dari yang dipegang peserta.

### Lima track resmi (fixed, dibagi rata ke tiap tim)
| Track | Nama AI Employee |
|---|---|
| 1. Customer Support | Stalled-Ticket Resolver |
| 2. Finance | Accounts Payable AI Employee |
| 3. Operations | Procurement Exception Commander |
| 4. Sales Intelligence | Inbound Revenue Capture AI Employee |
| 5. **HR & People Ops** ⬅ **track gua** | **Onboarding and Retention AI Employee** |

Track ditentukan/di-assign oleh panitia (bukan pilih sendiri), dikonfirmasi lewat role Discord dan
Google Sheet alokasi track. Track terkunci di deadline submission Round 1.

---

## 2. Timeline Lengkap

| Tanggal | Fase |
|---|---|
| Juni – 9 Juli 2026 | Registrasi & platform enablement |
| 11–12 Juli 2026 | **Pre-Hackathon Workshop (wajib)** — Day 1: intro Supervity Auto & overview track; Day 2: reveal problem statement, judging criteria, live build demo, Q&A |
| 17 Juli 2026, 18:00 MYT | Problem statement resmi dirilis |
| **18 Juli 2026, 12:00 MYT** | **Round 1 dimulai** — sprint online 48 jam |
| 19 Juli 2026, 12:00 MYT | Submission portal Round 1 dibuka |
| **20 Juli 2026, 12:00 MYT** | **Deadline submission Round 1** — tidak ada toleransi keterlambatan sama sekali |
| 20–24 Juli 2026 | Evaluasi & shortlisting oleh juri (evaluator pods + kalibrasi) |
| 25 Juli 2026 | Pengumuman finalis (~120 tim / ~300 peserta, ~20 tim per track dari 5 track) |
| 25 Juli 2026 | Brief Round 2 + starter repo GitHub (NextJS, FastAPI, Docker) dirilis ke tim finalis |
| 26–27 Juli 2026 | Persiapan Round 2 (onboarding, koordinasi travel ke Malaysia) |
| 3–7 Agustus 2026 | **Round 2: "The AI Employee"** — 5 hari remote build sambil berbasis di Malaysia, office hours FDE harian via Discord |
| **8 Agustus 2026** | In-Person Build Day di Asia Pacific University (APU), Kuala Lumpur. **Code freeze pukul 23:59** |
| **9 Agustus 2026** | Finals Day — demo, judging, keynote CEO, pengumuman pemenang, di APU Kuala Lumpur |

**Catatan tanggal saat ini (dari sudut pandang project):** Round 1 sedang/baru saja berlangsung
(18–20 Juli 2026). Prioritas segera adalah **submission Round 1**.

---

## 3. Struktur Ronde

### Round 1 — "The AI Intern" / No-code Auto build
- 48 jam, online, dikerjakan **tanpa kode** langsung di platform Supervity Auto.
- Fokus penilaian: **dekomposisi kerja & koordinasi antar-agent**, bukan kerapihan UI.
- ~1.000 entrants → gate lolos ke ~250 tim.
- Yang diuji: apakah build memakai pola **Orchestrator + Operator Agents** dengan integrasi live yang
  benar, bukan sekadar 1 mega-agent.

### Round 2 — "The AI Employee" / Coded build
- Orkestrasi Round 1 diubah jadi AI Employee yang di-deploy sungguhan: **Auto Manager Console** di
  atas **Auto Runtime**, yang bisa dioperasikan oleh business user (non-teknis).
- Fokus penilaian: **business value** mendominasi skor.
- ~250 finalis → pemenang diumumkan di Finals Day.

---

## 4. Konsep Inti: Orchestrator & Operator Agents (WAJIB DIPAHAMI)

Ini konsep yang menopang seluruh build — dan jadi syarat lolos gate.

### Operator Agent
Satu AI Employee yang mengerjakan **satu pekerjaan end-to-end**. Ambil input → kerjakan satu unit
kerja (contoh: ekstrak & klasifikasi record, screening duplikat, deteksi risiko, draft email) → pakai
integrasi yang dibutuhkan → kembalikan hasil. Satu Operator = satu tanggung jawab.

### Orchestrator
Sebuah Operator yang **menjalankan Operator lain**. Tidak mengerjakan detail sendiri. Tugasnya:
- memutuskan Operator mana yang dipanggil dan urutannya (sequence / paralel / branching kondisional),
- meneruskan context & hasil antar-Operator,
- retry kalau ada yang gagal,
- eskalasi ke manusia di **Auto Workbench** kalau butuh keputusan manusia.

Orchestrator = "manajer" yang mengoordinasi para "pekerja" (Operators).

### Cara memanggil Operator dari Orchestrator
Di dalam workflow Orchestrator, panggil Operator lain dengan menyebut namanya dalam bahasa natural,
misalnya: *"I want to trigger the Risk Screen Operator Agent"* atau *"call the Extraction operator
agent."* Auto akan menjalankan Operator itu sebagai satu step di dalam Orchestrator.

### Urutan build yang benar
1. Bangun tiap Operator sebagai workflow mandiri dulu, pastikan jalan sendiri (input, integrasi, output
   sendiri-sendiri).
2. Baru bangun Orchestrator sebagai workflow yang memanggil Operator-Operator itu, mengumpulkan
   hasilnya, branching, retry, dan eskalasi exception.

**⚠️ JANGAN** bikin satu workflow raksasa yang mengerjakan semuanya sendirian — itu disebut
**"single mega-agent"** dan **otomatis gagal di qualification gate**, tidak peduli sebagus apa hasilnya.

---

## 5. Qualification Gate (Round 1) — Pass/Fail, Dicek Duluan Sebelum Skoring

Submission harus lolos **SEMUA** 4 syarat berikut, baru dinilai. Kalau gagal salah satu → tereliminasi
di triage, tidak masuk penilaian sama sekali.

1. **Bukan single mega-agent.** Orchestrator mengoordinasi **minimal 2 Operator Agent berbeda**,
   menunjukkan perilaku paralel, branching, atau stateful yang sesuai kebutuhan track.
2. **Minimal 3 integrasi live, mencakup minimal 2 kategori**, termasuk **minimal 1 channel** dan
   **minimal 1 system of record**.
3. **Minimal 1 exception nyata dirutekan live ke manusia** di **Auto Workbench** (bukan simulasi).
4. Perilaku yang dibutuhkan domain (paralel/branch/stateful) harus **bisa didemonstrasikan secara live**.

### Kategori integrasi (untuk keperluan gate)
- **System of record**: CRM, ERP/accounting, ticket system, database, **HRIS** ← relevan untuk track HR
- **Channel**: Slack, Discord, Teams, Outlook
- **Document store**: SharePoint, OneDrive, Box, Dropbox
- **Scheduling/meeting**: Zoom
- **Forms**: Typeform
- **Developer systems**: GitHub, GitLab
- **Social**: LinkedIn

**⚠️ Google integrations (Drive, Sheets, Gmail, Calendar) sedang BETA untuk event ini — HINDARI.**
Pakai alternatif: Airtable, Supabase, SharePoint, OneDrive, Box, Dropbox, Outlook.

### Aturan integrasi lainnya
- Tim **bawa sistem sendiri** — tidak connect ke akun Supervity yang di-hosting panitia. Bikin akun
  sendiri di CRM/ticket tool/ERP/database/document store/messaging tool yang dipakai, dan **tim
  memiliki koneksi tersebut**.
- Dua jalur koneksi: **Path 1** — native Auto integration (tercepat untuk sistem umum). **Path 2** —
  code-built API Operator: karena Auto generate kode, Operator Agent bisa panggil API aplikasi apa pun
  langsung, bahkan yang belum ada native integration-nya.
- Screenshot tool **bukan** integrasi. Sistem harus benar-benar berdiri dan koneksinya milik tim sendiri.
- **Auto Policies dan Auto Insights TIDAK WAJIB** dipakai — bahkan sengaja di luar scope sebagai fitur
  siap pakai. Logika kebijakan (threshold, routing rule, eligibility) harus didefinisikan tim sendiri saat
  runtime, lewat kode atau LLM yang mengevaluasi output Operator. Auto Insights sifatnya bonus opsional,
  bukan syarat.

---

## 6. Do's and Don'ts (Resmi dari Rules)

**DO:**
- Bangun Operator terpisah untuk pekerjaan terpisah, dan satu Orchestrator yang mengoordinasi mereka.
- Masukkan data ke sistem nyata (atau ambil dari SharePoint/Drive), baca-tulis lewat integrasi live.
- Rutekan exception genuine ke manusia di Auto Workbench, jangan menebak.
- Tangani data berantakan dan mismatch antar-record — itu memang intinya tugas.
- Jaga logic tetap configurable (threshold, routing, template bisa diubah tanpa ubah kode).

**DON'T:**
- Bikin satu agent raksasa yang mengerjakan semuanya (gagal gate).
- Baca file dataset langsung dan proses di memory tanpa integrasi.
- Hardcode ke baris-baris sample dataset ini — judging pakai data tersembunyi yang berbeda.
- Biarkan AI Employee crash atau mengarang nilai saat field kosong — harus pause & escalate.
- Skip human loop atau memalsukan demo.

---

## 7. Kriteria Penilaian (Rubrik, Skala 1–5 per baris, dibobot ke 100)

| Komponen | Bobot | Yang dinilai |
|---|---|---|
| **Business output** | 40% | Hasil nyata & terkuantifikasi pada outcome metric track (untuk HR: task completion & day-90 retention), dihasilkan **live** di atas data yang belum pernah dilihat tim |
| **Technical architecture** | 20% | Dekomposisi operator-first yang genuine: parallel fan-out/fan-in, branching, retry, escalation |
| **Customizability** | 20% | Business user bisa ubah logic, threshold, routing, template lewat konfigurasi (bukan kode), dan tetap generalize di luar sample data |
| **Demo & console** | 20% | Auto Manager Console bisa dioperasikan business user, dijalankan live end-to-end |

### Bonus (di luar rubrik dasar, additive)
- **Open-source usage** — pemakaian komponen/model/framework open-source yang bermakna, disebutkan
  dan punya peran nyata di build (bukan sekadar import token).
- **Auditability & governance** — full audit trail per case, override path yang berfungsi, business owner
  bisa baca logic tanpa perlu engineer.
- **Self-learning capability** — koreksi/override di Auto Workbench tertangkap dan mengubah perilaku ke
  depan (real correction loop, bukan rulebook statis).
- Menambah Operator/aksi downstream berguna, dan kreativitas genuine di luar brief, akan skor di atas
  build baseline. **Tapi selesaikan masalah inti dulu baru extend.**

### Yang membedakan submission juara
> "A quantified result on the outcome metric, produced live on data you have not seen, that survives an
> enterprise buyer's cross-question." + orkestrasi operator-first genuine + business user bisa
> rekonfigurasi tanpa sentuh kode + console yang benar-benar bisa dioperasikan, didemokan live dengan
> value story yang jelas.

Statistik dari Gartner yang dikutip panitia: **40%+ project agentic AI diprediksi akan dibuang di akhir
2027** karena value tidak jelas dan governance lemah — jadi *"governed autonomy yang jalan"* mengalahkan
*"ambisi yang tidak jalan."*

---

## 8. Submission Round 1 — Wajib Ada

1. Nama tim, anggota tim, email anggota tim, track yang di-assign.
2. **Live Operator URL** dari AI Employee yang sudah selesai.
3. **Link workspace Auto tim** — supaya evaluator bisa verifikasi build itu nyata, bukan cuma dipalsukan
   di video.
4. **Demo video publik, 3–5 menit**, dengan builder **share screen**, wajib mencakup:
   - **Rationale** — kenapa desain Operator ini, masalah apa yang diselesaikan.
   - **Uniqueness** — bagaimana AI Employee ini beda dari chatbot generik, bagaimana ia memakai
     integrasi multi-sistem Supervity.
   - **Live end-to-end execution** — memproses data dari satu sistem eksternal ke sistem lain, tanpa
     halusinasi, **termasuk kasus exception yang ditangani**.
5. **Public LinkedIn post** tentang project, wajib menyebut Supervity dan Autopilot Asia Hackathon.

Submission portal dibuka 19 Juli 12:00 MYT, deadline **20 Juli 12:00 MYT — TIDAK ADA toleransi
keterlambatan sama sekali**. Disarankan submit lebih awal.

---

## 9. Track 5 — HR & People Ops: "The Onboarding and Retention AI Employee"

### Skenario
Persona: **Farah**, People Ops specialist. Sekitar **1/5 (20%) hire baru keluar dalam 90 hari pertama**.
Tanda bahaya sudah ada di data tapi **tidak pernah dirakit lintas sistem** (HR, IT, payroll): akses hari
pertama yang belum dikasih (missing day-one access), dokumen yang macet (stalled document), pulse
engagement yang datar/rendah (flat pulse).

### Outcome metric resmi
**Task completion & day-90 retention.**

### Yang harus dibangun
AI Employee yang menjalankan **program 90 hari yang hidup dan time-aware**:
- mengorkestrasi setiap task onboarding,
- mendeteksi risiko dini (early risk),
- memicu intervensi,
- mengeskalasi hire yang berisiko **sebelum mereka keluar**,
- disclosure sensitif (mis. masalah kesehatan, keluhan terhadap rekan kerja) harus dirutekan secara
  **konfidensial** — TIDAK BOLEH masuk ke laporan kohort umum.

### Contoh alur (bukan wajib diikuti persis — hanya ilustrasi)
`New hire (Day 1–90)` → **Orchestrator** → cabang: `Pulse & cadence` → `On track?` → jika ya:
`Provision & tasks` → `Log & continue`; jika ada masalah: `Detect risk` → `Human review`.

Tim bebas menambah/mengurangi Operator, mengubah cara kerja dan logikanya, membuat alur lebih
optimal, selama menangani semua jenis exception. **"Teams differ on the how; judges compare on the
result."**

### Mandatory khusus Round 1 (sama seperti gate umum, ditegaskan ulang di problem statement)
1. **Orchestrator + minimal 2 Operator berbeda**, menunjukkan perilaku paralel/branching/stateful.
2. **Live integrations**: minimal 3, lintas minimal 2 kategori (1 channel + 1 system of record), dengan
   minimal 1 exception live ke manusia.

### Cara kerja dengan data (WAJIB dibaca ulang)
> "The dataset is how you exercise your integrations, not a file to read from."

Dua opsi:
- **Seed** sistem yang di-connect dengan data ini (masukkan record ke CRM/ticket tool/database/Airtable
  base), ATAU
- **Park** di document store (SharePoint/OneDrive/Box/Dropbox), lalu arahkan integrasi ke sana.

Kedua cara: data harus **sampai ke Operator lewat integrasi live**, bukan dibaca langsung dari file di
laptop.

Contoh konkret untuk HR track:
| Kategori | Contoh |
|---|---|
| A way in (channel masuk) | New hire ditambahkan lewat form atau row |
| System of record | Onboarding di-track di Airtable; provisioning task di Jira/Asana |
| Human loop | Slack nudge ke manager; jalur konfidensial untuk sensitive disclosure |

### Do's & Don'ts khusus Track 5
**DO:** Operator terpisah + 1 Orchestrator · data masuk ke sistem nyata / ditarik dari SharePoint-OneDrive
lewat integrasi live · rutekan exception genuine ke Auto Workbench · tangani data berantakan & mismatch
antar record · logic tetap configurable tanpa kode.

**DON'T:** 1 giant single agent · baca file dataset langsung tanpa integrasi · hardcode ke baris sample ini
(judging pakai data segar/berbeda) · crash atau mengarang nilai saat field kosong (harus pause &
escalate) · skip human loop atau fake demo.

### Rubrik penilaian Track 5 (sama strukturnya dengan rubrik umum, dipertegas)
- **Business output (40)** — AI Employee benar-benar mengerjakan tugasnya di atas data yang diberikan,
  hasil benar; hasil terkuantifikasi pada outcome metric (task completion & day-90 retention),
  dihasilkan live.
- **Customizability (20)** — business user bisa ubah logic/threshold/routing/template, atau arahkan ke
  data masuk berbeda, tetap berfungsi tanpa nulis ulang kode.
- **Technical architecture (20)** — cara Operator Agents diorkestrasi: Orchestrator koordinasi mereka,
  meneruskan context bersih, retry saat gagal, eskalasi ke manusia saat butuh keputusan.
- **Demo (20)** — walkthrough live yang jelas di Auto Manager Console, dijalankan end-to-end di atas
  data yang **tidak** disiapkan sebelumnya oleh tim.
- **Bonus** — aksi downstream tambahan yang berguna, lebih banyak Operator, inovasi/kreativitas genuine
  di luar brief.

**Ditegaskan (FAQ resmi problem statement):**
- Tidak perlu keahlian domain HR mendalam — skenario & dataset sudah menyediakan yang dibutuhkan;
  fokus ke workflow dan exception handling, bukan riset HR.
- Single agent **tidak bisa** menyelesaikan track ini — wajib Orchestrator + multi-Operator + minimal 1
  live exception ke manusia di Auto Workbench.
- Judging dijalankan **live di atas dataset terpisah yang tidak pernah dilihat tim**; kadang juri test dengan
  beberapa dataset berbeda. AI Employee harus universal — mampu mencerna data apa pun yang datang,
  memahaminya, dan menangani exception — bukan di-tuning ke baris sample ini.

---

## 10. Seeded Trap Types di Dataset (dari `Field_Dictionary.csv`)

Dataset sengaja mengandung 4 jenis "jebakan" yang harus terdeteksi/tertangani oleh AI Employee:
1. **Missing day-one access** — provisioning terblokir padahal sudah lewat tanggal start.
2. **Stalled compliance doc** — dokumen kepatuhan (compliance) yang macet/tidak diselesaikan.
3. **Disengaged hire** — skor pulse survey rendah, tanda hire mulai tidak engaged.
4. **Sensitive disclosure in a pulse** — komentar sensitif (mis. isu kesehatan, isu antar rekan kerja) yang
   muncul di jawaban pulse survey dan **wajib dirutekan konfidensial**, bukan masuk laporan kohort umum.

Selain itu, rules umum (section 4.5) menyebutkan dataset publik sengaja berisi **data berantakan**:
name variants, format tanggal & currency campur-campur, trailing whitespace, blank field, duplicate row,
timestamp beda zona. Ini sudah kelihatan nyata di dataset (lihat §12 di bawah).

---

## 11. Struktur Folder Project (Lokal)

```
C:\Users\riant\Downloads\supervity\
│   CONTEXT.md                              ← file ini, root — knowledge base immutable
│   README.md                               ← overview repo, urutan baca, status project
│
├───dataset
│   │   hr_enterprise_export.xlsx           ← workbook lengkap (7 sheet, identik dgn CSV di bawah)
│   │
│   └───csv
│           00_INDEX.csv                    ← deskripsi isi workbook
│           Field_Dictionary.csv            ← kamus semua sheet + tipe (master/transaksional) + trap types
│           Manager_Directory.csv           ← 25 manager, untuk eskalasi/nudge
│           Onboarding_Tasks.csv            ← 780 baris, task onboarding per milestone Day 1–90
│           Peakon_Engagement.csv           ← 140 baris, hasil pulse survey engagement
│           Provisioning_Integration.csv    ← 300 baris, feed provisioning IT (laptop/email/badge/VPN/akses)
│           Workers.csv                     ← 60 worker (EMP7000–EMP7059), master data Workday-style
│
└───docs                                    ← paket dokumentasi engineering (dibuat setelah CONTEXT.md)
        ARCHITECTURE.md                     ← desain sistem lengkap + diagram
        DATA_FLOW.md                        ← siklus hidup data, kontrak konfidensialitas
        DECISIONS.md                        ← Architectural Decision Records (ADR-001–012)
        DEMO.md                             ← skrip demo, timing, antisipasi pertanyaan juri
        INTEGRATIONS.md                     ← detail tiap integrasi eksternal
        MASTER_PLAN.md                      ← strategi, fase, success criteria
        OPERATORS.md                        ← spesifikasi implementasi tiap Operator + Orchestrator
        RISKS.md                            ← risk register
        TASKS.md                            ← backlog implementasi granular
```

`hr_enterprise_export.xlsx` berisi 7 sheet: `00_INDEX`, `Workers`, `Onboarding_Tasks`,
`Provisioning_Integration`, `Peakon_Engagement`, `Manager_Directory`, `Field_Dictionary` — **isinya sama
persis** dengan 6 file CSV di folder `dataset\csv\` (xlsx = versi workbook gabungan, CSV = versi per-sheet
terpisah).

Folder `docs\` berisi paket perencanaan engineering lengkap (arsitektur, spesifikasi Operator, backlog
implementasi, dll.) yang dibangun di atas `CONTEXT.md` sebagai fondasinya — lihat `README.md` untuk
urutan baca yang disarankan. `config\` dan `scripts\` (tempat `policy_config` dan reseeding utility
nantinya tinggal) belum dibuat — itu masih berupa spesifikasi di dalam `docs\` sampai benar-benar
diimplementasikan.

---

## 12. Detail Dataset (Hasil Inspeksi Aktual)

**Sumber sistem (klaim dataset):** Workday HCM + Peakon Employee Voice. Semua **fully synthetic**, tidak
ada data customer/personal asli. `Worker_WID` berbentuk GUID. Program berbasis siklus 90 hari.
**Judging berjalan di dataset tersembunyi terpisah — jangan hardcode ke baris-baris di bawah ini.**

### 12.1 `Workers.csv` — 60 baris (master)
Employee_ID: `EMP7000`–`EMP7059`.
Kolom: `Employee_ID, Worker_WID, Legal_Name, Preferred_Name, Business_Title, Job_Profile, Job_Family,
Management_Level, Position_ID, Manager_Name, Manager_WID, Cost_Center, Location, Hire_Date,
Worker_Type, Time_Type, FTE, Email_Work`

- **Job_Family**: Finance (17), Technology (17), People (16), Operations (10)
- **Location**: Penang (23), Singapore (17), KL-HQ (13), Remote (7)
- **Worker_Type**: Fixed Term (25), Regular (20), Intern (15)
- **Time_Type**: Full time (31), Part time (29) — FTE bervariasi (0.5/0.8/1.0)
- **Management_Level**: Individual Contributor (33), Team Lead (27)
- `Hire_Date` adalah anchor untuk "90-day clock" — dipakai untuk hitung Day 1/7/30/60/90.
- `Manager_WID` menghubungkan ke `Manager_Directory.csv`.

### 12.2 `Onboarding_Tasks.csv` — 780 baris (transaksional)
Kolom: `Event_ID, Employee_ID, Business_Process, Step_Name, Milestone, Due_Date, Status,
Completed_Date, Assigned_To_Role`

- 780 baris = 60 worker × 13 step tetap per worker.
- `Business_Process` selalu `"Onboarding"`.
- **13 Step_Name tetap** (masing-masing muncul 60×), dikelompokkan per milestone:
  - **Day 1**: Laptop issued · Email + SSO access · Building badge · Team introduction
  - **Day 7**: Compliance training assigned · Policy handbook acknowledgement · First 1:1 scheduled
  - **Day 30**: Role goals set · Compliance Document signed · 30-day check-in
  - **Day 60**: Mid-probation review
  - **Day 90**: Probation decision · 90-day survey
- **Status**: Completed (476) · In Progress (154) · Not Started (110) · **Escalated (40)**
- **Assigned_To_Role**: Manager (203) · IT (199) · Payroll (189) · HR (189)
- Konsistensi: semua baris `Completed` **punya** `Completed_Date` terisi; semua baris non-`Completed`
  **kosong** di `Completed_Date` (tidak ada inkonsistensi di titik ini pada sample — trap-nya kemungkinan
  ada di `Due_Date` vs `Completed_Date` yang lewat/terbalik, dan di `Status = Escalated` yang butuh
  human loop).

### 12.3 `Provisioning_Integration.csv` — 300 baris (transaksional)
Kolom: `Integration_Event_ID, Employee_ID, Resource, Requested_On, Status, Fulfilled_On`

- 300 baris = 60 worker × 5 resource tetap: **Laptop, Email, Badge, VPN, System Access** (masing-masing
  60×).
- **Status**: Fulfilled (213) · Requested (63) · **Blocked (24)**
- `Blocked` yang tanggalnya sudah lewat start date = definisi resmi **"missing day-one access"** (salah
  satu seeded trap, lihat §10).
- Baris `Fulfilled` punya `Fulfilled_On`; `Requested`/`Blocked` kosong di `Fulfilled_On`.

### 12.4 `Peakon_Engagement.csv` — 140 baris (transaksional)
Kolom: `Response_ID, Employee_ID, Survey_Round, Milestone, Driver, Score, Comment, Submitted_At`

- Hanya **59 dari 60 worker** yang punya minimal 1 respons pulse (1 worker: **zero response** —
  ini sendiri adalah sinyal, karena field dictionary bilang "blank Submitted_At = non-response").
- **Survey_Round / Milestone**: Day 30 (48) · Day 7 (47) · Day 60 (45) — tidak ada Day 1/Day 90 pulse.
- **Driver**: Belonging (48) · Onboarding (47) · Role Clarity (45)
- **Score**: skala 0–10. Ditemukan **1 baris dengan Score kosong** (dan `Submitted_At` kosong juga di
  baris yang sama) → non-response eksplisit.
- **Comment** berisi disclosure sensitif nyata di sample, contoh polanya (bukan kutipan verbatim
  lengkap): keluhan soal isu kesehatan yang belum berani disampaikan ke manager, dan keluhan soal
  perlakuan rekan kerja yang tidak tahu harus lapor ke siapa. **Ini persis skenario "sensitive disclosure
  in a pulse"** yang wajib dirutekan konfidensial.
- **⚠️ `Submitted_At` formatnya TIDAK KONSISTEN** — ini bukti nyata trap "mixed date formats" dari
  rules §4.5. Tiga format berbeda ditemukan di kolom yang sama:
  - ISO dengan waktu: `2026-06-15 00:00:00`
  - DD/MM/YYYY: `15/07/2026`
  - Nama bulan: `Jun 21 2026`
  → Operator/Orchestrator **wajib** bisa parse ketiga format ini secara robust, bukan asumsi satu format
  saja.

### 12.5 `Manager_Directory.csv` — 25 baris (master)
Kolom: `Manager_WID, Employee_ID, Name, Email_Work, Org`
- Employee_ID manager: `EMP2000`–`EMP2024` (rentang ID beda dari worker `EMP7xxx` — jangan tertukar).
- **Org**: Finance (7) · Sales (5) · Ops (5) · Engineering (4) · People (4)
- Dipakai untuk tujuan **eskalasi/nudge** (mis. Slack nudge ke manager saat hire berisiko).

### 12.6 `Field_Dictionary.csv` — kamus resmi
| Sheet | Deskripsi | Class |
|---|---|---|
| Workers | Workday worker report. `Employee_ID, Worker_WID, Job_Profile, Job_Family, Manager_WID, Cost_Center, Hire_Date` menggerakkan 90-day clock | master |
| Onboarding_Tasks | Workday onboarding business-process steps. Milestone Day 1..Day 90, Status Not Started/In Progress/Completed/Escalated | transactional |
| Provisioning_Integration | Feed Workday→IT provisioning. Resource Laptop/Email/Badge/VPN/System Access; **Blocked past start = missing day-one access** | transactional |
| Peakon_Engagement | Workday Peakon Employee Voice. Score 0–10, **Comment (sensitive disclosures di sini)**, blank Submitted_At = non-response | transactional |
| Manager_Directory | Manager untuk eskalasi/nudge (Manager_WID) | master |
| SEEDED TRAP TYPES | missing day-one access · stalled compliance doc · disengaged hire · sensitive disclosure in a pulse | note |

### 12.7 `00_INDEX.csv`
Ringkasan workbook: sistem asal Workday HCM + Peakon Employee Voice, program 90 hari, list 6 sheet,
catatan **"Fully synthetic. Sensitive-disclosure comments must route confidentially, never into the
cohort report,"** dan penegasan **"Judging runs on a separate hidden set; do not hardcode."**

---

## 13. Kesimpulan Teknis untuk Desain Build (Turunan dari Data + Rules)

Ini bukan resep wajib (tim bebas desain), tapi observasi logis dari data + brief untuk jadi bahan diskusi
desain:

- **Minimal 2 Operator yang jelas relevan** dari data yang ada, misalnya: (a) Operator yang menilai
  status onboarding task + provisioning (deteksi missing access / stalled compliance doc), dan
  (b) Operator yang menilai pulse engagement (deteksi disengaged hire / sensitive disclosure). Orchestrator
  menggabungkan output keduanya per worker untuk memutuskan "on track?" lalu branching ke
  provisioning lanjut vs human review/eskalasi.
- **System of record** yang masuk akal: HRIS-like store (Airtable/Supabase) tempat 5 sheet ini di-seed,
  atau ticket tool (Jira/Asana) untuk provisioning tasks.
- **Channel**: Slack/Teams/Outlook untuk nudge ke manager (pakai `Manager_Directory.csv` + email
  manager), dan jalur terpisah/konfidensial khusus untuk sensitive disclosure.
- **Exception nyata yang bisa didemokan**: baris `Status = Escalated` di `Onboarding_Tasks`, baris
  `Status = Blocked` di `Provisioning_Integration`, atau baris comment sensitif di `Peakon_Engagement` —
  semua ini legitimate live-exception candidates untuk dirutekan ke Auto Workbench.
- **Wajib robust terhadap data kotor**: minimal parsing 3 format tanggal berbeda di `Submitted_At`,
  serta kemungkinan field kosong (`Score` kosong, `Fulfilled_On` kosong, `Completed_Date` kosong) yang
  harus di-pause-and-escalate, bukan diasumsikan/diisi sembarangan.
- **Konfidensialitas** untuk sensitive disclosure harus benar-benar dipisah rutenya dari laporan kohort
  umum — ini poin eksplisit yang disebut dua kali (di `00_INDEX.csv` dan problem statement).

---

## 14. Aturan Fair Play & Ketentuan Lain yang Perlu Diingat

- Semua pekerjaan harus dibuat **selama window hackathon** oleh tim terdaftar. Reuse komponen milik
  tim sendiri boleh asal **disclosed**; mengklaim karya orang/tim lain sebagai milik sendiri tidak boleh.
- Pemakaian AI untuk membangun Auto **diharapkan** (Auto memang generate kode) — yang dinilai adalah
  hasil akhirnya: dekomposisi, governance, exception handling, business output di atas trap set.
- Tim tetap memegang IP submission; dengan mendaftar, tim memberi lisensi ke Supervity untuk
  menampilkan submission di case study/rekaman/materi promosi dengan atribusi. **Juara 1 di tiap
  track wajib bersedia difitur di case study Supervity.**
- Dataset dari Supervity hanya untuk dipakai di hackathon ini, **tidak boleh diredistribusi**.
- Tidak boleh plagiarisme, tidak boleh memalsukan build, tidak boleh mengotak-atik sistem/submission
  tim lain, dan tidak boleh berusaha mendapatkan dataset judging tersembunyi sebelum waktunya.
- Submission yang memalsukan demo, hardcode ke sample data, atau salah representasi fungsi aktual AI
  Employee **akan didiskualifikasi** begitu ketahuan saat dijalankan di hidden pack.
- Kode etik berlaku di semua kanal (Discord, submission, tatap muka di APU) — pelanggaran bisa kena
  pengurangan poin sampai diskualifikasi.
- Keputusan juri final.
- Satu orang hanya boleh di satu tim; satu tim hanya boleh submit ke satu track.

---

## 15. Hal-hal Operasional / FAQ Penting dari Discord

- **Discord adalah source of truth mutlak** — kalau tidak ada di Discord, dianggap tidak resmi.
- Peserta **bawa sistem sendiri** — tidak dapat akun Supervity hosted; bikin akun sendiri di
  CRM/ticket/ERP/database/document store yang dipakai.
- Data sample berupa **starter data pack ala enterprise export**: untuk HR = Workday+Peakon style
  (yang sudah dijelaskan di §12), untuk track lain gaya berbeda (SAP-style Finance/Ops, ServiceNow-style
  Support, Salesforce-style Sales).
- **Auto Policies / Auto Insights tidak wajib** dipakai — Insights hanya bonus opsional, bukan syarat gate.
- **Akses platform gratis** sepanjang periode hackathon untuk semua peserta terdaftar.
- Sempat ada isu teknis alokasi track (nama tim salah tercatat, teammate ke-assign track beda) — semua
  ini murni administratif Discord dan **tidak relevan** untuk isi build itu sendiri; kalau ada masalah track
  assignment, itu perlu dicek langsung ke panitia via Discord (bukan bagian dari file ini karena sifatnya
  sementara/berubah-ubah).
- Recording workshop Day 1 & Day 2, cheatsheet, dan slide deck ada di Enablement Kit yang dibagikan
  panitia lewat Google Drive.

---

## 16. Checklist Cepat Sebelum Submit (Self-Check terhadap Gate + Rubrik)

- [ ] Ada 1 Orchestrator + **minimal 2 Operator Agent** berbeda, dengan perilaku paralel/branching/
      stateful yang kelihatan jelas (bukan cuma sequential lurus).
- [ ] **Minimal 3 integrasi live**, mencakup **≥2 kategori berbeda**, termasuk **1 channel** + **1 system of
      record** — semuanya akun/sistem milik tim sendiri, bukan Google-based (Google masih beta).
- [ ] **Minimal 1 exception nyata** benar-benar dirutekan live ke **Auto Workbench** (bukan
      disimulasikan/di-mock).
- [ ] Data **tidak** dibaca langsung dari file lokal — masuk lewat integrasi live (seed ke sistem, atau
      ditarik dari document store).
- [ ] Logic (threshold/routing/policy) didefinisikan sendiri oleh tim saat runtime, **configurable tanpa
      kode**.
- [ ] Field kosong / data hilang di-**pause & escalate**, tidak di-crash atau diisi asal.
- [ ] Sensitive disclosure (dari Peakon comment) dirutekan **konfidensial**, tidak masuk laporan umum.
- [ ] Build **tidak** di-hardcode ke baris sample di dataset ini — harus generalize ke data baru.
- [ ] Demo video 3–5 menit, share screen, cover: rationale, uniqueness, live end-to-end execution +
      exception case.
- [ ] Live Operator URL + link Auto workspace tim siap dikirim.
- [ ] Public LinkedIn post siap, menyebut Supervity & Autopilot Asia Hackathon.
- [ ] Submit **sebelum** 20 Juli 12:00 MYT (jangan mepet deadline).

---

*Disusun berdasarkan dokumen resmi hackathon (rules, problem statement, workshop deck), transkrip
pengumuman Discord, dan inspeksi langsung terhadap isi dataset (`hr_enterprise_export.xlsx` beserta 6
CSV turunannya). Kalau ada pengumuman terbaru di Discord yang bertentangan dengan isi file ini,
ikuti Discord.*
