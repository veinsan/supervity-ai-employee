# OPERATORS.md — Operator Agent Specifications

**Reads as prerequisite:** `CONTEXT.md`, `MASTER_PLAN.md`, `ARCHITECTURE.md`
**Purpose:** this is the implementation specification. Claude Opus 4.8 should be able to build each
Operator directly from its section without consulting any other document except `ARCHITECTURE.md` §7
(config shape) and `INTEGRATIONS.md` (connection details).

**Conventions used below:**
- *Configurable parameters* reference the `policy_config` shape defined in `ARCHITECTURE.md` §7.
- *Escalation* always means: package the case context and route to the Auto Workbench (platform
  feature, not built by the team) or, for confidential cases, directly to the confidential Slack channel
  per `DATA_FLOW.md` §7.
- Every Operator's failure-handling table follows the same 3-row shape (validation / integration /
  low-confidence) so behavior is predictable and auditable across the whole build.

---

## OP-01 — Intake & Normalization Operator

### Purpose
Accept a new-hire record from any intake path (Typeform submission, or a row arriving via the
reseeding utility) and turn it into a clean, deduplicated `Workers` record before anything downstream
sees it. This is the Operator responsible for the "name variants … duplicate rows" trap category
(`CONTEXT.md` §4.5, §10).

### Responsibilities
- Validate required fields are present and well-typed.
- Normalize free-text fields (name casing, whitespace trimming, date parsing across known formats).
- Fuzzy-match the incoming record against existing `Workers` rows to catch name-variant duplicates
  (e.g., "Faizal Nair" vs "faizal nair " vs "Faizal  Nair") before creating a new record.
- Write the normalized record to `Workers` (Supabase, `DECISIONS.md` ADR-001 amendment), or update an
  existing matched record.

### Inputs
| Field | Source | Required | Notes |
|---|---|---|---|
| `Legal_Name` | Typeform / seed row | **yes** | the only true identity field — needed to start the clock and to dedup at all |
| `Hire_Date` | Typeform / seed row | **yes** | any of the known formats, see `DECISIONS.md` ADR-011; this is what starts the 90-day clock, so it cannot be optional |
| `Manager_Name` or `Manager_WID` | Typeform / seed row | **yes** (one of the two) | resolved against `Manager_Directory`; without this, OP-04 can never route a manager nudge later, so it must be captured at intake, not deferred |
| `Business_Title`, `Job_Profile`, `Job_Family`, `Location`, `Worker_Type`, `Time_Type`, `FTE`, `Email_Work` | Typeform / seed row | **no — enrich-later** | not needed to start the 90-day clock or to route a notification; missing at intake is stored as blank/`"Unknown"` and does **not** trigger escalation. A live Typeform intake form realistically won't collect `Job_Profile`/`FTE`/`Position_ID` at the moment a hire is added, so treating these as hard-required would make the live intake path (`DEMO.md` Beat 3) fail on almost every real submission |
| `Cost_Center`, `Position_ID` | seed row only (Typeform may omit) | no | escalate only if a downstream Operator actually needs it and it's missing at the point of use — never at intake time |

**Why only 3 fields are hard-required:** the earlier draft of this spec marked ~11 fields required, which
meant a normal Typeform submission (missing HR-system-only fields like `Position_ID`) would escalate on
nearly every live intake — directly undermining the one gate-mandatory "real, live integration" demo beat
(`CONTEXT.md` §5 rule 2). The 3 fields above are exactly what's needed to (a) identify the person,
(b) start the clock, and (c) know who to notify later — everything else is enrichment that can arrive
after intake without blocking it.

### Outputs
- A single `Workers` row (created or updated), with a normalized `Worker_WID` (generated if new).
- An `intake_result` object returned to the caller: `{ status: created|updated|escalated, worker_wid,
  dedup_confidence }`.

