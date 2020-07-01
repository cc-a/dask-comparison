from collections import OrderedDict
from pathlib import Path

import numpy as np
from pytest import mark

from analysis_lib import load_data

ROOT_DIR = Path(__file__).parent / "test_load_data"
N_REPEATS = 2

a_kwargs = OrderedDict(
    nproc=[1, 4],
    block_size=[256],
    placement=["pack"],
    repeat=list(range(N_REPEATS))
)
a_timings = (
    (dict(placement="pack", block_size=256, nproc=4, repeat=1), 1798.978),
    (dict(placement="pack", block_size=256, nproc=1, repeat=0), 6711.620),
)


b_kwargs = dict(N=[256, 512], repeat=list(range(N_REPEATS)))
b_sizes = (
    (dict(N=256, repeat=1), 1.2200000E-02),
    (dict(N=512, repeat=1), 1.3700000E-02),
)

load_parameters = (("a", a_kwargs, a_timings), ("b", b_kwargs, b_sizes))


@mark.parametrize("data_dir,kwargs,timings", load_parameters)
def test_load(data_dir, kwargs, timings):
    data = load_data(
        ROOT_DIR / data_dir,
        **kwargs
    )

    assert data.shape == tuple(len(val) for val in kwargs.values())
    assert not np.any(np.isnan(data.min(dim="repeat")))
    for sel, timing in timings:
        assert data.sel(**sel) == timing

    assert data.dims == tuple(kwargs.keys())
    for dim, coords in kwargs.items():
        assert coords == list(data.coords[dim])
