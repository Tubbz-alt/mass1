! ----------------------------------------------------------------
! file: pidlink.f90
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Battelle Memorial Institute
! Pacific Northwest Laboratory
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Created October 10, 2001 by William A. Perkins
! Last Change: Wed Oct 17 09:18:49 2001 by William A. Perkins <perk@gehenna.pnl.gov>
! ----------------------------------------------------------------


! ----------------------------------------------------------------
! MODULE pidlink
! PID stands for proportional, integral, and differential which is a
! mathematical description of process controllers.  This module
! implements a special link that uses the PID process control to cause
! the simulated water surface elevation to follow, but deviate as
! necessary from, observed stage.
! ----------------------------------------------------------------
MODULE pidlink

  IMPLICIT NONE
  CHARACTER (LEN=80), PRIVATE, SAVE :: rcsid = "$Id$"
  CHARACTER (LEN=80), PARAMETER, PRIVATE :: default_filename = "pidlink.dat"
  INTEGER, PARAMETER, PRIVATE :: maxlags = 5
  
  TYPE pidlink_lag_rec
     INTEGER :: link            ! link to get the flow from (point 1)
     REAL :: lag                ! in days

                                ! this is used to keep the lagged
                                ! flows in an FIFO queue, only the
                                ! number needed are saved
                                ! (lag/time_step)
     INTEGER :: nlag
     REAL, POINTER :: flow(:)
  END TYPE pidlink_lag_rec

  TYPE pidlink_rec
     INTEGER :: link            ! the link number
     REAL :: kc, ti, tr         ! constant coefficients
     REAL :: errsum             ! integral term
     REAL :: oldsetpt
     INTEGER :: numflows
     TYPE (pidlink_lag_rec), POINTER :: lagged(:)
  END TYPE pidlink_rec

  INTEGER, PRIVATE, ALLOCATABLE :: linkidmap(:)
  INTEGER, PRIVATE :: npidlink
  TYPE (pidlink_rec), PRIVATE, POINTER :: piddata(:)

