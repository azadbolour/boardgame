name := "scala-server"
organization := "com.bolour.boardgame.scala"
version := "0.9.5"
publishMavenStyle := true
publishTo := Some(Resolver.file("file",  new File(Path.userHome.absolutePath+"/.m2/repository")))

lazy val scalautil = project

lazy val plane = (project in file("plane"))
    .dependsOn(scalautil % "test->test;compile->compile")

lazy val boardgamecommon = (project in file("boardgamecommon"))
    .dependsOn(scalautil % "test->test;compile->compile")
    .dependsOn(plane % "test->test;compile->compile")

lazy val `scala-server` = (project in file("."))
  .enablePlugins(PlayScala)
    .dependsOn(scalautil % "test->test;compile->compile")
    .dependsOn(plane % "test->test;compile->compile")
    .dependsOn(boardgamecommon % "test->test;compile->compile")

resolvers += "scalaz-bintray" at "https://dl.bintray.com/scalaz/releases"
      
resolvers += "Akka Snapshot Repository" at "http://repo.akka.io/snapshots/"
      
// scalaVersion := "2.12.2"
scalaVersion := "2.12.10"

val akkaVersion = "2.5.6"
dependencyOverrides ++= Seq( // Seq for SBT 1.0.x
  "com.typesafe.akka" %% "akka-actor" % akkaVersion,
  "com.typesafe.akka" %% "akka-stream" % akkaVersion,
  "com.google.guava" % "guava" % "22.0",
  "org.slf4j" % "slf4j-api" % "1.7.25"
)

libraryDependencies ++= Seq( jdbc , ehcache , ws , guice )
libraryDependencies += "org.scalatestplus.play" %% "scalatestplus-play" % "3.1.2" % "test"
libraryDependencies += "com.typesafe.slick" %% "slick" % "3.2.1"
libraryDependencies += "com.h2database" % "h2" % "1.4.185"
libraryDependencies += "io.spray" %%  "spray-json" % "1.3.3"

unmanagedResourceDirectories in Test +=  baseDirectory.value / "target/web/public/test" 
// unmanagedResourceDirectories in Test <+=  baseDirectory ( _ /"target/web/public/test" )  

