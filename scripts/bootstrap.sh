#!/usr/bin/env bash
# Template bootstrap: rename every placeholder to your app's identity.
#
#   scripts/bootstrap.sh NewName [--bundle-id-prefix ID] [--github-user USER]
#                                [--author "Full Name"] [--email ADDRESS] [--repo slug]
#
# Replaces (in all git-tracked text files):
#   MyApp        -> NewName            (also MyAppKit/MyAppCore/MyAppUI/MyAppApp)
#   my-app       -> repo slug          (default: kebab-case of NewName)
#   com.example  -> --bundle-id-prefix (kept if omitted)
#   your-username / Your Name / you@example.com -> optional args (kept if omitted)
#
# Then renames MyApp* paths and regenerates the Xcode project.
# Running it again with the same name is a no-op, so it is safe to re-run.
set -euo pipefail

usage() {
    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
}

[ $# -ge 1 ] || usage
NEW_NAME="$1"
shift

if ! [[ "${NEW_NAME}" =~ ^[A-Z][A-Za-z0-9]*$ ]]; then
    echo "error: '${NEW_NAME}' is not PascalCase (expected ^[A-Z][A-Za-z0-9]*$)" >&2
    exit 1
fi

# Default slug: kebab-case of NewName (DemoApp -> demo-app).
DEFAULT_SLUG=$(echo "${NEW_NAME}" | perl -pe 's/([a-z0-9])([A-Z])/$1-$2/g' | tr '[:upper:]' '[:lower:]')

BUNDLE_ID_PREFIX=""
GITHUB_USER=""
AUTHOR=""
EMAIL=""
REPO_SLUG="${DEFAULT_SLUG}"

while [ $# -gt 0 ]; do
    case "$1" in
        --bundle-id-prefix) BUNDLE_ID_PREFIX="$2"; shift 2 ;;
        --github-user)      GITHUB_USER="$2";      shift 2 ;;
        --author)           AUTHOR="$2";           shift 2 ;;
        --email)            EMAIL="$2";            shift 2 ;;
        --repo)             REPO_SLUG="$2";        shift 2 ;;
        *) echo "error: unknown option '$1'" >&2; usage ;;
    esac
done

cd "$(dirname "$0")/.."

replace() { # replace <from> <to> — literal replacement in all tracked text files
    local from="$1" to="$2" file
    [ "${from}" = "${to}" ] && return 0
    git ls-files -z | while IFS= read -r -d '' file; do
        [ -f "${file}" ] || continue
        grep -Iq . "${file}" 2>/dev/null || continue # skip binary and empty files
        FROM="${from}" TO="${to}" perl -pi -e 's/\Q$ENV{FROM}\E/$ENV{TO}/g' "${file}"
    done
}

echo "==> Replacing placeholders"
replace "MyApp" "${NEW_NAME}"
replace "my-app" "${REPO_SLUG}"
[ -n "${BUNDLE_ID_PREFIX}" ] && replace "com.example" "${BUNDLE_ID_PREFIX}"
[ -n "${GITHUB_USER}" ] && replace "your-username" "${GITHUB_USER}"
[ -n "${AUTHOR}" ] && replace "Your Name" "${AUTHOR}"
[ -n "${EMAIL}" ] && replace "you@example.com" "${EMAIL}"

echo "==> Renaming MyApp* paths"
# Drop any stale generated project first; it is rebuilt below.
rm -rf MyApp.xcodeproj "${NEW_NAME}.xcodeproj"
# -depth renames the deepest entries first, so only basenames need rewriting.
find . -depth -name "*MyApp*" -not -path "./.git/*" -not -path "./.build/*" | while IFS= read -r path; do
    base=$(basename "${path}")
    target="$(dirname "${path}")/${base//MyApp/${NEW_NAME}}"
    if [ "${path}" != "${target}" ]; then
        mv "${path}" "${target}"
    fi
done

echo "==> Regenerating Xcode project"
if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate
elif command -v mise >/dev/null 2>&1; then
    mise exec -- xcodegen generate
else
    echo "warning: xcodegen not found — run 'just generate' after installing tools" >&2
fi

echo
echo "Bootstrap complete: MyApp -> ${NEW_NAME} (repo slug: ${REPO_SLUG})"
[ -n "${BUNDLE_ID_PREFIX}" ] && echo "  bundle-id prefix: ${BUNDLE_ID_PREFIX}"
echo
echo "Next steps:"
echo "  1. Review the changes: git diff"
echo "  2. Check for leftovers: rg -i 'myapp|my-app|com\\.example|your-username'"
echo "  3. Commit: git add -A && git commit -m 'chore: bootstrap ${NEW_NAME} from template'"
