# DECISIONS.md — Architectural Decision Records

**Reads as prerequisite:** `CONTEXT.md`, `MASTER_PLAN.md`
**Purpose:** every non-obvious design choice referenced elsewhere in this package, with alternatives
considered and reasoning, so a future reader (or Opus, mid-implementation) never has to guess *why*.
Each ADR is referenced by ID (`ADR-0xx`) from other documents rather than re-explained there.

**Format:** Decision · Alternatives Considered · Reasoning · Tradeoffs · Future Considerations.

---

## ADR-001 — System of Record: Airtable

**Decision:** Use Airtable as the sole system of record for all five dataset tables plus the derived
audit log.

**Alternatives Considered:**
- **Supabase** (Postgres-backed, explicitly allowed per `CONTEXT.md` §5) — stronger for complex
  relational queries and would suit a Round 2 coded console well, but has a steeper setup cost for a
  no-code Round 1 build and a less mature native Auto integration surface as of the rules' published
  palette.
- **SharePoint/OneDrive as a "park the file" document store** (`CONTEXT.md` §9 alternative pattern) —
  viable per the rules, but treats the dataset as a file to be pulled rather than a queryable live
  system, making per-hire reads (OP-02/OP-03's core operation) more awkward to express in a no-code
  workflow than a proper table-based query.
- **A generic spreadsheet tool without Auto's native integration** — rejected outright; would require
  API Operator (Path 2), adding unnecessary build complexity for zero benefit over Airtable's native
  path.

**Reasoning:** Airtable's table+linked-record model maps almost 1:1 onto the dataset's existing 5-sheet
structure (`CONTEXT.md` §12), has a native Auto integration path (fastest route, `CONTEXT.md` §5 Path
1), and is explicitly named as an approved Google alternative in both the rules and the problem
statement.

**Tradeoffs:** weaker for complex relational joins than a real relational database; acceptable because
no Operator in this design performs a multi-table join beyond what ORCH-01's fan-in already does at the
application layer (`ARCHITECTURE.md` §2).

**Future Considerations:** if Round 2's coded console needs heavier query patterns, migrating the read
side to Supabase while keeping Airtable as the write-side system of record is a viable incremental path
— not designed now, per the Round 2 scope boundary (`ARCHITECTURE.md` §10).

**Amendment (Round 1, in progress):** the incremental path above started earlier than planned, and on
the write side too, not just reads. `Workers`, `Manager_Directory`, and `policy_config` — the three
tables OP-01 touches — now live on Supabase (`config/supabase_schema.sql`), written via
`scripts/seed_loader/supabase_client.py` and Auto's custom-REST path (`AUTO_BUILD_GUIDE.md` Conventions
§A). `Onboarding_Tasks`, `Provisioning_Integration`, `Peakon_Engagement`, and `Cases & Audit Log` are
deliberately **not** migrated yet:
- The first three belong to OP-02/OP-03, which aren't built — no forcing function to move them before
  their own Operators exist.
- `Cases & Audit Log` is held back specifically because `TASKS.md` `0.0.4` already confirmed OP-05's
  Round 1 console as an **Airtable Interface** sitting on top of it (`ARCHITECTURE.md` §1 `DASH` node).
  Moving that table would reopen `0.0.4` and require a different console (Airtable Interfaces have no
  Supabase/Postgres equivalent in this workspace) — a decision deliberately deferred until Epic 4.1 is
  actually being built, not made preemptively here.

This makes Airtable the system of record for 4 of 7 tables and Supabase for the remaining 3, both reached
through the same Path-2-custom-REST pattern in Auto (no native connector for either, per spike `0.0.3`).
Every other document in this package that names "Airtable" as *the* system of record should be read with
this split in mind; only `INTEGRATIONS.md` §1 and `ARCHITECTURE.md` §1/§7 have been updated with the
explicit caveat, since they're the load-bearing summaries — per-Operator sections elsewhere (`OPERATORS.md`
OP-02/OP-03/OP-04/OP-05) are still accurate as written because they only ever touch the still-Airtable
tables.

