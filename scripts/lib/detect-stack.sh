#!/usr/bin/env bash
# detect-stack.sh — stack detection + per-stack command/template lookup.
# Mirrors the marker-file table in references/scan.md. Sourced, not executed directly.

detect_stack() {  # detect_stack <dir> -> prints stack name on stdout
  local dir="$1"
  if   [ -f "$dir/package.json" ]; then echo "node"
  elif [ -f "$dir/pyproject.toml" ] || [ -f "$dir/setup.py" ]; then echo "python"
  elif [ -f "$dir/Cargo.toml" ]; then echo "rust"
  elif [ -f "$dir/go.mod" ]; then echo "go"
  elif [ -f "$dir/composer.json" ]; then echo "php"
  elif ls "$dir"/*.csproj "$dir"/*.sln >/dev/null 2>&1; then echo "dotnet"
  elif [ -f "$dir/Gemfile" ]; then echo "ruby"
  # Scala before Java: an sbt project may also carry a build.gradle for tooling, but
  # build.sbt is unambiguous about which toolchain actually builds it.
  elif [ -f "$dir/build.sbt" ]; then echo "scala"
  # Kotlin before Java, and only on positive evidence. A Gradle project is Java by
  # default; it is Kotlin when the build script declares a kotlin plugin or the repo
  # actually contains .kt sources.
  elif _is_kotlin_project "$dir"; then echo "kotlin"
  elif [ -f "$dir/pom.xml" ] || [ -f "$dir/build.gradle" ] || [ -f "$dir/build.gradle.kts" ]; then echo "java"
  elif [ -f "$dir/Package.swift" ]; then echo "swift"
  else echo "generic"
  fi
}

_is_kotlin_project() {  # internal: positive evidence of Kotlin, not just of Gradle
  local dir="$1" f
  for f in "$dir/build.gradle.kts" "$dir/build.gradle"; do
    # `kotlin("jvm")`, `kotlin("multiplatform")`, `id "org.jetbrains.kotlin.jvm"`, ...
    [ -f "$f" ] && grep -qE 'kotlin\(|org\.jetbrains\.kotlin' "$f" 2>/dev/null && return 0
  done
  # No plugin declaration but real Kotlin sources present (depth-limited: a stray .kt
  # in a deep vendor dir should not reclassify a Java repo).
  find "$dir" -maxdepth 5 -name '*.kt' -not -path '*/build/*' -not -path '*/.git/*' \
    -print -quit 2>/dev/null | grep -q . && return 0
  return 1
}

# --- Orthogonal detection ---------------------------------------------------------------
# A repo has exactly one primary language stack, but it can simultaneously be a monorepo
# and/or containerised. These are separate axes, not more `detect_stack` branches: a
# pnpm workspace is still "node", it just needs extra setup guidance.

detect_monorepo() {  # detect_monorepo <dir> -> prints the workspace flavour, or nothing
  local dir="$1"
  if [ -f "$dir/pnpm-workspace.yaml" ] || [ -f "$dir/pnpm-workspace.yml" ]; then
    echo "pnpm"
  elif [ -f "$dir/package.json" ] && grep -q '"workspaces"' "$dir/package.json" 2>/dev/null; then
    # npm and yarn both spell it "workspaces" in package.json; yarn.lock disambiguates.
    if [ -f "$dir/yarn.lock" ]; then echo "yarn"; else echo "npm"; fi
  elif [ -f "$dir/Cargo.toml" ] && grep -qE '^\[workspace\]' "$dir/Cargo.toml" 2>/dev/null; then
    echo "cargo"
  elif [ "$(find "$dir" -maxdepth 3 -name go.mod -not -path '*/.git/*' 2>/dev/null | wc -l)" -gt 1 ]; then
    # More than one go.mod means multiple modules, whether or not go.work exists.
    echo "go"
  fi
}

detect_docker() {  # detect_docker <dir> -> prints "true" when containerised, else nothing
  local dir="$1"
  if [ -f "$dir/Dockerfile" ] || [ -f "$dir/docker-compose.yml" ] \
     || [ -f "$dir/docker-compose.yaml" ] || [ -f "$dir/compose.yaml" ] \
     || [ -f "$dir/compose.yml" ]; then
    echo "true"
  fi
}

# Per-stack: ecosystem id (for dependabot), install/dev/verify commands (for CONTRIBUTING.md).
stack_ecosystem() {
  case "$1" in
    node) echo "npm" ;; python) echo "pip" ;; rust) echo "cargo" ;; go) echo "gomod" ;;
    php) echo "composer" ;; dotnet) echo "nuget" ;; ruby) echo "bundler" ;;
    java) echo "maven" ;; swift) echo "github-actions" ;;
    # scala is detected via build.sbt, and Dependabot has no sbt ecosystem, so it falls
    # back to github-actions rather than claiming a maven/gradle setup it does not have.
    kotlin) echo "gradle" ;; scala) echo "github-actions" ;;
    *) echo "github-actions" ;;
  esac
}

stack_install_cmd() {
  case "$1" in
    node) echo "npm install" ;; python) echo "pip install -e .[dev]" ;;
    rust) echo "cargo build" ;; go) echo "go build ./..." ;;
    php) echo "composer install" ;; dotnet) echo "dotnet restore" ;;
    ruby) echo "bundle install" ;; java) echo "mvn install -DskipTests || ./gradlew build -x test" ;;
    swift) echo "swift build" ;;
    kotlin) echo "./gradlew build -x test" ;; scala) echo "sbt compile" ;;
    *) echo "(no install step needed)" ;;
  esac
}

stack_dev_cmd() {
  case "$1" in
    node) echo "npm run dev --if-present" ;; python) echo "python -m <package>" ;;
    rust) echo "cargo run" ;; go) echo "go run ." ;;
    php) echo "php -S localhost:8000" ;; dotnet) echo "dotnet run" ;;
    ruby) echo "bundle exec rackup" ;; java) echo "mvn spring-boot:run || ./gradlew run" ;;
    swift) echo "swift run" ;;
    kotlin) echo "./gradlew run" ;; scala) echo "sbt run" ;;
    *) echo "(no dev server for this project type)" ;;
  esac
}

stack_verify_cmd() {
  case "$1" in
    node) echo "npm test" ;; python) echo "pytest" ;; rust) echo "cargo test" ;;
    go) echo "go test ./..." ;; php) echo "composer test" ;; dotnet) echo "dotnet test" ;;
    ruby) echo "bundle exec rspec" ;; java) echo "mvn verify || ./gradlew test" ;;
    swift) echo "swift test" ;;
    kotlin) echo "./gradlew test" ;; scala) echo "sbt test" ;;
    *) echo "(add your test command here)" ;;
  esac
}

stack_test_cmd() {  # short form for the PR-template checklist ({{TEST_COMMAND}})
  case "$1" in
    node) echo "npm test" ;; python) echo "pytest" ;; rust) echo "cargo test" ;;
    go) echo "go test ./..." ;; php) echo "composer test" ;; dotnet) echo "dotnet test" ;;
    ruby) echo "bundle exec rspec" ;; java) echo "mvn verify" ;; swift) echo "swift test" ;;
    kotlin) echo "./gradlew test" ;; scala) echo "sbt test" ;;
    *) echo "your test command" ;;
  esac
}

stack_gitignore_file() {  # relative to templates/
  case "$1" in
    node) echo "gitignore/node.gitignore" ;; python) echo "gitignore/python.gitignore" ;;
    rust) echo "gitignore/rust.gitignore" ;; go) echo "gitignore/go.gitignore" ;;
    php) echo "gitignore/php.gitignore" ;; dotnet) echo "gitignore/dotnet.gitignore" ;;
    ruby) echo "gitignore/ruby.gitignore" ;; java) echo "gitignore/java.gitignore" ;;
    swift) echo "gitignore/swift.gitignore" ;;
    kotlin) echo "gitignore/kotlin.gitignore" ;; scala) echo "gitignore/scala.gitignore" ;;
    *) echo "gitignore/generic.gitignore" ;;
  esac
}

stack_ci_file() {  # relative to templates/
  case "$1" in
    node) echo ".github/workflows/node-ci.yml" ;; python) echo ".github/workflows/python-ci.yml" ;;
    php) echo ".github/workflows/php-ci.yml" ;; dotnet) echo ".github/workflows/dotnet-ci.yml" ;;
    ruby) echo ".github/workflows/ruby-ci.yml" ;; java) echo ".github/workflows/java-ci.yml" ;;
    swift) echo ".github/workflows/swift-ci.yml" ;;
    kotlin) echo ".github/workflows/kotlin-ci.yml" ;; scala) echo ".github/workflows/scala-ci.yml" ;;
    *) echo ".github/workflows/generic-ci.yml" ;;
  esac
}
