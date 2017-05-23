#! /bin/sh
# -------------------------------------------------------------
# file: runit.sh
# -------------------------------------------------------------
# -------------------------------------------------------------
# Battelle Memorial Institute
# Pacific Northwest Laboratory
# -------------------------------------------------------------
# -------------------------------------------------------------
# Created December 11, 1998 by William A. Perkins
# Last Change: 2017-03-10 08:02:12 d3g096
# -------------------------------------------------------------
# $Id$

set -x
set -e

model=${MODEL-../../../build/mass1}

$model

(echo \
    set terminal postscript landscape color solid \"Helvetica\" 14\; \
    load \"plot.gp\"\; ) | \
        gnuplot > plot.ps
(echo \
    set terminal postscript eps color solid \"Helvetica\" 22 \; \
    load \"plot.gp\"\; ) | \
        gnuplot > plot.eps

(echo \
    set terminal postscript landscape color solid \"Helvetica\" 14\; \
    load \"plot-elev.gp\"\; ) | \
        gnuplot > plot-elev.ps
(echo \
    set terminal postscript eps color solid \"Helvetica\" 22 \; \
    load \"plot-elev.gp\"\; ) | \
        gnuplot > plot-elev.eps
