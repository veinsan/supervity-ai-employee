# RISKS.md — Engineering Risk Register

**Reads as prerequisite:** `MASTER_PLAN.md`, `ARCHITECTURE.md`, `OPERATORS.md`, `TASKS.md`
**Purpose:** every material risk to gate compliance, score, or timeline, with likelihood/impact and a
concrete mitigation — not a generic disclaimer list.

**Severity key:** Impact × Likelihood, both rated Low/Medium/High. **Priority** = the combination,
used to order mitigation effort.

---

## Technical Risks

| ID | Risk | Likelihood | Impact | Priority | Mitigation | Contingency |
|---|---|---|---|---|---|---|
| R-01 | Hidden dataset uses a date format the shared parser (`DECISIONS.md` ADR-011) doesn't recognize | Medium | High | **High** | Parser accepts a broad format list plus 2 formats never seen in the public sample (`TASKS.md` 0.2.2 acceptance criteria); unrecognized formats escalate rather than crash or misparse | If escalation volume spikes during judging, this is still a *pass* on the "don't crash/invent a value" rule — worse for the business-output metric, not fatal to the gate |
| R-02 | Hidden dataset structural variation (reordered/renamed/extra columns) breaks the reseeding utility | Low | High | Medium | Column-name-based mapping, not position-based (`DATA_FLOW.md` §10); schema validation aborts with a clear report rather than partial-loading garbage (`TASKS.md` 3.2) | If a genuinely renamed required column is encountered, this is a judge-visible platform-provided dataset following the documented `Field_Dictionary.csv` schema (`CONTEXT.md` §12.6) — same-schema is a stated guarantee (`CONTEXT.md` §4.3: "same structure, different records"), so this risk is bounded by the rules themselves, not open-ended |
| R-03 | Fuzzy-dedup false-merges two genuinely different people with similar names | Low | High | Medium | High confidence threshold (0.90 default) for auto-merge; ambiguous band escalates instead of deciding (`DECISIONS.md` ADR-012) | A false merge that does occur is auditable via the `Cases & Audit Log` (every OP-01 write is logged) and correctable by a human at the Workbench |
| R-04 | LLM disclosure classifier produces a false negative (misses a real disclosure) | Low | Very High | **High** | Fail-safe-to-confidential design means only a *confident* false negative slips through — the failure mode most likely to occur (low confidence) already fails safe (`OPERATORS.md` §OP-03 Retry Behavior) | This is the single risk with the highest reputational/ethical impact in the whole build; treated as P0 test coverage (`TASKS.md` 1.3.4, 1.3.8) rather than left to chance |
| R-05 | Airtable API rate limits hit during a full 60-worker cohort sweep or live demo — now scoped to the 4 tables still on Airtable (`Onboarding_Tasks`, `Provisioning_Integration`, `Peakon_Engagement`, `Cases & Audit Log`); `Workers`/`Manager_Directory`/`policy_config` reads no longer hit this limit (`DECISIONS.md` ADR-001 amendment) | Low | Medium | Low | Retry/backoff config (`ARCHITECTURE.md` §7); cohort size is small enough that this is unlikely in practice | If hit during the live demo, the retry/backoff is itself demonstrable evidence of robustness (`OPERATORS.md` failure tables) rather than pure downside |
| R-06 | ORCH-01's fan-in barrier logic has an edge case where one Operator's escalation incorrectly blocks the whole hire's evaluation | Medium | Medium | Medium | Explicit partial-signal handling requirement (`OPERATORS.md` §ORCH-01 Validation, `TASKS.md` 2.2.7) with a dedicated test case | Caught in Phase 2 integration testing (`TASKS.md` 2.2.10) before Phase 3 begins |
| R-23 | Production retry/backoff schedule (up to 85s across 3 attempts, `ARCHITECTURE.md` §7) causes dead air during a failed write chain in the live demo recording, which has zero slack in a 3:50 target | Medium | Medium | Medium | `retry_demo_profile` (0 backoff, 1 attempt) toggled via `demo_mode` specifically for recording (`ARCHITECTURE.md` §7, `TASKS.md` 0.2.4); production behavior unaffected when `demo_mode` is off | If a write still fails visibly during a take despite the demo profile, that failure and its escalation is itself evidence of the "never crash, always escalate" design — reframe live rather than cut, or re-take the segment |
| R-24 | The "today" used in every lateness rule (OP-02, OP-03, OP-05) was originally implicit (system wall-clock), making risk detection non-reproducible between test runs, rehearsal, and the final demo recording, and creating a hidden-dataset failure mode where judging-time wall-clock could make every hire look artificially at-risk or artificially clean depending purely on when judging happens | Medium | High | **High** | Explicit `policy_config.as_of_date` field (`ARCHITECTURE.md` §5, `DECISIONS.md` ADR-014), defaulting to real wall-clock in production but pinned for every test (`TASKS.md` Phase 1 unit tests) and for the demo recording (`DEMO.md` §6 checklist) | If this were missed and only caught late, the fix is cheap (one config field, already routed through every Operator per `OPERATORS.md`) — but catching it before Phase 1 begins, as this package now does, avoids re-deriving every lateness rule's test expectations after the fact |
| R-25 | Four Supervity Auto platform capabilities this architecture depends on (Workbench programmatic escalation + resolution round-trip, visibly concurrent parallel execution, native connectors for all 3 required integrations, a Round-1-appropriate OP-05 output surface) were originally assumed rather than verified, risking discovery of a gap mid-way through the highest-complexity build phase (ORCH-01, Phase 2) | Low | High | Medium | Dedicated ~30-minute Phase-0 spike (`TASKS.md` Epic 0.0, `DECISIONS.md` ADR-015) confirms or falls back on each of the four before any Operator is built | If a native connector is genuinely missing, the documented fallback is a Path 2 code Operator (`CONTEXT.md` §5) for that one integration — a known, bounded contingency rather than a discovery under time pressure |

