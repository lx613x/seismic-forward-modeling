function test_external_model()
%TEST_EXTERNAL_MODEL 外部 MAT 数据及几何验证。
    cfg = default_config('quick');
    root = tempname; mkdir(root); cleanup = onCleanup(@() rmdir(root, 's')); %#ok<NASGU>
    cfg.modelFile = fullfile(root, 'model.mat'); cfg.targetTime = 0.65;
    x = cfg.x; z = cfg.z; v = single(1500 * ones(numel(z), numel(x))); %#ok<NASGU>
    save(cfg.modelFile, 'x', 'z', 'v');
    model = load_velocity_model(cfg, root);
    assert(isequal(size(model.v), [numel(z), numel(x)]));
    assert(~isfield(model, 'h1'));
    v(1,1) = NaN; save(cfg.modelFile, 'x', 'z', 'v');
    must_fail(@() load_velocity_model(cfg, root));
    v = single(1500 * ones(numel(z)-1, numel(x))); save(cfg.modelFile, 'x', 'z', 'v');
    must_fail(@() load_velocity_model(cfg, root));
    v = single(1500 * ones(numel(z), numel(x))); x(2) = x(2) + 1;
    save(cfg.modelFile, 'x', 'z', 'v');
    must_fail(@() load_velocity_model(cfg, root));
    invalid = cfg.plans(1); invalid.sx(1) = cfg.x(1) - cfg.dx;
    must_fail(@() validate_acquisition(cfg, invalid));
    fprintf('External model checks passed.\n');
end

function must_fail(f)
    didFail = false;
    try, f(); catch, didFail = true; end
    assert(didFail, 'Expected invalid input to fail.');
end
