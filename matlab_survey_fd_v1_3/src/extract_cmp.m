function [clean, noisy, offsets] = extract_cmp( ...
    plan, cmpPosition, shotX, commonReceiverX, cleanShots, noisyShots)
%EXTRACT_CMP Extract an exact CMP gather from shared forward shot records.
%
% Both clean and noisy traces are indexed from the same source/receiver
% coordinates. Offset sign is preserved and the gather is sorted by offset.

    clean = [];
    noisy = [];
    offsets = [];

    for iShot = 1:numel(plan.sx)
        shotIndex = find(shotX == plan.sx(iShot), 1);
        assert(~isempty(shotIndex), 'Required shot was not simulated.');

        for iReceiver = 1:numel(plan.rx)
            midpoint = (plan.sx(iShot) + plan.rx(iReceiver)) / 2;

            if abs(midpoint - cmpPosition) > 1e-8
                continue;
            end

            receiverIndex = find( ...
                commonReceiverX == plan.rx(iReceiver), 1);
            assert(~isempty(receiverIndex), ...
                'Required receiver was not simulated.');

            clean(:, end + 1) = ...
                cleanShots(:, receiverIndex, shotIndex); %#ok<AGROW>
            noisy(:, end + 1) = ...
                noisyShots(:, receiverIndex, shotIndex); %#ok<AGROW>
            offsets(end + 1) = ...
                plan.rx(iReceiver) - plan.sx(iShot); %#ok<AGROW>
        end
    end

    [offsets, order] = sort(offsets);
    clean = clean(:, order);
    noisy = noisy(:, order);
end
