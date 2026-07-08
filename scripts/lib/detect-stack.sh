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
  elif [ -f "$dir/pom.xml" ] || [ -f "$dir/build.gradle" ] || [ -f "$dir/build.gradle.kts" ]; then echo "java"
  elif [ -f "$dir/Package.swift" ]; then echo "swift"
  else echo "generic"
  fi
}

# Per-stack: ecosystem id (for dependabot), install/dev/verify commands (for CONTRIBUTING.md).
stack_ecosystem() {
  case "$1" in
    node) echo "npm" ;; python) echo "pip" ;; rust) echo "cargo" ;; go) echo "gomod" ;;
    php) echo "composer" ;; dotnet) echo "nuget" ;; ruby) echo "bundler" ;;
    java) echo "maven" ;; swift) echo "github-actions" ;; *) echo "github-actions" ;;
  esac
}

stack_install_cmd() {
  case "$1" in
    node) echo "npm install" ;; python) echo "pip install -e .[dev]" ;;
    rust) echo "cargo build" ;; go) echo "go build ./..." ;;
    php) echo "composer install" ;; dotnet) echo "dotnet restore" ;;
    ruby) echo "bundle install" ;; java) echo "mvn install -DskipTests || ./gradlew build -x test" ;;
    swift) echo "swift build" ;; *) echo "(no install step needed)" ;;
  esac
}

stack_dev_cmd() {
  case "$1" in
    node) echo "npm run dev --if-present" ;; python) echo "python -m <package>" ;;
    rust) echo "cargo run" ;; go) echo "go run ." ;;
    php) echo "php -S localhost:8000" ;; dotnet) echo "dotnet run" ;;
    ruby) echo "bundle exec rackup" ;; java) echo "mvn spring-boot:run || ./gradlew run" ;;
    swift) echo "swift run" ;; *) echo "(no dev server for this project type)" ;;
  esac
}

stack_verify_cmd() {
  case "$1" in
    node) echo "npm test" ;; python) echo "pytest" ;; rust) echo "cargo test" ;;
    go) echo "go test ./..." ;; php) echo "composer test" ;; dotnet) echo "dotnet test" ;;
    ruby) echo "bundle exec rspec" ;; java) echo "mvn verify || ./gradlew test" ;;
    swift) echo "swift test" ;; *) echo "(add your test command here)" ;;
  esac
}

stack_test_cmd() {  # short form for the PR-template checklist ({{TEST_COMMAND}})
  case "$1" in
    node) echo "npm test" ;; python) echo "pytest" ;; rust) echo "cargo test" ;;
    go) echo "go test ./..." ;; php) echo "composer test" ;; dotnet) echo "dotnet test" ;;
    ruby) echo "bundle exec rspec" ;; java) echo "mvn verify" ;; swift) echo "swift test" ;;
    *) echo "your test command" ;;
  esac
}

stack_gitignore_file() {  # relative to templates/
  case "$1" in
    node) echo "gitignore/node.gitignore" ;; python) echo "gitignore/python.gitignore" ;;
    rust) echo "gitignore/rust.gitignore" ;; go) echo "gitignore/go.gitignore" ;;
    php) echo "gitignore/php.gitignore" ;; dotnet) echo "gitignore/dotnet.gitignore" ;;
    ruby) echo "gitignore/ruby.gitignore" ;; java) echo "gitignore/java.gitignore" ;;
    swift) echo "gitignore/swift.gitignore" ;; *) echo "gitignore/generic.gitignore" ;;
  esac
}

stack_ci_file() {  # relative to templates/
  case "$1" in
    node) echo ".github/workflows/node-ci.yml" ;; python) echo ".github/workflows/python-ci.yml" ;;
    php) echo ".github/workflows/php-ci.yml" ;; dotnet) echo ".github/workflows/dotnet-ci.yml" ;;
    ruby) echo ".github/workflows/ruby-ci.yml" ;; java) echo ".github/workflows/java-ci.yml" ;;
    swift) echo ".github/workflows/swift-ci.yml" ;; *) echo ".github/workflows/generic-ci.yml" ;;
  esac
}
