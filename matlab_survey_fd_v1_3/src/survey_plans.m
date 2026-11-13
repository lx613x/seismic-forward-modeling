function plans = survey_plans(mode)
%SURVEY_PLANS Define four acquisition layouts used for comparison.
%
% A: baseline
% B: two extra receiver locations
% C: two extra shot locations
% D: wider regular shot interval coverage

    if any(strcmp(mode, {'quick', 'dense'}))
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
    % 八套独立采集几何：网格对齐，保留 A-D 原有定义。
    if strcmp(mode, 'full')
        first = 200; last = 1800; right = 2000;
    else
        first = 150; last = 850; right = 1000;
    end
    plans(5) = struct('name', 'E_40m_shots', 'sx', first:40:last, 'rx', baseReceivers);
    plans(6) = struct('name', 'F_40m_receivers', 'sx', baseShots, 'rx', 0:40:right);
    plans(7) = struct('name', 'G_wide_receivers', 'sx', baseShots, 'rx', -100:50:right+100);
    plans(8) = struct('name', 'H_left_shots', 'sx', [first-100, baseShots], 'rx', baseReceivers);
    plans(9) = struct('name', 'I_right_shots', 'sx', [baseShots, last+100], 'rx', baseReceivers);
    plans(10) = struct('name', 'J_shifted_receivers', 'sx', baseShots, 'rx', 20:50:right+20);
    plans(11) = struct('name', 'K_short_spread', 'sx', baseShots, 'rx', 100:50:right-100);
    plans(12) = struct('name', 'L_asymmetric', 'sx', first-100:50:last, 'rx', 0:50:right+100);
    if strcmp(mode, 'dense')
        plans(13) = struct('name', 'M_dense_20m', 'sx', 100:20:900, 'rx', -100:20:1100);
    end
end
