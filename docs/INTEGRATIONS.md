# INTEGRATIONS.md — External Integrations

**Reads as prerequisite:** `CONTEXT.md` §5–§6 (gate rules, integration categories), `ARCHITECTURE.md`,
`OPERATORS.md`
**Purpose:** document every external system the build connects to, and why. This is also the direct
evidence trail for Qualification Gate criterion 2 (`CONTEXT.md` §5: "≥3 integrations, ≥2 categories,
including 1 channel + 1 system of record").

---

## Summary Table

| # | Integration | Category | Required for gate? | Owning Operator(s) |
|---|---|---|---|---|
| 1 | Supabase | System of record | **Yes** (satisfies "1 system of record") | OP-01 (write, `Workers`), OP-02/OP-03 (read), OP-04 (read `Manager_Directory`, write `Cases_Audit_Log`), OP-05 (read), every Operator (read `policy_config`) |
| 2 | Slack | Channel | **Yes** (satisfies "1 channel") | OP-04 (write) |
| 3 | Typeform | Forms | **Yes** (3rd distinct category, only category-diversity margin remaining — see note below) | OP-01 (trigger source, via the `1.1.5` polling Parent Workflow) |
| 4 | GitHub | Developer systems | No — bonus only (auditability) | OP-04 (optional stretch write, see `TASKS.md` Phase 4) |

*Airtable — deprecated, no longer an active integration.* `DECISIONS.md` ADR-001's second amendment moved
every table off Airtable; it's kept connected in the workspace only as an inert historical artifact
(nothing reads or writes to it) and is not part of the gate-evidence count below.

**Gate math (`DECISIONS.md` ADR-001 second amendment, Consequence 2):** Supabase + Slack + Typeform =
**3 integrations, 3 categories** — this is the gate's bare stated minimum (`CONTEXT.md` §5: "≥3
integrations, ≥2 categories, incl. 1 channel + 1 SoR") with **zero spare integration margin**, down from
5 integrations before the full migration. GitHub is optional/bonus and explicitly not counted toward the
gate by this project's own design (see §4's Qualification Gate Contribution) — wiring it does not restore
margin. This is an accepted, deliberate trade-off (a single-backend architecture was judged simpler to
build correctly with a two-person team and the time remaining than maintaining two live data backends
through the rest of the build) — see `RISKS.md` R-26 for the accepted residual risk and its mitigation.

**Note on the LLM classification call inside OP-03:** this uses Supervity Auto's native LLM step, not a
new external system connection, so it is **not counted** toward the integration total — it does not
connect to a CRM/ERP/ticket system/database/HRIS, channel, document store, scheduling tool, form tool,
developer system, or social platform (`CONTEXT.md` §5 category list), so counting it would misrepresent
the gate evidence. This is stated explicitly to avoid any ambiguity when assembling the submission.

---

## 1. System of Record — Supabase

