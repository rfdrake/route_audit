# Route Audit

## what does it do

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

## Other uses

I used the output from this to generate reverse DNS for our network.  The
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

# TODO

1. add support for pulling a routing table

Being able to see what is actually used can give a different perspective that might be useful
