# -------------------------------------------------------------
# file: mass-plot.gp
# -------------------------------------------------------------
# -------------------------------------------------------------
# Battelle Memorial Institute
# Pacific Northwest Laboratory
# -------------------------------------------------------------
# -------------------------------------------------------------
# Created March 16, 2000 by William A. Perkins
# Last Change: Thu Mar 16 13:53:59 2000 by William A. Perkins <perk@mack.pnl.gov>
# -------------------------------------------------------------
# $Id$

set xdata time
set timefmt '%m-%d-%Y %H:%M:%S'

set data style lines

set format x '%H:%M'
set xlabel 'Simulation Time'

set format y '%.1e'
set ylabel 'Contaminant Mass'

set key bottom

plot 7200000 notitle with lines 0, \
     "<awk '$0 !~ /^#/ {sum=sum+$4*$8*144; print $1, $2, sum; }' ts11.out" using 1:3 title 'Inflow' with lines 1, \
     "<awk '$0 !~ /^#/ {sum=sum+$4*$8*144; print $1, $2, sum; }' tsend.out" using 1:3 title 'Outflow' with lines 3
     