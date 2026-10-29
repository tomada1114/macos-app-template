# my-app

[![CI](https://github.com/your-username/my-app/actions/workflows/ci.yml/badge.svg)](https://github.com/your-username/my-app/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/your-username/my-app/badge)](https://scorecard.dev/viewer/?uri=github.com/your-username/my-app)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A strict, supply-chain-hardened GitHub template for open-source macOS apps.
It ships as a working counter app: XcodeGen project, thin app shell over a
local Swift package, Swift Testing suite with an enforced coverage floor, an
XCUITest launch guarantee, and hardened CI — all from the first commit.

Most popular OSS macOS apps ship without CI-gated tests, SECURITY.md,
Dependabot, or pinned actions. This template starts with all of them.

**Starting your own app from this template?** Jump to
[Using This Template](#using-this-template).

## Quickstart

Prerequisites: Xcode 26.5+, [mise](https://mise.jdx.dev/), and
[Just](https://just.systems) (`brew install mise just`).

```bash
git clone https://github.com/your-username/my-app.git
cd my-app
mise trust     # approve mise.toml once — mise refuses untrusted configs
just install   # pinned tools via mise + git hooks + xcodegen generate
just check     # verify-hooks → fmt → lint → test-scripts → check-harness → test → build
open MyApp.xcodeproj
```

## Layout

`App/` is a thin `@main` shell; everything real lives in the local Swift package
`Packages/MyAppKit` — `MyAppCore` (logic, coverage-gated), `MyAppUI` (thin SwiftUI
views), and `MyAppPlatform` (OS adapters behind Core ports). `AGENTS.md`'s Architecture
section holds the layer rules, and how each part is built and why lives in the skill
under `.agents/skills/` that owns it, indexed by `AGENTS.md`'s Skills table. There is no
separate architecture or roadmap document.

## Using This Template

1. Click **"Use this template"** on GitHub and clone your new repository
   (the bootstrap script enumerates files with `git ls-files`, so it needs a
   git checkout — a ZIP download must be `git init`-ed first)
2. Run the bootstrap script to rename everything:

   ```bash
   scripts/bootstrap.sh CoolApp \
     --bundle-id-prefix io.example --github-user janedoe \
     --author "Jane Doe" --email jane@example.com
   ```

   <!-- bootstrap:keep-begin -->
   This replaces `MyApp` (and `MyAppKit`/`MyAppCore`/`MyAppUI`), `my-app`,
   `com.example`, `your-username`, `Your Name`, and `you@example.com` across
   all tracked files, renames the matching paths, and regenerates the Xcode
   project. Omitted optional arguments leave their placeholders as-is. This
   paragraph, and the other passages that explain the placeholders, sit between
   keep markers the script never rewrites, so they still read correctly after it runs.
   <!-- bootstrap:keep-end -->
3. Fill in `AGENTS.md`'s `## Product` section: what the app is and who it is
   for, the core interaction, and the **Non-goals** it must not grow — the
   agent instructions have no other in-repo answer to "is this in scope?".
   Delete every `TODO:` marker as you go; `just check` fails while one is left
   (`scripts/checks/product-section-filled.sh`). That section and the open
   issues are the app's whole direction; there is no roadmap file
4. Verify the rename: `just install && just check`
5. Create the label set on the new repository: `just labels`
   (`.github/labels.yml`; issue forms rely on these labels existing)
6. Update `README.md` (this file), `SECURITY.md`, the rest of `AGENTS.md`, and
   `CODE_OF_CONDUCT.md` for your app (the conduct-reporting contact stays
   `you@example.com` if `--email` was omitted, so check it), and review
   `LICENSE`'s copyright line (`CHANGELOG.md` is reset automatically)
7. Replace or remove the example code — the counter and the `FrontmostApp`
   port/adapter — following the checklist in
   [docs/getting-started.md › Removing the example code](docs/getting-started.md#removing-the-example-code);
   keep the Core/UI split and the tests
8. For signed releases, add the secrets listed in docs/distribution.md
9. Optional, repository admin only: once the bootstrap commit is on `main`,
   protect it with `just ruleset` (`.github/rulesets/main.json`; it requires
   pull requests from then on, and needs a paid plan on a private repository)
10. Private repository only, before step 9: delete
    `.github/workflows/scorecard.yml`, `codeql.yml`, and `dependency-review.yml`
    (they need a public repository or GitHub Advanced Security), remove the
    `Attest build provenance` step from `release.yml` unless your plan supports
    attestations on private repositories, and drop the `Dependency Review` context
    from `.github/rulesets/main.json` — otherwise no pull request can merge. Details:
    [private-repository.md](.agents/skills/starting-an-app/references/private-repository.md)

To find any placeholders the script left untouched (the pattern uses `.`
wildcards so the rename cannot rewrite this very command into your new names):

```bash
rg -i "my.?app|com\.example|your.username|Your.Name|you@example"
```

### Keeping up with template updates

A repository generated from a GitHub template has no upstream link — the files
are copied once. The bootstrap script therefore writes `.template-origin`: the
template commit your app was created from on line 1, the template repository on
line 2. To pull later template improvements (CI hardening, lint-rule bumps,
workflow fixes) into your app:

```bash
git remote add template https://github.com/tomada1114/macos-app-template.git
git fetch template
git log --oneline "$(sed -n 1p .template-origin)"..template/main   # what you don't have yet
git cherry-pick <sha>    # or: git merge template/main --allow-unrelated-histories
```

Both lines read `unknown` when the script could not know them honestly: it records
`HEAD` only when the history's root commit is the template's own first commit.
GitHub's "Use this template" gives the new repository a fresh root instead, so its
`HEAD` is not a template commit and its `origin` is your app rather than the template.
The file then names the file tree to look for, so one `git log --format='%H %T'`
over `template/main` finds the commit — fill the two lines in and the command
above works from then on. Update line 1 yourself whenever you adopt template
changes; the script never rewrites an existing file.

Cherry-picking narrowly scoped commits is usually cleaner than a full merge:
the bootstrap rename means most template commits touch files whose names and
contents differ in your repository. Treat the template as a starting point,
not a dependency — adopt the changes that earn their place.

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for full setup instructions.

```bash
just install
just check
```

The first local `just uitest` run may prompt for Accessibility permission
(System Settings → Privacy & Security); CI runners are pre-provisioned and
run it on every push. If your app itself asks for such a permission, see
[Keeping Permission Grants Across Rebuilds](docs/getting-started.md#keeping-permission-grants-across-rebuilds) —
ad-hoc-signed Debug builds lose the grant on every rebuild.

## Documentation

- [Getting Started](docs/getting-started.md)
- [Distribution & Signing](docs/distribution.md)
- [Adding iOS Later](docs/adding-ios.md)

## License

[MIT](LICENSE)
