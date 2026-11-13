function index = cmp_bin_index(midpoint, centres, width)
%CMP_BIN_INDEX 等间距 bin 左闭右开；边界归入右侧，范围外返回 0。
    assert(isscalar(width) && isfinite(width) && width > 0, 'Invalid CMP bin width.');
    centres = double(centres(:).');
    assert(~isempty(centres) && all(isfinite(centres)) && ...
        (numel(centres) == 1 || all(abs(diff(centres) - width) < 1e-7)), ...
        'CMP bin centres must be spaced by bin width.');
    index = floor((double(midpoint) - (centres(1) - width / 2)) / width) + 1;
    if index < 1 || index > numel(centres)
        index = 0;
    end
end
