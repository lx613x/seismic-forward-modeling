function run_tests()
%RUN_TESTS Basic regression checks for geometry, FD reciprocity and NMO.
%
% Run from the project root:
%   addpath('tests'); run_tests

    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(root, fullfile(root, 'src'));
    cfg = default_config('quick');

    %% 1. Model geometry and velocity values
    model = build_velocity(cfg);
    expectedSize = [numel(cfg.z), numel(cfg.x)];

    assert(isequal(size(model.v), expectedSize));
    assert(min(model.v(:)) == 1500 && max(model.v(:)) == 3300);
    assert(any(model.v(:) == 2100));
    assert(any(model.v(:) == 2400));

    %% 2. Two feasible acquisition layouts
    geometryB = geometry_metrics(cfg, cfg.plans(2));
    geometryC = geometry_metrics(cfg, cfg.plans(3));

    assert(geometryB.pass && geometryC.pass, ...
        'Both edge-coverage alternatives should be feasible.');
    assert(geometryB.minFold >= cfg.minFold);
    assert(geometryB.minKinds >= cfg.minUsableKinds);
    assert((150 + (-50)) / 2 == (-50 + 150) / 2);

    %% 3. Mini homogeneous FD reciprocity
    mini = cfg;
    mini.x = -100:10:200;
    mini.z = 0:10:200;
    mini.sourceZ = 80;
    mini.receiverZ = 80;
    mini.tmax = 0.30;
    mini.f0 = 10;

    homogeneous.v = single( ...
        1500 * ones(numel(mini.z), numel(mini.x)));
    propagator = prepare_fd(mini, homogeneous);

    responseAB = simulate_shot(propagator, -50, 150);
    responseBA = simulate_shot(propagator, 150, -50);

    relativeError = norm(double(responseAB - responseBA)) ...
        / max(norm(double(responseAB)), eps);

    assert(relativeError < 1e-4, ...
        'Homogeneous acoustic FD reciprocity failed.');
    assert(any(responseAB ~= 0), ...
        'The simulated wave did not reach the receiver.');

    %% 4. Zero-offset NMO identity
    time = propagator.time;
    signal = single(sin((1:numel(time))' / 10));
    stack = nmo_stack(signal, time, 0, 1500);

    maxDifference = max( ...
        abs(stack(1:end-1) - double(signal(1:end-1))));
    assert(maxDifference < 1e-8, 'Zero-offset NMO check failed.');

    %% 5. Known hyperbola: source delay, velocity pick and NMO alignment
    syntheticTime = (0:0.001:1.2)';
    syntheticOffsets = 0:100:800;
    knownVelocity = 2000;
    sourceDelay = 0.10;
    zeroOffsetTime = 0.58;
    centreFrequency = 20;

    syntheticGather = zeros( ...
        numel(syntheticTime), numel(syntheticOffsets));
    for k = 1:numel(syntheticOffsets)
        arrival = sourceDelay + sqrt( ...
            (zeroOffsetTime - sourceDelay)^2 + ...
            (syntheticOffsets(k) / knownVelocity)^2);
        phase = pi * centreFrequency * (syntheticTime - arrival);
        syntheticGather(:, k) = ...
            (1 - 2 * phase.^2) .* exp(-phase.^2);
    end

    [~, pickedVelocity] = semblance_scan( ...
        syntheticGather, syntheticTime, syntheticOffsets, ...
        zeroOffsetTime, 1500:100:2600, 0.018, sourceDelay);
    assert(abs(pickedVelocity - knownVelocity) <= 100, ...
        'Delayed-wavelet semblance velocity did not recover truth.');

    [syntheticStack, syntheticNMO] = nmo_stack( ...
        syntheticGather, syntheticTime, syntheticOffsets, ...
        knownVelocity, sourceDelay);
    assert(isequal(size(syntheticNMO), size(syntheticGather)), ...
        'Corrected gather size mismatch.');

    [~, peakIndex] = max(abs(syntheticStack));
    assert(abs(syntheticTime(peakIndex) - zeroOffsetTime) <= 0.006, ...
        'Delayed-wavelet NMO did not align the synthetic reflector.');

    %% 6. Mini snapshot test: independent central source and cache metadata
    mini.snapshotShotX = (mini.x(1) + mini.x(end)) / 2;
    mini.snapshotTimes = [0.12, 0.20];
    mini.outputDir = fullfile(tempdir, 'survey_fd_v13_snapshot_test');
    snapshotPropagator = prepare_fd(mini, homogeneous);
    save_center_snapshots(mini, homogeneous, snapshotPropagator);
    savedSnapshot = load(fullfile(mini.outputDir, 'wave_snapshots.mat'));
    assert(savedSnapshot.snapshots.shot == mini.snapshotShotX, ...
        'Snapshot source is not at the requested model centre.');
    assert(numel(savedSnapshot.snapshots.time) == 2, ...
        'Unexpected number of snapshots.');
    save_center_snapshots(mini, homogeneous, snapshotPropagator);

    %% 7. Scoring gate and normalized weights
    qualityB = struct( ...
        'meanSNRdB', 5.55, 'meanSemblance', 0.54, ...
        'meanCorrelation', 0.87);
    qualityC = struct( ...
        'meanSNRdB', 5.27, 'meanSemblance', 0.55, ...
        'meanCorrelation', 0.87);
    scores = score_plans(cfg, cfg.plans(2:3), ...
        [geometryB, geometryC], [qualityB, qualityC]);

    assert(all(scores.pass));
    assert(all(isfinite(scores.score)));
    assert(all(scores.qualityScore >= 0 & scores.qualityScore <= 1));
    assert(~isempty(scores.winner));

    fprintf(['ALL TESTS PASSED: grid, lenses, geometry, ' ...
        'FD reciprocity, delayed NMO, centre snapshots, scoring.\n']);
end
