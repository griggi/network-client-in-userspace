Work in Progress.

This should become a network client (someday) which can do DHCP negotiation & http requests.

`Oct 25 2016` - It does DHCP negotiation . `dhcping` linux utility is used alongside the C code. Its sub-optimal but works. 

Forked from [dhcp-client](https://github.com/samueldotj/dhcp-client). Original README below 

dhcp-client
===========

A simple DHCP client written in 500 lines of C code.

Uses pcap library to read/write packets on the network interface.
This program sends out DHCP DISCOVER packet on the given interface and
waits for DHCP OFFER. 

It works on Linux and FreeBSD.
