#!/usr/bin/env bash
# Runs every scripts/tests/*_test.sh, each in its own bash process (the same bash
# running this script, so `/bin/bash scripts/tests/run.sh` tests under bash 3.2).
#
# The files run concurrently: each builds its own throwaway repository under its own
# mktemp root and only ever reads the checkout, so they share no state. Every file's
# output is captured to its own log and printed whole, in glob order, once that file
# is waited for — so a concurrent run reads exactly like a sequential one and two
# files can never interleave a line. Every file runs even after one fails; the exit
# code is 1 if any failed.
#
#   scripts/tests/run.sh    (what `just test-scripts` and CI's lint job run)
#
# Git work tree: not required — each test builds its own throwaway repository.
#
# Errors (each followed by Expected:/Actual:/Next: lines, exit 1):
#   ERR_TESTS_NONE    no *_test.sh file was found
#   ERR_TESTS_FAILED  at least one test file exited non-zero
set -euo pipefail

cd "$(dirname "$0")/../.."

LOG_DIR=$(mktemp -d "${TMPDIR:-/tmp}/script-tests-run.XXXXXX")
trap 'rm -rf "${LOG_DIR}"' EXIT

# Start every file, then collect them in glob order. Indexed arrays and `wait <pid>`
# are the bash 3.2 subset: no associative array, no `wait -n`, no `wait -p`.
TOTAL=0
PIDS=()
FILES=()
for file in scripts/tests/*_test.sh; do
    [ -e "${file}" ] || continue
    "${BASH}" "${file}" >"${LOG_DIR}/${TOTAL}.log" 2>&1 &
    PIDS[TOTAL]=$!
    FILES[TOTAL]="${file}"
    TOTAL=$((TOTAL + 1))
done

if [ "${TOTAL}" = 0 ]; then
    echo "ERR_TESTS_NONE: no test file to run" >&2
    echo "Expected: at least one scripts/tests/*_test.sh" >&2
    echo "Actual: the glob matched nothing" >&2
    echo "Next: add scripts/tests/<script-name>_test.sh for the script you changed" >&2
    exit 1
fi

FAILED_COUNT=0
FAILED_FILES=""
INDEX=0
while [ "${INDEX}" -lt "${TOTAL}" ]; do
    STATUS=0
    wait "${PIDS[INDEX]}" || STATUS=$?
    echo "==> ${FILES[INDEX]}"
    cat "${LOG_DIR}/${INDEX}.log"
    if [ "${STATUS}" != 0 ]; then
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_FILES="${FAILED_FILES} ${FILES[INDEX]}"
    fi
    INDEX=$((INDEX + 1))
done

if [ "${FAILED_COUNT}" -gt 0 ]; then
    echo "ERR_TESTS_FAILED: ${FAILED_COUNT} of ${TOTAL} test file(s) failed:${FAILED_FILES}" >&2
    echo "Expected: every scripts/tests/*_test.sh to exit 0" >&2
    echo "Actual: failed:${FAILED_FILES}" >&2
    echo "Next: run \`bash <file>\` and read its \`not ok\` cases and FAIL lines" >&2
    exit 1
fi
echo "script tests: ${TOTAL} file(s) passed"