CONTAINS

  ! ----------------------------------------------------------------
  ! SUBROUTINE read_pidlink_info
  ! ----------------------------------------------------------------
  SUBROUTINE read_pidlink_info()

    USE general_vars, ONLY: maxlinks
    USE link_vars, ONLY: linktype

    IMPLICIT NONE


    INTEGER :: l, link, count, laglink, i
    LOGICAL :: file_exist
    REAL :: kc, ti, tr, lagvalues(2*maxlags)
    REAL :: lagtime
    CHARACTER (LEN=256) :: fname
    INTEGER :: iounit

    fname = default_filename
    iounit = 33

                                ! determine the number of pid type
                                ! links we have in the link data, and
                                ! map the link id's into the array of
                                ! pidlinks

    ALLOCATE(linkidmap(maxlinks))
    linkidmap = 0
    count = 0
    DO l = 1, maxlinks
       IF (linktype(l) .EQ. 13) THEN 
          count = count + 1
          linkidmap(l) = count
       END IF
    END DO

    npidlink = count
    NULLIFY(piddata)

                                ! if there are none, we need not do
                                ! anything else

    IF (count .LE. 0) RETURN

                                ! open and read the pidlink data file

    INQUIRE(FILE=fname,EXIST=file_exist)
    IF(file_exist)THEN
       OPEN(iounit,file=fname)
       WRITE(99,*)'pidlink coefficient file opened: ', fname
    ELSE
       WRITE(*,*)'pidlink coefficient file does not exist - ABORT: ',fname
       WRITE(99,*)'pidlink coefficient file does not exist - ABORT: ',fname
       CALL EXIT(1)
    ENDIF

    ALLOCATE(piddata(count))

    DO l = 1, count
       lagvalues = -99.0
       READ (iounit, *, END=100) link, kc, ti, tr, lagvalues
       IF (linkidmap(link) .EQ. 0) THEN
          WRITE (99,*) 'ABORT: error reading pidlink coefficient file ', fname
          WRITE (99,*) 'record ', l, ' is for link ', link, &
               &', but link ', link, ' is not the correct type'
          WRITE (*,*) 'ABORT: error reading pidlink coefficient file ', fname
          WRITE (*,*) 'record ', l, ' is for link ', link, &
               &', but link ', link, ' is not the correct type'
          CALL EXIT(1)
       ELSE
          WRITE (99,*) 'setting coefficients for pidlink no. ', link
       END IF

       piddata(l)%link = link
       piddata(l)%kc = kc
       piddata(l)%ti = ti
       piddata(l)%tr = tr

                                ! count the number of flows that are
                                ! to be lagged
       
       DO i = 1, maxlags
          IF (lagvalues(i*2 - 1) .LE. 0) EXIT
       END DO
       piddata(l)%numflows = i - 1

       IF (piddata(l)%numflows .LE. 0) THEN
          WRITE (99,*) 'ABORT: error reading pidlink coefficient file ', TRIM(fname)
          WRITE (99,*) 'no lagged flows specified for link ', link
          WRITE (*,*) 'ABORT: error reading pidlink coefficient file ', TRIM(fname)
          WRITE (*,*) 'no lagged flows specified for link ', link
          CALL EXIT(1)
       END IF

                                ! make a list of the important
                                ! information for storing lagged flows
       
       ALLOCATE(piddata(l)%lagged(piddata(l)%numflows))
       
       DO i = 1, piddata(l)%numflows

                                ! identify and check the specified link

          laglink = INT(lagvalues(i*2 - 1))
          IF (laglink .EQ. 0  .OR. laglink .GT. maxlinks) THEN
             WRITE (99,*) 'ABORT: error reading pidlink coefficient file ', TRIM(fname)
             WRITE (99,*) 'link ', link, 'uses lagged flow from link ', laglink, &
                  &', which is not a valid link '
             WRITE (*,*) 'ABORT: error reading pidlink coefficient file ', TRIM(fname)
             WRITE (*,*) 'link ', link, 'uses lagged flow from link ', laglink, &
                  &', which is not a valid link '
             CALL EXIT(1)
          END IF
          piddata(l)%lagged(i)%link = laglink

                                ! check the specified lag

          lagtime = lagvalues(i*2)
          IF (lagtime .LT. 0) THEN
             WRITE (99,*) 'ABORT: error reading pidlink coefficient file ', TRIM(fname)
             WRITE (99,*) 'link ', link, 'uses lagged flow from link ', laglink, &
                  &', but the specified lag (', lagvalues(i*2), ') is invalid '
             WRITE (*,*) 'ABORT: error reading pidlink coefficient file ', TRIM(fname)
             WRITE (*,*) 'link ', link, 'uses lagged flow from link ', laglink, &
                  &', but the specified lag (', lagvalues(i*2), ') is invalid '
             CALL EXIT(1)
          END IF
          piddata(l)%lagged(i)%lag = lagtime

                                ! initialize the remainder of the
                                ! record

          piddata(l)%lagged(i)%nlag = 0
          nullify(piddata(l)%lagged(i)%flow)
       END DO

    END DO

    RETURN

                                ! this should be executed when too few
                                ! records are in the input file
