#!/usr/local/bin/bash -
#
# Script to back up important config and database junk from noc0 to noc1

# Depending on how paranoid we're being here, we might want to use a
# pair of staging areas (two entry ring buffer, basicly) so that we
# always have the previous buffer to fall back to if an update cycle
# fails.  Punt this for the moment, but if we decide to go this way
# it'd be trivial to frob $dest here to .../flip or .../flop, with
# some kind of dirty bit (probably represented as an empty file using
# touch or whatever).

host=noc1.ops.ietf.org
dest=/var/rsync-stage
mode=700

# Make sure our target directory exists with suita

/usr/bin/ssh -n $host "if test -d $dest; then chmod $mode $dest; else mkdir -p -m $mode $dest; fi"

# Copy over the mail state.  Do we need to do anything special to get
# this into a safe state, eg, shut down exim temporarily?
#
# We use the scary --delete option because starting up exim with a
# queue full of old messages would really suck.

cd /var/spool/exim
echo 'rsyncing exim stuff'
/usr/bin/ssh -n $host "test -d ${dest}${PWD} || mkdir -p ${dest}${PWD}"
/usr/local/bin/rsync -azv --delete $PWD/ $host:${dest}${PWD}

# Now copy over some config directories that we might want

cd /
for d in /etc /usr/local/etc
do
  echo ''
  echo "rsyncing $d"
  /usr/bin/ssh -n $host "test -d ${dest}${d} || mkdir -p ${dest}${d}"
  /usr/local/bin/rsync -azv $d/ $host:${dest}${d}/
done

echo ''

# Finally, copy over the current version of this script

cd /usr/local/sbin/
echo 'rsyncing this script'
/usr/bin/ssh -n $host "test -d ${dest}${PWD} || mkdir -p ${dest}${PWD}"
/usr/local/bin/rsync -azv ietf55-noc-backup.sh $host:${dest}${PWD}/

# Are we done yet?
