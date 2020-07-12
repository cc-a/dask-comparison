cd $PBS_O_WORKDIR
source activate dask-bench

n_procs=$1
N=$2
block=$3
repeats=$4
output_prefix=$5
nodes=( $(uniq "$PBS_NODEFILE") )

for r in $(echo $repeats | tr ',' ' ')
do
    mpirun -np $(( $n_procs + 2 )) -hosts ${nodes[$r]} python scripts/dask_benchmark.py $N $block > ${output_prefix}-${block}-${r} &
done

wait