---

## Integration Risks

| ID | Risk | Likelihood | Impact | Priority | Mitigation | Contingency |
|---|---|---|---|---|---|---|
| R-07 | Slack app credentials expire or workspace access is accidentally revoked between submission and judging | Low | High | Medium | Explicit checklist item in `MASTER_PLAN.md` §11 (deployment strategy) to keep all systems live through the judging window | If detected, re-authenticate immediately; Discord office hours (`CONTEXT.md` §9) are the escalation path to organizers if a platform-side integration issue is suspected |
| R-08 | Google-integration temptation: a team member defaults to a Google tool out of habit (Sheets/Drive) during a time-pressured build | Medium | High | **High** | Explicit reminder in `INTEGRATIONS.md` and this register; Google integrations are beta and excluded by design (`CONTEXT.md` §9, §15) | Caught at Phase 0 review (`TASKS.md` Epic 0.1) before any Operator depends on it |
| R-09 | Typeform webhook delivery delay or failure during the live demo | Low | Medium | Low | Reseeding utility serves as a fallback intake path already built for a different purpose (`INTEGRATIONS.md` §3 Fallback) | If Typeform is flaky live, Beat 3 (`DEMO.md`) can fall back to showing a row arrive via the reseeding utility instead — rehearse both paths, not just one |
| R-10 | GitHub bonus integration failure incorrectly blocks a core flow due to an implementation mistake (violating its "best-effort only" design) | Low | Medium | Low | Explicit non-blocking failure-recovery requirement (`INTEGRATIONS.md` §4); tested at `TASKS.md` 4.2.2 acceptance criteria | Because this is P2/optional, worst case is simply disabling the integration before submission with zero impact on gate or core rubric lines |

---

## Hidden Dataset Risks

