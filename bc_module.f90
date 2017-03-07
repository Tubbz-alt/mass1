  ! ----------------------------------------------------------------
  ! file: bc_module.f90
  ! ----------------------------------------------------------------
  ! ----------------------------------------------------------------
  ! Battelle Memorial Institute
  ! Pacific Northwest Laboratory
  ! ----------------------------------------------------------------
  ! ----------------------------------------------------------------
  ! Created January 17, 2017 by William A. Perkins
  ! Last Change: 2017-03-07 14:28:45 d3g096
  ! ----------------------------------------------------------------
! ----------------------------------------------------------------
! MODULE bc_module
! ----------------------------------------------------------------
MODULE bc_module

  USE utility
  USE time_series
  USE dlist_module

  IMPLICIT NONE

  PRIVATE

  ENUM, BIND(C) 
     ENUMERATOR :: BC_ENUM = 0
     ENUMERATOR :: LINK_BC_TYPE = 1
     ENUMERATOR :: LATFLOW_BC_TYPE
     ENUMERATOR :: HYDRO_BC_TYPE
     ENUMERATOR :: TEMP_BC_TYPE
     ENUMERATOR :: TRANS_BC_TYPE
  END ENUM
  PUBLIC :: BC_ENUM, LINK_BC_TYPE, LATFLOW_BC_TYPE, HYDRO_BC_TYPE, &
       &TEMP_BC_TYPE, TRANS_BC_TYPE
  

  ! ----------------------------------------------------------------
  ! TYPE bc_t
  ! ----------------------------------------------------------------
  TYPE, ABSTRACT, PUBLIC :: bc_t
     INTEGER :: ID
     DOUBLE PRECISION :: current_value
   CONTAINS
     PROCEDURE (read_proc), DEFERRED :: read 
     PROCEDURE (update_proc), DEFERRED :: update
     PROCEDURE (destroy_proc), DEFERRED :: destroy
  END type bc_t

  ABSTRACT INTERFACE 

     SUBROUTINE read_proc(this, fname)
       IMPORT :: bc_t
       IMPLICIT NONE
       CLASS(bc_t), INTENT(INOUT) :: this
       CHARACTER(LEN=*), INTENT(IN) :: fname
     END SUBROUTINE read_proc

     SUBROUTINE update_proc(this, time)
       IMPORT :: bc_t
       IMPLICIT NONE
       CLASS(bc_t), INTENT(INOUT) :: this
       DOUBLE PRECISION, INTENT(IN) :: time
     END SUBROUTINE update_proc

     SUBROUTINE destroy_proc(this)
       IMPORT :: bc_t
       IMPLICIT NONE
       CLASS(bc_t), INTENT(INOUT) :: this
     END SUBROUTINE destroy_proc


  END INTERFACE

  ! ----------------------------------------------------------------
  ! TYPE simple_bc
  ! ----------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(bc_t) :: simple_bc_t
     TYPE (time_series_rec), POINTER :: tbl
   CONTAINS
     PROCEDURE :: read => simple_bc_read
     PROCEDURE :: update => simple_bc_update
     PROCEDURE :: destroy => simple_bc_destroy
  END type simple_bc_t

  
  ! ----------------------------------------------------------------
  ! TYPE bc_ptr
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: bc_ptr
     INTEGER (KIND(BC_ENUM)) :: bc_kind
     CLASS (bc_t), POINTER :: p
  END type bc_ptr

  ! ----------------------------------------------------------------
  ! TYPE hydro_bc
  ! ----------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(simple_bc_t) :: hydro_bc_t
     DOUBLE PRECISION :: current_spill
     DOUBLE PRECISION :: current_powerhouse
   CONTAINS
     PROCEDURE :: read => hydro_bc_read
     PROCEDURE :: update => hydro_bc_update
  END type hydro_bc_t

  ! ----------------------------------------------------------------
  ! TYPE bc_list
  ! ----------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(dlist) :: bc_list
   CONTAINS 
     PROCEDURE :: push => bc_list_push
     PROCEDURE :: pop => bc_list_pop
     PROCEDURE :: clear => bc_list_clear
     PROCEDURE :: find => bc_list_find
     PROCEDURE :: update => bc_list_update
  END type bc_list

  INTERFACE bc_list
     MODULE PROCEDURE new_bc_list
  END INTERFACE bc_list

  ! ----------------------------------------------------------------
  ! TYPE bc_manager_t
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: bc_manager_t
     TYPE (bc_list) :: bcs
   CONTAINS
     PROCEDURE :: read => bc_manager_read
     PROCEDURE :: find => bc_manager_find
     PROCEDURE :: update => bc_manager_update
     PROCEDURE :: destroy => bc_manager_destroy
  END type bc_manager_t

  INTERFACE bc_manager_t
     MODULE PROCEDURE new_bc_manager
  END INTERFACE bc_manager_t

  PUBLIC :: new_bc_manager
  
  TYPE (bc_manager_t), PUBLIC :: bc_manager

