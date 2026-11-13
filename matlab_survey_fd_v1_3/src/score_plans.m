function result = score_plans(cfg, plans, geometry, quality)
%SCORE_PLANS Compare feasible plans using stable, weighted utilities.
%
% This is a transparent teaching utility, not a guarantee of imaging quality.

    numPlans = numel(plans);
    cost = zeros(1, numPlans);
    qualityScore = zeros(1, numPlans);
    geometryScore = zeros(1, numPlans);
    pass = false(1, numPlans);

    for iPlan = 1:numPlans
        plan = plans(iPlan);
        numShots = numel(plan.sx);
        numReceivers = numel(plan.rx);

        cost(iPlan) = cfg.Cshot * numShots + ...
            cfg.Creceiver * numReceivers + ...
            cfg.Ctrace * numShots * numReceivers;

        pass(iPlan) = geometry(iPlan).pass;
        if ~pass(iPlan)
            continue;
        end

        %% 1. Data quality score (0-1)
        scaledSNR = (quality(iPlan).meanSNRdB - cfg.snrScaleDb(1)) ...
            / diff(cfg.snrScaleDb);
        snr = clamp01(scaledSNR);
        semblance = clamp01(quality(iPlan).meanSemblance);
        correlation = clamp01(quality(iPlan).meanCorrelation);

        qualityScore(iPlan) = ...
            cfg.qWeights * [snr; semblance; correlation];

        %% 2. Geometry quality score (0-1)
        fold = clamp01(geometry(iPlan).meanFold / cfg.foldTarget);
        diversity = clamp01(mean(geometry(iPlan).goodKinds) ...
            / cfg.goodTarget);
        uniformity = clamp01(1 - geometry(iPlan).cv);

        geometryScore(iPlan) = ...
            cfg.gWeights * [fold; diversity; uniformity];
    end

    %% 3. Economics score, relative to cheapest feasible plan
    costScore = zeros(1, numPlans);
    if any(pass)
        costScore(pass) = min(cost(pass)) ./ cost(pass);
    end

    %% 4. Final weighted objective with a hard feasibility gate
    score = cfg.weights(1) * qualityScore + ...
        cfg.weights(2) * geometryScore + ...
        cfg.weights(3) * costScore;
    score(~pass) = -inf;

    if any(pass)
        [~, winner] = max(score);
    else
        winner = [];
    end

    result = struct( ...
        'pass', pass, ...
        'qualityScore', qualityScore, ...
        'geometryScore', geometryScore, ...
        'costScore', costScore, ...
        'cost', cost, ...
        'score', score, ...
        'winner', winner);
end

function y = clamp01(x)
%CLAMP01 Simple deterministic score normalization helper.
    y = max(0, min(1, x));
end
