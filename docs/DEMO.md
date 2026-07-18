# DEMO.md — Demo Design

**Reads as prerequisite:** `CONTEXT.md` §8 (submission requirements), `MASTER_PLAN.md` §13,
`ARCHITECTURE.md`, `OPERATORS.md`, `DATA_FLOW.md` §7 (confidentiality contract)
**Constraint:** 3–5 minutes, screen-share required, must cover rationale, uniqueness, and a live
end-to-end execution including the exception case (`CONTEXT.md` §8, rule 5.5). Target runtime for this
script: **3 minutes 50 seconds**, leaving margin under the 5-minute ceiling.

---

## 1. Storyline (One Sentence Judges Should Be Able to Repeat Afterward)

*"Farah's onboarding signals live in three disconnected systems — this AI Employee assembles them
continuously, acts automatically on the clear cases, and routes the judgment calls — including
anything sensitive — to a human, provably, on data it's never seen before."*

---

## 2. Beat-by-Beat Script

| # | Beat | Time budget | Cumulative | Rubric/gate line served |
|---|---|---|---|---|
| 1 | Rationale — the problem | 0:00–0:35 | 0:35 | Business output |
| 2 | Architecture explanation | 0:35–1:30 | 1:30 | Technical architecture |
| 3 | Live run: new hire intake | 1:30–2:05 | 2:05 | Gate (live, real integration) |
| 4 | Live exception → Auto Workbench | 2:05–2:45 | 2:45 | Gate (mandatory), Technical architecture |
| 5 | Confidential-routing proof | 2:45–3:10 | 3:10 | Business narrative, problem-statement-specific requirement |
| 6 | Hidden-dataset proof (re-seed + re-run) | 3:10–3:40 | 3:40 | Robustness, pre-empts the #1 likely judge objection |
| 7 | Console + business metric close | 3:40–3:50 | 3:50 | Demo & console, Business output |

### Beat 1 — Rationale (0:00–0:35)
> "Roughly 1 in 5 new hires here leave within 90 days. The warning signs — a missing laptop, a stalled
> compliance doc, a flat engagement score — already exist, spread across Workday-style onboarding data,
> IT provisioning, and Peakon pulse surveys. Nobody's assembling them in time. We built an AI Employee
> that does — and knows exactly when to act on its own versus when to put a human in the loop."

*Why this framing, not a feature list:* opens on the business problem (`CONTEXT.md` §9 scenario), not
the tech, matching what `MASTER_PLAN.md` §5 identifies as the narrative judges need to leave with.

### Beat 2 — Architecture Explanation (0:35–1:30)
Show the architecture diagram (`ARCHITECTURE.md` §1) on screen for ~10 seconds, then narrate live over
the Auto workspace:
> "One Orchestrator, five Operators, each with one job. Two of them — onboarding risk and engagement
> risk — run in parallel for every hire. The Orchestrator combines what they find, and branches: routine
> cases get logged, risky cases get a manager nudge, and anything ambiguous or sensitive goes straight to
> a human at the Auto Workbench."

