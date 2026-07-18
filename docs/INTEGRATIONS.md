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
| 1 | Airtable | System of record | **Yes** (satisfies "1 system of record") | OP-01 (write), OP-02/OP-03 (read), OP-04 (write), OP-05 (read) |
| 2 | Slack | Channel | **Yes** (satisfies "1 channel") | OP-04 (write) |
| 3 | Typeform | Forms | **Yes** (3rd integration, 3rd category — margin above the gate minimum) | OP-01 (trigger source) |
| 4 | GitHub | Developer systems | No — bonus only (auditability) | OP-04 (optional stretch write, see `TASKS.md` Phase 4) |

This set already satisfies the gate at integrations 1–2 (2 integrations, 2 categories, channel + SoR
present); integration 3 exists purely to build margin (`MASTER_PLAN.md` §3) so a single integration
failure during judging cannot drop the build below the gate threshold.

**Note on the LLM classification call inside OP-03:** this uses Supervity Auto's native LLM step, not a
new external system connection, so it is **not counted** toward the integration total — it does not
connect to a CRM/ERP/ticket system/database/HRIS, channel, document store, scheduling tool, form tool,
developer system, or social platform (`CONTEXT.md` §5 category list), so counting it would misrepresent
the gate evidence. This is stated explicitly to avoid any ambiguity when assembling the submission.

---

## 1. Airtable — System of Record

### Purpose
Hosts the five source-data tables (`Workers`, `Onboarding_Tasks`, `Provisioning_Integration`,
`Peakon_Engagement`, `Manager_Directory`) plus the derived `Cases & Audit Log` table. This is the single
persistent state store for the whole system (`ARCHITECTURE.md` §6).

### Category
System of record — explicitly listed as an eligible category alongside CRM/ERP/ticket system/database/
HRIS (`CONTEXT.md` §5).

### Why Selected (over alternatives)
See `DECISIONS.md` ADR-001 for the full comparison against Supabase and a generic spreadsheet. Summary:
Airtable's native Auto integration path (`CONTEXT.md` §5, "Path 1 — native integration") is the fastest
route for a no-code Round 1 build, its schema (tables + linked records) maps almost 1:1 onto the
dataset's 5-sheet structure (`CONTEXT.md` §12), and it is explicitly named as an approved Google
alternative in both the rules and the problem statement (`CONTEXT.md` §5, §9).

### Authentication
Personal/workspace API token, owned by the team (rules §3.1/§3.3: teams must own their own connections —
`CONTEXT.md` §5). Token scoped to the single Airtable base used for this project only.

### Data Exchanged
- **Read:** `Workers`, `Onboarding_Tasks`, `Provisioning_Integration`, `Manager_Directory` by the
  detection/action Operators; `Peakon_Engagement` is read by **OP-03 only** — no other Operator's read
  scope includes it (see the confidentiality contract, `DATA_FLOW.md` §7).
- **Write:** `Workers` (OP-01, new/updated hire records), `Cases & Audit Log` (OP-04, every
  notification/escalation outcome).

### Read/Write Operations
| Operation | Operator | Table |
|---|---|---|
| Write (create/update) | OP-01 | `Workers` |
| Read | OP-02 | `Onboarding_Tasks`, `Provisioning_Integration`, `Workers` |
| Read | OP-03 | `Peakon_Engagement`, `Workers` |
| Read | OP-04 | `Manager_Directory` |
| Write | OP-04 | `Cases & Audit Log` |
| Read (aggregate) | OP-05 | `Workers`, `Onboarding_Tasks`, `Provisioning_Integration`, `Cases & Audit Log` — **never** `Peakon_Engagement`, by design (`OPERATORS.md` §OP-05, `DATA_FLOW.md` §7.3). This row must always match `OPERATORS.md` §OP-05's Inputs list exactly; a mismatch here previously contradicted the confidentiality contract and has been corrected. |

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
Satisfies "at least one system of record" outright.

### Judging Contribution
Central to **Business output** (OP-05 reads it for the quantified metric) and **Customizability**
(no code path bypasses Airtable — a business user changing data in Airtable directly changes what the
AI Employee sees next run, without any workflow edit).

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
Adds a 3rd integration and a 3rd distinct category, building margin above the gate's minimum
(`MASTER_PLAN.md` §3) — the single highest-leverage integration decision for gate *safety*, since it
means a Slack or Airtable outage during judging still leaves the gate satisfied via Typeform's category
plus whichever of the other two remains healthy... **caveat**, explicitly noted: the gate still requires
1 channel + 1 SoR specifically, so Typeform alone cannot substitute for a Slack or Airtable outage; its
real value is the 3rd-integration count buffer and the 3rd category, not category substitution. This
caveat is recorded so the team does not misunderstand the margin it provides.

### Judging Contribution
Demonstrates the full lifecycle "new hire arrives → normalized → monitored" live, which strengthens the
**Business output** narrative (this is a real intake path, not just a report over static historical
data) and gives the demo a natural opening beat (`DEMO.md` §3).

---

## 4. GitHub — Developer Systems (Bonus / Optional)

### Purpose
Stretch-goal audit trail: mirror every `Cases & Audit Log` write as a GitHub issue or commit, giving a
fully external, tamper-evident audit surface beyond Airtable itself.

### Category
Developer systems — explicitly listed (`CONTEXT.md` §5: "GitHub, GitLab").

### Why Selected (and why optional)
Named directly in the rules; a natural fit for the **auditability & governance bonus**
(`CONTEXT.md` §7: *"a full audit trail per case... readable without an engineer"*). Marked optional
because it is not required for the gate (already satisfied by integrations 1–3) and should only be
attempted after Phase 1–3 of `TASKS.md` are solid, per `MASTER_PLAN.md` §4.5 bonus-priority ordering —
attempting a 4th integration before the core pipeline is robust would trade robustness for a bonus,
which `MASTER_PLAN.md` §1 explicitly ranks below gate/business-output/architecture.

### Authentication
GitHub personal access token or GitHub App, scoped to a single repository the team creates for this
purpose only.

### Data Exchanged
Outbound only: case summaries (same non-sensitive fields as the Airtable audit log — the confidentiality
contract in `DATA_FLOW.md` §7 applies identically here; a GitHub issue must never contain raw disclosure
text either).

### Read/Write Operations
Write-only (create issue/commit).

### Failure Recovery
Best-effort — because this integration is bonus-only and not gate-relevant, a failure here should log a
warning but must **never** escalate to the Workbench or block the primary Airtable audit write (which
remains the authoritative record). This is an explicit priority ordering: the bonus integration must not
be able to degrade core functionality.

### Fallback
Airtable `Cases & Audit Log` remains fully authoritative with or without this integration; GitHub is
strictly additive.

### Qualification Gate Contribution
None (by design — explicitly not counted toward the gate, to avoid any temptation to treat it as
load-bearing).

### Judging Contribution
Bonus line only: **Auditability and governance**.
