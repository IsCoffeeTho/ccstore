# API

the ccstore API runs over ports `1000` to `1001 - 9999`

Each storage server has a listener on port `1000` listening for requests on their "[namespace](#namespaces)"

# Protocol

## Architecture

The ccstore protocol consists of Transactional Request and Response messages to and from Servers and Clients.

A Server is any computer that is to "supply" a storage system or something inventory (and can be used to do work), this doesn't mean a server has to be directly
responsible for an inventory but needs to be attatched to one to send and recieve items. Servers can be configured to be (but not limited to):

- A small storage collection.
- A large scale storage collection (usually slower).
- An interface for a working block like a [Furnace](https://minecraft.wiki/w/Furnace) or [Crafter](https://minecraft.wiki/w/Crafter).
- A proxy to another network of storage servers.

A Client is any computer that wants to access a storage system or similar (provided by a server), this means that the client doesn't necessarily have to be
controlled by a player. Clients can be configured to be (but not limited to):

- A userinterface for accessing various storage systems on a network.
- A feed in to the system, possibly from a farm or grinder.
- A scheduler for various work based servers (scheduling crafts or smelts).

## Transactional Messages

### Requests

Request Messages follow a format of `Space seperated` fields:

1. `namespace`: Namespace of the storage server to handle the request (or which namespaces to discover)
2. `msgid`: Message ID to handle idempotency between requests
3. `operation`: Indicate what the client is wanting of the storage server(s)
4. `data`: An optional body of which is specific to each [operation](#operations) and its format

```sh
mystorage.node1 89u0asd237 push minecraft:chest_10;2
```

### Response

Response Messages follow a similar format to the Request Messages being `Space seperated` fields:

1. `msgid`: Message id of the request being handled
2. `statusCode`: A Quickcode of the status of the request (similar to GeminiProtocol)
3. `body`: An optional body that supplies information about the request

```sh
89u0asd237 20 OK
```

| Name                      |   Code   | Notes                                                                                                       |
| :------------------------ | :------: | :---------------------------------------------------------------------------------------------------------- |
| **Informational Message** | **Code** | **Notes**                                                                                                   |
| `ACK`                     |   `05`   | Gets sent by a server to alert the client that the request is being handled and to await a response.        |
| **Succesful Response**    | **Code** | **Notes**                                                                                                   |
| `OK`                      |   `20`   | Server has completed the request and succeeded.                                                             |
| `PARTIAL_OK`              |   `21`   | Indicates that the server handled the request partialy but didn't fully succeed.                            |
| `EMPTY_NAMEPSACE`         |   `28`   | This is not to be sent by a server, instead handled by requests to alert that there were no discovery hits. |
| `SERVER_PRESENT`          |   `29`   | Alerts the the discovery process was a hit. The server responding is here.                                  |
| **Temporary Error**       | **Code** | **Notes**                                                                                                   |
| `ERROR`                   |   `40`   | Server had a problem processing the request.                                                                |
| `NOT_ACCEPTED`            |   `41`   | Server doesn't accept the item because its not designed to handle it (usually for work based systems).      |
| `INVENTORY_INACCESSIBLE`  |   `42`   | Server cannot reach the inventory specified in the request.                                                 |
| `ITEM_INACCESSIBLE`       |   `43`   | Server cannot reach the item in the inventory specified in the request.                                     |
| **Permenant Error**       | **Code** | **Notes**                                                                                                   |
| `BAD_REQUEST`             |   `50`   | Alerts client that the request had bad information that doesn't make sense.                                 |
| `STORAGE_FULL`            |   `51`   | Server cannot accept any items or more of the requested item.                                               |
| `ITEM_EMPTY`              |   `52`   | Server has no more of the requested item.                                                                   |
| `MISSING_INFO`            |   `53`   | Server has recieved the request but it is not complete.                                                     |
| `MALFORMED_REQUEST`       |   `54`   | Server recieved the request but the data is mangled or possibly not even a request.                         |
| `REQUEST_TIMEOUT`         |   `59`   | No server responded to the request. Consider changing namespace or adding your own server.                  |

# Namespaces

> [!warning] WARNING  
> This section is not standardized, please continue with caution.

A Namespace _should_ be unique to a server and is the identifier for making requests, meaning that if a request is made to a namespace with no server
responding, it will timeout.

A standard to follow could look along the lines of:

```
<OWNER>[.<LOCATION>[.<PURPOSE>]].<NODEID>
```

### `<OWNER>`

Would be the person or persons or group of persons that own the storage system.

### `<LOCATION>` _optional_

An area description of where the server could reside (useful for debugging).

### `<PURPOSE>` _optional_

This could describe the type of blocks that are to be stored here (regulated by the server with response codes) or work it does toward the blocks inbound

### `<NODEID>`

An ID specifically of this server in the system.

# Operations

## `discover`

> [!warning] WARNING  
> This section is not standardized, please continue with caution.

The `discover` request is handled differently than other requests in the sense that its not a transactional message.

1. Client sends a Discover request.
2. Servers hear the request and reply if it applies to them.
3. Client waits and accumulates all replies.

### Format

```sh
* 13298yuid2 discover

13298yuid2 29 me.storage.node1
13298yuid2 29 alex.storage.node1
13298yuid2 29 bob.storage.node1
# TIMEOUT OCCURS
```

```sh
mystorage.node1 98udjoi32f discover
# or
98udjoi32f 29 mystorage.node1
# TIMEOUT OCCURS
```
