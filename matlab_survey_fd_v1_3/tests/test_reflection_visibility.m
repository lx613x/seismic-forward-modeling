function test_reflection_visibility()
%TEST_REFLECTION_VISIBILITY 验证显示增强独立于输入；不声称物理反射可辨。
    t = (0:0.001:1)'; input = zeros(numel(t), 2);
    input(101,:) = [100, 80]; input(601,:) = [1, 2];
    original = input; displayData = reflection_display(input, t, 0.60, 0.05);
    assert(isequal(input, original));
    assert(all(abs(displayData(601,:) - 1) < 1e-10));
    assert(all(abs(displayData(:)) <= 1));
    fprintf('Reflection display isolation checks passed.\n');
end
