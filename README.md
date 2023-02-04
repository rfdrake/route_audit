# Route Audit

This originated as a script that would try to use regex to find all the routes
for all sorts of devices.  At some point I rewrote it to be modular so that
new device types can be added easily.

This is old and I haven't used it in a while but I wanted to release it for
others to enjoy.

## What does it do

This uses rancid config backups to build a JSON or CSV list of all the static
and connected routes in your network.  You can use this to audit an IPAM and
find allocated blocks that aren't databased, or unallocated blocks that are
reserved.

## Supported devices

Juniper, Cisco IOS, Cisco Nexus, Cisco ASA, Casa, Mikrotik, Vyos

## How to run this thing

Synopsis: "raudit_json > routes.json"

You might need to tweak the script depending on where your files are located,
and there may be some things I hardcoded that you need to tweak.

## Problems

When comparing this to your IPAM the routes might not exactly match up.  You
might have a /20 aggregate that is broken out into /24s at properties, or
other such exceptions.  The best solution I've come up with to deal with this
is tagging the routes in IPAM to clarify the exception.

Depending on how flexible your IPAM is this might not be feasible for you.  In
which case you can modify these scripts to handle edge cases.

Every IPAM is different so you will need to write a script to do the actual
audit.  When I wrote this I was using an IPAM written by myself and the audit
scripts were just using SQL queries.  I could include those but they are not
really portable to any other IPAM.

## Other uses

I used the output from this to generate reverse DNS for our network.  That
script has too much business logic for me to include it, but you should be
able to loop over the json and generate PTR records if that interests you.

Long term I would suggest that you fix up your IPAM data and generate reverse
DNS from IPAM instead of the routers.

I also used it to check ipv6 health of the network to find reachability
problems.  Something like this would give you all IPv6 connected routes in
your network, where "2607" is your IPv6 prefix.

```
cat $* | jq -r '.[] | select(.type == "CONNECTED") | select(.addr|test("^2607:")).addr' | cut -f1 -d/
```

You could pipe that to "xargs fping" and get a quick view of if any IPv6
addresses were unreachable.

# TODO

1. add support for pulling and parsing a routing table

Being able to see what is actually in use can give a different perspective
that might be useful when running an audit.