CONTAINS

  ! ----------------------------------------------------------------
  !  FUNCTION bc_kind_name
  ! ----------------------------------------------------------------
  FUNCTION bc_kind_name(bckind) RESULT(s)
    IMPLICIT NONE
    CHARACTER(LEN=80) :: s
    INTEGER (KIND(BC_ENUM)), INTENT(IN) :: bckind
    SELECT CASE (bckind)
    CASE (LINK_BC_TYPE)
       s = "Hydrodynamic"
    CASE (LATFLOW_BC_TYPE)
       s = "Lateral Inflow"
    CASE (HYDRO_BC_TYPE)
       s = "Hydropower"
    CASE (TEMP_BC_TYPE)
       s = "Temperature"
    CASE (TRANS_BC_TYPE)
       s = "TDG"
    CASE DEFAULT
       s = "Unknown"
    END SELECT
  END FUNCTION bc_kind_name

  ! ----------------------------------------------------------------
  ! SUBROUTINE simple_bc_read
  ! ----------------------------------------------------------------
  SUBROUTINE simple_bc_read(this, fname)
    IMPLICIT NONE
    CLASS(simple_bc_t), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: fname
    INTEGER, PARAMETER :: iunit = 55
    this%tbl => time_series_read(fname, iunit)
  END SUBROUTINE simple_bc_read

  ! ----------------------------------------------------------------
  ! SUBROUTINE simple_bc_update
  ! ----------------------------------------------------------------
  SUBROUTINE simple_bc_update(this, time)
    IMPLICIT NONE
    CLASS(simple_bc_t), INTENT(INOUT) :: this
    DOUBLE PRECISION, INTENT(IN) :: time

    CALL time_series_interp(this%tbl, time)
    this%current_value = this%tbl%current(1)

  END SUBROUTINE simple_bc_update

  ! ----------------------------------------------------------------
  ! SUBROUTINE simple_bc_destroy
  ! ----------------------------------------------------------------
  SUBROUTINE simple_bc_destroy(this)
    IMPLICIT NONE
    CLASS(simple_bc_t), INTENT(INOUT) :: this
    CALL time_series_destroy(this%tbl)
  END SUBROUTINE simple_bc_destroy

  ! ----------------------------------------------------------------
  ! SUBROUTINE hydro_bc_read
  ! ----------------------------------------------------------------
  SUBROUTINE hydro_bc_read(this, fname)
    IMPLICIT NONE
    CLASS(hydro_bc_t), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: fname
    INTEGER, PARAMETER :: iunit = 55
    this%tbl => time_series_read(fname, unit=iunit, fields=2)
  END SUBROUTINE hydro_bc_read

  ! ----------------------------------------------------------------
  ! SUBROUTINE hydro_bc_update
  ! ----------------------------------------------------------------
  SUBROUTINE hydro_bc_update(this, time)
    IMPLICIT NONE
    CLASS(hydro_bc_t), INTENT(INOUT) :: this
    DOUBLE PRECISION, INTENT(IN) :: time
    CALL time_series_interp(this%tbl, time)
    this%current_powerhouse = this%tbl%current(1)
    this%current_spill = this%tbl%current(2)
    this%current_value = this%current_spill + this%current_powerhouse
  END SUBROUTINE hydro_bc_update

  ! ----------------------------------------------------------------
  !  FUNCTION new_bc_list
  ! ----------------------------------------------------------------
  FUNCTION new_bc_list()
    IMPLICIT NONE
    TYPE (bc_list) :: new_bc_list
    NULLIFY(new_bc_list%head)
    NULLIFY(new_bc_list%tail)
  END FUNCTION new_bc_list


  ! ----------------------------------------------------------------
  ! SUBROUTINE bc_list_push
  ! ----------------------------------------------------------------
  SUBROUTINE bc_list_push(this, bckind, bc)
    IMPLICIT NONE
    CLASS (bc_list), INTENT(INOUT) :: this
    INTEGER (KIND(BC_ENUM)), INTENT(IN) :: bckind
    CLASS (bc_t), POINTER, INTENT(IN) :: bc
    TYPE (bc_ptr), POINTER :: ptr
    CLASS(*), POINTER :: p

    ALLOCATE(ptr)
    ptr%bc_kind = bckind
    ptr%p => bc
    p => ptr
    CALL this%genpush(p)
  END SUBROUTINE bc_list_push

  ! ----------------------------------------------------------------
  !  FUNCTION bc_list_pop
  ! ----------------------------------------------------------------
  FUNCTION bc_list_pop(this) RESULT(bc)
    IMPLICIT NONE
    CLASS (bc_list), INTENT(INOUT) :: this
    CLASS (bc_t), POINTER :: bc
    TYPE (bc_ptr), POINTER :: ptr
    CLASS(*), POINTER :: p

    NULLIFY(bc)
    p => this%genpop()

    IF (ASSOCIATED(p)) THEN
       SELECT TYPE (p)
       TYPE IS (bc_ptr)
          ptr => p
          bc => ptr%p
          DEALLOCATE(ptr)
       END SELECT
    END IF
    RETURN
  END FUNCTION bc_list_pop

  ! ----------------------------------------------------------------
  ! SUBROUTINE bc_list_clear
  ! ----------------------------------------------------------------
  SUBROUTINE bc_list_clear(this)
    IMPLICIT NONE
    CLASS (bc_list), INTENT(INOUT) :: this
    CLASS (bc_t), POINTER :: bc

    DO WHILE (.TRUE.)
       bc => this%pop()
       IF (ASSOCIATED(bc)) THEN
          CALL bc%destroy()
          DEALLOCATE(bc)
       ELSE 
          EXIT
       END IF
    END DO
  END SUBROUTINE bc_list_clear

  ! ----------------------------------------------------------------
  !  FUNCTION bc_list_find
  ! ----------------------------------------------------------------
  FUNCTION bc_list_find(this, bckind, bcid) RESULT(bc)
    IMPLICIT NONE
    CLASS (bc_t), POINTER :: bc
    CLASS (bc_list) :: this
    INTEGER (KIND(BC_ENUM)), INTENT(IN) :: bckind
    INTEGER, INTENT(IN) :: bcid

    TYPE (dlist_node), POINTER :: node
    TYPE (bc_ptr), POINTER :: ptr
    CLASS(*), POINTER :: p

    NULLIFY(bc)
    
    node => this%head
    DO WHILE (ASSOCIATED(node)) 
       p => node%data
       IF (ASSOCIATED(p)) THEN
          SELECT TYPE (p)
          TYPE IS (bc_ptr)
             ptr => p
             IF (ptr%bc_kind .EQ. bckind) THEN 
                bc => ptr%p
                IF (bc%id .EQ. bcid) THEN
                   EXIT
                END IF
             END IF
          END SELECT
       END IF
       node => node%next
    END DO
  END FUNCTION bc_list_find

  ! ----------------------------------------------------------------
  ! SUBROUTINE bc_list_update
  ! ----------------------------------------------------------------
  SUBROUTINE bc_list_update(this, time)
    IMPLICIT NONE
    CLASS (bc_list) :: this
    DOUBLE PRECISION, INTENT(IN) :: time
    TYPE (dlist_node), POINTER :: node
    TYPE (bc_ptr), POINTER :: ptr
    CLASS(*), POINTER :: p
    CLASS (bc_t), POINTER :: bc
    
    node => this%head
    DO WHILE (ASSOCIATED(node)) 
       p => node%data
       IF (ASSOCIATED(p)) THEN
          SELECT TYPE (p)
          TYPE IS (bc_ptr)
             ptr => p
             bc => ptr%p
             CALL bc%update(time)
          END SELECT
       END IF
       node => node%next
    END DO

  END SUBROUTINE bc_list_update


  ! ----------------------------------------------------------------
  ! SUBROUTINE bc_manager_read
  ! ----------------------------------------------------------------
  SUBROUTINE bc_manager_read(this, bckind, filename)
    IMPLICIT NONE
    CLASS (bc_manager_t), INTENT(INOUT) :: this
    INTEGER (KIND(BC_ENUM)), INTENT(IN) :: bckind
    CHARACTER(LEN=*), INTENT(IN) :: filename
    INTEGER, PARAMETER :: iounit = 53

    INTEGER :: i
    INTEGER :: bcid
    CHARACTER(LEN=1024) :: bcfile, msg
    CLASS (bc_t), POINTER :: bc

    CALL open_existing(filename, iounit, fatal=.TRUE.)
    WRITE(msg, *) "Reading ", TRIM(bc_kind_name(bckind)), &
         &" boundary conditions from ", TRIM(filename)
    CALL status_message(msg)

    i = 1
    DO WHILE(.TRUE.)
       READ(iounit, *, END=101, ERR=1000) bcid, bcfile
       SELECT CASE (bckind)
       CASE (LINK_BC_TYPE, LATFLOW_BC_TYPE, TEMP_BC_TYPE, TRANS_BC_TYPE)
          ALLOCATE(simple_bc_t :: bc)
       CASE (HYDRO_BC_TYPE)
          ALLOCATE(hydro_bc_t :: bc)
       CASE DEFAULT
          WRITE(msg, *) TRIM(filename) // ": unknown BC kind: ", bckind
          CALL error_message(msg, fatal=.TRUE.)
       END SELECT
       bc%id = bcid
       CALL bc%read(bcfile)
       CALL this%bcs%push(bckind, bc)
       WRITE(msg, '(A, ", line", I4, ": created ", A, " BC ", I4, " from ", A)')&
            &TRIM(filename), i, TRIM(bc_kind_name(bckind)), bcid, TRIM(bcfile)
       CALL status_message(msg)
       i = i + 1
    END DO
