# API

the ccstore API runs over ports `1000` to `1001 - 9999`

Each storage server has a listener on port `1000` listening for requests on their "[namespace](#namespaces)"

## Protocol
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

## Namespaces
> [!warning] WARNING
> No Standard is implemented

A Namespace *should* be unique to a server and is the identifier for making requests,
meaning that if a request is made to a namespace with no server responding, it will timeout.


A standard to follow could look along the lines of:
```html
<OWNER>[.<LOCATION>[.<PURPOSE>]].<SUBID>
```
where:
- `<OWNER>`: Would be the person or persons or group of persons that own the storage system.
- `<LOCATION>` *optional*: An area description of where the server could reside (useful for debugging).
- `<PURPOSE>` *optional*: This could describe the type of blocks that are to be stored here (regulated by the server with response codes) or
	work it does toward the blocks inbound
- `<SUBID>`: An ID specifically of this server in the system.

## Operations
### Discover
The discover ope