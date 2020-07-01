import os
import sys
import timeit

from dask.distributed import Client
from dask_mpi import initialize

# initialize(nthreads=1, local_directory=os.environ["TMPDIR"] + "/dask_workers", memory_limit=100e9)
initialize(nthreads=1, local_directory="/dev/shm/dask_workers", memory_limit=100e9)


def setup(inputs):
    N = int(sys.argv[1])
    block_size = sys.argv[2]

    if block_size == "full":
        block_size = str(N)
    elif block_size == "auto":
        block_size = "'auto'"
    return N, block_size


if __name__ == '__main__':
    client = Client()

    N, block_size = setup(sys.argv[1:])

    print(timeit.timeit("da.tensordot(a, b, axes=1).trace().compute()", setup=f'import numpy as np; import dask.array as da; a=da.random.random(({N}, {N}), chunks={block_size}).astype(np.float32); b=da.random.random(({N}, {N}), chunks={block_size}).astype(np.float32)', number=1))
