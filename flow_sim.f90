
!***************************************************************
!            Pacific Northwest National Laboratory
!***************************************************************
!
! NAME:	flow_sim
!
! VERSION and DATE: MASS1 v0.75 3/25/98
!
! PURPOSE: hydraulics solver for St. Venant Equations
!
! RETURNS:
!
! REQUIRED:
!
! LOCAL VARIABLES:
!
! COMMENTS: based on an old homework problem from Holly.
!
!
! MOD HISTORY: added hydrad to CALL section and added
!              calculation of froude_num, friction_slope, etc. ; mcr 11/21/1997
!			   added lateral inflow; mcr 3/25/98
!
!***************************************************************
!

SUBROUTINE flow_sim

! $DEBUG

USE general_vars
USE link_vars
USE point_vars
USE fluvial_coeffs
USE flow_coeffs
USE logicals , ONLY : do_latflow

IMPLICIT NONE

REAL :: a,b,c,d,g,ap,bp,cp,dp,gp,denom
REAL :: latq_old,latq_new
REAL :: depth,area_temp,width,conveyance,dkdy,hydrad
REAL :: sum,sum2,bcval,dy,dq,y_new_time, q_new_time
REAL :: table_interp, temp

INTEGER :: i,j,point_num,link,point,table_type

LOGICAL :: fluvial

! run through links top down according to computational order


links_forward:	DO i=1,maxlinks

link = comporder(i)

SELECT CASE(linktype(link))
	CASE(1,20,21)
		fluvial = .TRUE.
	CASE(2,3,4,5,6,7,13)
		fluvial = .FALSE.
END SELECT

! set upstream bc q(t) or junction condition for first point

point = 1

IF(num_con_links(link) == 0)THEN  ! must be an upstream most link

SELECT CASE(linktype(link))
	CASE(1,20)
	table_type = 1
	bcval = table_interp(time,table_type,linkbc_table(link),time_mult)
	CASE(21)
	table_type = 3 !generation flow
	temp = table_interp(time,table_type,linkbc_table(link),time_mult)

	table_type = 4 !spill flow
	bcval = table_interp(time,table_type,linkbc_table(link),time_mult)

	bcval = bcval + temp ! total flow rate at the dam
END SELECT
	q1 = q(link,point)
	e(link,point) = 0.0
	f(link,point) = bcval - q1

ELSE
	sum = 0.0
	sum2 = 0.0
	DO j=1,num_con_links(link)
	sum = sum + e(con_links(link,j),maxpoints(con_links(link,j)))
	sum2 = sum2 + q(con_links(link,j),maxpoints(con_links(link,j))) + f(con_links(link,j),maxpoints(con_links(link,j))) &
        + e(con_links(link,j),maxpoints(con_links(link,j)))*(y(link,point) - y(con_links(link,j),maxpoints(con_links(link,j))))
	END DO
	e(link,point) = sum
	f(link,point) = -q(link,point) + sum2

END IF


! do internal links
points: DO point=1,maxpoints(link)-1

IF( fluvial )THEN
! fluvial links
! set geometric data for points i, i+1
point_num = point
depth = y(link,point) - thalweg(link,point) !remember y is ELEVATION
CALL section(link,point_num,depth,area_temp,width,conveyance,dkdy,hydrad)
!CALL section(link,point_num,depth,area_temp,width,conveyance,dkdy)

y1 = y(link,point)
q1 = q(link,point)
a1 = area_temp
b1 = width
k1 = conveyance
ky1 = dkdy

vel(link,point_num) = q1/a1
area_old(link,point_num) = a1
q_old(link,point_num) = q1
y_old(link,point_num) = y1

point_num = point + 1
depth = y(link,point+1) - thalweg(link,point+1)
CALL section(link,point_num,depth,area_temp,width,conveyance,dkdy,hydrad)
!CALL section(link,point_num,depth,area_temp,width,conveyance,dkdy)
y2 = y(link,point+1)
q2 = q(link,point+1)
a2 = area_temp
b2 = width
k2 = conveyance
ky2 = dkdy

vel(link,point_num) = q2/a2
area_old(link,point_num) = a2
q_old(link,point_num) = q2
y_old(link,point_num) = y2

delta_x	= ABS(x(link,point+1) - x(link,point))

! uniform lateral inflow per unit length
IF(do_latflow)THEN
	IF(latflowbc_table(link) /= 0)THEN
	  latq_old = lateral_inflow(link,point) 
      lateral_inflow_old(link,point) = latq_old
	  table_type = 5 !lateral inflow
	  lateral_inflow(link,point) = table_interp(time,table_type,latflowbc_table(link),time_mult)
      latq_new = lateral_inflow(link,point)
	ELSE
	  latq_old = 0.0
	  latq_new = 0.0
	ENDIF
