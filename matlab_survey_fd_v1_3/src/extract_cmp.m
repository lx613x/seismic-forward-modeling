function [clean, noisy, offsets, traceInfo] = extract_cmp( ...
    plan, cmpPosition, shotX, commonReceiverX, cleanShots, noisyShots, cfg)
%EXTRACT_CMP Extract an exact CMP gather from shared forward shot records.
%
% Both clean and noisy traces are indexed from the same source/receiver
% coordinates. Offset sign is preserved and the gather is sorted by offset.

    if nargin < 7
        binWidth = 0; % 兼容旧接口的精确 CMP 匹配
    else
        binWidth = cfg.cmpBinWidth;
    end
    clean = [];
    noisy = [];
    offsets = [];
    sourcePositions = []; receiverPositions = []; midpoints = [];

    for iShot = 1:numel(plan.sx)
        shotIndex = find(shotX == plan.sx(iShot), 1);
        assert(~isempty(shotIndex), 'Required shot was not simulated.');

        if isstruct(cleanShots)
            mids = (plan.sx(iShot) + plan.rx) / 2;
            if binWidth == 0
                hasTrace = any(abs(mids - cmpPosition) <= 1e-8);
            else
                hasTrace = any(mids >= cmpPosition - binWidth / 2 & ...
                    mids < cmpPosition + binWidth / 2);
            end
            if ~hasTrace, continue; end
            shotData = load(cleanShots.files{shotIndex}, 'record');
        end
        for iReceiver = 1:numel(plan.rx)
            midpoint = (plan.sx(iShot) + plan.rx(iReceiver)) / 2;

            if binWidth == 0
                inBin = abs(midpoint - cmpPosition) <= 1e-8;
            else
                inBin = midpoint >= cmpPosition - binWidth / 2 && ...
                    midpoint < cmpPosition + binWidth / 2;
            end
            if ~inBin
                continue;
            end

            receiverIndex = find( ...
                commonReceiverX == plan.rx(iReceiver), 1);
            assert(~isempty(receiverIndex), ...
                'Required receiver was not simulated.');

            if isstruct(cleanShots)
                trace = shotData.record(:, receiverIndex);
                % Unique grid-coordinate pair maps to a repeatable local stream.
                sxIndex = round((plan.sx(iShot) - cleanShots.gridOrigin) / cleanShots.dx);
                rxIndex = round((plan.rx(iReceiver) - cleanShots.gridOrigin) / cleanShots.dx);
                pair = sxIndex * cleanShots.gridCount + rxIndex;
                seed = mod(double(noisyShots.seed) + pair * 104729, 2^32 - 1);
                stream = RandStream('mt19937ar', 'Seed', seed);
                noise = single(noisyShots.noiseStd) * randn(stream, size(trace), 'single');
                clean(:, end + 1) = trace; %#ok<AGROW>
                noisy(:, end + 1) = trace + noise; %#ok<AGROW>
            else
                clean(:, end + 1) = cleanShots(:, receiverIndex, shotIndex); %#ok<AGROW>
                noisy(:, end + 1) = noisyShots(:, receiverIndex, shotIndex); %#ok<AGROW>
            end
            offsets(end + 1) = ...
                plan.rx(iReceiver) - plan.sx(iShot); %#ok<AGROW>
            sourcePositions(end + 1) = plan.sx(iShot); %#ok<AGROW>
            receiverPositions(end + 1) = plan.rx(iReceiver); %#ok<AGROW>
            midpoints(end + 1) = midpoint; %#ok<AGROW>
        end
    end

    [offsets, order] = sort(offsets);
    clean = clean(:, order);
    noisy = noisy(:, order);
    traceInfo = struct('sourceX', sourcePositions(order), ...
        'receiverX', receiverPositions(order), 'midpoint', midpoints(order));
end
