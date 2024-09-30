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

# Check if the branch is already merged into the main branch
if git branch --merged $MAIN_BRANCH | grep -q "$BRANCH_NAME"; then
  echo "Branch '$BRANCH_NAME' is merged into '$MAIN_BRANCH'."

  # Checkout the main branch
  git checkout $MAIN_BRANCH

  # Find the merge commit that brought the branch into the main branch
  MERGE_BASE=$(git merge-base $MAIN_BRANCH $BRANCH_NAME)

  # Calculate the number of commits that were made on the branch before the merge
  # Compare commits made on the branch after the merge base
  COMMIT_COUNT=$(git rev-list --count $MERGE_BASE..$BRANCH_NAME)

  if [ "$COMMIT_COUNT" -le 1 ]; then
    echo "Branch '$BRANCH_NAME' has only $COMMIT_COUNT commit(s). No need to squash on '$MAIN_BRANCH'."
    exit 0
  else
    echo "Branch '$BRANCH_NAME' has $COMMIT_COUNT commits to squash into '$MAIN_BRANCH'."

    # Squash the commits by resetting the main branch to the merge base
    git reset --soft $MERGE_BASE

    # Add all changes and create a new squashed commit on the main branch
    git add -A
    git commit -m "Squashed $COMMIT_COUNT commits from branch '$BRANCH_NAME' into '$MAIN_BRANCH'"

    # Force push the changes to the remote main branch
    git push origin $MAIN_BRANCH --force

    echo "Commits squashed from branch '$BRANCH_NAME' into '$MAIN_BRANCH', and the changes have been force-pushed."
  fi
else
  echo "Branch '$BRANCH_NAME' is not merged into '$MAIN_BRANCH'. No squashing will be done."
fi
