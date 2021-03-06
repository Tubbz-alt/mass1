!***************************************************************
! Copyright (c) 2017 Battelle Memorial Institute
! Licensed under modified BSD License. A copy of this license can be
! found in the LICENSE file in the top level directory of this
! distribution.
!***************************************************************
!
! NAME:	array_dealloc
!
! VERSION and DATE: MASS1 v0.75 3/25/98
!
! PURPOSE: deallocation of arrays after completion of run
!
! RETURNS:
!
! REQUIRED:
!
! LOCAL VARIABLES:
!
! COMMENTS:
!
!
! MOD HISTORY: dealloc for top_width,hyd_radius, etc; mcr 11/21/1997
!			   lateral inflows; mcr 3/25/98
!
!***************************************************************
! CVS ID: $Id$
! Last Change: Tue Dec  7 09:19:47 2010 by William A. Perkins <d3g096@PE10900.pnl.gov>
!

SUBROUTINE array_dealloc

USE flow_coeffs
USE link_vars
USE point_vars
USE section_vars
USE transport_vars
USE hydro_output_module

IMPLICIT NONE

!----------------------------------------------------------
!flow coeff module

DEALLOCATE(e,f,l,m,n)

!----------------------------------------------------------
!module link_vars

DEALLOCATE(maxpoints,linkname,linkorder,linktype,input_option)
DEALLOCATE(linkbc_table,num_con_links,con_links,ds_conlink)
DEALLOCATE(comporder,dsbc_table,transbc_table,tempbc_table)
DEALLOCATE(latflowbc_table, met_zone)
DEALLOCATE(lattransbc_table, lattempbc_table)
DEALLOCATE(crest)
DEALLOCATE(lpiexp)

!-----------------------------------------------------------
!module point_vars

DEALLOCATE(x, q, q_old)
DEALLOCATE(thalweg,y,y_old, manning,vel)
DEALLOCATE(kstrick, area, area_old)
DEALLOCATE(k_diff)
DEALLOCATE(top_width,hyd_radius,froude_num,friction_slope,bed_shear)
DEALLOCATE(lateral_inflow, lateral_inflow_old)
DEALLOCATE(courant_num, diffuse_num)

!-----------------------------------------------------------
!module sections_vars

DEALLOCATE(section_id,section_type,delta_y,sect_levels)
DEALLOCATE(section_number)
 
DEALLOCATE(bottom_width,bottom_width_flood)
DEALLOCATE(depth_main)

DEALLOCATE(sect_area,sect_hydradius,sect_depth)
DEALLOCATE(sect_width,sect_convey,sect_perm)

!----------------------------------------------------------
!MODULE transport_vars

DEALLOCATE(c)
DEALLOCATE(dxx)
DEALLOCATE(k_surf)
DEALLOCATE(temp)

!----------------------------------------------------------
!MODULE hydro_output_module

DEALLOCATE(hydro_spill, hydro_gen, hydro_disch, &
     &hydro_conc, hydro_sat, hydro_temp, hydro_baro)

END SUBROUTINE array_dealloc
