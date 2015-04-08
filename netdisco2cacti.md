# Introduction #

For IETF 65, 67 and 68, and probably on an ongoing basis, I've been using netdisco
to discover the network and then exporting those discovered devices to cacti to graph.

The tools depend on the "bulk import to cacti" php scripts that can be found at http://forums.cacti.net/viewtopic.php?t=7683
(how's that for an archival-quality url)

# Details #

The scripts also depend on my cacti dot11-stats configuration, found elsewhere in this tangled mess (link forthcoming, I promise)

The scripts are as follows:
  * add-one-ap
  * add-one-switch
  * add-all-switches
  * gadd-Radio0
  * gadd-both
  * reapply-aps
  * reapply-switches

(in theory, further documentation on usage will end up here.)