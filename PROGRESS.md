# PROGRESS.md — Audit Progres vs `docs/TASKS.md`

**Tanggal audit:** 2026-07-18 · **Sifat:** read-only, tidak ada kode di luar test yang dijalankan/diubah.
**Sumber kebenaran urutan kerja:** `docs/TASKS.md`. **Bukti kode:** isi repo pada commit `d53e4c7`.

**Legenda status:**

| Simbol | Arti |
|---|---|
| ✅ | Selesai & terverifikasi dari repo |
| ⚠️ | Ada file/artefak, tapi belum sesuai spek atau baru sebagian |
| ❌ | Belum ada (artefak yang seharusnya bisa dilihat di repo memang tidak ada) |
| ❓ | Tidak bisa diverifikasi dari repo — perlu cek manual (hidup di Supervity Auto / Airtable / Slack / Typeform / eksternal) |

> **Prinsip audit (non-optimis):** tugas yang berjalan di platform Auto / Airtable / Slack / Typeform / video **tidak** dianggap selesai hanya karena tidak ada buktinya di repo. Itu ditandai ❓, bukan ✅ dan bukan ❌. ❌ hanya dipakai kalau artefaknya memang wajar ada di repo tapi tidak ada.

---

## Ringkasan bukti kode yang ada di repo

Seluruh kode di repo hanya di dua tempat:
- `config/policy_config.json` (+ `config/README.md`)
- `scripts/seed_loader/` — `normalize.py`, `fuzzy_dedup.py`, `loader.py`, `airtable_client.py`, `schema.py`, `seed_policy_config.py`, + `test_normalize.py`, `test_fuzzy_dedup.py`, `test_loader.py`

**Hasil test:** `python3 -m unittest discover` → **58 tests, semua PASS** (7.76s).
Catatan lingkungan: `rapidfuzz` **tidak** terpasang, jadi `fuzzy_dedup.py` teruji lewat fallback `difflib`. Semua acceptance test tetap lolos di backend fallback. `requests` terpasang.

**TIDAK ADA** satupun file implementasi Operator (OP-01…OP-05) maupun Orchestrator (ORCH-01) di repo — itu memang no-code workflow di Supervity Auto, jadi wajar tidak ada, tapi konsekuensinya semua Fase 1, 2, dan 4 tidak bisa diverifikasi dari repo.

---

## Phase 0 — Foundations

### Epic 0.0 — Platform Capability Spike

| ID | Status | Bukti | Catatan |
|---|---|---|---|
| 0.0.1 Escalation ke Workbench + writeback | ❓ | Tidak ada artefak repo | Spike konfirmasi platform Auto. Perlu cek manual di workspace Auto. |
| 0.0.2 Trace UI menampilkan 2 step paralel | ❓ | Tidak ada artefak repo | Bukti visual di trace Auto. Ini prasyarat acceptance 2.2.2 — wajib dibuktikan manual. |
| 0.0.3 Konektor native Airtable/Slack/Typeform | ❓ | Tidak ada artefak repo | Perlu cek manual apakah ketiganya muncul sebagai native connector. |
| 0.0.4 Output surface OP-05 = Airtable Interface | ❓ | `ARCHITECTURE.md` §1/§10 mengasumsikan Airtable Interface | Keputusan terdokumentasi di arsitektur, tapi konfirmasi "sudah diputuskan tim" tidak ada di repo. |

### Epic 0.1 — Systems Provisioning