| ID | Risk | Likelihood | Impact | Priority | Mitigation | Contingency |
|---|---|---|---|---|---|---|
| R-11 | Team unconsciously tunes thresholds to produce "nice-looking" results on the public sample, overfitting despite intent | Medium | High | **High** | Every threshold has a documented *reasoning*, not just a value tuned by trial-and-error against the sample (`OPERATORS.md` per-Operator "Configurable Parameters" tables); Phase 3 adversarial dataset is authored independently of the public sample's specific values, precisely to catch this | Phase 3 exit criteria (`MASTER_PLAN.md` §7) is a hard gate — if the adversarial run reveals overfitting, thresholds are revisited against the *reasoning*, not against making the adversarial run also "look nice" |
| R-12 | Hidden dataset trap density is much higher than the public sample, and the build's escalation volume becomes unmanageably high for a live demo | Medium | Medium | Medium | Phase 3 adversarial dataset is deliberately authored with denser trap density than the public sample specifically to rehearse this (`TASKS.md` 3.3) | If escalation volume is genuinely high, this is framed in the demo narrative as the system correctly finding more real problems, not as a build failure — but only if Phase 3 already proved the pipeline doesn't crash under this load |
| R-13 | A trap type exists in the hidden dataset that isn't one of the 4 named seeded trap types (`CONTEXT.md` §10) | Low | Medium | Low | The general "escalate on uncertainty/missing field" philosophy (`MASTER_PLAN.md` §6) is not limited to the 4 named traps — any field-level anomaly not matching a known rule still hits the generic validation layer (`DATA_FLOW.md` §4) and escalates rather than crashing | Accepted residual risk — the 4 named traps are explicitly what `Field_Dictionary.csv` documents as seeded, so this is a low-probability scenario by the rules' own description |

---

## Demo Risks

| ID | Risk | Likelihood | Impact | Priority | Mitigation | Contingency |
|---|---|---|---|---|---|---|
| R-14 | Live demo runs over the 5-minute hard limit | Medium | High | **High** | Beat-by-beat timing table with hard ceilings (`DEMO.md` §3); rehearsed with a stopwatch before final recording (`TASKS.md` 5.2) | Cut order defined in advance (`DEMO.md` §9) so a real-time decision isn't needed under pressure |
| R-15 | The pre-selected demo hires (Beat 4, Beat 5) no longer have the expected data state at recording time, because earlier test runs changed them | Medium | Medium | Medium | Explicit pre-recording checklist item to re-verify state immediately before recording (`DEMO.md` §6) | If state has drifted, re-seed cleanly (reseeding utility, already built and timed) rather than recording against stale/incorrect state |
| R-16 | Screen-share/audio quality issues make the live Workbench or Slack proof illegible | Low | High | Medium | Explicit legibility check against a compressed export, not just the live recording (`DEMO.md` §6) | Re-record the affected segment; the beat structure (`DEMO.md` §2) is modular enough that a single beat can be re-shot without a full re-record if the tooling allows it |

---

## Qualification Gate Risks

| ID | Risk | Likelihood | Impact | Priority | Mitigation | Contingency |
|---|---|---|---|---|---|---|
| R-17 | A single integration (e.g., Slack) is unreachable at the exact moment judges re-run the build | Low | Very High | **High** | 3rd integration (Typeform) provides category/count margin above the gate minimum (`MASTER_PLAN.md` §3); retry/backoff on every write-side call | Deployment-strategy checklist (`MASTER_PLAN.md` §11) keeps all credentials live through the full judging window specifically to minimize this window of exposure |
| R-18 | Judges' hidden dataset triggers a genuine, previously-unseen crash (not just an escalation) | Low | Very High | **High** | Every Operator's failure table (`OPERATORS.md`) has an explicit path for validation/integration/low-confidence failure — "escalate, never crash" is enforced as a design invariant, not left to chance per-Operator | Phase 3's adversarial rehearsal (`TASKS.md` Phase 3) is the closest achievable proxy and is a hard release gate specifically to catch this class of risk before judging, not after |
| R-19 | The parallel/branching/stateful behavior is real in the implementation but not *visibly demonstrable* to a judge in the time available | Medium | High | **High** | Demo Beat 2 explicitly shows the execution trace, not just narrates it (`DEMO.md` §2 Beat 2); ORCH-01's fan-out is required to be "observably concurrent... in Auto's execution trace" as an acceptance criterion, not just functionally parallel (`TASKS.md` 2.2.2) | If Auto's UI doesn't surface concurrency clearly, fall back to narrating the workflow structure explicitly while pointing at the named Operator-call steps, which is still evidence, just weaker |

