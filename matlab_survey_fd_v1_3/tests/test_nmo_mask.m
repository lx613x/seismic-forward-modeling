function test_nmo_mask()
%TEST_NMO_MASK 缺失和拉伸切除不参与叠加，零偏移距保持不变。
    t = (0:0.001:1)'; signal = sin(10*t); gather = [signal, signal];
    [stack, corrected, valid, counts] = nmo_stack(gather, t, [0, 1000], 1500, 0.1, 0.3);
    assert(max(abs(corrected(:,1)-signal)) < 1e-10);
    assert(all(valid(:,1)) && any(~valid(:,2)));
    assert(all(isnan(corrected(~valid))));
    singleTrace = counts == 1;
    assert(max(abs(stack(singleTrace)-signal(singleTrace))) < 1e-10);
    fprintf('NMO validity and stretch-mute checks passed.\n');
end
