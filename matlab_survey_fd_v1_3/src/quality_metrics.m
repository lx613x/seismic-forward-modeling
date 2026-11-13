function quality = quality_metrics( ...
    cfg, model, plan, shotX, receiverX, cleanShots, noisyShots, time)
%QUALITY_METRICS Waveform metrics measured on full-wave FD shot records.
%
% SNR is an ORACLE synthetic metric: clean FD traces serve as ground truth.
% This is valid for a controlled simulation, not directly for field records.

    snrDb = [];
    peakSemblance = [];
    velocityPickPerturbation = [];
    stackCorrelation = [];
    example = [];

    for cmpPosition = cfg.qualityCMP
        %% 1. Extract the identical source/receiver combinations
        [clean, noisy, offsets, traceInfo] = extract_cmp( ...
            plan, cmpPosition, shotX, receiverX, cleanShots, noisyShots, cfg);

        if numel(offsets) < 3
            continue;
        end

        %% 2. Approximate zero-offset time of second interface
        if ~isempty(cfg.targetTime)
            targetTime = cfg.targetTime;
        else
        [~, iX] = min(abs(model.x - cmpPosition));
            depth1 = model.h1(iX);
            depth2 = model.h2(iX);
            targetTime = cfg.sourceDelay + 2 * ( ...
                (depth1 - cfg.sourceZ) / 1500 + ...
                (depth2 - depth1) / 1800);
        end

        if targetTime + cfg.stackHalfWindow >= time(end)
            continue;
        end

        %% 3. Compare velocity picks before/after random noise
        [~, cleanPick, ~] = semblance_scan( ...
            clean, time, offsets, targetTime, ...
            cfg.velocityGrid, cfg.scanHalfWindow, ...
            cfg.sourceDelay);

        [semblance, noisyPick, peak] = semblance_scan( ...
            noisy, time, offsets, targetTime, ...
            cfg.velocityGrid, cfg.scanHalfWindow, ...
            cfg.sourceDelay);

        %% 4. NMO-correct and stack with SAME noisy-data velocity pick
        cleanStack = nmo_stack( ...
            clean, time, offsets, noisyPick, cfg.sourceDelay, cfg.maxNmoStretch);
        [noisyStack, correctedGather, nmoValid, nmoCounts] = nmo_stack( ...
            noisy, time, offsets, noisyPick, cfg.sourceDelay, cfg.maxNmoStretch);

        useSample = abs(time - targetTime) <= cfg.stackHalfWindow & ...
            isfinite(cleanStack) & isfinite(noisyStack);
        if nnz(useSample) < 5
            continue;
        end

        cleanWindow = cleanStack(useSample);
        noisyWindow = noisyStack(useSample);
        noiseWindow = noisyWindow - cleanWindow;

        % 10*log10(power ratio) = 20*log10(amplitude RMS ratio).
        snrDb(end + 1) = 10 * log10( ...
            (sum(cleanWindow.^2) + eps) ...
            / (sum(noiseWindow.^2) + eps)); %#ok<AGROW>

        %% 5. Windowed waveform correlation with clean reference
        a = noisyWindow - mean(noisyWindow);
        b = cleanWindow - mean(cleanWindow);
        correlation = sum(a .* b) / sqrt( ...
            sum(a.^2) * sum(b.^2) + eps);

        stackCorrelation(end + 1) = ...
            max(0, min(1, correlation)); %#ok<AGROW>
        peakSemblance(end + 1) = peak; %#ok<AGROW>
        velocityPickPerturbation(end + 1) = ...
            abs(cleanPick - noisyPick); %#ok<AGROW>

        %% 6. Store one example for visualization
        if isempty(example) || abs(cmpPosition - 500) < abs(example.cmp - 500)
            example = struct( ...
                'clean', clean, ...
                'noisy', noisy, ...
                'nmo', correctedGather, ...
                'nmoValid', nmoValid, ...
                'nmoCounts', nmoCounts, ...
                'offset', offsets, ...
                'traceInfo', traceInfo, ...
                'sem', semblance, ...
                'vPick', noisyPick, ...
                'stack', noisyStack, ...
                'tEvent', targetTime, ...
                'cmp', cmpPosition);
        end
    end

    assert(~isempty(snrDb), ...
        'No CMP events available for waveform-quality evaluation.');

    quality.meanSNRdB = mean(snrDb);
    quality.meanSemblance = mean(peakSemblance);
    quality.meanCorrelation = mean(stackCorrelation);
    quality.meanPickPerturbation = mean(velocityPickPerturbation);
    quality.snrByCMP = snrDb;
    quality.semByCMP = peakSemblance;
    quality.sample = example;
end
