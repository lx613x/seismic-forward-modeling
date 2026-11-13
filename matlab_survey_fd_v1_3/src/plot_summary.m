function plot_summary(cfg, model, plans, geometry, quality, scores, time)
%PLOT_SUMMARY 在同一个独立弹窗中用标签页展示各张图。
%
% 每个标签页是独立图表，不采用把所有图拼在一个页面上的方案。
% 仍分别导出 PNG；只创建一个 MATLAB figure 窗口。
% 兼容 MATLAB R2020b+（经典 figure + uitabgroup + uitab）。

    outputDir = cfg.outputDir;
    numPlans = numel(plans);
    planIds = cell(1, numPlans);
    for iPlan = 1:numPlans
        planIds{iPlan} = plans(iPlan).name(1);  % A, B, C, D
    end

    %% 创建唯一的独立图形窗口及标签组
    % 再次运行程序时关闭旧版结果窗口，避免叠加弹窗。
    oldFigures = findall(groot, 'Type', 'figure', ...
        'Tag', 'SurveyResultsTabbedWindow');
    if ~isempty(oldFigures)
        close(oldFigures);
    end

    fig = figure( ...
        'Name', '二维地震正演与观测系统综合评价', ...
        'Tag', 'SurveyResultsTabbedWindow', ...
        'NumberTitle', 'off', ...
        'WindowStyle', 'normal', ...
        'Color', 'w', ...
        'Units', 'pixels', ...
        'Position', [100, 75, 1180, 740]);

    tabGroup = uitabgroup('Parent', fig, ...
        'Units', 'normalized', ...
        'Position', [0, 0, 1, 1]);

    %% 标签1：复杂二维速度模型
    tabModel = uitab('Parent', tabGroup, 'Title', '速度模型');
    ax = make_axes(tabModel);
    imagesc(ax, model.x, model.z, double(model.v));
    set(ax, 'YDir', 'reverse');
    axis(ax, 'tight');
    caxis(ax, [1500, 3300]);
    colormap(ax, parula);
    cb = colorbar(ax);
    cb.Label.String = '速度 (m/s)';
    hold(ax, 'on');
    plot(ax, model.x, model.h1, 'k:', 'LineWidth', 1);
    plot(ax, model.x, model.h2, 'k:', 'LineWidth', 1);
    plot(ax, model.x, model.h3, 'k:', 'LineWidth', 1);
    line(ax, [1300, 1300], [min(model.z), max(model.z)], ...
        'Color', 'w', 'LineStyle', '--', 'LineWidth', 1.3);
    text(ax, 1315, 115, '断层', 'Color', 'w', 'FontSize', 11);
    % The marked centre shot is only used for the wavefield snapshots.
    if isfield(cfg, 'snapshotShotX')
        plot(ax, cfg.snapshotShotX, cfg.sourceZ, 'rp', ...
            'MarkerSize', 12, 'MarkerFaceColor', 'r');
        text(ax, cfg.snapshotShotX + 45, cfg.sourceZ + 40, ...
            '中心快照炮', 'Color', 'w', 'FontSize', 10);
    end
    hold(ax, 'off');
    xlabel(ax, '水平距离 (m)');
    ylabel(ax, '深度 (m)');
    title(ax, '复杂二维声波速度模型');
    export_chart(ax, fig, tabGroup, tabModel, outputDir, '01_velocity_model.png');

    %% 标签2：CMP覆盖次数
    tabFold = uitab('Parent', tabGroup, 'Title', 'CMP覆盖');
    ax = make_axes(tabFold);
    hold(ax, 'on');
    for iPlan = 1:numPlans
        plot(ax, geometry(iPlan).cmp, geometry(iPlan).fold, ...
            'LineWidth', 1.7, 'DisplayName', plans(iPlan).name);
    end
    yline(ax, cfg.minFold, 'k--', '最低覆盖要求', 'LineWidth', 1.2);
    xlabel(ax, 'CMP位置 (m)');
    ylabel(ax, '几何覆盖次数');
    title(ax, '不同观测系统的CMP覆盖次数对比');
    legend(ax, 'Location', 'eastoutside', 'Interpreter', 'none');
    grid(ax, 'on');
    hold(ax, 'off');
    export_chart(ax, fig, tabGroup, tabFold, outputDir, '02_cmp_folds.png');

    %% 标签3：综合评分
    tabScores = uitab('Parent', tabGroup, 'Title', '综合评分');
    ax = make_axes(tabScores);
    scoreData = [scores.qualityScore(:), ...
                 scores.geometryScore(:), ...
                 scores.costScore(:), ...
                 scores.score(:)];
    scoreData(~scores.pass, :) = NaN;
    bar(ax, scoreData, 'grouped');
    ylim(ax, [0, 1.05]);
    set(ax, 'XTick', 1:numPlans, 'XTickLabel', planIds);
    xlabel(ax, '观测系统方案');
    ylabel(ax, '归一化评分');
    title(ax, '质量、几何、成本和综合评分（仅显示合格方案）');
    legend(ax, {'数据质量', '几何质量', '经济性', '综合评分'}, ...
        'Location', 'northoutside', 'Orientation', 'horizontal');
    grid(ax, 'on');
    export_chart(ax, fig, tabGroup, tabScores, outputDir, '03_scores.png');

    if isempty(scores.winner)
        tabGroup.SelectedTab = tabModel;
        return;
    end

    %% 标签4：原始CMP道集及目标反射走时预测
    example = quality(scores.winner).sample;
    if ~isempty(example)
        amplitudeLimit = max(abs(double(example.noisy(:))));
        if ~isfinite(amplitudeLimit) || amplitudeLimit == 0
            amplitudeLimit = 1;
        end

        tabGather = uitab('Parent', tabGroup, 'Title', 'CMP道集');
        ax = make_axes(tabGather);
        imagesc(ax, 1:numel(example.offset), time, double(example.noisy));
        set(ax, 'YDir', 'reverse');
        colormap(ax, gray);
        caxis(ax, [-amplitudeLimit, amplitudeLimit]);
        cb = colorbar(ax);
        cb.Label.String = '振幅';
        set_offset_ticks(ax, example.offset);
        hold(ax, 'on');
        referenceTime = cfg.sourceDelay + sqrt( ...
            (example.tEvent - cfg.sourceDelay)^2 + ...
            (double(example.offset) / example.vPick).^2);
        plot(ax, 1:numel(example.offset), referenceTime, ...
            'r--', 'LineWidth', 1.5);
        hold(ax, 'off');
        xlabel(ax, '有符号炮检距 (m)');
        ylabel(ax, '时间 (s)');
        title(ax, sprintf('CMP = %g m：含噪记录与理论走时（红虚线）', ...
            example.cmp));
        export_chart(ax, fig, tabGroup, tabGather, ...
            outputDir, '04_cmp_gather.png');

        %% 标签5：相干速度扫描（并非二维速度谱）
        tabVelocity = uitab('Parent', tabGroup, 'Title', '速度扫描');
        ax = make_axes(tabVelocity);
        plot(ax, cfg.velocityGrid, example.sem, ...
            'b-o', 'LineWidth', 1.6);
        hold(ax, 'on');
        xline(ax, example.vPick, 'r--', ...
            sprintf('拾取：%g m/s', example.vPick), ...
            'LineWidth', 1.2);
        xlabel(ax, '候选NMO速度 (m/s)');
        ylabel(ax, '时间窗相干系数');
        title(ax, sprintf('CMP = %g m：参考时间 %.3f s 的速度扫描', ...
            example.cmp, example.tEvent));
        ylim(ax, [0, 1.05]);
        grid(ax, 'on');
        hold(ax, 'off');
        export_chart(ax, fig, tabGroup, tabVelocity, ...
            outputDir, '05_velocity_scan.png');

        %% 标签6：NMO校正后的CMP道集
        tabNMO = uitab('Parent', tabGroup, 'Title', 'NMO校正后');
        ax = make_axes(tabNMO);
        imagesc(ax, 1:numel(example.offset), time, double(example.nmo));
        set(ax, 'YDir', 'reverse');
        colormap(ax, gray);
        caxis(ax, [-amplitudeLimit, amplitudeLimit]);
        cb = colorbar(ax);
        cb.Label.String = '振幅';
        set_offset_ticks(ax, example.offset);
        hold(ax, 'on');
        yline(ax, example.tEvent, 'r--', ...
            '参考零偏移距时间', 'LineWidth', 1.2);
        hold(ax, 'off');
        xlabel(ax, '有符号炮检距 (m)');
        ylabel(ax, '时间 (s)');
        title(ax, sprintf('CMP = %g m：NMO校正后道集（未做拉伸切除）', ...
            example.cmp));
        export_chart(ax, fig, tabGroup, tabNMO, ...
            outputDir, '06_nmo_corrected_gather.png');

        %% 标签7：NMO平均叠加道
        tabStack = uitab('Parent', tabGroup, 'Title', 'NMO叠加');
        ax = make_axes(tabStack);
        plot(ax, time, example.stack, 'k', 'LineWidth', 1.5);
        hold(ax, 'on');
        xline(ax, example.tEvent, 'r--', ...
            '目标反射时间', 'LineWidth', 1.2);
        hold(ax, 'off');
        xlim(ax, [0.35, min(1.10, max(time))]);
        xlabel(ax, '时间 (s)');
        ylabel(ax, '叠加振幅');
        title(ax, sprintf('NMO叠加结果：拾取速度 %g m/s', ...
            example.vPick));
        grid(ax, 'on');
        export_chart(ax, fig, tabGroup, tabStack, ...
            outputDir, '07_nmo_stack.png');
    end

    %% 标签8：综合评分对质量权重的敏感性
    qualityWeight = 0:0.02:1;
    scoreByWeight = NaN(numel(qualityWeight), numPlans);
    mix = cfg.weights(2:3) / sum(cfg.weights(2:3));
    for iWeight = 1:numel(qualityWeight)
        w = qualityWeight(iWeight);
        scoreByWeight(iWeight, scores.pass) = ...
            w * scores.qualityScore(scores.pass) + ...
            (1 - w) * ( ...
                mix(1) * scores.geometryScore(scores.pass) + ...
                mix(2) * scores.costScore(scores.pass));
    end

    tabWeights = uitab('Parent', tabGroup, 'Title', '权重敏感性');
    ax = make_axes(tabWeights);
    hold(ax, 'on');
    for iPlan = find(scores.pass)
        plot(ax, qualityWeight, scoreByWeight(:, iPlan), ...
            'LineWidth', 2, 'DisplayName', plans(iPlan).name);
    end
    xlabel(ax, '数据质量权重');
    ylabel(ax, '综合效用评分');
    title(ax, '不同质量权重下的方案综合评分');
    legend(ax, 'Location', 'eastoutside', 'Interpreter', 'none');
    grid(ax, 'on');
    hold(ax, 'off');
    export_chart(ax, fig, tabGroup, tabWeights, outputDir, '08_weight_sensitivity.png');

    %% 标签9：质量-成本二维Pareto投影
    feasible = find(scores.pass);
    dominated = false(size(feasible));
    for i = 1:numel(feasible)
        for j = 1:numel(feasible)
            if i == j
                continue;
            end
            a = feasible(i);
            b = feasible(j);
            notWorse = scores.cost(b) <= scores.cost(a) && ...
                scores.qualityScore(b) >= scores.qualityScore(a);
            strictlyBetter = scores.cost(b) < scores.cost(a) || ...
                scores.qualityScore(b) > scores.qualityScore(a);
            if notWorse && strictlyBetter
                dominated(i) = true;
            end
        end
    end

    tabPareto = uitab('Parent', tabGroup, 'Title', 'Pareto分析');
    ax = make_axes(tabPareto);
    hold(ax, 'on');
    plot(ax, scores.cost(feasible), scores.qualityScore(feasible), ...
        'ko', 'MarkerSize', 7, 'DisplayName', '可行方案');
    plot(ax, scores.cost(feasible(~dominated)), ...
        scores.qualityScore(feasible(~dominated)), ...
        'ro', 'MarkerSize', 10, 'LineWidth', 1.8, ...
        'DisplayName', '非支配方案');
    for i = 1:numel(feasible)
        k = feasible(i);
        text(ax, scores.cost(k), scores.qualityScore(k), ...
            ['  ' planIds{k}], 'FontSize', 11);
    end
    xlabel(ax, '采集成本（教学成本单位）');
    ylabel(ax, '数据质量评分');
    title(ax, '数据质量与采集成本的Pareto投影');
    legend(ax, 'Location', 'best');
    grid(ax, 'on');
    hold(ax, 'off');
    export_chart(ax, fig, tabGroup, tabPareto, outputDir, '09_pareto_projection.png');

    %% 标签10：中心炮波场快照（同一个标签内比较不同时刻）
    snapshotFile = fullfile(outputDir, 'wave_snapshots.mat');
    if exist(snapshotFile, 'file')
        snapshotData = load(snapshotFile);
        if isfield(snapshotData, 'snapshots')
            snapshots = snapshotData.snapshots;
        elseif isfield(snapshotData, 'snaps')
            snapshots = snapshotData.snaps;  % 兼容旧版结果
        else
            snapshots = [];
        end

        % Never show a v1.2 first-shot snapshot as a centre-shot result.
        isCentreShot = ~isempty(snapshots) && ...
            isfield(snapshots, 'shot') && ...
            isequal(snapshots.shot, cfg.snapshotShotX);

        if isCentreShot && ~isempty(snapshots.time)
            tabWave = uitab('Parent', tabGroup, 'Title', '波场快照');
            nSnap = numel(snapshots.time);
            cols = ceil(nSnap / 2);
            layout = tiledlayout(tabWave, 2, cols, ...
                'TileSpacing', 'compact', 'Padding', 'compact');
            for iSnap = 1:nSnap
                ax = nexttile(layout);
                wave = double(snapshots.wave(:, :, iSnap));
                imagesc(ax, model.x, model.z, wave);
                set(ax, 'YDir', 'reverse');
                axis(ax, 'tight');
                maxAmp = max(abs(wave(:)));
                if maxAmp > 0
                    caxis(ax, [-maxAmp, maxAmp]);
                end
                colormap(ax, gray);
                title(ax, sprintf('炮点 %g m，传播时间 %.2f s', ...
                    snapshots.shot, snapshots.time(iSnap)));
                xlabel(ax, '水平距离 (m)');
                ylabel(ax, '深度 (m)');
            end
            export_chart(layout, fig, tabGroup, tabWave, ...
                outputDir, '10_wavefield_snapshots.png');
        end
    end

    % 默认打开速度模型标签，用户可以直接单击切换到其他图。
    tabGroup.SelectedTab = tabModel;
    drawnow;
