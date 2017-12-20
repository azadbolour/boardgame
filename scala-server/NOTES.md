
## Coding Conventions

- When getting an option from a map that should not be empty but needs
  to be checked, for brevity name the option ov where v is the first letter of 
  the map value we need. The option is just going to be needed immediately
  for checking and for getting the value of it, so the meaning of the 
  abbreviation will be obvious.

  Monadic treatment of such options is inadequate since we don't get to
  know which option in a monadic chain was empty.

  Treatment by matching becomes unwieldy in nesting levels for each
  match and cases.

  The approach that is easiest to read for me is to just return 
  Failure with the right error when an expected key is missing,
  and then extract the expected value. This approach avoids 
  levels of nesting at the cost of introducing a variable
  for the option.

- Divide the application.conf into sections for each package.
  The rule is that even though config will be passed down from
  the top, only the config section belonging to a given package
  should be read by the classes of that package.

## Intellij

- ^Q for implicit conversions

- ^-SH-P type of expression

- To assign an free expression to a variable - just extract variable:

      CMD-ALT-V
  
  You have to select the whole expression, though. 

  CMD-W will extend selection.

- If the intellij play configuration goes awry and things like
  running tests stop working, the best remedy I have found is
  to simply create another empty play porject from inside intellij,
  get rid of its sources (keep build.sbt, poroject/, and yes target/
  as well), and copy your sources back to this project and merge your
  build.sbt taking care not to change configured stuff.

## Akka HTTP

- https://doc.akka.io/docs/akka-http/current/scala/http/introduction.html

- https://doc.akka.io/docs/akka-http/current/scala/http/routing-dsl/routes.html

- https://doc.akka.io/docs/akka-http/current/scala/http/routing-dsl/directives/marshalling-directives/entity.html

- https://doc.akka.io/api/akka-http/10.0.10/akka/http/scaladsl/index.html - 
  this is the api

- https://doc.akka.io/docs/akka-http/current/scala/http/index.html

- jsonFormat1 etc are templates that come from 

  https://github.com/spray/spray-json/blob/7277ddc103d345e2ca42d6f39a21bbe8c453049b/src/main/boilerplate/spray/json/ProductFormatsInstances.scala.template

  the 1, 2, etc refers to the number of parameters in the case class

- Conversion to json:

  https://doc.akka.io/docs/akka/2.4.4/scala/http/common/json-support.html

  That seems to have good samples auto-convert to json. 

- How to work with json:

    https://github.com/spray/spray-json 

- Implicit conversion to json format - if the case class has a companion
  object, you need to use its apply method explicitly:

  `implicit val playerFormat = jsonFormat2(Player.apply)`

  You can use the name of the case class if it does not have 
  a companion object.

- Akka Http - 
  
      https://doc.akka.io/docs/akka-http/current/scala/http/routing-dsl/exception-handling.html
      https://doc.akka.io/docs/akka-http/current/scala/http/routing-dsl/rejections.html

  You can provide an overall rejection handler and an overall exception handler 
  around the route. What if the call out of route only uses Try?

- Case class json converter macros are defined as templates here:

  https://github.com/spray/spray-json/blob/master/src/main/boilerplate/spray/json/ProductFormatsInstances.scala.template

  You can just click through to say jsonFormat3 from intellij to see 
  the expanded code.

## Scala

- Within a Try for block if a function throws an exception, that 
  exception is caught and converted to a Failure. This includes
  match failures in tests.

- Don't use undefined vals in traits. Use undefined defs and in an object or 
  new definition for that trait use override def.

  Abstract val in trait leads to initialization issues.

- varargs: `method (list:_*)`

- seq.sortBy(function)
  `seq.sortWith(_._1 > _._1)` // descending

- Pattern-matching anonymous function:

    val groupedStripsAndCombos = stripsByBlanks.toList.map {
      case (blanks, strips) => (blanks, strips, trayCombosByLength(blanks))
    }

  You can't pattern match directly on function parameter. Use the above syntax
  instead.

- https://docs.scala-lang.org/tour/pattern-matching.html - good writeup