| ID | Status | Bukti | Catatan |
|---|---|---|---|
| 0.1.1 Airtable base 6 tabel + `Cases & Audit Log` | ❓ | `scripts/seed_loader/schema.py` men-encode 5 tabel sumber (kolom persis dari `Field_Dictionary.csv`) | Struktur skema ada di kode, tapi **keberadaan base Airtable-nya** + tabel `Cases & Audit Log` tidak bisa diverifikasi dari repo. Perlu cek manual. |
| 0.1.2 Slack workspace + 7 channel | ❓ (dengan bukti parsial) | `config/policy_config.json` → `routing` berisi **channel ID Slack asli** (format `C0B…`) untuk 5 Org + confidential + IT (7 total), **bukan** placeholder `#nama`. Commit `d53e4c7`. | Sub-kriteria "`manager_channel_by_org` diisi 5 channel ID asli, bukan placeholder" → **terpenuhi di config**. Tapi keberadaan channel, review membership channel confidential, dan token bot **tidak** bisa diverifikasi dari repo. |
| 0.1.3 Typeform form (field OP-01) | ❓ | Tidak ada artefak repo | Perlu cek manual: form live + webhook payload dengan 3 field wajib. |
| 0.1.4 Konek 3 integrasi di dalam Auto | ❓ | Tidak ada artefak repo | Status "connected" hanya bisa dilihat di workspace Auto. Tidak ada `.env` di repo (gitignored). |

### Epic 0.2 — Configuration & Shared Rules

| ID | Status | Bukti | Catatan |
|---|---|---|---|
| 0.2.1 `policy_config` v1.0 | ✅ | `config/policy_config.json` | **`as_of_date` ADA** (`null` = live wall-clock, sesuai `ARCHITECTURE.md` §5/§7). **`retry_demo_profile` ADA** (`max_attempts:1`, `backoff:[]`). Semua field §7 lengkap (`thresholds`, `routing`, `templates`, `retry`) + tambahan wajar (`normalization`, `demo_mode`, `dedup_*`, `catch_rate_sla_days`). `seed_policy_config.py` bisa push ke tabel Airtable. **Caveat:** salinan Airtable-table yang benar-benar bisa diedit business user tanpa kode = ❓ (belum bisa dilihat dari repo). |
| 0.2.2 Date-normalization multi-format | ✅ | `scripts/seed_loader/normalize.py` + `test_normalize.py` (semua pass) | Sesuai ADR-011. Parse 3 format sampel (`2026-06-15 00:00:00`, `15/07/2026`, `Jun 21 2026`) **+ >2 format unseen** (`2026/06/15`, `June 21, 2026`, `21 Jun 2026`, ISO-`T`, dsb — 13 pola). Garbage → `UNPARSEABLE` (tidak menebak). Numeric ambigu (`07/25/2026` di bawah order DMY) → `AMBIGUOUS`, tidak di-swap diam-diam. Blank → status `BLANK` tersendiri. Coverage acceptance 0.2.2 terpenuhi penuh. |
| 0.2.3 Fuzzy-dedup | ✅ | `scripts/seed_loader/fuzzy_dedup.py` + `test_fuzzy_dedup.py` (semua pass) | Sesuai ADR-012, 3 band (merge/review/new). Test: **5 pasangan varian** (auto-merge) + **5 pasangan orang berbeda** (zero false merge) — sesuai acceptance. Bonus: gate proximity `Hire_Date` + regresi pasangan nama identik nyata di sampel (EMP7032/7059, EMP7038/7043) yang **tidak** boleh merge. |
| 0.2.4 `retry_demo_profile` + wiring Operator | ⚠️ | Field `retry_demo_profile` + `demo_mode` ADA di `policy_config.json` | **Setengah jalan:** field config-nya ada (bagus). Tapi "wire OP-01/OP-04 baca `retry_demo_profile` saat `demo_mode` on" hidup di Auto → ❓. Selain itu, di kode repo sendiri (`airtable_client.py`) jalur tulis **selalu** pakai blok produksi `retry`, `demo_mode`/`retry_demo_profile` tidak pernah dibaca. Jadi konsumen toggle-nya belum terbukti di manapun yang bisa dilihat repo. |

**Exit criteria Phase 0** ("all systems connected and live; config & shared rules pass acceptance"):
config + shared rules (0.2.1–0.2.3) **terverifikasi**. "All systems connected and live" (0.1.x) **tidak** bisa diverifikasi dari repo.

---

## Phase 1 — Detection Operators

