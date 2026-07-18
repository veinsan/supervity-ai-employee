# AUTO_BUILD_GUIDE.md — Operator Build Prompts & Test Cases
**Purpose:** copy-paste-ready prompts for Supervity Auto's AI Operator builder, one per `TASKS.md`
sub-task, each paired with the test cases needed to confirm its Acceptance Criteria. This is a build
runbook, not a redesign — every prompt implements the frozen spec in `OPERATORS.md`. Read a task's
`OPERATORS.md` section alongside its prompt here if anything is unclear.

**Covers:** OP-01 `1.1.4`–`1.1.6` (finishing Epic 1.1) and OP-04 `2.1.2`–`2.1.5` (finishing Epic 2.1).
`1.1.1`–`1.1.3` and `2.1.1` are already built; this guide continues from those.

**How to use each section:**
1. Paste the **Prompt** block into Auto's Operator builder (continue the named Operator, don't start a new one).
2. Bind any highlighted data-write/read step to the Supabase Path 2 REST credential (see Conventions §A).
3. If Auto asks a clarifying question or asks you to confirm before running/saving, answer directly and
   explicitly — a concrete decision or a clear "yes, proceed." A vague or unanswered prompt is the most
   common way these builds stall.
4. Run the **Test Cases** and confirm each expected outcome before marking the task Done in `TASKS.md`.

### §0 — If Auto's builder chat gets stuck
Per Auto's own best-practice guide, translated to this project's specifics:

| Situation | What to do |
|---|---|
| Auto keeps asking instead of building, or nothing happens | Reply with one concrete decision, or re-paste the **Goal** line plus just the step you're stuck on. |
| "Waiting for approval" or similar | Send an explicit yes/no, or list exactly what to change, before anything else. |
| Plan keeps changing, or the same error repeats | Narrow the ask to the single **STEP** that's failing rather than re-pasting the whole multi-step prompt. |
| Auto picks the wrong data source or tool | State the correct one explicitly — e.g. "use the Supabase REST credential (§A), not the native/old Airtable connector — nothing lives in Airtable anymore." |
| Run blocked after you finish building | Open the Operator's/workspace's integration settings and finish any pending connection or authorization — check §A/§B for which one this step needs. |
| Transient failure | Retry once; if it repeats, describe the last message you saw rather than pasting a raw technical error. |
| The build conversation gets long or confused across several continue-prompts | Start a fresh Auto chat against the Operator's current saved version, then paste the next prompt there — keeps context clean without losing prior build progress. |

---

## Conventions (read once, applies to every prompt below)

### §A — Supabase, Path 2 (custom REST API), NOT a native connector
`DECISIONS.md` ADR-001's second amendment: **Airtable is fully deprecated.** Every table —
`Workers`, `Manager_Directory`, `policy_config`, `Onboarding_Tasks`, `Provisioning_Integration`,
`Peakon_Engagement`, `Cases_Audit_Log` — lives on Supabase now. Every read/write is a **custom REST API
call** — this workspace has no native Supabase/Postgres connector. Do **not** use a native "Airtable" or
"Supabase"/"Postgres" action block — it will show a "requires integration connected" error with no
selectable connection. Use an HTTP/custom API request instead, bound to the Supabase REST credential
below.

> **Gotcha:** the old Airtable base still physically exists with all 6 original tables from before the
> migration. Auto's builder may default to suggesting it since it's still a connected credential in this
> workspace. Don't use it, for anything, ever — every table now lives in Supabase only.

Verified live against the project before writing this:

| Property | Value |
|---|---|
| API root | `https://{SUPABASE_PROJECT_REF}.supabase.co/rest/v1` |
| Auth headers | **both** required — `apikey: {SUPABASE_SERVICE_ROLE_KEY}` AND `Authorization: Bearer {SUPABASE_SERVICE_ROLE_KEY}`. Missing either → rejected. |
| Content type | `Content-Type: application/json` |
| Create/upsert | `POST .../{table}?on_conflict=<key column, e.g. Worker_WID>` with header `Prefer: resolution=merge-duplicates,return=representation` and body a **bare JSON array** `[{...fields...}]` — no `records`/`fields` envelope, that was Airtable's shape |
| Read/filter | `GET .../{table}?{column}=eq.<value>&select=*` |
| Delete | requires an explicit filter — PostgREST rejects a filter-less `DELETE` outright (`400: DELETE requires a WHERE clause`) |