- Good replacement for Scala Source for IO. Seems like Source is 
  disfavored these days.

- Remember: Try.get throw the included exception if the try is failure.

- Map.get returns option. Map(key) throws exception if not present.

  Map.getOrElse(key, default)

- list.mkString - concatentate member toStrings

- range interval is: [a ..b) 
  
  scala> List.range(0, 0)
  res0: List[Int] = List()

  scala> List.range(0, 1)
  res1: List[Int] = List(0)

- Future errors - onComplete takes a callback: Try[T] => U (U is an arbitrary
  type). But you are not going to get the result of teh callback. So U might as 
  well be Unit, unless the callback is also used for other purposes.

  recover and recoverWith allow you to provide a default value in case of
  failure - you can pattern match on the exception

  https://docs.scala-lang.org/overviews/core/futures.html
  http://www.scala-lang.org/api/2.12.3/scala/concurrent/Future.html

- import java.util.{ArrayList => JavaList}

- List: def fill[A](n: Int)(elem: ⇒ A): List[A]

  val userPieces = List.fill(p.trayCapacity) {generator.next}

- Default parameter value may be an expression.

- TODO. Had issues with traits with abstract vals within which you 
  import something from the abstract val - not sure about the semantics
  of these imports - dynamic, static?? Worked for some imported members
  and not for others. Trying to create database-generic code for slick.

  When I used class instead of trait and made the abstract vals into
  "val" constructor parameters, teh issues went away.

  For now you need to avoid imports from abstract vals of traits.
  Until you can figure out the semantics and maybe find a better way.
  Perhaps using self-type annotation instead of abstract vals??

- Line continuation - end line with open paren or infix operator.

- To delete from a vector use patch - updates a range of values
  with another sequence.

- def apiConfigPath(path: String) = s"${apiConfigPrefix}.${path}"
  Config path is dot-separated not /-separated!

- 1 to 3 is inclusive of 3
  1 until 3 is exclusive of 3

- Aliasing imports:

    import slick.model.{ForeignKeyAction => FKAction}

