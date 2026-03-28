#!/bin/bash

# Stop Hook - Auto-commit and push changes on session exit
# Generates Conventional Commits style messages with file change details.

set -euo pipefail

# Infer Conventional Commits type from file extensions.
# Tallies each file into a category and returns the predominant type.
infer_commit_type() {
  local files="$1"
  local docs=0 config=0 code=0 tests=0 ci=0

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    case "$f" in
      *.md|*.txt|*.rst|*.adoc)              ((docs++))   || true ;;
      .github/workflows/*|.github/actions/*) ((ci++))     || true ;;
      *.test.*|*.spec.*|*_test.*|*Test.*|*Tests.*|*_spec.*) ((tests++)) || true ;;
      *.json|*.yml|*.yaml|*.toml|*.xml|*.editorconfig|*.gitignore|*.sh|*.ps1|*.bash) ((config++)) || true ;;
      *)                                     ((code++))   || true ;;
    esac
  done <<< "$files"

  local max=$docs type="docs"
  [[ $config -gt $max ]] && max=$config && type="chore"
  [[ $code   -gt $max ]] && max=$code   && type="feat"
  [[ $tests  -gt $max ]] && max=$tests  && type="test"
  [[ $ci     -gt $max ]] && max=$ci     && type="ci"
  echo "$type"
}

# Build a Conventional Commits message from the staged changes.
generate_commit_message() {
  local name_status file_list
  name_status=$(git diff --cached --name-status)
  file_list=$(echo "$name_status" | awk '{print $NF}')

  local added modified deleted
  added=$(echo "$name_status"   | grep -c '^A' || true)
  modified=$(echo "$name_status" | grep -c '^M' || true)
  deleted=$(echo "$name_status"  | grep -c '^D' || true)

  # --- type ---
  local type
  type=$(infer_commit_type "$file_list")

  # --- summary line ---
  local parts=()
  [[ $modified -gt 0 ]] && parts+=("update ${modified} file(s)")
  [[ $added    -gt 0 ]] && parts+=("add ${added} file(s)")
  [[ $deleted  -gt 0 ]] && parts+=("remove ${deleted} file(s)")
  local summary
  summary=$(IFS=', '; echo "${parts[*]}")

  # --- body: file list (truncated at 15) + shortstat ---
  local file_count body shortstat
  file_count=$(echo "$name_status" | grep -c . || true)

  if [[ $file_count -le 15 ]]; then
    body="$name_status"
  else
    body=$(echo "$name_status" | head -15)
    body+=$'\n'"... and $((file_count - 15)) more file(s)"
  fi

  shortstat=$(git diff --cached --shortstat)

  printf '%s: %s\n\n%s\n\n%s' "$type" "$summary" "$body" "$shortstat"
}

if git rev-parse --is-inside-work-tree &>/dev/null; then
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "📦 Auto-committing and pushing changes..."
    git add -A

    COMMIT_MSG=$(generate_commit_message)

    git commit -m "$COMMIT_MSG" --no-verify 2>/dev/null || true
    git push 2>/dev/null && echo "✅ Changes pushed successfully." || echo "⚠️  Push failed."
  else
    echo "📦 No changes to push."
  fi
fi

exit 0