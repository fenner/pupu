#!/usr/local/bin/bash -
#
# Script to back up important config and database junk from srv0 to srv1

# Depending on how paranoid we're being here, we might want to use a
# pair of staging areas (two entry ring buffer, basicly) so that we
# always have the previous buffer to fall back to if an update cycle
# fails.  Punt this for the moment, but if we decide to go this way
# it'd be trivial to frob $dest here to .../flip or .../flop, with
# some kind of dirty bit (probably represented as an empty file using
# touch or whatever).

host=srv1.ops.ietf.org
dest=/var/rsync-stage
mode=700

# Make sure our target directory exists with suita

/usr/bin/ssh -n $host "if test -d $dest; then chmod $mode $dest; else mkdir -p -m $mode $dest; fi"

# Dump the mysql database in a safe fashion.  If this gets too slow,
# we might need to look into using mysqlhotcopy, but this is simplest
# approach.
#
# This assumes that /root/mysql-client.cnf exists, contains a [client]
# group with a password option, and is not readable by nogoodniks.
#
# Add --verbose to the argument list to get chatter.

cd /var/db/mysql
echo -n 'dumping mysql databases...'
if /usr/local/bin/mysqldump --defaults-extra-file=/root/mysql-client.cnf \
			    --all-databases --opt \
			    > all-databases.sql.$$ &&
   ! /usr/bin/cmp -s all-databases.sql all-databases.sql.$$
then
  /bin/mv all-databases.sql.$$ all-databases.sql
  echo 'ok.'
else
  /bin/rm all-databases.sql.$$
  echo 'no change.'
fi

echo 'rsyncing mysql stuff'
/usr/bin/ssh -n $host "test -d ${dest}${PWD} || mkdir -p ${dest}${PWD}"
/usr/local/bin/rsync -azv my.cnf all-databases.sql $host:${dest}${PWD}/

echo ''

# Dump the DNS database in what we hope is a safe fashion, using the
# kicky new "freeze" command to disable dynamic update temporarily and
# push any recent updates out to the zone files.
#
# If we were being really clever we'd parse the list of zones out of
# named's config file, but it's probably not worth the effort.
#
# We use the scary --delete option in case journal files were
# present from a previous run and are not present now.  This
# probably isn't supposed to happen, but let's be paranoid.

cd /var/dns

#zones='fee.example fie.example foe.example fum.example'
zones=''
echo 'no zones set yet for dynamic update freeze!'

echo 'freezing dynamic zones'
/usr/bin/ssh -n $host "test -d ${dest}${PWD} || mkdir -p ${dest}${PWD}"
for z in $zones ; do /usr/local/sbin/rndc freeze $z ; done
echo 'rsyncing DNS stuff'
/usr/local/bin/rsync -azv --delete $PWD/ $host:${dest}${PWD}
echo 'unfreezing dynamic zones'
for z in $zones ; do /usr/local/sbin/rndc unfreeze $z ; done

echo ''

# Copy over the mail state.  Do we need to do anything special to get
# this into a safe state, eg, shut down exim temporarily?
#
# We use the scary --delete option because starting up exim with a
# queue full of old messages would really suck.

cd /var/spool/exim
echo 'rsyncing exim stuff'
/usr/bin/ssh -n $host "test -d ${dest}${PWD} || mkdir -p ${dest}${PWD}"
/usr/local/bin/rsync -azv --delete $PWD/ $host:${dest}${PWD}

echo ''

# Copy over the dhcpd lease database.  Do we need to kill or pause
# dhcpd to get this into a safe state?

cd /var/db
echo 'rsyncing dhcpd stuff'
/usr/bin/ssh -n $host "test -d ${dest}${PWD} || mkdir -p ${dest}${PWD}"
/usr/local/bin/rsync -azv dhcpd* $host:${dest}${PWD}/

# Now copy over some config directories that we might want

cd /
for d in /etc /usr/local/etc /usr/local/rt2/etc
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
/usr/local/bin/rsync -azv ietf55-srv-backup.sh $host:${dest}${PWD}/

# Are we done yet?