> Seluruh OP-01/02/03 adalah no-code workflow di Supervity Auto. Modul aturan referensi (`normalize.py`, `fuzzy_dedup.py`) yang jadi dependensi 1.1.1–1.1.3 memang ada & teruji, **tapi Operator-nya sendiri + unit test in-Auto (1.1.6, 1.2.7, 1.3.8) tidak ada di repo**. Tidak ada satupun bukti repo bahwa pekerjaan Auto Phase 1 sudah dimulai.

### Epic 1.1 — OP-01 Intake & Normalization

| ID | Status | Bukti | Catatan |
|---|---|---|---|
| 1.1.1 Field validation | ❓ | Aturan referensi: `normalize.py` | Operator step di Auto. Perlu cek manual. |
| 1.1.2 Wire date parse + manager resolution | ❓ | Referensi date-parse ada; resolusi manager belum ada di repo | Perlu cek manual. |
| 1.1.3 Wire fuzzy-dedup ke write path | ❓ | Aturan referensi: `fuzzy_dedup.py` | Perlu cek manual. |
| 1.1.4 Airtable write + retry/escalation | ❓ | — | Perlu cek manual. |
| 1.1.5 Konek trigger Typeform → OP-01 | ❓ | — | Perlu cek manual. |
| 1.1.6 Unit test OP-01 (5 kasus) | ❓ | Tidak ada test OP-01 di repo | Kalau dites, kemungkinan di Auto. Tidak bisa diverifikasi dari repo. |

### Epic 1.2 — OP-02 Onboarding & Provisioning Risk

| ID | Status | Bukti | Catatan |
|---|---|---|---|
| 1.2.1 Read step `Onboarding_Tasks`+`Provisioning_Integration` | ❓ | — | Auto-side. Perlu cek manual. |
| 1.2.2 Rule 1 (missing day-one access) | ❓ | — | Auto-side. |
| 1.2.3 Rule 2 (stalled compliance doc) | ❓ | — | Auto-side. |
| 1.2.4 Rules 3–4 | ❓ | — | Auto-side. |
| 1.2.5 Tier aggregation | ❓ | — | Auto-side. |
| 1.2.6 Retry/escalation read failure | ❓ | — | Auto-side. |
| 1.2.7 Unit test OP-02 (5+1 kasus) | ❓ | Tidak ada di repo | Auto-side. |

### Epic 1.3 — OP-03 Engagement & Disclosure

| ID | Status | Bukti | Catatan |
|---|---|---|---|
| 1.3.1 Read step `Peakon_Engagement` | ❓ | — | Auto-side. |
| 1.3.2 Rule 1 (low score) | ❓ | Threshold `engagement_low_score` ada di config | Logika Operator di Auto. |
| 1.3.3 Rule 2 (survey non-response) | ❓ | — | Auto-side. |
| 1.3.4 LLM disclosure classifier | ❓ | Threshold `disclosure_classifier_min_confidence` ada di config | Prompt + wiring classifier di Auto. |
| 1.3.5 Output contract `_internal_case_payload` | ❓ | Kontrak terdokumentasi di `DATA_FLOW.md` §7 | Implementasi di Auto. |
| 1.3.6 Fail-safe-to-confidential | ❓ | — | Auto-side. |
| 1.3.7 Tier aggregation | ❓ | — | Auto-side. |
| 1.3.8 Unit test OP-03 (5 kasus) | ❓ | Tidak ada di repo | Auto-side. |

**Exit criteria Phase 1** (OP-01/02/03 lolos unit test masing-masing): **tidak** bisa diverifikasi dari repo.

---

## Phase 2 — Orchestration & Action

> Semua Auto-side. Tidak ada bukti repo.

### Epic 2.1 — OP-04 Escalation & Notification