- class GameDaoSlick(val profile: JdbcProfile // this is public
  without the val it is private

- vararags: 
    `
    val creates = neededTableNames map {name => tableMap(name).schema.create}
    val future = db.run(DBIO.seq(creates:_*))
    `

- Use backtick to match value of a variable in a pattern: case `h2Driver` => H2Profile

- Interpolation: println(s"1 + 1 = ${1 + 1}")

- Overloaded method needs result type.

- I am going to have immutable domain objects. So might as well
  model them in case classes.

- Scala Language Specification - https://www.scala-lang.org/files/archive/spec/2.12/

- Casting numerics:  val index: Int = (binInt % cycleLength).toInt

- The notation def func(p1)(p2) is Scala's way of doing Haskell functions.

  The type becomes p1 => p2 => result.

- lambdas: (x: Int) => x + 1

- Should one use trait with some undefined stuff or a class with 
  constructor parameters? I think the trait gives more flexibility.
  But need to make this more precise.

- Use java.time which is joda time in the standard library.

- To override a trait val you need to have an explicit override in
  in the overriding class/trait.

- Last parameter may be a block.

- Recursive functions need explicit return type.

- +: and :+ the + is on the side of the element.

- Error handling

  Use Try. It is functional and yet includes exceptions. Exceptions
  are needed to get stack traces. And you are going to get exceptions
  from Java libraries and even Scala libraries because they have to 
  work with Java. Try provides a clean way to capture those exceptions
  in functional code.

  http://danielwestheide.com/blog/2012/12/26/the-neophytes-guide-to-scala-part-6-error-handling-with-try.html
  http://danielwestheide.com/blog/2013/01/02/the-neophytes-guide-to-scala-part-7-the-either-type.html
  http://www.scala-lang.org/api/2.12.1/scala/util/Try.html
  http://longcao.org/2015/06/15/easing-into-functional-error-handling-in-scala

  will catch non-fatal exceptions - comes out as Failure(exception)

  Try will add another level of nesting to code code:  if a function is
  to return Try, then its code has to be wrapped in a Try block.
  
  Can pattern match on specific exceptions: Failure(ex: MyException)

  Note that constructors have to return the constructed object and 
  cannot return a Try. Similarly with applies of companion objects.

  Since that is the accepted pattern for creating object in Scala, 
  we'll have to enclose constructor calls in Try when working with Tries.

- Try is a sealed abstract class - sub-class Failure(exception: Throwable)

- Fatal exceptions are not caught by try. They are fatal and it makes sense
  for them to crash the server. 
  
  See http://www.scala-lang.org/api/2.12.0/scala/util/control/NonFatal) 
  for examples of fatal. I am guessing that anything that is an Error. 
  They include OutOfMemoryErrorOutOfMemoryError, StackOverflowError,
  LinkageError. One would expect that these would be discovered and fixed
  in testing. Also if you are load balancing, you might get one server
  crashing and the load balancer restarts it. In any case, you'll need 
  a monitor to restart the service.

- For consistency we'll require all functions of the service layer 
  and above to return tries. 

  But because there are lots of functions in the domain model that
  do not throw [non-fatal] exception, for simplicity and brevity
  we only require Try for those functions of the domain model that 
  can cause exceptions.

- At the level of the rest end point, we assume that the only 
  exceptions not captured in Try are fatal exceptions, and
  for now we just let the framework handle them. If by mistake we
  forget to capture a regular exception in a Try, the framework
  will handle it probably as a 500. For now that seems a reasonable
  approach for simplicity. If it does get to be a problem, need to 
  catch exceptions at the end point and return 500 ourselves.

  TODO. Need to research best practices for when a fatal exception occurs
  in a rest server.

- To convert a method to a function to pass as a function argument:

    `myFunction(method _)`

- Returning a function as a parameter:

    `return (s: String) => { some code }`

- def test(arg: () => Unit) = { arg }

  See page 174 of Scala for the impatient.

  { functionParameter(values) } means call the function parameter

  If the function being passed has arguments, or if you use () for 
  no parameter function then it is obvious in the body of the receiving
  method that the function is being called.
  
  The only issue arises when you call a no-arg function without 
  parens. In that case putting the function name inside { } 
  in the body of the receiving method means call it.

- Call by name is a special case of parameter passing

  you can pass a function that has a parameter by doing 
  
        f((x: Int) => expression(x))
        the formal ars will be f(func: (x: Int) => SomeType)

  But if the function takes no parameters, you can abbreviate this to

  myMethod (func: => SomeType)

  Then in the body using { func } means apply the function.

  The nice thing is that there is an abbreviation for the actual parameter
  in the body of teh caller. Just as in the formal parameter definition
  you don't need to include () for the argument, in the actual parameter
  too you don't. In the caller you can just do:

  myMethod {
    body of function to be passed
  }

  This is just abbreviation for 
  
    `myMethod ( () => { body of what is being passed })`

  But now f looks like a special control structure.

  What if you are defining a function (not a method - def is always a method)
  that takes a no-arg function. Will call-by-name extend to that as well?
  TODO. Create examples.

- In tests the application.conf in test resources is the first one on classpath,
  and only it gets used.

- Scala cookbook: Alvin Alexander - clear practical tips.

  https://alvinalexander.com/scala/sbt-how-pass-command-line-arguments-sbt-run

- Default configuration: reference.conf. 

- Can dummy returns be eliminated in a for comprehension?

      _ <- savePlay(newState, playPieces, refills)
      _ = gameCache.put(gameId, newState)

## Scalatest

- http://doc.scalatest.org/3.0.0/index.html#org.scalatest.FlatSpec

- `http://www.scalatest.org/user_guide/writing_your_first_test`

- Default os parallel execution. To change:

      build.sbt settings: parallelExecution in Test := false

## Slick

- Slick - http://slick.lightbend.com/doc/3.1.0/dbio.html

- Logging configuration details:

  http://slick.lightbend.com/doc/3.2.0-M1/config.html

- Use column[Option[Instant]] for nullable column.

- Import profile is your friend for getting types that Intellij can't find.
  Try this to see if available:

      `import H2Profile.api._`

  Then provide a generic profile and do:

      `import profile.api._`

- Sequence of actions.

    `
    val creates = neededTableNames map {name => tableMap(name).schema.create}
    val future = db.run(DBIO.seq(creates:_*))
    `
- val schema = coffees.schema ++ suppliers.schema
  db.run(DBIO.seq(schema.create))

- val insert = DBIO.seq(playerRows += playerRow)

- http://books.underscore.io/essential-slick/essential-slick-3.html

- http://slick.lightbend.com/doc/3.2.1/database.html

      shows what to add to application.conf

- val query = people.map(p => (p.id, p.name,p.age))
  db.run(query.result)

- JdbcProfile supertype of drivers

- Using self types:

  trait DatabaseProfile {
    val profile: JdbcProfile
  }

  trait Dao {
    self: DatabaseProfile => 

    import profile.api._

  video https://underscore.io/books/essential-slick/

- dbIOAction.asTry will just give back a Try
  may reduce bulk - not sure - as opposed to enclsing in Try.

- dbIOAction.cleanUp(f: Option[Throwable] => DBIOAction)
    allows you to check if exception occurred and take appropriate action

## SBT

- http://www.scala-sbt.org/1.0/docs/Installing-sbt-on-Linux.html

- sbt "testOnly com.bolour.boardgame.scala.server.web.GameEndPointSpec"

- repl for the project: sbt console

- http://www.scala-sbt.org/1.x/docs

- brew install sbt@1

- sbt clean compile "testOnly TestA TestB"  # batch mode

- new project from existing source - then select SBT as the type

- importing new sbt dependencies - tools/SBT opens SBT view - refresh

- assume that maven groupId is organization 

- assume that and maven artifactId is the name of the project

- checked use sbt shell - do as much with sbt as you can

- sbt new sbt/scala-seed.g8
  
  - asks for project name - creates project under a directory of that name
  - creates a target directory in the root - removed that

- getting types in sbt:

    :t (new GameController(null, null)).addPlayer
    play.api.mvc.Action[play.api.libs.json.JsValue]

- interactive mode

  sbt
  > run
  > test
  > ~compile - continuous
  > reload
  > exit

Initial install produced:

Caveats

You can use $SBT\_OPTS to pass additional JVM options to SBT:
   SBT\_OPTS="-XX:+CMSClassUnloadingEnabled -XX:MaxPermSize=256M"

This formula uses the standard Lightbend sbt launcher script.
Project specific options should be placed in .sbtopts in the root of your project.
Global settings should be placed in /usr/local/etc/sbtopts
==> Summary
🍺  /usr/local/Cellar/sbt/1.0.2: 482 files, 61.0MB, built in 45 seconds

## Play

- To create timer tasks see:

    https://www.playframework.com/documentation/2.6.x/ScheduledTasks

- Created a play application from intellij.

- Complained about sbt build disabled.

  In languages and frameworks/play enabled use play2 compilation.

- TODO. Don't know why there is a play2 compilation in addition to 
  sbt compilation, and why intellij does not like sbt compilation.

- Had to explicitly add scala library 2.12 to the project structure

- From the command line:

    sbt run

    starts server on port 9000

- From browser: http://localhost:9000

  Causes the server to do some compilations and then displays the root
  page.

- To run from inside intellij: On the main (top) menu select run/Play2Run.
  It will sart the server and bring up a new browser window on the root page.

- To set the server port in Intellij: In Play2Run configuration add:
  
    `-Dhttp.port=6587

- Setup of static content. 

    -- The location of the web ui bundle is public/javascripts. To get public 
       assets such as the bundle by using the built-in assets controller, added
       the following route to the routes file:

       `GET /assets/*file controllers.Assets.versioned(path="/public", file: Asset)`

    -- Created a script update-ui-bundle.sh to copy the ui bundle built by the
       we ui project over to public/javascscript.

    -- Created an index view the Play way by using a main view for the
       surrounding html.
       
       The index view has an empty div called 'root' which is where React
       renders its components. The index page just runs the bundle as a script:

      `<script src="@routes.Assets.versioned("javascripts/boardgame.bundle.js")" type="text/javascript"></script>`

    -- Created a trivial IndexController to get the index page.

    -- In order to access the application from http://localhost:6587/boardgame
       added the following route to the routes file:

       `GET /boardgame controllers.IndexController.index`

- When doing development by using npm, the javascript comes from the npm server,
  which is by convention at localhost:3000. Since the javascript is comning from 
  a different location as the boardgame server, we must explicitly allow scripts
  from that location to access our boardgame server. In application.conf set:

    `
    play.filters {
      cors {
        allowedOrigins = ["http://localhost:3000"]
      }
    }
    `
- https://www.playframework.com/documentation/2.6.x/ScalaConfig

  play.api.Configuration is a wrapper on Scala's Config.

- In tests, app is provided by default by the framework.

- https://www.playframework.com/documentation/2.6.x/ScalaTestingWithScalaTest

  Just creates a new controller and calls its methods. How to provide the 
  constructor parameters?

  I really want to go through the route so my routing configuration is also
  being tested.

  I don't see an example of this. So best to instantiate the controller and call
  it for now. We already have web-ui integration tests.

- https://www.packtpub.com/web-development/play-framework-essentials
  2014 - maybe the best (and most recent book)

- There is no main program - 

  https://www.playframework.com/documentation/2.6.x/Deploying

- play application secret: probbaly the safest is to have a production 
  config file as described and make it read only to a particular user

- scala> :t (new GameController(null, null)).addPlayer
  play.api.mvc.Action[play.api.libs.json.JsValue]

  def Action: ActionBuilder[Request, AnyContent] = controllerComponents.actionBuilder

- In play we have status applied to some value.  Ok is a status, and
  UnprocessableEntity is a status. The value can be a Json value. 
  To convert a case class to json you need an implicit writes for its type.
  Use the play.api.libs.json.Json.{reads, writes} macros.

  https://www.playframework.com/documentation/2.6.x/ScalaJson
  https://www.playframework.com/documentation/2.6.x/ScalaJsonAutomated
  https://www.playframework.com/documentation/2.6.x/ScalaJsonHttp

- Remember Json.toJson is your friend. If base types of the argument 
  data structure are writable to json then it will work.

  https://alvinalexander.com/scala/play-framework-convert-seq-sequence-scala-objects-to-json

- https://www.playframework.com/documentation/2.6.x/ScalaHome
  https://www.playframework.com/documentation/2.6.x/ScalaRouting
  https://www.playframework.com/documentation/2.6.x/ScalaFunctionalTestingWithScalaTest
  https://nordicapis.com/building-a-rest-api-in-java-scala-using-play-framework-2-part-1/
  https://www.playframework.com/documentation/2.6.x/ScalaJsonAutomated
  https://www.jetbrains.com/help/idea/getting-started-with-play-2-x.html
  https://github.com/playframework/play-scala-rest-api-example 

- cross site requests

    https://www.playframework.com/documentation/2.6.x/ScalaCsrf - they have a filter
    https://www.playframework.com/documentation/2.6.x/CorsFilter
    https://github.com/lomigmegard/akka-http-cors/blob/master/akka-http-cors/src/test/scala/ch/megard/akka/http/cors/CorsDirectivesSpec.scala
    https://github.com/lomigmegard/akka-http-cors/blob/master/akka-http-cors-example/src/main/scala/ch/megard/akka/http/cors/scaladsl/CorsServer.scala
    https://github.com/lomigmegard/akka-http-cors

    Headers are defined here

    https://doc.akka.io/api/akka-http/10.0.4/akka/http/scaladsl/model/headers/Access$minusControl$minusAllow$minusOrigin.html

## CSS

- Useful guide for styling:

    https://css-tricks.com/snippets/css/a-guide-to-flexbox/

## Chrome Postman

- When installed on the MAC it also creates a separate application.
  Can copy that app from the launch pad to tray for easy access.

- Posting: Choose type application/json (to the right) 
  then add the body like:
  
    {"name" : "Bill"} 

## Misc

- curl -v - provides the header information

- division in javascript parseInt(3/2) 

- logback - Error and warning in logback will just turn on info logging
  for logback ignoring any logger directives for logback code itself. 
  Fix the error or warning and the flurry of logback messages will stop.

  For test can have a separate logback-test.xml in teh resources directory.


## Design Decisions

### Domain Object versus Data Transfer Object

Not all fields of a domain object need to be made public in the API.
Also, a convenient representation of a domain object may not be 
convenient for transfer across the wire. Finally, it is useful to be
able to change the the representation of domain objects used in 
internal business logic without affecting the API.

Therefore, we make a distinction between domain objects and 
data transfer objects, in the same way that domain objects are 
distinguished from entity rows. This type of distinction sacrifices
dryness for separation of responsibility between business logic and 
data transfer.

Of course, are some domain objects that are so simple that 
they are highly unlikely to change and all of whose fields 
are subject to data transfer in the API. In that case,
there is really no need to distinguish between the data transfer
object and the domain object, and we just use the data transfer 
object for the domain object.

### Domain Object versus Entity Row

Domain objects may include ephemeral fields that don't need persistence.
The externally-visible identifier of domain objects should not depend on 
the implementation details of persisting them in a database. Finally,
a convenient representation of a domain object for business logic may 
not be convenient for storage.

So we distinguish between domain objects and their corresponding entitity row
objects used for persistence. Id generation is done in business logic and is
independent of the database used.

We could use a similar strategy as with data transfer objects, and identify
domain objects and entity rows where there is no chance of divergence. However
in our intial stages of the development process, for simplicity and consistency,
we will always distinguish domain objects and entity rows.

This design sacrifices dryness in favor of simplicity. But over time
time however as the design stabilizes, we can reduce duplication 
by suing domain objects for entity rows where it makes sense.

## Rest Error Responses

The HTTP protocol has lots of response codes and rules for when to use which
response code. We are going to delegate most of the details of determining
response codes to the REST framework we are using. We will assume that out of
the box, Akka HTTP will provide most of the right response codes, like 400, 401,
etc.  and 500. 

The one case where the framework cannot be responsible for providing the
response is when a known application error is encountered. In that case,
conceptually the return type of the API method is Either(Err, T) where T is the
return type of the happy path. Because the HTTP protocol has a specific response
status, 422, for this case, we will use that status to distinguish between 
a good reponse (status 200) and an error response (status 422). Initially
for simplicity, the entity returned by the error response will just be the 
message associated with the server side error. Later different types of 
errors themselves will be made part of the API so that clients get more control
over dealing with the errors and/or presenting them to users.

The Akka Http framework includes rejections as well as completions.
But the only application level rejection is has is ValidationRejection.
And it is not clear what status code it returns. In any case, our
application errors are not necessarily all just valdation errors.
Our wire protocol specification needs to be independent of the http
framework for different implementations to be easily pluggable
into our framework. Hence we do not use the rejection mechanism
of Akka Http. We complete the request with stats code 422 and
and (initially) a string entity designating the problem. (Later
we can define specific entity types for errors.)

Note that default json encoding does not include the name of the 
class. But we need that in order to know what game error was encountered.
In Servant aeson addsa a tag with the name of the constructor to
the encoding. In spray json there is no equivalent. So to keep 
things simple, we simply create aDTO object for each user error
that needs to be reported back and add the tag to it. This makes
the Scala API consistent with the Haskell API. It allows the fron
end to decipher errors. And it divorces the wire protocol from 
internal server exceptions.

An escaped exception should be caught by the framework and lead to a 
500 status response. But should we get an escaped exception, we need to 
know about it so the problem can be diagnosed. So exceptions need to 
be caught at the highest level and logged. But then throw another
exception so that the framework will deal with it.

## Bash

- diff directory structures

    diff -qr dir1 dir2 

