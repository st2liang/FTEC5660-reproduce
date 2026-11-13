# Speaker notes — 11 slides, ~11 min 30 s

Recorded-presentation script to accompany `deck.html` (open in any browser,
arrow keys to advance, `#5` in the URL jumps to slide 5). Timings are targets,
not limits; the deck reads fine at 10 minutes if you skip the parentheticals.

---

## 1 · Title — 25 s

> This is a reproduction of appendix item 8, *Real-Time Detection and Repair of
> LLM Agent Failures*, by Sunny Dubey. The paper claims a small one-class
> monitor can flag a failing agent before it derails, and that deterministic
> checks plus rollback can repair much of what it flags. My question was
> narrow: do the numbers hold when someone else runs the code?

## 2 · The claim — 75 s

> The system has three layers. A one-class echo-state-network ensemble reads the
> telemetry the agent already emits — surprise, entropy, latency — fused by
> CUSUM, with no labels and no healthy reference at run time. On real traces it
> detects 0.71 of failures at a 5% alarm budget. The second layer is
> deterministic: arithmetic totals, required-call coverage, tool-result shape.
> It catches 60% of failures with zero false alarms on 63 healthy runs, and 96%
> once a missing-call check is added. The third layer rolls back to the first
> violated step and re-runs from there; the paper reports 45% recovery against
> 16% for blind resampling.

## 3 · Setup — 60 s

> The single fact that made this reproducible in a day: the authors committed
> their traces. Four thousand and twenty-two episodes with labels, 2,765 of them
> healthy. So the monitor, the checks and the repair regrade all run offline —
> no Ollama, no Gemini key, no GPU. I cloned the repo, reused the system Python
> 3.13, and wrote one script that runs twelve studies in about 45 minutes.

## 4 · Result 1 — 70 s

> Table 3 reproduces to the episode. Recall is 34 of 57 and 53 of 82 — the same
> two numbers as the paper. The more interesting column is false alarms: zero on
> 63 and 38 healthy runs, against 11 and 6 for the behavioural monitor. That is
> the paper's real claim, that checks buy precision for free at equal recall.
> The held-out arm — 120 task seeds the checks were frozen before — comes out
> 30 of 56, 52 of 56 with coverage, zero of 64. And the cross-model arm on
> llama3.1:8b is a clean 110 out of 110 at zero of 10.

## 5 · Result 2 — 65 s

> On the 2,823 real episodes the detector lands on 0.7089 detection and 0.8401
> AUROC, against 0.709 and 0.840. Per class it is 0.773 goal drift, 1.000
> looping, 0.833 tool cascade and 0.286 context corruption — including the weak
> class the paper admits to. On the simulator, five seeds give 0.7065 plus or
> minus 0.0682 at AUROC 0.8721. The master seed alone is 0.693, which is what
> the repository's own README says it should be; the gap to the mean is seed
> spread the paper already reports.

## 6 · Result 3 — 60 s

> I did not re-run a single agent for the repair table. The repo persists every
> retry trace, so re-grading all 110 outcomes — 55 wrong episodes, seven rungs,
> three repeats — reproduces 45% against 16%, and net success from 52 to 73%.
> The negative rungs reproduce too: recompute 28%, adaptive 21%. That matters,
> because a reproduction that only recovers the winners is not a reproduction.

## 7 · What did not reproduce — 55 s

> Two numbers moved, neither of them a result. Step latency is 525 microseconds
> here against 219 on the authors' machine — their own UNREPRODUCIBLE file says
> that column is hardware and should not be regenerated elsewhere. And
> context-corruption coverage prints 41.5% instead of 46%, but the numerator is
> identical at 113 and the corpus grew from 244 to 272 episodes. The onset
> count, which has no denominator, is 215 of 218 exactly. Everything else is
> within 5% or exact, and the repository's claim ledger passes 121 of 121.

## 8 · The modification — 70 s

> The paper is explicit about its blind spot: a wrong-but-well-formed number is
> undetectable from telemetry and needs an external reference. I noticed the
> trajectory can supply that reference itself. If the agent calls the same tool
> with the same arguments twice, a deterministic tool must answer the same
> figures. Two identical calls that disagree mean one result is not the tool's.
> That is forty lines, wired in as a fourth check, with no threshold and no
> calibration. The interesting part was narrowing it: comparing whole strings
> false-alarmed on 28 healthy runs — truncated snippets, reworded 429s — and
> numeric tokens still cost 26. Monetary figures cost zero.

## 9 · Modification results — 65 s

> It flags 19 of 272 context-corruption episodes and zero of 2,765 healthy runs.
> Seventeen of the 19 are missed by the paper's shape check, so coverage goes
> from 41.5 to 47.8% at no precision cost, and Table 3 is byte-identical because
> healthy booking runs repeat their calls consistently. I want to be honest
> about the size: 253 of 272 episodes of that class still pass, and the check
> only works when the agent repeats the call. It is a small gain on the paper's
> own admitted weakness, not a fix.

## 10 · Gaps — 45 s

> Two things a laptop with no keys cannot claim. I did not re-collect live
> repair rollouts, organic traces or judge calibration — those need local models
> and a Gemini key; I verified their arithmetic from persisted traces instead.
> And this environment cannot push to GitHub or record a screen, so the local
> repo carries the commits and this deck stands in for the recording.

## 11 · Takeaway — 40 s

> Three things I would tell someone deciding whether to trust the paper. The
> numbers are real, at episode-level counts, on corpora the checks were frozen
> before. The paper is honest about its weak class, and that weakness is partly
> closable with an invariant it already had the data for. And the only claim
> that does not travel is the cost figure — everything else reproduces on a
> laptop in under an hour.

---

### Timing summary

| Slide | Time | Cumulative |
|---|---|---|
| 1 Title | 0:25 | 0:25 |
| 2 Claim | 1:15 | 1:40 |
| 3 Setup | 1:00 | 2:40 |
| 4 Result 1 | 1:10 | 3:50 |
| 5 Result 2 | 1:05 | 4:55 |
| 6 Result 3 | 1:00 | 5:55 |
| 7 Non-repro | 0:55 | 6:50 |
| 8 Modification | 1:10 | 8:00 |
| 9 Mod results | 1:05 | 9:05 |
| 10 Gaps | 0:45 | 9:50 |
| 11 Takeaway | 0:40 | 10:30 |

Leaves ~4 minutes of the 15-minute allowance for a live terminal walkthrough of
`repro/run_repro.ps1` and questions.
