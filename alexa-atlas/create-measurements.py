#!/usr/bin/env python
#

import ripe.atlas.cousteau
from datetime import datetime

meeting = 'IETF97'
meetingEnd = datetime.strptime( "2016-11-20 17:00", "%Y-%m-%d %H:%M" )

api_key = file( 'API_KEY' ).read().strip()

targets = eval( file( 'targets.txt' ).read() )

ourProbe = ripe.atlas.cousteau.AtlasSource( type="probes", value="1114", requested=1 )

pings = []
for af in ( 4, 6 ):
    targetList = targets[ 'v%d' % af ]
    # Bill isn't allowed to run more than 100 concurrent measurements.
    for i in range( 50 ):
        target = targetList[ i ]
        # TODO: if there is an existing measurement
	pings.append( ripe.atlas.cousteau.Ping( af=af, target=target[1], description='%s Alexa #%d: %s' % ( meeting, i + 1, target[ 0 ] ) ) )

atlas_request = ripe.atlas.cousteau.AtlasCreateRequest(
    start_time=datetime.utcnow(),
    end_time=meetingEnd,
    key=api_key,
    measurements=pings,
    sources=[ourProbe],
    is_oneoff=False
)

(is_success, response) = atlas_request.create()

print "is_success = %r" % is_success
print "response = %r" % response