| ID | Status | Bukti | Catatan |
|---|---|---|---|
| 2.1.1 Channel/manager resolution | ❓ | `routing.manager_channel_by_org` ada di config | Logika resolusi di Auto. |
| 2.1.2 Message templating (3 case type) | ❓ | 3 template (`manager_nudge`/`it_escalation`/`confidential_alert`) ada di `policy_config.templates` | Template string-nya ada; wiring + assertion "tak bocor `_internal_case_payload`" di Auto. |
| 2.1.3 Slack send + retry/escalation | ❓ | — | Auto-side. |
| 2.1.4 Write `Cases & Audit Log` | ❓ | — | Auto-side + butuh tabel Airtable. |
| 2.1.5 Unit test OP-04 (6 kasus) | ❓ | Tidak ada di repo | Auto-side. |

### Epic 2.2 — ORCH-01 Orchestrator

| ID | Status | Bukti | Catatan |
|---|---|---|---|
| 2.2.1 Entry point event-triggered | ❓ | — | Auto-side. |
| 2.2.2 Parallel fan-out OP-02+OP-03 | ❓ | — | Butuh bukti visual trace paralel (lihat 0.0.2). Auto-side. |
| 2.2.3 Fan-in / reason-code routing | ❓ | Tabel routing terdokumentasi `ARCHITECTURE.md` §6 | Implementasi di Auto. |
| 2.2.4 Confidentiality-first override | ❓ | — | Auto-side. |
| 2.2.5 Already-escalated → Workbench | ❓ | — | Jalur exception gate-mandatory. Auto-side. |
| 2.2.6 Low-confidence disclosure → Workbench | ❓ | — | Auto-side. |
| 2.2.7 Partial-signal handling | ❓ | — | Auto-side. |
| 2.2.8 Cohort-sweep entry point | ❓ | — | Auto-side. |
| 2.2.9 Wire OP-04 tiap branch | ❓ | — | Auto-side. |
| 2.2.10 E2E test 60-worker cohort | ❓ | — | Auto-side. |

**Exit criteria Phase 2** (E2E cohort tanpa crash, ≥3 branch live): **tidak** bisa diverifikasi dari repo.

---

## Phase 3 — Robustness & Hidden-Dataset Rehearsal

| ID | Status | Bukti | Catatan |
|---|---|---|---|
| 3.1 Reseeding utility | ⚠️ (kode ✅ / live-run ❓) | `loader.py` + `airtable_client.py` + `schema.py` + `test_loader.py` (pass). **Catatan penting: task memperkirakan file ini "belum ada" — ternyata SUDAH ADA.** | Kode sesuai kontrak `DATA_FLOW.md` §6: schema-driven by column name, idempoten via Airtable `performUpsert` (server-side), load report (`row_count`/`deduped`/`flagged`/`written`), mode `--reset` hanya `Cases & Audit Log`, normalisasi per row, **tidak** jalankan fuzzy-dedup di bulk. **Yang belum terverifikasi:** "loads public sample cleanly + idempotent on re-run" **melawan Airtable asli** — test sengaja tanpa network, tidak ada `.env`. Idempotensi & clean-load nyata perlu cek manual. Load report + normalisasi + in-file dedup sudah teruji lewat unit test. |
| 3.2 Schema validation abort-with-report | ✅ | `loader.py::validate_schema` + `test_loader.py` (rename kolom & file hilang → abort, no partial load) | Terpenuhi penuh sesuai acceptance. |
| 3.3 Adversarial rehearsal dataset | ❌ | Tidak ada file dataset adversarial di repo (`dataset/` hanya sampel publik + `hr_enterprise_export.xlsx`) | Belum dibuat. P1, bisa paralel. |
| 3.4 Run pipeline vs adversarial dataset | ❌ | — | Bergantung 3.3 (belum ada) + Phase 2 (belum terverifikasi). |
| 3.5 Fix gaps dari 3.4 | ❌ | — | N/A sampai 3.4 jalan. |
| 3.6 Timing reseed <90s | ❓ | — | Perlu run live terhadap dataset skala-60. Tidak bisa diverifikasi dari repo. P1. |