---

## ADR-002 — Channel Integration: Slack with a Separate Confidential Channel

**Decision:** Use Slack for both manager nudges (routed by `Org`) and confidential HR alerts (a single,
separately access-controlled channel, not routed by `Org`).

**Alternatives Considered:**
- **Microsoft Teams / Outlook** — equally eligible per `CONTEXT.md` §5, and Discord chat evidence
  (`CONTEXT.md` §9's linked transcripts) suggests some participants defaulted to Teams/Outlook since
  Google integrations are off-limits; Slack was chosen instead for its simpler no-code Auto setup and
  because a single-workspace, multi-channel model maps cleanly onto the "public manager channel +
  private confidential channel" pattern needed here.
- **One single channel for everything, filtered by @mention** — rejected: this would put confidential
  content in the same channel history as routine nudges, which cannot satisfy the "never leaks into the
  general report" requirement even if individual messages are theoretically hideable; a structurally
  separate channel is a stronger, simpler-to-audit guarantee than a filtering convention.
- **Org-routed confidential channels (one per Org, like manager nudges)** — rejected: fragmenting
  confidential routing by Org multiplies the number of people with access to sensitive material for no
  functional benefit; a single small channel is the more defensible confidentiality posture.

**Reasoning:** structural separation (different channel, not different message formatting) is a
guarantee that survives even if someone forgets a formatting rule — the confidentiality property lives
in the routing architecture, not in message content discipline.

**Tradeoffs:** requires maintaining channel membership for the confidential channel as an ongoing
governance task in a real deployment; acceptable and arguably correct — confidential access *should*
require deliberate membership management.

**Future Considerations:** Round 2 could add a real access-control layer (Auto Manager Console
permissions) rather than relying on Slack channel membership alone; noted as a Round 2 forward item,
not designed now.

---

## ADR-003 — Forms Integration: Typeform for New-Hire Intake

**Decision:** Use Typeform as the live "a way in" intake path feeding OP-01.

**Alternatives Considered:**
- **A row directly in Airtable (skip a dedicated form tool)** — this alone would not add a distinct
  integration category, weakening gate margin (`MASTER_PLAN.md` §3); also less representative of a real
  HR coordinator's workflow, where intake is more naturally a form than a direct database edit.
- **Airtable's own form-view feature** (forms built into Airtable itself) — would not count as a
  separate, named integration category for gate purposes, since it's the same underlying system
  (Airtable) rather than a distinct connected tool.

**Reasoning:** Typeform is named explicitly in the rules' category list and in the problem statement's
own example ("a new hire added via a form or a row," `CONTEXT.md` §9), making it the most
rules-legible choice for this specific role.

**Tradeoffs:** one more system to provision and maintain credentials for; accepted because the gate
margin benefit (`INTEGRATIONS.md` §3 Qualification Gate Contribution) outweighs the setup cost, which is
small (`TASKS.md` 0.1.3, sized S).

**Future Considerations:** none — this integration's role doesn't change materially in Round 2.

---

## ADR-004 — Operator Decomposition: One Orchestrator, Five Operators

**Decision:** Decompose into OP-01 through OP-05 plus ORCH-01, rather than the gate-minimum of 1
Orchestrator + 2 Operators, and rather than two separate Orchestrators (one per trigger type).

**Alternatives Considered:**
- **Gate-minimum decomposition (2 Operators)** — e.g., one "assess risk" Operator and one "take action"
  Operator. Rejected: this would force OP-02/OP-03's genuinely distinct detection logic (structured
  onboarding data vs. free-text engagement/disclosure classification) into a single Operator, which
  both violates the single-responsibility principle (`ARCHITECTURE.md` §2) and removes the ability to
  demonstrate a true parallel fan-out, since one Operator can't meaningfully run "in parallel" with
  itself. It would also make the confidentiality contract (`DATA_FLOW.md` §7) harder to enforce
  structurally, since detection and the sensitive-payload boundary would live inside the same Operator
  as the notification logic instead of being cleanly separated.
