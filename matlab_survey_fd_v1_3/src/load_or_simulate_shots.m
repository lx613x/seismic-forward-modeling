function [shotX, receiverX, data] = load_or_simulate_shots(cfg, model, propagator, plans)
%LOAD_OR_SIMULATE_SHOTS 按炮缓存；每炮仅存一次，CMP 按需读取。
% 缓存比较完整模型和全部影响求解的参数，避免统计摘要碰撞。
    shotX = unique([plans.sx]);
    receiverX = unique([plans.rx]);
    nt = numel(propagator.time);
    validate_acquisition(cfg, plans);
    bytes = 4 * double(nt) * numel(receiverX) * numel(shotX);
    fprintf('[FD] %d shots, %d receivers; raw single records %.1f MiB on disk.\n', ...
        numel(shotX), numel(receiverX), bytes / 2^20);
    fprintf('[FD] At most one shot record is loaded per CMP extraction.\n');
    if cfg.useDiskCache && cfg.saveShots
        cacheDir = fullfile(cfg.outputDir, 'shot_cache');
    else
        cacheDir = tempname;
    end
    if ~exist(cacheDir, 'dir'), mkdir(cacheDir); end
    signature = [cfg.dx, cfg.dz, cfg.dt, cfg.tmax, cfg.nb, cfg.sigmaMax, ...
        cfg.f0, cfg.sourceDelay, cfg.sourceZ, cfg.receiverZ];
    cacheModel = model.v; cacheX = cfg.x; cacheZ = cfg.z;
    files = cell(1, numel(shotX));
    peak = 0;
    for k = 1:numel(shotX)
        gridIndex = round((shotX(k) - cfg.x(1)) / cfg.dx);
        files{k} = fullfile(cacheDir, sprintf('shot_%07d.mat', gridIndex));
        valid = false;
        if cfg.useDiskCache && cfg.saveShots && exist(files{k}, 'file')
            try
                old = load(files{k});
                required = {'shot', 'record', 'signature', 'cacheModel', 'cacheX', 'cacheZ', 'receiverX'};
                valid = all(isfield(old, required)) && isequal(old.shot, shotX(k)) && ...
                    isequal(old.signature, signature) && isequal(old.cacheModel, cacheModel) && ...
                    isequal(old.cacheX, cacheX) && isequal(old.cacheZ, cacheZ) && ...
                    isequal(old.receiverX, receiverX) && ...
                    isequal(size(old.record), [nt, numel(receiverX)]) && all(isfinite(old.record(:)));
            catch
                valid = false;
            end
        end
        if valid
            record = old.record;
        else
            fprintf('[FD] Simulating shot %d/%d at x=%g m.\n', k, numel(shotX), shotX(k));
            shot = shotX(k);
            record = simulate_shot(propagator, shot, receiverX);
            save(files{k}, 'shot', 'record', 'signature', 'cacheModel', ...
                'cacheX', 'cacheZ', 'receiverX', '-v7');
        end
        peak = max(peak, double(max(abs(record(:)))));
    end
    data = struct('files', {files}, 'peak', peak, 'nt', nt, ...
        'gridOrigin', cfg.x(1), 'dx', cfg.dx, 'gridCount', numel(cfg.x));
end