**Exit criteria Phase 3** (adversarial run bersih — hard gate): **belum tercapai** (3.3/3.4 belum ada).

---

## Phase 4 — Reporting, Console, Bonus

### Epic 4.1 — OP-05 Cohort Reporting

| ID | Status | Bukti | Catatan |
|---|---|---|---|
| 4.1.0 Exposure-rate | ❓ | Definisi di `OPERATORS.md`/`DATA_FLOW.md` §7 | Operator OP-05 di Auto. |
| 4.1.1 Task completion rate | ❓ | Sanity-check 476/780 ≈ 61% terdokumentasi | Implementasi di Auto; butuh `as_of_date` di-pin. |
| 4.1.2 At-risk catch-rate + SLA exclusion | ❓ | `catch_rate_sla_days` ada di config | Auto-side; butuh `Cases & Audit Log` terisi. |
| 4.1.3 Zero-division guard | ❓ | — | Auto-side. |
| 4.1.4 Staleness fallback | ❓ | — | Auto-side. |
| 4.1.5 Dashboard/console (Airtable Interface) | ❓ | — | Airtable Interface. Perlu cek manual. |

### Epic 4.2 — Auditability Bonus (P1)

| ID | Status | Bukti | Catatan |
|---|---|---|---|
| 4.2.1 `Cases & Audit Log` queryable & human-readable | ❓ | — | Bergantung 2.1.4 (Auto) + tabel Airtable. |
| 4.2.2 GitHub integration (P2) | ❓ | Tidak ada bukti repo | Best-effort, opsional. |

### Epic 4.3 — Self-Learning Sketch (P2, dokumentasi saja)

| ID | Status | Bukti | Catatan |
|---|---|---|---|
| 4.3.1 Design note Workbench-override → `policy_config` | ❌ | **Diverifikasi via grep:** catatan desain ini **TIDAK ADA** di `ARCHITECTURE.md` §9 maupun addendum manapun | Acceptance bilang "note sudah ada di §9" — faktanya belum. §9 = Maintainability, §10 = Round 2 forward notes (soal coded console, bukan feedback loop). Ini task yang seharusnya repo-verifiable, dan memang belum ada. Cheap: doc-only. |

**Exit criteria Phase 4** (console tampil 2 metrik live + audit trail queryable): **tidak** bisa diverifikasi / belum tercapai.

---

## Phase 5 — Submission Package

| ID | Status | Bukti | Catatan |
|---|---|---|---|
| 5.1 Rekam demo video | ❓ | Tidak ada di repo | Bergantung Phase 4. Eksternal. |
| 5.2 Review video vs beat timing | ❓ | — | Eksternal. |
| 5.3 LinkedIn post publik | ❓ | — | Eksternal. |
| 5.4 Rakit Operator URL + Auto workspace link | ❓ | — | Eksternal. |
| 5.5 Draft field portal | ❓ | Tidak ada file draft di repo | Bisa jadi repo-artefak; belum ada. |
| 5.6 Submit portal | ❓ | — | Eksternal. Portal buka 19 Jul 12:00 MYT. |
| 5.7 Final readiness checklist | ❓ | — | Eksternal. |

**Exit criteria Phase 5** (5 artefak siap ≥18 jam sebelum 20 Jul 12:00 MYT): **belum tercapai**.

---

## Ringkasan

### Phase sekarang ada di mana

Berdasarkan **bukti yang bisa dilihat dari repo saja**, yang benar-benar terverifikasi selesai adalah:

- **Phase 0 Epic 0.2 (config + shared rules)** — `policy_config.json` (0.2.1), `normalize.py` (0.2.2), `fuzzy_dedup.py` (0.2.3) lengkap, sesuai spek ADR-011/012 & `ARCHITECTURE.md` §7, 58/58 test pass. (0.2.4 baru setengah: field config ada, wiring konsumen belum terbukti.)
- **Head-start Phase 3** — `loader.py`/`schema.py`/`airtable_client.py` (3.1) sudah dibangun lebih awal (task ini malah mengira belum ada) dan schema-validation abort (3.2) sudah teruji penuh. Yang tersisa: verifikasi run live + adversarial dataset (3.3) yang belum ada.

