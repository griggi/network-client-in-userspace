> Work in Progress

###Summary###

This should become a network client (someday) which can do DHCP negotiation & http requests (upload/download/fetching a url) just like a regular network client (PC/laptop/mobile phone). As for now, DHCP part is only working. The next step is to pick up an http client like [Wget](https://github.com/jay/wget) or [Curl](https://github.com/curl/curl) & integrate with this project. 

As per [@sarvana815](https://github.com/saravana815)

>The way dhtest tool works and the way application works is different. 
>
>dhtest basically opens up raw socket (SOCK\_RAW). This allows to take the full control of all the packet headers.
>
>For Application, they open socket called sock\_stream or sock\_data (tcp, udp). with these sockets, application cares only application data. All the network layer headers are manipulated by network stack which sits on the kernel.

One of the ways is to pick up wget or curl code and see if the packet handling can be changed to use raw sockets. For more reference check [http://www.pdbuchan.com/rawsock/rawsock.html](http://www.pdbuchan.com/rawsock/rawsock.html)

The current implementation so far, uses pcap library. But the link above does not. Also, Wget also does not use any pcap. They all open & write to socket directly. 

###Progress Report###


`Oct 25 2016` - DHCP negotiation works. The client picks up a random mac id on spawning & then get an IP address from the router for the random mac-address . `dhcping` linux utility is used alongside the C code. Its sub-optimal but works. 

<hr/>

Forked from [dhcp-client](https://github.com/samueldotj/dhcp-client). Original README below 

dhcp-client
===========

A simple DHCP client written in 500 lines of C code.

Uses pcap library to read/write packets on the network interface.
This program sends out DHCP DISCOVER packet on the given interface and
waits for DHCP OFFER. 

It works on Linux and FreeBSD.
