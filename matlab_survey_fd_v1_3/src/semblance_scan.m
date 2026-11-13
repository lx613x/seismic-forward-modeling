function [semblance, pickedVelocity, peakSemblance] = semblance_scan( ...
    gather, time, offsets, tCenter, velocities, halfWindow, sourceDelay)
%SEMBLANCE_SCAN Windowed moveout semblance with a source-time shift.
%
% tCenter and time use the RECORD time axis (including the source wavelet
% centre delay). For an ideal hyperbolic reflector the sampled time is
%
%   t_input = sourceDelay + sqrt((t_zero - sourceDelay)^2 + (x/v)^2)
%
% For dipping/heterogeneous models this is an approximation. This routine
% does not subtract a direct arrival or perform a stretch mute.

    if nargin < 7
        sourceDelay = 0;  % Preserve v1.2 calling syntax.
    end

    time = double(time(:));
    offsets = double(offsets(:).');
    velocities = double(velocities(:).');

    assert(size(gather, 1) == numel(time), ...
        'The gather must have one row for each time sample.');
    assert(size(gather, 2) == numel(offsets), ...
        'The gather must have one column for each offset.');
    assert(numel(offsets) >= 2, 'At least two traces are required.');
    assert(isscalar(sourceDelay) && isfinite(sourceDelay) && ...
        sourceDelay >= 0, 'Invalid source wavelet centre delay.');
    assert(tCenter > sourceDelay, ...
        'Reference event time must exceed the source delay.');
    assert(all(velocities > 0) && all(isfinite(velocities)), ...
        'Velocity candidates must be finite and positive.');

    dt = time(2) - time(1);
    assert(dt > 0 && max(abs(diff(time) - dt)) < dt * 1e-5, ...
        'Time samples must be evenly spaced and increasing.');

    windowIndices = find(abs(time - tCenter) <= halfWindow & ...
        time >= sourceDelay);
    assert(~isempty(windowIndices), 'Semblance time window is empty.');

    nWindow = numel(windowIndices);
    nTrace = numel(offsets);
    semblance = zeros(1, numel(velocities));

    for iVelocity = 1:numel(velocities)
        trialVelocity = velocities(iVelocity);
        aligned = NaN(nWindow, nTrace);

        for iTrace = 1:nTrace
            travelTime = time(windowIndices) - sourceDelay;
            inputTime = sourceDelay + sqrt( ...
                travelTime.^2 + (offsets(iTrace) / trialVelocity)^2);

            % interp1 avoids an assumption that time(1) must be zero.
            aligned(:, iTrace) = interp1(time, ...
                double(gather(:, iTrace)), inputTime, 'linear', NaN);
        end

        % Invalid interpolations are excluded from both numerator and
        % denominator. At least two valid traces must contribute.
        valid = isfinite(aligned);
        aligned(~valid) = 0;
        nValid = sum(valid, 2);
        keep = nValid >= 2;

        if any(keep)
            amplitudes = aligned(keep, :);
            traceCount = nValid(keep);
            numerator = sum(sum(amplitudes, 2).^2);
            denominator = sum(traceCount .* sum(amplitudes.^2, 2));
            if denominator > eps
                semblance(iVelocity) = numerator / denominator;
            end
        end
    end

    [peakSemblance, pickedIndex] = max(semblance);
    pickedVelocity = velocities(pickedIndex);
end