101 CONTINUE

    CLOSE(iounit)

    RETURN
1000 CONTINUE 

    CALL error_message("Error reading BC table" // TRIM(filename), .TRUE.)
  END SUBROUTINE bc_manager_read

  ! ----------------------------------------------------------------
  !  FUNCTION new_bc_manager
  ! ----------------------------------------------------------------
  FUNCTION new_bc_manager() RESULT (man)
    IMPLICIT NONE
    TYPE (bc_manager_t) :: man
    man%bcs = new_bc_list()
  END FUNCTION new_bc_manager

  ! ----------------------------------------------------------------
  !  FUNCTION bc_manager_find
  ! ----------------------------------------------------------------
  FUNCTION bc_manager_find(this, bckind, bcid) RESULT(bc)
    IMPLICIT NONE
    CLASS (bc_t), POINTER :: bc
    CLASS (bc_manager_t), INTENT(IN) :: this
    INTEGER (KIND(BC_ENUM)), INTENT(IN) :: bckind
    INTEGER, INTENT(IN) :: bcid
    bc => this%bcs%find(bckind, bcid)
  END FUNCTION bc_manager_find

  ! ----------------------------------------------------------------
  ! SUBROUTINE bc_manager_update
  ! ----------------------------------------------------------------
  SUBROUTINE bc_manager_update(this, time)
    IMPLICIT NONE
    CLASS (bc_manager_t), INTENT(INOUT) :: this
    DOUBLE PRECISION, INTENT(IN) :: time
    CALL this%bcs%update(time)
  END SUBROUTINE bc_manager_update


  ! ----------------------------------------------------------------
  ! SUBROUTINE bc_manager_destroy
  ! ----------------------------------------------------------------
  SUBROUTINE bc_manager_destroy(this)
    IMPLICIT NONE
    CLASS (bc_manager_t), INTENT(INOUT) :: this
    CALL this%bcs%clear()
  END SUBROUTINE bc_manager_destroy


END MODULE bc_module
  
