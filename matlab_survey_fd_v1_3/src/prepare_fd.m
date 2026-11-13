function op = prepare_fd(cfg, model)
%PREPARE_FD Validate stability and prepare padded velocity/damping arrays.
%
% Fourth-order spatial stencil assumes equal horizontal and vertical
% spacing. Polynomial sponge is outside the physical grid (not a PML).

    %% 1. Numerical stability and dispersion checks
    assert(cfg.dx == cfg.dz, ...
        'Fourth-order stencil currently requires dx = dz.');
    assert(cfg.nb >= 4, 'Sponge width must be at least four cells.');
    assert(all(model.v(:) > 0) && all(isfinite(model.v(:))), ...
        'Velocity model must be finite and positive.');

    maxVelocity = double(max(model.v(:)));
    courant = cfg.dt * maxVelocity / cfg.dx;
    assert(courant < 0.45, ...
        'Potential CFL instability: reduce the time step.');

    minimumPointsPerWavelength = ...
        double(min(model.v(:))) / (2 * cfg.f0 * cfg.dx);
    if minimumPointsPerWavelength < 6
        warning('Less than 6 grid points per shortest 2*f0 wavelength.');
    end

    %% 2. Extend model by edge copying
    nb = cfg.nb;
    [nz, nx] = size(model.v);

    paddedRows = min(max((1:(nz + 2 * nb)) - nb, 1), nz);
    paddedCols = min(max((1:(nx + 2 * nb)) - nb, 1), nx);
    velocityPadded = model.v(paddedRows, paddedCols);

    %% 3. Build smooth sponge damping
    [row, col] = ndgrid( ...
        0:size(velocityPadded, 1) - 1, ...
        0:size(velocityPadded, 2) - 1);

    distanceToBoundary = min( ...
        min(row, size(velocityPadded, 1) - 1 - row), ...
        min(col, size(velocityPadded, 2) - 1 - col));

    taperFraction = max(0, (nb - distanceToBoundary) / nb);
    damping = cfg.sigmaMax * taperFraction.^2;

    %% 4. Pack wave-equation coefficients
    op.vp2dt2 = single( ...
        (double(velocityPadded) * cfg.dt / cfg.dx).^2);
    op.beta = single(damping * cfg.dt / 2);
    op.nb = nb;
    op.nx = nx;
    op.nz = nz;
    op.nPadX = size(velocityPadded, 2);
    op.nPadZ = size(velocityPadded, 1);
    op.time = (0:round(cfg.tmax / cfg.dt))' * cfg.dt;
    op.cfg = cfg;
end
