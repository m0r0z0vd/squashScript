#!/usr/bin/env bash

set -e

# Check if a branch pattern is provided
if [ -z "$1" ]; then
  echo "Please provide a branch pattern (e.g., branch1 or DSS-3990)."
  exit 1
fi

BRANCH_PATTERN=$1
MAIN_BRANCH=${2:-master}  # Use 'master' as default if no second parameter is provided

# Remove the temp_squash_branch if it already exists
if git branch --list temp_squash_branch; then
  echo "Removing existing temp_squash_branch..."
  git branch -D temp_squash_branch
fi

# Fetch the latest branches
git fetch

# Checkout the main branch
git checkout $MAIN_BRANCH

# Find all commits in the main branch with commit messages that match the branch pattern
echo "Searching for commits with pattern '$BRANCH_PATTERN' in '$MAIN_BRANCH'..."
COMMIT_LIST=$(git log --pretty=format:"%H" --grep="^$BRANCH_PATTERN")

# Count the number of commits found
COMMIT_COUNT=$(echo "$COMMIT_LIST" | wc -l)

# If there is 1 commit or less, exit without doing anything
if [ "$COMMIT_COUNT" -le 1 ]; then
  echo "Only $COMMIT_COUNT commit(s) found with pattern '$BRANCH_PATTERN'. No need to squash."
  exit 0
fi

# Squash all the commits into a single commit
echo "Squashing $COMMIT_COUNT commits matching pattern '$BRANCH_PATTERN' into one commit..."

# Create a temporary branch to squash the commits
git checkout -b temp_squash_branch

# Cherry-pick the commits found in the log and resolve conflicts by favoring master changes
for commit in $COMMIT_LIST; do
    git cherry-pick -n -X ours $commit || git cherry-pick --skip  # Automatically resolve conflicts by choosing master changes
done

# Create a single squashed commit, allowing an empty commit if no changes were made
git commit --allow-empty -m "Squashed $COMMIT_COUNT commits matching pattern '$BRANCH_PATTERN' into one commit"

# Checkout the main branch again
git checkout $MAIN_BRANCH

# Merge the squashed commit into the main branch
git merge temp_squash_branch --ff-only

# Use git filter-branch to remove the original branch1 commits from history, forcing overwrite of previous backup
echo "Rewriting history to remove original commits..."
git filter-branch -f --commit-filter '
if git log -1 --pretty=%B $GIT_COMMIT | grep -q "^'$BRANCH_PATTERN'";
then
    skip_commit "$@";
else
    git commit-tree "$@";
fi' -- HEAD

# Force push the changes to the main branch
git push origin $MAIN_BRANCH --force

# Clean up temporary branch
git branch -d temp_squash_branch

echo "All $COMMIT_COUNT commits matching pattern '$BRANCH_PATTERN' have been squashed, original commits removed, and force-pushed to '$MAIN_BRANCH'."