Semua sisanya — **Epic 0.0 & 0.1 (spike + provisioning), seluruh Phase 1 & 2 (Operator + Orchestrator), Phase 4 (reporting/console), Phase 5 (submission)** — hidup di Supervity Auto / Airtable / Slack / Typeform / eksternal dan **tidak bisa diverifikasi dari repo**. Tidak ada satupun file Operator/Orchestrator di repo, dan tidak ada bukti repo bahwa pekerjaan Auto sudah dimulai.

**Kesimpulan jujur:** repo membuktikan **fondasi Phase 0 (aturan bersama) + kerangka utilitas Phase 3**. Status "sistem tersambung & live" (gate Phase 0) dan seluruh pembangunan Operator di Auto **belum terbukti sama sekali** dari sisi repo — bisa jadi sudah dikerjakan di Auto, bisa jadi belum. Itu harus dipastikan manual.

> ⏰ **Catatan waktu (kritis):** hari ini **18 Jul 2026**; portal submission buka **19 Jul 12:00 MYT**, deadline **20 Jul 12:00 MYT** (`TASKS.md` 5.6, `MASTER_PLAN.md` §12). Sisa waktu ± **2 hari**. Kalau Phase 1/2/4 di Auto memang belum dibangun, jadwalnya sangat ketat untuk jalur demo gate-mandatory.

### 3 next action paling prioritas

1. **Audit manual workspace Supervity Auto + Airtable — SEKARANG.** Seluruh status ❓ (Epic 0.0, 0.1, semua Phase 1/2/4) menentukan gambaran sebenarnya, dan tidak satupun terlihat dari repo. Konfirmasi konkret: base Airtable 6 tabel + `Cases & Audit Log` ada? 7 channel Slack + token ada (config sudah punya ID asli)? Typeform live? Integrasi "connected" di Auto? Operator apa saja yang sudah terbangun? Tanpa ini, mustahil menilai posisi nyata proyek dengan deadline ± 2 hari.

2. **Prioritaskan jalur demo gate-mandatory (Phase 1 → 2), bukan poles.** Jalur inti yang wajib live: OP-01 intake Typeform → ORCH-01 fan-out paralel OP-02+OP-03 → exception `TASK_ALREADY_ESCALATED` ke Auto Workbench + routing confidential. Ini pusat demo (`DEMO.md` Beat 3–6) dan prasyarat Phase 3/4/5. Jika di Auto belum ada, ini critical path. (Repo sudah menyediakan modul aturan referensi `normalize.py`/`fuzzy_dedup.py` untuk mempercepat.)

3. **Tutup gap Phase 3 yang murah tapi gate-blocking + buktikan loader live.** (a) Buat **adversarial rehearsal dataset (3.3)** — belum ada file sama sekali, padahal Phase 3 exit = hard release gate. (b) Jalankan `loader.py` **live** sekali terhadap Airtable untuk mengubah 3.1 dari "kode ✅ / live ❓" jadi idempotensi terverifikasi, sekalian ukur <90s (3.6). Sisipan cepat lain: lengkapi wiring `demo_mode`→`retry_demo_profile` (0.2.4) dan tulis design note self-learning (4.3.1, doc-only, saat ini ❌).

---

### Temuan sampingan (bukan blocker, tapi perlu dirapikan)

- `scripts/seed_loader/README.md` baris 13 masih menyatakan **"loader itself — Not yet built (Phase 3)"**, padahal `loader.py` sudah ada & teruji. Dokumentasi stale — perlu update.
- `requirements.txt` mencantumkan `rapidfuzz`, tapi di lingkungan audit tidak terpasang; verifikasi berjalan lewat fallback `difflib`. Semua test tetap pass, jadi tidak ada regresi — tapi backend yang dipakai saat submission sebaiknya dipastikan konsisten.
