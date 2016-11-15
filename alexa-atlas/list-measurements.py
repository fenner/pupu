#!/usr/bin/env python
#
import ripe.atlas.cousteau

api_key = file( 'API_KEY' ).read().strip()

measurements = ripe.atlas.cousteau.MeasurementRequest(description__startswith="IETF97 Alexa")
for m in measurements:
   print m
