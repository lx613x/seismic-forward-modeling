function model = build_velocity(cfg)
%BUILD_VELOCITY Four layers, undulating horizons, fault and two anomalies.
%
% All depths are positive downward. This velocity model is an acoustic,
% constant-density teaching model, not a measured geological section.

    x = cfg.x;
    z = cfg.z;
    nx = numel(x);
    nz = numel(z);

    %% 1. Three undulating horizons
    h1 = 180 + 20 * sin(2 * pi * x / 1800);
    h2 = 480 + 50 * sin(2 * pi * (x - 200) / 1400);
    h3 = 820 - 120 * exp(-((x - 1000) / 420).^2) ...
        + 25 * sin(2 * pi * x / 2000);

    %% 2. Downthrow on the right side of x = 1300 m
    throw = 80 * (x >= 1300);
    h1 = h1 + throw;
    h2 = h2 + throw;
    h3 = h3 + throw;

    %% 3. Layered background velocities
    v = 1500 * ones(nz, nx, 'single');

    for ix = 1:nx
        v(z >= h1(ix), ix) = 1800;
        v(z >= h2(ix), ix) = 2400;
        v(z >= h3(ix), ix) = 3000;
    end

    %% 4. Low-velocity and high-velocity elliptical anomalies
    [X, Z] = meshgrid(x, z);
    lowLens = ((X - 650) / 220).^2 + ((Z - 620) / 90).^2 <= 1;
    highLens = ((X - 1050) / 260).^2 + ((Z - 860) / 110).^2 <= 1;

    v(lowLens) = 2100;
    v(highLens) = 3300;

    %% 5. Return model structure
    model.v = v;
    model.x = x;
    model.z = z;
    model.h1 = h1;
    model.h2 = h2;
    model.h3 = h3;
end
