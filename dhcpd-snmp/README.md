# ISC dhcpd and net-snmp and cacti

These scripts have been passed around and munged to the
point that I have no idea where to find the originals.
They second and currently based upon version came from
https://github.com/spions/cacti_isc_dhcp.git
and patched based on a mailing list post
https://lists.isc.org/pipermail/dhcp-users/2014-March/017693.html
by Bjoern and Bill.

## The script

[The script](snmpd/dhcpd-snmp) is running on services-1 and 2.
The net-snmp configuration to include it is straightforward:

    pass_persist .1.3.6.1.4.1.21695.1.2 /usr/local/etc/snmp/dhcpd-snmp

Normally people would use the configuration file as 2nd argument but
due to difficulties we hardcoded it into the perl script.

Luckily, it is using the most efficient extension interface
that net-snmp supports -- pass_persist.

It is configured by `/usr/local/etc/snmp/dhcpd-snmp.conf`, which has
two types of line:

* `leases:` a pointer to the leases file; probably `/var/db/dhcpd/dhcpd.leases`

* `pool:`: a comma-separated list of:

    1. A pool number, used as the INDEX of the table.

    2. A textual name for this pool.

    3. A list of address ranges.  This has to match the `dhcpd-subnets.conf` file.  E.g., for
        this stanza in `dhcpd-subnets.conf`:

            # Users/Wireless-IETF   2176    31.133.176.0/21
            subnet 31.133.176.0 netmask 255.255.248.0 {
                    pool {
                            failover peer "dhcp-failover";
                            deny dynamic bootp clients;
                            range   31.133.176.50  31.133.179.250;
                    }
                    pool {
                            failover peer "dhcp-failover";
                            deny dynamic bootp clients;
                            range   31.133.180.1    31.133.180.250;
                    }
            }

        we have this `pool:` entry:

            pool:10,"Wireless-IETF: 31.133.176.50-31.133.179.250",31.133.176.50-31.133.179.250,31.133.180.1-31.133.180.250

In case it does not work (can't walk it; or the dhcpd-snmp is never spwaned),
run it locally as ./dhscpd-snmp and it will tell you warnings and errors.
You can then also use PING\n or getnext\n\n, or even get\nOID\n to test it.


## The MIB

The "MIB" came from the first original copy wej apparently still had in
his home directory from the nettrack website which no longer exists (we assume; wej?).

Sadly, [the MIB](mib/nettrack-dhcpd-snmp.mib) is not structured per SMIv2.  The table has
no Entry underneath it, so tools like "snmptable" do not
recognize it as a table.

This MIB is edited a little from the one in the distribution to not depend
on NETTRACK-MIB.

## The Cacti Configuration

[The cacti query file](cacti/dhcpd-snmp.xml) goes in `resource/snmp_queries/dhcpd-snmp.xml`.

The cacti template is yet to be properly exported.

## Nagios integration

[The nagios check script](nagios/check_dhcp_pools.sh) is just modified to get
credentials from /etc/snmp/snmpd.conf instead of passing a v2 community
on the command line.