Point at the actual Orchestrator workflow in Auto while saying this — showing the named Operator calls
("trigger the Onboarding Risk Operator," etc., per `CONTEXT.md` §9's naming convention) is what makes
this beat *evidence*, not narration.

### Beat 3 — Live Run: New-Hire Intake (1:30–2:05)
Submit a live Typeform entry for a new hire on screen. Show the record land, normalized, in `Workers`
(Supabase, `DECISIONS.md` ADR-001 amendment) within seconds. Trigger the Orchestrator (event path,
`ARCHITECTURE.md` §3.1) for this hire live.

> "That's a real Typeform submission, a real write to Supabase, and the Orchestrator picking it up
> automatically — no mock data, no pre-staged screen recording."

### Beat 4 — Live Exception → Auto Workbench (2:05–2:45) — **non-negotiable, must be live**
Use a pre-selected hire (from the seeded dataset) with an `Onboarding_Tasks` row at `Status = Escalated`
(`CONTEXT.md` §12.2 confirms 40 such rows in the sample — plenty of choices). This specific condition is
the one that **deterministically** routes to the Workbench under the routing table
(`ARCHITECTURE.md` §6): `TASK_ALREADY_ESCALATED` bypasses the Slack manager-nudge path entirely, because
the source system itself already judged the case needs a human. **Do not** substitute a hire whose only
signal is a `Blocked` provisioning row with no `Escalated` task — that case routes to a Slack manager
nudge under the corrected routing logic, not the Workbench, and would silently break this beat.
Trigger the Orchestrator for this hire live, show:
1. OP-02 firing `TASK_ALREADY_ESCALATED`.
2. ORCH-01 routing directly to the Auto Workbench — narrate that this is a deliberate design choice, not
   the low-confidence/uncertainty path: the source system already escalated this case, so the AI Employee
   preserves that human-review requirement rather than resolving it into an automated notification.
3. The Workbench UI actually showing the case, live.

> "This is the mandatory piece the rules call out specifically — a real exception, routed live to a
> human, not simulated. And it's not just the system being unsure — this hire's own onboarding record
> was already flagged for human review, so we make sure that judgment doesn't get silently downgraded
> into an automated Slack message."

### Beat 5 — Confidential-Routing Proof (2:45–3:10)
Use a pre-selected hire with a sensitive Peakon comment (`CONTEXT.md` §12.4 references real sample
comments matching this). Trigger, show:
1. OP-03 classifying it `confidential: true`.
2. The message landing in the **confidential** Slack channel only.
3. Immediately after, open the cohort console (OP-05, Supabase's Table Editor — see Beat 7 note) and
   show this hire's case is counted in aggregate but **the disclosure text itself is nowhere in the
   report.**

> "The problem statement is explicit that sensitive disclosures can't leak into the general report. We
> don't just say that — watch: it's in the confidential channel, and it's not in the dashboard."

*This is the single most differentiating beat in the whole demo* — most competing teams will detect
risk; few will explicitly, visibly prove the confidentiality contract on camera. See `DECISIONS.md`
ADR-005.

### Beat 6 — Hidden-Dataset Proof (3:10–3:40)
Run the reseeding utility live against a **second dataset** (the Phase 3 adversarial rehearsal dataset,
`TASKS.md` §Phase 3, or a fresh synthetic one prepared for this exact purpose) — same schema, different
values, different name variants, different dates. Re-trigger a cohort sweep. Show it completing cleanly.

> "The rules are explicit that judging happens on a dataset we've never seen. So here's a second dataset
> we generated ourselves and have never fed the system before — same structure, different everything
> else. Re-seed, re-run, same correct behavior, zero code changes."

*Why this beat exists at all:* pre-empts the single most likely judge cross-question (`§4` below) by
answering it before it's asked, which is a stronger position than answering it reactively.

### Beat 7 — Console + Business Metric Close (3:40–3:50)
Show the two headline numbers in OP-05's console — **exposure rate** first, then task completion rate.
This console is Supabase's Table Editor (`DECISIONS.md` ADR-001 second amendment Consequence 1): a plain
filterable/sortable grid over the computed metrics, not a purpose-built dashboard with formatted fields
the way the originally-planned Airtable Interface would have been. Frame it honestly as that on camera —
a labeled, correctly-computed grid is still a real, falsifiable business output, just not a polished one.

> "Right now, this is the percentage of the active cohort with a real, unresolved onboarding risk —
> computed straight from the raw provisioning and task data, not from our own case log. And here's task
> completion, live, on real data, computed by the system itself."

---

## 3. Timing Table (Stopwatch Checklist for Rehearsal)

| Beat | Target | Hard ceiling |
|---|---|---|
| 1 | 0:35 | 0:45 |
| 2 | 0:55 | 1:10 |
| 3 | 0:35 | 0:45 |
| 4 | 0:40 | 0:55 |
| 5 | 0:25 | 0:35 |
| 6 | 0:30 | 0:40 |
| 7 | 0:10 | 0:15 |
| **Total** | **3:50** | **≤5:00** |

If rehearsal runs over, cut from Beat 2 (narration can be tightened) before cutting any of Beats 3–6,
which are the load-bearing *live, evidentiary* beats — `MASTER_PLAN.md` §13 flags these as
non-negotiable.

---

## 4. Qualification Gate Proof — Explicit Mapping

Every gate criterion must be *visibly* proven in the video, not merely true in the build. This table is
the pre-flight check before recording:

| Gate criterion | Proven in beat | How |
|---|---|---|
| Not a single mega-agent | 2, 3, 4 | Named Operators shown individually in Auto; parallel execution visible in the execution trace during beat 3/4 |
| ≥3 integrations, ≥2 categories | 3, 4, 5 | Typeform (beat 3), Supabase (beat 3, `Workers` write; beats 4–5, `Cases_Audit_Log` visible in workspace — sole SoR, `DECISIONS.md` ADR-001 second amendment), Slack (beats 4, 5) — exactly the 3-integration gate minimum, zero spare (`DECISIONS.md` ADR-001 second amendment Consequence 2) |
| ≥1 live exception to Workbench | 4 | Workbench UI shown with the case live |
| Demonstrable parallel/branching/stateful | 2 (parallel), 4/5 (branching), narration only for stateful (90-day clock is harder to show live in 4 minutes — verbally note it, don't fabricate a visual for it) |

---

## 5. Business Narrative (Full Talking Points, Not Just the Script)

For any judge follow-up beyond the video itself (live Q&A, if applicable):
- The problem is real and specific: 1-in-5 attrition, signals that exist but aren't assembled
  (`CONTEXT.md` §9).
- The design choice to separate detection (OP-02/OP-03) from action (OP-04) isn't just clean code — it
  means the notification/escalation logic is auditable and testable independent of the risk logic,
  which is exactly the kind of separation an enterprise buyer's engineering team would ask for.
- The confidentiality-first branch ordering (`ARCHITECTURE.md` §6) is a deliberate governance choice,
  not an afterthought — confidentiality is checked *before* any other routing rule, so nothing can
  outrank it.

---

## 6. Live Walkthrough Checklist (Pre-Recording)

- [ ] **Pin `policy_config.as_of_date`** to a fixed date inside the seeded dataset's active range
      (`ARCHITECTURE.md` §5) before rehearsal and before final recording — an unpinned wall-clock value
      could change which hires show which risk state between rehearsal and the final take, silently
      invalidating the pre-selected demo hires below.
- [ ] **Enable `demo_mode`** so write-side Operators use `retry_demo_profile` (no backoff) rather than
      the production retry/backoff schedule — a failed write chain on the production profile can cost up
      to 85 seconds of dead air (`RISKS.md` R-23), which the 3:50 target cannot absorb.
- [ ] Pre-select and note down: 1 hire for Beat 4 with an `Onboarding_Tasks` row at `Status = Escalated`
      specifically (**not** merely a `Blocked` provisioning row — see Beat 4 above for why this
      distinction is load-bearing), 1 hire for Beat 5 (known sensitive comment), verified against the
      current state of the seeded dataset (Supabase, `DECISIONS.md` ADR-001 second amendment — Airtable
      is fully deprecated) immediately before recording (data could have shifted from earlier test runs).
- [ ] Confirm Auto Workbench has no leftover unresolved test cases that would confuse the Beat 4 shot.
- [ ] Confirm the confidential Slack channel is visibly empty of old test messages before Beat 5, or
      scroll to the correct message live rather than showing a cluttered history.
- [ ] Confirm the adversarial rehearsal dataset for Beat 6 is staged and ready to load in one action
      (per the reseeding utility's timing requirement, `MASTER_PLAN.md` §14: under 90 seconds).
- [ ] Screen resolution/font size legible at video-compressed resolution (test by re-watching an export,
      not just the live recording).

---

## 7. Exception Demonstration — Detail

Beat 4 is the gate-mandatory exception; Beat 5 doubles as a *second*, distinct exception type
(confidential routing). Showing two different escalation *reasons* (a data-quality/process exception vs.
a governance/confidentiality exception) is deliberate — it demonstrates the escalation surface is
general-purpose, not a single hardcoded special case built only to clear the gate.

---

## 8. Likely Judge Questions & Suggested Answers

| Likely question | Suggested answer | Grounded in |
|---|---|---|
| "How do I know this isn't hardcoded to your sample data?" | Point directly to Beat 6 already having answered this in the video; if asked live, re-run the reseeding utility against a *third*, freshly-generated dataset on the spot | `DATA_FLOW.md` §10, `MASTER_PLAN.md` §10 |
| "What happens if the LLM classifier gets the confidential call wrong?" | Explain the fail-safe design: low-confidence always routes to a human, never defaults to "not confidential" — the asymmetry is intentional | `OPERATORS.md` §OP-03 Retry Behavior, `DATA_FLOW.md` §7 |
| "Why isn't 'day-90 retention' measured directly?" | Explain Assumption A-01 openly: the dataset has no ground-truth attrition field, so the system reports **exposure rate** (a real, raw-data-computed number: what % of the cohort has an unresolved risk right now) as the headline, with catch rate as a secondary "and here's how much of that we've already routed" — deliberately not leading with catch rate alone, since that would only measure whether the system acted on cases it generated | `MASTER_PLAN.md` §4.1, `DECISIONS.md` ADR-007 |
| "Could a business user really change this without an engineer?" | Live-edit one `policy_config` threshold (e.g., `engagement_low_score`) in Supabase's Table Editor (`DECISIONS.md` ADR-001 amendment) in front of them and re-run a case to show the changed behavior | `ARCHITECTURE.md` §7 |
| "What happens if Slack is down during judging?" | Explain the retry + escalate-to-Workbench fallback, and that the audit log write is attempted independently either way, so nothing is silently lost | `OPERATORS.md` §OP-04 Retry Behavior |
| "Why 5 Operators instead of the minimum 2?" | Explain the margin strategy: single-responsibility Operators are individually testable and the extra decomposition is what makes the audit trail and the parallel/branching behavior demonstrable at all, not decoration | `MASTER_PLAN.md` §3, `ARCHITECTURE.md` §2 |
| "Does the confidential comment ever appear anywhere outside the Workbench?" | No — walk through the contract: only OP-03 reads it, only `_internal_case_payload` carries it, only OP-04's confidential branch consumes that field, never templated into any message, never read by OP-05 | `DATA_FLOW.md` §7 |

---

## 9. Judging Emphasis Summary

If time pressure forces a cut during recording, the priority order to preserve (highest first) is:
Beat 4 (gate-mandatory) > Beat 3 (gate: live integration) > Beat 6 (robustness proof, differentiator) >
Beat 5 (governance differentiator) > Beat 2 (architecture explanation, can be compressed) > Beat 7
(nice close, can be shortened to a single sentence) > Beat 1 (can be shortened, not cut — judges need the
"why" to weight everything that follows).
