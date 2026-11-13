function displayGather = reflection_display(gather, time, targetTime, halfWindow)
%REFLECTION_DISPLAY 按目标窗逐道缩放，仅用于显示，不改变输入。
    displayGather = double(gather);
    window = abs(time(:) - targetTime) <= halfWindow;
    assert(any(window), 'Reflection display window is empty.');
    for k = 1:size(displayGather, 2)
        scale = max(abs(displayGather(window, k)));
        if scale > 0, displayGather(:, k) = displayGather(:, k) / scale; end
    end
    displayGather = max(-1, min(1, displayGather));
end
