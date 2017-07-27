! ----------------------------------------------------------------
! file: link_module.f90
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Copyright (c) 2017 Battelle Memorial Institute
! Licensed under modified BSD License. A copy of this license can be
! found in the LICENSE file in the top level directory of this
! distribution.
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Created March  8, 2017 by William A. Perkins
! Last Change: 2017-07-27 08:03:33 d3g096
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! MODULE link_module
! ----------------------------------------------------------------
MODULE link_module

  USE utility
  USE dlist_module
  USE bc_module
  USE mass1_config

  IMPLICIT NONE

  PRIVATE

  ! ----------------------------------------------------------------
  ! TYPE confluence_ptr (forward)
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: confluence_ptr
     TYPE (confluence_t), POINTER :: p
  END type confluence_ptr

  ! ----------------------------------------------------------------
  ! TYPE link_input_data
  ! Fields expected in link input data
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: link_input_data
    INTEGER :: linkid, inopt, npt, lorder, ltype
    INTEGER :: nup, dsid
    INTEGER :: dsbcid, gbcid, tbcid, mzone, lbcid, lgbcid, ltbcid
    DOUBLE PRECISION :: lpiexp
  CONTAINS 
    PROCEDURE :: defaults => link_input_defaults
  END type link_input_data

  ! ----------------------------------------------------------------
  ! TYPE link_t
  ! ----------------------------------------------------------------
  TYPE, ABSTRACT, PUBLIC :: link_t
     INTEGER :: id
     INTEGER :: order
     INTEGER :: dsid
     TYPE (bc_ptr) :: usbc, dsbc
     TYPE (confluence_ptr) :: ucon, dcon
   CONTAINS

     PROCEDURE (init_proc), DEFERRED :: initialize
     PROCEDURE (readpts_proc), DEFERRED :: readpts
     PROCEDURE (destroy_proc), DEFERRED :: destroy

     PROCEDURE, NON_OVERRIDABLE :: set_order => link_set_order

     ! the up/down routines are required by confluence

     PROCEDURE (up_down_proc), DEFERRED :: q_up
     PROCEDURE (up_down_proc), DEFERRED :: q_down
     PROCEDURE (up_down_proc), DEFERRED :: y_up
     PROCEDURE (up_down_proc), DEFERRED :: y_down
     PROCEDURE (c_up_down_proc), DEFERRED :: c_up
     PROCEDURE (c_up_down_proc), DEFERRED :: c_down

     ! hydrodynamics are computed with two sweeps

     PROCEDURE (fsweep_proc), DEFERRED :: forward_sweep
     PROCEDURE (bsweep_proc), DEFERRED :: backward_sweep
     PROCEDURE (hupdate_proc), DEFERRED :: hydro_update


  END type link_t

  ABSTRACT INTERFACE
     FUNCTION init_proc(this, ldata, bcman) RESULT(ierr)
       IMPORT :: link_t, link_input_data, bc_manager_t
       IMPLICIT NONE
       INTEGER :: ierr
       CLASS (link_t), INTENT(INOUT) :: this
       CLASS (link_input_data), INTENT(IN) :: ldata
       CLASS (bc_manager_t), INTENT(IN) :: bcman
     END FUNCTION init_proc

     FUNCTION readpts_proc(this, theconfig, punit, lineno) RESULT (ierr)
       IMPORT :: link_t, configuration_t
       IMPLICIT NONE
       INTEGER :: ierr
       CLASS (link_t), INTENT(INOUT) :: this
       TYPE (configuration_t), INTENT(IN) :: theconfig
       INTEGER, INTENT(IN) :: punit
       INTEGER, INTENT(INOUT) :: lineno

     END FUNCTION readpts_proc


     DOUBLE PRECISION FUNCTION up_down_proc(this)
       IMPORT :: link_t
       IMPLICIT NONE
       CLASS (link_t), INTENT(IN) :: this
     END FUNCTION up_down_proc
     
     DOUBLE PRECISION FUNCTION c_up_down_proc(this, ispecies)
       IMPORT :: link_t
       IMPLICIT NONE
       CLASS (link_t), INTENT(IN) :: this
       INTEGER, INTENT(IN) :: ispecies
     END FUNCTION c_up_down_proc
     
     SUBROUTINE fsweep_proc(this, deltat)
       IMPORT :: link_t
       IMPLICIT NONE
       CLASS (link_t), INTENT(INOUT) :: this
       DOUBLE PRECISION, INTENT(IN) :: deltat
     END SUBROUTINE fsweep_proc

     SUBROUTINE bsweep_proc(this)
       IMPORT :: link_t
       IMPLICIT NONE
       CLASS (link_t), INTENT(INOUT) :: this
     END SUBROUTINE bsweep_proc

     SUBROUTINE hupdate_proc(this, res_coeff)
       IMPORT :: link_t
       IMPLICIT NONE
       CLASS (link_t), INTENT(INOUT) :: this
       DOUBLE PRECISION, INTENT(IN) :: res_coeff
     END SUBROUTINE hupdate_proc

     SUBROUTINE destroy_proc(this)
       IMPORT :: link_t
       IMPLICIT NONE
       CLASS (link_t), INTENT(INOUT) :: this
     END SUBROUTINE destroy_proc

  END INTERFACE

  ! ----------------------------------------------------------------
  ! TYPE link_ptr
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: link_ptr
     CLASS (link_t), POINTER :: p
  END type link_ptr

  ! ----------------------------------------------------------------
  ! link_list
  ! ----------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(dlist) :: link_list
   CONTAINS
     PROCEDURE :: push => link_list_push
     PROCEDURE :: pop => link_list_pop
     PROCEDURE :: clear => link_list_clear
     PROCEDURE :: find => link_list_find
     PROCEDURE :: current => link_list_current
  END type link_list

  INTERFACE link_list
     MODULE PROCEDURE new_link_list
  END INTERFACE link_list

  PUBLIC new_link_list

  ! ----------------------------------------------------------------
  ! TYPE confluence_t
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: confluence_t
     TYPE (link_list) :: ulink
     TYPE (link_ptr) :: dlink
   CONTAINS
     PROCEDURE :: coeff_e => confluence_coeff_e
     PROCEDURE :: coeff_f => confluence_coeff_f
     PROCEDURE :: elev => confluence_elev
     PROCEDURE :: conc => confluence_conc
     PROCEDURE :: set_order => confluence_set_order
  END type confluence_t

  INTERFACE confluence_t
     MODULE PROCEDURE new_confluence_t
  END INTERFACE

  INTERFACE confluence_ptr
     MODULE PROCEDURE new_confluence_ptr
  END INTERFACE confluence_ptr