---

## Schedule Risks

| ID | Risk | Likelihood | Impact | Priority | Mitigation | Contingency |
|---|---|---|---|---|---|---|
| R-20 | Phase 3 (robustness rehearsal) is treated as a hard release gate (`MASTER_PLAN.md` §7) but time runs short before the internal deadline | Medium | High | **High** | Phase 3 work (authoring the adversarial dataset, `TASKS.md` 3.3) is explicitly parallelizable with Phase 2, not strictly sequential — starts early rather than after Phase 2 fully closes | If Phase 3 genuinely cannot complete in time, the contingency is to cut Phase 4 bonus scope (`TASKS.md` Epic 4.2, 4.3 — both P1/P2) entirely before cutting any Phase 3 item, since Phase 3 protects the gate and Phase 4 only protects bonus points |
| R-21 | Two-person team, one member unavailable for a stretch during the 48-hour window | Low | High | Medium | Task allocation suggestion (`TASKS.md` "Two-person team allocation") keeps each Epic ownable by one person with clear documented specs (`OPERATORS.md`) that don't require tribal knowledge to pick up | The remaining member can continue directly from `OPERATORS.md`'s specs without needing the other member's context, by design of this documentation package |
| R-22 | Internal deadline (19 July 18:00 MYT, `MASTER_PLAN.md` §12) slips into the true deadline's danger zone | Medium | Very High | **High** | Explicit go/no-go checkpoint at the internal deadline (`MASTER_PLAN.md` §14 last item) that forces an immediate scope-cut decision rather than silent slippage | Scope-cut order: Phase 4 bonus items first, then Phase 3's *extended* adversarial coverage (keeping only the minimum needed to pass Phase 3 exit criteria), never Phase 0–2 (gate-blocking) |

---

## Priority Summary (High-Priority Items Requiring Active Owner Attention)

| ID | Risk | Owning phase |
|---|---|---|
| R-01 | Unrecognized hidden-dataset date format | Phase 0 (parser), Phase 3 (rehearsal) |
| R-04 | LLM classifier false negative on disclosure | Phase 1 (OP-03 build + test) |
| R-08 | Accidental Google-integration usage | Phase 0 review |
| R-11 | Unconscious overfitting to public sample | Phase 3 (hard gate) |
| R-14 | Demo over time limit | Phase 5 |
| R-17 | Single integration outage during judging | Deployment checklist, ongoing |
| R-18 | Genuine crash on hidden dataset | Phase 3 (hard gate) |
| R-19 | Parallel/branching not visibly demonstrable | Phase 2 (acceptance criteria), Phase 5 (demo) |
| R-20 | Phase 3 time pressure | Schedule management, start early |
| R-22 | Internal deadline slip | Ongoing, checked at `MASTER_PLAN.md` §14 |
| R-24 | Undefined/implicit clock breaks reproducibility and hidden-dataset safety | Phase 0 (config field), Phase 1 (test pinning) |
| R-25 | Unverified platform capabilities discovered mid-build | Phase 0 (Epic 0.0 spike, before Phase 1 begins) |

Every ID in this table maps to a concrete, already-scheduled mitigation elsewhere in this package — this
register exists to make risk ownership explicit, not to introduce new work.
