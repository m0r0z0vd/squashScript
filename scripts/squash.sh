#!/usr/bin/env bash

set -e

# Check if a branch name or pattern is provided
if [ -z "$1" ]; then
  echo "Please provide a branch name or pattern as a parameter."
  exit 1
fi

BRANCH_PATTERN=$1
MAIN_BRANCH=${2:-master}  # Use 'master' as default if no second parameter is provided

# Fetch the latest branches
git fetch

# Checkout the main branch
git checkout $MAIN_BRANCH

# Identify commits that match the Jira ticket pattern in commit messages
echo "Searching for commits with pattern '$BRANCH_PATTERN' in '$MAIN_BRANCH'..."

# List all commits that contain the branch pattern in the commit message
COMMIT_LIST=$(git log --pretty=format:"%H" --grep="^$BRANCH_PATTERN")

if [ -z "$COMMIT_LIST" ]; then
  echo "No commits with pattern '$BRANCH_PATTERN' found to squash."
  exit 0
else
  echo "Found commits matching '$BRANCH_PATTERN'. Proceeding to squash them into '$MAIN_BRANCH'..."

  # Create a new temporary branch to handle the squash
  git checkout -b temp_squash_branch

  # Cherry-pick the found commits and automatically resolve conflicts by preferring branch1 changes
  for commit in $COMMIT_LIST; do
    git cherry-pick -X theirs $commit  # Automatically resolve conflicts by choosing branch1's changes
  done

  # Squash the commits into one
  git reset --soft HEAD~$(echo "$COMMIT_LIST" | wc -l)
  git add -A
  git commit -m "Squashed commits matching pattern '$BRANCH_PATTERN' into '$MAIN_BRANCH'"

  # Checkout the main branch again
  git checkout $MAIN_BRANCH

  # Merge the squashed commit back into the main branch
  git merge --ff-only temp_squash_branch

  # Force push the changes to the remote main branch
  git push origin $MAIN_BRANCH --force

  # Clean up the temporary branch
  git branch -d temp_squash_branch

  echo "Commits matching '$BRANCH_PATTERN' squashed into '$MAIN_BRANCH', and changes have been force-pushed."
fi
