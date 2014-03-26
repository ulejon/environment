#!/usr/bin/env bash
#
# sbt-skeleton

set -e

declare projectPath="$(greadlink -fn ${1:-$(pwd)})"
declare githubUser="${GITHUB_USER:-$USER}"

[[ -d "$projectPath" ]] || mkdir -p "$projectPath"
cd "$projectPath"
[[ -e project ]] && { echo "Aborting: $(pwd)/project already exists." && exit 1; }
[[ -e .git ]] && { echo "Aborting: $(pwd)/.git already exists." && exit 1; }

# defaults - not used unless variable is unset
: ${sbtVersion:=0.13.1}
: ${scalaVersion:=2.10.3}
: ${organization:=${ORGANIZATION:-com.sparetimecoders}}
: ${rootPackage:=$organization}
: ${projectName:="$(basename "$projectPath")"}
: ${projectUrl:="https://github.com/$githubUser/$projectName"}

mkdir -p src/{main,test}/scala project


cat >project/plugins.sbt <<EOM
addSbtPlugin("com.github.mpeltonen" % "sbt-idea" % "1.6.0")
EOM

cat >build.sbt <<EOM
name := "$projectName"

description := "$projectName description"

organization := "$organization"

homepage := Some(url("$projectUrl"))

version := "0.1.0-SNAPSHOT"

scalaVersion := "$scalaVersion"

parallelExecution in Test := false

licenses := Seq("Apache" -> url("http://www.apache.org/licenses/LICENSE-2.0"))

shellPrompt := (s => name.value + "> ")

logBuffered := false

libraryDependencies ++= Seq(
 "org.scalatest" % "scalatest_2.10" % "2.1.0" % "test"
  // "org.scala-lang" % "scala-reflect" % scalaVersion.value,
  // "org.scala-lang" % "scala-compiler" % scalaVersion.value,
  // "org.specs2" %% "specs2" % "2.0 % "test",
  // "org.scalacheck" %% "scalacheck" % "1.10.1" % "test"
)

scalacOptions ++= Seq("-unchecked", "-deprecation", "-feature", "-language:postfixOps")


EOM

cat >LICENSE <<EOM
Copyright 2014 Peter Liljenberg

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
EOM

cat >src/main/scala/Main.scala <<EOM
package $rootPackage

object Main {
  def main(args: Array[String]): Unit = {
    println(s"\nSkeleton runner for project $projectName")
  }
}
EOM

cat >src/main/scala/package.scala <<EOM
package object $rootPackage {
}
EOM

cat >src/test/scala/ExampleSpec.scala <<EOM
import collection.mutable.Stack
import org.scalatest._

class ExampleSpec extends FlatSpec with Matchers {

  "A Stack" should "pop values in last-in-first-out order" in {
    val stack = new Stack[Int]
    stack.push(1)
    stack.push(2)
    stack.pop() should be (2)
    stack.pop() should be (1)
  }

  it should "throw NoSuchElementException if an empty stack is popped" in {
    val emptyStack = new Stack[Int]
    a [NoSuchElementException] should be thrownBy {
      emptyStack.pop()
    }
  }
}
EOM

touch README.MD

cat >.gitignore <<EOM
.DS_Store
project/project
project/target
target
.history
/.idea
/*.iml
/.idea_modules
EOM

git init -q .
git add -f .
git commit -q -m "Initial commit - setup"
#git remote add origin "$projectUrl"
#pwd

