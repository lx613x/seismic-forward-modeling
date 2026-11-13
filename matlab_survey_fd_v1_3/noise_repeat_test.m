function noise_repeat_test(numRepeat, mode)
%NOISE_REPEAT_TEST Repeat synthetic-noise realizations with shared FD shots.
%
%   noise_repeat_test()            5 repetitions in quick mode
%   noise_repeat_test(20, 'quick')  20 repetitions in quick mode
%   noise_repeat_test(5, 'full')     full-extent optional test
%
% Every candidate sees the same noise field for identical shot/receiver
% combinations within one repetition. No new Figure window is created;
% results are printed and written to output/noise_repeat_scores.csv.

    if nargin < 1 || isempty(numRepeat)
        numRepeat = 5;
    end
    if nargin < 2 || isempty(mode)
        mode = 'quick';
    end
    assert(isscalar(numRepeat) && numRepeat >= 2 && ...
        mod(numRepeat, 1) == 0, ...
        'numRepeat must be an integer >= 2.');

    root = fileparts(mfilename('fullpath'));
    addpath(fullfile(root, 'src'));
    cfg = default_config(mode);
    if ~exist(cfg.outputDir, 'dir')
        mkdir(cfg.outputDir);
    end

    model = load_velocity_model(cfg, root);
    propagator = prepare_fd(cfg, model);
    plans = cfg.plans;
    numPlans = numel(plans);

    geometry = repmat(geometry_metrics(cfg, plans(1)), 1, numPlans);
    for iPlan = 1:numPlans
        geometry(iPlan) = geometry_metrics(cfg, plans(iPlan));
    end

    [shotX, receiverX, cleanShots] = load_or_simulate_shots( ...
        cfg, model, propagator, plans);

    noiseStd = cfg.noiseFraction * cleanShots.peak;
    repeatedScores = NaN(numRepeat, numPlans);

    for iRepeat = 1:numRepeat
        noisyShots = struct('noiseStd', noiseStd, ...
            'seed', cfg.randomSeed + iRepeat - 1);

        quality = evaluate_all_plans( ...
            cfg, model, plans, geometry, shotX, receiverX, ...
            cleanShots, noisyShots, propagator.time);
        scores = score_plans(cfg, plans, geometry, quality);
        repeatedScores(iRepeat, scores.pass) = scores.score(scores.pass);

        fprintf('[NOISE] Repetition %d/%d finished.\n', ...
            iRepeat, numRepeat);
    end

    fprintf('\n%-26s %12s %12s %12s\n', ...
        'Plan', 'Mean score', 'Std. dev.', 'Wins');

    winnerIndices = NaN(numRepeat, 1);
    for iRepeat = 1:numRepeat
        [best, idx] = max(repeatedScores(iRepeat, :));
        if isfinite(best)
            winnerIndices(iRepeat) = idx;
        end
    end

    planName = cell(numPlans, 1);
    meanScore = NaN(numPlans, 1);
    stdScore = NaN(numPlans, 1);
    wins = zeros(numPlans, 1);

    for iPlan = 1:numPlans
        planName{iPlan} = plans(iPlan).name;
        values = repeatedScores(:, iPlan);
        values = values(isfinite(values));
        wins(iPlan) = sum(winnerIndices == iPlan);
        if ~isempty(values)
            meanScore(iPlan) = mean(values);
            stdScore(iPlan) = std(values);
        end

        fprintf('%-26s %12.4f %12.4f %12d\n', ...
            planName{iPlan}, meanScore(iPlan), ...
            stdScore(iPlan), wins(iPlan));
    end

    report = table(planName, meanScore, stdScore, wins, ...
        'VariableNames', {'Plan', 'MeanScore', 'StdScore', 'WinnerCount'});
    outputCsv = fullfile(cfg.outputDir, 'noise_repeat_scores.csv');
    writetable(report, outputCsv);
    fprintf('Saved: %s\n', outputCsv);
end
