#! /bin/sh
# -------------------------------------------------------------
# file: runit.sh
# -------------------------------------------------------------
# -------------------------------------------------------------
# Battelle Memorial Institute
# Pacific Northwest Laboratory
# -------------------------------------------------------------
# -------------------------------------------------------------
# Created July  2, 1999 by William A. Perkins
# Last Change: Wed Sep 29 14:16:10 2010 by William A. Perkins <d3g096@bearflag.pnl.gov>
# -------------------------------------------------------------
# $Id$

set -x
set -e

                                # to trap floating point errors on SGI

TRAP_FPE='INVALID=ABORT(1);UNDERFL=ZERO;OVERFL=ABORT(1);INT_OVERFL=ABORT(1);DIVZERO=ABORT(1);DEBUG'
export TRAP_FPE

model=${MODEL-../../../mass1}

rm -f mass1.cfg
ln -f -s mass1-inflow.cfg mass1.cfg
$model

(echo \
    set terminal postscript portrait color solid \"Helvetica\" 14\; \
    set title \"Transport with Lateral Inflow\"\; \
    load \"plot.gp\"\; ) | \
        gnuplot > plot-inflow.eps

cp profile1.out profile1.inflow.out
rm -f mass1.cfg
ln -f -s mass1-outflow.cfg mass1.cfg
$model
rm -f mass1.cfg

(echo \
    set terminal postscript portrait color solid \"Helvetica\" 14\; \
    set title \"Transport with Lateral Outflow\"\; \
    load \"plot.gp\"\; ) | \
        gnuplot > plot-outflow.eps

cp profile1.out profile1.outflow.out

rm -f mass1.cfg
ln -f -s mass1-vary.cfg mass1.cfg
$model
rm -f mass1.cfg

(echo \
    set terminal postscript portrait color solid \"Helvetica\" 14\; \
    set title \"Transport with Varying Lateral Inflow/Outflow\"\; \
    load \"plot.gp\"\; ) | \
        gnuplot > plot-vary.eps

cp profile1.out profile1.vary.out
