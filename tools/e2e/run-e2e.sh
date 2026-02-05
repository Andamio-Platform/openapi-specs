#!/usr/bin/env bash
set -euo pipefail

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required env var: $name" >&2
    exit 1
  fi
}

iso_to_epoch() {
  # GNU date is available on GitHub runners
  date -u -d "$1" +%s
}

wait_for_run() {
  local repo="$1"
  local workflow_file="$2"
  local start_epoch="$3"
  local timeout_seconds="$4"
  local poll_seconds="$5"

  local start_time
  start_time=$(date -u +%s)

  while true; do
    local now
    now=$(date -u +%s)
    if (( now - start_time > timeout_seconds )); then
      echo "Timed out waiting for workflow run: $workflow_file" >&2
      return 1
    fi

    local run_id
    run_id=$(gh api "repos/$repo/actions/workflows/$workflow_file/runs?per_page=10" \
      --jq "[.workflow_runs[] | select((.created_at | fromdateiso8601) >= $start_epoch) | .id] | first // empty")

    if [[ -n "$run_id" ]]; then
      echo "$run_id"
      return 0
    fi

    sleep "$poll_seconds"
  done
}

wait_for_run_completion() {
  local repo="$1"
  local run_id="$2"
  local timeout_seconds="$3"
  local poll_seconds="$4"

  local start_time
  start_time=$(date -u +%s)

  while true; do
    local now
    now=$(date -u +%s)
    if (( now - start_time > timeout_seconds )); then
      echo "Timed out waiting for run $run_id to complete" >&2
      return 1
    fi

    local status
    local conclusion
    status=$(gh api "repos/$repo/actions/runs/$run_id" --jq '.status')
    conclusion=$(gh api "repos/$repo/actions/runs/$run_id" --jq '.conclusion')

    if [[ "$status" == "completed" ]]; then
      if [[ "$conclusion" != "success" ]]; then
        echo "Run $run_id completed with conclusion: $conclusion" >&2
        return 1
      fi
      return 0
    fi

    sleep "$poll_seconds"
  done
}

wait_for_pr_merge() {
  local repo="$1"
  local pr_number="$2"
  local timeout_seconds="$3"
  local poll_seconds="$4"

  local start_time
  start_time=$(date -u +%s)

  while true; do
    local now
    now=$(date -u +%s)
    if (( now - start_time > timeout_seconds )); then
      echo "Timed out waiting for PR #$pr_number to merge" >&2
      return 1
    fi

    local merged_at
    merged_at=$(gh pr view -R "$repo" "$pr_number" --json mergedAt --jq '.mergedAt')
    if [[ -n "$merged_at" && "$merged_at" != "null" ]]; then
      echo "$merged_at"
      return 0
    fi

    sleep "$poll_seconds"
  done
}

require_env E2E_PAT
require_env SOURCE_REPO
require_env RELEASE_TAG
require_env COMMIT_SHA
require_env TRIGGERED_BY

DOCS_REPO="${DOCS_REPO:-${GITHUB_REPOSITORY:-}}"
require_env DOCS_REPO

SYNC_WORKFLOW_FILE="${SYNC_WORKFLOW_FILE:-sync-from-api.yml}"
DEPLOY_WORKFLOW_FILE="${DEPLOY_WORKFLOW_FILE:-deploy-docs.yml}"
SYNC_BRANCH_PREFIX="${SYNC_BRANCH_PREFIX:-sync/}"
PR_TITLE_MATCH="${PR_TITLE_MATCH:-}"
DOCS_REF="${DOCS_REF:-main}"

E2E_TIMEOUT_MINUTES="${E2E_TIMEOUT_MINUTES:-30}"
POLL_SECONDS="${POLL_SECONDS:-20}"
MERGE_METHOD="${MERGE_METHOD:-merge}"
AUTO_MERGE="${AUTO_MERGE:-1}"
MERGE_ADMIN="${MERGE_ADMIN:-0}"

export GH_TOKEN="$E2E_PAT"

start_epoch=$(date -u +%s)

echo "Triggering sync workflow $SYNC_WORKFLOW_FILE in $DOCS_REPO for $RELEASE_TAG"

gh api -X POST "repos/$DOCS_REPO/actions/workflows/$SYNC_WORKFLOW_FILE/dispatches" \
  -f ref="$DOCS_REF" \
  -f "inputs[source_repo]=$SOURCE_REPO" \
  -f "inputs[release_tag]=$RELEASE_TAG" \
  -f "inputs[commit_sha]=$COMMIT_SHA" \
  -f "inputs[triggered_by]=$TRIGGERED_BY"

sync_run_id=$(wait_for_run "$DOCS_REPO" "$SYNC_WORKFLOW_FILE" "$start_epoch" "$((E2E_TIMEOUT_MINUTES * 60))" "$POLL_SECONDS")

echo "Found sync run: $sync_run_id"
wait_for_run_completion "$DOCS_REPO" "$sync_run_id" "$((E2E_TIMEOUT_MINUTES * 60))" "$POLL_SECONDS"

echo "Searching for PR created by sync workflow"

pr_number=$(gh pr list -R "$DOCS_REPO" --state open --json number,title,headRefName,createdAt \
  --jq "[.[] | select((.createdAt | fromdateiso8601) >= $start_epoch) \
    | select(.headRefName | startswith(\"$SYNC_BRANCH_PREFIX\")) \
    | select(\"$PR_TITLE_MATCH\" == \"\" or (.title | test(\"$PR_TITLE_MATCH\"))) \
    | .number] | first // empty")

if [[ -z "$pr_number" ]]; then
  echo "No matching PR found for sync workflow run" >&2
  exit 1
fi

echo "Merging PR #$pr_number"

merge_flags=("--$MERGE_METHOD")
if [[ "$AUTO_MERGE" == "1" || "$AUTO_MERGE" == "true" || "$AUTO_MERGE" == "TRUE" ]]; then
  merge_flags+=("--auto")
fi
if [[ "$MERGE_ADMIN" == "1" || "$MERGE_ADMIN" == "true" || "$MERGE_ADMIN" == "TRUE" ]]; then
  merge_flags+=("--admin")
fi

gh pr merge -R "$DOCS_REPO" "$pr_number" "${merge_flags[@]}"

merged_at=$(wait_for_pr_merge "$DOCS_REPO" "$pr_number" "$((E2E_TIMEOUT_MINUTES * 60))" "$POLL_SECONDS")
merge_epoch=$(iso_to_epoch "$merged_at")

echo "Waiting for deploy workflow $DEPLOY_WORKFLOW_FILE"

deploy_run_id=$(wait_for_run "$DOCS_REPO" "$DEPLOY_WORKFLOW_FILE" "$merge_epoch" "$((E2E_TIMEOUT_MINUTES * 60))" "$POLL_SECONDS")

if [[ -z "$deploy_run_id" ]]; then
  echo "No deploy workflow run found after merge" >&2
  exit 1
fi

wait_for_run_completion "$DOCS_REPO" "$deploy_run_id" "$((E2E_TIMEOUT_MINUTES * 60))" "$POLL_SECONDS"

echo "E2E check passed"
