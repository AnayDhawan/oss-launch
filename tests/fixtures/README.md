# tests/fixtures

Minimal, hand-written repo shapes that `tests/run.sh` asserts detection against. Each
directory contains only the marker files the detection actually keys on, so a fixture
stays readable and its purpose stays obvious.

| Fixture | Asserts |
|---|---|
| `kotlin-project/` | `build.gradle.kts` with a `kotlin("jvm")` plugin resolves to `kotlin`, not `java` |
| `gradle-java-project/` | plain Gradle with no Kotlin evidence still resolves to `java` (the regression guard for the branch above) |
| `scala-project/` | `build.sbt` resolves to `scala`, not `generic` |
| `pnpm-monorepo/` | `detect_monorepo` returns `pnpm`, while `detect_stack` still returns `node` |
| `dockerized-node/` | `detect_docker` returns `true`, while `detect_stack` still returns `node` |

The audit-scoring fixtures used by the rest of `run.sh` are built at run time via
`demo/scaffold.sh` instead, so they cannot drift from what `templates/` produces. These
detection fixtures are committed because they encode the *input* shapes being tested,
which is exactly the thing that must not be regenerated.
