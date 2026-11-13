function test_cache_consistency()
%TEST_CACHE_CONSISTENCY 检验模型变化时不复用旧炮记录。
    cfg = default_config('quick'); cfg.x = -100:10:100; cfg.z = 0:10:200;
    cfg.sourceZ = 50; cfg.receiverZ = 50; cfg.tmax = 0.2;
    cfg.outputDir = tempname; mkdir(cfg.outputDir);
    cleanup = onCleanup(@() rmdir(cfg.outputDir, 's')); %#ok<NASGU>
    model.v = single(1500*ones(numel(cfg.z), numel(cfg.x)));
    plan = struct('name', 'test', 'sx', 0, 'rx', [0, 50]);
    [~, ~, d] = load_or_simulate_shots(cfg, model, prepare_fd(cfg, model), plan);
    a = load(d.files{1});
    [~, ~, d] = load_or_simulate_shots(cfg, model, prepare_fd(cfg, model), plan);
    b = load(d.files{1}); assert(isequal(a.record, b.record));
    model.v(:) = 1800;
    [~, ~, d] = load_or_simulate_shots(cfg, model, prepare_fd(cfg, model), plan);
    c = load(d.files{1});
    assert(isequal(c.cacheModel, model.v) && ~isequal(a.record, c.record));
    fprintf('Per-shot cache validation checks passed.\n');
end
