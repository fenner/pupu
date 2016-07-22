#!/usr/bin/env python2.7
#
import csv
import socket

targets = { 'v4': [], 'v6': [] }
sockaf = { 'v4': socket.AF_INET, 'v6': socket.AF_INET6 }
ip = {}

alexa = csv.reader( file( 'top-1m.csv' ) )
while ( len( targets[ 'v4' ] ) < 100 or
	len( targets[ 'v6' ] ) < 100 ):
    ( rank, site ) = alexa.next()
    for af in sockaf:
	try:
	    for (family, socktype, proto, canonname, sockaddr) in \
		socket.getaddrinfo( site, None, sockaf[ af ] ):
		hisIp = sockaddr[ 0 ]
		if hisIp in ip:
		    continue
		targets[ af ].append( ( site, hisIp ) )
		ip[ hisIp ] = True
		break
	except socket.gaierror:
	    # No response for this AF.
	    print "No %s for %s (#%s)." % ( af, site, rank )

import pprint
pprint.pprint( targets )
