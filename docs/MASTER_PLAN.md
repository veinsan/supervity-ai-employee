# MASTER_PLAN.md — Onboarding & Retention AI Employee

**Scope:** Track 5 (HR & People Ops) · Supervity Autopilot Asia Hackathon 2026
**Status:** Pre-implementation planning, Round 1
**Reads as prerequisite:** `CONTEXT.md` (immutable knowledge base — this document extends it, never repeats its factual content)
**Companion documents:** `ARCHITECTURE.md`, `OPERATORS.md`, `DATA_FLOW.md`, `INTEGRATIONS.md`, `TASKS.md`, `DEMO.md`, `DECISIONS.md`, `RISKS.md`

---

## 1. Engineering Goals

Ranked by what actually moves the score, per the Round 1 rubric in `CONTEXT.md` §7:

| Rank | Goal | Rubric line it serves | Weight |
|---|---|---|---|
| 1 | Pass the Qualification Gate with margin, not exactly at the line | Gate (pass/fail, blocks all scoring) | Gate |
| 2 | Produce a real, quantified business result on the outcome metric, live, on unseen data | Business output | 40 |
| 3 | Genuine operator-first orchestration: parallel, branching, retry, escalation, all demonstrable | Technical architecture | 20 |
| 4 | Config-driven policy layer a non-engineer could edit | Customizability | 20 |
| 5 | A console + demo a business user could actually run | Demo & console | 20 |
| 6 | Bonus: audit trail, open-source usage, self-learning loop | Bonus | additive |

**Engineering philosophy:** every architectural choice below is justified against this table, not against
elegance for its own sake. Where elegance and score conflict, score wins — but we never sacrifice
robustness, because robustness is what the hidden dataset tests directly.

---

## 2. Success Criteria

A build is "done" for Round 1 submission when **all** of the following are simultaneously true:

1. All 4 Qualification Gate criteria (CONTEXT.md §5) pass on a dataset the team has **never seen**,
   not just the sample rows.
2. The Orchestrator can be triggered live, end-to-end, in under 5 minutes of demo time, and produces a
   visible, correct outcome (a risk classification, a routed notification, an updated cohort metric).
3. At least one exception case reaches the Auto Workbench live, with a human able to act on it.
4. At least one sensitive-disclosure case is demonstrably routed to a confidential path and is
   demonstrably **absent** from the general cohort report.
5. Swapping the seeded dataset for a different one (same schema, new values) requires **zero** changes
   to Operator logic — only a re-run of the seeding utility. This is proven live in the demo (see
   `DEMO.md` §5).
6. The submission package (CONTEXT.md §8) is fully assembled with 18 hours of margin before the
   20 July 12:00 MYT deadline.

---

## 3. Qualification Gate Strategy

The gate is binary and checked before any scoring (`CONTEXT.md` §5, §7), so the strategy is **margin,
not minimalism**: hit each requirement with headroom so a partial failure (one integration flaking
during judging, one Operator not firing) still leaves the build inside the gate.

| Gate requirement | Minimum | Our design | Margin |
|---|---|---|---|
| Not a single mega-agent | 1 Orchestrator + 2 Operators | 1 Orchestrator + **5** Operators (`OPERATORS.md`) | 3 operators of slack |
| ≥3 integrations, ≥2 categories, incl. 1 channel + 1 system of record | 3 integrations / 2 categories | **3 required (bare minimum) + 1 bonus, not counted** integrations across **3** categories (`INTEGRATIONS.md`, `DECISIONS.md` ADR-001 second amendment Consequence 2) | +1 category only — integration-count margin is now zero |
| ≥1 live exception to Auto Workbench | 1 | **3 distinct escalation triggers** wired to the same Workbench path (`OPERATORS.md` §OP-04) | 3x |
| Demonstrable parallel/branching/stateful behavior | 1 of the 3 | **All 3 simultaneously**: OP-02/OP-03 run in parallel, ORCH-01 branches on combined risk, the 90-day clock is explicit state per hire (`ARCHITECTURE.md` §4–§6) | full coverage |

