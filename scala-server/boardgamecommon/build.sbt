name := "boardgamecommon"
organization := "com.bolour"
version := "0.9.5"
publishMavenStyle := true
publishTo := Some(Resolver.file("file",  new File(Path.userHome.absolutePath+"/.m2/repository")))
scalaVersion := "2.12.2"

// Causes invalid build URI when starting sbt from the parent project.
// OK for this project.
// lazy val scalautil = ProjectRef(file("../scalautil"), "scalautil")
// lazy val theProject = (project in file(".")).dependsOn(scalautil)

libraryDependencies += "org.scalatest" %% "scalatest" % "3.0.5" % Test
libraryDependencies += "org.slf4j" % "slf4j-api" % "1.7.25"
libraryDependencies += "ch.qos.logback" % "logback-classic" % "1.2.3"
