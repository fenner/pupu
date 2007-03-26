#!/usr/bin/perl -Tw
#
# Copyright 2007 VeriLAN Event Services, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the VeriLAN Event Services, Inc. nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY VeriLAN Event Services, Inc. ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL <copyright holder> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# $Id$

use strict;
use Net::SNMP qw(:snmp);

sub client_rates($);

our $cDot11ClientDataRateSet = '1.3.6.1.4.1.9.9.273.1.2.1.1.11.1';
#my @hosts = ('ap01', 'ap02');
my @hosts = map { "130.129.1.$_" } (101 .. 190);
push (@hosts, map { "130.129.1.$_" } (202,203,207 .. 216));

for my $host (@hosts) {
    print "$host\n";
    client_rates($host);
}

exit;

sub client_rates ($) {
    my ($host) = @_;

    my ($session, $error) = Net::SNMP->session(
	-timeout     => '1',
	-version     => 'snmpv2c',
	-nonblocking => 1,
	-hostname    => $host,
	-community   => 'ietf68',
    );
    if (!defined($session)) {
	#printf("ERROR: %s.\n", $error);
	exit 1;
    }
    my $result = $session->get_bulk_request(
	-callback       => [\&table_cb, {}],
	-maxrepetitions => 2,
	-varbindlist    => [$cDot11ClientDataRateSet]
    );
    if (!defined($result)) {
	#printf("ERROR: %s.\n", $session->error);
	$session->close;
	exit 1;
    }
    snmp_dispatcher();
    $session->close;
}

sub table_cb {
    my ($session, $table) = @_;

    if (!defined($session->var_bind_list)) {
	#printf("ERROR: %s\n", $session->error);   
    } else {
	# Loop through each of the OIDs in the response and assign
	# the key/value pairs to the anonymous hash that is passed
	# to the callback.  Make sure that we are still in the table
	# before assigning the key/values.

	my $next;

	foreach my $oid (oid_lex_sort(keys(%{$session->var_bind_list}))) {
	    if (!oid_base_match($cDot11ClientDataRateSet, $oid)) {
		$next = undef;
		last;
	    }
	    $next = $oid; 
	    $table->{$oid} = $session->var_bind_list->{$oid};   
	}

	# If $next is defined we need to send another request 
	# to get more of the table.

	if (defined($next)) {
	    my $result = $session->get_bulk_request(
		-callback       => [\&table_cb, $table],
		-maxrepetitions => 10,
		-varbindlist    => [$next]
	    ); 

	    if (!defined($result)) {
		printf("ERROR: %s\n", $session->error);
	    }
	} else {
	    # We are no longer in the table, so print the results.
	    my %rate_count;
	    foreach my $oid (oid_lex_sort(keys(%{$table}))) {
		#printf("%s => %s\n", $oid, $table->{$oid});
		# parse this info
		if($table->{$oid} =~ /^0x([\d\w]+)/) {
		    #print "$1\n";
		    my $len = length($1);
		    my $top_rate = 0;
		    for my $byte (0..($len/2-1)) {
		        my $str = substr($1, 2*$byte, 2);
			my $rate = sprintf("%2.1f", hex($str)/2);
			if ($rate > $top_rate) {
			    $top_rate = $rate;
			}
		    }
		    $rate_count{$top_rate}++;
		    #print "top: $top_rate\n";
		}
	    }
	    for my $k (sort keys %rate_count) {
	        print "rate $k: " . $rate_count{$k} . "\n";
	    }
	}
    }
}
