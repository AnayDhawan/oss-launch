ThisBuild / scalaVersion := "3.4.2"
ThisBuild / organization := "com.example"

lazy val root = (project in file("."))
  .settings(
    name := "scala-fixture",
    libraryDependencies += "org.scalameta" %% "munit" % "1.0.0" % Test
  )
