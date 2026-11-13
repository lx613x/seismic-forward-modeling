function [stack, correctedGather] = nmo_stack( ...
    gather, time, offsets, velocity, sourceDelay)
%NMO_STACK Hyperbolic NMO with a shifted source-time origin, then stack.
%
% Input/Output:
%   gather(nt,ntr)    original common-midpoint traces
%   time(nt,1)        RECORD times in seconds
%   offsets(1,ntr)    signed offsets in metres
%   velocity          trial NMO velocity (m/s)
%   sourceDelay       centre delay of the source wavelet (s)
%   stack(nt,1)       average of valid corrected traces
%   correctedGather   NMO traces; invalid extrapolations become NaN
%
% This is a teaching hyperbolic-NMO operator. Stretch mute is NOT applied;
% avoid interpreting it as accurate imaging for complex structures.

    if nargin < 5
        sourceDelay = 0;  % Preserve existing zero-delay tests.
    end

    time = double(time(:));
    offsets = double(offsets(:).');
    nTrace = numel(offsets);
    nt = numel(time);

    assert(size(gather, 1) == nt && size(gather, 2) == nTrace, ...
        'Gather dimensions must be [length(time), length(offsets)].');
    assert(isscalar(velocity) && isfinite(velocity) && velocity > 0, ...
        'NMO velocity must be finite and positive.');
    assert(sourceDelay >= 0 && isfinite(sourceDelay), ...
        'Invalid source wavelet centre delay.');

    correctedGather = NaN(nt, nTrace);
    isAfterSource = time >= sourceDelay;

    for iTrace = 1:nTrace
        offset = offsets(iTrace);
        inputTime = NaN(size(time));

        % At zero offset NMO is exactly the identity, including early time.
        if abs(offset) < 1e-12
            inputTime = time;
        else
            travelTime = time(isAfterSource) - sourceDelay;
            inputTime(isAfterSource) = sourceDelay + sqrt( ...
                travelTime.^2 + (offset / velocity)^2);
        end

        validTime = isfinite(inputTime) & ...
            inputTime >= time(1) & inputTime <= time(end);
        if any(validTime)
            correctedGather(validTime, iTrace) = interp1( ...
                time, double(gather(:, iTrace)), ...
                inputTime(validTime), 'linear', NaN);
        end
    end

    valid = isfinite(correctedGather);
    counts = sum(valid, 2);
    samples = correctedGather;
    samples(~valid) = 0;

    stack = NaN(nt, 1);
    haveData = counts > 0;
    stack(haveData) = sum(samples(haveData, :), 2) ./ counts(haveData);
end
