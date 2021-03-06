! ----------------------------------------------------------------
! file: bctable.f90
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Copyright (c) 2017 Battelle Memorial Institute
! Licensed under modified BSD License. A copy of this license can be
! found in the LICENSE file in the top level directory of this
! distribution.
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Created November 30, 2010 by William A. Perkins
! Last Change: 2017-06-21 13:02:24 d3g096
! ----------------------------------------------------------------
  
! RCS ID: $Id$ Battelle PNL

! ----------------------------------------------------------------
! MODULE bctable
! ----------------------------------------------------------------
MODULE bctable

  USE utility
  USE time_series

  IMPLICIT NONE

  CHARACTER (LEN=80), PRIVATE, SAVE :: rcsid = "$Id$"

  ! ----------------------------------------------------------------
  ! TYPE bc_table_entry
  ! ----------------------------------------------------------------
  TYPE bc_table_entry
     INTEGER :: id              ! identifier used in bc table file
     TYPE (time_series_rec), POINTER :: bc ! the time series
  END TYPE bc_table_entry

  ! ----------------------------------------------------------------
  ! TYPE bc_table
  ! ----------------------------------------------------------------
  TYPE bc_table
     CHARACTER(LEN=1024) :: fname
     INTEGER :: nbc
     INTEGER :: maxid
     INTEGER :: nfld
     INTEGER, POINTER :: idlookup(:)
     TYPE (bc_table_entry), POINTER :: bc(:)
  END TYPE bc_table


  TYPE (bc_table), PUBLIC, POINTER :: linkbc
  TYPE (bc_table), PUBLIC, POINTER :: hydrobc
  TYPE (bc_table), PUBLIC, POINTER :: tempbc
  TYPE (bc_table), PUBLIC, POINTER :: transbc
  TYPE (bc_table), PUBLIC, POINTER :: latflowbc

CONTAINS


  ! ----------------------------------------------------------------
  ! TYPE (BC_TABLE) FUNCTION bc_table_read
  ! ----------------------------------------------------------------
  TYPE (BC_TABLE) FUNCTION bc_table_read(filename, nfields) RESULT (tbl)

    IMPLICIT NONE

    CHARACTER(LEN=*), INTENT(IN) :: filename
    INTEGER, INTENT(IN) :: nfields

    POINTER tbl

    INTEGER, PARAMETER :: iounit = 53

    INTEGER :: count, maxid, i
    INTEGER :: bcid
    CHARACTER(LEN=1024) :: bcfile

    CALL open_existing(filename, iounit, fatal=.TRUE.)

    ! count the number of entries, and find the maximum bc id

    count = 0
    maxid = -1
    
    DO WHILE(.TRUE.)
       READ(iounit, *, END=100, ERR=1000) bcid, bcfile
       count = count + 1
       if (bcid .GT. maxid) maxid = bcid
    END DO
100 CONTINUE

    ALLOCATE(tbl)
    tbl%fname = filename
    tbl%nbc = count
    tbl%maxid = maxid
    tbl%nfld = nfields
    ALLOCATE(tbl%idlookup(maxid))
    tbl%idlookup = 0
    ALLOCATE(tbl%bc(count))
    
    REWIND(iounit)
    i = 1
    DO WHILE(.TRUE.)
       READ(iounit, *, END=101, ERR=1000) bcid, bcfile
       tbl%idlookup(bcid) = i
       tbl%bc(i)%id = bcid
       tbl%bc(i)%bc => time_series_read(bcfile, nfields)
       i = i + 1
    END DO
101 CONTINUE

    CLOSE(iounit)

    RETURN
1000 CONTINUE 

    CALL error_message("Error reading BC table" // TRIM(filename), .TRUE.)
  END FUNCTION bc_table_read

  ! ----------------------------------------------------------------
  ! LOGICAL FUNCTION bc_table_id_ok
  ! ----------------------------------------------------------------
  LOGICAL FUNCTION bc_table_id_ok(tbl, id)

    IMPLICIT NONE
    TYPE (bc_table), INTENT(IN) :: tbl
    INTEGER, INTENT(IN) :: id
    
    INTEGER :: idx

    idx = 0
    IF (id .LE. tbl%maxid) THEN
       idx = tbl%idlookup(id)
    END IF

    bc_table_id_ok = (idx .GT. 0)

  END FUNCTION bc_table_id_ok


  ! ----------------------------------------------------------------
  ! INTEGER FUNCTION bc_table_index
  ! ----------------------------------------------------------------
  INTEGER FUNCTION bc_table_index(tbl, id) RESULT(idx)

    IMPLICIT NONE

    TYPE (bc_table), INTENT(IN) :: tbl
    INTEGER, INTENT(IN) :: id

    CHARACTER(LEN=1024) :: msg

    IF (id .LE. tbl%maxid) THEN
       idx = tbl%idlookup(id)
    ELSE 
       idx = 0
    END IF

    IF (idx .LE. 0) THEN
       WRITE(msg, *) TRIM(tbl%fname), ": looking for bad BC id: ", id
       CALL error_message(msg, .TRUE.)
    END IF

  END FUNCTION bc_table_index


  ! ----------------------------------------------------------------
  ! SUBROUTINE bc_table_interpolate
  ! ----------------------------------------------------------------
  SUBROUTINE bc_table_interpolate(tbl, id, datetime)

    IMPLICIT NONE

    TYPE (bc_table), INTENT(IN) :: tbl
    INTEGER, INTENT(IN) :: id
    DOUBLE PRECISION, INTENT(IN) :: datetime

    INTEGER :: idx
    idx = bc_table_index(tbl, id)

    CALL time_series_interp(tbl%bc(idx)%bc, datetime)

  END SUBROUTINE bc_table_interpolate

  ! ----------------------------------------------------------------
  ! DOUBLE PRECISION FUNCTION bc_table_current
  ! ----------------------------------------------------------------
  DOUBLE PRECISION FUNCTION bc_table_current(tbl, id, fld)

    IMPLICIT NONE

    TYPE (bc_table), INTENT(IN) :: tbl
    INTEGER, INTENT(IN) :: id
    INTEGER, INTENT(IN) :: fld

    INTEGER idx

    idx = bc_table_index(tbl, id)

    bc_table_current = tbl%bc(idx)%bc%current(fld)
  END FUNCTION bc_table_current



END MODULE bctable
