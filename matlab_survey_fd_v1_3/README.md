# MATLAB 二维地震正演与采集观测系统优化 V1.3

在 V1.2 成功运行的工程基础上更新：**中心炮波场快照 + 带震源延迟的速度扫描/NMO + NMO前后道集 + 单窗口10个中文图形标签**。

> 教学/研究原型。数值正演和简化速度分析尚未通过全面的地球物理基准验证，不能作为真实施工或反射成像的最终结论。

## 1. 启动（MATLAB R2025b适用）

在 MATLAB 的“当前文件夹”切换到解压后的 `matlab_survey_fd_v1_3` 目录（**包含 `run_project.m`**）。依次执行：

```matlab
addpath('src');
addpath('tests');
run_tests        % 数值和算法回归测试
```

如果基础测试通过，继续：

```matlab
test_plot_tabs   % 不用多炮正演，检查10个中文标签及PNG导出
run_project      % 快速模式
```

扩展研究区（包含1300 m断层）时：

```matlab
run_project('full')
```

默认结果写入工程 `output/` 目录，顶层仅弹出 **一个图形窗口**，通过10个标签页查看独立图表：

1. 速度模型；2. CMP覆盖；3. 综合评分；4. CMP道集；5. 速度扫描；6. NMO校正后；7. NMO叠加；8. 权重敏感性；9. Pareto分析；10. 波场快照。

## 2. 中心炮位置如何设置

修改 `default_config.m`：

```matlab
cfg.snapshotShotX = (cfg.x(1) + cfg.x(end)) / 2;
```

默认 `cfg.x = -200:10:2200`，所以是 `1000 m`。此值只控制波场快照，不参与CMP几何、采集成本和评分。

V1.2原先的 `wave_snapshots.mat` 是第一炮（可能为 `-50 m`），V1.3不会把它当作中心炮快照：旧文件第一次运行将被重新计算覆盖。多炮数据缓存 `output/forward_data.mat` 可以沿用，只要模型/数值参数/炮检排列均未改变，并且自动校验通过。

## 3. 物理和评分注意事项

- `sourceDelay=0.10` 秒是**震源子波中心时间**，不是地下传播时间。在理想双曲线模型中，速度扫描和NMO须使用 `sourceDelay + sqrt((t0-sourceDelay)^2+(x/v)^2)`。
- 现在“CMP道集”会显示一条红色**预测走时曲线**；这不代表该同相轴已被证明是目标反射波。
- “速度扫描”显示的是**某个参考时间窗的一维相干性随试验速度变化**，不是全时间范围的速度谱。
- NMO未实施拉伸切除，远偏移距的拉伸和空白区域可能存在；NMO前后道集的色标相同，便于比较。
- B、C评分基于有限差分模拟和人工噪声；分数小幅差别应通过重复噪声试验验证。新增测试：

```matlab
noise_repeat_test(5)           % 快速试验：5次噪声
noise_repeat_test(20,'quick')  % 更可靠：20次噪声
```

它不会打开第二个图形弹窗，而是把统计输出到命令行和 `output/noise_repeat_scores.csv`。

## 4. 项目结构

```text
matlab_survey_fd_v1_3/
├── run_project.m                   主程序入口
├── default_config.m                配置（含中心炮位置和权重）
├── noise_repeat_test.m             噪声稳定性独立检查
├── src/
│   ├── build_velocity.m            速度模型
│   ├── survey_plans.m              A/B/C/D观测系统
│   ├── prepare_fd.m                数值参数、外置海绵边界
│   ├── simulate_shot.m             四阶空间/二阶时间声波方程
│   ├── load_or_simulate_shots.m    共享炮集及磁盘缓存
│   ├── save_center_snapshots.m     新增中心炮快照/校验缓存
│   ├── geometry_metrics.m          CMP几何与有效偏移距
│   ├── extract_cmp.m               CMP道集抽取
│   ├── semblance_scan.m            修正震源延迟后的速度扫描
│   ├── nmo_stack.m                 修正延迟后的NMO/叠加
│   ├── quality_metrics.m           数据质量评价
│   ├── evaluate_all_plans.m        方案评价组织
│   ├── score_plans.m               硬约束+加权目标函数
│   ├── plot_summary.m              单窗口10中文标签及PNG导出
│   ├── print_results.m             命令行评价表
│   └── export_scores.m             CSV数据导出
├── tests/
│   ├── run_tests.m                 数值/几何/延迟/NMO/快照测试
│   └── test_plot_tabs.m            标签页和图表导出测试
├── figures/                        模型参考图
├── output/                         运行后自动生成数据与图片
├── CHANGELOG_V1_3.md              完整修改记录
├── VALIDATION.md                   验证局限
└── REFERENCES.md                   GitHub源码方法参考
```

## 5. 如何升级而不重复计算多炮

1. 关闭之前的 MATLAB 正演执行任务。
2. 将 `V1.2/output/forward_data.mat` 复制到 `V1.3/output/`，但**不要复制 `evaluation.mat` / `noisy_data.mat`**。
3. 运行 `run_project`。符合条件将输出 `[FD] Validated cache found ...`，避免重复多炮；中心炮快照是单独的一次FD正演。
4. 速度扫描与NMO修正后，A/B/C/D质量分数可能变化，重新检查表格、速度扫描图和NMO前后道集。

## 6. 模型限制与验证

当前常密度声学波动方程，外置海绵边界非PML，没有完全模拟真实弹性、自由表面、多次波物理、吸收衰减或成像照明；代码修复不能自动保证成像质量。详见 `VALIDATION.md`。

## 7. 开源参考

见 `REFERENCES.md`。本项目未直接混入第三方GPL源码。
