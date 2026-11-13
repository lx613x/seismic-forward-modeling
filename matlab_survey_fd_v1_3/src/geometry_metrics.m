function geometry = geometry_metrics(cfg, plan)
%GEOMETRY_METRICS Calculate CMP fold and usable-offset diversity.
%
% The offset-quality check uses a simple hyperbolic travel-time proxy.
% It is NOT a replacement for true heterogeneous wave propagation.

    cmpPositions = cfg.cmpPos;
    numCMP = numel(cmpPositions);

    fold = zeros(1, numCMP);
    goodKinds = zeros(1, numCMP);
    allOffsets = cell(1, numCMP);
    validOffsets = cell(1, numCMP);

    %% 1. Count traces in exact regular CMP bins
    for iShot = 1:numel(plan.sx)
        for iReceiver = 1:numel(plan.rx)
            midpoint = (plan.sx(iShot) + plan.rx(iReceiver)) / 2;
            iCMP = cmp_bin_index(midpoint, cmpPositions, cfg.cmpBinWidth);

            if iCMP == 0
                continue;
            end

            absOffset = abs(plan.rx(iReceiver) - plan.sx(iShot));
            fold(iCMP) = fold(iCMP) + 1;
            allOffsets{iCMP}(end + 1) = absOffset; %#ok<AGROW>

            %% 2. Approximate velocity sensitivity and NMO stretch
            travelTime1 = sqrt(cfg.geomTZero^2 + ...
                (absOffset / cfg.geomV1)^2);
            travelTime2 = sqrt(cfg.geomTZero^2 + ...
                (absOffset / cfg.geomV2)^2);

            moveoutDifferenceMs = 1000 * abs(travelTime1 - travelTime2);
            stretch = (travelTime1 - cfg.geomTZero) / cfg.geomTZero;

            passesOffsetCheck = ...
                moveoutDifferenceMs >= cfg.minMoveoutMs && ...
                stretch <= cfg.maxNmoStretch;

            if passesOffsetCheck
                validOffsets{iCMP}(end + 1) = absOffset; %#ok<AGROW>
            end
        end
    end

    %% 3. Distinct absolute offsets, not total trace count
    for iCMP = 1:numCMP
        goodKinds(iCMP) = numel(unique(validOffsets{iCMP}));
    end

    meanFold = mean(fold);
    if meanFold > 0
        foldCV = std(fold, 1) / meanFold;
    else
        foldCV = inf;
    end

    geometry = struct( ...
        'cmp', cmpPositions, ...
        'fold', fold, ...
        'goodKinds', goodKinds, ...
        'allOffsets', {allOffsets}, ...
        'validOffsets', {validOffsets}, ...
        'minFold', min(fold), ...
        'minKinds', min(goodKinds), ...
        'meanFold', meanFold, ...
        'cv', foldCV);

    geometry.pass = ...
        geometry.minFold >= cfg.minFold && ...
        geometry.minKinds >= cfg.minUsableKinds;
    reasons = {};
    if geometry.minFold < cfg.minFold, reasons{end+1} = 'fold below minimum'; end
    if geometry.minKinds < cfg.minUsableKinds, reasons{end+1} = 'offset diversity below minimum'; end
    geometry.failReason = strjoin(reasons, '; ');
end
