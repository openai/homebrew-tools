# Working in this repository

This is the `openai/tools` Homebrew tap. It distributes generated Ruby recipes
for prebuilt tools; it does not contain their application source or generators.
Read and follow [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md) before making
changes. The recipe and upstream inventory is in
[Generated recipes](CONTRIBUTING.md#generated-recipes).

## Scope and ownership

- Before editing, state the requested outcome, acceptance criteria, affected
  paths, and non-goals. Keep changes limited to that outcome; ask before changing
  public interfaces, crossing ownership boundaries, or restructuring architecture.
- Use a linked Git worktree, verify its intended base commit, and preserve
  unrelated work. Do not edit the primary checkout.
- Follow the [generated-recipe inventory and upstream workflow](CONTRIBUTING.md#generated-recipes) for durable fixes. Regenerate from the owning generator; never silently hand-edit output or assume every recipe uses Castiron.
- Maintain tap-owned documentation, `.github/`, and
  `scripts/validate_recipes.rb` here. Consult [.github/CODEOWNERS](.github/CODEOWNERS)
  for reviewers; its current owner is `@openai/sdks-team`.

## Security boundaries

- Follow [private reporting and safe-example requirements](CONTRIBUTING.md#security-reports-and-safe-examples) and [SECURITY.md](SECURITY.md). Use synthetic data, redact sensitive output, and never read/print unrelated local secrets. Exposed credentials require private reporting and owner-coordinated revocation/rotation; deletion alone is insufficient.
- Validation needs no API/release credentials. Never commit them, put them in arguments/recipe URLs, or expose them to PR code. Keep release credentials in the configured secret store; use scoped, short-lived tokens where supported.
- Preserve [release-artifact sources and checksum/provenance requirements](CONTRIBUTING.md#release-artifacts): versioned HTTPS sources and per-artifact SHA-256; no `sha256 :no_check`, mutable URLs, or unreviewed mirrors. Checksums alone do not prove provenance.
- Recipe Ruby, install hooks, completions, and downloaded executables are code: review before Homebrew loading. Never execute unknown artifacts to inspect versions; prefer synthetic evidence over live networking, VMs, or tunnels.
- Follow the [security review checklist](CONTRIBUTING.md#review-and-pull-requests) for artifacts, installation/bundled code, wrappers, dependencies, validation, Actions, credentials, merge checks, and publishing. Preserve full-SHA Action pins and minimal permissions; never add dependencies merely to bypass failing checks.

## Verification and delivery

- Run the [validation commands](CONTRIBUTING.md#validation) from the repository
  root. Report exactly what passed, failed, or was unavailable. These checks do
  not prove artifact authenticity or upstream security.
- Review the complete diff against the intended base, including new files. Fix
  supported defects introduced by the change and narrowly necessary corrections;
  report unrelated preexisting issues separately. Do not expand the change to
  satisfy speculative review concerns.
- Before pushing or opening/updating a PR, complete applicable tests, linters,
  and security review. Use the `adversarial-review` skill when available: exactly
  two independent, read-only, fresh-context reviewers per round, both inspecting
  this worktree's complete change against the original scope. Require two
  consecutive clean rounds; stop after ten rounds if unresolved. Do not create
  extra worktrees or user-facing tasks for review. If the skill is unavailable,
  report the limitation and arrange equivalent independent review before pushing.
- Monitor CI after submitting a PR; fix in-scope failures and revalidate before
  pushing again. Explain fixes to review feedback and resolve the corresponding
  comments after pushing. Do not claim checks or approvals that were not observed.