CONTAINS

  ! ----------------------------------------------------------------
  ! SUBROUTINE link_input_defaults
  ! ----------------------------------------------------------------
  SUBROUTINE link_input_defaults(this)
    IMPLICIT NONE
    CLASS (link_input_data), INTENT(INOUT) :: this

    this%linkid = 0
    this%inopt = 1
    this%npt = 0
    this%lorder = 0
    this%ltype = 0
    this%nup = 0
    this%dsbcid = 0
    this%gbcid = 0
    this%tbcid = 0
    this%mzone = 0
    this%lbcid = 0
    this%lgbcid = 0
    this%ltbcid = 0
    this%lpiexp = 0.0

    this%dsid = 0

  END SUBROUTINE link_input_defaults


  ! ! ----------------------------------------------------------------
  ! !  FUNCTION new_link_t
  ! ! ----------------------------------------------------------------
  ! FUNCTION new_link_t(id, dsid) RESULT(link)
  !   IMPLICIT NONE
  !   INTEGER, INTENT(IN) :: id, dsid
  !   TYPE (link_t) :: link

  !   link%id = id
  !   link%dsid = dsid
  !   NULLIFY(link%usbc%p)
  !   NULLIFY(link%dsbc%p)
  !   NULLIFY(link%ucon%p)
  !   NULLIFY(link%dcon%p)

  ! END FUNCTION new_link_t

  ! ----------------------------------------------------------------
  !  FUNCTION link_initialize
  ! ----------------------------------------------------------------
  FUNCTION link_initialize(this, ldata, bcman) RESULT(ierr)

    IMPLICIT NONE
    INTEGER :: ierr
    CLASS (link_t), INTENT(INOUT) :: this
    CLASS (link_input_data), INTENT(IN) :: ldata
    CLASS (bc_manager_t), INTENT(IN) :: bcman
    CHARACTER (LEN=1024) :: msg


  END FUNCTION link_initialize

  ! ----------------------------------------------------------------
  !  FUNCTION new_link_list
  ! ----------------------------------------------------------------
  FUNCTION new_link_list()
    IMPLICIT NONE
    TYPE (link_list) :: new_link_list
    NULLIFY(new_link_list%head)
    NULLIFY(new_link_list%tail)
  END FUNCTION new_link_list


  ! ----------------------------------------------------------------
  ! SUBROUTINE link_list_push
  ! ----------------------------------------------------------------
  SUBROUTINE link_list_push(this, alink)
    IMPLICIT NONE
    CLASS (link_list), INTENT(INOUT) :: this
    CLASS (link_t), POINTER, INTENT(IN) :: alink
    TYPE (link_ptr), POINTER :: ptr
    CLASS(*), POINTER :: p

    ALLOCATE(ptr)
    ptr%p => alink
    p => ptr
    CALL this%genpush(p)
  END SUBROUTINE link_list_push

  ! ----------------------------------------------------------------
  !  FUNCTION link_list_pop
  ! ----------------------------------------------------------------
  FUNCTION link_list_pop(this) RESULT(link)
    IMPLICIT NONE
    CLASS (link_list), INTENT(INOUT) :: this
    CLASS (link_t), POINTER :: link
    TYPE (link_ptr), POINTER :: ptr
    CLASS(*), POINTER :: p

    NULLIFY(link)
    p => this%genpop()

    IF (ASSOCIATED(p)) THEN
       SELECT TYPE (p)
       TYPE IS (link_ptr)
          ptr => p
          link => ptr%p
          DEALLOCATE(ptr)
       END SELECT
    END IF
    RETURN
  END FUNCTION link_list_pop

  ! ----------------------------------------------------------------
  ! SUBROUTINE link_list_clear
  ! ----------------------------------------------------------------
  SUBROUTINE link_list_clear(this)
    IMPLICIT NONE
    CLASS (link_list), INTENT(INOUT) :: this
    CLASS (link_t), POINTER :: link

    DO WHILE (.TRUE.)
       link => this%pop()
       IF (ASSOCIATED(link)) THEN
          CALL link%destroy()
          DEALLOCATE(link)
       ELSE 
          EXIT
       END IF
    END DO
  END SUBROUTINE link_list_clear

  ! ----------------------------------------------------------------
  !  FUNCTION link_list_find
  ! ----------------------------------------------------------------
  FUNCTION link_list_find(this, linkid) RESULT(link)
    IMPLICIT NONE
    CLASS (link_t), POINTER :: link
    CLASS (link_list) :: this
    INTEGER, INTENT(IN) :: linkid

    NULLIFY(link)

    CALL this%begin()
    link => this%current()
    DO WHILE (ASSOCIATED(link)) 
       IF (link%id .EQ. linkid) THEN
          EXIT
       END IF
       CALL this%next()
       link => this%current()
    END DO
  END FUNCTION link_list_find

  ! ----------------------------------------------------------------
  !  FUNCTION link_list_current
  ! ----------------------------------------------------------------
  FUNCTION link_list_current(this) RESULT(link)
    IMPLICIT NONE
    CLASS (link_t), POINTER :: link
    CLASS (link_list) :: this
    TYPE (link_ptr), POINTER :: ptr
    CLASS(*), POINTER :: p

    NULLIFY(link)

    IF (ASSOCIATED(this%cursor)) THEN
       p => this%cursor%data
       IF (ASSOCIATED(p)) THEN
          SELECT TYPE (p)
          TYPE IS (link_ptr)
             ptr => p
             link => ptr%p
          END SELECT
       END IF
    END IF
  END FUNCTION link_list_current

  ! ----------------------------------------------------------------
  !  FUNCTION new_confluence_t
  ! ----------------------------------------------------------------
  FUNCTION new_confluence_t(dlink)
    IMPLICIT NONE
    TYPE (confluence_t) :: new_confluence_t
    CLASS (link_t), POINTER, INTENT(IN) :: dlink
    new_confluence_t%ulink = new_link_list()
    new_confluence_t%dlink%p => dlink
  END FUNCTION new_confluence_t

  ! ----------------------------------------------------------------
  !  FUNCTION new_confluence_ptr
  ! ----------------------------------------------------------------
  FUNCTION new_confluence_ptr()

    IMPLICIT NONE
    TYPE (confluence_ptr) :: new_confluence_ptr
    NULLIFY(new_confluence_ptr%p)
  END FUNCTION new_confluence_ptr

  ! ----------------------------------------------------------------
  ! FUNCTION confluence_coeff_e
  !
  ! This is called by the downstream link and returns the sum of the
  ! upstream link "e" momentum cofficients
  ! ----------------------------------------------------------------
  FUNCTION confluence_coeff_e(this) RESULT(ue)
    IMPLICIT NONE
    DOUBLE PRECISION :: ue
    CLASS (confluence_t), INTENT(INOUT) :: this

    ue = 0.0
    
  END FUNCTION confluence_coeff_e

  ! ----------------------------------------------------------------
  !  FUNCTION confluence_coeff_f
  ! ----------------------------------------------------------------
  FUNCTION confluence_coeff_f(this) RESULT(uf)

    IMPLICIT NONE
    DOUBLE PRECISION :: uf
    CLASS (confluence_t), INTENT(INOUT) :: this
    uf = 0.0

  END FUNCTION confluence_coeff_f

  ! ----------------------------------------------------------------
  !  FUNCTION confluence_elev
  ! ----------------------------------------------------------------
  FUNCTION confluence_elev(this) RESULT(dsy)

    IMPLICIT NONE
    DOUBLE PRECISION :: dsy
    CLASS (confluence_t), INTENT(INOUT) :: this

    dsy = this%dlink%p%y_up()

  END FUNCTION confluence_elev

  ! ----------------------------------------------------------------
  !  FUNCTION confluence_conc
  ! ----------------------------------------------------------------
  FUNCTION confluence_conc(this, ispecies) RESULT(uconc)

    IMPLICIT NONE
    DOUBLE PRECISION :: uconc
    CLASS (confluence_t), INTENT(INOUT) :: this
    INTEGER, INTENT(IN) :: ispecies
    CLASS (link_t), POINTER :: link
    DOUBLE PRECISION :: qin, qout, cavg
    INTEGER :: n
    
    qin = 0.0
    qout = 0.0
    uconc = 0.0
    cavg = 0.0
    
    CALL this%ulink%begin()
    link => this%ulink%current()
    DO WHILE (ASSOCIATED(link))
       cavg = cavg + link%c_down(ispecies)
       IF (link%q_down() .GE. 0.0) THEN
          qin = qin + link%q_down()
          uconc = link%q_down()*link%c_down(ispecies)
       ELSE 
          qout = qout + link%q_down()
       END IF
       n = n + 1
    END DO
    
    link => this%dlink%p
    cavg = cavg +  link%c_up(ispecies)
    IF (link%q_up() .LT. 0.0) THEN
       qin = qin + link%q_up()
       uconc = link%q_up()*link%c_up(ispecies)
    ELSE 
       qout = qout + link%q_up()
    END IF
       
    IF (qout .GT. 0.0) THEN
       uconc = uconc/qout
    ELSE 
       uconc = cavg/REAL(n+1)
    END IF
  END FUNCTION confluence_conc

  ! ----------------------------------------------------------------
  !  FUNCTION confluence_set_order
  ! ----------------------------------------------------------------
  RECURSIVE FUNCTION confluence_set_order(this, order0) RESULT(order)

    IMPLICIT NONE
    INTEGER :: order
    CLASS (confluence_t), INTENT(INOUT) :: this
    INTEGER, INTENT(IN) :: order0
    CLASS (link_t), POINTER :: link
    INTEGER :: o

    o = order0

    CALL this%ulink%begin()
    link => this%ulink%current()
    DO WHILE (ASSOCIATED(link))
       o = link%set_order(o)
       CALL this%ulink%next()
       link => this%ulink%current()
    END DO
    order = o

  END FUNCTION confluence_set_order


  ! ----------------------------------------------------------------
  !  FUNCTION link_set_order
  ! ----------------------------------------------------------------
  RECURSIVE FUNCTION link_set_order(this, order0) RESULT(order)
    IMPLICIT NONE
    INTEGER :: order
    CLASS (link_t), INTENT(INOUT) :: this
    INTEGER, INTENT(IN) :: order0
    INTEGER :: o

    o = order0
    IF (ASSOCIATED(this%ucon%p)) THEN
       o = this%ucon%p%set_order(o)
    END IF
    this%order = o
    order = o + 1

  END FUNCTION link_set_order



END MODULE link_module