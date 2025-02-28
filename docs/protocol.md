# CCSP (CC Store Protocol)

`CCSP` will use the channel `100` by default and will consist of two different systems:

1. Discovery System
2. Storage System

## Discovery

A Discovery packet is used to see which servers are active on a given network

```sh
CCSP DISCOVER <PREDICATES>
```

Predicates are space seperated.

in which the servers can choose to reply with

```sh
CCSP MATCH <SERVERNAME>
```

### Servernames

Servernames must follow this format

```
SERVERNAME =  SUBDOMAIN "." SUBDOMAIN ("." SUBDOMAIN)

SUBDOMAIN = /[a-zA-Z][a-zA-Z0-9]{2,}/g
```

### Predicates for Servers

| Predicate           | Definition                                         |
| :------------------ | :------------------------------------------------- |
| `NAME=<SERVERNAME>` | Server has the name of \<SERVERNAME\>              |
| `MASS`              | Has the ability to store an item in bulk           |
| `SYNTH`             | Able to synthesise items given it has the material |

## Packets

A standard `CCSP Packet` will be a string with the following format

```sh
CCSP <SERVERNAME> <COMMAND> <ARGUMENTS>
```

Consider you have a server called `my.base.ccsp` and it has a double chest full of cobblestone:

```sh
CCSP my.base.ccsp COUNT cobblestone
# OK 3456
```

## Responses

Servers can respond to packets with one of two responses

```sh
OK <RESPONSE>
```

or

```sh
ERR <CODE> <REASON>
```
