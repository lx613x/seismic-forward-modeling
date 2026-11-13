function cfg = default_config(mode)
%DEFAULT_CONFIG Settings for reproducible 2-D seismic acquisition tests.
%
%   cfg = default_config('quick')   CMP 200-800 m
%   cfg = default_config('full')    CMP 200-1800 m, includes fault zone
%
% Change survey weights and unit-cost assumptions here. For physics-related
% changes, the validated disk cache automatically becomes invalid.

    if nargin < 1
        mode = 'quick';
    end
    assert(any(strcmp(mode, {'quick', 'full'})), ...
        'Mode must be ''quick'' or ''full''.');

    cfg.mode = mode;

    %% 1. Physical grid and numerical model
    cfg.dx = 10;                 % Grid spacing in x (m)
    cfg.dz = 10;                 % Grid spacing in z (m)
    cfg.x = -200:cfg.dx:2200;
    cfg.z = 0:cfg.dz:1200;
    cfg.nb = 20;                 % Sponge cells OUTSIDE physical grid
    cfg.sigmaMax = 180;          % Peak sponge damping (1/s)
    cfg.dt = 0.001;              % Simulation time step (s)
    cfg.tmax = 1.20;             % Record duration (s)

    %% 2. Source and receivers
    cfg.f0 = 12;                 % Ricker dominant frequency (Hz)
    cfg.sourceDelay = 0.10;      % Ricker centre time (s)
    cfg.sourceZ = 20;            % Source datum depth (m)
    cfg.receiverZ = 20;          % Receiver datum depth (m)
    % Snapshot-only source; this does not modify the four survey layouts.
    cfg.snapshotShotX = (cfg.x(1) + cfg.x(end)) / 2;

    %% 3. Noise and output
    cfg.noiseFraction = 0.010;   % Relative to global clean peak
    cfg.randomSeed = 20261112;
    cfg.useDiskCache = true;
    cfg.saveShots = true;
    cfg.saveSnapshots = true;
    cfg.makePlots = true;
    cfg.snapshotTimes = [0.22, 0.42, 0.65, 0.88];
    cfg.outputDir = fullfile(fileparts(mfilename('fullpath')), 'output');

    %% 4. Geometrical preselection (teaching approximation)
    cfg.geomV1 = 1500;
    cfg.geomV2 = 1600;
    cfg.geomTZero = 2 * 450 / 1500;
    cfg.minMoveoutMs = 3;
    cfg.maxNmoStretch = 0.30;    % Fraction, not percentage
    cfg.minFold = 6;
    cfg.minUsableKinds = 3;

    %% 5. Data-quality measurement windows
    cfg.velocityGrid = 1400:100:2800;
    cfg.scanHalfWindow = 0.018;
    cfg.stackHalfWindow = 0.085;

    %% 6. Adjustable scoring weights (must each sum to one)
    cfg.weights = [0.55, 0.25, 0.20];   % Quality, geometry, cost
    cfg.qWeights = [0.45, 0.30, 0.25];  % SNR, semblance, correlation
    cfg.gWeights = [0.40, 0.30, 0.30];  % Fold, offsets, uniformity
    cfg.snrScaleDb = [0, 30];
    cfg.foldTarget = 12;
    cfg.goodTarget = 6;

    %% 7. Unit costs (teaching units, NOT actual project quotations)
    cfg.Cshot = 3000;
    cfg.Creceiver = 800;
    cfg.Ctrace = 5;

    %% 8. Survey extent
    if strcmp(mode, 'quick')
        cfg.cmpPos = 200:25:800;
        cfg.qualityCMP = 200:100:800;
    else
        cfg.cmpPos = 200:25:1800;
        cfg.qualityCMP = 200:200:1800;
    end
    cfg.plans = survey_plans(mode);

    %% 9. Input checks
    assert(abs(sum(cfg.weights) - 1) < 1e-10, ...
        'Overall weights must sum to one.');
    assert(abs(sum(cfg.qWeights) - 1) < 1e-10, ...
        'Quality weights must sum to one.');
    assert(abs(sum(cfg.gWeights) - 1) < 1e-10, ...
        'Geometry weights must sum to one.');
end
