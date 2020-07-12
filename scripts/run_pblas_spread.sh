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
    mpirun -np $n_procs -hosts ${nodes[$r]} ./pblas_benchmark $N $block > ${output_prefix}-${block}-${r} &
done

wait
