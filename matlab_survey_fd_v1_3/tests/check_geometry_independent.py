"""Independent geometry arithmetic; does not execute or validate MATLAB code."""
from itertools import product


def pairs(shots, receivers, centre=500, width=25):
    return [(s, r) for s, r in product(shots, receivers)
            if centre - width / 2 <= (s + r) / 2 < centre + width / 2]


def stats(items):
    offsets = [r - s for s, r in items]
    return len(items), len(set(offsets)), len(set(map(abs, offsets)))


baseline = pairs(range(150, 851, 50), range(0, 1001, 50))
dense = pairs(range(100, 901, 20), range(-100, 1101, 20))
assert len(baseline) == len(set(baseline))
assert len(dense) == len(set(dense))
assert stats(baseline) == (15, 15, 8)
assert stats(dense) == (123, 83, 42)
print('CMP 500 m: A trace/signed/absolute =', stats(baseline))
print('CMP 500 m: M trace/signed/absolute =', stats(dense))
print('Arithmetic checks passed; this does not execute MATLAB or FD modelling.')
