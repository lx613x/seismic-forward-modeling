# Codex instructions: MATLAB seismic survey optimization V1.4

## Objective
Read `Codex_地震正演观测系统优化_V1.4_任务书.md` first, then inspect and update the MATLAB project in `matlab_survey_fd_v1_3/`. Follow the full task specification, preserve a reproducible baseline, and deliver the complete V1.4 project with tests and documentation.

## Non-negotiables
- Do not fabricate MATLAB test results; distinguish executed tests from static analysis.
- Improve physics and diagnostic validity before visual enhancement; preserve raw data for scoring.
- External model support: .mat v/x/z with path-driven auto-selection, no manual toggle.
- >=12 materially different acquisition alternatives, plus a true high-density mode with real added CMP traces.
- One MATLAB figure window with Chinese tabs; NMO invalid samples must not masquerade as seismic amplitude.
- Reuse identical shots across plans, validate caches by model and solver settings, and test geometry/NMO/FD stability.

## Deliverables
Complete upgraded MATLAB code, test results, representative graphics/CSV outputs if runnable, README, CHANGELOG, and honest limitations.