# V1.4 开发分支：使用方法与验证状态

本分支在 V1.3 上开发，保留原目录和 A–D 炮检几何。**尚未在 MATLAB 中运行或完成任务书全部验收，不能视为已验证的 V1.4 正式版**。已执行的独立几何检查、未执行的测试及待完成项目见 `VALIDATION_V1_4.md`。

## 运行

在 MATLAB R2025b 进入 `matlab_survey_fd_v1_3`：

```matlab
run_project('quick')  % 普通几何，包含 A–L 方案
run_project('dense')  % 额外增加 M：20 m 炮距和道距，计算量明显增加
run_project('full')   % 200–1800 m CMP 范围，耗时最长
addpath('tests'); run_tests; test_plot_tabs
noise_repeat_test(5, 'quick')
```

模式根据 `default_config.m` 创建参数；第二个参数可覆盖其中现有字段，例如：

```matlab
addpath('examples')
create_external_model(fullfile(pwd, 'external_model.mat'))
opt.modelFile = fullfile(pwd, 'external_model.mat');
opt.targetTime = 0.67;  % 记录时间，包含 0.10 s 震源中心延迟，仅为示例近似值
run_project('quick', opt)
```

`modelFile=''` 选用内置模型。MAT 文件需提供二维 `v(z,x)`、向量 `x`、`z`，也可放在 `model` 结构体内。坐标须与配置网格完全一致、递增等距，速度必须有限且为正；不插值、不裁剪、不外推。外部模型必须指定目标事件记录时间 `targetTime`，应依据模型和震源延迟设置，示例不代表自动拾取。求解器还会检查 CFL 和频散；炮检位置必须在网格上。

可在 `default_config.m` 修改速度扫描范围、源参数、`maxNmoStretch`（默认 0.30）、CMP bin 宽、目标窗及权重；权重需非负并各自合计 1。CMP bin 左闭右开，宽度默认为 25 m，中心间距必须等于 bin 宽。修改网格或方案后须同时保证炮检位置、CMP 范围及深度合法。

## 数据和显示

`output/shot_cache` 按炮保存无噪数据，校验完整速度矩阵、网格、炮检点和 FD 参数；跨方案共享炮点记录。需重算时可删除该目录或设置 `useDiskCache=false`。关闭磁盘缓存后仍会使用临时目录存放单炮数据，系统临时目录需自行清理。噪声由炮检坐标和随机种子生成，相同组合在同一次运行内一致；噪声水平按本次所有炮记录的全局峰值确定，因此改变整个候选集可能改变噪声水平。

`output/evaluation.mat` 与 `scores.csv` 保存结果，原始无噪记录保存在逐炮缓存中。原始道集、无噪道集、目标窗增强、NMO 和波场图均在一个窗口的中文标签页；反射增强是逐道目标窗归一化和截幅，仅用于显示。NMO 灰色背景表示无效或拉伸切除，原始和 NMO 图使用共同振幅标尺。波场“原始振幅”使用统一物理标尺；增强图逐帧归一化并平方根压缩，不能比较不同时刻的实际振幅。

## 计算开销与解释

启动时打印单精度炮记录的未压缩大小估算 `4 × 时间样点 × 联合检波点 × 联合炮点`，以及炮数；每次仅加载单炮记录，磁盘文件还包含模型元数据，实际磁盘占用和时间取决于压缩、机器及缓存。`dense` 和 `full` 可能需要较长时间及较大磁盘空间，请先用 `quick`；没有自动可用空间检查或经过实测的运行时间。`score` 仍为教学型加权效用；oracle-SNR 使用无噪真值，不能直接用于野外数据。相干谱的速度是近似 NMO 速度而非复杂介质真实层速度。反射事件可见性和边界效应仍需在真实 MATLAB 运行后检查。
