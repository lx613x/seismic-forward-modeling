# V1.2 更新记录（2026-11-12）

- 图形输出由多个独立弹窗修改成**一个独立弹窗 + 顶部标签切换**，每个概念图仍独立显示。
- 把速度模型、CMP覆盖、评分、CMP道集、叠加、权重敏感性、Pareto和快照的标题与坐标轴中文化。
- 拆开了原来的“CMP道集+叠加图”双面板，分别成独立标签与PNG。
- 每张图保持独立PNG导出；再次运行会替换旧结果弹窗。
- 新增无多炮正演开销的图形冒烟测试 `tests/test_plot_tabs.m`。
- 数值模拟算法、物理参数、综合评分函数没有变化。

# V1.1 · Code style and figure layout cleanup

- Split long monolithic main script into `load_or_simulate_shots`, `evaluate_all_plans`, `print_results` and `export_scores`.
- Standardized four-space indentation, variable names, operator spacing and section comments throughout `.m` sources.
- Made `run_project` callable as `run_project` or `run_project('full')`.
- Matched figure canvas sizes and axis typography; simplified multi-panel and comparison plots.
- Rendered failed-plan metrics as `--` in the console while keeping numeric `NaN/-Inf` in machine-readable results.
- Preserved legacy `G / Q / R` keys in `evaluation.mat`.
- Added compatibility for the v1 disk cache fields `shotsClean` and `rxAll` when physics and geometry validate.
- Extended test function to cover weighted scoring.
- Numerical scheme, noise definition, and objective scoring constants remain unchanged.

## Verification status

Static file and interface checks completed in the authoring environment. MATLAB runtime is unavailable here; please run `addpath('tests'); run_tests` before relying on results. The user's prior V1 tests passed, but V1.1 needs its own MATLAB check.