ELSE
	latq_old = 0.0
	latq_new = 0.0
ENDIF

CALL fluvial_coeff(link,a,b,c,d,g,ap,bp,cp,dp,gp,delta_x,delta_t,grav,latq_old,latq_new)


! nonfluvial internal links ----------------------------
ELSE

                                ! nonfluvial links also need q_old for
                                ! transport

   
	IF(linktype(link) == 6)THEN	  ! hydropower plant
	table_type = 3 !generation flow
	temp = table_interp(time,table_type,linkbc_table(link),time_mult)

	table_type = 4 !spill flow
	bcval = table_interp(time,table_type,linkbc_table(link),time_mult)

	bcval = bcval + temp ! total flow rate at the dam

	ELSE ! other non-fluvial links
	table_type = 1
	bcval = table_interp(time,table_type,linkbc_table(link),time_mult)
	ENDIF

	CALL nonfluvial_coeff(link,point,bcval,a,b,c,d,g,ap,bp,cp,dp,gp)

   q_old(link, :) = q(link, :)

END IF

denom = (c*dp - cp*d)
l(link,point) = (a*dp - ap*d)/denom
m(link,point) = (b*dp - bp*d)/denom
n(link,point) = (d*gp - dp*g)/denom

denom = b - m(link,point)*(c + d*e(link,point))
e(link,point+1)	= (l(link,point)*(c + d*e(link,point)) - a)/denom
f(link,point+1) = (n(link,point)*(c + d*e(link,point)) +d*f(link,point) + g)/denom

END DO points


END DO links_forward

!------------------------------------------------------------------------------
! run through links bottom to top

links_backward: DO i=maxlinks,1,-1

link = comporder(i)

point = maxpoints(link)

! set downstream bc y(t) or Q(t)  OR junction conditions

IF(ds_conlink(link) == 0)THEN

SELECT CASE(dsbc_type)
CASE(1)
! given downstream stage y(t)
	table_type = 1
	y1 = y(link,point)
	y_new_time = table_interp(time,table_type,dsbc_table(link),time_mult)

	dy = y_new_time - y1
	dq = e(link,point)*dy + f(link,point)
CASE(2)
! given Q(t)
	table_type = 1
	q1 = q(link,point)
	q_new_time = table_interp(time,table_type,dsbc_table(link),time_mult)
	dq = q_new_time - q1
	dy = (dq - f(link,point))/e(link,point)
END SELECT

!update stage and discharge at last point on the link
y(link,point) = y(link,point) + dy
q(link,point) = q(link,point) + dq

ELSE
! junction conditions
dy = y(ds_conlink(link),1) - y(link,point)
dq = e(link,point)*dy + f(link,point)
y(link,point) = y(link,point) + dy
q(link,point) = q(link,point) + dq

END IF

DO point=maxpoints(link)-1,1,-1

IF(linktype(link) == 2)THEN
    table_type = 1
	bcval = table_interp(time,table_type,linkbc_table(link),time_mult)
	dq = bcval - q(link,point)
	dy = (dq - f(link,point))/e(link,point)

ELSEIF(linktype(link) == 6)THEN

  table_type = 3 !generation flow
  temp = table_interp(time,table_type,linkbc_table(link),time_mult)

  table_type = 4 !spill flow
  bcval = table_interp(time,table_type,linkbc_table(link),time_mult)

  bcval = bcval + temp ! total flow rate at the dam

  dq = bcval - q(link,point)
  dy = (dq - f(link,point))/e(link,point)

ELSE

dy = l(link,point)*dy + m(link,point)*dq + n(link,point)
dq = e(link,point)*dy + f(link,point)

ENDIF
y(link,point) = y(link,point) + dy
q(link,point) = q(link,point) + dq

END DO


END DO links_backward

!------------------------------------------------------------------------------
! computes additional data after hydraulics have been
! updated for this time 
!-------------------------------------------------------------------------------
DO link = 1,maxlinks
	SELECT CASE(linktype(link)) 
	CASE(1,20,21)
		DO point = 1,maxpoints(link)

		depth = y(link,point) - thalweg(link,point)
		CALL section(link,point,depth,area_temp,width,conveyance,dkdy,hydrad)
!CALL section(link,point,depth,area_temp,width,conveyance,dkdy)

		area(link,point) = area_temp
		top_width(link,point) = width
		hyd_radius(link,point) = hydrad
		froude_num(link,point) = SQRT((q(link,point)**2*width)/(grav*area_temp**3))
		friction_slope(link,point) =&
                     & ((q(link,point)*manning(link,point))/&
                     & (res_coeff*area_temp*(hydrad**2.0)**0.3333333))**2.0
		bed_shear(link,point) = unit_weight_h2o*hydrad*friction_slope(link,point)

		END DO
	END SELECT
END DO



END SUBROUTINE flow_sim
