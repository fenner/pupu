# ISC dhcpd and net-snmp and cacti

These scripts have been passed around and munged to the
point that I have no idea where to find the originals.
They first came from
_
and patched by a mailing list post
https://lists.isc.org/pipermail/dhcp-users/2014-March/017693.html
and patched by Bjoern and Bill.

## The script

[The script](dhcpd-snmp) is running on services-1 and 2.
The net-snmp configuration to include it is straightforward:

    pass_persist .1.3.6.1.4.1.21695.1.2 /usr/local/etc/snmp/dhcpd-snmp

Luckily, it is using the most efficient extension interface
that net-snmp supports -- pass_persist.

## The MIB

Sadly, [the MIB](nettrack-dhcpd-snmp.mib) is not structured per SMIv2.  The table has
no Entry underneath it, so tools like "snmptable" do not
recognize it as a table.

This MIB is edited a little from the one in the distribution to not depend
on NETTRACK-MIB.

## The Cacti Configuration

We need the xml, etc. files to commit here.
