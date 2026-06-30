#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup-aiuser-fortisai-repo.sh <git_repo_url>
#
# Example:
#   ./setup-aiuser-fortisai-repo.sh git@github.com:LesterAJohn/FortisAI.git

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <git_repo_url>"
  exit 1
fi

REPO_URL="$1"
TARGET_DIR="${FORTISAI_TARGET_DIR:-/opt/home/aiuser/FortisAI}"
TARGET_PARENT="$(dirname "$TARGET_DIR")"
EXCLUDE_FILE="$TARGET_DIR/.git/info/exclude"

ensure_exclude_line() {
  local line="$1"

  if [[ ! -f "$EXCLUDE_FILE" ]]; then
    mkdir -p "$(dirname "$EXCLUDE_FILE")"
    touch "$EXCLUDE_FILE"
  fi

  if ! grep -Fqx "$line" "$EXCLUDE_FILE"; then
    printf '%s\n' "$line" >> "$EXCLUDE_FILE"
  fi
}

setup_local_excludes() {
  # Keep local symlinked/session paths out of git status and pull/push workflows.
  ensure_exclude_line "/tmp"
  ensure_exclude_line "/tmp/"
  ensure_exclude_line "/Development_Environment/llm_directory"
  ensure_exclude_line "/Development_Environment/llm_directory/"
}

mkdir -p "$TARGET_PARENT"

if [[ -d "$TARGET_DIR/.git" ]]; then
  echo "Existing repository found at $TARGET_DIR"
  git -C "$TARGET_DIR" remote set-url origin "$REPO_URL"
  git -C "$TARGET_DIR" fetch --all --prune

  current_branch="$(git -C "$TARGET_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  if [[ -n "$current_branch" && "$current_branch" != "HEAD" ]]; then
    git -C "$TARGET_DIR" pull --ff-only origin "$current_branch"
  else
    default_branch="$(git -C "$TARGET_DIR" remote show origin | sed -n '/HEAD branch/s/.*: //p')"
    if [[ -z "$default_branch" ]]; then
      default_branch="main"
    fi
    git -C "$TARGET_DIR" checkout "$default_branch"
    git -C "$TARGET_DIR" pull --ff-only origin "$default_branch"
  fi
else
  if [[ -e "$TARGET_DIR" && ! -d "$TARGET_DIR" ]]; then
    echo "Error: $TARGET_DIR exists but is not a directory"
    exit 1
  fi

  echo "Cloning $REPO_URL into $TARGET_DIR"
  git clone "$REPO_URL" "$TARGET_DIR"
fi

setup_local_excludes

echo "FortisAI repository is set up at $TARGET_DIR"
echo "Host-local excludes configured in $EXCLUDE_FILE:"
echo "  /tmp"
echo "  /Development_Environment/llm_directory"