100 CONTINUE
    WRITE (99,*) 'ABORT: error reading pidlink coefficient file ', TRIM(fname)
    WRITE (99,*) 'error reading record ', l, ' of ', count, ' expected'
    WRITE (*,*) 'ABORT: error reading pidlink coefficient file ', TRIM(fname)
    WRITE (*,*) 'error reading record ', l, ' of ', count, ' expected'
    CALL EXIT(1)
  END SUBROUTINE read_pidlink_info

  ! ----------------------------------------------------------------
  ! SUBROUTINE pidlink_assemble_lagged_flow
  ! This routine needs to be called after each time step
  ! ----------------------------------------------------------------
  SUBROUTINE pidlink_assemble_lagged_flow()

    USE general_vars, ONLY: time_step
    USE point_vars, ONLY: q
    IMPLICIT NONE
    TYPE (pidlink_rec), POINTER :: rec

    INTEGER :: i, j, k

    IF (.NOT. ASSOCIATED(piddata)) RETURN

    DO k = 1, npidlink
       rec => piddata(k)

       DO i = 1, rec%numflows

                                ! index 1 holds the oldest flow, get
                                ! rid of it and put the newest at the
                                ! end of the queue

          DO j = 2, rec%lagged(i)%nlag
             rec%lagged(i)%flow(j - 1) = rec%lagged(i)%flow(j)
          END DO
          rec%lagged(i)%flow(rec%lagged(i)%nlag) = q(rec%lagged(i)%link, 1)

       END DO
    END DO

  END SUBROUTINE pidlink_assemble_lagged_flow


  ! ----------------------------------------------------------------
  ! SUBROUTINE pidlink_initialize
  ! This routine does all necessary initialization of the piddata
  ! list.  It must be called after initial conditions have been
  ! applied.
  ! ----------------------------------------------------------------
  SUBROUTINE pidlink_initialize()

    USE general_vars, ONLY: time_begin, time_mult, time_step
    USE link_vars, ONLY: linkbc_table
    USE point_vars, ONLY: q

    IMPLICIT NONE

    TYPE (pidlink_rec), POINTER :: rec
    INTEGER :: i, j, link

    EXTERNAL table_interp
    REAL :: table_interp
    INTEGER :: table_type

    IF (.NOT. ASSOCIATED(piddata)) RETURN

    DO j = 1, npidlink
       rec => piddata(j)
       link = rec%link
       rec%errsum = 0.0
       table_type = 1
       rec%oldsetpt = table_interp(time_begin,table_type,linkbc_table(link),time_mult)
    
       DO i = 1, rec%numflows

                                ! allocate a queue and make it just
                                ! the right length: the number of
                                ! time_steps in the lag

          rec%lagged(i)%nlag = MAX(INT(rec%lagged(i)%lag/time_step + 0.5), 1)
          ALLOCATE(rec%lagged(i)%flow(rec%lagged(i)%nlag))

                                ! go ahead and fill the queue with the
                                ! initial conditions

          rec%lagged(i)%flow = q(rec%lagged(i)%link, 1)

       END DO
    END DO
       
  END SUBROUTINE pidlink_initialize

  ! ----------------------------------------------------------------
  ! REAL FUNCTION pidlink_lagged_flow
  ! This just adds up the lagged flows in the list
  ! ----------------------------------------------------------------
  REAL FUNCTION pidlink_lagged_flow(rec)

    IMPLICIT NONE
    TYPE (pidlink_rec) :: rec
    DOUBLE PRECISION :: time

    INTEGER :: i

    pidlink_lagged_flow = 0.0
  
    DO i = 1, rec%numflows
       pidlink_lagged_flow = pidlink_lagged_flow + rec%lagged(i)%flow(1)
    END DO

  END FUNCTION pidlink_lagged_flow


  ! ----------------------------------------------------------------
  ! SUBROUTINE pidlink_coeff
  ! ----------------------------------------------------------------
  SUBROUTINE pidlink_coeff(link, point, setpt, a, b, c, d, g, ap, bp, cp, dp, gp)

    USE general_vars, ONLY: time, time_step
    USE point_vars, ONLY: q, y
    USE date_vars, ONLY: date_string, time_string

    IMPLICIT NONE
    INTEGER, INTENT(IN) :: link, point
    REAL, INTENT(IN) :: setpt
    REAL, INTENT(OUT) ::  a, b, c, d, g, ap, bp, cp, dp, gp
    TYPE (pidlink_rec), POINTER :: rec

    INTEGER :: table_type

    EXTERNAL table_interp
    REAL :: table_interp, qlag

    rec => piddata(linkidmap(link))

    a = 0.0
    b = 1.0
    c = 0.0
    d = 1.0
    g = q(link, point) - q(link, point + 1)

    rec%errsum = rec%errsum + (y(link, point) -  rec%oldsetpt)*time_step
    qlag = pidlink_lagged_flow(rec)

    ap = 0.0
    bp = 0.0
    dp = -1.0
    IF (rec%ti .GT. 0.0) THEN
       cp = rec%kc*(1.0 + time_step/rec%ti + rec%tr/time_step)
       gp = qlag - q(link, point) + &
            & rec%kc*y(link, point)*(1.0 + time_step/rec%ti) - &
            & rec%kc*setpt*(1.0 + time_step/rec%ti + rec%tr/time_step) + &
            & rec%kc/rec%ti*rec%errsum + rec%kc*rec%tr/time_step*rec%oldsetpt
    ELSE
       cp = rec%kc*(1.0 + rec%tr/time_step)
       gp = qlag - q(link, point) + &
            & rec%kc*y(link, point) - &
            & rec%kc*setpt*(1.0 + rec%tr/time_step) + &
            & rec%kc*rec%tr/time_step*rec%oldsetpt
    END IF

    rec%oldsetpt = setpt

    ! WRITE (1,100) date_string, time_string, link, point, y(link, point), q(link, point), setpt, rec%oldsetpt, qlag, rec%errsum
100 FORMAT(A10, 1X, A8, 2(1X,I5), 6(1X,F10.2))
  END SUBROUTINE pidlink_coeff


END MODULE pidlink