**Why margin over minimalism:** judges re-run the build on a hidden dataset live. A design that barely
clears the gate on the public sample has no slack if the hidden dataset triggers an edge case the team
didn't anticipate (see `RISKS.md` R-01, R-02). Extra Operators and extra escalation triggers cost little
additional Round-1 build time (Auto is no-code) but materially reduce the chance of an unlucky gate
failure.

---

## 4. Judging Strategy (Score Maximization)

### 4.1 Business output (40%) — the metric problem
`CONTEXT.md` fixes the outcome metric as **task completion & day-90 retention**, but the dataset
(`CONTEXT.md` §12) contains no explicit "did this hire leave" field. This is treated as an **explicit
assumption**, not a gap to paper over:

> **Assumption A-01:** Because no ground-truth attrition field exists in the Workday/Peakon-style
> export, "day-90 retention" is operationalized as a **leading-indicator risk score** plus a
> **measured intervention rate** — the AI Employee's job is to move the leading indicators (on-time
> provisioning, on-time compliance docs, engagement trend) in the right direction and to prove that
> at-risk hires were caught and routed to a human before Day 90, not to claim knowledge of an outcome
> that isn't in the data. This is addressed head-on in the demo's judge-question prep (`DEMO.md` §8) so
> judges see it as a deliberate, defensible modeling choice rather than an omission.

Three metrics are computed live by OP-05 and shown on the console (`OPERATORS.md` §OP-05):
- **Exposure rate (headline)** — % of the active cohort currently showing at least one unresolved
  onboarding/provisioning risk reason, computed **directly from `Onboarding_Tasks`/
  `Provisioning_Integration`**, independent of whether the system has already acted on it. This is a
  real, falsifiable number a judge can spot-check against the raw data — deliberately **not**
  self-referential (an earlier draft used "at-risk catch rate" as the headline, which measured whether
  the system acted on cases it itself generated — near-tautological by construction, since the routing
  logic acts on nearly every detected case; see `DECISIONS.md` ADR-007 amendment).
