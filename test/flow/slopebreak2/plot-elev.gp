# -------------------------------------------------------------
# file: plot.gp
# -------------------------------------------------------------
# -------------------------------------------------------------
# Battelle Memorial Institute
# Pacific Northwest Laboratory
# -------------------------------------------------------------
# -------------------------------------------------------------
# Created March 22, 1999 by William A. Perkins
# Last Change: Thu Sep 30 07:23:39 2010 by William A. Perkins <d3g096@PE10900.pnl.gov>
# -------------------------------------------------------------
# $Id$


set samples 2000
set format x "%.1f"
set xrange [0:22000]
set xlabel 'Longitudinal Distance, ft'
set format y "%.1f"
set ylabel 'Elevation, ft'
set yrange [0:25]
set pointsize 0.5
# set timestamp
set key below

plot "<awk '/Time: 03:00/, /Time: 05:/ { if ($0 !~ /^ *#/) {print $4, $13;} }' profile1.out" using (2*10656 - $1):2 title 'Thalweg' with linespoint lt -1, \
     "<awk '/Time: 03:00/, /Time: 05:/ { if ($0 !~ /^ *#/) {print $4, $5;} }' profile1.out" using (2*10656 - $1):2 title 'Initial Conditions' with linespoint lt 1, \
     "<awk '/Time: 11:/, /END/ { if ($0 !~ /^ *#/) {print $4, $5;} }' profile1.out" using (2*10656 - $1):2 title 'Steady State' with linespoints lt 7  


