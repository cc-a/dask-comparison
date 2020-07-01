INCPATH=$(MKLROOT)/include
LIBS=-lmkl_core -lmkl_intel_thread -lmkl_intel_lp64 -liomp5 -lmkl_blacs_intelmpi_lp64 -lmkl_scalapack_lp64
FLAGS=-O2

pblas_benchmark: pblas_benchmark.f90
	mpif90 -fc=x86_64-conda_cos6-linux-gnu-gfortran $(FLAGS) -o $@ $< $(LIBS)