- **Task completion rate** — directly computable, objective, per-milestone and cohort-wide.
- **At-risk-hire catch rate (secondary)** — % of hires with a detected risk signal that received a
  routed intervention before their next milestone due date. Retained as a supporting number ("and here's
  how much of the exposure we've already routed to a human or resolved"), not the headline claim.

### 4.2 Technical architecture (20%)
Achieved by construction: 5 single-responsibility Operators + 1 Orchestrator with real parallel fan-out
(OP-02 ∥ OP-03), conditional branching (risk tier → routing path), retries (all write-side Operators),
and escalation (3 distinct trigger conditions). See `ARCHITECTURE.md`.

### 4.3 Customizability (20%)
All thresholds, routing rules, and message templates live in a single external `policy_config` object
(`ARCHITECTURE.md` §7, `OPERATORS.md` per-operator "Configurable Parameters" sections), edited without
touching workflow logic. This directly satisfies rules §3.5 ("the business owns the logic") and is
demoed live by changing one threshold and re-running (`DEMO.md` §5).

### 4.4 Demo & console (20%)
See `DEMO.md` in full — storyline, timing, live walkthrough, and the hidden-dataset proof moment.

### 4.5 Bonus targets (priority order, attempt only after core gate + rubric are solid)
1. **Auditability & governance** — every Orchestrator decision writes a structured case record
   (who, what, why, which policy rule fired) to the system of record; this is nearly free once OP-04
   exists and directly matches the bonus description in `CONTEXT.md` §7.
2. **Open-source usage** — the date-normalization and fuzzy-dedup logic (see `DECISIONS.md` ADR-011,
   ADR-012) should name and genuinely use an open-source library rather than reinventing parsing, so
   the usage is real and disclosable, not a token import.
3. **Self-learning capability** — stretch goal, only attempted after 1–2 are solid (see `TASKS.md`
   Phase 4, marked optional). Design sketch only in `ARCHITECTURE.md` §9; not required for Round 1.

---

## 5. Business Value Strategy

The narrative judges must leave with: *"Farah's team currently discovers a flight risk when it's too
late because the signals live in three disconnected systems. This AI Employee assembles those signals
continuously, acts on the unambiguous cases automatically, and puts a human in the loop exactly where
judgment — not automation — is required (a struggling new hire, a sensitive disclosure)."*

Every design decision is filtered through: *does this make the automation's judgment more defensible to
an enterprise buyer, or just more impressive to look at?* Defensibility wins (see `DEMO.md` §7, likely
judge questions).

---

## 6. Architecture Philosophy

1. **Single responsibility per Operator.** Detection is separated from action (OP-02/OP-03 detect,
   OP-04 acts). This isolates retry/failure logic to the one Operator that actually touches external
   write APIs, and makes each Operator independently testable — critical when the hidden dataset is
   unknown at build time.
2. **State lives in the system of record, not in the workflow.** The Orchestrator is stateless between
   runs; the 90-day clock is derived from `Workers.Hire_Date`, while risk history and case status are
   persisted fields in `Cases_Audit_Log` — both now live on Supabase, the sole system of record
   (`DECISIONS.md` ADR-001 second amendment).
   This means a failed or restarted run cannot corrupt state, and the same Orchestrator design works
   whether triggered on a schedule or on demand.
3. **Escalate on uncertainty, never guess.** Every Operator has an explicit "insufficient confidence /
   missing field → escalate" path, per the rules' hard requirement (`CONTEXT.md` §6, "Don't let the AI
   Employee crash or invent a value"). This is treated as a correctness requirement, not a nice-to-have.
4. **Config is data, not code.** Anything a business user might reasonably want to change (thresholds,
   channel routing, message copy) is a field in `policy_config`, never a hardcoded literal inside a
   workflow step.
5. **Build for a schema, not for a sample.** No Operator logic references specific `Employee_ID`
   values, specific comment text, or specific dates from the public dataset. Validated explicitly in
   Phase 3 testing (`TASKS.md`).

---

## 7. Implementation Phases & Milestone Roadmap

| Phase | Goal | Exit criteria | Maps to |
|---|---|---|---|
| **Phase 0 — Foundations** | Platform capabilities verified, systems stood up, dataset seeded, config schema defined | **Epic 0.0 spike passes first** (`DECISIONS.md` ADR-015: Workbench round-trip, visible parallelism, all 3 native connectors, a Round-1-appropriate OP-05 output surface all confirmed — that surface is now Supabase's Table Editor, not an Airtable Interface, `DECISIONS.md` ADR-001 second amendment Consequence 1); then Supabase live with correct schema, Airtable fully deprecated (`DECISIONS.md` ADR-001 second amendment); Slack workspace + 5 channels live (one per `Manager_Directory.Org`, §3.1 M1 fix — never 2); Typeform live; `policy_config` v1 committed (Supabase) | `TASKS.md` Phase 0 |
| **Phase 1 — Detection Operators** | OP-01, OP-02, OP-03 built and independently testable | Each Operator returns correct output on 5 hand-picked test hires covering each seeded trap type | `TASKS.md` Phase 1 |
| **Phase 2 — Orchestration & Action** | ORCH-01 and OP-04 built, parallel + branching wired | End-to-end run on the full 60-worker cohort completes without crash; at least 3 branch types observed | `TASKS.md` Phase 2 |
| **Phase 3 — Robustness & Hidden-Dataset Rehearsal** | Reseeding utility built; adversarial test dataset authored and run | Build survives a hand-authored "trap-heavy" dataset with malformed dates, blanks, name variants, and duplicate rows without crashing or misrouting | `TASKS.md` Phase 3 |
| **Phase 4 — Reporting, Console, Bonus** | OP-05 cohort metrics live; audit trail bonus; polish | Console shows exposure rate and task completion live; audit trail queryable; optional self-learning sketch documented only | `TASKS.md` Phase 4 |
| **Phase 5 — Submission Package** | Demo video, LinkedIn post, submission form | All 5 required submission artifacts (`CONTEXT.md` §8) ready ≥18h before the true deadline (internal target below, §12) | `TASKS.md` Phase 5 |

Phases are sequential but Phase 1's three Operators can be built in parallel by different team members
if the team is 2 people (see `TASKS.md` dependency graph).

---

## 8. Integration Strategy

Summarized here; full detail and per-integration justification in `INTEGRATIONS.md`.

- **System of record: Supabase** — sole system of record for all 7 tables (5 dataset tables,
  `policy_config`, and `Cases_Audit_Log`); Airtable is fully deprecated (`DECISIONS.md` ADR-001 second
  amendment).
- **Channel: Slack** — two logical channels: a manager-nudge channel (routed by `Org`, via
  `Manager_Directory`) and a confidential HR-only channel for sensitive disclosures.
- **Forms: Typeform** — the "a way in" new-hire intake path named explicitly in the problem statement's
  example table (`CONTEXT.md` §9).
- **Bonus / stretch: GitHub** — audit-trail log of every Orchestrator decision, for the auditability
  bonus only; not required for the gate.

This set clears the gate (≥3 integrations, ≥2 categories, 1 channel + 1 SoR) with one spare category
(Forms — 3 categories vs. the minimum 2) but **zero** spare integrations: Supabase, Slack, and Typeform
are exactly the 3 required (`DECISIONS.md` ADR-001 second amendment Consequence 2). GitHub (bonus/stretch,
above) is not counted toward the gate by design and does not restore this margin.

---

## 9. Testing Strategy

Testing is designed around one constraint: **the team will never see the judging dataset.** Therefore
testing optimizes for generalization, not for passing on the sample.

1. **Unit-level (per Operator):** a fixed set of hand-picked hires from the public sample, chosen to
   cover each of the 4 seeded trap types (`CONTEXT.md` §10) plus at least one clean/no-risk hire, run
   through each Operator individually.
2. **Format-robustness tests:** synthetic rows added to a **test-only** copy of the dataset (never the
   real seed) exercising the 3 known date formats plus at least 2 formats *not* seen in the public
   sample (to guard against a parser tuned only to what's visible today) — see `DECISIONS.md` ADR-011.
3. **Missing/blank-field tests:** every required field in every Operator's input contract
   (`OPERATORS.md`) is tested blank at least once, confirming escalation fires instead of a crash or an
   invented value.
4. **Full-cohort integration test:** all 60 sample workers run through the full Orchestrator in one
   pass; verifies no duplicate escalations, no missed hires, and correct parallel completion.
5. **Adversarial rehearsal dataset (Phase 3):** the team authors a second, deliberately messier dataset
   (same schema) with denser trap density, name variants, and duplicate rows, and runs the full pipeline
   against it before submission. This is the closest achievable proxy to the hidden judging dataset and
   is treated as a release gate — Phase 3 does not close until this passes cleanly.
6. **Live re-seed rehearsal:** the reseeding utility (`DATA_FLOW.md` §6) is run at least twice during
   Phase 3, timed, to make sure the live demo's "new dataset" moment fits inside the demo's time budget.

---

## 10. Hidden Dataset Strategy

The single highest-leverage risk in this competition is optimizing for the public sample and failing on
the hidden one (`CONTEXT.md` §4.3–§4.5, explicit and repeated warning). Concrete countermeasures:

- No literal `Employee_ID`, name, date, or comment string from the public sample appears in any
  Operator's logic, threshold, or test assertion beyond the test suite itself.
- All thresholds are config values with documented defaults and documented *reasoning* for the default
  (`OPERATORS.md`), so a judge (or teammate) can sanity-check them without needing to know the sample.
- The reseeding utility is schema-driven, not file-driven: it maps by **column name**, not column
  position, and tolerates extra/reordered columns where feasible (defensive parsing, `DATA_FLOW.md` §3).
- Every "trap type" named in `Field_Dictionary.csv` (`CONTEXT.md` §10) has a corresponding, named,
  testable rule in `OPERATORS.md` — not an implicit behavior nobody could point to.

---

## 11. Deployment Strategy

Round 1 requires no "deployment" in the traditional sense — the AI Employee runs live inside the
Supervity Auto workspace, and the deliverable is a **live Operator URL** plus the connected Auto
workspace itself (`CONTEXT.md` §8). "Deployment" for Round 1 therefore means:

1. All Operators and the Orchestrator are published/active (not draft) in the Auto workspace at
   submission time.
2. All three required integrations are connected with live, non-expired credentials at submission time
   and will remain live through the judging window (20–24 July).
3. The Supabase project, Slack workspace, and Typeform form are not deleted, renamed, or re-permissioned
   between submission and judging — a private checklist item, not a technical task. The original Airtable
   base is fully deprecated (`DECISIONS.md` ADR-001 second amendment); it holds no live data and its
   state no longer matters for judging.

Round 2 deployment (Auto Runtime / Auto Manager Console / GitHub starter repo) is explicitly **out of
scope** for this planning package until the Round 2 starter repo is released to finalists on 25 July —
attempting to design it now would mean fabricating an undocumented API surface, which is disallowed by
constraint. `ARCHITECTURE.md` §10 records forward-looking notes only.

---

## 12. Submission Strategy

Maps directly to `CONTEXT.md` §8. Ownership and timing:

| Artifact | Owned by (role) | Ready by |
|---|---|---|
| Team name, members, emails, track | Either team member | Phase 0 |
| Live Operator URL | Whoever builds ORCH-01 | End of Phase 2 |
| Auto workspace link | Same | End of Phase 2 |
| Demo video (3–5 min) | See `DEMO.md` | Phase 5, ≥18h before the true deadline (internal target, §12) |
| Public LinkedIn post mentioning Supervity + Autopilot Asia Hackathon | Either member | Phase 5 |

**Submit-early rule:** rules §5.3 states no late submissions are accepted for any reason. Internal
target deadline is **19 July, 18:00 MYT** — 18 hours before the real deadline — treated as the hard
deadline for this team.

---

## 13. Demo Preparation Strategy

Full script in `DEMO.md`. Summary of the non-negotiable beats, each mapped to a rubric or gate line so
nothing in the video is filler:

1. Rationale (30–45s) → judging line "business output," establishes the problem is real.
2. Architecture explanation (45–60s) → "technical architecture" line, shows Orchestrator + Operators by
   name, not just a diagram.
3. Live end-to-end run on the seeded dataset (60–90s) → gate requirement, shows parallel + branching.
4. Live exception → Auto Workbench (30–45s) → gate requirement, non-negotiable, must be **live**, not
   narrated.
5. Confidential-routing proof (20–30s) → shows the sensitive-disclosure path and its absence from the
   cohort report — a specific, explicit requirement from the problem statement.
6. Hidden-dataset proof: re-seed with a fresh dataset and re-run in front of the camera (30–45s) →
   directly answers the rules' repeated warning about hardcoding, pre-empts the single most likely judge
   objection.
7. Console + business metric close (20–30s) → "demo & console" line, ends on the quantified result.

Total: 3.5–4.5 minutes, inside the 3–5 minute limit with margin.

---

## 14. Final Readiness Checklist

This is the authoritative pre-submission gate for the team — a superset of `CONTEXT.md` §16, extended
with engineering-specific items:

- [ ] All items in `CONTEXT.md` §16 checklist pass.
- [ ] Phase 3 adversarial rehearsal dataset run completed with zero crashes and zero silent
      misclassifications (all Operators correctly escalate what they should escalate).
- [ ] Reseeding utility executes in under 90 seconds against a fresh dataset of the same size as the
      sample (60 workers) — required for the live demo re-seed beat to fit its time budget.
- [ ] `policy_config` reviewed end-to-end by both team members; every threshold has a one-line
      justification comment.
- [ ] Audit trail (bonus) queryable and shown to contain at least one entry per escalation type.
- [ ] Demo video recorded, watched back in full by both members, checked against the beat list in
      §13 with a stopwatch.
- [ ] Submission portal fields drafted in a text file in advance so submission itself takes under
      5 minutes once the portal opens.
- [ ] Internal deadline (19 July 18:00 MYT) met with a go/no-go check; any incomplete item triggers
      immediate scope-cut per `RISKS.md` contingency plans, not silent slippage.
