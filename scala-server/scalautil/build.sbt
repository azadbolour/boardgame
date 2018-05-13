name := "scalautil"
organization := "com.bolour"
version := "0.9.5"
publishMavenStyle := true
publishTo := Some(Resolver.file("file",  new File(Path.userHome.absolutePath+"/.m2/repository")))
scalaVersion := "2.12.2"