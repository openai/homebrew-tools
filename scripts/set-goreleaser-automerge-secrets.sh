#!/usr/bin/env bash
set -euo pipefail

repo="openai/homebrew-tools"
environment="goreleaser-automerge"
app_id="${RELEASE_APP_ID:-}"
private_key_file="${RELEASE_APP_PRIVATE_KEY_FILE:-}"

usage() {
  cat <<'USAGE'
Usage:
  scripts/set-goreleaser-automerge-secrets.sh \
    --app-id <github-app-id> \
    --private-key-file <path-to-private-key.pem>

Options:
  --repo <owner/repo>              Defaults to openai/homebrew-tools.
  --environment <name>            Defaults to goreleaser-automerge.
  --app-id <id>                   GitHub App ID. Can also use RELEASE_APP_ID.
  --private-key-file <path>       PEM private key path. Can also use RELEASE_APP_PRIVATE_KEY_FILE.
  -h, --help                      Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repo="${2:?missing value for --repo}"
      shift 2
      ;;
    --environment)
      environment="${2:?missing value for --environment}"
      shift 2
      ;;
    --app-id)
      app_id="${2:?missing value for --app-id}"
      shift 2
      ;;
    --private-key-file)
      private_key_file="${2:?missing value for --private-key-file}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${app_id}" ]]; then
  echo "Missing --app-id or RELEASE_APP_ID." >&2
  exit 2
fi

if [[ -z "${private_key_file}" ]]; then
  echo "Missing --private-key-file or RELEASE_APP_PRIVATE_KEY_FILE." >&2
  exit 2
fi

if [[ ! -f "${private_key_file}" ]]; then
  echo "Private key file does not exist: ${private_key_file}" >&2
  exit 2
fi

if ! gh auth status --hostname github.com >/dev/null; then
  echo "GitHub CLI is not authenticated for github.com." >&2
  exit 2
fi

gh api "repos/${repo}/environments/${environment}" >/dev/null

gh secret set RELEASE_APP_ID \
  --repo "${repo}" \
  --env "${environment}" \
  --body "${app_id}"

gh secret set RELEASE_APP_PRIVATE_KEY \
  --repo "${repo}" \
  --env "${environment}" \
  < "${private_key_file}"

echo "Updated RELEASE_APP_ID and RELEASE_APP_PRIVATE_KEY in ${repo}/${environment}."
