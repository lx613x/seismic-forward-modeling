function test_cmp_binning()
%CMP 边界按左闭右开，记录只能归到一个 bin。
    cfg = default_config('quick'); centres = 200:25:800;
    assert(cmp_bin_index(212.5, centres, 25) == 2);
    assert(cmp_bin_index(187.5, centres, 25) == 1);
    assert(cmp_bin_index(812.5, centres, 25) == 0);
    p = struct('name', 'fixture', 'sx', [190, 200], 'rx', [210, 220]);
    cfg.cmpPos = centres;
    g = geometry_metrics(cfg, p);
    shots = reshape(single(1:16), [4, 2, 2]);
    [clean, ~, offsets] = extract_cmp(p, 200, p.sx, p.rx, shots, shots, cfg);
    assert(size(clean,2) == g.fold(1));
    assert(numel(offsets) == 4);
    assert(numel(unique(clean(1,:))) == 4);
    fprintf('CMP bin boundary and extraction checks passed.\n');
end
