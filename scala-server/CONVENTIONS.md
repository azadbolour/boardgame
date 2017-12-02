
## JSON

In Haskell's Servant http server, unit () is encoded
in JSON as []. That is, unit is considered an empty tuple. And since
tuples are encoded in arrays, so is unit. We will follow this standard
in the Scala server as well, as the specification of the JSON API
should be independent of the server implementation (but we don't 
have a choice in the case of Haskell's Servant).



