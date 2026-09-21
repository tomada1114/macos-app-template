#!/usr/bin/env bash
# Tests for scripts/tests/run.sh, the runner this very file is run by. Every case
# copies run.sh into a throwaway tree of its own (run.sh resolves its glob relative
# to its own location, so a copy at TREE/scripts/tests/run.sh globs TREE's fixture
# files and never the real checkout's) and writes fake *_test.sh files into it.
set -euo pipefail
# shellcheck source=scripts/tests/lib.sh
. "$(dirname "$0")/lib.sh"
trap cleanup_temp EXIT

RUN_SRC="${REPO_ROOT}/scripts/tests/run.sh"

# Prints the path of a throwaway tree holding a copy of run.sh and no test file yet.
make_runner_tree() {
    local tree
    tree=$(make_temp_dir)
    mkdir -p "${tree}/scripts/tests"
    cp "${RUN_SRC}" "${tree}/scripts/tests/run.sh"
    echo "${tree}"
}

# write_test_file TREE NAME BODY — writes TREE/scripts/tests/NAME_test.sh.
write_test_file() {
    printf '%s\n' "$3" >"$1/scripts/tests/$2_test.sh"
}

case_all_passing_files_run() {
    local tree
    tree=$(make_runner_tree)
    write_test_file "${tree}" aaa 'echo "from aaa"'
    write_test_file "${tree}" bbb 'echo "from bbb"'

    capture "${BASH}" "${tree}/scripts/tests/run.sh"
    assert_exit 0
    assert_stdout_contains "==> scripts/tests/aaa_test.sh"
    assert_stdout_contains "from aaa"
    assert_stdout_contains "==> scripts/tests/bbb_test.sh"
    assert_stdout_contains "from bbb"
    assert_stdout_contains "script tests: 2 file(s) passed"
}

case_no_test_file_fails_tests_none() {
    local tree
    tree=$(make_runner_tree)

    capture "${BASH}" "${tree}/scripts/tests/run.sh"
    assert_exit 1
    head -n 1 "${CASE_DIR}/stderr" | grep -q '^ERR_TESTS_NONE: ' ||
        _fail "the first stderr line is not ERR_TESTS_NONE"
    assert_stderr_contains "Expected:"
    assert_stderr_contains "Actual:"
    assert_stderr_contains "Next:"
}

case_every_file_runs_after_a_failure() {
    local tree
    tree=$(make_runner_tree)
    write_test_file "${tree}" aaa 'echo "from aaa"; exit 1'
    write_test_file "${tree}" bbb 'echo "from bbb"'
    write_test_file "${tree}" ccc 'echo "from ccc"; exit 1'

    capture "${BASH}" "${tree}/scripts/tests/run.sh"
    assert_exit 1
    # The file after the first failure still ran, and so did the one after it.
    assert_stdout_contains "from bbb"
    assert_stdout_contains "from ccc"
    head -n 1 "${CASE_DIR}/stderr" | grep -q '^ERR_TESTS_FAILED: 2 of 3 ' ||
        _fail "the first stderr line does not count 2 of 3 failures"
    assert_stderr_contains "scripts/tests/aaa_test.sh"
    assert_stderr_contains "scripts/tests/ccc_test.sh"
    assert_stderr_not_contains "scripts/tests/bbb_test.sh" "the passing file"
    assert_stderr_contains "Expected:"
    assert_stderr_contains "Actual:"
    assert_stderr_contains "Next:"
}

case_output_is_printed_whole_per_file() {
    local tree
    tree=$(make_runner_tree)
    # aaa is slow between its two lines, and bbb prints while aaa is still running,
    # so unbuffered output would interleave them. Each file's log is printed whole.
    write_test_file "${tree}" aaa 'echo "AAA-1"; sleep 1; echo "AAA-2"'
    write_test_file "${tree}" bbb 'echo "BBB-1"'

    capture "${BASH}" "${tree}/scripts/tests/run.sh"
    assert_exit 0
    [ "$(grep -A1 -- 'AAA-1' "${CASE_DIR}/stdout" | tail -n 1)" = "AAA-2" ] ||
        _fail "another file's output landed between AAA-1 and AAA-2"
}

case_files_run_concurrently() {
    local tree
    tree=$(make_runner_tree)
    # Each file announces itself and then waits for all three announcements. Run
    # sequentially the first one would wait alone until its timeout and exit 1, so
    # a passing run is itself the proof that the three ran at the same time.
    local name target
    for name in aaa bbb ccc; do
        target="${tree}/scripts/tests/${name}_test.sh"
        # TREE is the fixture root; the rest of the body is taken verbatim.
        printf 'TREE=%s\n' "${tree}" >"${target}"
        cat >>"${target}" <<'BODY'
: >"${TREE}/started.$$"
i=0
while [ "${i}" -lt 200 ]; do
    started=$(ls "${TREE}"/started.* 2>/dev/null | wc -l)
    [ "${started}" -lt 3 ] || exit 0
    sleep 0.05
    i=$((i + 1))
done
echo "timed out waiting for the other files to start" >&2
exit 1
BODY
    done

    capture "${BASH}" "${tree}/scripts/tests/run.sh"
    assert_exit 0
    assert_stdout_contains "script tests: 3 file(s) passed"
}

run_case "every passing file runs and is announced" case_all_passing_files_run
run_case "no test file fails ERR_TESTS_NONE" case_no_test_file_fails_tests_none
run_case "every file runs after a failure and ERR_TESTS_FAILED names each" case_every_file_runs_after_a_failure
run_case "each file's output is printed whole, never interleaved" case_output_is_printed_whole_per_file
run_case "the files run concurrently, not one after another" case_files_run_concurrently
finish
