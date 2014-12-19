#!/bin/sh
export BOARD="jactive"
export CARRIER="eur"
export ADD_KTWEAKER="Y"
export EXEC_LOKI="N"
export RD_CMDLINE="androidboot.hardware=qcom user_debug=31 zcache msm_rtb.filter=0x3F ehci-hcd.park=3"

if [ "$1" == "lp" ]; then
    export MREV="LP5.0"
    export VERSION=5.0
else
    export MREV="KK4.4"
    export VERSION=4.4
    
fi
./build_master.sh
