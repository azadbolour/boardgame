
## Shared Code

Code shared by client and server.

### API

The representation of the API.

### Domain
 
Simple domain model data structures whose representation is not expected to change,
and can be represented directly in JSON.

For these data structures there is no need to distinguish between the client
and server representations.

### Message

Data structures representing request and response messages exchanged
between the client and the server. Also includes the specific wire 
representation of those server-side domain data structures that may change 
over time, or whose wire representation in JSON is ot directly 
related to their server-side representation, for reasons of lack 
of direct JSON type equivalence, or wire transfer efficiency. 
The message representation of these server domain data structures
are suffixed by Dto, for data transfer object. The representation
of the request and response message data structures are are suffixed
by Request and Response respectively.

