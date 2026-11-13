function [shotX, receiverX, cleanShots] = load_or_simulate_shots( ...
    cfg, model, propagator, plans)
%LOAD_OR_SIMULATE_SHOTS Validate cached FD results or run unique shots.
%
% Cache hits require the entire velocity matrix and all source/receiver
% positions to match; changing only score weights does not rerun the FD.

    shotX = unique([plans.sx]);
    receiverX = unique([plans.rx]);
    nt = numel(propagator.time);

    cacheFile = fullfile(cfg.outputDir, 'forward_data.mat');

    % Scalar signature plus exact model and coordinate arrays.
    signature = [numel(cfg.x), numel(cfg.z), cfg.dx, cfg.dz, ...
        cfg.dt, cfg.tmax, cfg.nb, cfg.sigmaMax, cfg.f0, ...
        cfg.sourceDelay, cfg.sourceZ, cfg.receiverZ, ...
        sum(double(model.v(:))), sum(double(model.v(:)).^2)];

    cacheIsValid = false;
    if cfg.useDiskCache && exist(cacheFile, 'file')
        previous = load(cacheFile);
        % Support both tidy v1.1 keys and original v1 cache field names.
        if isfield(previous, 'receiverX') && ...
                isfield(previous, 'cleanShots')
            cachedReceiverX = previous.receiverX;
            cachedShots = previous.cleanShots;
        elseif isfield(previous, 'rxAll') && ...
                isfield(previous, 'shotsClean')
            cachedReceiverX = previous.rxAll;
            cachedShots = previous.shotsClean;
        else
            cachedReceiverX = [];
            cachedShots = [];
        end

        requiredFields = {'signature', 'shotX', 'cacheModel', ...
            'cacheX', 'cacheZ'};

        if all(isfield(previous, requiredFields)) && ~isempty(cachedShots)
            expectedSize = [nt, numel(receiverX), numel(shotX)];
            cacheIsValid = isequal(previous.signature, signature) && ...
                isequal(previous.shotX, shotX) && ...
                isequal(cachedReceiverX, receiverX) && ...
                isequal(previous.cacheX, cfg.x) && ...
                isequal(previous.cacheZ, cfg.z) && ...
                isequal(previous.cacheModel, model.v) && ...
                isequal(size(cachedShots), expectedSize);
        end
    end

    if cacheIsValid
        fprintf('[FD] Validated cache found: reusing %d shots.\n', ...
            numel(shotX));
        cleanShots = cachedShots;
        return;
    end

    fprintf('[FD] Simulating %d unique shots on %d x %d grid.\n', ...
        numel(shotX), numel(cfg.x), numel(cfg.z));

    cleanShots = zeros(nt, numel(receiverX), numel(shotX), 'single');

    for iShot = 1:numel(shotX)
        fprintf('[FD] Shot %3d/%3d | x = %g m\n', ...
            iShot, numel(shotX), shotX(iShot));

        % Snapshot computation is handled independently by
        % save_center_snapshots, not by the first acquisition shot.
        cleanShots(:, :, iShot) = simulate_shot( ...
            propagator, shotX(iShot), receiverX);
    end

    if cfg.saveShots
        cacheModel = model.v;
        cacheX = cfg.x;
        cacheZ = cfg.z;

        save(cacheFile, 'signature', 'shotX', 'receiverX', ...
            'cleanShots', 'cacheModel', 'cacheX', 'cacheZ', '-v7');
    end
end
