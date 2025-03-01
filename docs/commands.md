# CCSP Commands

| Commands                                             | Needs | Definition                                                                      |
| ---------------------------------------------------- | :---: | ------------------------------------------------------------------------------- |
| [`CAP`](#cap)                                        |  N/A  | Presents the servers Capabilities                                               |
| [`COUNT <item> [predicate]`](#count)                 |  N/A  | Counts items (matching predicate)                                               |
| [`QUERY <item> [predicate]`](#query)                 |  N/A  | Usualy faster than count but returns if an item (matching predicate) is present |
| [`REQ <inventory> <item> <count> [predicate]`](#req) |  N/A  | Places `count` items (matching predicate) into inventory                        |

# `CAP`
```sh
CCSP <SERVERNAME> CAP
# OK <CAPABILITES>

# Example
CCSP server.name CAP
#OK SYNTH MASS
```

# `COUNT`

```sh
CCSP <SERVERNAME> COUNT <ITEM>
# OK <NUMBER>

# Example
CCSP server.name COUNT diamond
# OK 47
CCSP server.name COUNT minecraft:iron
# OK 173
```

Item is usually formatted with the namespace behind it, however if it is determiend that there
is no namespace then the server will assume the `minecraft` namespace.

In the example because there is no namespace provided, it is assumed to be `minecraft:diamond`.

# `QUERY`

```sh
CCSP <SERVERNAME> QUERY <ITEM>
# OK <BOOLEAN>

# Example
CCSP server.name QUERY minecraft:lily_of_the_valley
# OK true
CCSP server.name QUERY minecraft:ancient_debris
# OK false
```
