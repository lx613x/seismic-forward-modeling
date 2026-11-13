function save_center_snapshots(cfg, model, propagator)
%SAVE_CENTER_SNAPSHOTS Compute/cache wavefield snapshots from the centre.
%
% This source is ONLY for visualizing propagation, never for evaluating
% survey geometry or costing. Previous v1.2 first-shot snapshots are not
% reused because they have no validated snapshot metadata.

    if ~cfg.saveSnapshots
        return;
    end

    if ~exist(cfg.outputDir, 'dir')
        mkdir(cfg.outputDir);
    end

    snapshotFile = fullfile(cfg.outputDir, 'wave_snapshots.mat');

    % Include every setting which affects wave propagation/snapshot times.
    signature = [ ...
        cfg.snapshotShotX, cfg.sourceZ, cfg.receiverZ, ...
        cfg.dx, cfg.dz, cfg.dt, cfg.tmax, cfg.nb, ...
        cfg.sigmaMax, cfg.f0, cfg.sourceDelay, ...
        cfg.snapshotTimes(:).'];

    cacheIsValid = false;
    if cfg.useDiskCache && exist(snapshotFile, 'file')
        previous = load(snapshotFile);
        required = {'snapshots', 'signature', 'cacheVelocity', ...
            'cacheX', 'cacheZ'};

        if all(isfield(previous, required)) && ...
                isfield(previous.snapshots, 'shot') && ...
                isfield(previous.snapshots, 'time') && ...
                isfield(previous.snapshots, 'wave')
            cacheIsValid = ...
                isequal(previous.signature, signature) && ...
                isequal(previous.cacheVelocity, model.v) && ...
                isequal(previous.cacheX, cfg.x) && ...
                isequal(previous.cacheZ, cfg.z) && ...
                isequal(previous.snapshots.shot, cfg.snapshotShotX) && ...
                size(previous.snapshots.wave, 3) == ...
                    numel(previous.snapshots.time);
        end
    end

    if cacheIsValid
        fprintf('[SNAPSHOT] Reusing validated centre-shot snapshots at x = %g m.\n', ...
            cfg.snapshotShotX);
        return;
    end

    fprintf('[SNAPSHOT] Simulating centre-shot wavefield at x = %g m.\n', ...
        cfg.snapshotShotX);

    % One temporary receiver is enough: the requested output is the
    % complete wavefield returned by the second output of simulate_shot.
    [~, snapshots] = simulate_shot( ...
        propagator, cfg.snapshotShotX, cfg.snapshotShotX);

    cacheVelocity = model.v; %#ok<NASGU>
    cacheX = cfg.x; %#ok<NASGU>
    cacheZ = cfg.z; %#ok<NASGU>

    save(snapshotFile, 'snapshots', 'signature', ...
        'cacheVelocity', 'cacheX', 'cacheZ', '-v7');

    fprintf('[SNAPSHOT] Centre-shot snapshots saved.\n');
end