- **Two Orchestrators (one event-triggered, one schedule-triggered)** — rejected per `ARCHITECTURE.md`
  §3.2: risks the two paths silently diverging in branching logic over time, and doubles the escalation
  surface a judge or teammate has to audit.
- **A single mega-agent** — explicitly disallowed by the gate itself (`CONTEXT.md` §5); not a real
  alternative, listed here only for completeness.

**Reasoning:** 5 Operators is the smallest decomposition that (a) keeps every Operator single-purpose,
(b) makes the parallel/branching/stateful gate criteria independently demonstrable rather than merely
claimed, and (c) isolates all external write side-effects (OP-04) from all detection logic (OP-02/OP-03)
and all read-only reporting (OP-05), which is what makes the audit trail bonus achievable without extra
work later.

**Tradeoffs:** more moving pieces to build and test than the gate strictly requires (`TASKS.md` Phase
1–2 is correspondingly larger than a minimal build would need). Accepted deliberately — see
`MASTER_PLAN.md` §3, margin-over-minimalism philosophy.

**Future Considerations:** OP-06+ can be added in Round 2 without renumbering (`ARCHITECTURE.md` §9).

---

## ADR-005 — Sensitive Disclosure Detection: LLM Classifier, Not Keyword Matching

**Decision:** OP-03 uses an LLM-based classifier with a narrowly-scoped prompt to detect sensitive
disclosures in free-text `Comment` fields, rather than a keyword/regex list.

**Alternatives Considered:**
- **Keyword/regex matching** (e.g., flag comments containing "health," "harassment," "confidential")
  — rejected: brittle against phrasing the team didn't anticipate (exactly the risk the hidden dataset
  is designed to expose, `CONTEXT.md` §4.3–§4.5), prone to both false negatives (a disclosure phrased
  without a trigger word) and false positives (routine comments that happen to contain a flagged word in
  an unrelated context) at a rate a hackathon team cannot realistically tune well in 48 hours.
- **No automated detection; always route every comment to a human** — rejected: defeats the purpose of
  automation entirely and would make OP-05's cohort reporting meaningless (nothing would ever be
  auto-classified as low-risk), failing the "business output" rubric line by producing no usable signal.

