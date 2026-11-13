# Reproduce every offline result reported in report/reproduction_report.pdf.
# Run from any directory:  powershell -ExecutionPolicy Bypass -File run_repro.ps1
# Requires: Python 3.11+ with numpy, scipy, scikit-learn, pandas, matplotlib, pytest.
# No LLM, GPU, API key or network access is needed: every input is a trace or a
# label manifest committed in the repository.

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = Split-Path -Parent (Split-Path -Parent $here)
$logs = Join-Path $here "logs"
New-Item -ItemType Directory -Force $logs | Out-Null
Set-Location $repo

function Step($name, $block) {
    Write-Host "== $name"
    $t = Measure-Command { & $block *> (Join-Path $logs "$name.log") }
    Write-Host ("   {0:N1} s -> logs\{0}.log" -f $t.TotalSeconds)
}

Step "01_self_test"        { py -m derail.verify.checks }
Step "02_unit_tests"       { py -m pytest tests\test_verification_checks.py -q }
Step "03_table3"           { py -m derail.verify.run_verification_study }
Step "04_holdout"          { py -m derail.verify.run_verification_study --holdout organic_demo7b_holdout }
Step "05_llama8b"          { py -m derail.verify.run_verification_study --holdout organic_llama8b_cold }
Step "06_contract"         { py -m derail.verify.run_verification_study --contract-coverage }
Step "07_repeat"           { py -m derail.verify.run_verification_study --repeat-stability }
Step "08_real_traces"      { py -m derail.experiments.run_real_traces }
Step "09_repair_regrade"   { py -m derail.intervene.evaluate_repair_policies --from-csv --regrade }
Step "10_synthetic_seed"   { py -m derail.experiments.run_experiment }
Step "11_synthetic_5seed"  { py -m derail.experiments.run_multiseed }
Step "12_benchmark"        { py -m derail.experiments.run_benchmark }

# The runners above overwrite the committed artifacts with this machine's
# bytes. Restore them so the working tree keeps only the modification, and
# copy this run's numbers beside this script for comparison with the report.
$out = $here
Copy-Item results\tables\verification_vs_monitor.csv            "$out\our_verification_vs_monitor.csv" -Force
Copy-Item results\tables\verification_holdout.csv               "$out\our_verification_holdout.csv" -Force
Copy-Item results\tables\verification_organic_llama8b_cold.csv  "$out\our_verification_llama8b.csv" -Force
Copy-Item results\tables\tool_contract_denominators.csv         "$out\our_tool_contract_denominators.csv" -Force
Copy-Item results\tables\repeat_stability_coverage.csv          "$out\our_repeat_stability_coverage.csv" -Force
Copy-Item results\tables\repeat_stability_denominators.csv      "$out\our_repeat_stability_denominators.csv" -Force
Copy-Item results\tables\real_traces.csv                        "$out\our_real_traces.csv" -Force
Copy-Item results\tables\repair_policies.csv                    "$out\our_repair_policies.csv" -Force
Copy-Item results\results.json                                  "$out\our_results_synthetic_master_seed.json" -Force
Copy-Item results\tables\h1_main.csv                            "$out\our_h1_main.csv" -Force
Copy-Item results\tables\multiseed_summary.csv                  "$out\our_multiseed_summary.csv" -Force
Copy-Item results\tables\runtime.csv                            "$out\our_runtime.csv" -Force
git checkout -- results
Write-Host "done: results beside this script, logs in logs\"
