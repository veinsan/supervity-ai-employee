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
| 4 | Live exception → real Human Review → Auto Workbench | 2:05–2:45 | 2:45 | Gate (mandatory), Technical architecture |
| 5 | Confidential-routing proof | 2:45–3:10 | 3:10 | Business narrative, problem-statement-specific requirement |
| 6 | Hidden-dataset proof (re-seed + re-run) | 3:10–3:40 | 3:40 | Robustness, pre-empts the #1 likely judge objection |
| 7 | Business output close | 3:40–3:50 | 3:50 | Demo & console, Business output |

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

### Beat 4 — Live Exception → Real Human Review → Auto Workbench (2:05–2:45) — **non-negotiable, must be live**
Use **`EMP7000`** — already verified in rehearsal to have an `Onboarding_Tasks` row at
`Status = Escalated` (two, in fact: "First 1:1 scheduled" and "Compliance Document signed";
`CONTEXT.md` §12.2 confirms 40 such rows exist in the sample generally, but `EMP7000` specifically is
the pre-confirmed, tested choice — don't substitute a different ID without re-verifying it live first).
This specific condition is the one that **deterministically** routes to human review under the routing
table (`ARCHITECTURE.md` §6): `TASK_ALREADY_ESCALATED` bypasses the Slack manager-nudge path entirely,
because the source system itself already judged the case needs a human. **Do not** substitute a hire
whose only signal is a `Blocked` provisioning row with no `Escalated` task — that case routes to a Slack
manager or IT nudge under the corrected routing logic, not human review, and would silently break this
beat.

**What this beat actually proves, precisely:** OP-04's `workbench_log` branch calls Supervity Auto's
native **Human Review** step (`auto.supervity.ai/docs/guides/human-review`) — not a database write
labeled "workbench." This is a first-class platform mechanism: execution genuinely **pauses**, a real
review form is generated at a unique URL, a human must act on it, and only then does execution
**resume**. This was verified end-to-end before recording, not assumed: a real run for `EMP7000`
produced a live form at a unique `form_url`, sat in "Waiting Review" status until manually approved, and
only then proceeded to write the final audit record — this is the literal mechanism the gate criterion
describes ("routed live to a human, not simulated"), not a paraphrase of it.

Trigger the Orchestrator for `EMP7000` live, show:
1. OP-02 firing `TASK_ALREADY_ESCALATED` (among its other findings — this hire is HIGH tier with 5
   total reasons, so the routing to human review is visibly not the only thing detected, just the thing
   that takes priority).
2. ORCH-01 routing to `case_type: "workbench_log"` — narrate that this is a deliberate design choice,
   not the low-confidence/uncertainty path: the source system already escalated this case, so the AI
   Employee preserves that human-review requirement rather than resolving it into an automated
   notification.
3. **Execution visibly pausing** on the "Human Review" step in the Activity Timeline (status:
   "Waiting Review") — this is the moment to slow down and narrate, since a paused, waiting step is
   itself the proof this isn't simulated.
4. Open the generated review form (its own URL, distinct from the Auto workspace) — show the case
   details on screen: Case ID, Employee ID, Case Type, and the full reasons table, exactly as OP-02
   detected them, unmodified.
5. Click **Approve**, then show the workflow resuming and the final audit step completing
   (`status: "approved"`, `channel_used: "workbench"`).

> "This is the mandatory piece the rules call out specifically — a real exception, routed live to a
> human, not simulated. Watch the workflow actually pause here — it's not proceeding until a person
> acts on it. That's a real review form, not a message that says 'this would go to a human.' I'll
> approve it now, live, and you'll see the workflow resume on its own."

*Why this beat is now stronger than originally planned:* the original design only committed to "the
Workbench UI actually showing the case" — during final testing, the team discovered the initial
implementation only wrote a database row labeled "workbench" and never touched the platform's actual
Human Review feature, which would have made this beat's core claim false on camera. That gap was found
and fixed before recording (`DECISIONS.md`, `RISKS.md` R-27 for the full story) — the version demoed
here is the corrected, genuinely-verified one.

### Beat 5 — Confidential-Routing Proof (2:45–3:10)
Use **`EMP7003`** — already verified in rehearsal: real Peakon comment ("...dealing with a health
matter and have not felt able to raise it with my manager yet") correctly classifies
`confidential: true`. Trigger, show:
1. OP-03 classifying it `confidential: true`, `reasons` containing only the generic
   `SENSITIVE_DISCLOSURE_DETECTED` entry — **not** the comment text.
2. ORCH-01 routing this to `case_type: "confidential_disclosure"` — point out live that
   `_internal_case_payload` (which does carry the real comment, for the human reviewer) and `reasons`
   (which never does) are visibly different fields in the same JSON output, on screen, in one shot.
3. The message landing in the **confidential** Slack channel only.

> "The problem statement is explicit that sensitive disclosures can't leak into the general report. We
> don't just say that — watch: the real comment only ever appears in one place, and it's not the field
> anything else in the system reads from."

*This is the single most differentiating beat in the whole demo* — most competing teams will detect
risk; few will explicitly, visibly prove the confidentiality contract on camera, end to end through the
Orchestrator, not just inside one Operator. See `DECISIONS.md` ADR-005.

> **Optional, time-permitting addition:** if there's a spare 10–15 seconds, mention (verbally, no need to
> re-run live) that the same routing logic was independently verified for the other two branches this
> beat doesn't have time to show live: an IT-provisioning-only signal routes to the IT Slack channel
> (`EMP7018`, verified), and a compliance-only signal routes to a manager nudge (`EMP7035`, verified) —
> this signals the routing table's coverage is broader than what's on camera, without spending demo time
> proving each one.

### Beat 6 — Robustness Proof: An Employee the System Has Never Seen (3:10–3:40)
**Scope change from the original plan, stated honestly:** the original plan for this beat was a full
adversarial-dataset re-seed (`TASKS.md` Phase 3), which was not completed in the time available. Rather
than skip the robustness beat entirely or overstate what was tested, this beat uses a smaller, real,
already-verified proof: trigger ORCH-01 live for **`EMP9999`** — an Employee ID that does not exist
anywhere in the seeded data. Show, live:
1. OP-02 and OP-03 both return cleanly (`data_state: "no_data_yet"` / equivalent empty-but-valid result)
   — no crash, no fabricated risk finding.
2. The merge step correctly produces an empty combined signal.
3. ORCH-01's routing logic correctly resolves to `action: "none"` — no escalation, no notification, no
   error.

> "Judging happens on data we've never seen. We can't show you the full hidden dataset rehearsal we'd
> planned — we ran out of time for that specific test — but here's a concrete version of the same
> question: an employee ID that doesn't exist anywhere in our system, live, right now. Every step
> handles it cleanly. Nothing crashes, nothing invents a risk that isn't there."

*Why this is an honest substitute, not a workaround:* it's a real, unplanned-for input run live on
camera — the core claim (untested input doesn't break the pipeline) is genuinely demonstrated, just at
smaller scope than a full adversarial dataset would have proven (this doesn't test malformed dates,
name-variant duplicates, or schema drift — only "no record at all"). Say this limitation out loud in the
talking points (`§8` below) if asked, rather than implying broader coverage than what was actually run.

### Beat 7 — Business Output Close (3:40–3:50)
**Scope change, stated honestly:** OP-05 (the cohort dashboard) was deliberately not built this round —
a documented, deliberate scope cut (`TASKS.md` Phase 4, all Not Started), since it's not gate-required
and the team's remaining time was prioritized toward the Orchestrator's routing logic instead. This beat
therefore closes on the **real, quantified results already shown live in this video** rather than a
separate dashboard:

> "That's the whole loop, live, on real data: a HIGH-risk hire correctly escalated to a human, a
> confidential disclosure correctly isolated from the general report, and — off camera, but verified —
> the same routing logic correctly handling an IT-only signal and a compliance-only signal differently.
> Five distinct outcomes, one Orchestrator, zero crashes."

*Why this is a legitimate close, not a downgrade:* the "quantified result on real data" bar
(`CONTEXT.md` §7) is met by the concrete case outcomes already demonstrated in Beats 3–6 — a cohort
dashboard would summarize these same facts, not add new evidence. Naming the scope cut explicitly (one
sentence) is more credible than silently omitting Beat 7's originally-planned dashboard shot and hoping
it isn't noticed.

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
| ≥1 live exception to Workbench | 4 | Native Human Review step shown genuinely pausing execution, a real review form opened and approved on camera, execution resuming afterward — not a database write labeled "workbench" (see Beat 4's note on why this was corrected before recording) |
| Demonstrable parallel/branching/stateful | 2 (parallel), 4/5 (branching — 2 of 5 routing branches shown live on camera, 2 more mentioned verbally as independently verified per Beat 5's optional addition, `TASKS.md` 2.2.3), narration only for stateful (90-day clock is harder to show live in 4 minutes — verbally note it, don't fabricate a visual for it) |

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
- [ ] Pre-select and note down: `EMP7000` for Beat 4 (verified: 2 `Status = Escalated` rows,
      routes to `workbench_log`), `EMP7003` for Beat 5 (verified: real disclosure comment, routes to
      `confidential_disclosure`), `EMP9999` for Beat 6 (verified: does not exist, routes to `none`
      cleanly) — re-confirm all three still behave as expected immediately before recording (data could
      have shifted from earlier test runs). If mentioning the off-camera branches in Beat 5's optional
      addition, have `EMP7018` (`it_escalation`) and `EMP7035` (`manager_nudge`) noted as well, though
      these don't need to be run live.
- [ ] Confirm the Human Review dashboard (`auto.supervity.ai/u/human-review`) has no leftover
      unresolved/pending review items that would confuse the Beat 4 shot — either clear old test cases
      or be ready to point specifically at the new one that appears live.
- [ ] Confirm the confidential Slack channel is visibly empty of old test messages before Beat 5, or
      scroll to the correct message live rather than showing a cluttered history.
- [ ] Run `EMP9999` once in rehearsal immediately before recording Beat 6, to confirm it still resolves
      to a clean `action: "none"` (not e.g. `data_state` wording drifting after any later Operator edit).
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
| "How do I know the 'Workbench' step is real and not just a Slack message or a database log labeled 'workbench'?" | This is answered directly by the live pause-and-approve shown in Beat 4 itself, not just asserted — the execution trace shows a genuine "Waiting Review" status, a real generated form URL, and a resume-after-approval sequence, matching Supervity's own documented Human Review mechanism (`auto.supervity.ai/docs/guides/human-review`). Worth mentioning if pressed: an earlier build iteration *did* only write a database row, which the team caught and corrected before this recording — happy to discuss that as an example of the team's own verification discipline, not something to hide | `RISKS.md` R-27, `DECISIONS.md` |
| "How do I know this isn't hardcoded to your sample data?" | Point to Beat 6's live proof with `EMP9999` (an ID that doesn't exist in the system, handled cleanly); be upfront that a full adversarial-dataset rehearsal was planned but not completed in the time available, so this is real but narrower evidence — offer to re-run live with a judge-supplied ID on the spot if asked | `DATA_FLOW.md` §10, `MASTER_PLAN.md` §10, `TASKS.md` 3.3–3.6 (Not Started, stated honestly) |
| "What happens if the LLM classifier gets the confidential call wrong?" | Explain the fail-safe design: low-confidence always routes to a human, never defaults to "not confidential" — the asymmetry is intentional. Note honestly: the distinct low-confidence-uncertainty branch to the Workbench (`TASKS.md` 2.2.6) wasn't separately built as its own routing path this round — every tested case had high classifier confidence, so this exact scenario wasn't exercised live | `OPERATORS.md` §OP-03 Retry Behavior, `DATA_FLOW.md` §7, `TASKS.md` 2.2.6 |
| "Why isn't 'day-90 retention' measured directly?" | Explain Assumption A-01 openly: the dataset has no ground-truth attrition field, so the defensible proxy is the leading-indicator risk signal itself — shown live and correctly routed for multiple real hires this video, which is the quantified, falsifiable result the rubric asks for | `MASTER_PLAN.md` §4.1, `DECISIONS.md` ADR-007 |
| "Could a business user really change this without an engineer?" | Live-edit one `policy_config` threshold (e.g., `engagement_low_score`) in Supabase's Table Editor in front of them and re-run a case to show the changed behavior | `ARCHITECTURE.md` §7 |
| "What happens if Slack is down during judging?" | Explain the retry + escalate-to-Workbench fallback, and that the audit log write is attempted independently either way, so nothing is silently lost | `OPERATORS.md` §OP-04 Retry Behavior |
| "Why 5 Operators instead of the minimum 2?" | Explain the margin strategy: single-responsibility Operators are individually testable and the extra decomposition is what makes the audit trail and the parallel/branching behavior demonstrable at all, not decoration | `MASTER_PLAN.md` §3, `ARCHITECTURE.md` §2 |
| "Does the confidential comment ever appear anywhere outside the Workbench?" | No — walk through the contract: only OP-03 reads it, only `_internal_case_payload` carries it, only OP-04's confidential branch consumes that field, never templated into any message. Verified live end-to-end through the Orchestrator this session (`EMP7003`), not just inside OP-03 standalone | `DATA_FLOW.md` §7 |
| "Where's the cohort dashboard / OP-05?" | Not built this round — a deliberate, disclosed scope cut, not an oversight (`TASKS.md` Phase 4, all items honestly marked Not Started). The business-output evidence instead comes from the concrete, live case outcomes shown in the video itself | `TASKS.md` Phase 4 |

---

## 9. Judging Emphasis Summary

If time pressure forces a cut during recording, the priority order to preserve (highest first) is:
Beat 4 (gate-mandatory) > Beat 3 (gate: live integration) > Beat 5 (governance differentiator) >
Beat 6 (robustness proof, smaller-scope but still real and live) > Beat 2 (architecture explanation, can
be compressed) > Beat 7 (business-output close, can be shortened to a single sentence) > Beat 1 (can be
shortened, not cut — judges need the "why" to weight everything that follows).
