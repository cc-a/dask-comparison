# Dask Linear Algebra Benchmark

This repository contains a benchmarking exercise comparing the performance of
Dask against the linear algreba library PBLAS. Results can be seen in the
[Jupyter notebook](analysis.ipynb). This notebook contains output of the
analysis run against timings obtained from Imperial's Research Computing
Service. The raw data for these timings can be found in the `results`
directory.

## Setup

A Conda environment for running the benchmark, analysing the resulting data and
displaying it via a Jupyter notebook is provided. First create the environment:
```
conda env create -v environment.yml
```

## Execution

The benchmark can then be executed via Snakemake. The exact method for this
varies depending on the computational environment. For instance, to run on
Imperial's Research Computing Service (RCS), Snakemake must be called twice:
```
snakemake -k --cluster "qsub -l walltime={params.walltime},select={params.select}:ncpus=48:mem=100gb:mpiprocs=24" -j 3 short
snakemake -k --cluster "qsub -l walltime={params.walltime},select={params.select}:ncpus=48:mem=100gb:mpiprocs=24:cpumodel=24" -j 3 long
```

The rules defined in the `Snakefile` are designed to maximise throughput on the
RCS. You'll need to remove the current data in the results directory so that
Snakemake will regenerate it.

## Analysis

Some tests are provided for the analysis code. These can be run with
```
python -m pytest .
```

To run the analysis, start a notebook server with:
```
jupyter notebook
```

open `analysis.ipynb`, and execute the cells as desired.