end

function ax = make_axes(tab)
%MAKE_AXES 为单个标签页创建填满大部分区域的独立坐标轴。
    ax = axes('Parent', tab, ...
        'Units', 'normalized', ...
        'Position', [0.09, 0.13, 0.77, 0.75], ...
        'FontName', 'Microsoft YaHei', ...
        'FontSize', 11, ...
        'LineWidth', 0.9, ...
        'Box', 'on');
end

function export_chart(target, fig, tabGroup, tab, outputDir, fileName)
%EXPORT_CHART 导出每张图的PNG，不创建任何新的图窗。
% exportgraphics 直接导出坐标轴或布局；旧版本回退至saveas。
    tabGroup.SelectedTab = tab;
    axesFound = findall(tab, 'Type', 'axes');
    for i = 1:numel(axesFound)
        set(axesFound(i), 'FontName', 'Microsoft YaHei', ...
            'FontSize', 11, 'LineWidth', 0.9);
        try
            axesFound(i).Toolbar.Visible = 'off';
        catch
            % 兼容未提供坐标轴工具栏属性的MATLAB版本。
        end
    end

    drawnow;
    filePath = fullfile(outputDir, fileName);
    try
        exportgraphics(target, filePath, 'Resolution', 170);
    catch exportError
        warning('图像导出使用兼容模式：%s', exportError.message);
        saveas(fig, filePath);
    end
end

function set_offset_ticks(ax, offsets)
%SET_OFFSET_TICKS Show physical signed offsets on equally spaced trace slots.
    step = max(1, round(numel(offsets) / 9));
    tickIndex = 1:step:numel(offsets);
    set(ax, 'XTick', tickIndex, ...
        'XTickLabel', arrayfun(@num2str, offsets(tickIndex), ...
        'UniformOutput', false));
end
