#!/usr/bin/env bash

set -e

# Check if a branch name is provided
if [ -z "$1" ]; then
  echo "Please provide a branch name as a parameter."
  exit 1
fi

BRANCH_NAME=$1
MAIN_BRANCH=${2:-master}  # Use 'master' as default if no second parameter is provided

# Fetch the latest branches
git fetch

# Check if the branch exists
if ! git show-ref --quiet refs/heads/$BRANCH_NAME; then
  echo "Branch '$BRANCH_NAME' does not exist."
  exit 1
fi

# Get the number of commits in the branch
COMMIT_COUNT=$(git rev-list --count $BRANCH_NAME)

if [ "$COMMIT_COUNT" -le 1 ]; then
  echo "Branch '$BRANCH_NAME' has only $COMMIT_COUNT commit(s). No need to squash."
  exit 0
else
  echo "Branch '$BRANCH_NAME' has $COMMIT_COUNT commits. Proceeding to squash..."

  # Checkout the branch
  git checkout $BRANCH_NAME

  # Squash all commits into one based on the divergence point with the main branch
  git reset $(git merge-base $BRANCH_NAME $MAIN_BRANCH)

  # Create a new squashed commit with the branch name in the message
  git add -A
  git commit -m "Squashed $COMMIT_COUNT commits into one on branch '$BRANCH_NAME'"

  # Force push the squashed commit to the remote branch
  git push origin $BRANCH_NAME --force

  echo "All commits squashed for branch '$BRANCH_NAME', and the changes have been force-pushed."
fi
