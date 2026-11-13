# Reproduction package — *Real-Time Detection and Repair of LLM Agent Failures*

Course: FTEC5660 Agentic AI for Business and FinTech — Individual homework 2
(paper reproduction). Target paper: appendix item 8, Sunny Dubey,
*Real-Time Detection and Repair of LLM Agent Failures*, arXiv:2608.02464.

This directory holds everything produced by the reproduction: the numbers our
re-runs emitted and the one-command script that regenerates them. The code
change lives in the repository this folder sits in.

```
..\..\derail\verify\checks.py      + repeat_stability()
..\..\derail\verify\run_verification_study.py  + --repeat-stability mode
reproduction\
   package\run_repro.ps1           runs all 12 studies, ~45 min on one laptop
   package\our_*.csv               what our runs produced
   package\paper_vs_ours.csv       every target, paper value vs ours
   package\our_env.txt             interpreter and library versions
   report\reproduction_report.pdf  the 6-page report (+ HTML source, figures)
```

Logs are not committed: `run_repro.ps1` writes them to `logs\` beside this
README, which `.gitignore` excludes.

## Environment actually used

| item | value |
|---|---|
| OS | Windows 11 Home (China), 22H2 |
| CPU / RAM | Intel Core i7-11800H, 8C/16T, 15.8 GB |
| Python | 3.13.17 (system interpreter, reused — no venv) |
| numpy / pandas / scipy / sklearn | 2.5.4 / 3.1.1 / 1.18.1 / 1.9.1 |
| torch | 2.6.0+cu124 (CUDA present, unused — all runs are CPU) |

The repository pins numpy 2.4.6 / pandas 3.0.3. The two-version gap changes only
the last digit of floats; metrics agree to the fourth decimal (visible in the
log of the master-seed step). No dependency was installed beyond
`pypdf`/`requests` (paper download) and the scientific stack above.

## What reproduces, and how to check it

Every command is offline: the repo commits 4,022 episode traces plus their label
manifests, so no Ollama server, Gemini key or GPU is needed.

Environment caveat: the repository's full suite runs 868 passed / 25 skipped /
8 failed on this machine. The failures inspected are import errors for optional
extras that are not installed (`autogen_core`, `langchain_core`, `sqlalchemy`);
none of them is in the verification or monitor suites, which pass in full.

| # | command | reproduces |
|---|---|---|
| 1 | `py -m derail.verify.run_verification_study` | Table 3: checks vs monitor, T=0.2 and T=0.9 |
| 2 | `py -m derail.verify.run_verification_study --holdout organic_demo7b_holdout` | held-out 120-seed arm (54% / 93% / 0 of 64) |
| 3 | `py -m derail.verify.run_verification_study --holdout organic_llama8b_cold` | cross-model arm (110 of 110 at 0 of 10) |
| 4 | `py -m derail.verify.run_verification_study --contract-coverage` | tool_contract false positives and onset timing |
| 5 | `py -m derail.verify.run_verification_study --repeat-stability` | **our modification** across every labelled corpus |
| 6 | `py -m derail.experiments.run_real_traces` | real-corpus ESN: 0.709 detection, 0.840 AUROC |
| 7 | `py -m derail.intervene.evaluate_repair_policies --from-csv --regrade` | Table 4 repair rungs, re-derived from persisted retry traces |
| 8 | `py -m derail.experiments.run_experiment` | synthetic testbed, master seed (415 s) |
| 9 | `py -m derail.experiments.run_multiseed` | synthetic testbed, five seeds (~40 min) |
| 10 | `py -m derail.experiments.run_benchmark` | fit time, step latency, footprint |
| 11 | `py -m derail.verify.checks` + `py -m pytest tests\test_verification_checks.py` | self-test and 24 unit tests |

`run_repro.ps1` chains all of them and copies the outputs beside itself.

## The modification

`repeat_stability` (in `derail\verify\checks.py`, wired into `verify()`): a
repeated identical tool call — same tool, same canonical arguments — that
returns a different monetary figure is a violation. The run's own earlier
replay is the reference the paper says plausible-value corruption needs.

Measured on the committed corpora (`our_repeat_stability_denominators.csv`):

| label | flagged | n |
|---|---|---|
| context_corruption | 19 | 272 |
| healthy | **0** | 2765 |
| every other injected class | 0 | 985 |

17 of the 19 are episodes `tool_contract` misses, lifting its context-corruption
coverage from 41.5% (113/272) to 47.8% (130/272) at zero additional false
positives. Table 3 is unchanged (the organic arms produce no findings), so the
change is strictly additive.

## What could not be reproduced, and why

* **Live repair runs.** Table 4 is reproduced at the analysis layer by
  re-deriving all 110 episodes x rungs from the committed retry traces
  (`--from-csv --regrade`), which reproduces 45% vs 16% and 52% -> 73% exactly.
  Re-sampling the agents themselves needs a local `ollama` server with
  qwen2.5:7b plus the gemini-2.5-flash judge key, which we do not have; the
  artifacts let us verify the arithmetic without pretending to new samples.
* **Generator-side studies** (`run_organic_collection`, live judge calibration)
  need the same models/keys. Their committed tables are unchanged and are
  covered by `py -m devtools.claims_ledger --check` (121/121 claims match).
* **Step latency.** 219 us is a reference-machine number; this laptop measures
  525 us for the same monitor. Expected and documented by the authors in
  `results\tables\UNREPRODUCIBLE.md` at the repository root.
* **Recorded presentation.** This environment has no screen recorder, so the
  deck in `..\slides\` stands in for the walkthrough; the repository commit
  carries the package, the report and the deck.
