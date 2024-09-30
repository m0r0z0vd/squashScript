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

  # Find the commits from the original branch (branch1) in develop
  echo "Searching for commits from '$BRANCH_NAME'..."

  # Find the merge base between develop and the original branch
  DEVELOP_BASE=$(git merge-base develop $BRANCH_NAME)

  # List commits from branch1 that were merged into develop
  COMMIT_LIST=$(git log --pretty=format:"%H" $DEVELOP_BASE..$BRANCH_NAME)

  if [ -z "$COMMIT_LIST" ]; then
    echo "No commits from branch '$BRANCH_NAME' found to squash."
    exit 0
  else
    echo "Found commits from branch '$BRANCH_NAME'. Squashing them into '$MAIN_BRANCH'..."

    # Create a new temporary branch to handle the squash
    git checkout -b temp_squash_branch

    # Cherry-pick all the commits from the original branch (that passed through develop)
    git cherry-pick $COMMIT_LIST

    # Squash the commits into one
    git reset --soft $DEVELOP_BASE
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

    echo "Commits from branch '$BRANCH_NAME' squashed into '$MAIN_BRANCH', and changes have been force-pushed."
  fi
else
  echo "Branch '$BRANCH_NAME' is not merged into '$MAIN_BRANCH'. No squashing will be done."
fi
