from itertools import product

from xarray import DataArray
import numpy as np


def load_data(dir_path, **kwargs):
    dims = kwargs.keys()
    coords = kwargs.values()
    data = DataArray(
        np.empty(
            tuple(len(kwarg) for kwarg in kwargs.values())
        ),
        dims=dims,
        coords=coords,
    )
    for comb in product(*coords):
        timing = get_timing(dir_path, *comb)
        indices = dict(zip(dims, comb))
        data.loc[indices] = timing
    return data


def get_timing(dir_path, *args):
    path = dir_path / "-".join([str(arg) for arg in args])
    try:
        with open(path) as f:
            return float(f.read().strip())
    except (FileNotFoundError, ValueError):
        return np.nan


def speed_up(timings, reference):
    return reference / timings
