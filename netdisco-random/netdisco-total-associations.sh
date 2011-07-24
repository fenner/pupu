#!/bin/sh
/usr/local/bin/psql --pset "format=unaligned" --pset "fieldsep= " -t -U netdisco -c "select node.port,count(node.port) from (select distinct mac,port from node) as node where port like '%Radio%' group by node.port;" netdisco | awk '{ split( $1, v, "." ); count[ v[ 2 ] ] += $2 }
END { for ( vlan in count ) { print vlan, count[ vlan ] } }'
