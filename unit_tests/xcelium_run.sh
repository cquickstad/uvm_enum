#!/bin/bash

# $UVM_UNIT should be set to wherever you installed https://github.com/cquickstad/uvm_unit

xrun \
    -xmallerror \
    -nowarn RNDFUNAC:RNDXCELON:RTSVAV:SRCDEPR \
    -access rwc \
    -sv \
    -timescale 1ns/1ns \
    -xceligen on \
    -disable_sem2009 \
    -uvmhome $UVM_UNIT/uvm_unit-uvm-1.2 \
    -uvmnoautocompile \
    -uvmnocdnsextra \
    -uvmnoloaddpi \
    -sv_lib $UVM_HOME/lib/libuvmdpi.so \
    -incdir $UVM_UNIT \
    -incdir $UVM_UNIT/uvm_unit-uvm-1.2/src \
    -incdir ../ \
    \
    $*
