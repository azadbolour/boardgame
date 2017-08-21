
## Data Transfer Notes

The client side domain objects used to interact with the game server are all
immutable.

In order to allow deserialization of immutable objects by Jackson (used
internally by Spring Framework's RestTemplate, the library we use to make
Rest calls), the objects need to be annotated as follows:

- @JsonCreator - For constructors.

- @JsonProperty("fieldName") - For fields.