### Business Logic
> **Scope note (fixes an earlier ambiguity):** the steps below apply to the **live, single-record
> intake path** (a Typeform submission). The **bulk reseeding utility** (`DATA_FLOW.md` §6) that loads
> the public/hidden dataset's `Workers.csv` does **not** run fuzzy-dedup against existing rows — the
> source file's workers are already distinct, verified records (`CONTEXT.md` §12.1 confirms 60 unique
> `Employee_ID`s), so running a fuzzy-merge over them would only introduce risk of a false merge for no
> benefit. The bulk path applies steps 1–2 (text/date normalization) and writes rows as-is; it skips
> steps 3–4 (manager ambiguity / dedup) unless the utility detects an actual duplicate `Employee_ID`
> within the file itself (a true duplicate row, one of the named trap types, `CONTEXT.md` §10) — that
> case is deduped by exact `Employee_ID` match, not fuzzy name matching. Fuzzy name-based dedup exists
> specifically for the live intake path, where a new submission genuinely might refer to an already-known
> person under a slightly different spelling.
>
> **On "shared" logic:** the normalization/parsing **rules** (§Business Logic below, `DECISIONS.md`
> ADR-011/012) are specified once, in this document, and both OP-01 (a no-code Auto workflow) and the
> reseeding utility (a standalone script, `DATA_FLOW.md` §6) implement them independently against that
> one specification — not as literally shared, imported code across a no-code/script boundary, which
> Auto's no-code environment cannot do. "Shared" in this package means *one documented rule set*, not
> *one runtime module*; see `DECISIONS.md` ADR-006 for the corrected framing.

1. Parse and normalize every text field (trim, collapse whitespace, title-case names).
2. Parse `Hire_Date` using the robust multi-format parser (`DECISIONS.md` ADR-011). If unparseable →
   escalate (do not guess a date).
3. Resolve manager: if `Manager_WID` given, verify it exists in `Manager_Directory`; if only
   `Manager_Name` given, match by normalized name against `Manager_Directory.Name`. Ambiguous match
   (multiple candidates) → escalate.
4. Run fuzzy-dedup against existing `Workers` rows on normalized `Legal_Name` + `Hire_Date` proximity
   (`DECISIONS.md` ADR-012) — **live intake path only**, per the scope note above. Above
   `dedup_confidence_threshold` → treat as update to existing record, not a new hire. Below threshold but
   above a lower "worth flagging" band → escalate for human confirmation rather than silently deciding
   either way.
5. Write to Supabase.

### Validation
- The 3 hard-required fields (`Legal_Name`, `Hire_Date`, manager identification) must be non-empty after
  normalization — missing any of these escalates (§Business Logic steps 2–3).