`{SUPABASE_URL}` (= `https://{SUPABASE_PROJECT_REF}.supabase.co`) and `{SUPABASE_SERVICE_ROLE_KEY}` are in
your `.env`. Column names are quoted mixed-case in the DB (`config/supabase_schema.sql`) but work
unquoted in URLs/JSON keys — no extra encoding needed for any of `Worker_WID`, `Manager_WID`, `field_key`.
One table's name changed shape on migration: Airtable's `Cases & Audit Log` (space + `&`, needed a table
ID to avoid URL-encoding bugs) is `Cases_Audit_Log` in Supabase — plain underscore, no encoding gymnastics
needed at all.

### §B — Slack is native; Typeform is native but poll-based, not push-webhook
Slack send (`2.1.3`) uses the native Slack connector, posting to a channel **ID** (not name) — connected
in `0.1.4`. Typeform (`1.1.5`) uses the native Typeform connector, but Auto implements it as **scheduled
polling**, not an instant push webhook — a single poll can return zero, one, or several new submissions at
once. OP-01's existing steps (`1.1.1`–`1.1.4`) are built and tested as single-submission-in,
single-outcome-out; per `1.1.5`, a small **Parent Workflow** polls Typeform and calls OP-01 once per
individual submission returned, so OP-01 itself never has to change to handle a batch.

### §C — Retry + demo_mode (folds in task `0.2.4`)
Every **write-side** step (Supabase write, Slack send) wraps its call in this retry logic — identical
shape regardless of target. This implements `0.2.4` for OP-01 and OP-04 at the same time — mark `0.2.4`
Done once both are built and the demo_mode toggle is verified.

1. Read `policy_config` row `field_key = "demo_mode"` → boolean `demo_mode`.
2. If `demo_mode` is `true`, read row `field_key = "retry_demo_profile"` → `{max_attempts:1, backoff_seconds:[]}`.
   Else read row `field_key = "retry"` → `{max_attempts:3, backoff_seconds:[5,20,60]}`.
3. Attempt the call. On **any** failure (network error or non-2xx HTTP status), wait
   `backoff_seconds[attempt_index]` seconds (0 if the list is shorter/empty) and retry, up to
   `max_attempts` total attempts.
