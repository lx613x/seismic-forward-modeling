function [gather, snapshots] = simulate_shot(op, sourceX, receiverX)
%SIMULATE_SHOT Simulate one shot with 4th-order 2-D acoustic FD.
%
% Equation: p_tt + damping*p_t = v(x,z)^2 * Laplacian(p) + source.
% Spatial accuracy: fourth order; temporal accuracy: second order.
% Boundary: external polynomial sponge, NOT an absorbing PML or free surface.

    cfg = op.cfg;

    %% 1. Convert physical coordinates to grid indices
    assert(sourceX >= cfg.x(1) && sourceX <= cfg.x(end), ...
        'Source x is outside the physical model.');
    assert(all(receiverX >= cfg.x(1) & receiverX <= cfg.x(end)), ...
        'A receiver x is outside the physical model.');
    assert(cfg.sourceZ >= cfg.z(1) && cfg.sourceZ <= cfg.z(end), ...
        'Source z is outside the physical model.');
    assert(cfg.receiverZ >= cfg.z(1) && cfg.receiverZ <= cfg.z(end), ...
        'Receiver z is outside the physical model.');

    sourceGridX = round((sourceX - cfg.x(1)) / cfg.dx) + 1;
    receiverGridX = round((receiverX - cfg.x(1)) / cfg.dx) + 1;
    sourceGridZ = round((cfg.sourceZ - cfg.z(1)) / cfg.dz) + 1;
    receiverGridZ = round((cfg.receiverZ - cfg.z(1)) / cfg.dz) + 1;

    assert(abs(cfg.x(sourceGridX) - sourceX) < 1e-7, ...
        'Source position must be on a grid node.');
    assert(all(abs(cfg.x(receiverGridX) - receiverX) < 1e-7), ...
        'Receiver positions must be on grid nodes.');

    % Offset the indices by the external sponge width.
    sourceGridX = sourceGridX + op.nb;
    receiverGridX = receiverGridX + op.nb;
    sourceGridZ = sourceGridZ + op.nb;
    receiverGridZ = receiverGridZ + op.nb;

    sourceIndex = sub2ind([op.nPadZ, op.nPadX], ...
        sourceGridZ, sourceGridX);
    receiverIndices = sub2ind([op.nPadZ, op.nPadX], ...
        receiverGridZ * ones(1, numel(receiverGridX)), receiverGridX);

    %% 2. Allocate wavefields and output traces
    previous = zeros(op.nPadZ, op.nPadX, 'single');
    current = previous;
    next = previous;

    nt = numel(op.time);
    gather = zeros(nt, numel(receiverX), 'single');
    snapshots = struct();

    if nargout > 1
        snapshotIndex = round(cfg.snapshotTimes / cfg.dt) + 1;
        snapshotIndex = snapshotIndex( ...
            snapshotIndex >= 1 & snapshotIndex <= nt);

        snapshots.time = op.time(snapshotIndex);
        snapshots.wave = zeros( ...
            op.nz, op.nx, numel(snapshotIndex), 'single');
        snapshots.shot = sourceX;
    end

    %% 3. Ricker source time function
    phase = pi * cfg.f0 * (op.time - cfg.sourceDelay);
    wavelet = single((1 - 2 * phase.^2) .* exp(-phase.^2));

    %% 4. Spatial fourth-order Laplacian stencil
    rows = 3:(op.nPadZ - 2);
    cols = 3:(op.nPadX - 2);
    waveSpeedFactor = op.vp2dt2(rows, cols);
    dampingFactor = op.beta(rows, cols);

    for it = 1:nt
        nearest = current(rows, cols + 1) + ...
            current(rows, cols - 1) + ...
            current(rows + 1, cols) + ...
            current(rows - 1, cols);

        nextNearest = current(rows, cols + 2) + ...
            current(rows, cols - 2) + ...
            current(rows + 2, cols) + ...
            current(rows - 2, cols);

        laplacian = (4 / 3) * nearest ...
            - (1 / 12) * nextNearest ...
            - 5 * current(rows, cols);

        next(rows, cols) = ( ...
            2 * current(rows, cols) ...
            - (1 - dampingFactor) .* previous(rows, cols) ...
            + waveSpeedFactor .* laplacian) ...
            ./ (1 + dampingFactor);

        % Inject point-pressure source and sample receiver grid nodes.
        next(sourceIndex) = next(sourceIndex) + wavelet(it);
        gather(it, :) = next(receiverIndices);

        if nargout > 1
            snapshotSlot = find(snapshotIndex == it, 1);
            if ~isempty(snapshotSlot)
                snapshots.wave(:, :, snapshotSlot) = next( ...
                    op.nb + (1:op.nz), op.nb + (1:op.nx));
            end
        end

        previous = current;
        current = next;
        % Two outer grid layers remain fixed at zero, beyond the sponge.
    end

    assert(all(isfinite(gather(:))), ...
        'Wave-equation solver produced non-finite samples.');
end
