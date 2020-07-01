
program test
  use mpi
  implicit none
  integer                  :: N
  integer                  :: context, n_proc_rows, n_proc_cols
  integer                  :: n_rows, n_cols
  integer                  :: row_blocks_per_proc, col_blocks_per_proc, block_size
  integer                  :: rows_per_proc, cols_per_proc
  integer                  :: row_id, col_id
  integer                  :: i, j, k, tmp, info, n_repeats
  integer, dimension(9)    :: array_desc_a, array_desc_b, array_desc_c
  real, allocatable        :: a(:, :), b(:, :), c(:, :)
  real                     :: pslatra, trace
  integer                  :: start, finish
  real                     :: count_rate
  character(len=50)        :: buffer
  integer                  :: n_procs, ierr

  call GET_COMMAND_ARGUMENT(1, buffer)
  read (buffer, '(i10)') N
  n_rows = N
  n_cols = N

  call MPI_Init(ierr)
  call MPI_Comm_size(MPI_COMM_WORLD, n_procs, ierr)
  n_proc_rows = sqrt(real(n_procs))
  n_proc_cols = n_proc_rows

  call GET_COMMAND_ARGUMENT(2, buffer)
  read (buffer, '(i10)') block_size

  call SL_INIT(context, n_proc_rows, n_proc_cols)

  call blacs_gridinfo(context, n_proc_rows, n_proc_cols, row_id, col_id)

  rows_per_proc = n_rows/n_proc_rows
  cols_per_proc = n_cols/n_proc_cols
  row_blocks_per_proc = rows_per_proc/block_size
  col_blocks_per_proc = cols_per_proc/block_size

  call descinit(array_desc_a, n_rows, n_cols, block_size, block_size, 0, 0, context, row_blocks_per_proc*block_size, info)
  call descinit(array_desc_b, n_rows, n_cols, block_size, block_size, 0, 0, context, row_blocks_per_proc*block_size, info)
  call descinit(array_desc_c, n_rows, n_cols, block_size, block_size, 0, 0, context, row_blocks_per_proc*block_size, info)

  ! a(:, :) = 1
  ! b(:, :) = 1

  ! if (row_id .eq. 0 .and. col_id .eq. 0) then
  !    a(2, 2) = 5
  ! endif

  ! write (*,*) a
  ! trace = pslatra(n_rows, a, 1, 1, array_desc_a)
  ! if (row_id .eq. 0 .and. col_id .eq. 0) then
  !    write (*,*) 'trace ', trace
  ! endif

  ! k = 1
  ! do j = 1, row_blocks_per_proc
  !    do i = 1, block_size
  !       tmp = i+(j-1)*block_size*row_blocks_per_proc + row_id * block_size
  !       a(k, :) = tmp - 1
  !       b(k, :) = tmp
  !       k = k + 1
  !    enddo
  ! enddo

  ! do i = 1, rows_per_proc
  !    a(i, :) = i - 1 + block_size*row_id
  !    b(i, :) = i + block_size*row_id
  ! enddo

  call SYSTEM_CLOCK(start)

  allocate (a(rows_per_proc, cols_per_proc), &
       b(rows_per_proc, cols_per_proc), &
       c(rows_per_proc, cols_per_proc))

  call RANDOM_NUMBER(a)
  call RANDOM_NUMBER(b)
  call psgemm('N', 'N', n_rows, n_cols, n_cols, 1.0, &
       a, 1, 1, array_desc_b, &
       b, 1, 1, array_desc_a, &
       0.0, c, 1, 1, array_desc_c)
  trace = pslatra(n_rows, c, 1, 1, array_desc_c)
  deallocate (a, b, c)
  call SYSTEM_CLOCK(finish, count_rate)

  if (row_id .eq. 0 .and. col_id .eq. 0) then
     write (*, *) (finish - start) / count_rate
  endif

  ! ! write (*, *) 'after', row_id, col_id, c
  ! if (row_id .eq. 0 .and. col_id .eq. 0) then
  !    write (*, *) 'after'
  !    write (*, *) c
  ! endif


  CALL BLACS_GRIDEXIT(context)
  call BLACS_EXIT(0)

endprogram test
