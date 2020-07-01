from itertools import product
from math import ceil
from string import Template
import os

RESULTS_DIR = "results"
WORKDIR = os.getcwd()
PPN = 24
N_REPEATS = 5

Ns = 32768, 65536
n_procs = 1, 4, 16, 64, 256
pblas_block_sizes = 32, 64, 128, 256, 512, 1024
dask_block_sizes = ("auto",)
methods = "pblas", "dask"
repeats = tuple(range(N_REPEATS))


def make_targets(dir_name, method, *args):
    """Generate target file names in `dir_name` for method, from the
    string representions of iterables passed as args.
    """
    roots = [
        "-".join([str(c) for c in comb])
        for comb in product(*args)
    ]

    return [f"{dir_name}/{method}-{root}" for root in roots]


pblas_long_targets = make_targets(
    RESULTS_DIR, "pblas", Ns[1:], n_procs[:1], pblas_block_sizes[3:4], repeats
) + make_targets(
    RESULTS_DIR, "pblas", Ns, n_procs[3:], pblas_block_sizes, repeats
)
pblas_short_targets = make_targets(
    RESULTS_DIR, "pblas", Ns[:1], n_procs[:1], pblas_block_sizes[3:4], repeats
) + make_targets(
    RESULTS_DIR, "pblas", Ns, n_procs[1:3], pblas_block_sizes, repeats
)

dask_long_targets = make_targets(
    RESULTS_DIR, "dask", Ns[1:], n_procs[:1], dask_block_sizes, repeats
) + make_targets(
    RESULTS_DIR, "dask", Ns, n_procs[3:], dask_block_sizes, repeats
)
dask_short_targets = make_targets(
    RESULTS_DIR, "dask", Ns[:1], n_procs[:1], dask_block_sizes, repeats
) + make_targets(
    RESULTS_DIR, "dask", Ns, n_procs[1:3], dask_block_sizes, repeats
)
    

rule dask_short:
    input:
        dask_short_targets

rule dask_long:
    input:
        dask_long_targets

rule pblas_short:
    input:
        pblas_short_targets

rule pblas_long:
    input:
        pblas_long_targets

rule short:
    input:
        dask_short_targets + pblas_short_targets

rule long:
    input:
        dask_long_targets + pblas_long_targets


def select(wildcards, output):
    """Return the number of nodes required for the number of
    processes specified by the n_proc wildcard.
    """
    return ceil(int(wildcards.n_proc) / PPN)


def output_prefix(wildcards, output):
    """Return the prefix to be used for output filenames"""
    return RESULTS_DIR + \
        f"/{wildcards.method}-{wildcards.N}-{wildcards.n_proc}"


shell_template = Template(
    "bash ${workdir}/scripts/run_{wildcards.method}.sh {wildcards.n_proc} "
    "{wildcards.N} {wildcards.block_size} {wildcards.repeat} "
    "{params.output_prefix}"
)
rule single_block_single_repeat:
    output:
        RESULTS_DIR + "/{method}-{N}-{n_proc}-{block_size}-{repeat}"
    params:
        select = select,
        walltime = "02:00:00",
        output_prefix = output_prefix
    wildcard_constraints:
        n_proc = "(" + "|".join(map(str, n_procs[:3])) + ")",
    shell:
        shell_template.substitute(workdir=WORKDIR)


# The below rule represents a special case for n_proc=1 and N=65536.
# The run time for this exceeds the walltime limit of the short queue
# where it would most naturally fit. As a workaround we run 5 at once,
# each on its own node. The mechanism for this is contained in the
# shell script. This places the jobs into the long queue.
spread_shell_template = Template(
    "bash ${workdir}/scripts/run_{wildcards.method}_spread.sh "
    "{wildcards.n_proc} {wildcards.N} {wildcards.block_size} "
    "{params.repeats} {params.output_prefix}"
)
rule single_block_multi_repeat_spread:
    output:
        [
            Template(
                RESULTS_DIR + "/{method}-{N}-{n_proc}-{block_size}-${rep}"
            ).substitute(rep=rep)
            for rep in repeats
        ]
    params:
        select = str(N_REPEATS),
        walltime = "06:00:00",
        repeats = ','.join(map(str, repeats)),
        output_prefix = output_prefix,
    wildcard_constraints:
        n_proc = str(n_procs[0]),
        N = Ns[1],
    shell:
        spread_shell_template.substitute(workdir=WORKDIR)


# for paramters sets that run in the large queue, queue time >> run time so
# throughput is much increased by running multiple blocks in a single job

multi_block_shell_template = Template(
    "bash "
    "${workdir}/scripts/run_{wildcards.method}.sh {wildcards.n_proc} "
    "{wildcards.N} {params.blocks} {params.repeats} {params.output_prefix}"
)
rule multi_block_multi_repeat_dask:
    output:
        [
            Template(
                RESULTS_DIR + "/{method}-{N}-{n_proc}-${block_size}-${rep}"
            ).substitute(rep=rep, block_size=block_size)
            for rep in repeats for block_size in dask_block_sizes
        ]
    params:
        select = select,
        walltime = "02:00:00",
        blocks = ",".join(map(str, dask_block_sizes)),
        repeats = ','.join(map(str, repeats)),
        output_prefix = output_prefix,
    wildcard_constraints:
        n_proc = "(" + "|".join(map(str, n_procs[3:])) + ")",
        method = "dask",
    shell:
        multi_block_shell_template.substitute(workdir=WORKDIR)

rule multi_block_multi_repeat_pblas:
    output:
        [
            Template(
                RESULTS_DIR + "/{method}-{N}-{n_proc}-${block_size}-${rep}"
            ).substitute(rep=rep, block_size=block_size)
            for rep in repeats for block_size in pblas_block_sizes
        ]
    params:
        select = select,
        walltime = "02:00:00",
        repeats = ','.join(map(str, repeats)),
        blocks = ",".join(map(str, pblas_block_sizes)),
        output_prefix = output_prefix,
    wildcard_constraints:
        n_proc = "(" + "|".join(map(str, n_procs[3:])) + ")",
        method = "pblas",
    shell:
        multi_block_shell_template.substitute(workdir=WORKDIR)


ruleorder: single_block_multi_repeat_spread > single_block_single_repeat
