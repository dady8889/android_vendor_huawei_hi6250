#!/system/bin/sh

KBG_MAXINFLIGHT=$1
BG_MAXINFLIGHT=$2

USERDATADIR="/data"
BLKROOT="/dev/cpuset"

TOPAPP="$BLKROOT/top-app"
FGDIR="$BLKROOT/foreground"
FGBOOSTDIR="$BLKROOT/foreground/boost"
BGDIR="$BLKROOT/background"
KBGDIR="$BLKROOT/key-background"
SBGDIR="$BLKROOT/system-background"

USERDEVID=`mountpoint -d $USERDATADIR`
if [ -z "$USERDEVID" ]; then
	echo "Get userdata devid failed"
	exit 1
fi

SYSUSERDEV="/sys/dev/block/$USERDEVID/partition"
if [ -f $SYSUSERDEV ]; then
	SYSDEV=`readlink -f /sys/dev/block/$USERDEVID`
	SYSDEV=`dirname $SYSDEV`

	if [ -z "$SYSDEV" ]; then
		echo "Get device failed"
		exit 1
	fi

	USERDEVID=`cat $SYSDEV/dev`
	if [ -z "$USERDEVID" ]; then
		echo "Get device id failed"
		exit 1
	fi
fi

echo "$USERDEVID 3" > $BLKROOT/blkio.throttle.mode_device
if [ $? -ne 0 ]; then
	echo "open iops weight control failed"
	exit 1
fi

echo "$USERDEVID 32" > $BLKROOT/blkio.throttle.iops_slice_device
if [ $? -ne 0 ]; then
	echo "set iops slice failed"
	exit 1
fi


set_weight()
{
	local CGRPNAME=$1
	local CGRP=$2
	local VALUE=$3

	echo "$USERDEVID $VALUE" > $CGRP/blkio.throttle.weight_device
	if [ $? -ne 0 ]; then
		echo "set $CGRPNAME weight failed"
	fi
}

set_weight "top-app" $TOPAPP 800
set_weight "fg" $FGDIR 800
set_weight "sbg" $SBGDIR 400
set_weight "kbg" $KBGDIR 400
set_weight "bg" $BGDIR 100

set_max_inflights()
{
	local CGRPNAME=$1
	local CGRP=$2
	local VALUE=$3

	echo "$VALUE" > $CGRP/blkio.throttle.max_inflights
	if [ $? -ne 0 ]; then
		echo "set $CGRPNAME max inflight failed"
	fi
}

echo "$USERDEVID 1" > $BLKROOT/blkio.throttle.enable_max_inflights_device
set_max_inflights "kbg" $KBGDIR $KBG_MAXINFLIGHT
set_max_inflights "bg" $BGDIR $BG_MAXINFLIGHT

set_fg_flag()
{
	local CGRPNAME=$1
	local CGRP=$2
	local VALUE=$3

	echo "$USERDEVID $VALUE" > $CGRP/blkio.throttle.fg_flag
	if [ $? -ne 0 ]; then
		echo "set $CGRPNAME fg flag failed"
	fi
}

set_fg_flag "top-app" $TOPAPP 1
set_fg_flag "foreground" $FGDIR 1
set_fg_flag "foreground/boost" $FGBOOSTDIR 1
