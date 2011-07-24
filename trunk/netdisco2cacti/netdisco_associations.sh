#!/bin/sh
/usr/local/bin/psql --pset "format=unaligned" --pset "fieldsep= " -t -U netdisco -c "select node.port,count(node.port) as num from node,device where device.ip=node.switch and node.port like '%Radio%' and node.time_last >= device.last_macsuck and node.active='t' group by node.port;" netdisco | sed -e 's/-802.1Q vLAN subif//' | awk 'BEGIN {OFS=":"; ORS=" "}
{print $1, $2}
END {print "\n"}'

