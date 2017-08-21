
## Isolated Server-Side Code

Private server-side code not shared by client.

### Domain

Includes those domain model data structures that are private to
the server. When the information in one of these structures is needed
in an API request or response message, a specific data transfer object
is created for it in the Common.Message package, and conversion functions
to/from that DTO from/to the domain data structure are provided in a
separate converter module.

### Service

The rest-end-point-independent server-side implementation of the API.
This implementation is independent of messages, DTOs, and DTO converters.

But it uses the common domain model data structures defined the common
package. Those data structures are very simple structures that are not 
subject to change, and that can be directly modeled in JSON for wire
transfer. Conceptually they belong to the server-side domain model. 
But because they are simple and not subject to change, their 
corresponding DTOs would simply be copies of themselves, and 
for reasons of 'dryness' they are shared with the client, rather 
than duplicated in DTOs.

### Web

The 'rest-controller' layer. Thin translation layer between the server-side 
API end point, and the rest-independent server-side implementation of API 
functions. This layer is dependent on the API and the messages and DTOs 
defined in the common module.