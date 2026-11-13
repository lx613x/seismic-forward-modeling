function create_external_model(filename)
%CREATE_EXTERNAL_MODEL 生成与默认网格匹配的水平两层模型。
    if nargin < 1, filename = 'external_model.mat'; end
    x = -200:10:2200; z = 0:10:1200;
    v = 1500 * ones(numel(z), numel(x), 'single');
    v(z >= 450, :) = 2200;
    save(filename, 'v', 'x', 'z');
end
