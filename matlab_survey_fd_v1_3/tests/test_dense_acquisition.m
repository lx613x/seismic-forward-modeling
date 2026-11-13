function test_dense_acquisition()
%TEST_DENSE_ACQUISITION 比较真实炮检组合和不同偏移距。
    cfg = default_config('dense');
    assert(numel(cfg.plans) >= 13);
    cmp = 500; a = cfg.plans(1); dense = cfg.plans(end);
    [na, oa] = count_pairs(a, cmp, cfg.cmpBinWidth);
    [nd, od] = count_pairs(dense, cmp, cfg.cmpBinWidth);
    assert(nd > na && numel(unique(od)) > numel(unique(oa)));
    assert(numel(unique(abs(od))) > numel(unique(abs(oa))));
    validate_acquisition(cfg, cfg.plans);
    fprintf('CMP %g m: baseline %d traces, dense %d traces.\n', cmp, na, nd);
end

function [n, offsets] = count_pairs(plan, centre, width)
    offsets = [];
    for s = plan.sx
        for r = plan.rx
            mid = (s+r)/2;
            if mid >= centre-width/2 && mid < centre+width/2
                offsets(end+1) = r-s; %#ok<AGROW>
            end
        end
    end
    n = numel(offsets);
end
