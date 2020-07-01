cd $PBS_O_WORKDIR
source activate dask-exp

n_procs=$1
N=$2
blocks=$3
repeats=$4
output_prefix=$5

for block in $(echo $blocks | tr ',' ' ')
do
    for r in $(echo $repeats | tr ',' ' ')
    do
	mpirun -np $n_procs ./pblas_benchmark $N $block > ${output_prefix}-${block}-${r}
    done
done
