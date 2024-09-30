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

  # Now we will find the commits that were introduced by branch1, excluding other commits in master
  # Use cherry-pick to squash only the relevant commits

  # Get the merge base between the main branch and the branch
  MERGE_BASE=$(git merge-base $MAIN_BRANCH $BRANCH_NAME)

  # List all commits made on branch1
  COMMIT_LIST=$(git rev-list --reverse $MERGE_BASE..$BRANCH_NAME)

  if [ -z "$COMMIT_LIST" ]; then
    echo "No commits to squash from branch '$BRANCH_NAME'."
    exit 0
  else
    echo "Branch '$BRANCH_NAME' has commits to squash into '$MAIN_BRANCH'. Proceeding..."

    # Create a new temporary branch to handle the squash
    git checkout -b temp_squash_branch

    # Cherry-pick all the commits from the branch
    git cherry-pick $COMMIT_LIST

    # Squash the commits into one
    git reset --soft $MERGE_BASE
    git add -A
    git commit -m "Squashed commits from branch '$BRANCH_NAME' into '$MAIN_BRANCH'"

    # Checkout the main branch again
    git checkout $MAIN_BRANCH

    # Merge the squashed commit back into the main branch
    git merge --ff-only temp_squash_branch

    # Force push the changes to the remote main branch
    git push origin $MAIN_BRANCH --force

    # Clean up the temporary branch
    git branch -d temp_squash_branch

    echo "Commits squashed from branch '$BRANCH_NAME' into '$MAIN_BRANCH', and the changes have been force-pushed."
  fi
else
  echo "Branch '$BRANCH_NAME' is not merged into '$MAIN_BRANCH'. No squashing will be done."
fi