4. If all attempts fail → escalate to the Workbench with the task-specific integration-failure tag and
   full case context, then stop (or, for OP-04's Slack failure, continue to the audit-log write — see `2.1.3`).

> Testing note: with `demo_mode` **off**, a failing write runs 3 attempts with 5s/20s/60s waits (~85s
> total) before escalating — that is the behavior to observe for the retry AC. With `demo_mode` **on**, it
> fails once immediately (no wait) then escalates — that is the `0.2.4`/`RISKS.md R-23` fast-path.

### §D — as_of_date
Any "today"/day-count math reads `policy_config` row `field_key = "as_of_date"`. If its value is null/empty
→ use the live current date. Else → use the pinned date (used for tests/demo recording). Never call an
implicit system clock directly.

### §E — Shared reference values

| Thing | Value |
|---|---|
| Supabase tables (§A) | `Workers`, `Manager_Directory`, `policy_config`, `Onboarding_Tasks`, `Provisioning_Integration`, `Peakon_Engagement`, `Cases_Audit_Log` — all 7, Airtable fully deprecated |
| Manager-nudge channels (by `Manager_Directory.Org`) | Finance `C0BJA0P1M6V` · Sales `C0BJBQ02U2Y` · Ops `C0BHSMV328P` · Engineering `C0BJ4PYGV5K` · People `C0BJ4PZ8961` |
| IT-escalation channel | `C0BJ839B24A` |
| Confidential HR channel | `C0BK2CRJ596` |
| `policy_config` shape | columns `field_key` / `category` / `value` / `justification`; read the `value` column of the matching `field_key` row. `manager_channel_by_org` `value` is a JSON string. |
| Known-good test manager | Name `Kevin Goh`, `Manager_WID` `006140bc-6dbd-2df9-29ec-9b1114eca3ab`, Org `Sales` → channel `C0BJBQ02U2Y` |

### §F — Assumptions flagged in this guide (design-fill beyond the frozen spec)
These are calls made where the spec's input contracts don't fully pin down a template/field source. They
are reasonable defaults, safe to change — search "ASSUMPTION" in this doc to review each in context.

| # | Where | Call made |
|---|---|---|
| 1 | `2.1.2` `requested_on` | Not in OP-04 inputs; pulled from the matching reason's `task_or_resource_ref`/`detail` if present, else rendered `"unknown"`. |
| 2 | `2.1.2` `case_link` | Optional OP-04 input `workbench_case_link` if provided; else a plain text reference `"Case {case_id} — see Cases_Audit_Log"` (revised, `DECISIONS.md` ADR-001 second amendment — Supabase has no Airtable-style automatic record URL to fall back to). |
| 3 | `2.1.4` `case_id` | A UUID generated at OP-04 start, written into both the message templates and `Cases_Audit_Log.case_id` (already the table's primary key, `config/supabase_schema.sql` — no field to add). |
| 4 | `1.1.4` Worker_WID | New hires get a generated UUID v4 as `Worker_WID`; the write always upserts on `Worker_WID`, so create vs update is decided by whether that WID already exists. |

### §G — Platform-capability checks (verify these exist in Auto before relying on them)
| Capability | Used by | If unavailable |
|---|---|---|
| Generate a UUID / random ID | `1.1.4` (new Worker_WID), `2.1.4` (case_id) | Fall back to a timestamp + employee_id composite string as the ID. |
| Per-step retry with configurable wait, or a loop + wait step | §C retry everywhere | Use Auto's built-in step-retry with a fixed 3 attempts if custom backoff isn't supported; note the backoff won't match 5/20/60 exactly. |
| Invoke/call another Operator as a step, passing named inputs, once per loop iteration | `1.1.5` Parent Workflow → OP-01 | If unsupported, fall back to wrapping OP-01's existing steps in a "for each submission" loop inside one Operator instead of two — this touches already-tested logic, so re-run all of `1.1.6`'s test cases afterward if you take this path. |

---

## OP-01 — Epic 1.1 (Intake & Normalization), continued

Recap of what's already built (`1.1.1`–`1.1.3`): a manual/test trigger accepting the intake fields → field
validation (3 hard-required fields, optional-field data-quality notes) → date parse + manager resolution →
fuzzy-dedup producing a placeholder output of `intake_result: will_create | will_update` (or an
`intake_possible_duplicate` escalation). The steps below replace that placeholder.

### `1.1.4` — Supabase write + retry/escalation

**Prompt:**
```
Goal: every intake ends in exactly one outcome — a Worker row is created or
updated in Supabase, or the record is escalated to the Workbench with full
context. Nothing is ever silently dropped.

Continue building "OP-01 Intake & Normalization". Replace the placeholder final
step (the one that outputs intake_result: will_create / will_update) with the
Supabase write step below. Keep everything before it unchanged.

Context from earlier steps you can use: the normalized field values, the parsed
Hire_Date, the resolved Manager_WID and Manager_Org, and the dedup decision
(intake_result = "will_update" with a matched_worker_wid, OR "will_create").

STEP — Write the normalized Worker to Supabase (custom REST API, not a native
action; use the Supabase REST credential, §A — NOT the old Airtable credential
or its leftover "Workers" table, which are fully deprecated).

1. Determine the Worker_WID to write:
   - If intake_result = "will_update": use the matched_worker_wid from the dedup
     step.
   - If intake_result = "will_create": generate a new UUID v4 and use that as
     the Worker_WID.

2. Build the record fields object from the normalized values (only include
   fields that are present; leave unknown optional fields out or as ""):
   Worker_WID, Legal_Name, Preferred_Name, Business_Title, Job_Profile,
   Job_Family, Location, Worker_Type, Time_Type, FTE, Email_Work,
   Manager_Name, Manager_WID, Cost_Center, Position_ID, and Hire_Date
   formatted as YYYY-MM-DD.

3. Read policy_config for the retry profile (this write is a write-side action;
   policy_config is also on Supabase now, same credential as this step):
   - Read the row where field_key = "demo_mode". If its value is true, read the
     row field_key = "retry_demo_profile" (max_attempts 1, no backoff). Else read
     field_key = "retry" (max_attempts 3, backoff_seconds [5,20,60]).

4. Send the write as an upsert so create and update share one path:
     POST https://{SUPABASE_PROJECT_REF}.supabase.co/rest/v1/Workers?on_conflict=Worker_WID
     Headers: apikey: {SUPABASE_SERVICE_ROLE_KEY},
       Authorization: Bearer {SUPABASE_SERVICE_ROLE_KEY},
       Content-Type: application/json,
       Prefer: resolution=merge-duplicates,return=representation
     Body: [ { ...the fields object from step 2... } ]
   (A bare JSON array — no "records"/"fields" wrapper; that's Airtable's shape,
   not Supabase's.) Because the merge key is Worker_WID, a matched existing WID
   updates that row and a freshly generated WID creates a new row.

5. Retry on ANY failure (network error or non-2xx HTTP response): wait
   backoff_seconds[attempt index] seconds between attempts (0 if none), up to
   max_attempts total attempts.

6. If the write succeeds (2xx): output the final result
     { status: <"created" if will_create else "updated">,
       worker_wid: <the Worker_WID written>,
       dedup_confidence: <from the dedup step>,
       data_quality_notes: <from the validation step> }

7. If all attempts fail: escalate to the Workbench, tagged
   "intake_integration_failure" (this tag is distinct from the business-logic
   validation tag on purpose, for audit clarity), with case context containing
   the full normalized record that failed to write and the last error message.
   Do not silently drop the record.
```

**Simulate the failure for testing:** temporarily change the write step's table from `Workers` to a
nonexistent name like `Workers_FAIL` in the URL (verified live: Supabase returns `404 PGRST205 — Could not
find the table 'public.Workers_FAIL'` → treated as a failure, same mechanism as Airtable's 404). Run,
observe the retry behavior, then revert the table name.

**Test cases:**

| # | Scenario | Setup | Expected outcome |
|---|---|---|---|
| 1 | Create new hire | Valid new hire (name not in Workers), `demo_mode` off, table correct | New `Workers` row created; final output `status: created`, `worker_wid` = a new UUID |
| 2 | Update existing hire | Inputs that dedup classifies `will_update` (name-variant of an existing worker, hire date within 3 days) | Existing row updated in place (no duplicate created); output `status: updated`, `worker_wid` = matched WID |
| 3 | Integration failure → retry → escalate (production) | Table set to `Workers_FAIL`, `demo_mode` **off** | 3 attempts with ~5s/20s/60s waits (~85s), then Workbench escalation tagged `intake_integration_failure` with the record in context |
| 4 | Integration failure fast-path (demo) | Table set to `Workers_FAIL`, `demo_mode` **on** | 1 attempt, no wait, then the same `intake_integration_failure` escalation — confirms `0.2.4` |

> After case 3/4, revert the table name to `Workers` and re-run case 1 to confirm the happy path still writes.

---

### `1.1.5` — Typeform intake, live path (Parent Workflow + unchanged OP-01)

**Platform reality (discovered while building this task):** Auto's Typeform integration polls on a
schedule rather than pushing an instant webhook, and one poll can return multiple new submissions at once.
OP-01's existing steps are built and tested for exactly one submission in, one outcome out (create /
update / escalate) — see `1.1.1`–`1.1.4`. To keep that already-tested logic untouched, this task builds a
small **Parent Workflow** that does the polling and hands each submission to OP-01 individually, one call
per submission. OP-01 itself is not modified.

**Capability check first:** confirm Auto can invoke one workflow/Operator from another as a step, passing
named inputs, inside a loop over an array (see §G). If it can't, fall back to wrapping OP-01's existing
steps in a "for each submission" loop inside a single Operator instead — but that touches already-tested
logic (`1.1.1`–`1.1.4`), so re-run all of `1.1.6`'s test cases afterward if you take that path.

**Prompt — Parent Workflow (build as a new Operator, e.g. "OP-01 Typeform Intake Poller"):**
```
Goal: every new Typeform intake submission — however many arrive in one poll —
ends up processed through OP-01 exactly once, with OP-01 itself unchanged.

Build a new Operator, "OP-01 Typeform Intake Poller".

1. Trigger: the native Typeform poll trigger, on the intake form created in
   task 0.1.3, on Auto's default/shortest available poll interval.

2. For each individual submission returned by one poll (zero, one, or many):
   call OP-01 ("OP-01 Intake & Normalization") once, passing that submission's
   answers mapped onto OP-01's existing input variable names:
     Legal_Name, Hire_Date, Manager_Name, Manager_WID, Business_Title,
     Job_Profile, Job_Family, Location, Worker_Type, Time_Type, FTE,
     Email_Work, Cost_Center, Position_ID.
   Map each Typeform question to its variable by the form's field ref/label.
   Any OP-01 field the form does not collect maps to an empty string (OP-01's
   own validation step already treats blank optional fields as fine; only the
   3 hard-required fields — Legal_Name, Hire_Date, and one manager identifier —
   gate the record).

3. If a poll returns zero submissions, do nothing that run.

4. Do not add any business logic here — validation, date parsing, manager
   resolution, dedup, and the Supabase write all stay inside OP-01, unchanged.
   This workflow's only job is polling and fan-out.
```

**Field-mapping check:** open your Typeform form and confirm each collected question maps to the right
variable above. The 3 hard-required must be present as form fields: `Legal_Name`, `Hire_Date`, and one of
`Manager_Name`/`Manager_WID`.

**Test cases:**

| # | Scenario | Submit via live Typeform | Expected outcome |
|---|---|---|---|
| 1 | Live clean intake, single submission | Legal_Name = a new name, Hire_Date = `2026-06-15`, Manager_Name = `Kevin Goh`, other fields as available | Within one poll cycle, a normalized `Workers` row appears (Sales manager resolved); no escalation |
| 2 | Live intake missing required | Submit with Hire_Date left blank (if the form allows) | Workbench escalation tagged `intake_validation`, `missing_fields` includes `missing_hire_date` |
| 3 | Live intake, sparse optional fields | Only the 3 required + a couple optionals filled | Row still created; missing optionals stored blank, no escalation |
| 4 | Batched poll, multiple submissions | Submit 2–3 distinct clean intakes in quick succession, before the next poll fires | All submissions from that one poll each produce their own correct `Workers` row — none dropped, none merged into each other |

> `1.1.5` AC ("a live Typeform submission produces a correctly normalized Workers row within a few
> seconds") assumed a push webhook; under polling, latency is bounded by the poll interval instead. Check
> Auto's actual poll interval when you build this — if it's materially longer than "a few seconds," flag it
> back so `TASKS.md`'s AC wording and `DEMO.md`'s live-submission beat (if it shows the wait) can be updated
> to say "within one poll cycle" instead of an implied instant.

---

### `1.1.6` — Unit test OP-01 (5 hand-picked cases, no build)

No new building — this is the end-to-end verification of the whole OP-01. Run all 5 through the live
(or manual) trigger and confirm the exact outcome. Substitute the **bracketed** values with real data from
your Supabase `Workers` table (an existing worker's name for the duplicate case).

| # | Case | Inputs | Expected outcome |
|---|---|---|---|
| 1 | Clean new hire | Legal_Name = `Ravi Menon` (or any name absent from Workers), Hire_Date = `2026-06-15`, Manager_Name = `Kevin Goh` | `Workers` row **created**, manager resolved to Sales, no escalation |
| 2 | Name-variant duplicate | Legal_Name = `[casing/spacing variant of an existing worker, e.g. "  faizal  nair "]`, Hire_Date = `[within 3 days of that worker's Hire_Date]`, Manager_Name = `Kevin Goh` | Existing row **updated** (no duplicate); `dedup_confidence` ≥ 0.90 |
| 3 | Unparseable date | Legal_Name = `Ravi Menon`, Hire_Date = `banana`, Manager_Name = `Kevin Goh` | Escalate `intake_validation`, note: no accepted date format matched |
| 4 | Ambiguous manager (0 candidates) | Legal_Name = `Ravi Menon`, Hire_Date = `2026-06-15`, Manager_Name = `Nonexistent Person`, Manager_WID blank | Escalate `intake_validation`, note: Manager_Name matches no Manager_Directory row |
| 5 | Missing required field | Legal_Name blank, Hire_Date = `2026-06-15`, Manager_Name = `Kevin Goh` | Escalate `intake_validation`, `missing_fields` includes `missing_legal_name` |

> These are the 3 distinct escalation types (validation-date, manager-unresolved, missing-field) plus the
> create and update happy paths — the exact 5 the `1.1.6` AC calls for. The `>1 candidate` ambiguous-manager
> variant is intentionally covered by the 0-candidate form here, since the sample `Manager_Directory` has no
> natural name collision (noted earlier; can be added later with a synthetic test-only row before Phase 3).

---

## OP-04 — Epic 2.1 (Escalation & Notification), continued

Recap of what's already built (`2.1.1`): a manual/test trigger accepting `case_type`, `employee_id`,
`worker_wid`, `reasons[]`, `internal_case_payload?` → channel/manager resolution producing a
`target_channel` (or an `op04_routing_unresolved` escalation) and a placeholder output. The steps below
replace that placeholder.

> **Check before continuing:** `2.1.2`'s templating step reads a `Workers` row that `2.1.1`'s
> channel/manager resolution already looked up (for `preferred_name`). If `2.1.1` was built pointing at
> the old Airtable `Workers`/`Manager_Directory` tables, repoint both lookups to Supabase (§A) before
> building `2.1.2` — Airtable is now fully deprecated, and a stale pointer here reads
> absent/frozen-in-time data silently rather than failing loudly.

> **Confidentiality is the highest-stakes rule in this Operator.** A real disclosure leaking into a
> manager/IT message or the general audit log is "the single worst failure mode in the whole build"
> (`OPERATORS.md` OP-03 Retry). Every prompt below is explicit: `internal_case_payload.comment_text` (and
> `.driver`) must **never** be interpolated into any message or written to any audit field. Only
> `.milestone` from the payload may be used, and only in the confidential-channel message.

### `2.1.2` — Message templating

**Prompt:**
```
Goal: render an outbound notification message per case_type from
policy_config templates, with zero leakage of confidential content.

CRITICAL CONSTRAINT — apply this before writing any templating logic:
internal_case_payload.comment_text and internal_case_payload.driver must NEVER
be interpolated into any message, for any case_type. manager_nudge and
it_escalation must not reference internal_case_payload at all. Only
internal_case_payload.milestone may be used, and only in the
confidential_disclosure message.

Continue building "OP-04 Escalation & Notification". At the very start of the
Operator (right after the trigger, before channel resolution), add a step that
generates a case_id as a UUID v4 and stores it for use in both the message and
the later audit-log write.

Then replace the placeholder final step (from the 2.1.1 channel-resolution build)
with the message-templating step below. It runs after target_channel is resolved.

STEP — Render the outbound message from policy_config templates.

1. Read the needed policy_config template rows (value column):
   - field_key = "manager_nudge"  -> manager template
   - field_key = "it_escalation"  -> IT template
   - field_key = "confidential_alert" -> confidential template
   NOTE the mapping: case_type "confidential_disclosure" uses the template whose
   field_key is "confidential_alert". case_type "workbench_log" has NO template
   (it is log-only; skip templating entirely for it and go straight to the
   audit-log step built next session).

2. Assemble these interpolation values (only from non-sensitive sources):
   - case_id: the UUID generated at the start of this Operator.
   - employee_id: from input.
   - reason_summary: join the detail text of every item in input reasons[]
     with "; ".
   - preferred_name: for manager_nudge, read from the Workers row already looked
     up during channel resolution (Preferred_Name column).
   - day_number: for manager_nudge, compute floor(as_of_date - Workers.Hire_Date
     in days) + 1, minimum 1, where as_of_date follows the policy_config
     as_of_date rule (null = live today).
   - resource_list: for it_escalation, join the non-empty task_or_resource_ref
     values from input reasons[] with ", ".
   - requested_on: for it_escalation, use a requested-date found in the matching
     reason's task_or_resource_ref or detail if present; otherwise render the
     literal "unknown".
   - milestone: for confidential_disclosure ONLY, read
     internal_case_payload.milestone.
   - case_link: for confidential_disclosure ONLY, use the input
     workbench_case_link if provided; otherwise render the literal text
     "Case {case_id} — see Cases_Audit_Log" (Supabase has no Airtable-style
     automatic record URL to fall back to, so this resolves fully here — no
     later step needs to fill anything in).

3. Render the template for the case_type by substituting {{...}} placeholders
   with the values above.

4. CRITICAL confidentiality rules, enforce all:
   - NEVER interpolate internal_case_payload.comment_text or .driver into ANY
     message.
   - For manager_nudge and it_escalation, do not reference internal_case_payload
     at all.
   - For confidential_disclosure, the message must contain only employee_id,
     milestone, and case_link — no comment text, no survey answer content.

5. Output a placeholder result carrying { case_id, case_type, target_channel,
   rendered_message } for the Slack-send step (next session).
```

**Template field-source reference** (what fills each `{{placeholder}}`):

| Template (`case_type`) | Placeholders | Sources |
|---|---|---|
| `manager_nudge` | `preferred_name`, `employee_id`, `day_number`, `reason_summary`, `case_id` | Workers row + input + computed |
| `it_escalation` | `employee_id`, `reason_summary`, `resource_list`, `requested_on`, `case_id` | input reasons + ASSUMPTION #1 for `requested_on` |
| `confidential_alert` (for `case_type` `confidential_disclosure`) | `employee_id`, `milestone`, `case_link` | input + `internal_case_payload.milestone` + ASSUMPTION #2 for `case_link` |

**Test cases:**

| # | Scenario | Input | Expected outcome |
|---|---|---|---|
| 1 | Manager nudge renders | `case_type` = `manager_nudge`, valid `worker_wid` (Kevin Goh's report), reasons = `[{code:"LOW_ENGAGEMENT_SCORE",detail:"Score 2 at day 30"}]` | Rendered message names the hire, day-of-90, and reason; contains `case_id`; no payload text |
| 2 | IT escalation renders | `case_type` = `it_escalation`, reasons = `[{code:"PROVISIONING_DELAYED",detail:"Laptop still Requested",task_or_resource_ref:"Laptop"}]` | Message lists `Laptop` as resource; `requested_on` = `unknown` (no date supplied); has `case_id` |
| 3 | Confidential renders comment-free | `case_type` = `confidential_disclosure`, `internal_case_payload` = `{comment_text:"SENTINEL_SECRET_HEALTH_XYZ", driver:"Wellbeing", milestone:"Day 30"}` | Message mentions milestone `Day 30` + a case link, and **must NOT** contain `SENTINEL_SECRET_HEALTH_XYZ` or `Wellbeing` |
| 4 | Leak-guard on manager path | `case_type` = `manager_nudge` **with** `internal_case_payload` = `{comment_text:"SENTINEL_SECRET_HEALTH_XYZ",...}` present | Rendered manager message **must NOT** contain `SENTINEL_SECRET_HEALTH_XYZ` (the `2.1.2` AC's automated assertion) |

> Case 3 and 4 are the confidentiality gate. Use the literal sentinel string and search the rendered
> output for it — its absence is the pass condition.

---

### `2.1.3` — Slack send + retry/escalation

**Prompt:**
```
Goal: every notification attempt ends with a recorded outcome — sent, or
failed-and-escalated — and the audit-log step always runs afterward, even when
the Slack send fails.

Continue building "OP-04 Escalation & Notification". Replace the placeholder
result from the templating step with the Slack-send step below. It runs for
case_types manager_nudge, it_escalation, and confidential_disclosure. For
case_type workbench_log, skip sending entirely and pass straight through to the
audit-log step (next session) — workbench_log never posts to Slack.

STEP — Send the rendered message to Slack (native Slack connector).

1. Read the retry profile from policy_config exactly as the OP-01 write does:
   demo_mode true -> retry_demo_profile (1 attempt, no backoff); else retry
   (3 attempts, backoff 5/20/60s).

2. Post rendered_message to the resolved target_channel (a Slack channel ID)
   using the native Slack "send message" action.

3. Retry on ANY failure (Slack API error or non-success response): wait
   backoff_seconds[attempt index] between attempts, up to max_attempts total.

4. On success (message posted): set outcome = "sent" and carry
   { case_id, case_type, target_channel, outcome, channel_used: target_channel }
   forward to the audit-log step.

5. If all attempts fail: set outcome = "failed", escalate to the Workbench
   tagged "op04_notification_failure" with the case context — BUT still continue
   to the audit-log step afterward (do NOT stop before it). The audit trail must
   record that we tried to notify and failed. Carry outcome = "escalated" (Slack
   failed, routed to Workbench) into the audit-log step.
```

**Simulate the failure for testing:** temporarily set `target_channel` to an invalid ID like
`C000INVALID` (Slack returns `channel_not_found`). Run, observe retries + escalation + that the audit-log
step still runs, then revert.

**Test cases:**

| # | Scenario | Input | Expected outcome |
|---|---|---|---|
| 1 | Manager nudge sends | `manager_nudge`, valid channel resolved (Sales `C0BJBQ02U2Y`) | Message posts to the Sales channel; `outcome: sent` |
| 2 | Confidential sends to confidential channel | `confidential_disclosure` | Comment-free alert posts to `C0BK2CRJ596`; `outcome: sent` |
| 3 | Slack failure → retry → escalate + audit still runs | Channel forced to `C000INVALID`, `demo_mode` off | 3 attempts, then Workbench escalation `op04_notification_failure`, **and** the audit-log step still executes with `outcome: escalated` |
| 4 | `workbench_log` skips Slack | `case_type` = `workbench_log` | No Slack post attempted; flows straight to audit-log step |

---

### `2.1.4` — Cases_Audit_Log write (every case type, incl. `workbench_log`)

**Prompt:**
```
Goal: every OP-04 run produces exactly one audit-log row — for every
case_type, including workbench_log and failed sends — and that row never
contains internal_case_payload content.

Continue building "OP-04 Escalation & Notification". Add the final step below —
the audit-log write. It runs for EVERY case_type, including workbench_log and
including cases where the Slack send failed/escalated. Exactly one audit row per
Operator run.

STEP — Write one case record to Supabase's Cases_Audit_Log table (custom REST
API, not native; use the Supabase REST credential, §A — NOT the old Airtable
credential or its leftover "Cases & Audit Log" table, which are deprecated).

1. Build the audit fields:
   - case_id: the UUID generated at the start of this Operator (this is also
     Cases_Audit_Log's primary key — no separate field needs adding).
   - timestamp: the current time (or as_of_date if policy_config as_of_date is
     pinned), ISO 8601.
   - employee_id: from input.
   - case_type: from input (manager_nudge | it_escalation |
     confidential_disclosure | workbench_log).
   - channel: the target_channel actually used; for workbench_log use the
     literal "workbench"; for a Slack failure that escalated, use "workbench".
   - policy_rules_fired: join the code values of input reasons[] with ", "
     (e.g. "MISSING_DAY_ONE_ACCESS, STALLED_COMPLIANCE_DOC").
   - outcome: "sent" | "escalated" | "failed" as set by the send step; for
     workbench_log use "escalated".
   IMPORTANT: never write comment_text, driver, or any internal_case_payload
   content into any audit field. The audit log is read by non-technical
   reviewers and must stay disclosure-free even for confidential cases — only the
   case's existence, milestone-free, is recorded.

2. Write it:
     POST https://{SUPABASE_PROJECT_REF}.supabase.co/rest/v1/Cases_Audit_Log?on_conflict=case_id
     Headers: apikey: {SUPABASE_SERVICE_ROLE_KEY},
       Authorization: Bearer {SUPABASE_SERVICE_ROLE_KEY},
       Content-Type: application/json,
       Prefer: resolution=merge-duplicates,return=representation
     Body: [ { ...the audit fields from step 1... } ]
   (A bare JSON array, not an Airtable-style "records"/"fields" wrapper. Every
   run generates a fresh case_id, so this upsert behaves as a plain insert in
   practice — on_conflict is included only for safety against an accidental
   re-run with the same case_id.)

3. Apply the same write-side retry profile (demo_mode-aware) as OP-01/2.1.3. If
   the audit write itself fails after retries, escalate to the Workbench tagged
   "op04_audit_write_failure" (the audit trail failing is itself a governance
   event worth a human's attention).

4. Output the final Operator result:
   { status: <outcome>, case_record_id: <case_id>,
     channel_used: <channel> }
```

> `case_link` (used by `2.1.2`'s confidential template) no longer depends on this step — it resolves
> fully in `2.1.2` itself now, either from `workbench_case_link` or a plain-text case reference, since
> Supabase has no Airtable-style automatic record URL to fill in after the fact (`DECISIONS.md` ADR-001
> second amendment, Consequence 3).

**Test cases:**

| # | Scenario | Input | Expected audit row |
|---|---|---|---|
| 1 | Manager nudge logged | `manager_nudge`, sent | 1 row: `case_type` manager_nudge, `channel` = Sales ID, `policy_rules_fired` listing the codes, `outcome` sent |
| 2 | IT escalation logged | `it_escalation`, sent | 1 row: channel = `C0BJ839B24A`, outcome sent |
| 3 | Confidential logged, comment-free | `confidential_disclosure` with sentinel payload | 1 row: channel = `C0BK2CRJ596`, outcome sent, and **no field contains** `SENTINEL_SECRET_HEALTH_XYZ` |
| 4 | Workbench log (direct escalation) | `workbench_log` | 1 row: `channel` = `workbench`, `outcome` escalated, no Slack sent |
| 5 | Slack-failure case still logs | `manager_nudge`, channel forced invalid | 1 row written with `channel` = `workbench`, `outcome` escalated (audit survives the send failure) |

---

### `2.1.5` — Unit test OP-04 (6 cases, no build)

Run all 6 end-to-end and confirm both the routing/send outcome and the resulting single audit row. Use a
`worker_wid` that reports to Kevin Goh for the manager_nudge cases (substitute a real one).

| # | Case | Input | Expected outcome | Expected audit row |
|---|---|---|---|---|
| 1 | manager_nudge | valid worker → Sales | Posts to `C0BJBQ02U2Y`, `sent` | manager_nudge / Sales channel / `sent` |
| 2 | it_escalation | any | Posts to `C0BJ839B24A`, `sent` | it_escalation / IT channel / `sent` |
| 3 | confidential_disclosure | sentinel payload | Comment-free alert to `C0BK2CRJ596`, `sent` | confidential / conf. channel / `sent`, **no sentinel anywhere** |
| 4 | workbench_log | any | No Slack; logged only | workbench_log / `workbench` / `escalated` |
| 5 | Unresolved routing | `manager_nudge`, worker with blank `Manager_WID` | Escalate `op04_routing_unresolved`, no Slack | (per your routing-escalation logging choice) |
| 6 | Slack failure | `manager_nudge`, channel forced `C000INVALID` | Retry → escalate `op04_notification_failure` | manager_nudge / `workbench` / `escalated` |

> `2.1.5` AC: all 4 case types + 1 unresolved-routing + 1 simulated-Slack-failure produce correct
> routing/escalation and a correct audit entry. Case 3 doubles as the final confidentiality check.

---

## After building

Mark each task Done in `TASKS.md` only after its own test cases pass. Building `1.1.4` + `2.1.3` + `2.1.4`
with the demo_mode-aware retry (§C) also completes **`0.2.4`** — mark it Done once the demo_mode toggle is
verified on both Operators (test `1.1.4` cases 3 vs 4).

**Dependency reality:** OP-04 (`2.1.x`) is fully buildable now — it takes a manual test payload and does not
need OP-01 or ORCH-01 to exist. The only cross-Operator coupling is `case_link`/Workbench confidential
routing, which is ORCH-01's job (Epic 2.2) and is handled here via the ASSUMPTION #2 fallback until then.
