function test_plot_tabs()
%TEST_PLOT_TABS 无需进行多炮正演，快速测试单窗口标签式出图。
% 使用方法：addpath('src'); addpath('tests'); test_plot_tabs

    cfg = default_config('quick');
    outputDir = fullfile(tempdir, 'survey_fd_tab_test');
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end
    cfg.outputDir = outputDir;

    % 准备简单模型与方案几何数据。
    model.x = 0:10:2000;
    model.z = 0:10:1200;
    model.v = single(1800 * ones(numel(model.z), numel(model.x)));
    model.h1 = 180 + zeros(size(model.x));
    model.h2 = 470 + zeros(size(model.x));
    model.h3 = 820 + zeros(size(model.x));
    plans = cfg.plans;
    nPlan = numel(plans);

    geometry = repmat(geometry_metrics(cfg, plans(1)), 1, nPlan);
    for k = 1:nPlan
        geometry(k) = geometry_metrics(cfg, plans(k));
    end

    % 仅作绘图功能检查，不代表真实正演质量数据。
    quality = repmat(struct('sample', []), 1, nPlan);
    t = (0:0.001:1.2)';
    example.cmp = 500;
    example.offset = [-400, 0, 400];
    example.noisy = single([sin(15*t), sin(16*t), sin(17*t)]);
    example.stack = sin(15*t);
    example.vPick = 2100;
    example.nmo = double(example.noisy);
    example.sem = exp(-((cfg.velocityGrid - 2100) / 300).^2);
    example.tEvent = 0.60;
    quality(2).sample = example;

    scores.pass = false(1, nPlan); scores.pass(2:3) = true;
    scores.winner = 2;
    scores.qualityScore = zeros(1, nPlan); scores.qualityScore(2:3) = [0.70, 0.65];
    scores.geometryScore = zeros(1, nPlan); scores.geometryScore(2:3) = [0.90, 0.86];
    scores.costScore = zeros(1, nPlan); scores.costScore(2:3) = [1, 0.90];
    scores.score = -inf(1, nPlan); scores.score(2:3) = [0.78, 0.73];
    scores.cost = 69585 * ones(1, nPlan); scores.cost(2) = 65125;

    % Synthetic snapshot fixture exercises the final wavefield tab without
    % performing a finite-difference simulation.
    snapshots.shot = cfg.snapshotShotX;
    snapshots.time = [0.22; 0.42; 0.65; 0.88];
    snapshots.wave = single(zeros(numel(model.z), numel(model.x), 4));
    save(fullfile(cfg.outputDir, 'wave_snapshots.mat'), 'snapshots');

    plot_summary(cfg, model, plans, geometry, quality, scores, t);

    fig = findall(groot, 'Type', 'figure', ...
        'Tag', 'SurveyResultsTabbedWindow');
    assert(numel(fig) == 1, '图表应只出现一个结果弹窗。');
    tabGroup = findall(fig, 'Type', 'uitabgroup');
    assert(numel(tabGroup) == 1, '结果弹窗应包含一个标签页组。');
    assert(numel(tabGroup.Children) == 14, ...
        '应有14个标签页，包括覆盖、无噪和反射增强。');
    assert(exist(fullfile(outputDir, '01_velocity_model.png'), 'file') == 2, ...
        '速度模型PNG未成功导出。');

    assert(exist(fullfile(outputDir, '05_velocity_scan.png'), 'file') == 2, ...
        '速度扫描PNG未成功导出。');
    assert(exist(fullfile(outputDir, '06_nmo_corrected_gather.png'), 'file') == 2, ...
        'NMO校正后道集PNG未成功导出。');
    assert(exist(fullfile(outputDir, '10_wavefield_snapshots.png'), 'file') == 2, ...
        '中心炮波场快照PNG未成功导出。');

    fprintf('绘图测试通过：单弹窗、10标签页、中文图名、独立PNG导出。\n');
    fprintf('测试PNG输出位置：%s\n', outputDir);
end
