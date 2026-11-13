function plans = survey_plans(mode)
%SURVEY_PLANS Define four acquisition layouts used for comparison.
%
% A: baseline
% B: two extra receiver locations
% C: two extra shot locations
% D: wider regular shot interval coverage

    if strcmp(mode, 'quick')
        baseShots = 150:50:850;
        baseReceivers = 0:50:1000;
        extraShots = [-50, baseShots, 1050];
        widerShots = 100:50:900;
        extraReceivers = -50:50:1050;

    elseif strcmp(mode, 'full')
        baseShots = 200:50:1800;
        baseReceivers = 0:50:2000;
        extraShots = [-50, baseShots, 2050];
        widerShots = 150:50:1850;
        extraReceivers = -50:50:2050;

    else
        error('Unknown mode: %s', mode);
    end

    plans(1) = struct( ...
        'name', 'A_base', 'sx', baseShots, 'rx', baseReceivers);
    plans(2) = struct( ...
        'name', 'B_extra_receivers', 'sx', baseShots, 'rx', extraReceivers);
    plans(3) = struct( ...
        'name', 'C_extra_shots', 'sx', extraShots, 'rx', baseReceivers);
    plans(4) = struct( ...
        'name', 'D_wider_shot_range', 'sx', widerShots, 'rx', baseReceivers);
end
