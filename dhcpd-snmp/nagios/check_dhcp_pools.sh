#! /bin/sh
# https://lists.isc.org/pipermail/dhcp-users/2014-March/017693.html
# https://lists.isc.org/pipermail/dhcp-users/attachments/20140312/62ba636d/attachment.sh
# ##############################################################################
# check_dhcp_pool.sh - Nagios plugin
#
# This script querys a MS Windows DHCP-Server via SNMP v2 to fetch informations about the given DHCP-Pool.
#
# Copyright (C) 2006, 2007 Lars Michelsen <lars@vertical-visions.de>,
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
#
# GNU General Public License: http://www.gnu.org/licenses/gpl-2.0.txt
#
# Report bugs to: lars@vertical-visions.de
#
# 2006-07-05 Version 0.2
# 2007-10-27 Version 0.3
# ##############################################################################
 
if [ $# -lt 3 ]; then
	echo "check_dhcp_pool.sh - Lars Michelsen (Version 0.3 - 2007-10-27)"
	echo "Usage: $0 <host> <community> <pool-ip> [<warn=10>] [<crit=5>]"
	exit 3
fi
 
IP="$1"
COMMUNITY="$2"
POOL="$3"
WARN="$4"
CRIT="$5"
 
if [ ${#WARN} -lt 1 ]
then
	WARN=10
fi
 
if [ ${#CRIT} -lt 1 ]
then
	CRIT=5
fi
 
FREEOID=".1.3.6.1.4.1.21695.1.2.2.1.6.$POOL"
USEDOID=".1.3.6.1.4.1.21695.1.2.2.1.4.$POOL"
NAMEOID=".1.3.6.1.4.1.21695.1.2.2.1.2.$POOL"
 
#SNMP_RESULT=`snmpget -OQ -Ov -v 2c -c $COMMUNITY $IP $FREEOID $USEDOID $NAMEOID`
# Use the snmp.conf defaults
SNMP_RESULT=`snmpget -OQ -Ov $IP $FREEOID $USEDOID $NAMEOID`
set $SNMP_RESULT
FREE=$1
USED=$2
NAME=`echo $3|sed -e's/"//g'`
 
MAX=`echo "$FREE+$USED" |bc`
PERCFREE=`echo "$FREE*100/$MAX" |bc`
PERCUSED=`echo "$USED*100/$MAX" |bc`
 
#DEBUG: echo "FREE: $FREE USED: $USED MAX: $MAX PERC: $PERCFREE,$PERCUSED"
 
if [ "$PERCFREE" -le "$WARN" -a "$PERCFREE" -gt "$CRIT" ]; then
	echo -n "Warning: $FREE Addresses ($PERCFREE% of $MAX) in pool $NAME free"
	RET=1
elif [ "$PERCFREE" -le "$CRIT" ]; then
	echo -n "Critical: $FREE Addresses ($PERCFREE% of $MAX) in pool $NAME free"
	RET=2
else
	echo -n "OK: $FREE Addresses ($PERCFREE% of $MAX) in pool $NAME free"
	RET=0
fi
 
# Performance-Data
echo " | ipAddressesFree=$FREE;$WARN;$CRIT;0;$MAX"
exit $RET
