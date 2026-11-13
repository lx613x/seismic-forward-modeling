function run_project(mode, overrides)
%RUN_PROJECT Run 2-D acoustic forward modelling and survey comparison.
%
%   run_project()        : quick verification (CMP 200-800 m)
%   run_project('full')  : full survey (CMP 200-1800 m)
%
% Workflow:
%   1. Configuration and velocity model
%   2. Geometry-only checks
%   3. Shared multi-shot FD simulation (with validated disk cache)
%   4. Waveform quality assessment and weighted selection
%   5. Figures and export
%
% Requires base MATLAB (R2020b+ recommended), no extra toolboxes.

    if nargin < 1
        mode = 'quick';
    end

    projectRoot = fileparts(mfilename('fullpath'));
    addpath(fullfile(projectRoot, 'src'));

    cfg = default_config(mode);
    if nargin >= 2 && ~isempty(overrides)
        names = fieldnames(overrides);
        for k = 1:numel(names)
            assert(isfield(cfg, names{k}), 'Unknown configuration field: %s', names{k});
            cfg.(names{k}) = overrides.(names{k});
        end
    end
    assert(all(cfg.weights >= 0) && abs(sum(cfg.weights)-1) < 1e-10 && ...
        all(cfg.qWeights >= 0) && abs(sum(cfg.qWeights)-1) < 1e-10 && ...
        all(cfg.gWeights >= 0) && abs(sum(cfg.gWeights)-1) < 1e-10, ...
        'All weights must be nonnegative and sum to one.');
    if ~exist(cfg.outputDir, 'dir')
        mkdir(cfg.outputDir);
    end

    rng(cfg.randomSeed, 'twister');

    fprintf('\n%s\n', repmat('=', 1, 65));
    fprintf('  2-D ACOUSTIC FD | SURVEY DESIGN | %s MODE\n', upper(mode));
    fprintf('%s\n', repmat('=', 1, 65));

    % Phase 1: Model and precomputed propagator.
    model = load_velocity_model(cfg, projectRoot);
    cfg.snapshotShotX = (model.x(1) + model.x(end)) / 2;
    assert(abs((cfg.snapshotShotX - model.x(1)) / cfg.dx - ...
        round((cfg.snapshotShotX - model.x(1)) / cfg.dx)) < 1e-7, ...
        'Model centre must lie on a grid node for snapshots.');
    save(fullfile(cfg.outputDir, 'velocity_model.mat'), 'model', '-v7');
    propagator = prepare_fd(cfg, model);

    % Phase 2: CMP geometry, independent of the seismic traces.
    plans = cfg.plans;
    validate_acquisition(cfg, plans);
    numPlans = numel(plans);
    geometry = repmat(geometry_metrics(cfg, plans(1)), 1, numPlans);

    for iPlan = 1:numPlans
        geometry(iPlan) = geometry_metrics(cfg, plans(iPlan));
    end

    % Phase 3: One simulation per unique shot, reused by every plan.
    [shotX, receiverX, cleanShots] = load_or_simulate_shots( ...
        cfg, model, propagator, plans);

    % A separate central-source simulation is used only for wave snapshots.
    % It does not affect the acquisition layouts or the FD shot cache.
    save_center_snapshots(cfg, model, propagator);

    noiseStd = cfg.noiseFraction * cleanShots.peak;
    noisyShots = struct('noiseStd', noiseStd, 'seed', cfg.randomSeed);
    fprintf('[NOISE] 逐道确定性噪声标准差 %.6g；相同炮检组合共享噪声。\n', noiseStd);

    % Phase 4: Waveform metrics for feasible plans only.
    quality = evaluate_all_plans( ...
        cfg, model, plans, geometry, shotX, receiverX, ...
        cleanShots, noisyShots, propagator.time);

    scores = score_plans(cfg, plans, geometry, quality);
    print_results(plans, geometry, quality, scores);

    % Phase 5: Figures and result files.
    if cfg.makePlots
        plot_summary(cfg, model, plans, geometry, quality, ...
            scores, propagator.time);
    end

    % Keep legacy G/Q/R variable names in MAT output for v1 users.
    G = geometry; %#ok<NASGU>
    Q = quality; %#ok<NASGU>
    R = scores; %#ok<NASGU>
    save(fullfile(cfg.outputDir, 'evaluation.mat'), ...
        'cfg', 'plans', 'geometry', 'quality', 'scores', ...
        'G', 'Q', 'R', '-v7');
    export_scores(cfg, plans, geometry, quality, scores);

    fprintf('\nResults: %s\n', cfg.outputDir);
    fprintf('%s\n\n', repmat('=', 1, 65));
end