**Reasoning:** a classification task this semantically nuanced ("is this a personal/health/interpersonal
disclosure vs. routine feedback") is a better fit for a model's language understanding than a fixed
rule list, and Supervity Auto's native LLM step makes this available without adding a new external
integration (`INTEGRATIONS.md` summary note).

**Tradeoffs:** classifier calls have latency and non-zero failure rate, both addressed by the
fail-safe-to-confidential design (`OPERATORS.md` §OP-03 Retry Behavior) — the tradeoff is explicitly
accepted in exchange for correctness on the axis that matters most (never leaking a real disclosure).

**Future Considerations:** the confidence threshold (`disclosure_classifier_min_confidence`, default
0.75) should be revisited with real usage data if this reaches Round 2; documented as a config value
specifically so this revision requires no code change.

---

## ADR-006 — Reseeding Utility for Hidden-Dataset Robustness

**Decision:** Build a standalone, schema-driven (column-name-mapped) loading utility, independent of any
single Operator, used both for initial seeding and for the live hidden-dataset demo proof.

**Alternatives Considered:**
- **Manual, one-time data entry into Airtable** — rejected: not repeatable, cannot be re-run live during
  judging or the demo, and directly contradicts the rules' repeated warning against tuning to the public
  sample (`CONTEXT.md` §4.3–§4.5) since there would be no fast way to prove behavior on a different
  dataset.
- **Position-based (column-index) CSV mapping** — rejected: fragile against any structural variation in
  the hidden dataset (reordered or added columns), a stronger failure mode than the rules strictly
  promise won't happen, but cheap to defend against (`DATA_FLOW.md` §10).

**Reasoning:** this utility is the single artifact that makes Beat 6 of the demo (`DEMO.md` §2) possible
at all, and directly operationalizes the rules' most-repeated warning into a concrete, demoable
capability rather than a promise.

**Amendment (post-review correction — see `OPERATORS.md` §OP-01 scope note):** an earlier version of
this ADR and of `DATA_FLOW.md` §6 described the utility as running "the same shared normalization
module" as OP-01, implying literally shared runtime code between a no-code Auto workflow and a
standalone script. That is not achievable across the no-code/script boundary in Supervity Auto and has
been corrected: the utility is a **local script** (run by the team, not an Auto Operator) that
implements the **same documented rules** as OP-01 (text/date normalization) as an independent
implementation of one specification, not a shared module. The utility also does **not** run fuzzy-dedup
against existing Airtable rows during bulk seeding — the seed file's workers are already known-distinct
records, so a fuzzy-merge pass over them only risks a false merge for no benefit. Fuzzy dedup is reserved
for the live Typeform intake path (OP-01 only), where a genuinely ambiguous match is a real possibility.
Exact-`Employee_ID` duplicate rows within a single seed file are still deduped, by exact match, as part
of the utility's own load logic.

**Tradeoffs:** additional build effort (`TASKS.md` Phase 3, sized L) that a minimal submission could
skip; accepted because it is judged to be the highest-leverage robustness investment in the whole
project (`MASTER_PLAN.md` §10).

**Future Considerations:** none for Round 1; Round 2's Auto Runtime deployment will need an equivalent
but is out of scope until the starter repo is released.

---

## ADR-007 — Business Output Metric Definition: Proxy Metrics Over Unavailable Ground Truth

**Decision:** Operationalize "day-90 retention" as a leading-indicator risk score plus a measured
at-risk-hire catch rate, rather than claiming to measure retention directly.

**Alternatives Considered:**
- **Claim direct retention measurement anyway** (e.g., assume any hire without a "Probation decision =
  approved" record has left) — rejected: the dataset does not actually encode an attrition/termination
  outcome distinct from ordinary task lateness, so this would be an unsupported inference dressed up as
  a fact, which is exactly the kind of overclaim a judge cross-questioning the build (`DEMO.md` §8) would
  catch immediately, damaging credibility on the single highest-weighted rubric line (business output,
  40%).
- **Ignore the retention half of the metric entirely, report only task completion** — rejected: task
  completion alone doesn't address the "retention" half of the fixed outcome metric name
  (`CONTEXT.md` §9) at all, leaving an obvious gap a judge would immediately notice.

**Reasoning:** stating the modeling assumption openly (Assumption A-01, `MASTER_PLAN.md` §4.1) and
choosing a metric that is both computable from real data and a defensible proxy for the stated goal is
more credible than either overclaiming or ignoring half the brief.

**Amendment (post-review correction — see `OPERATORS.md` §OP-05):** the original choice of "at-risk
catch rate" as the *headline* metric was flawed independent of the retention-proxy question above: catch
rate measures whether the system acted on the cases it itself generated (routing acts on nearly every
detected case by construction, per `ARCHITECTURE.md` §6), which trends toward a self-report of "did my
automation run" rather than a business result — precisely the kind of claim `CONTEXT.md` §7's bar
("survives an enterprise buyer's cross-question") would puncture. The correction: **exposure rate**
("% of the active cohort currently showing ≥1 unresolved onboarding/provisioning risk," computed
directly from `Onboarding_Tasks`/`Provisioning_Integration`, independent of `Cases & Audit Log`) is now
the headline metric — a real, falsifiable number computed without reference to the system's own actions.
Catch rate is retained only as a secondary, supporting metric.

**Tradeoffs:** a proxy metric is inherently a weaker claim than a direct measurement; accepted as the
honest option given the data actually available, and explicitly surfaced as a talking point rather than
hidden (`DEMO.md` §8).

**Future Considerations:** if the hidden judging dataset *does* include an explicit outcome field not
present in the public sample, OP-05 should be checked for one at read time and use it preferentially —
noted as a defensive design point for `TASKS.md` 4.1.1 implementation, not a redesign.

---

## ADR-008 — Configuration Layer: External `policy_config`, Auto Policies/Insights Not Used

**Decision:** All thresholds, routing, and templates live in a single external `policy_config` object;
Supervity's built-in Auto Policies/Auto Insights modules are deliberately not used as the mechanism for
this logic.

**Alternatives Considered:**
- **Use Auto Policies as the threshold/routing mechanism** — rejected per the rules themselves
  (`CONTEXT.md` §5, rule 3.5): these are explicitly out of scope as prebuilt features for the core
  build, and teams are scored on defining and owning their own governance logic, not on using a policy
  module. Using it anyway would actively work against the "customizability" rubric line's actual intent.

**Reasoning:** the rules make this close to a non-decision, but it's recorded as an ADR because a future
implementer unfamiliar with rule 3.5 might otherwise reach for the seemingly-obvious built-in tool.

**Tradeoffs:** none of consequence — building a config object is not meaningfully harder than
configuring a built-in module, and it satisfies the rules' explicit intent.

**Future Considerations:** none.

---

## ADR-009 — Escalation Strategy: Centralized in ORCH-01, Not Duplicated per Operator

**Decision:** Detection Operators (OP-02, OP-03) return structured risk signals but do not themselves
decide to escalate a *business* finding to the Workbench — that decision is centralized in ORCH-01. They
do independently escalate their own *integration failures*.

**Alternatives Considered:**
- **Let each detection Operator decide its own escalation independently** — rejected: would scatter
  the confidentiality-first branching rule and the uncertainty-threshold rule (`ARCHITECTURE.md` §6)
  across multiple Operators, risking the two Operators disagreeing on when to escalate, and making the
  full escalation policy harder to audit in one place (working against the auditability bonus).

**Reasoning:** a single, centralized branching authority is both easier to reason about and easier to
demo/explain (`DEMO.md` Beat 2) than distributed decision-making, and matches the Orchestrator's
conceptual role as "the manager who coordinates" (`CONTEXT.md` §2.6).

**Tradeoffs:** ORCH-01 becomes the highest-complexity single component in the system (`TASKS.md` 2.2.3
is sized L); accepted, and mitigated by giving it the most thorough test coverage in the backlog
(`TASKS.md` 2.2.10).

**Future Considerations:** none.

---

## ADR-010 — Bonus Integration: GitHub Audit Mirror, Explicitly Non-Blocking

**Decision:** GitHub integration (auditability bonus) is built only after core phases are solid, and its
failure mode is designed to never affect core functionality (`INTEGRATIONS.md` §4 Failure Recovery).

**Alternatives Considered:**
- **Treat GitHub as a required integration from the start** — rejected: would add a 4th required
  integration with zero gate benefit (gate is already satisfied by 3), increasing build risk for no
  scoring guarantee (bonus points are not guaranteed the way gate/rubric points are).

**Reasoning:** matches the bonus-priority ordering in `MASTER_PLAN.md` §4.5 — attempt only after the
core is solid, and design it so a failure here cannot regress anything that is scored.

**Tradeoffs:** the auditability bonus may end up partially unrealized if time runs short; explicitly
acceptable per the phase-priority ordering (P0 items always precede P2 items, `TASKS.md` priority key).

**Future Considerations:** none.

---

## ADR-011 — Date Normalization: Shared Multi-Format Parser with Defensive Fallback

**Decision:** All date fields across all tables go through one shared parsing module, which accepts the
3 known public-sample formats plus additional formats defensively, and returns an explicit
"unparseable" signal (never a guessed date) on failure.

**Alternatives Considered:**
- **Format-specific parsing per field, tuned to what's observed in the public sample** — rejected: this
  is precisely the kind of sample-tuning the rules warn will fail on the hidden dataset
  (`CONTEXT.md` §4.3–§4.5); confirmed as a real risk, not a hypothetical one, since `CONTEXT.md` §12.4
  already documents 3 distinct formats in the public sample's `Submitted_At` column alone.
- **A permissive "guess the format" parser that silently picks the most likely interpretation of an
  ambiguous date** (e.g., `03/04/2026` as MM/DD vs DD/MM) — rejected: silent misinterpretation of a
  date is worse than an explicit escalation, per the "don't invent a value" rule (`CONTEXT.md` §6);
  ambiguous dates should escalate, not be guessed.

**Reasoning:** a single shared, well-tested module (built once, `TASKS.md` 0.2.2) used by every
Operator and the reseeding utility guarantees consistent behavior and is the direct implementation of
the hidden-dataset defensive philosophy (`MASTER_PLAN.md` §10, `DATA_FLOW.md` §3).

**Tradeoffs:** a genuinely ambiguous date (e.g., `03/04/2026` with no other context) must escalate rather
than guess, which could increase escalation volume on a hidden dataset with more such cases than the
public sample; accepted as the correct tradeoff — an escalation is recoverable by a human, a wrong
silent guess is not.

**Future Considerations:** if the hidden dataset consistently uses one unambiguous format, this could be
tuned post-hoc, but doing so *before* seeing it would be exactly the sample-tuning this ADR exists to
avoid.

---

## ADR-012 — Duplicate/Name-Variant Handling: Fuzzy Matching with a Human-Review Band

**Decision:** OP-01 uses a fuzzy string-similarity match (not exact match) against existing `Workers`
rows, with three explicit bands: confident-merge, confident-new, and escalate-for-review.

**Alternatives Considered:**
- **Exact string match only** — rejected: fails the entire named "name variants" trap type outright
  (`CONTEXT.md` §4.5, §10) by design, since the point of the trap is that variants are *not* exact
  matches.
- **Fuzzy match with only two bands (merge or new, no review band)** — rejected: forces a binary
  decision at the exact confidence range where the system is least certain, which is precisely where a
  wrong automatic decision (merging two different people, or creating a duplicate for one person) is
  most likely and most costly; a middle escalation band converts the riskiest automated decisions into
  safe human judgment calls instead.

**Reasoning:** three bands directly implement the "escalate on uncertainty, never guess" philosophy
(`MASTER_PLAN.md` §6) applied specifically to identity resolution, which is one of the two data-quality
problems (`CONTEXT.md` §4.5) most likely to cause a wrong business decision if mishandled.

**Tradeoffs:** requires two tuned thresholds (`dedup_confidence_threshold`, `dedup_flag_band_low`)
rather than one, and both need real test data to calibrate well (`TASKS.md` 0.2.3 acceptance criteria
requires 5+5 hand-crafted test pairs specifically because of this).

**Future Considerations:** thresholds are config values (`ARCHITECTURE.md` §7) so recalibration never
requires a code change.

---

## ADR-013 — Routing Authority: ORCH-01 Routes on the Union of `reasons[]`, Never on Either Operator's Tier

**Decision:** OP-02 and OP-03 each emit a `tier` field, but it is advisory/audit-log-only. ORCH-01's
routing decision (`ARCHITECTURE.md` §6) is derived exclusively from the union of `reasons[]` codes
returned by the two Operators, never from either Operator's own tier or from a separately-computed
"combined tier."

**Alternatives Considered:**
- **Each Operator computes its own tier, ORCH-01 combines the two tiers into a "combined tier," and
  routes on that** — this was the original design and is rejected here: it created two competing
  notions of severity (OP-02's own HIGH condition vs. a differently-defined cross-Operator HIGH) with no
  stated rule for which one governs a routing decision, and left OP-02's `confidence` field undefined in
  practice (nothing computed it, so the uncertainty branch had no real trigger for provisioning-only
  cases). This is a genuine specification defect that would leave an implementer guessing.
- **Only ORCH-01 computes any tier at all (Operators return raw facts only)** — considered, but a
  human-readable severity label is still useful in the audit log (`OPERATORS.md` §OP-04, auditability
  bonus) for a reviewer who doesn't want to re-derive severity from raw reason codes; keeping tier as an
  Operator output, demoted to advisory-only, preserves that readability without it doing double duty as
  routing logic.

**Reasoning:** a single routing authority, driven by an enumerable, testable set of reason codes, removes
an entire class of "which number wins" ambiguity and makes every routing outcome traceable to a specific,
named reason code rather than an opaque tier comparison. It also directly fixes a second problem: the
original design routed `TASK_ALREADY_ESCALATED` (a signal the source system itself already raised,
`CONTEXT.md` §12.2) to a Slack nudge rather than to the Auto Workbench, which under-served exactly the
case the problem statement calls out as needing a human loop. The corrected table (`ARCHITECTURE.md` §6)
routes `TASK_ALREADY_ESCALATED` and any compounding (both-Operators-fired) case directly to the
Workbench.

**Tradeoffs:** none identified — this is a pure specification fix; no Operator's actual detection logic
changes, only which of its outputs ORCH-01 is allowed to read for routing purposes.

**Future Considerations:** if Round 2 introduces additional Operators, they must emit `reasons[]` in the
same code/detail shape to remain routable by this authority, rather than inventing a parallel severity
concept.

---

## ADR-014 — Explicit `as_of_date` Clock, Never an Implicit Wall-Clock Inside Operator Logic

**Decision:** every lateness/window computation (`OPERATORS.md` OP-02 rules 1–4, OP-03 rule 2, OP-05's
task-completion metric) reads a single config value, `policy_config.as_of_date`, rather than each
Operator independently calling a system "now."

**Alternatives Considered:**
- **Each Operator calls the platform's current-time function directly** — this was the implicit
  assumption in the original spec (written as "today" throughout `OPERATORS.md`) and is rejected: it
  makes every risk determination depend on the literal moment the workflow happens to execute, which is
  fine for a genuinely live production system but breaks two things this project specifically needs —
  (a) deterministic, repeatable tests (`TASKS.md` unit tests would produce different pass/fail results
  depending on which day they're run), and (b) a reproducible demo recording, since the pre-selected demo
  hires (`DEMO.md` Beat 4/5) were chosen because they show a specific risk state as of a specific
  moment — an unpinned wall-clock could silently change that state between rehearsal and final recording.

**Reasoning:** a single named config field, defaulting to real wall-clock `now()` in production but
explicitly pinnable for tests and the demo, gets both properties: real-time correctness when it matters
(actual judging, actual production use) and determinism when it matters (tests, the recorded video). This
also directly protects against a hidden-dataset failure mode: `CONTEXT.md` §4.3's "different records"
guarantee says nothing about which date range those records fall in, so an implicit wall-clock `now()`
risks either flagging everything or nothing as "90+ days in" depending purely on when judging happens to
occur relative to whatever epoch the hidden dataset uses.

**Tradeoffs:** one more field every Operator must remember to read from config rather than reaching for a
built-in "current time" primitive; mitigated by making this explicit and load-bearing in
`ARCHITECTURE.md` §5 rather than a buried detail, precisely so it isn't missed during implementation.

**Future Considerations:** none — this is a permanent property of the system, not a Round-1-only
workaround; a real production deployment would leave `as_of_date` unpinned (true wall-clock) at all
times outside of testing.

---

## ADR-015 — Phase-0 Platform Capability Spike Before Building Any Operator

**Decision:** insert a dedicated, time-boxed spike at the start of Phase 0 (`TASKS.md` Epic 0.0) to
confirm four Supervity Auto platform capabilities this architecture depends on, before building any of
the five Operators.

**Alternatives Considered:**
- **Assume the capabilities exist and discover gaps during Phase 1–2 build-out** — rejected: this
  architecture makes four assumptions about the platform that are not verified anywhere in this
  documentation package because they cannot be verified from the rules/workshop materials alone —
  (1) the Auto Workbench can receive a programmatic escalation with arbitrary case context and later
  write a resolution back to a system of record; (2) Auto's execution UI actually surfaces two Operators
  running in parallel visibly enough to satisfy `TASKS.md` 2.2.2's "observably concurrent" acceptance
  criterion; (3) native Auto connectors genuinely exist for Airtable, Slack, and Typeform (Path 1,
  `CONTEXT.md` §5) rather than requiring a Path 2 code Operator for one or more of them; (4) a
  Round-1-appropriate reporting surface exists for OP-05's output, given that Supervity's coded "Auto
  Manager Console" is explicitly a Round 2 artifact (`CONTEXT.md` §3). Discovering any of these are false
  mid-way through Phase 2 (the highest-complexity phase, `ARCHITECTURE.md` §ORCH-01) would be far more
  expensive to recover from than discovering it in a 30-minute Phase 0 check.

**Reasoning:** each of the four capabilities above is load-bearing for a specific gate criterion or
rubric line (Workbench round-trip → gate criterion 3; visible parallelism → gate criterion 4 and
`DEMO.md` Beat 2; native connectors → build complexity and timeline risk; OP-05 surface → the "Demo &
console" rubric line, 20%). A cheap, early spike converts four unverified assumptions into either
confirmed facts or known, early-surfaced risks the team can plan around (e.g., falling back to a Path 2
code Operator for one integration, or choosing an Airtable Interface as OP-05's surface, per
`ARCHITECTURE.md` §1's resolution).

**Tradeoffs:** costs roughly 30 minutes of otherwise-buildable time at the very start of the 48-hour
window; accepted as strictly positive expected value given what a mid-build discovery would cost instead.

**Future Considerations:** none — this is a one-time Round 1 check; Round 2's platform (Auto Runtime) is
a different surface and would need its own equivalent spike if and when that scope begins.

---

## ADR-016 — Controlled-Vocabulary Fields Are Config Values, Never Hardcoded Substring Matches

**Decision:** wherever a rule needs to match against a known set of source-system labels (e.g., OP-02's
compliance-related `Step_Name` values), the set is a named `policy_config` list
(`compliance_step_terms`), not a substring/keyword match embedded in the Operator's logic.

**Alternatives Considered:**
- **Hardcode a substring check** (e.g., "`Step_Name` contains `Compliance`") — this was the original
  OP-02 rule 2 specification and is rejected: it is exactly the kind of sample-tuning
  `MASTER_PLAN.md` §10 exists to prevent, made worse by being easy to miss precisely because it looks
  like ordinary string-matching logic rather than an obviously sample-specific literal (unlike, say, a
  hardcoded `Employee_ID`, which is much more visibly suspicious during a review pass).

**Reasoning:** the dataset's `Step_Name` and `Resource` values (`CONTEXT.md` §12.2–§12.3) are a fixed,
documented enumeration in the public sample, but nothing in the rules guarantees the hidden dataset
reuses the exact same vocabulary rather than a same-schema-different-labels variant. Externalizing the
term list to config means this assumption is visible and correctable without a code change, consistent
with every other threshold in this system (`ARCHITECTURE.md` §7).

**Tradeoffs:** none of consequence — a config list costs nothing extra to build over a hardcoded
substring check.

**Future Considerations:** if other Operators are found to have a similar implicit vocabulary assumption
during implementation, the same pattern (named config list, not embedded literal) should be applied
rather than treated as a one-off fix specific to OP-02.
