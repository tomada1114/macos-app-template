# Development task runner — requires Just (https://just.systems)
# All commands also work without Just by running the underlying commands directly.

# Show available recipes
default:
    @just --list

# Run tests with the 80% line-coverage floor on MyAppCore
test:
    scripts/coverage.sh

# Build Release and assert the app launches and stays alive
smoke:
    scripts/smoke_launch.sh
