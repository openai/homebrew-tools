# Contributing to OpenAI Homebrew Tools

## Contribution policy

We welcome bug reports, feature requests, minimal reproductions, and root-cause
analysis through [GitHub issues](https://github.com/openai/homebrew-tools/issues).

**Pull requests are limited to repository collaborators. We do not accept pull
requests from non-collaborators**, including documentation or example changes.
If you are not a collaborator, please open an issue instead of preparing a pull
request. Include the affected version, expected and actual behavior, and a small,
sanitized reproduction when applicable.

Report suspected security vulnerabilities privately as described in
[SECURITY.md](SECURITY.md), rather than in issues or pull requests.

The development and pull request instructions below are for maintainers and
repository collaborators.

This repository is the `openai/tools` Homebrew tap for prebuilt command-line
tools. See [README.md](README.md) for installation and
[AGENTS.md](AGENTS.md) for agent instructions.

## Security reports and safe examples

Report suspected vulnerabilities privately to `disclosure@openai.com`, following
[SECURITY.md](SECURITY.md) and its coordinated disclosure policy. Do not disclose
vulnerabilities in public issues, PRs, or discussions before coordination.
Include affected recipe versions and minimal, sanitized reproduction steps.

Use synthetic data in examples, fixtures, and tests. Redact API keys, tokens,
authorization headers, cookies, tunnel credentials, customer content, private
hostnames, local account paths, and signed URL query strings from logs and
screenshots. Local recipe validation requires no API or release credentials.
Never commit secrets or include them in command arguments, download URLs, or
test output. If a secret is exposed, report it privately and coordinate
revocation or rotation with its owner; deleting it from a PR is not enough.

## Generated recipes

The headers identify the generators below. Generator configuration and tool
source live upstream; they are not maintained in this tap. For a durable recipe
fix, coordinate with that project's maintainers, change its release configuration
or generator, and regenerate the recipe. Link the upstream change in the tap PR
without copying private source or credentials into public discussion.

| Tool | Recipe | Generator indicated by the recipe | Upstream project |
| --- | --- | --- | --- |
| OpenAI CLI | [Casks/openai.rb](Casks/openai.rb) | GoReleaser | [openai-cli](https://github.com/openai/openai-cli) |
| Orchard | [Formula/orchard.rb](Formula/orchard.rb) | GoReleaser | [orchard](https://github.com/openai/orchard) |
| Softnet | [Formula/softnet.rb](Formula/softnet.rb) | GoReleaser | [softnet](https://github.com/openai/softnet) |
| Tart Guest Agent | [Formula/tart-guest-agent.rb](Formula/tart-guest-agent.rb) | GoReleaser | [tart-guest-agent](https://github.com/openai/tart-guest-agent) |
| Tart | [Formula/tart.rb](Formula/tart.rb) | GoReleaser | [tart](https://github.com/openai/tart) |
| Tunnel Client | [Formula/tunnel-client.rb](Formula/tunnel-client.rb) | Tunnel Client release automation | [tunnel-client](https://github.com/openai/tunnel-client) |

The CLI's application generation and its GoReleaser cask generation are separate
concerns. Do not assume the other projects use the CLI's generator. Headers alone
do not verify upstream release controls or provenance.

## Release artifacts

Use the existing source for each recipe update:

- OpenAI CLI: versioned assets under
  `https://github.com/openai/openai-cli/releases/download/v<version>/`.
- Orchard, Softnet, Tart Guest Agent, and Tart: versioned GitHub release assets
  in the corresponding `openai/<project>` repository above. Preserve that
  project's tag convention; Tart Guest Agent currently uses a `v` prefix.
- Tunnel Client: ZIP assets under
  `https://persistent.oaistatic.com/tunnel-client/v<version>/`.

These are the existing permitted source locations, not evidence that a release
has been audited. Changes to the host, repository, redirect destination, or
artifact naming require maintainer security review. Do not substitute a personal
fork, mutable latest-release URL, or unreviewed mirror.

For each changed platform/architecture artifact, check the upstream release and
version, inspect the final download source, and compare the archive's SHA-256
with the recipe and upstream checksum metadata where available. Compute an
archive digest without executing it, for example:

```sh
shasum -a 256 /path/to/downloaded-artifact.zip
```

Keep a concrete 64-character SHA-256 for every download; never use
`sha256 :no_check`. Record what was verified and any unavailable upstream
signature, attestation, or provenance evidence. A digest proves byte equality
with the expected checksum, not who built those bytes.

Review archive contents and installation behavior as well as version numbers:
the CLI installs completions and a manpage; Orchard generates completions by
running its binary; Tart installs an app bundle, writes a wrapper, generates
completions, and depends on `openai/tools/softnet`. Tunnel Client installs
`tunnel-client`, `cloudflared`, and `cloudflared-manifest.json` together under
`libexec` and writes an executable wrapper. Changes to bundled dependencies or
these execution paths need security review. Do not run untrusted binaries or
start real VMs, networking, or tunnels just to validate release metadata.

## Validation

Use Ruby and Homebrew on macOS, as in
[Validate cask](.github/workflows/validate-cask.yml). From the repository root:

```sh
find Casks Formula -name '*.rb' -type f -print0 | xargs -0 -n1 ruby -c
ruby -c scripts/validate_recipes.rb
ruby scripts/validate_recipes.rb
git diff --check
```

After reviewing recipe code, use a disposable Homebrew environment with no
existing `openai/tools` tap to check that Homebrew can load it:

```sh
brew tap openai/tools "$PWD"
brew readall openai/tools
```

`brew tap` clones the local repository's committed state. Commit the intended
changes locally before this check; it does not include uncommitted edits. If the
tap is already installed, it may refer to a different checkout or revision. Do
not count a check against that copy as validation of your change, or replace a
contributor's existing tap just to run the check. Report when a clean environment
is unavailable. CI checks its checked-out commit using these Homebrew commands.

The structural validator checks expected headers, URLs, checksum shapes, and
selected installation declarations. It does not download or hash release assets,
validate signatures, scan bundled executables, or reject every possible Ruby
behavior. Homebrew loading also evaluates Ruby; passing these checks is not a
security audit. Run applicable linters for changed files; this tap currently has
no dedicated Markdown lint configuration. Include commands and results in the PR.

## Review and pull requests

Keep PRs focused and explain the problem, affected recipes/platforms, upstream
generation changes, validation, and remaining uncertainty. Tap-owned guidance,
workflows, and the validator are maintained here.
[CODEOWNERS](.github/CODEOWNERS) assigns this repository to `@openai/sdks-team`.

Generated release recipe updates require code-owner approval before merging into
`main`. After validation, the GoReleaser workflow enables normal auto-merge;
GitHub waits for required reviews and checks. The release app and SDK team must
not bypass the review rule. Upstream binaries are already published at this
point, so this approval governs their availability through the Homebrew tap.

Maintainer decision (2026-09-14): accept GitHub's native auto-merge behavior for
this tap. The workflow's exact-head and single-recipe checks govern enabling
auto-merge, not the eventual merge. `--match-head-commit` does not permanently
pin an enabled auto-merge request; later pushes by a writer can keep it enabled,
even if the updated PR no longer meets the workflow's single-recipe allowlist.
Safety therefore relies on CODEOWNERS covering every file, required code-owner
approval, dismissal of stale approvals on new commits, required validation, and
no release-app or SDK-team review bypass. Reviewers must inspect the complete
current diff, including changes beyond the generated recipe. Disable this
automation if those protections cannot be maintained. This decision permits
auto-merge to follow reviewed updates; it does not permit merging without review.

Request maintainer security review for sensitive recipe, workflow, and publishing
changes, including:

- Release source, checksums, install/post-install code, shell completions,
  wrappers, bundled binaries, and dependency changes. Review source ownership,
  release notes, advisories, integrity evidence, and transitive dependencies.
- GitHub Action updates: review the exact upstream commit and permission changes;
  retain full commit SHA pins and minimal permissions. Keep secrets out of
  PR-controlled code, logs, and artifacts, and retain checkout credential isolation.
- Validation or merge automation: preserve validation of the expected PR author,
  repository, branch, single recipe path, successful check, and exact head commit.
  The [GoReleaser auto-merge workflow](.github/workflows/auto-merge-goreleaser.yml)
  handles the five GoReleaser recipes; Tunnel Client is not in its allowlist.
  Review changes to its privileged `workflow_run` path, GitHub App token,
  `goreleaser-automerge` environment, or admin merge behavior explicitly.

Repository source shows configured behavior, not live branch protection,
environment approval, publisher binding, or upstream provenance. Do not present
those controls as verified without checking them. Changes to release-approval
policy must be agreed with maintainers separately; this guide does not establish
a new deployment approval gate or authorize bypassing required reviews/checks.