- All other fields are validated **only if present**: `FTE`, if given, must parse as a number in (0, 1];
  `Email_Work`, if given, must match a basic email shape. A missing optional field is never an escalation
  trigger; a present-but-malformed optional field is stored with a data-quality note rather than blocking
  the write (it doesn't gate the 90-day clock the way the 3 required fields do).

### Execution Order
First in the pipeline for any new-hire event; not part of the periodic cohort sweep (existing hires
don't re-run OP-01).

### Dependencies
None upstream. Downstream: writes the `Workers` row that OP-02/OP-03 read.

### Integrations
- **Read/write:** Supabase `Workers`, read-only `Manager_Directory` (both Supabase, `DECISIONS.md`
  ADR-001 amendment — see `INTEGRATIONS.md` §1b).
- **Trigger source:** Typeform poll trigger, via the `1.1.5` Parent Workflow (see `INTEGRATIONS.md` §3;
  `AUTO_BUILD_GUIDE.md` §B on the poll-vs-webhook platform reality).

### Retry Behavior
Supabase write failure → retry per `policy_config.retry` (3 attempts, backoff 5/20/60s). Exhausted →
escalate as an **integration failure** case (distinct from a business-logic escalation, tagged
accordingly in the case record for audit clarity).

### Failure Handling
| Failure type | Condition | Action |
|---|---|---|
| Validation | Required field missing/unparseable after normalization | Escalate to Workbench, tag `intake_validation` |
| Integration | Supabase write fails after retries | Escalate to Workbench, tag `intake_integration_failure` |
| Low-confidence | Dedup match confidence in the ambiguous band | Escalate to Workbench, tag `intake_possible_duplicate` |

### Escalation Conditions
- Unparseable `Hire_Date`.
- Ambiguous manager match (0 or >1 candidates).
- Ambiguous dedup match.
- Supabase write failure after retries.

### Configurable Parameters
| Parameter | Default | Reasoning |
|---|---|---|
| `dedup_confidence_threshold` | 0.90 | High bar — false-merge (treating two real people as one) is worse than an extra escalation |
| `dedup_flag_band_low` | 0.70 | Below this, treated as confidently a new hire, no escalation needed |
| `date_formats_accepted` | list, see ADR-011 | Extendable without code change if a new hidden-dataset format appears |

---

## OP-02 — Onboarding & Provisioning Risk Operator

### Purpose
Assess a single hire's onboarding-task and IT-provisioning health, and surface the "missing day-one
access" and "stalled compliance doc" trap types (`CONTEXT.md` §10) as a structured risk signal.

### Responsibilities
- Read all `Onboarding_Tasks` rows and all `Provisioning_Integration` rows for the given hire.
- Compute per-task lateness against `Due_Date` / `Requested_On`.
- Classify specific known risk patterns (below) into a risk tier with human-readable reasons.

### Inputs
| Field | Source | Required |
|---|---|---|
| `Employee_ID`, `Hire_Date` | `Workers` | yes |
| `Onboarding_Tasks` rows for this `Employee_ID` (`Milestone`, `Due_Date`, `Status`, `Completed_Date`, `Assigned_To_Role`) | Airtable | yes (may legitimately be empty for a brand-new hire — not an error) |
| `Provisioning_Integration` rows for this `Employee_ID` (`Resource`, `Requested_On`, `Status`, `Fulfilled_On`) | Airtable | yes (same note) |

### Outputs
```
risk_signal_A = {
  tier: "LOW" | "MEDIUM" | "HIGH",   // ADVISORY ONLY — human-readable severity for the audit log.
                                       // ORCH-01 never routes on this field; see ARCHITECTURE.md §6.
  reasons: [ { code, detail, task_or_resource_ref } ],  // this is what ORCH-01 actually routes on
  confidence: 1.0                     // fixed for this Operator — every rule below is a deterministic
                                       // data check, not a probabilistic classification, so there is no
                                       // meaningful notion of "confidence" to vary here. OP-03's
                                       // confidence field is the real one (its LLM classifier's actual
                                       // confidence) and is the only confidence value ORCH-01's
                                       // uncertainty branch reads — see ARCHITECTURE.md §6.
}
```

### Business Logic (rule definitions — the actual "trap type" detectors)
> All lateness comparisons below use `policy_config.as_of_date` (`ARCHITECTURE.md` §5, §7), never an
> implicit system clock — this is load-bearing for hidden-dataset reproducibility, not a stylistic
> choice.

1. **Missing day-one access:** any `Provisioning_Integration` row with `Status = Blocked` where
   `as_of_date - Hire_Date > provisioning_blocked_grace_days` → reason code `MISSING_DAY_ONE_ACCESS`.
2. **Stalled compliance doc:** any `Onboarding_Tasks` row whose `Step_Name` matches an entry in
   `policy_config.thresholds.compliance_step_terms` (default: `["Compliance training assigned",
   "Compliance Document signed"]` — a **configurable list**, not a hardcoded substring match, precisely
   because the hidden dataset is not guaranteed to reuse the public sample's exact step vocabulary,
   `MASTER_PLAN.md` §10) where `Status ∈ {Not Started, In Progress}` and
   `as_of_date - Due_Date > task_stalled_overdue_days` → reason code `STALLED_COMPLIANCE_DOC`.
3. **Explicit escalation signal:** any `Onboarding_Tasks` row with `Status = Escalated` → reason code
   `TASK_ALREADY_ESCALATED`. This reason code is special: per `ARCHITECTURE.md` §6, its presence alone
   routes the case directly to the **Auto Workbench**, not a Slack nudge — the source system already
   judged this needs a human, and this Operator must not silently downgrade that judgment.
4. **Provisioning stuck in Requested:** a `Requested` row older than the grace threshold with no
   `Fulfilled_On` → reason code `PROVISIONING_DELAYED`.
5. **Tier (advisory only, per Outputs above):** 0 reasons → LOW. Exactly 1 reason → MEDIUM. 2+ reasons →
   HIGH. This tier is carried into the audit log for human readability and is **not** consulted by
   ORCH-01 for routing — routing is decided solely from which reason codes are present, per
   `ARCHITECTURE.md` §6's single-authority table (see `DECISIONS.md` ADR-013 for why an earlier draft's
   separately-computed "combined tier" was removed).

### Validation
- If a hire has **zero** rows in both source tables (should not happen for a seeded hire, but must not
  crash for a hidden-dataset edge case) → return `tier: LOW, reasons: [], data_state: "no_data_yet"`
  rather than error — a brand-new hire legitimately has no rows yet. `confidence` stays `1.0` per the
  Outputs contract; `data_state` is a separate, explicit flag for this case, not an overload of
  `confidence`.
- Any row with a `Due_Date`/`Requested_On` that fails date parsing → excluded from lateness math but
  logged as a data-quality note on the output, not silently dropped.

### Execution Order
Runs in parallel with OP-03, triggered by ORCH-01, per hire, both event- and schedule-triggered.

### Dependencies
Reads `Workers` (for `Hire_Date`), `Onboarding_Tasks`, `Provisioning_Integration`. No write dependency —
this Operator is read-only, which is a deliberate design choice (see `ARCHITECTURE.md` §2 "who calls
what" invariant) so it can be re-run idempotently at any time without side effects.

### Integrations
Airtable, read-only (`Onboarding_Tasks`, `Provisioning_Integration`); Supabase, read-only (`Workers`,
`DECISIONS.md` ADR-001 amendment).

### Retry Behavior
Read failures retry per `policy_config.retry` regardless of which backend the read targets; exhausted →
escalate as `provisioning_read_failure` (this is rare for a read-only call but must still degrade to
escalation, not a crash, per the non-negotiable "don't crash" rule).

### Failure Handling
| Failure type | Condition | Action |
|---|---|---|
| Validation | Unparseable date on a row | Exclude row from lateness math, note in output, continue |
| Integration | Airtable or Supabase read fails after retries | Escalate, tag `op02_integration_failure` |
| Low-confidence | Zero source rows for an active-window hire | Return `tier: LOW, data_state: "no_data_yet"`; do not escalate (expected state, not an error) |

### Escalation Conditions
Only on integration failure after retries. Business-logic findings (even HIGH tier) are **not**
escalated directly by OP-02 — that decision belongs to ORCH-01 (§6 in `ARCHITECTURE.md`), keeping
escalation policy centralized rather than duplicated across Operators.

### Configurable Parameters
| Parameter | Default | Reasoning |
|---|---|---|
| `provisioning_blocked_grace_days` | 1 | Day-one access should exist by end of Day 1; 1 day grace absorbs timezone/EOD ambiguity |
| `task_stalled_overdue_days` | 3 | 3 days past due is late enough to be a real signal, short enough to still be actionable before the next milestone |
| `compliance_step_terms` | `["Compliance training assigned", "Compliance Document signed"]` | Explicit list, not a substring match, so the rule survives a hidden dataset that renames or adds compliance-related steps — extending coverage requires editing this list, not the Operator's logic |

---

## OP-03 — Engagement & Disclosure Operator

### Purpose
Assess a single hire's Peakon pulse-survey history for engagement risk, and — critically — detect
sensitive disclosures in free-text comments so they can be routed confidentially, never into the cohort
report (`CONTEXT.md` §9 scenario text, §10, §12.7 index note).

### Responsibilities
- Read all `Peakon_Engagement` rows for the hire.
- Compute an engagement trend/score.
- Classify each `Comment` for sensitive disclosure using an LLM-based classifier (not keyword matching —
  see `DECISIONS.md` ADR-005), returning a confidentiality flag independent of the engagement score.

### Inputs
| Field | Source | Required |
|---|---|---|
| `Employee_ID` | `Workers` | yes |
| `Peakon_Engagement` rows (`Survey_Round`, `Milestone`, `Driver`, `Score`, `Comment`, `Submitted_At`) | Airtable | yes (may be empty — non-response is a valid, meaningful state) |

### Outputs
```
risk_signal_B = {
  tier: "LOW" | "MEDIUM" | "HIGH",   // ADVISORY ONLY, same convention as OP-02 — see ARCHITECTURE.md §6
  reasons: [ { code, detail } ],       // never includes raw Comment text; this is what ORCH-01 routes on
  confidential: true | false,
  confidence: 0.0–1.0,                 // THE real, meaningful confidence value in this system — this is
                                        // the LLM disclosure classifier's actual output confidence, and
                                        // is the only confidence ORCH-01's uncertainty branch reads
                                        // (ARCHITECTURE.md §6). Populated only for the disclosure
                                        // classification (rule 3); rules 1–2 do not produce a confidence
                                        // value of their own, since they are deterministic checks like
                                        // OP-02's.
  _internal_case_payload: { comment_text, driver, milestone }  // only attached when confidential=true,
                                                                 // routed exclusively to OP-04's
                                                                 // confidential path — see DATA_FLOW.md §7
}
```

### Business Logic
> All window/lateness comparisons below use `policy_config.as_of_date` (`ARCHITECTURE.md` §5, §7),
> never an implicit system clock — same reproducibility rationale as OP-02.
1. **Disengaged hire:** if the most recent `Score` (or the average of the last 2 responses, whichever is
   available) is `< engagement_low_score` → reason code `LOW_ENGAGEMENT_SCORE`, MEDIUM.
2. **Non-response:** if a hire has passed a `Milestone` window (per `Hire_Date` and `as_of_date`) with
   **no** corresponding `Peakon_Engagement` row (blank `Submitted_At` per `Field_Dictionary.csv`
   definition) → reason code `SURVEY_NON_RESPONSE`, LOW-MEDIUM signal on its own (a single non-response
   is common and not alarming), escalates to MEDIUM if combined with a prior low score.
3. **Sensitive disclosure classification:** every non-empty `Comment` is passed to an LLM classifier with
   a narrowly-scoped prompt: *does this comment disclose a personal, health, interpersonal-conflict, or
   safety concern that should be handled confidentially by HR, as opposed to routine onboarding
   feedback?* Returns `confidential: boolean` + `confidence: float`.
   - `confidential = true` and `confidence ≥ disclosure_classifier_min_confidence` → set
     `risk_signal_B.confidential = true`, attach `_internal_case_payload`, **do not** include any
     excerpt of `Comment` in `reasons[]` (reasons must stay safe to display on the general cohort
     report).
   - `confidential = true` but `confidence < threshold` → do **not** auto-decide; report the low
     `confidence` value on the signal and let ORCH-01's uncertainty rule (`ARCHITECTURE.md` §6, second
     row of the routing table) send it to the Workbench for a human judgment call — this is intentional:
     a low-confidence *possible* disclosure must still never leak into the general report even while
     unconfirmed, so the routing on low confidence is Workbench, never "log and continue."
4. Tier aggregation (advisory only, per Outputs above): 0 reasons → LOW, 1 → MEDIUM, 2+ → HIGH,
   independent of the `confidential` flag (confidentiality is a routing property evaluated first and
   separately, not a severity property — see `ARCHITECTURE.md` §6).

### Validation
- `Score` outside 0–10 → treat as invalid, exclude from scoring, log as data-quality note.
- Empty `Comment` → skip classification, no confidentiality flag possible from this row.

### Execution Order
Runs in parallel with OP-02, triggered by ORCH-01.

### Dependencies
Reads `Workers` (`Hire_Date`), `Peakon_Engagement`. Read-only, same idempotency rationale as OP-02.

### Integrations
Airtable (read-only, `Peakon_Engagement`) + Supabase (read-only, `Workers`, `DECISIONS.md` ADR-001
amendment) + LLM classification call (via Supervity Auto's native LLM step — not a separate external
integration for gate-counting purposes, since it does not connect to a new system of record, channel, or
document store; see `INTEGRATIONS.md` note on this distinction).

### Retry Behavior
Both reads (Airtable and Supabase) and the LLM classification call retry per `policy_config.retry`. LLM
call exhausted → **must not** default to `confidential: false` (a false negative here is the single worst
failure mode in the whole build — a real disclosure leaking into the general report). Default-on-failure
is `confidential: true` with `confidence: 0` (fail safe, not fail silent), which routes to the Workbench
for a human to actually read the comment and decide.

### Failure Handling
| Failure type | Condition | Action |
|---|---|---|
| Validation | Score out of range | Exclude from scoring, note in output |
| Integration | Airtable or Supabase read fails after retries | Escalate, tag `op03_integration_failure` |
| Low-confidence | Classifier confidence below threshold on a possible disclosure | Fail-safe to `confidential: true`, route to Workbench, never to general report |

### Escalation Conditions
Integration failure after retries; low-confidence disclosure classification (fail-safe path, §above).

### Configurable Parameters
| Parameter | Default | Reasoning |
|---|---|---|
| `engagement_low_score` | 5 (of 0–10) | Below the midpoint; conservative enough to avoid flagging normal variance |
| `disclosure_classifier_min_confidence` | 0.75 | High bar to auto-confirm; below it, fail-safe to human review rather than a coin-flip auto-decision |

---

## OP-04 — Escalation & Notification Operator

### Purpose
Own **every** outbound write side-effect in the system: Slack messages and case-record writes. This is
the only Operator with write access to notification channels, which localizes all retry/failure/
credential logic for external side-effects to one place (`ARCHITECTURE.md` §9).

### Responsibilities
- Look up the correct manager and channel (via `Manager_Directory` + `policy_config.routing`).
- Compose and send the correct message template for the case type.
- Write a structured case record (audit trail bonus) for every action taken, including Workbench
  escalations initiated elsewhere in the flow (ORCH-01 calls OP-04 to *log* a Workbench escalation even
  when OP-04 didn't do the routing itself, so the audit trail is complete — see `DATA_FLOW.md` §8).

### Inputs
```
{
  case_type: "manager_nudge" | "it_escalation" | "confidential_disclosure" | "workbench_log",
  employee_id, worker_wid,
  reasons: [...],              // never raw sensitive text, per OP-03 contract
  _internal_case_payload?: {...}  // present only for confidential_disclosure, handled per DATA_FLOW.md §7
}
```

### Outputs
`{ status: sent|escalated|failed, case_record_id, channel_used }`

### Business Logic
1. Resolve target channel: `manager_nudge` → look up hire's `Manager_WID` → `Manager_Directory.Org` →
   `policy_config.routing.manager_channel_by_org`. `it_escalation` →
   `policy_config.routing.it_escalation_channel`. `confidential_disclosure` →
   `policy_config.routing.confidential_channel` **always**, regardless of `Org` (no org-based branching
   on confidential cases — a single, small, access-controlled channel by design, see `DECISIONS.md`
   ADR-002).
2. Render the message from `policy_config.templates[case_type]`, interpolating only non-sensitive fields
   (`reasons[].detail`, never `_internal_case_payload`, into manager/IT templates).
3. Send via Slack integration.
4. Write a case record to the `Cases & Audit Log` Airtable table: timestamp, hire, case type, channel,
   policy rule(s) that fired, outcome — this record is what the auditability bonus is graded on.

### Validation
- `Manager_WID` must resolve to a valid `Manager_Directory` row for `manager_nudge`; if not →
  escalate to Workbench instead of silently failing to notify anyone (`Org`-less or manager-less hire is
  itself a data-quality signal worth a human's attention).

### Execution Order
Called by ORCH-01 after risk tiering (§6 in `ARCHITECTURE.md`), after the confidential/uncertain checks
have already routed away anything that shouldn't reach this Operator's non-confidential paths.

### Dependencies
Reads `Manager_Directory` (Supabase); writes Slack channels and the `Cases & Audit Log` table (Airtable).

### Integrations
Slack (write); Supabase (read, `Manager_Directory`, `DECISIONS.md` ADR-001 amendment); Airtable (write,
`Cases & Audit Log`).

### Retry Behavior
Slack send failure → retry per `policy_config.retry`. Exhausted → the case is **not** silently dropped:
escalate to Workbench with tag `op04_notification_failure`, and still attempt the audit-log write
independently (so the audit trail reflects "we tried to notify and failed," which is itself an important
governance record).

### Failure Handling
| Failure type | Condition | Action |
|---|---|---|
| Validation | Manager/channel cannot be resolved | Escalate to Workbench, tag `op04_routing_unresolved` |
| Integration | Slack send fails after retries | Escalate to Workbench, tag `op04_notification_failure`; audit-log write attempted regardless |
| Low-confidence | N/A (this Operator does not classify) | — |

### Escalation Conditions
Unresolved routing target; Slack send failure after retries.

### Configurable Parameters
All of `policy_config.routing` and `policy_config.templates` (§`ARCHITECTURE.md` §7) — this Operator is
the primary consumer of the customizability layer, since routing and message copy are the fields a
business user is most likely to want to change.

---

## OP-05 — Cohort Reporting Operator

### Purpose
Compute the business-output metrics (`MASTER_PLAN.md` §4.1) across the whole active cohort and publish
them for the console/demo, while guaranteeing sensitive disclosure content never appears in this output.

> **This is a structural guarantee, not a filter.** OP-05's read scope, listed in Inputs below,
> **permanently excludes `Peakon_Engagement` as a table** — not just its `Comment` field. OP-05 has no
> input contract that could read a raw disclosure even by mistake, because the table isn't in its read
> list at all. Any future edit that adds `Peakon_Engagement` to OP-05's inputs (or to `INTEGRATIONS.md`'s
> summary row for OP-05) breaks this guarantee and must be treated as a regression, not a refactor —
> see `DATA_FLOW.md` §7.3 for the full contract and `INTEGRATIONS.md` §1a/§1b's OP-05 rows (Airtable and
> Supabase respectively, `DECISIONS.md` ADR-001 amendment), which must always match the Inputs list below
> exactly.

### Responsibilities
- Compute an **exposure rate**: the % of the active cohort currently showing at least one unresolved
  onboarding/provisioning risk reason (`MISSING_DAY_ONE_ACCESS`, `STALLED_COMPLIANCE_DOC`,
  `TASK_ALREADY_ESCALATED`, `PROVISIONING_DELAYED`) — computed **directly from `Onboarding_Tasks` and
  `Provisioning_Integration`**, independent of whether the system has already acted on it. This is the
  **headline business metric** (see rationale below).
- Compute **task completion rate** per milestone and cohort-wide, from `Onboarding_Tasks` directly.
- Compute **at-risk-hire catch rate** (secondary metric): of hires with a logged case in `Cases & Audit
  Log`, what fraction received a routed intervention before their next milestone's due date.
- Publish all three to the dashboard data shape (`ARCHITECTURE.md` §1, `DASH` node — an Airtable
  Interface, per the Phase-0-confirmed surface, `ARCHITECTURE.md` §1 note). **This publish step must
  write to an Airtable table** regardless of which backend a given metric was computed from — Airtable
  Interfaces can only visualize Airtable data, and `active_cohort_size` (below) is sourced from Supabase's
  `Workers` table post-migration. OP-05 itself (the Operator, reaching both backends via REST) is the only
  place that bridges this; the Interface never queries Supabase directly.

> **Why exposure rate, not catch rate, is the headline (fixes a near-tautology):** "at-risk catch rate"
> as originally specified measured whether the system acted on the cases *it itself generated* — since
> the routing logic (`ARCHITECTURE.md` §6) acts on essentially every detected case by construction, this
> number would trend near 100% almost regardless of whether the underlying onboarding problems are
> actually improving, which is a self-report of "did my automation run," not a business result. It is
> exactly the kind of claim `CONTEXT.md` §7's bar — "survives an enterprise buyer's cross-question" —
> would puncture. **Exposure rate is computed from the raw source tables, without reference to the
> system's own case log**, so it is a real, falsifiable, independently-checkable number: "X% of the
> active cohort has at least one unresolved onboarding risk right now." Catch rate is retained as a
> secondary, supporting metric — "and here's how much of that we've already routed to a human or
> resolved" — which is honest framing rather than the headline claim.

### Inputs
`Workers` (Supabase, read-only); `Onboarding_Tasks`, `Provisioning_Integration`, `Cases & Audit Log`
(Airtable, read-only). **`Peakon_Engagement` is deliberately not in this list** — see the Purpose note
above.

### Outputs
```
cohort_metrics = {
  as_of: policy_config.as_of_date,     // explicit, not implicit — see ARCHITECTURE.md §5
  exposure_rate: float,                 // headline metric — % of active cohort with ≥1 unresolved OP-02 reason, computed independent of Cases & Audit Log
  task_completion_rate: { overall: float, by_milestone: {...} },
  at_risk_catch_rate: float,            // secondary metric
  active_cohort_size: int,
  open_cases: int
}
```

### Business Logic
1. **Exposure rate** = (count of active-cohort hires with ≥1 currently-unresolved OP-02-style reason,
   recomputed directly from `Onboarding_Tasks`/`Provisioning_Integration` using the same rule definitions
   as `OPERATORS.md` §OP-02) / (active cohort size). This is a fresh computation using OP-02's rules, not
   a read of OP-02's own prior output, so it reflects true current state even if a sweep hasn't run
   recently.
2. **Task completion rate** = `Completed` tasks / tasks with `Due_Date ≤ policy_config.as_of_date`
   ("due-to-date"), computed overall and broken down by `Milestone`. **Note for test authors:** on the
   full public sample with `as_of_date` set beyond the latest `Due_Date` in the data (`CONTEXT.md` §12.2
   confirms the sample's `Due_Date`s span into early August 2026), "due-to-date" converges to the full
   780-row set, so the sanity-check value is `Completed / Total` = 476/780 ≈ 61% — but this is a
   **special case of the as_of-bounded definition**, not a separate metric; `TASKS.md` 4.1.1's acceptance
   criterion must pin `as_of_date` to this "beyond all due dates" condition for the 476/780 check to be
   valid, or the two will legitimately disagree at any other `as_of_date`.
3. **At-risk catch rate** (secondary) = (cases in `Cases & Audit Log` with `outcome = sent|escalated`,
   i.e., *acted on*) / (all cases created), **excluding** cases still legitimately pending within their
   SLA window.
4. Sensitive disclosure cases are counted in `open_cases` and in the catch-rate denominator/numerator
   like any other case, but **never** surfaced with their content — only their existence and resolution
   status are aggregate-countable, per the confidentiality contract (`DATA_FLOW.md` §7). This remains
   true even under the exposure-rate metric, since exposure rate is computed from OP-02-style tables
   only and never touches case content either.

### Validation
Zero-division guard when `active_cohort_size = 0` or no tasks due yet (return nulls with an explicit
"insufficient data" flag rather than a divide-by-zero error).

### Execution Order
Runs once at the end of each schedule-triggered cohort sweep (`ARCHITECTURE.md` §3.1); can also be
triggered on-demand for the demo/console.

### Dependencies
Reads outputs written by OP-01 (indirectly, via Supabase) and OP-04 (indirectly, via Airtable), so must
run after a sweep completes, never interleaved with it — ORCH-01 enforces this ordering.

### Integrations
Airtable (read-only, aggregate query, `Onboarding_Tasks`/`Provisioning_Integration`/`Cases & Audit Log`;
also write, publishing computed metrics for the Interface — see Responsibilities); Supabase (read-only,
`Workers`, `DECISIONS.md` ADR-001 amendment).

### Retry Behavior
Read failure (either backend) → retry per `policy_config.retry`; exhausted → publish the **previous**
successful metric snapshot with a staleness flag, rather than showing a broken/blank dashboard during a
live demo.

### Failure Handling
| Failure type | Condition | Action |
|---|---|---|
| Validation | Zero-division case | Return explicit "insufficient data," not an error |
| Integration | Airtable or Supabase read fails after retries | Serve last-known-good snapshot with staleness flag |
| Low-confidence | N/A | — |

### Escalation Conditions
None — this Operator never escalates to the Workbench; it is a pure reporting Operator by design (no
side effects beyond the dashboard write), keeping the escalation surface concentrated in ORCH-01/OP-04
for auditability.

### Configurable Parameters
| Parameter | Default | Reasoning |
|---|---|---|
| `catch_rate_sla_days` | 3 | Matches `task_stalled_overdue_days`, keeping the "did we act in time" bar consistent with the "is this task late" bar used to generate the signal in the first place |

---

## ORCH-01 — Onboarding & Retention Orchestrator

### Purpose
Coordinate OP-01 through OP-05, own all branching and escalation-routing decisions, and maintain the
per-hire execution lifecycle (`ARCHITECTURE.md` §4–§6).

### Responsibilities
Exactly the responsibilities described in `ARCHITECTURE.md` §3–§6: trigger handling, fan-out to
OP-02/OP-03, fan-in (union of `reasons[]` from both signals — **not** a combined tier; neither Operator's
`tier` field is consulted for routing), confidentiality-first branching, routing to OP-04 or the
Workbench, periodic OP-05 invocation.

### Inputs
Either a single `employee_id` (event-triggered) or none (schedule-triggered, sweeps all active hires).

### Outputs
Per-hire: a completed case (logged via OP-04) or a clean "no action" (logged internally, not written as
a case, to keep the audit log meaningful rather than noisy — see `DATA_FLOW.md` §8 for why "no action"
is not itself an audit record).

### Business Logic
The full branching table in `ARCHITECTURE.md` §6 is this Operator's specification, verbatim; it is not
repeated here to avoid duplication across documents (constraint: "Avoid duplication across documents").

### Validation
Confirms both OP-02 and OP-03 returned before combining (fan-in barrier); if one Operator's call itself
fails integration retries and escalates independently, ORCH-01 treats the *other* Operator's signal
alone as sufficient to make a routing decision rather than blocking the whole hire's evaluation on one
failed read — partial signal is still actionable, and blocking entirely would let a single flaky
integration call silently suppress the whole risk pipeline for that hire.

### Execution Order
Top-level coordinator; see §3, §4 for the full model.

### Dependencies
OP-01 through OP-05, Auto Workbench.

### Integrations
None directly — by design (§2 "who calls what" invariant); all external I/O flows through the Operators
it coordinates.

### Retry Behavior
Orchestrator-level retry is not separately defined; each Operator call's own retry/escalation contract
(above) is what ORCH-01 relies on. This avoids a second, competing retry policy layered on top of the
Operators' own.

### Failure Handling
If an Operator call escalates (any type, from any of OP-01–OP-05), ORCH-01 does not treat this as an
Orchestrator failure — it is the expected, correct outcome of the "escalate on uncertainty" philosophy
(`MASTER_PLAN.md` §6). ORCH-01 continues processing the rest of the cohort sweep regardless of one
hire's escalation, so a single problematic case never blocks the sweep.

### Escalation Conditions
Directly escalates when (checked in the order given in `ARCHITECTURE.md` §6): confidentiality flag is
true (bypass all other routing); OP-03's disclosure-classifier `confidence` is below
`disclosure_classifier_min_confidence` on a possible disclosure; `TASK_ALREADY_ESCALATED` is present in
the unioned `reasons[]`, or both OP-02 and OP-03 independently produced at least one reason each
(compounding risk); or either OP-02 or OP-03 itself escalated due to integration failure with no usable
signal remaining for that hire. Note there is no such thing as "combined-risk confidence" — OP-02's
`confidence` is fixed at 1.0 (deterministic rules, `OPERATORS.md` §OP-02 Outputs) and is never a routing
input; only OP-03's classifier confidence feeds the uncertainty branch.

### Configurable Parameters
None owned directly — ORCH-01 reads only from the Operators' outputs and `policy_config.routing`/
`.thresholds`, which are already documented against the Operator that owns each field. This is
intentional: ORCH-01's logic is pure coordination, so there is nothing to tune here that isn't already
tunable at the Operator level.
