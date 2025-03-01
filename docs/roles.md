# CCSP Roles

There are three main roles.

1. [Client](#client)
2. [Server](#server)
3. [Proxy](#proxy)

## Client
A client is described as any machine paired with a dedicated storage unit that
sends requests to servers on a network. These come mostly in the form of the
image client which is a computer that is acts solely as a client and not a
general purpose cc:tweaked computer.

A user will setup their system by attaching both their client computer and a
chest to the network, make sure to note the name of the chest while attaching.
They are then available to access any server attached to the same network

## Server
A server is a machine that handles requests sent by clients, usually these
machines are attached to a large bank of storage however it doesn't need to be
attached to anything.

A server master will setup their system the same as the client except there are
two networks, an internal network and outgoing network. The internal network is
attached to its storage bank (if any) and the outgoing network is passed out into
a common or local network depending on implementation.

## Proxy
A proxy is a device that handles requests like a server except it delegates its
processing to other servers or proxies. Used to speed up big systems where having
a singleton server would introduce noticeable latency.

A server master would setup their proxies the same as servers except instead of a
storage bank connected to the internal network, it is other servers or proxies. 
usefull for desiging complex, large scale storage systems.