`DECISIONS.md` ADR-001 (second amendment): Supabase is now the sole system of record for all 7 tables.
The migration happened in two steps — first `Workers`/`Manager_Directory`/`policy_config` (OP-01's
tables), then the rest (`Onboarding_Tasks`/`Provisioning_Integration`/`Peakon_Engagement`/
`Cases_Audit_Log`, the last renamed from Airtable's `Cases & Audit Log` on the move). Airtable is fully
deprecated — see the Summary Table note above.

### Purpose
Hosts all 7 tables: the 5 source-data tables, `policy_config`, and the derived `Cases_Audit_Log`. The
single persistent state store for the whole system (`ARCHITECTURE.md` §6).

### Category
System of record — explicitly listed as an eligible category alongside CRM/ERP/ticket system/database/
HRIS (`CONTEXT.md` §5).

### Why Selected (over staying on Airtable, over a generic spreadsheet)
See `DECISIONS.md` ADR-001 (original decision, first amendment, and second amendment) for the full
history. Summary of the end state: Postgres-backed, stronger for relational queries than Airtable would
have been for a Round 2 coded console; reached via Path 2 custom REST since no native Auto connector
exists for it (same situation Airtable was in — `AUTO_BUILD_GUIDE.md` §A). The original Airtable choice
(fastest no-code Path 1 route, 1:1 schema mapping) was correct for getting Round 1 started quickly; the
full migration completed once OP-02/03/04/05 hadn't been built yet, meaning zero already-tested logic had
to be touched to make the move (see the ADR's "Why now, not later" reasoning).

### Authentication
Project-scoped Supabase `secret` API key (the current-generation equivalent of the legacy `service_role`
key — full access, bypasses Row Level Security), owned by the team, stored in `.env`
(`SUPABASE_URL`/`SUPABASE_SERVICE_ROLE_KEY`) and Auto's credential store, never committed. RLS is off on
every table — the only caller is this secret key from trusted server-side automation (Auto, and the local
reseed scripts), never a browser/anon client, so RLS would add no real security boundary here.

### Data Exchanged
- **Read:** `Onboarding_Tasks`/`Provisioning_Integration` by OP-02; `Peakon_Engagement` by **OP-03
  only** — no other Operator's read scope includes it (see the confidentiality contract, `DATA_FLOW.md`
  §7); `Manager_Directory` by OP-04; `Workers` by OP-01 (write) and OP-05 (read); `policy_config` by
  every Operator, every run (retry profile, thresholds, templates — `ARCHITECTURE.md` §7).
- **Write:** `Workers` (OP-01, new/updated hire records, upsert on `Worker_WID`); `Cases_Audit_Log`
  (OP-04, every notification/escalation outcome).

### Read/Write Operations
| Operation | Operator | Table |
|---|---|---|
| Write (create/update) | OP-01 | `Workers` |
| Read | OP-02 | `Onboarding_Tasks`, `Provisioning_Integration` |
| Read | OP-03 | `Peakon_Engagement` |
| Read | OP-04 | `Manager_Directory` |
| Write | OP-04 | `Cases_Audit_Log` |
| Read | every Operator | `policy_config` |
| Read (aggregate) | OP-05 | `Workers`, `Onboarding_Tasks`, `Provisioning_Integration`, `Cases_Audit_Log` — **never** `Peakon_Engagement`, by design (`OPERATORS.md` §OP-05, `DATA_FLOW.md` §7.3). This row must always match `OPERATORS.md` §OP-05's Inputs list exactly; a mismatch here previously contradicted the confidentiality contract and has been corrected. |

### Failure Recovery
Per-Operator retry policy (`policy_config.retry`: 3 attempts, 5/20/60s backoff — `ARCHITECTURE.md` §7).
Exhausted retries escalate per each Operator's failure table in `OPERATORS.md` — never a silent skip.

### Fallback
None for reads that feed a live business decision (a failed read must escalate, not guess —
`MASTER_PLAN.md` §6). The one designed exception is OP-05, which falls back to serving its last
successful metrics snapshot with a staleness flag rather than a broken dashboard during a live demo
(`OPERATORS.md` §OP-05 Retry Behavior) — a deliberate, narrow exception because a stale-but-labeled
number is more useful mid-demo than an error screen, and nothing downstream depends on OP-05's output
for correctness (it's a reporting leaf, not a decision input).

### Qualification Gate Contribution
Satisfies "at least one system of record" outright — the **only** system of record now, so this
integration going down during judging would fail the gate outright, not just degrade one metric. See
`RISKS.md` R-26 for the accepted residual risk this creates and its mitigation.

### Judging Contribution
Central to **Business output** (OP-05 reads it for the quantified metric) and **Customizability** (no
code path bypasses it — a business user editing any table, including `policy_config`, directly changes
what the AI Employee sees or does next run, without any workflow edit).

---

## 2. Slack — Channel

### Purpose
Delivers manager nudges, IT escalations, and confidential HR alerts (`OPERATORS.md` §OP-04).

### Category
Channel — explicitly listed (`CONTEXT.md` §5: "Slack, Discord, Teams, Outlook").

### Why Selected (over Teams/Outlook/Discord)
See `DECISIONS.md` ADR-002. Summary: Slack supports the specific pattern needed here — an
organization-routed public-ish channel *and* a small, separately access-controlled private channel for
confidential material — with a lightweight setup cost appropriate for a 48-hour build, and is explicitly
named in the rules' channel category.

### Authentication
Slack app/bot token, installed into a workspace the team creates and owns (rules §3.1/§3.3).

### Data Exchanged
Outbound only: rendered notification messages (`policy_config.templates`, `ARCHITECTURE.md` §7).
**No raw sensitive `Comment` text is ever sent to any Slack channel** — see `DATA_FLOW.md` §7 for the
full contract; the confidential channel receives a structured alert (hire, milestone, "a sensitive
disclosure requires review") with the actual disclosure content available only to a human who opens the
linked case at the Auto Workbench, not inline in the Slack message itself. This extra indirection is a
deliberate design choice: Slack channel membership can drift over time, while Workbench access is the
platform's own governed surface — keeping the most sensitive content one hop further from any
notification channel reduces exposure risk.

### Read/Write Operations
Write-only (send message). No inbound read dependency in Round 1's design.

### Failure Recovery
Retry per `policy_config.retry`; exhausted → escalate to Workbench with `op04_notification_failure` tag,
and the audit-log write is still attempted independently (`OPERATORS.md` §OP-04 Retry Behavior).

### Fallback
None beyond the Workbench escalation above — a failed notification about a real risk must never be
silently dropped.

### Qualification Gate Contribution
Satisfies "at least one channel" outright, and is also the source of the **live exception** demonstrated
in the demo when a Slack send fails or a case reaches the confidential path (`DEMO.md` §5).

### Judging Contribution
Primary evidence for **Technical architecture** (branching: manager vs. IT vs. confidential routing) and
directly visible in the **Demo** as the most legible, human-readable proof that the system took a real
action, not just a database write.

---

## 3. Typeform — Forms

### Purpose
The "a way in" intake channel named explicitly in the problem statement's example table
(`CONTEXT.md` §9: *"A new hire added via a form or a row"*), feeding OP-01.

### Category
Forms — explicitly listed (`CONTEXT.md` §5: "Typeform").

### Why Selected
Named directly in the rules as the forms-category example, has a native Auto integration path, and its
webhook-on-submit model maps cleanly onto OP-01's event trigger (`ARCHITECTURE.md` §3.1) without any
polling logic needed.

### Authentication
Typeform account + webhook secret, owned by the team.

### Data Exchanged
Inbound only: new-hire intake fields (`OPERATORS.md` §OP-01 Inputs table) submitted by whoever is
onboarding the new hire (in a real deployment, likely an HR coordinator; in the demo, the team itself).

### Read/Write Operations
Read (webhook payload) only; Typeform itself is never written back to.

### Failure Recovery
If the webhook payload is malformed or missing required fields, OP-01's own validation layer handles it
(`OPERATORS.md` §OP-01 Failure Handling) — Typeform-side failure recovery is limited to standard webhook
retry behavior, which is a platform property, not something this system needs to reimplement.

### Fallback
The reseeding utility (`DATA_FLOW.md` §6) is the fallback intake path for bulk/demo purposes — Typeform
is the *live* single-hire path, the utility is the *bulk* path; both converge on the same normalization
logic (§`DATA_FLOW.md` §6), so neither is a "backup" for the other so much as two entry points to one
pipeline.

### Qualification Gate Contribution
The 3rd required category (Forms), completing the gate's exact stated minimum alongside Supabase (SoR)
and Slack (channel) — see the Summary Table's gate-math note. **This is no longer margin — it's part of
the floor.** Since Airtable's full deprecation (`DECISIONS.md` ADR-001 second amendment), there is no 4th
or 5th integration left in reserve; a Typeform outage during judging would drop the category count below
the gate's "≥2 categories" requirement (Supabase + Slack alone is only 2 categories), not just remove
one demo beat. See `RISKS.md` R-26 for the accepted residual risk this creates.

### Judging Contribution
Demonstrates the full lifecycle "new hire arrives → normalized → monitored" live, which strengthens the
**Business output** narrative (this is a real intake path, not just a report over static historical
data) and gives the demo a natural opening beat (`DEMO.md` §3).

---

## 4. GitHub — Developer Systems (Bonus / Optional)

### Purpose
Stretch-goal audit trail: mirror every `Cases_Audit_Log` write as a GitHub issue or commit, giving a
fully external, tamper-evident audit surface beyond Supabase itself.

### Category
Developer systems — explicitly listed (`CONTEXT.md` §5: "GitHub, GitLab").

### Why Selected (and why optional)
Named directly in the rules; a natural fit for the **auditability & governance bonus**
(`CONTEXT.md` §7: *"a full audit trail per case... readable without an engineer"*). Marked optional
because it is not required for the gate (already satisfied at the bare minimum by Supabase + Slack +
Typeform, §1/§2/§3 above — see the Summary Table's gate-math note on why there's no spare margin left to
lean on) and should only be attempted after Phase 1–3 of `TASKS.md` are solid, per `MASTER_PLAN.md` §4.5
bonus-priority ordering — attempting this integration before the core pipeline is robust would trade
robustness for a bonus, which `MASTER_PLAN.md` §1 explicitly ranks below gate/business-output/architecture.

### Authentication
GitHub personal access token or GitHub App, scoped to a single repository the team creates for this
purpose only.

### Data Exchanged
Outbound only: case summaries (same non-sensitive fields as the Supabase `Cases_Audit_Log` table — the
confidentiality contract in `DATA_FLOW.md` §7 applies identically here; a GitHub issue must never contain
raw disclosure text either).

### Read/Write Operations
Write-only (create issue/commit).

### Failure Recovery
Best-effort — because this integration is bonus-only and not gate-relevant, a failure here should log a
warning but must **never** escalate to the Workbench or block the primary `Cases_Audit_Log` write (which
remains the authoritative record). This is an explicit priority ordering: the bonus integration must not
be able to degrade core functionality.

### Fallback
Supabase's `Cases_Audit_Log` remains fully authoritative with or without this integration; GitHub is
strictly additive.

### Qualification Gate Contribution
None (by design — explicitly not counted toward the gate, to avoid any temptation to treat it as
load-bearing).

### Judging Contribution
Bonus line only: **Auditability and governance**.
